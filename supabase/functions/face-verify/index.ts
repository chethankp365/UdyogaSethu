import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';
import {
  compareFacesWithEdenAi,
  base64ToUint8Array,
  isRealBiometricEmbedding,
  type EdenCompareResult,
} from '../_shared/face_matcher.ts';

export interface FaceVerifyRequest {
  image_base64?: string;
  embedding?: number[];
  context?: 'login' | 'job_start' | 'mid_job' | 'completion';
  assignment_id?: string;
  gps_ok?: boolean;
  health?: boolean;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  const url = new URL(req.url);
  let body: FaceVerifyRequest = {};
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

    // Check admin_settings
    const { error: adminErr } = await serviceClient.from('admin_settings').select('key').limit(1);
    if (adminErr) missingDbObjects.push('admin_settings');

    // Check face_profiles
    const { error: profileErr } = await serviceClient.from('face_profiles').select('id').limit(1);
    if (profileErr) missingDbObjects.push('face_profiles');

    // Check compare_face_embeddings RPC with real non-zero vectors
    const { error: rpcErr } = await serviceClient.rpc('compare_face_embeddings', {
      v1: [0.1, 0.2],
      v2: [0.1, 0.2],
    });
    if (rpcErr && rpcErr.message.includes('function') && rpcErr.message.includes('does not exist')) {
      missingDbObjects.push('compare_face_embeddings');
    }

    // Check verification_attempts
    const { error: attemptsErr } = await serviceClient.from('verification_attempts').select('id').limit(1);
    if (attemptsErr) missingDbObjects.push('verification_attempts');

    // Check fraud_flags
    const { error: flagsErr } = await serviceClient.from('fraud_flags').select('id').limit(1);
    if (flagsErr) missingDbObjects.push('fraud_flags');

    const edenKey = Deno.env.get('EDENAI_API_KEY') || Deno.env.get('EDEN_AI_API_KEY') || Deno.env.get('FACE_API_KEY');
    if (!edenKey && (Deno.env.get('FACE_MATCHER') || '').toLowerCase() === 'eden_ai') {
      missingSecrets.push('EDENAI_API_KEY');
    }

