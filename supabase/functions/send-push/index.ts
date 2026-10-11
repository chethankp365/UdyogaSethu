import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface SendPushRequest {
  user_id?: string;
  title?: string;
  body?: string;
  data?: Record<string, unknown>;
  health?: boolean;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const url = new URL(req.url);
    if (req.method === 'GET' || url.searchParams.get('health') === 'true') {
      return jsonResponse({
        ok: true,
        status: 'healthy',
        missing_secrets: [],
      });
    }

    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'send-push', 30, 60);
    if (rate.errorResponse) return rate.errorResponse;

    let body: SendPushRequest = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {}

    if (body.health === true) {
      return jsonResponse({ ok: true, status: 'healthy', missing_secrets: [] });
    }

    if (!body.user_id || !body.title || !body.body) {
      return errorResponse('validation_error', 'Missing required fields: user_id, title, body', 400);
    }

    logInfo('send_push_requested', { targetUserId: body.user_id });

    return errorResponse('not_implemented', 'Push notification delivery is not implemented yet', 501);
  } catch (err) {
    logError('send_push_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
