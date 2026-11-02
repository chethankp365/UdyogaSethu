import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface PaymentReconcileRequest {
  payment_id: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const url = new URL(req.url);
    if (req.method === 'GET' || url.searchParams.get('health') === 'true') {
      const missingSecrets: string[] = [];
      if (!Deno.env.get('RAZORPAY_KEY_ID')) missingSecrets.push('RAZORPAY_KEY_ID');
      if (!Deno.env.get('RAZORPAY_KEY_SECRET')) missingSecrets.push('RAZORPAY_KEY_SECRET');
      return jsonResponse({
        ok: true,
        status: 'healthy',
        missing_secrets: missingSecrets,
      });
    }

    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;
    const user = auth.context!.user;

    const rate = await checkRateLimit(user.id, 'payment-reconcile', 20, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<PaymentReconcileRequest>(req, ['payment_id']);
    if (validation.errorResponse) return validation.errorResponse;

    const { payment_id } = validation.data!;
    const serviceClient = getServiceClient();

    // 1. Fetch payment info with authorization check via SQL RPC
    const { data: payInfoRows, error: infoError } = await serviceClient.rpc(
      'get_payment_reconciliation_info',
      { p_payment_id: payment_id }
    );

    if (infoError || !payInfoRows || payInfoRows.length === 0) {
      logError('reconcile_fetch_failed', infoError);
      return errorResponse('not_found', 'Payment not found or unauthorized', 404);
    }

    const payInfo = payInfoRows[0];

    // Verify authenticated user is payer, payee, or admin
    if (payInfo.payer_id !== user.id && payInfo.payee_id !== user.id) {
      return errorResponse('forbidden', 'Access denied to this payment record', 403);
    }

    // 2. If already finalized, return current status idempotently
    if (['held', 'captured', 'released'].includes(payInfo.status)) {
      return jsonResponse({
        reconciled: true,
        status: payInfo.status,
        payment_id: payInfo.payment_id,
        message: 'Payment already confirmed and finalized in ledger.',
      });
    }

    // 3. For Cash, status remains created/pending until work completion
    if (payInfo.method === 'cash') {
      return jsonResponse({
        reconciled: false,
        status: payInfo.status,
        payment_id: payInfo.payment_id,
        message: 'Cash on completion to be settled upon verified work completion.',
      });
    }

    // 4. Query Razorpay API for Online Gateway (UPI / Card) Orders
    const razorpayOrderId = payInfo.razorpay_order_id;
    if (!razorpayOrderId) {
      return jsonResponse({
        reconciled: false,
        status: payInfo.status,
        payment_id: payInfo.payment_id,
        message: 'No external gateway order reference associated with payment.',
      });
    }

    const keyId = Deno.env.get('RAZORPAY_KEY_ID');
    const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET');

    if (!keyId || !keySecret) {
      logInfo('razorpay_secrets_missing_for_reconcile', {});
      return jsonResponse({
        reconciled: false,
        status: payInfo.status,
        payment_id: payInfo.payment_id,
        message: 'Payment gateway API credentials not configured on server.',
      });
    }

    const basicAuth = btoa(`${keyId}:${keySecret}`);
    const rzpUrl = `https://api.razorpay.com/v1/orders/${encodeURIComponent(razorpayOrderId)}/payments`;

    const rzpRes = await fetch(rzpUrl, {
      method: 'GET',
      headers: {
        'Authorization': `Basic ${basicAuth}`,
        'Content-Type': 'application/json',
      },
    });

    if (!rzpRes.ok) {
      const errText = await rzpRes.text();
      logError('razorpay_order_payments_fetch_failed', { status: rzpRes.status, errText });
      return jsonResponse({
        reconciled: false,
        status: payInfo.status,
        payment_id: payInfo.payment_id,
        message: 'Could not reach banking gateway to verify payment.',
      });
    }

    const rzpData = await rzpRes.json();
    const paymentsList = rzpData.items || [];

    // Find any successfully captured or authorized payment
    const capturedPayment = paymentsList.find(
      (p: { status: string; amount: number }) =>
        (p.status === 'captured' || p.status === 'authorized') &&
        Number(p.amount) === Number(payInfo.amount_paise)
    );

    if (capturedPayment) {
      logInfo('reconciliation_found_captured_payment', {
        paymentId: payInfo.payment_id,
        rzpPaymentId: capturedPayment.id,
      });

      // Update payment to captured / held via server-role
      const { data: updatedPayment, error: recordError } = await serviceClient.rpc(
        'record_payment_success',
        {
          p_payment_id: payInfo.payment_id,
          p_razorpay_payment_id: capturedPayment.id,
          p_signature_verified: true,
        }
      );

      if (recordError) {
        logError('reconcile_record_payment_success_error', recordError);
        return errorResponse('internal_error', 'Failed to update payment status', 500, recordError.message);
      }

      await serviceClient
        .from('payments')
        .update({
          reconciled_at: new Date().toISOString(),
          gateway_response: capturedPayment,
        })
        .eq('id', payInfo.payment_id);

      return jsonResponse({
        reconciled: true,
        status: updatedPayment?.status ?? (payInfo.is_protected ? 'held' : 'captured'),
        payment_id: payInfo.payment_id,
        razorpay_payment_id: capturedPayment.id,
        message: 'Payment verified and confirmed via banking gateway.',
      });
    }

    // Check if there was an explicitly failed payment
    const failedPayment = paymentsList.find((p: { status: string }) => p.status === 'failed');
    if (failedPayment && paymentsList.length === 1) {
      await serviceClient
        .from('payments')
        .update({
          status: 'failed',
          reconciled_at: new Date().toISOString(),
          gateway_response: failedPayment,
        })
        .eq('id', payInfo.payment_id);

      return jsonResponse({
        reconciled: true,
        status: 'failed',
        payment_id: payInfo.payment_id,
        message: 'Payment was declined or failed at banking gateway.',
      });
    }

    return jsonResponse({
      reconciled: false,
      status: payInfo.status,
      payment_id: payInfo.payment_id,
      message: 'Payment is still awaiting completion or authorization.',
    });
  } catch (err) {
    logError('payment_reconcile_unhandled', err);
    return errorResponse('internal_error', 'Internal server error during reconciliation', 500);
  }
});
