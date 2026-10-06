import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface QrIssueRequest {
  purpose?: string;
  assignment_id?: string;
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

    // Rate-limit issuance to 30 requests per minute
    const rate = await checkRateLimit(userId, 'qr-issue', 30, 60);
    if (rate.errorResponse) return rate.errorResponse;

    let body: QrIssueRequest = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {}

    const purpose = body.purpose ?? 'profile';
    const serviceClient = getServiceClient();

    // Read default expiry from admin_settings
    let expirySeconds = 300; // 5 minutes default
    try {
      const { data: settingData } = await serviceClient
        .from('admin_settings')
        .select('setting_value')
        .eq('setting_key', 'qr_expiry_seconds')
        .maybeSingle();

      if (settingData?.setting_value) {
        const val = Number(settingData.setting_value);
        if (!isNaN(val) && val > 0) {
          expirySeconds = val;
        }
      }
    } catch (e) {
      logError('read_qr_expiry_setting_failed', e);
    }

    const signingSecret = Deno.env.get('QR_SIGNING_SECRET');
    if (!signingSecret) {
      logError('qr_secret_missing', 'QR_SIGNING_SECRET is not configured in Supabase secrets');
      return errorResponse('server_misconfiguration', 'QR signing key is not configured', 500);
    }

    // Generate random token ID
    const tokenId = crypto.randomUUID();
    const iat = Math.floor(Date.now() / 1000);
    const exp = iat + expirySeconds;

    // Payload: Contains strictly non-PII token claims (NO user_id, NO phone, NO email)
    const payload = {
      tid: tokenId,
      pur: purpose,
      iat: iat,
      exp: exp,
      ...(body.assignment_id ? { aid: body.assignment_id } : {}),
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

    // Store token hash server-side for revocation check
    const tokenIdHash = await sha256Hex(tokenId);
    const expiresAt = new Date(exp * 1000).toISOString();

    const { error: insertErr } = await serviceClient.from('qr_tokens').insert({
      token_id_hash: tokenIdHash,
      user_id: userId,
      purpose: purpose,
      expires_at: expiresAt,
      revoked: false,
    });

    if (insertErr) {
      logError('qr_token_persist_failed', insertErr);
      return errorResponse('db_error', 'Failed to register token for validation', 500);
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
    logError('qr_issue_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
