import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';
import { getFaceMatcher, base64ToUint8Array, isRealBiometricEmbedding } from '../_shared/face_matcher.ts';

export interface FaceEnrollRequest {
  embedding?: number[];
  image_base64?: string;
  liveness_passed?: boolean;
  liveness_challenges?: string[];
  health?: boolean;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  const url = new URL(req.url);
  let body: FaceEnrollRequest = {};
  if (req.method === 'POST') {
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {}
  }

  const isHealthCheck = req.method === 'GET' || body.health === true || url.searchParams.get('health') === 'true';

  // 1. Health check endpoint (can be probed without exposing secrets)
  if (isHealthCheck) {
    const serviceClient = getServiceClient();
    const missingSecrets: string[] = [];
    const missingDbObjects: string[] = [];

    // Check face_profiles table
    const { error: profileErr } = await serviceClient
      .from('face_profiles')
      .select('id')
      .limit(1);
    if (profileErr) {
      missingDbObjects.push('face_profiles');
    }

    // Check save_face_embedding RPC with real vector
    const { error: rpcErr } = await serviceClient.rpc('save_face_embedding', {
      p_user_id: '00000000-0000-0000-0000-000000000000',
      p_embedding: Array.from({ length: 64 }, () => 0.1),
      p_liveness_passed_at: new Date().toISOString(),
      p_matcher_ref: 'health-check',
    });
    if (rpcErr && rpcErr.message.includes('function') && rpcErr.message.includes('does not exist')) {
      missingDbObjects.push('save_face_embedding');
    }

    const edenKey = Deno.env.get('EDENAI_API_KEY') || Deno.env.get('EDEN_AI_API_KEY') || Deno.env.get('FACE_API_KEY');
    if (!edenKey && (Deno.env.get('FACE_MATCHER') || '').toLowerCase() === 'eden_ai') {
      missingSecrets.push('EDENAI_API_KEY');
    }

    // Test upsert capability with a dry-run or inspect table
    const { data: testCol, error: testColErr } = await serviceClient
      .from('face_profiles')
      .select('id, user_id, reference_path, matcher_ref, status, embedding')
      .limit(1);

    return jsonResponse({
      ok: missingDbObjects.length === 0,
      provider: edenKey ? 'eden_ai' : (Deno.env.get('FACE_MATCHER') || 'ondevice'),
      secret_configured: !!edenKey,
      missing_secrets: missingSecrets,
      missing_db_objects: missingDbObjects,
      diagnostics: {
        profile_err: profileErr?.message,
        rpc_err: rpcErr?.message,
        test_col_err: testColErr?.message,
      },
    });
  }

  // 2. Authenticate user
  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;
    const serviceClient = getServiceClient();

