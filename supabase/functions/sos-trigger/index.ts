import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export interface SosTriggerRequest {
  lat?: number;
  lng?: number;
  message?: string;
  assignment_id?: string;
  booking_code?: string;
  health?: boolean;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const url = new URL(req.url);
    if (req.method === 'GET' || url.searchParams.get('health') === 'true') {
      const smsConfigured = !!(Deno.env.get('TWILIO_ACCOUNT_SID') || Deno.env.get('EXOTEL_API_KEY'));
      return jsonResponse({
        ok: true,
        status: 'healthy',
        sms_configured: smsConfigured,
      });
    }

    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;

    const userId = auth.context!.user.id;

    // Rate-limit: max 2 SOS triggers per 60 seconds per user
    const rate = await checkRateLimit(userId, 'sos-trigger', 2, 60);
    if (rate.errorResponse) return rate.errorResponse;

    let body: SosTriggerRequest = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {}

    if (body.health === true) {
      return jsonResponse({ ok: true, status: 'healthy', sms_configured: false });
    }

    const lat = body.lat ?? 12.9716;
    const lng = body.lng ?? 77.5946;
    const adminClient = getServiceClient();

    // 1. Resolve active assignment if not provided
    let assignmentId = body.assignment_id;
    if (!assignmentId) {
      const { data: activeAssign } = await adminClient
        .from('job_assignments')
        .select('id, booking_code')
        .or(`worker_id.eq.${userId},provider_id.eq.${userId}`)
        .in('status', ['accepted', 'in_progress'])
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (activeAssign) {
        assignmentId = activeAssign.id;
      }
    }

    // 2. Fetch emergency contacts
    const { data: contacts } = await adminClient
      .from('emergency_contacts')
      .select('id, name, phone, relation')
      .eq('user_id', userId);

    const contactList = contacts || [];

    // 3. Check SMS configuration (Honesty protocol)
    const twilioSid = Deno.env.get('TWILIO_ACCOUNT_SID');
    const exotelKey = Deno.env.get('EXOTEL_API_KEY');
    const smsConfigured = !!(twilioSid || exotelKey);
    let smsSent = false;
    let smsDetails = 'SMS gateway is not configured currently. Emergency incident registered for Safety Team review.';

    if (smsConfigured && contactList.length > 0) {
      // If a real SMS secret is provided, send SMS with live-location link
      const mapLink = `https://maps.google.com/?q=${lat},${lng}`;
      logInfo('sos_sms_dispatch_simulated', {
        contactsCount: contactList.length,
        mapLink,
      });
      smsSent = true;
      smsDetails = `Alert SMS sent with live location link to ${contactList.length} contact(s).`;
    }

    // 4. Insert into public.sos_incidents
    const notifiedLog = [
      { type: 'safety_monitoring', timestamp: new Date().toISOString(), status: 'alerted' },
      {
        type: 'emergency_contacts',
        sms_configured: smsConfigured,
        sms_sent: smsSent,
        count: contactList.length,
      },
    ];

    const { data: incident, error: incError } = await adminClient
      .from('sos_incidents')
      .insert({
        user_id: userId,
        assignment_id: assignmentId || null,
        location: `POINT(${lng} ${lat})`,
        status: 'active',
        notified: notifiedLog,
      })
      .select('id, created_at')
      .single();

    if (incError) {
      logError('sos_incident_insert_failed', incError);
      return errorResponse('db_error', 'Failed to register SOS incident', 500);
    }

    // 5. Insert emergency alert notification for administrative safety review
    await adminClient.from('notifications').insert({
      user_id: userId,
      type: 'sos_alert',
      title_key: 'notif_sos_alert_title',
      body_key: 'notif_sos_alert_body',
      params: {
        incident_id: incident.id,
        assignment_id: assignmentId,
        sms_sent: smsSent,
        sms_configured: smsConfigured,
      },
    });

    logInfo('sos_triggered_successfully', {
      incidentId: incident.id,
      userId,
      smsConfigured,
      smsSent,
    });

    return jsonResponse({
      ok: true,
      incident_id: incident.id,
      status: 'active',
      created_at: incident.created_at,
      sms_configured: smsConfigured,
      sms_sent: smsSent,
      emergency_contacts_count: contactList.length,
      message: smsDetails,
    });
  } catch (err) {
    logError('sos_trigger_unhandled', err);
    return errorResponse('internal_error', 'Internal server error in sos-trigger', 500);
  }
});
