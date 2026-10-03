import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';
import { getFaceMatcher } from '../_shared/face_matcher.ts';

export interface FaceEnrollRequest {
  embedding: number[];
  liveness_passed: boolean;
  liveness_challenges?: string[];
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;

    const rate = await checkRateLimit(userId, 'face-enroll', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<FaceEnrollRequest>(req, ['embedding', 'liveness_passed']);
    if (validation.errorResponse) return validation.errorResponse;

    const { embedding, liveness_passed, liveness_challenges } = validation.data!;

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

    const serviceClient = getServiceClient();
    const { data: profile, error: dbErr } = await serviceClient.rpc('save_face_embedding', {
      p_user_id: userId,
      p_embedding: embedding,
      p_liveness_passed_at: new Date().toISOString(),
      p_matcher_ref: matchResult.matcherRef,
    });

    if (dbErr) {
      logError('face_enroll_db_error', dbErr);
      return errorResponse('database_error', 'Failed to save face profile record', 500);
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
    logError('face_enroll_failed', err);
    return errorResponse('internal_error', 'Internal server error during face enrollment', 500);
  }
});
