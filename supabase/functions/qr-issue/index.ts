import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse } from '../_shared/response.ts';
import { getUserClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface QrIssueRequest {
  assignment_id: string;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const rate = await checkRateLimit(auth.context!.user.id, 'qr-issue', 20, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<QrIssueRequest>(req, ['assignment_id']);
    if (validation.errorResponse) return validation.errorResponse;

    logInfo('qr_issue_requested', { userId: auth.context!.user.id, assignmentId: validation.data!.assignment_id });

    return errorResponse('not_implemented', 'QR token issuance is not implemented yet', 501);
  } catch (err) {
    logError('qr_issue_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
