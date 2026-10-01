import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface SendPushRequest {
  user_id: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'send-push', 30, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<SendPushRequest>(req, ['user_id', 'title', 'body']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('send_push_requested', { targetUserId: validation.data!.user_id });

    return errorResponse('not_implemented', 'Push notification delivery is not implemented yet', 501);
  } catch (err) {
    logError('send_push_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
