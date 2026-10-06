import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';
import { getKycProvider } from '../_shared/kyc_provider.ts';

export interface KycStartRequest {
  doc_type?: 'aadhaar' | 'pan' | 'driving_licence' | 'voter_id';
  redirect_url?: string;
  health?: boolean;
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

    let body: KycStartRequest = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {}

    const url = new URL(req.url);
    const isHealthCheck = body.health === true || url.searchParams.get('health') === 'true';

    // Health check endpoint (signed-in users only)
    if (isHealthCheck) {
      const missingSecrets: string[] = [];
      const missingDbObjects: string[] = [];

      // Check consent_logs table
      const { error: consentErr } = await serviceClient
        .from('consent_logs')
        .select('id')
        .limit(1);
      if (consentErr) {
        missingDbObjects.push('consent_logs');
      }

      // Check kyc_records table
      const { error: kycErr } = await serviceClient
        .from('kyc_records')
        .select('id')
        .limit(1);
      if (kycErr) {
        missingDbObjects.push('kyc_records');
      }

      return jsonResponse({
        ok: missingSecrets.length === 0 && missingDbObjects.length === 0,
        missing_secrets: missingSecrets,
        missing_db_objects: missingDbObjects,
      });
    }

    const rate = await checkRateLimit(userId, 'kyc-start', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const docType = body.doc_type;
    if (!docType || !['aadhaar', 'pan', 'driving_licence', 'voter_id'].includes(docType)) {
      return errorResponse('bad_request', 'Missing or invalid doc_type parameter.', 400);
    }

    const returnUrl = body.redirect_url ?? 'udyogasethu://kyc/callback';

    // 1. Verify consent exists in consent_logs
    const { data: consent, error: consentErr } = await userClient
      .from('consent_logs')
      .select('granted')
      .eq('user_id', userId)
      .eq('purpose', 'kyc')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (consentErr) {
      console.error('[kyc-start] consent query error:', consentErr.message);
    }

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
      console.error('[kyc-start] kyc_records upsert failed:', dbErr.message);
      return errorResponse('db_error', 'Failed to initialize KYC record in database.', 500);
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
    console.error('[kyc-start] Unhandled error:', err instanceof Error ? err.message : String(err));
    return errorResponse('internal_error', 'Internal server error during KYC initialization', 500);
  }
});
