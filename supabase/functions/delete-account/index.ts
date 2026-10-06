import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';

export interface DeleteAccountRequest {
  health?: boolean;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    // 1. Verify caller authentication using request JWT header
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;
    const userClient = auth.context!.supabase;
    const serviceClient = getServiceClient();

    let body: DeleteAccountRequest = {};
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

      // Check anonymize_and_delete_user_data RPC
      const { error: rpcErr } = await serviceClient.rpc('anonymize_and_delete_user_data', {
        p_target_user_id: '00000000-0000-0000-0000-000000000000',
      });
      if (rpcErr && rpcErr.message.includes('function') && rpcErr.message.includes('does not exist')) {
        missingDbObjects.push('anonymize_and_delete_user_data');
      }

      return jsonResponse({
        ok: missingSecrets.length === 0 && missingDbObjects.length === 0,
        missing_secrets: missingSecrets,
        missing_db_objects: missingDbObjects,
      });
    }

    logInfo('delete_account_initiated', { userId });

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
        console.error(`[delete-account] storage cleanup warning for ${bucket}:`, err instanceof Error ? err.message : String(err));
      }
    }

    // 3. Anonymize/delete database profile and role rows via RPC using user's client
    const { error: rpcErr } = await userClient.rpc('anonymize_and_delete_user_data', {
      p_target_user_id: userId,
    });

    if (rpcErr) {
      console.error('[delete-account] anonymize_and_delete_user_data failed:', rpcErr.message);
      return errorResponse('db_error', 'Failed to delete user profile data. Please try again.', 500);
    }

    // 4. Delete Auth User from Supabase Auth Admin API only after RPC succeeds
    const { error: authDeleteErr } = await serviceClient.auth.admin.deleteUser(userId);
    if (authDeleteErr) {
      console.error('[delete-account] auth admin deleteUser failed:', authDeleteErr.message);
      return errorResponse('auth_delete_failed', 'Failed to delete user authentication account. Please try again.', 500);
    }

    logInfo('delete_account_completed', { userId });

    return jsonResponse({
      success: true,
      message: 'Account personal data and storage files have been permanently erased.',
    });
  } catch (err) {
    console.error('[delete-account] Unhandled error:', err instanceof Error ? err.message : String(err));
    return errorResponse('internal_error', 'An internal error occurred during account deletion. Please try again.', 500);
  }
});
