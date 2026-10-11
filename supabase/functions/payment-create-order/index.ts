import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface PaymentCreateOrderRequest {
  ref_type: 'assignment' | 'order' | 'group_order' | 'subscription';
  ref_id: string;
  method: 'upi' | 'card' | 'wallet' | 'cash';
  protection_override?: boolean;
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

    const rate = await checkRateLimit(user.id, 'payment-create-order', 30, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<PaymentCreateOrderRequest>(req, ['ref_type', 'ref_id', 'method']);
    if (validation.errorResponse) return validation.errorResponse;

    const { ref_type, ref_id, method, protection_override } = validation.data!;
    const serviceClient = getServiceClient();

    // 1. Compute bill strictly on server from database (never trust client amounts)
    const { data: billRows, error: billError } = await serviceClient.rpc('compute_payment_bill', {
      p_ref_type: ref_type,
      p_ref_id: ref_id,
      p_protection_override: protection_override ?? null,
    });

    if (billError || !billRows || billRows.length === 0) {
      logError('payment_bill_computation_failed', billError);
      return errorResponse('bad_request', 'Failed to compute bill for reference', 400, billError?.message);
    }

    const bill = billRows[0];
    const totalPaise = Number(bill.total_paise);
    const basePaise = Number(bill.base_amount_paise);
    const platformFeePaise = Number(bill.platform_fee_paise);
    const protectionFeePaise = Number(bill.protection_fee_paise);
    const isProtected = Boolean(bill.is_protected);
    const payerId = bill.payer_id;
    const payeeId = bill.payee_id;

    // Verify authenticated user is the payer
    if (payerId && payerId !== user.id) {
      return errorResponse('forbidden', 'You are not the designated payer for this service or order', 403);
    }

    // 2. Generate receipt number via SQL sequence
    const { data: receiptNo, error: receiptError } = await serviceClient.rpc('generate_payment_receipt_no');
    if (receiptError || !receiptNo) {
      return errorResponse('internal_error', 'Failed to generate receipt number', 500);
    }

    logInfo('payment_order_initiation', {
      userId: user.id,
      ref_type,
      ref_id,
      method,
      totalPaise,
      isProtected,
      receiptNo,
    });

    // 3. Handle Cash on Completion
    if (method === 'cash') {
      const { data: payment, error: insertError } = await serviceClient
        .from('payments')
        .insert({
          payer_id: user.id,
          payee_id: payeeId,
          ref_type,
          ref_id,
          amount_paise: totalPaise,
          platform_fee_paise: platformFeePaise,
          method: 'cash',
          status: 'created',
          protected: false,
          receipt_no: receiptNo,
        })
        .select()
        .single();

      if (insertError || !payment) {
        logError('payment_cash_insert_failed', insertError);
        return errorResponse('internal_error', 'Failed to record cash payment', 500, insertError?.message);
      }

      return jsonResponse({
        payment_id: payment.id,
        receipt_no: payment.receipt_no,
        method: 'cash',
        amount_paise: totalPaise,
        status: 'created',
        bill_summary: {
          base_amount_paise: basePaise,
          platform_fee_paise: platformFeePaise,
          protection_fee_paise: protectionFeePaise,
          total_paise: totalPaise,
          is_protected: false,
          description: bill.description,
        },
      });
    }

    // 4. Handle Wallet Balance Payment
    if (method === 'wallet') {
      const { data: balanceRows } = await serviceClient
        .from('wallet_balances')
        .select('available_paise')
        .eq('user_id', user.id)
        .maybeSingle();

      const availablePaise = Number(balanceRows?.available_paise ?? 0);
      if (availablePaise < totalPaise) {
        return errorResponse('insufficient_balance', 'Insufficient wallet balance', 400, {
          required: totalPaise,
          available: availablePaise,
        });
      }

      const { data: payment, error: insertError } = await serviceClient
        .from('payments')
        .insert({
          payer_id: user.id,
          payee_id: payeeId,
          ref_type,
          ref_id,
          amount_paise: totalPaise,
          platform_fee_paise: platformFeePaise,
          method: 'wallet',
          status: 'created',
          protected: isProtected,
          receipt_no: receiptNo,
        })
        .select()
        .single();

      if (insertError || !payment) {
        return errorResponse('internal_error', 'Failed to create payment record', 500);
      }

      // Record success & hold escrow directly
      const { data: updatedPayment, error: recordError } = await serviceClient.rpc('record_payment_success', {
        p_payment_id: payment.id,
        p_razorpay_payment_id: 'wallet-' + crypto.randomUUID().slice(0, 8),
        p_signature_verified: true,
      });

      if (recordError) {
        logError('wallet_payment_record_failed', recordError);
        return errorResponse('internal_error', 'Failed to process wallet payment', 500, recordError.message);
      }

      return jsonResponse({
        payment_id: payment.id,
        receipt_no: payment.receipt_no,
        method: 'wallet',
        amount_paise: totalPaise,
        status: updatedPayment?.status ?? (isProtected ? 'held' : 'captured'),
        bill_summary: {
          base_amount_paise: basePaise,
          platform_fee_paise: platformFeePaise,
          protection_fee_paise: protectionFeePaise,
          total_paise: totalPaise,
          is_protected: isProtected,
          description: bill.description,
        },
      });
    }

    // 5. Handle Online Gateway Checkout (UPI / Card via Razorpay)
    const keyId = Deno.env.get('RAZORPAY_KEY_ID');
    const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET');

    if (!keyId || !keySecret) {
      logError('razorpay_secrets_missing', { keyIdPresent: !!keyId, keySecretPresent: !!keySecret });
      return errorResponse('configuration_error', 'Razorpay credentials not configured on server', 500);
    }

    const basicAuth = btoa(`${keyId}:${keySecret}`);
    const rzpResponse = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${basicAuth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: totalPaise,
        currency: 'INR',
        receipt: receiptNo,
        notes: {
          ref_type,
          ref_id,
          payer_id: user.id,
        },
      }),
    });

    if (!rzpResponse.ok) {
      const errBody = await rzpResponse.text();
      logError('razorpay_order_create_failed', { status: rzpResponse.status, error: errBody });
      return errorResponse('payment_gateway_error', 'Failed to create Razorpay order', 502, errBody);
    }

    const rzpOrder = await rzpResponse.json();
    const razorpayOrderId = rzpOrder.id;

    const { data: payment, error: insertError } = await serviceClient
      .from('payments')
      .insert({
        payer_id: user.id,
        payee_id: payeeId,
        ref_type,
        ref_id,
        amount_paise: totalPaise,
        platform_fee_paise: platformFeePaise,
        method,
        status: 'created',
        protected: isProtected,
        razorpay_order_id: razorpayOrderId,
        receipt_no: receiptNo,
      })
      .select()
      .single();

    if (insertError || !payment) {
      logError('payment_order_insert_failed', insertError);
      return errorResponse('internal_error', 'Failed to create payment tracking record', 500, insertError?.message);
    }

    return jsonResponse({
      order_id: razorpayOrderId,
      key_id: keyId,
      payment_id: payment.id,
      receipt_no: payment.receipt_no,
      amount_paise: totalPaise,
      currency: 'INR',
      status: 'created',
      bill_summary: {
        base_amount_paise: basePaise,
        platform_fee_paise: platformFeePaise,
        protection_fee_paise: protectionFeePaise,
        total_paise: totalPaise,
        is_protected: isProtected,
        description: bill.description,
      },
    });
  } catch (err) {
    logError('payment_create_order_unhandled', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
