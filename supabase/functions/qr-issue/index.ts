import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface QrIssueRequest {
  purpose?: string;
  assignment_id?: string;
  health?: boolean;
}

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

async function sha256Hex(message: string): Promise<string> {
  const enc = new TextEncoder();
  const hashBuffer = await crypto.subtle.digest('SHA-256', enc.encode(message));
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;
    const serviceClient = getServiceClient();

    let body: QrIssueRequest = {};
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

      if (!Deno.env.get('QR_SIGNING_SECRET')) {
        missingSecrets.push('QR_SIGNING_SECRET');
      }

      // Check admin_settings table
      const { error: adminErr } = await serviceClient
        .from('admin_settings')
        .select('key')
        .limit(1);
      if (adminErr) {
        missingDbObjects.push('admin_settings');
      }

      // Check qr_tokens table
      const { error: qrTokensErr } = await serviceClient
        .from('qr_tokens')
        .select('id')
        .limit(1);
      if (qrTokensErr) {
        missingDbObjects.push('qr_tokens');
      }

      return jsonResponse({
        ok: missingSecrets.length === 0 && missingDbObjects.length === 0,
        missing_secrets: missingSecrets,
        missing_db_objects: missingDbObjects,
      });
    }

    // Purpose handling: 'profile' (Digital ID) vs 'ticket' (Job Attendance)
    const purpose = body.purpose ?? 'profile';

    if (purpose === 'profile') {
      const { data: userRoles, error: rolesErr } = await serviceClient
        .from('user_roles')
        .select('role')
        .eq('user_id', userId);

      const hasSeekerRole = userRoles?.some((r) => r.role === 'seeker');
      if (rolesErr || !hasSeekerRole) {
        return errorResponse(
          'unauthorized_role',
          'Only registered Job Seekers are eligible to generate a Digital ID pass.',
          403
        );
      }
    } else if (purpose === 'ticket') {
      if (!body.assignment_id) {
        return errorResponse(
          'bad_request',
          'Missing required parameter: assignment_id for ticket QR issuance.',
          400
        );
      }

      // Verify that the caller is the assigned worker
      const { data: assignment, error: assignErr } = await serviceClient
        .from('job_assignments')
        .select('id, worker_id, status, job_id')
        .eq('id', body.assignment_id)
        .maybeSingle();

      if (assignErr || !assignment) {
        return errorResponse('not_found', 'Job assignment not found.', 404);
      }

      if (assignment.worker_id !== userId) {
        return errorResponse(
          'unauthorized_worker',
          'Only the assigned worker can request an attendance ticket QR code.',
          403
        );
      }

      // Auto-advance accepted to ticket_issued if not already issued
      if (assignment.status === 'accepted') {
        await serviceClient
          .from('job_assignments')
          .update({ status: 'ticket_issued', updated_at: new Date().toISOString() })
          .eq('id', body.assignment_id);
      } else if (assignment.status !== 'ticket_issued') {
        return errorResponse(
          'invalid_status',
          `Cannot generate attendance QR for assignment in status: ${assignment.status}.`,
          400
        );
      }
    }

    // Rate-limit issuance to 60 requests per minute
    const rate = await checkRateLimit(userId, 'qr-issue', 60, 60);
    if (rate.errorResponse) return rate.errorResponse;

    // Read default expiry from admin_settings using correct schema (key, value)
    let expirySeconds = purpose === 'ticket' ? 120 : 300; // 2 minutes for ticket, 5 minutes for profile
    const settingKey = purpose === 'ticket' ? 'qr_ticket_expiry_seconds' : 'qr_expiry_seconds';
    try {
      const { data: settingData } = await serviceClient
        .from('admin_settings')
        .select('value')
        .eq('key', settingKey)
        .maybeSingle();

      if (settingData?.value) {
        const val = Number(settingData.value);
        if (!isNaN(val) && val > 0) {
          expirySeconds = val;
        }
      }
    } catch (e) {
      console.error('[qr-issue] read_qr_expiry_setting_failed:', e instanceof Error ? e.message : String(e));
    }

    const signingSecret = Deno.env.get('QR_SIGNING_SECRET');
    if (!signingSecret) {
      console.error('[qr-issue] QR_SIGNING_SECRET is not configured in Supabase secrets');
      return errorResponse('server_misconfiguration', 'QR signing key is not configured on the server.', 500);
    }

    // Generate random token ID (jti)
    const tokenId = crypto.randomUUID();
    const iat = Math.floor(Date.now() / 1000);
    const exp = iat + expirySeconds;

    // Payload: Contains strictly non-PII token claims (NO user_id, NO phone, NO email)
    const payload = {
      jti: tokenId,
      tid: tokenId,
      pur: purpose,
      iat: iat,
      exp: exp,
      ...(body.assignment_id ? { aid: body.assignment_id, assignment_id: body.assignment_id } : {}),
    };

    const enc = new TextEncoder();
    const payloadJson = JSON.stringify(payload);
    const encodedPayload = base64UrlEncode(enc.encode(payloadJson));

    // Sign with HMAC-SHA256
    const key = await crypto.subtle.importKey(
      'raw',
      enc.encode(signingSecret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );

    const sigBuffer = await crypto.subtle.sign('HMAC', key, enc.encode(encodedPayload));
    const encodedSig = base64UrlEncode(new Uint8Array(sigBuffer));
    const signedToken = `${encodedPayload}.${encodedSig}`;

    // Store token hash server-side for revocation check & replay prevention
    const tokenIdHash = await sha256Hex(tokenId);
    const expiresAt = new Date(exp * 1000).toISOString();

    const { error: insertErr } = await serviceClient.from('qr_tokens').insert({
      token_id_hash: tokenIdHash,
      user_id: userId,
      assignment_id: body.assignment_id ?? null,
      purpose: purpose,
      expires_at: expiresAt,
      revoked: false,
      used: false,
    });

    if (insertErr) {
      console.error('[qr-issue] qr_tokens insert failed:', insertErr.message);
      return errorResponse('db_error', 'Failed to register token for validation in database.', 500);
    }

    logInfo('qr_token_issued', {
      userId,
      purpose,
      expiresInSec: expirySeconds,
    });

    return jsonResponse({
      qr_token: signedToken,
      expires_at: expiresAt,
      expires_in_seconds: expirySeconds,
      token_id_hash: tokenIdHash,
    });
  } catch (err) {
    console.error('[qr-issue] Unhandled error:', err instanceof Error ? err.message : String(err));
    return errorResponse('internal_error', 'Internal server error during QR issuance.', 500);
  }
});
