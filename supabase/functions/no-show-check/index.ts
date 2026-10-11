import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getServiceClient } from '../_shared/supabase.ts';

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const url = new URL(req.url);
    if (url.searchParams.get('health') === 'true') {
      return jsonResponse({
        ok: true,
        status: 'healthy',
        missing_secrets: [],
      });
    }

    const supabase = getServiceClient();

    logInfo('no_show_check_triggered', { time: new Date().toISOString() });

    // Call idempotent stored procedure check_no_show_assignments
    const { data, error } = await supabase.rpc('check_no_show_assignments');

    if (error) {
      logError('no_show_check_rpc_failed', error);
      return errorResponse('rpc_error', error.message, 500);
    }

    const flaggedCount = Number(data ?? 0);
    logInfo('no_show_check_completed', { flaggedCount });

    return jsonResponse({
      success: true,
      flagged_count: flaggedCount,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    logError('no_show_check_failed', err);
    return errorResponse('internal_error', 'Internal server error in no-show engine', 500);
  }
});
