import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';
import { getKycProvider } from '../_shared/kyc_provider.ts';

export interface KycStartRequest {
  doc_type: 'aadhaar' | 'pan' | 'driving_licence' | 'voter_id';
  redirect_url?: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;
    const userClient = auth.context!.supabase;
    const serviceClient = getServiceClient();

    const rate = await checkRateLimit(userId, 'kyc-start', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<KycStartRequest>(req, ['doc_type']);
    if (validation.errorResponse) return validation.errorResponse;

    const docType = validation.data!.doc_type;
    const returnUrl = validation.data!.redirect_url ?? 'udyogasethu://kyc/callback';

    // 1. Verify consent exists in consent_logs
    const { data: consent } = await userClient
      .from('consent_logs')
      .select('granted')
      .eq('user_id', userId)
      .eq('consent_type', 'kyc')
      .order('granted_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!consent || consent.granted !== true) {
      logInfo('kyc_start_blocked_no_consent', { userId, docType });
      return errorResponse('consent_required', 'KYC processing consent is required before starting verification.', 403);
    }

    logInfo('kyc_start_initiated', { userId, docType });

    // 2. Initialize provider and start flow
    const provider = getKycProvider();
    const result = await provider.startKyc({
      userId,
      docType,
      redirectUrl: returnUrl,
    });

    // 3. Upsert pending kyc_records row in DB
    const { error: dbErr } = await serviceClient
      .from('kyc_records')
      .upsert({
        user_id: userId,
        doc_type: docType,
        provider: result.provider,
        provider_ref: result.provider_ref,
        status: 'pending',
        updated_at: new Date().toISOString(),
      }, { onConflict: 'user_id,doc_type' });

    if (dbErr) {
      logError('kyc_records_upsert_failed', dbErr, { userId });
    }

    return jsonResponse({
      success: true,
      provider: result.provider,
      provider_ref: result.provider_ref,
      redirect_url: result.redirect_url,
      is_demo_mode: result.is_demo_mode,
      message: 'KYC session initialized successfully.',
    });
  } catch (err) {
    logError('kyc_start_failed', err);
    return errorResponse('internal_error', 'Internal server error during KYC initialization', 500);
  }
});
