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

    // Role Guard per D-VISIBILITY: Worker verification is restricted to Job Providers and Admins
    const { data: userRoles, error: rolesErr } = await serviceClient
      .from('user_roles')
      .select('role')
      .eq('user_id', scannerUserId);

    const isProviderOrAdmin = userRoles?.some((r) => r.role === 'provider' || r.role === 'admin');
    if (rolesErr || !isProviderOrAdmin) {
      return errorResponse(
        'unauthorized_role',
        'Only registered Job Providers and Admins are authorized to scan and verify worker credentials.',
        403
      );
    }

    // Rate-limit scanner to 30 verification checks per minute
    const rate = await checkRateLimit(scannerUserId, 'qr-verify', 30, 60);
    if (rate.errorResponse) return rate.errorResponse;

    // Look up token hash in database for revocation & replay check
    const tokenIdHash = await sha256Hex(tokenId);

    const { data: tokenRecord, error: dbErr } = await serviceClient
      .from('qr_tokens')
      .select('id, user_id, purpose, expires_at, revoked, used')
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

    // Handle Attendance Ticket Verification
    if (purpose === 'ticket' || tokenRecord.purpose === 'ticket') {
      // Replay check: Cannot scan the same QR token twice
      if (tokenRecord.used) {
        return errorResponse(
          'token_already_used',
          'This QR ticket has already been used and cannot be scanned again.',
          400
        );
      }

      const { data: existingLog } = await serviceClient
        .from('attendance_logs')
        .select('id')
        .eq('token_id', tokenId)
        .maybeSingle();

      if (existingLog) {
        return errorResponse(
          'token_already_used',
          'This QR ticket has already been scanned for attendance.',
          400
        );
      }

      const assignmentId = (payload.aid ?? payload.assignment_id) as string | undefined;
      if (!assignmentId) {
        return errorResponse('invalid_token', 'Missing assignment identifier in ticket QR token.', 400);
      }

      // Query assignment and parent job
      const { data: assignment, error: aErr } = await serviceClient
        .from('job_assignments')
        .select('id, worker_id, status, booking_code, job_id')
        .eq('id', assignmentId)
        .maybeSingle();

      if (aErr || !assignment) {
        return errorResponse('assignment_not_found', 'Job assignment not found.', 404);
      }

      const { data: job, error: jErr } = await serviceClient
        .from('jobs')
        .select('id, provider_id, title, start_at, est_duration_minutes')
        .eq('id', assignment.job_id)
        .maybeSingle();

      if (jErr || !job) {
        return errorResponse('job_not_found', 'Job posting not found.', 404);
      }

      // Check assignment ownership: belongs to scanning provider (or admin)
      const isAdminUser = userRoles?.some((r) => r.role === 'admin');
      if (job.provider_id !== scannerUserId && !isAdminUser) {
        return errorResponse(
          'unauthorized_provider',
          'This assignment ticket belongs to another job provider.',
          403
        );
      }

      // Status check: must be ticket_issued (or accepted)
      if (assignment.status !== 'ticket_issued' && assignment.status !== 'accepted') {
        return errorResponse(
          'invalid_status',
          `Attendance cannot be recorded. Assignment status is "${assignment.status}" (expected ticket_issued).`,
          400
        );
      }

      // Allowed check-in window: up to 2 hours (120 min) before scheduled start time
      if (job.start_at) {
        const startMs = new Date(job.start_at).getTime();
        const earliestAllowedMs = startMs - (120 * 60 * 1000);
        if (Date.now() < earliestAllowedMs) {
          return errorResponse(
            'too_early',
            'Check-in is only allowed within 2 hours of the scheduled start time.',
            400
          );
        }
      }

      // Record attendance, advance status to arrived, and notify worker
      const { data: attRes, error: attErr } = await serviceClient.rpc('record_ticket_attendance', {
        p_assignment_id: assignmentId,
        p_token_id: tokenId,
        p_lat: typeof body.lat === 'number' ? body.lat : null,
        p_lng: typeof body.lng === 'number' ? body.lng : null,
        p_scanned_by: scannerUserId,
      });

      if (attErr || !attRes) {
        console.error('[qr-verify] record_ticket_attendance failed:', attErr?.message);
        return errorResponse(
          'attendance_record_failed',
          attErr?.message ?? 'Failed to record attendance.',
          400
        );
      }

      logInfo('ticket_attendance_recorded', {
        scannerUserId,
        assignmentId,
        workerId: assignment.worker_id,
      });

      return jsonResponse({
        valid: true,
        purpose: 'ticket',
        status: 'arrived',
        assignment_id: assignmentId,
        booking_code: attRes.booking_code,
        worker_id: attRes.worker_id,
        worker_name: attRes.worker_name,
        worker_avatar: attRes.worker_avatar,
        is_verified_badge: attRes.is_verified_badge === true,
        job_title: attRes.job_title,
        arrived_at: attRes.arrived_at,
        message: 'Worker attendance recorded successfully.',
      });
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
