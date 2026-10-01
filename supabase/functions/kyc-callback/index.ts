import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { validateBody } from '../_shared/validation.ts';

export interface KycCallbackPayload {
  provider_ref: string;
  status: 'verified' | 'rejected' | 'pending';
  masked_id?: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const signature = req.headers.get('x-webhook-signature') ?? req.headers.get('Authorization');
    if (!signature) {
      return errorResponse('unauthorized', 'Missing webhook signature or authorization', 401);
    }

    const validation = await validateBody<KycCallbackPayload>(req, ['provider_ref', 'status']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('kyc_callback_received', { provider_ref: validation.data!.provider_ref, status: validation.data!.status });

    return errorResponse('not_implemented', 'KYC callback handler is not implemented yet', 501);
  } catch (err) {
    logError('kyc_callback_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
