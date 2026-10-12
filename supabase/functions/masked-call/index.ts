import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';
import { getCallProvider } from '../_shared/call_provider.ts';

export interface MaskedCallRequest {
  action?: 'initiate' | 'end';
  recipient_id?: string;
  assignment_id?: string;
  booking_code?: string;
  call_id?: string;
  duration_seconds?: number;
  health?: boolean;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  const provider = getCallProvider();

  try {
    const url = new URL(req.url);
    if (req.method === 'GET' || url.searchParams.get('health') === 'true') {
      return jsonResponse({
        ok: true,
        status: 'healthy',
        provider: provider.name,
        is_demo: provider.isDemo,
      });
    }

    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const callerId = auth.context!.user.id;
    const rate = await checkRateLimit(callerId, 'masked-call', 15, 60);
    if (rate.errorResponse) return rate.errorResponse;

    let body: MaskedCallRequest = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {}

    if (body.health === true) {
      return jsonResponse({
        ok: true,
        status: 'healthy',
        provider: provider.name,
        is_demo: provider.isDemo,
      });
    }

    const serviceClient = getServiceClient();

    // 1. END CALL ACTION
    if (body.action === 'end') {
      if (!body.call_id) {
        return errorResponse('validation_error', 'Missing required call_id', 400);
      }

      await serviceClient
        .from('call_logs')
        .update({
          status: 'completed',
          duration_seconds: Math.max(0, body.duration_seconds || 0),
          ended_at: new Date().toISOString(),
        })
        .eq('id', body.call_id)
        .or(`caller_id.eq.${callerId},recipient_id.eq.${callerId}`);

      await provider.endCall({
        callSid: body.call_id,
        durationSeconds: body.duration_seconds,
      });

      return jsonResponse({ ok: true, status: 'completed' });
    }

    // 2. INITIATE CALL ACTION
    if (!body.recipient_id) {
      return errorResponse('validation_error', 'Missing required parameter: recipient_id', 400);
    }

    if (body.recipient_id === callerId) {
      return errorResponse('invalid_recipient', 'Cannot call yourself', 400);
    }

    // Fetch caller & recipient profiles using service client (to read phone securely on server)
    const { data: callerProfile } = await serviceClient
      .from('profiles')
      .select('id, full_name, phone')
      .eq('id', callerId)
      .maybeSingle();

    const { data: recipientProfile } = await serviceClient
      .from('profiles')
      .select('id, full_name, phone')
      .eq('id', body.recipient_id)
      .maybeSingle();

    if (!recipientProfile) {
      return errorResponse('not_found', 'Recipient user profile not found', 404);
    }

    // Determine booking code
    let bookingCode = body.booking_code;
    if (!bookingCode && body.assignment_id) {
      bookingCode = `BOOK-${body.assignment_id.slice(0, 6).toUpperCase()}`;
    }
    if (!bookingCode) {
      bookingCode = `CALL-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
    }

    // Execute through configured CallProvider
    const callResult = await provider.initiateCall({
      callerId,
      recipientId: body.recipient_id,
      callerPhone: callerProfile?.phone,
      recipientPhone: recipientProfile.phone,
      bookingCode,
      assignmentId: body.assignment_id,
    });

    // Record call log in Supabase
    const { data: logEntry, error: logError } = await serviceClient
      .from('call_logs')
      .insert({
        caller_id: callerId,
        recipient_id: body.recipient_id,
        booking_code: bookingCode,
        assignment_id: body.assignment_id || null,
        provider: callResult.provider,
        status: callResult.status,
        proxy_number: callResult.proxy_display,
        call_sid: callResult.call_sid,
        is_demo: callResult.is_demo,
        notes: callResult.notes || null,
      })
      .select('id')
      .single();

    if (logError) {
      logError('failed_to_log_call', logError);
    }

    logInfo('masked_call_initiated', {
      callerId,
      recipientId: body.recipient_id,
      provider: callResult.provider,
      isDemo: callResult.is_demo,
    });

    // Return strictly masked response to the client (NO raw phone numbers)
    return jsonResponse({
      ok: true,
      call_id: logEntry?.id || callResult.call_sid,
      status: callResult.status,
      proxy_display: callResult.proxy_display,
      is_demo: callResult.is_demo,
      caller_name: callerProfile?.full_name || 'Udyoga User',
      recipient_name: recipientProfile.full_name || 'Verified Contact',
      booking_code: bookingCode,
    });
  } catch (err) {
    logError('masked_call_failed', err);
    return errorResponse('internal_error', 'Internal server error', 500);
  }
});
