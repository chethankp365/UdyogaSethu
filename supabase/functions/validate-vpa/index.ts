import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface ValidateVpaRequest {
  vpa: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    // 1. Signed-in users only
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;
    const user = auth.context!.user;

    // 2. Rate-limited (e.g. 20 requests per minute per user)
    const rate = await checkRateLimit(user.id, 'validate-vpa', 20, 60);
    if (rate.errorResponse) return rate.errorResponse;

    // 3. Validate request payload
    const validation = await validateBody<ValidateVpaRequest>(req, ['vpa']);
    if (validation.errorResponse) return validation.errorResponse;

    const rawVpa = validation.data!.vpa.trim();
    if (!rawVpa || !rawVpa.includes('@')) {
      return errorResponse('bad_request', 'Invalid VPA format. Must contain @ (e.g. name@bank)', 400);
    }

    // Mask VPA in server logs per security & privacy policy (Prompt D6)
    const maskedVpa = rawVpa.replace(/^(.{2})(.*)(@.*)$/, '$1***$3');
    logInfo('vpa_validation_requested', { userId: user.id, vpa: maskedVpa });

    // 4. Retrieve Razorpay credentials from environment secrets (names only: RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET)
    const keyId = Deno.env.get('RAZORPAY_KEY_ID');
    const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET');

    if (!keyId || !keySecret) {
      logInfo('razorpay_credentials_missing', { message: 'RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET secret not set' });
      return jsonResponse({
        success: false,
        bank_verified: false,
        vpa: rawVpa,
        error: 'Razorpay API credentials not configured on server. Please set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in Supabase secrets.',
      });
    }

    // 5. Call Razorpay POST /v1/payments/validate/vpa
    // Store NO third-party data into the database
    const authHeader = `Basic ${btoa(`${keyId}:${keySecret}`)}`;
    const rpResponse = await fetch('https://api.razorpay.com/v1/payments/validate/vpa', {
      method: 'POST',
      headers: {
        'Authorization': authHeader,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ vpa: rawVpa }),
    });

    const rpData = await rpResponse.json();

    if (!rpResponse.ok) {
      const errorMsg = rpData?.error?.description || `Razorpay validation returned HTTP ${rpResponse.status}`;
      logInfo('vpa_validation_bank_rejected', { vpa: maskedVpa, error: errorMsg });
      return jsonResponse({
        success: false,
        bank_verified: false,
        vpa: rawVpa,
        error: errorMsg,
      });
    }

    // Success response from Razorpay
    const isValid = rpData?.success === true || rpData?.valid === true;
    const customerName = rpData?.customer_name || null;

    logInfo('vpa_validation_success', { vpa: maskedVpa, valid: isValid, hasCustomerName: !!customerName });

    return jsonResponse({
      success: true,
      bank_verified: isValid,
      customer_name: customerName,
      vpa: rawVpa,
      error: isValid ? null : 'VPA could not be verified by the issuing bank.',
    });
  } catch (err) {
    logError('vpa_validation_unexpected_error', err);
    return jsonResponse({
      success: false,
      bank_verified: false,
      error: `Validation service error: ${(err as Error)?.message || 'Unexpected failure'}`,
    });
  }
});
