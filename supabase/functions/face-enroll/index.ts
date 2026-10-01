import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface FaceEnrollRequest {
  image_base64: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'face-enroll', 5, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<FaceEnrollRequest>(req, ['image_base64']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('face_enroll_requested', { userId: auth.context!.user.id });

    return errorResponse('not_implemented', 'Face enrollment is not implemented yet', 501);
  } catch (err) {
    logError('face_enroll_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
