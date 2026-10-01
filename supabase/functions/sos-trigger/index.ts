import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface SosTriggerRequest {
  lat: number;
  lng: number;
  message?: string;
  assignment_id?: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'sos-trigger', 5, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<SosTriggerRequest>(req, ['lat', 'lng']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('sos_trigger_requested', { userId: auth.context!.user.id, lat: validation.data!.lat, lng: validation.data!.lng });

    return errorResponse('not_implemented', 'SOS alert trigger is not implemented yet', 501);
  } catch (err) {
    logError('sos_trigger_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
