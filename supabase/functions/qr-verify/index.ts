import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface QrVerifyRequest {
  qr_token?: string;
  lat?: number;
  lng?: number;
  health?: boolean;
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
    const serviceClient = getServiceClient();

    let body: QrVerifyRequest = {};
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

      // Check qr_tokens table
      const { error: qrErr } = await serviceClient
        .from('qr_tokens')
        .select('id')
        .limit(1);
      if (qrErr) {
        missingDbObjects.push('qr_tokens');
      }

      // Check get_public_verification RPC
      const { error: rpcErr } = await serviceClient.rpc('get_public_verification', {
        p_user_id: scannerUserId,
      });
      // If error mentions function does not exist
      if (rpcErr && rpcErr.message.includes('function') && rpcErr.message.includes('does not exist')) {
        missingDbObjects.push('get_public_verification');
      }

      return jsonResponse({
        ok: missingSecrets.length === 0 && missingDbObjects.length === 0,
        missing_secrets: missingSecrets,
        missing_db_objects: missingDbObjects,
      });
    }

    const qrToken = body.qr_token?.trim();
    if (!qrToken) {
      return errorResponse('bad_request', 'Missing required parameter: qr_token.', 400);
    }

    const parts = qrToken.split('.');
    if (parts.length !== 2) {
      return errorResponse('invalid_token', 'Invalid QR code format. Please scan a valid UdyogaSethu ID code.', 400);
    }

    const [encodedPayload, encodedSig] = parts;
    const signingSecret = Deno.env.get('QR_SIGNING_SECRET');
    if (!signingSecret) {
      console.error('[qr-verify] QR_SIGNING_SECRET is not configured');
      return errorResponse('server_misconfiguration', 'QR verification key is missing on the server.', 500);
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
        'This QR code has expired. Please ask for an updated QR code.',
        400,
        { expired_at: new Date(exp * 1000).toISOString() }
      );
    }

    // Produce Lot Traceability Verification (Available for all signed-in users)
    if (purpose === 'produce_lot' || purpose === 'lot') {
      const lotId = (payload.lot_id ?? payload.lot_number ?? tokenId) as string;
      const listingId = payload.listing_id as string | undefined;

      const { data: traceList, error: traceErr } = await serviceClient.rpc('get_produce_lot_traceability', {
        p_lot_number: lotId,
        p_listing_id: listingId ?? null,
      });

      if (traceErr || !traceList || traceList.length === 0) {
        return errorResponse('produce_lot_not_found', 'Produce lot traceability record not found.', 404);
      }

      const trace = traceList[0];
      return jsonResponse({
        valid: true,
        purpose: 'produce_lot',
        lot_number: trace.lot_number,
        crop_item: trace.crop_item,
        category: trace.category,
        farmer_origin: trace.farmer_origin,
        cluster_village: trace.cluster_village,
        harvest_time: trace.harvest_time,
        harvest_at: trace.harvest_at,
        farming_method: trace.farming_method,
        organic_certification: trace.organic_certification,
        quality_notes: trace.quality_notes,
        price_paise: trace.price_paise,
        unit: trace.unit,
        rating_avg: trace.rating_avg,
        images: trace.images,
        listing_id: trace.listing_id,
      });
    }

    // Rate-limit scanner to 30 verification checks per minute
    const rate = await checkRateLimit(scannerUserId, 'qr-verify', 30, 60);
    if (rate.errorResponse) return rate.errorResponse;

    // Look up token hash in database for revocation & replay check
    const tokenIdHash = await sha256Hex(tokenId);

    const { data: tokenRecord, error: dbErr } = await serviceClient
      .from('qr_tokens')
      .select('id, user_id, purpose, expires_at, revoked, used, assignment_id')
      .eq('token_id_hash', tokenIdHash)
      .maybeSingle();

    if (dbErr || !tokenRecord) {
      console.error('[qr-verify] qr_tokens lookup failed:', dbErr?.message ?? 'not found');
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
        'This QR code has expired. Please ask the worker to refresh their ticket.',
        400
      );
    }

    // Handle Attendance Ticket Verification (Provider, Farmer, or Worker scanning)
    if (purpose === 'ticket' || tokenRecord.purpose === 'ticket') {
      const { data: scanRes, error: scanErr } = await auth.client.rpc('verify_ticket_scan', {
        p_token: qrToken,
        p_provider_lat: typeof body.lat === 'number' ? body.lat : null,
        p_provider_lng: typeof body.lng === 'number' ? body.lng : null,
        p_job_id: body.job_id ?? null,
      });

      if (scanErr) {
        console.error('[qr-verify] verify_ticket_scan RPC error:', scanErr.message);
        return errorResponse('server_error', scanErr.message, 500);
      }

      if (scanRes && scanRes.valid === false) {
        return errorResponse(
          scanRes.error_code ?? 'scan_failed',
          scanRes.error_message ?? 'Verification failed.',
          400,
          {
            error_code: scanRes.error_code,
            scanned_at: scanRes.scanned_at,
            expired_at: scanRes.expired_at,
          }
        );
      }

      logInfo('ticket_attendance_recorded', {
        scannerUserId,
        assignmentId: scanRes?.assignment_id,
        workerId: scanRes?.worker_id,
      });

      return jsonResponse(scanRes);
    }

    // Role Guard per D-VISIBILITY: Worker Digital ID verification is restricted to Job Providers, Farmers, and Admins
    const { data: userRoles } = await serviceClient
      .from('user_roles')
      .select('role')
      .eq('user_id', scannerUserId);

    const isHirerOrAdmin = userRoles?.some((r) => r.role === 'provider' || r.role === 'farmer' || r.role === 'admin');
    if (!isHirerOrAdmin) {
      return errorResponse(
        'unauthorized_role',
        'Only registered Job Providers, Farmers, and Admins are authorized to scan and verify worker credentials.',
        403
      );
    }

    // Default: Digital ID Profile Verification
    const { data: pubData, error: rpcErr } = await serviceClient.rpc('get_public_verification', {
      p_user_id: tokenRecord.user_id,
    });

    if (rpcErr || !pubData) {
      console.error('[qr-verify] get_public_verification failed:', rpcErr?.message);
      return errorResponse('verification_failed', 'Could not load worker verification status from registry.', 500);
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
    console.error('[qr-verify] Unhandled error:', err instanceof Error ? err.message : String(err));
    return errorResponse('internal_error', 'Internal server error during QR verification.', 500);
  }
});
