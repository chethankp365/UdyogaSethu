import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface MaskedCallRequest {
  recipient_id: string;
  assignment_id?: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'masked-call', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<MaskedCallRequest>(req, ['recipient_id']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('masked_call_requested', { userId: auth.context!.user.id, recipientId: validation.data!.recipient_id });

    return errorResponse('not_implemented', 'Masked calling is not implemented yet', 501);
  } catch (err) {
    logError('masked_call_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
