import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface FaceVerifyRequest {
  image_base64: string;
  target_user_id: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'face-verify', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<FaceVerifyRequest>(req, ['image_base64', 'target_user_id']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('face_verify_requested', { userId: auth.context!.user.id, targetUserId: validation.data!.target_user_id });

    return errorResponse('not_implemented', 'Face verification is not implemented yet', 501);
  } catch (err) {
    logError('face_verify_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
