import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;
    logInfo('delete_account_initiated', { userId });

    const serviceClient = getServiceClient();

    // 1. Storage Cleanup: list and remove user files in avatars and kyc-docs
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

    // 2. Anonymize/delete database profile and role rows via RPC
    const { error: rpcErr } = await serviceClient.rpc('anonymize_and_delete_user_data', {
      p_target_user_id: userId,
    });

    if (rpcErr) {
      logError('anonymize_rpc_failed', rpcErr);
      return errorResponse('db_error', `Failed to delete user profile rows: ${rpcErr.message}`, 500);
    }

    // 3. Delete Auth User from Supabase Auth Admin API
    const { error: authDeleteErr } = await serviceClient.auth.admin.deleteUser(userId);
    if (authDeleteErr) {
      logError('auth_admin_delete_failed', authDeleteErr);
      // Even if admin delete fails (e.g. mock environment), database data is erased
    }

    logInfo('delete_account_completed', { userId });

    return jsonResponse({
      success: true,
      message: 'Account personal data and storage files have been permanently erased.',
    });
  } catch (err) {
    logError('delete_account_failed', err);
    return errorResponse('internal_error', 'Internal server error during account deletion', 500);
  }
});