    return jsonResponse({
      ok: missingDbObjects.length === 0,
      provider: edenKey ? 'eden_ai' : (Deno.env.get('FACE_MATCHER') || 'ondevice'),
      secret_configured: !!edenKey,
      missing_secrets: missingSecrets,
      missing_db_objects: missingDbObjects,
    });
  }

  // 2. Authenticate user
  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;
    const serviceClient = getServiceClient();

    // Rate limit: 10 calls per minute per user
    const rate = await checkRateLimit(userId, 'face-verify', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const embedding = body.embedding;
    const imageBase64 = body.image_base64;
    const context = body.context;
    const assignment_id = body.assignment_id;
    const gps_ok = body.gps_ok;

    const hasEmbedding = Array.isArray(embedding) && embedding.length >= 64;
    const hasPhoto = typeof imageBase64 === 'string' && imageBase64.trim().length > 100;

    if (!hasEmbedding && !hasPhoto) {
      return errorResponse('invalid_payload', 'Either a valid 64+ embedding array or live image_base64 photo must be provided', 400);
    }

    const validContexts = ['login', 'job_start', 'mid_job', 'completion'];
    if (!context || !validContexts.includes(context)) {
      return errorResponse('invalid_context', `Context must be one of: ${validContexts.join(', ')}`, 400);
    }

    let explicitGpsOk = false;
    if (context === 'login') {
      explicitGpsOk = true;
    } else {
      explicitGpsOk = gps_ok ?? false;
    }

    // 3. Fetch face_match_threshold from admin_settings
    let threshold = 0.65;
    const { data: settingRow } = await serviceClient
      .from('admin_settings')
      .select('key, value')
      .eq('key', 'face_match_threshold')
      .maybeSingle();

    if (settingRow?.value !== undefined && settingRow?.value !== null) {
      const val = settingRow.value;
      if (typeof val === 'number') {
        threshold = val;
      } else if (typeof val === 'string') {
        const parsed = parseFloat(val);
        if (!isNaN(parsed) && parsed > 0 && parsed <= 1.0) threshold = parsed;
      } else if (typeof val === 'object' && val !== null) {
        const parsed = parseFloat(String(val));
        if (!isNaN(parsed) && parsed > 0 && parsed <= 1.0) threshold = parsed;
      }
    }

    const edenApiKey = Deno.env.get('EDENAI_API_KEY') || Deno.env.get('EDEN_AI_API_KEY') || Deno.env.get('FACE_API_KEY');
    const explicitMatcherMode = (Deno.env.get('FACE_MATCHER') || '').toLowerCase();
    const matcherMode = explicitMatcherMode || (edenApiKey ? 'eden_ai' : 'ondevice');

    logInfo('face_verify_start', {
      userId,
      context,
      matcherMode,
      hasPhoto,
      hasEmbedding,
      threshold,
      gpsOk: explicitGpsOk,
    });

    let similarity = 0.0;
    let passed = false;
    let providerUsed = 'ondevice_tflite';
    let lastCloudError: EdenCompareResult | null = null;
    let storageError = false;

    if (matcherMode === 'mock') {
      providerUsed = 'mock';
      if (hasEmbedding && embedding![0] < 0) {
        similarity = 0.40;
        passed = false;
      } else {
        similarity = 0.92;
        passed = true;
      }
    } else {
      // 4. Fetch enrolled face profile
      const { data: faceProfile, error: profileErr } = await serviceClient
        .from('face_profiles')
        .select('reference_path, embedding, status')
        .eq('user_id', userId)
        .maybeSingle();

      if (profileErr) {
        logError('face_verify_profile_query_error', { userId, error: profileErr.message });
        return errorResponse('database_error', 'Failed to retrieve enrolled face profile', 500);
      }

      if (!faceProfile || (!faceProfile.embedding && !faceProfile.reference_path)) {
        logInfo('face_verify_no_enrolled_profile', { userId });
        await serviceClient.from('verification_attempts').insert({
          user_id: userId,
          context: context,
          assignment_id: assignment_id || null,
          liveness_ok: true,
          match_score: 0.00,
          gps_ok: explicitGpsOk,
          result: 'fail',
        });

        return jsonResponse({
          result: 'fail',
          match_score: 0.0,
          similarity: 0.0,
          threshold: threshold,
          provider: 'none',
          diagnostic_code: 'not_enrolled',
          message: 'No enrolled face profile found. Please complete face enrollment first.',
          fraud_flag_created: false,
          attempts_count: 1,
          needs_enrollment: true,
        });
      }

      let cloudVerified = false;

      // 5. Try real cloud verification with Eden AI if key is present and live photo is available
      if (edenApiKey && hasPhoto) {
        try {
          const refPath = faceProfile.reference_path || `face-refs/${userId}/ref.jpg`;
          const storageFile = refPath.replace(/^face-refs\//, '');

          logInfo('face_verify_download_reference', { userId, storageFile });
          const { data: refBlob, error: downloadErr } = await serviceClient.storage
            .from('face-refs')
            .download(storageFile);

          if (!downloadErr && refBlob) {
            const refBytes = new Uint8Array(await refBlob.arrayBuffer());
            const liveBytes = base64ToUint8Array(imageBase64!);

            logInfo('face_verify_eden_ai_call', {
              userId,
              refSize: refBytes.length,
              liveSize: liveBytes.length,
            });

            const edenRes = await compareFacesWithEdenAi(edenApiKey, refBytes, liveBytes, 'amazon');
            lastCloudError = edenRes;

            if (edenRes.success) {
              similarity = edenRes.similarity;
              passed = similarity >= threshold;
              providerUsed = `eden_ai_${edenRes.providerUsed}`;
              cloudVerified = true;
              logInfo('face_verify_eden_ai_success', {
                userId,
                similarity,
                passed,
                provider: providerUsed,
              });
            } else {
              logError('face_verify_eden_ai_failed', {
                userId,
                errorCode: edenRes.errorCode,
                error: edenRes.error,
              });
            }
          } else {
            storageError = true;
            logError('face_verify_ref_photo_download_failed', {
              userId,
              error: downloadErr?.message || 'Empty ref photo',
            });
          }
        } catch (cloudErr) {
          logError('face_verify_cloud_exception', {
            userId,
            error: cloudErr instanceof Error ? cloudErr.message : String(cloudErr),
          });
        }
      }

      // 6. Biometric vector fallback: ONLY run if real non-zero embeddings exist for both enrolled and live
      if (!cloudVerified) {
        const hasRealLiveEmbedding = isRealBiometricEmbedding(embedding);
        const hasRealEnrolledEmbedding = isRealBiometricEmbedding(faceProfile.embedding);

        if (hasRealLiveEmbedding && hasRealEnrolledEmbedding) {
          logInfo('face_verify_vector_fallback_start', { userId });
          const { data: simResult, error: simErr } = await serviceClient.rpc('compare_face_embeddings', {
            v1: embedding,
            v2: faceProfile.embedding,
          });

          if (simErr) {
            logError('face_verify_vector_rpc_error', { userId, error: simErr.message });
            return errorResponse('database_error', 'Failed to compare face embeddings on the server', 500);
          }

          similarity = typeof simResult === 'number' ? simResult : 0.0;
          passed = similarity >= threshold;
          providerUsed = edenApiKey ? 'ondevice_tflite_fallback' : 'ondevice_tflite';
          logInfo('face_verify_vector_fallback_success', { userId, similarity, passed });
        } else {
          // If no real embeddings are available, return safe, actionable diagnostic codes
          if (lastCloudError?.errorCode === 'NO_FACE_DETECTED') {
            return errorResponse(
              'no_face_detected',
              'No face detected in verification selfie. Please ensure good lighting and face camera directly.',
              400
            );
          }
          if (lastCloudError?.errorCode === 'EXHAUSTED_CREDITS') {
            return errorResponse(
              'provider_credits_exhausted',
              'Face verification provider credits are currently exhausted. Please contact support.',
              503
            );
          }
          if (lastCloudError?.errorCode === 'INVALID_CREDENTIALS') {
            return errorResponse(
              'invalid_credentials',
              'Face verification provider credentials are not properly configured.',
              500
            );
          }
          if (lastCloudError?.errorCode === 'TIMEOUT') {
            return errorResponse(
              'provider_timeout',
              'Face verification service timed out. Please check your internet connection and retry.',
              504
            );
          }
          if (lastCloudError?.errorCode === 'RATE_LIMITED') {
            return errorResponse(
              'provider_rate_limited',
              'Too many requests to face verification engine. Please wait a minute and retry.',
              429
            );
          }
          if (storageError) {
            return errorResponse(
              'reference_photo_missing',
              'Enrolled reference photo was not found in storage. Please complete face enrollment again.',
              404,
              { needs_enrollment: true }
            );
          }
          if (!edenApiKey && !hasRealLiveEmbedding) {
            return errorResponse(
              'missing_biometric_data',
              'Biometric face vector or reference photo is required for face verification',
              400
            );
          }
          return errorResponse(
            'verification_service_unavailable',
            'Face verification engine temporarily unavailable. Please retry.',
            503
          );
        }
      }
    }

    const matchScorePercent = Math.min(100.0, Math.max(0.0, similarity * 100.0));

    // 7. Query recent consecutive fails for user
    const { data: recentAttempts } = await serviceClient
      .from('verification_attempts')
      .select('result, created_at')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(10);

    let consecutiveFails = 0;
    if (recentAttempts && recentAttempts.length > 0) {
      for (const attempt of recentAttempts) {
        if (attempt.result === 'pass') {
          break;
        }
        if (attempt.result === 'fail' || attempt.result === 'manual_review_required') {
          consecutiveFails++;
        }
      }
    }

    const newConsecutiveFails = passed ? 0 : consecutiveFails + 1;

    let result: 'pass' | 'fail' | 'manual_review_required' = 'fail';
    if (passed) {
      result = 'pass';
    } else if (newConsecutiveFails >= 3) {
      result = 'manual_review_required';
    } else {
      result = 'fail';
    }

    // 8. Insert verification_attempts audit row
    const { error: insertAttemptErr } = await serviceClient
      .from('verification_attempts')
      .insert({
        user_id: userId,
        context: context,
        assignment_id: assignment_id || null,
        liveness_ok: true,
        match_score: matchScorePercent,
        gps_ok: explicitGpsOk,
        result: result,
      });

    if (insertAttemptErr) {
      console.error('[face-verify] verification_attempts insert failed:', insertAttemptErr.message);
    }

    let fraudFlagCreated = false;

    // 9. Create fraud_flags row on 3 consecutive fails
    if (!passed && newConsecutiveFails >= 3) {
      const { error: fraudErr } = await serviceClient
        .from('fraud_flags')
        .insert({
          user_id: userId,
          rule_key: 'repeated_face_fail',
          severity: 'high',
          ref_type: 'verification_attempt',
          evidence: {
            attempts: newConsecutiveFails,
            last_context: context,
            assignment_id: assignment_id || null,
            similarity: similarity,
            threshold: threshold,
            provider: providerUsed,
          },
          status: 'open',
        });

      if (fraudErr) {
        console.error('[face-verify] fraud_flags insert failed:', fraudErr.message);
      } else {
        fraudFlagCreated = true;
        logInfo('fraud_flag_created', { userId, ruleKey: 'repeated_face_fail', attempts: newConsecutiveFails });
      }
    }

    logInfo('face_verify_complete', {
      userId,
      passed,
      result,
      similarity,
      threshold,
      provider: providerUsed,
      consecutiveFails: newConsecutiveFails,
      fraudFlagCreated,
    });

    return jsonResponse({
      result: result,
      match_score: matchScorePercent,
      similarity: similarity,
      threshold: threshold,
      provider: providerUsed,
      message: passed
        ? 'Face identity verified successfully.'
        : result === 'manual_review_required'
        ? 'Three consecutive verification attempts failed. Account requires manual review.'
        : 'Face match score below threshold. Please try again.',
      fraud_flag_created: fraudFlagCreated,
      attempts_count: newConsecutiveFails,
    });

  } catch (err) {
    console.error('[face-verify] Unhandled error:', err instanceof Error ? err.message : String(err));
    return errorResponse('internal_error', 'Internal server error during face verification', 500);
  }
});
