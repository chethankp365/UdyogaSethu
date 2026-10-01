import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface PaymentCreateOrderRequest {
  ref_type: 'assignment' | 'order' | 'group_order' | 'subscription';
  ref_id: string;
  amount_paise: number;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'payment-create-order', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<PaymentCreateOrderRequest>(req, ['ref_type', 'ref_id', 'amount_paise']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('payment_create_order_requested', {
      userId: auth.context!.user.id,
      refType: validation.data!.ref_type,
      refId: validation.data!.ref_id,
      amountPaise: validation.data!.amount_paise,
    });

    return errorResponse('not_implemented', 'Payment order creation is not implemented yet', 501);
  } catch (err) {
    logError('payment_create_order_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