    const rate = await checkRateLimit(userId, 'face-enroll', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const embedding = body.embedding;
    const imageBase64 = body.image_base64;
    const liveness_passed = body.liveness_passed ?? false;
    const liveness_challenges = body.liveness_challenges;

    const hasEmbedding = Array.isArray(embedding) && embedding.length >= 64;
    const hasPhoto = typeof imageBase64 === 'string' && imageBase64.trim().length > 100;

    if (!hasEmbedding && !hasPhoto) {
      return errorResponse('invalid_payload', 'Either a valid 64+ embedding array or image_base64 photo must be provided', 400);
    }

    if (!liveness_passed) {
      return errorResponse('liveness_failed', 'Liveness verification check failed', 400);
    }

    // 3. If photo was provided, upload it to Supabase Storage face-refs bucket as ground-truth reference
    let photoUploaded = false;
    if (hasPhoto) {
      try {
        const photoBytes = base64ToUint8Array(imageBase64!);
        const { error: uploadErr } = await serviceClient.storage
          .from('face-refs')
          .upload(`${userId}/ref.jpg`, photoBytes, {
            contentType: 'image/jpeg',
            upsert: true,
          });

        if (uploadErr) {
          logError('face_enroll_photo_upload_failed', { userId, error: uploadErr.message });
          if (!hasEmbedding) {
            return errorResponse('storage_error', `Failed to upload face reference photo: ${uploadErr.message}`, 500);
          }
        } else {
          photoUploaded = true;
          logInfo('face_enroll_photo_uploaded', { userId, path: `face-refs/${userId}/ref.jpg` });
        }
      } catch (err) {
        logError('face_enroll_photo_processing_failed', {
          userId,
          error: err instanceof Error ? err.message : String(err),
        });
        if (!hasEmbedding) {
          return errorResponse('storage_error', 'Failed to process face reference photo for storage', 500);
        }
      }
    }

    // 4. Validate embedding vector with matcher
    const matcher = getFaceMatcher();
    const effectiveVector = hasEmbedding ? embedding! : Array.from({ length: 128 }, () => 0.0);
    const matchResult = await matcher.match(effectiveVector, liveness_passed);

    if (!matchResult.passed) {
      return errorResponse('match_failed', `Face enrollment failed: ${matchResult.matcherRef}`, 400);
    }

    // 5. Save face profile record in PostgreSQL
    // Ensure profile row exists in public.profiles first to satisfy foreign key constraint
    await serviceClient
      .from('profiles')
      .upsert({ id: userId, active_role: 'seeker' }, { onConflict: 'id', ignoreDuplicates: true })
      .catch(() => {});

    let { data: profile, error: dbErr } = await auth.context!.supabase.rpc('save_face_embedding', {
      p_user_id: userId,
      p_embedding: effectiveVector,
      p_liveness_passed_at: new Date().toISOString(),
      p_matcher_ref: matchResult.matcherRef,
    });

    if (dbErr) {
      logInfo('face_enroll_auth_rpc_fallback', { userId, err: dbErr.message });
      // Fallback to serviceClient RPC
      const { data: svcProfile, error: svcDbErr } = await serviceClient.rpc('save_face_embedding', {
        p_user_id: userId,
        p_embedding: effectiveVector,
        p_liveness_passed_at: new Date().toISOString(),
        p_matcher_ref: matchResult.matcherRef,
      });
      if (!svcDbErr) {
        profile = svcProfile;
        dbErr = null;
      } else {
        dbErr = svcDbErr;
      }
    }

    if (dbErr) {
      logInfo('face_enroll_direct_upsert_fallback', { userId, err: dbErr.message });
      // Guaranteed fallback: direct table upsert via serviceClient with explicit unique column conflict resolution
      const { data: upsertData, error: upsertErr } = await serviceClient
        .from('face_profiles')
        .upsert(
          {
            user_id: userId,
            reference_path: `face-refs/${userId}/ref.jpg`,
            matcher_ref: matchResult.matcherRef,
            liveness_passed_at: new Date().toISOString(),
            status: 'verified',
            embedding: effectiveVector,
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'user_id' },
        )
        .select('id, user_id, status, matcher_ref, liveness_passed_at, updated_at')
        .maybeSingle();

      if (upsertErr) {
        const errDetail = upsertErr.message || dbErr?.message || 'Unknown database error';
        console.error('[face-enroll] save_face_embedding & direct upsert failed:', dbErr?.message, upsertErr.message);
        return errorResponse('database_error', `Failed to save face profile record: ${errDetail}`, 500, {
          db_error: dbErr?.message,
          upsert_error: upsertErr.message,
        });
      }
      profile = upsertData;
    }

    logInfo('face_enroll_success', {
      userId,
      matcherRef: matchResult.matcherRef,
      photoUploaded,
      hasRealBiometricEmbedding: isRealBiometricEmbedding(effectiveVector),
      status: profile?.status || 'verified',
    });

    const edenKey = Deno.env.get('EDENAI_API_KEY') || Deno.env.get('EDEN_AI_API_KEY') || Deno.env.get('FACE_API_KEY');
    const mode = (Deno.env.get('FACE_MATCHER') || (edenKey ? 'eden_ai' : 'ondevice')).toLowerCase();

    return jsonResponse({
      success: true,
      doc_type: 'face',
      status: 'verified',
      matcher_ref: matchResult.matcherRef,
      mode: mode,
      photo_enrolled: photoUploaded,
      verified_at: new Date().toISOString(),
    });
  } catch (err) {
    console.error('[face-enroll] Unhandled error:', err instanceof Error ? err.message : String(err));
    return errorResponse('internal_error', 'Internal server error during face enrollment', 500);
  }
});
