import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface KycStartRequest {
  doc_type: 'aadhaar' | 'pan' | 'driving_licence' | 'voter_id';
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'kyc-start', 10, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<KycStartRequest>(req, ['doc_type']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('kyc_start_requested', { userId: auth.context!.user.id, docType: validation.data!.doc_type });

    return errorResponse('not_implemented', 'KYC start feature is not implemented yet', 501);
  } catch (err) {
    logError('kyc_start_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
