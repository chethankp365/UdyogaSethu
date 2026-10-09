import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getServiceClient } from '../_shared/supabase.ts';

// Constant-time HMAC-SHA256 signature verification
async function verifyRazorpayWebhookSignature(
  rawBody: string,
  signature: string,
  secret: string
): Promise<boolean> {
  if (!signature || !secret || !rawBody) {
    return false;
  }

  try {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );

    const sigBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(rawBody));
    const computedHex = Array.from(new Uint8Array(sigBuffer))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');

    const cleanSig = signature.trim().toLowerCase();
    const cleanComp = computedHex.toLowerCase();

    if (cleanComp.length !== cleanSig.length) {
      return false;
    }

    // Constant-time comparison to prevent timing attacks
    let diff = 0;
    for (let i = 0; i < cleanComp.length; i++) {
      diff |= cleanComp.charCodeAt(i) ^ cleanSig.charCodeAt(i);
    }
    return diff === 0;
  } catch (err) {
    logError('signature_verification_exception', err);
    return false;
  }
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    // 1. Signature Header Check
    const signature = req.headers.get('x-razorpay-signature');
    if (!signature) {
      logError('webhook_missing_signature', { headers: Object.fromEntries(req.headers.entries()) });
      return errorResponse('unauthorized', 'Missing x-razorpay-signature header', 401);
    }

    const webhookSecret = Deno.env.get('RAZORPAY_WEBHOOK_SECRET');
    if (!webhookSecret) {
      logError('webhook_secret_not_configured', {});
      return errorResponse('internal_error', 'RAZORPAY_WEBHOOK_SECRET is not configured on server', 500);
    }

    // 2. Read RAW Body and Verify HMAC-SHA256 Signature
    const rawBody = await req.text();
    const isValid = await verifyRazorpayWebhookSignature(rawBody, signature, webhookSecret);
    if (!isValid) {
      logError('webhook_invalid_signature', { providedSignature: signature });
      return errorResponse('forbidden', 'Invalid Razorpay webhook signature', 403);
    }

    // 3. Parse JSON Body
    const body = JSON.parse(rawBody);
    const eventType: string = body.event ?? '';
    const payload = body.payload ?? {};

    const paymentEntity = payload.payment?.entity;
    const orderEntity = payload.order?.entity;

    const rzpPaymentId: string | null = paymentEntity?.id ?? null;
    const rzpOrderId: string | null = paymentEntity?.order_id ?? orderEntity?.id ?? null;

    // Build unique event identifier for idempotency
    const eventId: string = body.event_id ?? `${eventType}:${rzpPaymentId ?? ''}:${rzpOrderId ?? ''}`;

    logInfo('webhook_verified_and_received', {
      eventType,
      eventId,
      rzpPaymentId,
      rzpOrderId,
    });

    const serviceClient = getServiceClient();

    // 4. Idempotency Check: Prevent Double-Credit / Duplicate Processing
    const { data: existingEvent } = await serviceClient
      .from('payment_webhook_events')
      .select('id, processed_at')
      .eq('event_id', eventId)
      .maybeSingle();

    if (existingEvent) {
      logInfo('webhook_event_already_processed', { eventId, processedAt: existingEvent.processed_at });
      return jsonResponse({ status: 'already_processed', event_id: eventId });
    }

    // 5. Find Target Payment in Database
    let paymentQuery = serviceClient.from('payments').select('*');
    if (rzpOrderId) {
      paymentQuery = paymentQuery.eq('razorpay_order_id', rzpOrderId);
    } else if (rzpPaymentId) {
      paymentQuery = paymentQuery.eq('razorpay_payment_id', rzpPaymentId);
    } else {
      return jsonResponse({ status: 'ignored', message: 'No payment or order reference in payload' });
    }

    const { data: payments, error: findError } = await paymentQuery.limit(1);
    if (findError || !payments || payments.length === 0) {
      logInfo('payment_row_not_found_for_webhook', { rzpOrderId, rzpPaymentId });
      // Record event so we do not spin if unknown
      const { error: insError } = await serviceClient.from('payment_webhook_events').insert({
        event_id: eventId,
        event_type: eventType,
        razorpay_payment_id: rzpPaymentId,
        payload: body,
      });
      if (insError) {
        logError('failed_to_insert_unknown_event', insError);
      }
      return jsonResponse({ status: 'acknowledged', message: 'Payment record not found', event_id: eventId });
    }

    const payment = payments[0];

    // 6. Process Event Types
    if (eventType === 'payment.captured' || eventType === 'order.paid') {
      // Record payment success in database and hold escrow if protected
      const { data: updatedPayment, error: successError } = await serviceClient.rpc(
        'record_payment_success',
        {
          p_payment_id: payment.id,
          p_razorpay_payment_id: rzpPaymentId ?? payment.razorpay_payment_id ?? 'rzp-captured',
          p_signature_verified: true,
        }
      );

      if (successError) {
        logError('webhook_record_payment_success_error', successError);
        return errorResponse('internal_error', 'Failed to update payment status', 500, successError.message);
      }

      // Record event in idempotency table
      const { error: insError } = await serviceClient.from('payment_webhook_events').insert({
        event_id: eventId,
        event_type: eventType,
        razorpay_payment_id: rzpPaymentId,
        payment_id: payment.id,
        payload: body,
      });
      if (insError) {
        logError('failed_to_insert_processed_event', insError);
      }

      logInfo('webhook_payment_captured_and_held', {
        paymentId: payment.id,
        status: updatedPayment?.status,
        protected: payment.protected,
      });

      return jsonResponse({
        status: 'success',
        payment_id: payment.id,
        payment_status: updatedPayment?.status ?? 'captured',
      });
    }

    if (eventType === 'payment.failed') {
      await serviceClient
        .from('payments')
        .update({ status: 'failed' })
        .eq('id', payment.id);

      await serviceClient.from('payment_webhook_events').insert({
        event_id: eventId,
        event_type: eventType,
        razorpay_payment_id: rzpPaymentId,
        payment_id: payment.id,
        payload: body,
      });

      logInfo('webhook_payment_failed_recorded', { paymentId: payment.id });

      return jsonResponse({
        status: 'failed_recorded',
        payment_id: payment.id,
      });
    }

    // Acknowledge other event types
    await serviceClient.from('payment_webhook_events').insert({
      event_id: eventId,
      event_type: eventType,
      razorpay_payment_id: rzpPaymentId,
      payment_id: payment.id,
      payload: body,
    });

    return jsonResponse({ status: 'acknowledged', event_type: eventType });
  } catch (err) {
    logError('payment_webhook_unhandled_exception', err);
    return errorResponse('internal_error', 'Internal server error processing webhook', 500);
  }
});
