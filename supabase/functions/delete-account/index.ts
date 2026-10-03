import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    // 1. Verify caller authentication using request JWT header
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;
    const userClient = auth.context!.supabase;
    logInfo('delete_account_initiated', { userId });

    const serviceClient = getServiceClient();

    // 2. Storage Cleanup: list and remove user files in avatars and kyc-docs using service role
    const buckets = ['avatars', 'kyc-docs'];
    for (const bucket of buckets) {
      try {
        const { data: fileList } = await serviceClient.storage.from(bucket).list(userId);
        if (fileList && fileList.length > 0) {
          const filePaths = fileList.map((f) => `${userId}/${f.name}`);
          await serviceClient.storage.from(bucket).remove(filePaths);
          logInfo('deleted_storage_files', { bucket, count: filePaths.length, userId });
        }
      } catch (err) {
        logError('storage_delete_warning', { bucket, userId, error: String(err) });
      }
    }

    // 3. Anonymize/delete database profile and role rows via RPC using user's client (so auth.uid() matches)
    const { error: rpcErr } = await userClient.rpc('anonymize_and_delete_user_data', {
      p_target_user_id: userId,
    });

    if (rpcErr) {
      logError('anonymize_rpc_failed', rpcErr);
      return errorResponse('db_error', 'Failed to delete user profile data. Please try again.', 500);
    }

    // 4. Delete Auth User from Supabase Auth Admin API only after RPC succeeds
    const { error: authDeleteErr } = await serviceClient.auth.admin.deleteUser(userId);
    if (authDeleteErr) {
      logError('auth_admin_delete_failed', authDeleteErr);
      return errorResponse('auth_delete_failed', 'Failed to delete user authentication account. Please try again.', 500);
    }

    logInfo('delete_account_completed', { userId });

    return jsonResponse({
      success: true,
      message: 'Account personal data and storage files have been permanently erased.',
    });
  } catch (err) {
    logError('delete_account_failed', err);
    return errorResponse('internal_error', 'An internal error occurred during account deletion. Please try again.', 500);
  }
});
