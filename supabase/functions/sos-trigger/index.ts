import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface SosTriggerRequest {
  lat?: number;
  lng?: number;
  message?: string;
  assignment_id?: string;
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

    const rate = await checkRateLimit(auth.context!.user.id, 'sos-trigger', 5, 60);
    if (rate.errorResponse) return rate.errorResponse;

    let body: SosTriggerRequest = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {}

    if (body.health === true) {
      return jsonResponse({ ok: true, status: 'healthy', missing_secrets: [] });
    }

    if (body.lat === undefined || body.lng === undefined) {
      return errorResponse('validation_error', 'Missing required coordinates: lat, lng', 400);
    }

    logInfo('sos_trigger_requested', { userId: auth.context!.user.id, lat: body.lat, lng: body.lng });

    return errorResponse('not_implemented', 'SOS alert trigger is not implemented yet', 501);
  } catch (err) {
    logError('sos_trigger_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
