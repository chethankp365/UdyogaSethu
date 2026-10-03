import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getServiceClient } from '../_shared/supabase.ts';
import { getKycProvider } from '../_shared/kyc_provider.ts';

export interface KycCallbackPayload {
  provider_ref: string;
  doc_type?: string;
  status: 'verified' | 'rejected' | 'pending';
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    let payload: KycCallbackPayload;
    if (req.method === 'GET') {
      const url = new URL(req.url);
      payload = {
        provider_ref: url.searchParams.get('provider_ref') || '',
        doc_type: url.searchParams.get('doc_type') || 'aadhaar',
        status: (url.searchParams.get('status') as 'verified' | 'rejected' | 'pending') || 'verified',
      };
    } else {
      payload = await req.json();
    }

    if (!payload.provider_ref) {
      return errorResponse('bad_request', 'Missing provider_ref parameter', 400);
    }

    logInfo('kyc_callback_received', { provider_ref: payload.provider_ref, status: payload.status });

    const provider = getKycProvider();
    const verifiedData = await provider.verifyCallback(payload as unknown as Record<string, unknown>);

    // Ensure 12-digit number is never stored in DB or logs
    const safeMaskedId = verifiedData.masked_id.replace(/\b\d{12}\b/g, 'XXXX-XXXX-4321');

    const serviceClient = getServiceClient();

    // 1. Fetch pending kyc_record row
    const { data: existingRecord } = await serviceClient
      .from('kyc_records')
      .select('id, user_id, doc_type')
      .eq('provider_ref', payload.provider_ref)
      .maybeSingle();

    if (!existingRecord) {
      logError('kyc_callback_record_not_found', { provider_ref: payload.provider_ref });
      return errorResponse('not_found', 'KYC reference record not found', 404);
    }

    // 2. Update kyc_records table with masked results ONLY
    const { error: updateErr } = await serviceClient
      .from('kyc_records')
      .update({
        status: verifiedData.status,
        masked_id: safeMaskedId,
        name_masked: verifiedData.name_masked,
        verified_at: verifiedData.verified_at,
        updated_at: new Date().toISOString(),
      })
      .eq('id', existingRecord.id);

    if (updateErr) {
      logError('kyc_callback_update_failed', updateErr);
      return errorResponse('db_error', 'Failed to update KYC verification status', 500);
    }

    // 3. Trigger badge recomputation RPC if available
    try {
      await serviceClient.rpc('recompute_verification_badge', {
        p_user_id: existingRecord.user_id,
      });
    } catch (_) {
      // Ignore if function not present in schema
    }

    logInfo('kyc_callback_completed', {
      user_id: existingRecord.user_id,
      doc_type: existingRecord.doc_type,
      status: verifiedData.status,
      masked_id: safeMaskedId,
    });

    return jsonResponse({
      success: true,
      status: verifiedData.status,
      masked_id: safeMaskedId,
      name_masked: verifiedData.name_masked,
      verified_at: verifiedData.verified_at,
      message: 'KYC verification status processed and updated.',
    });
  } catch (err) {
    logError('kyc_callback_failed', err);
    return errorResponse('internal_error', 'Internal server error processing KYC callback', 500);
  }
});
