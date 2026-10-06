import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';
import { getFaceMatcher } from '../_shared/face_matcher.ts';

export interface FaceEnrollRequest {
  embedding?: number[];
  liveness_passed?: boolean;
  liveness_challenges?: string[];
  health?: boolean;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;
    const serviceClient = getServiceClient();

    let body: FaceEnrollRequest = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {}

    const url = new URL(req.url);
    const isHealthCheck = body.health === true || url.searchParams.get('health') === 'true';

    // Health check endpoint (signed-in users only)
    if (isHealthCheck) {
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

      // Check save_face_embedding RPC
      const { error: rpcErr } = await serviceClient.rpc('save_face_embedding', {
        p_user_id: userId,
        p_embedding: [0.1, 0.2], // dry-run check or check signature
        p_liveness_passed_at: new Date().toISOString(),
        p_matcher_ref: 'health-check',
      });
      if (rpcErr && rpcErr.message.includes('function') && rpcErr.message.includes('does not exist')) {
        missingDbObjects.push('save_face_embedding');
      }

      return jsonResponse({
        ok: missingSecrets.length === 0 && missingDbObjects.length === 0,
        missing_secrets: missingSecrets,
        missing_db_objects: missingDbObjects,
      });
    }

    const rate = await checkRateLimit(userId, 'face-enroll', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const embedding = body.embedding;
    const liveness_passed = body.liveness_passed ?? false;
    const liveness_challenges = body.liveness_challenges;

    if (!Array.isArray(embedding) || embedding.length < 64) {
      return errorResponse('invalid_embedding', 'Embedding vector must be an array of length >= 64', 400);
    }

    if (!liveness_passed) {
      return errorResponse('liveness_failed', 'Liveness verification check failed', 400);
    }

    logInfo('face_enroll_start', {
      userId,
      vectorLength: embedding.length,
      livenessPassed: liveness_passed,
      challengeCount: liveness_challenges?.length || 0,
    });

    const matcher = getFaceMatcher();
    const matchResult = await matcher.match(embedding, liveness_passed);

    if (!matchResult.passed) {
      return errorResponse('match_failed', `Face enrollment failed: ${matchResult.matcherRef}`, 400);
    }

    const { data: profile, error: dbErr } = await serviceClient.rpc('save_face_embedding', {
      p_user_id: userId,
      p_embedding: embedding,
      p_liveness_passed_at: new Date().toISOString(),
      p_matcher_ref: matchResult.matcherRef,
    });

    if (dbErr) {
      console.error('[face-enroll] save_face_embedding failed:', dbErr.message);
      return errorResponse('database_error', 'Failed to save face profile record in database', 500);
    }

    logInfo('face_enroll_success', {
      userId,
      matcherRef: matchResult.matcherRef,
      status: profile?.status || 'verified',
    });

    const mode = (Deno.env.get('FACE_MATCHER') || 'ondevice').toLowerCase();

    return jsonResponse({
      success: true,
      doc_type: 'face',
      status: 'verified',
      matcher_ref: matchResult.matcherRef,
      mode: mode,
      verified_at: new Date().toISOString(),
    });
  } catch (err) {
    console.error('[face-enroll] Unhandled error:', err instanceof Error ? err.message : String(err));
    return errorResponse('internal_error', 'Internal server error during face enrollment', 500);
  }
});
