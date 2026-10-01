import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface MandiSyncRequest {
  state?: string;
  commodity?: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'mandi-sync', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<MandiSyncRequest>(req, []);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('mandi_sync_requested', { userId: auth.context!.user.id, state: validation.data?.state });

    return errorResponse('not_implemented', 'Mandi price sync is not implemented yet', 501);
  } catch (err) {
    logError('mandi_sync_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
