import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface QrVerifyRequest {
  qr_token: string;
  lat?: number;
  lng?: number;
}

function base64UrlDecode(str: string): Uint8Array {
  let b64 = str.replace(/-/g, '+').replace(/_/g, '/');
  while (b64.length % 4) b64 += '=';
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
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

    const scannerUserId = auth.context!.user.id;

    // Rate-limit scanner to 30 verification checks per minute
    const rate = await checkRateLimit(scannerUserId, 'qr-verify', 30, 60);
    if (rate.errorResponse) return rate.errorResponse;

    const validation = await validateBody<QrVerifyRequest>(req, ['qr_token']);
    if (validation.errorResponse) return validation.errorResponse;

    const qrToken = validation.data!.qr_token.trim();
    const parts = qrToken.split('.');
    if (parts.length !== 2) {
      return errorResponse('invalid_token', 'Invalid QR code format. Please scan a valid UdyogaSethu ID code.', 400);
    }

    const [encodedPayload, encodedSig] = parts;
    const signingSecret = Deno.env.get('QR_SIGNING_SECRET');
    if (!signingSecret) {
      logError('qr_secret_missing', 'QR_SIGNING_SECRET is not configured');
      return errorResponse('server_misconfiguration', 'QR verification key is missing', 500);
    }

    const enc = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      enc.encode(signingSecret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    );

    // Constant-time signature verification
    let sigBytes: Uint8Array;
    try {
      sigBytes = base64UrlDecode(encodedSig);
    } catch (_) {
      return errorResponse('invalid_signature', 'This QR code signature is invalid or tampered with.', 400);
    }

    const isValidSig = await crypto.subtle.verify(
      'HMAC',
      key,
      sigBytes,
      enc.encode(encodedPayload)
    );

    if (!isValidSig) {
      logInfo('qr_signature_verification_failed', { scannerUserId });
      return errorResponse('invalid_signature', 'This QR code is invalid or has been tampered with.', 400);
    }

    // Decode and parse payload
    let payload: Record<string, unknown>;
    try {
      const payloadBytes = base64UrlDecode(encodedPayload);
      const payloadString = new TextDecoder().decode(payloadBytes);
      payload = JSON.parse(payloadString);
    } catch (_) {
      return errorResponse('invalid_token', 'Unable to parse QR token payload.', 400);
    }

    const tokenId = payload.tid as string | undefined;
    const exp = Number(payload.exp);
    const purpose = (payload.pur as string | undefined) ?? 'profile';

    if (!tokenId || !exp) {
      return errorResponse('invalid_token', 'Incomplete claims in QR token.', 400);
    }

    // Check expiry timestamp
    const nowSec = Math.floor(Date.now() / 1000);
    if (nowSec > exp) {
      return errorResponse(
        'token_expired',
        'This QR code has expired. Please ask the worker to show an updated QR code.',
        400,
        { expired_at: new Date(exp * 1000).toISOString() }
      );
    }

    // Look up token hash in database for revocation check
    const tokenIdHash = await sha256Hex(tokenId);
    const serviceClient = getServiceClient();

    const { data: tokenRecord, error: dbErr } = await serviceClient
      .from('qr_tokens')
      .select('id, user_id, purpose, expires_at, revoked')
      .eq('token_id_hash', tokenIdHash)
      .maybeSingle();

    if (dbErr || !tokenRecord) {
      logInfo('qr_token_lookup_failed', { tokenIdHash, error: dbErr });
      return errorResponse('token_not_found', 'QR token not found in the verified registry.', 404);
    }

    if (tokenRecord.revoked) {
      return errorResponse(
        'token_revoked',
        'This QR code has been revoked and is no longer valid.',
        400
      );
    }

    if (new Date(tokenRecord.expires_at).getTime() < Date.now()) {
      return errorResponse(
        'token_expired',
        'This QR code has expired. Please ask the worker to refresh their ID card.',
        400
      );
    }

    // Fetch public verification details (returns strictly non-PII fields)
    const { data: pubData, error: rpcErr } = await serviceClient.rpc('get_public_verification', {
      p_user_id: tokenRecord.user_id,
    });

    if (rpcErr || !pubData) {
      logError('get_public_verification_failed', rpcErr);
      return errorResponse('verification_failed', 'Could not load worker verification status.', 500);
    }

    logInfo('qr_verification_success', {
      scannerUserId,
      workerTokenHash: tokenIdHash,
      purpose,
    });

    // Return ONLY public status fields (name initial, badge, level, verification dates, display ID)
    return jsonResponse({
      valid: true,
      purpose: tokenRecord.purpose,
      display_id: pubData.display_id,
      name_initial: pubData.name_initial,
      is_verified_badge: pubData.is_verified_badge == true,
      level: pubData.level ?? 1,
      level_name: pubData.level_name ?? 'Starter',
      kyc_verified_at: pubData.kyc_verified_at,
      face_verified_at: pubData.face_verified_at,
      training_verified_at: pubData.training_verified_at,
      verified_at: new Date().toISOString(),
    });
  } catch (err) {
    logError('qr_verify_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
