import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { validateBody } from '../_shared/validation.ts';

export interface PaymentWebhookPayload {
  event: string;
  payload: Record<string, unknown>;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const signature = req.headers.get('x-razorpay-signature') ?? req.headers.get('Authorization');
    if (!signature) {
      return errorResponse('unauthorized', 'Missing Razorpay signature or authorization header', 401);
    }

    const validation = await validateBody<PaymentWebhookPayload>(req, ['event', 'payload']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('payment_webhook_received', { event: validation.data!.event });

    return errorResponse('not_implemented', 'Payment webhook processing is not implemented yet', 501);
  } catch (err) {
    logError('payment_webhook_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
