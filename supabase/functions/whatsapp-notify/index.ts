import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getServiceClient } from '../_shared/supabase.ts';
import { validateBody } from '../_shared/validation.ts';

export interface WhatsAppNotifyRequest {
  recipient_user_id?: string;
  recipient_phone: string;
  event_type: 'booking_confirmed' | 'escrow_deposited' | 'escrow_released' | 'order_shipped' | 'service_alert';
  template_name?: string;
  language_code?: string;
  parameters?: string[];
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const url = new URL(req.url);
    if (req.method === 'GET' || url.searchParams.get('health') === 'true') {
      const token = Deno.env.get('WHATSAPP_CLOUD_API_TOKEN');
      const phoneId = Deno.env.get('WHATSAPP_PHONE_NUMBER_ID');
      return jsonResponse({
        ok: true,
        status: 'healthy',
        provider: 'Meta WhatsApp Business Cloud API',
        configured: Boolean(token && phoneId),
      });
    }

    const validation = await validateBody<WhatsAppNotifyRequest>(req, ['recipient_phone', 'event_type']);
    if (validation.errorResponse) return validation.errorResponse;

    const {
      recipient_user_id,
      recipient_phone,
      event_type,
      template_name = 'job_booking_confirmed_v1',
      language_code = 'en',
      parameters = [],
    } = validation.data!;

    const serviceClient = getServiceClient();

    // 1. Clean and normalize phone number (e.g. +91 98765 43210 -> 919876543210)
    let cleanPhone = recipient_phone.replace(/\D/g, '');
    if (cleanPhone.length === 10) {
      cleanPhone = '91' + cleanPhone; // Default to India country code
    }

    if (cleanPhone.length < 11 || cleanPhone.length > 15) {
      return errorResponse('bad_request', 'Invalid recipient phone number format', 400);
    }

    // 2. Check User Consent & Opt-In if recipient_user_id is provided
    if (recipient_user_id) {
      const { data: consent } = await serviceClient
        .from('consent_logs')
        .select('granted')
        .eq('user_id', recipient_user_id)
        .eq('purpose', 'whatsapp_notifications')
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (consent && consent.granted === false) {
        logInfo('whatsapp_notification_skipped_opt_out', { recipient_user_id, event_type });
        return jsonResponse({
          ok: true,
          status: 'skipped_opt_out',
          message: 'User has opted out of WhatsApp notifications',
        });
      }
    }

    // 3. Read Cloud API Secrets
    const apiToken = Deno.env.get('WHATSAPP_CLOUD_API_TOKEN');
    const phoneNumberId = Deno.env.get('WHATSAPP_PHONE_NUMBER_ID');

    // Safe fallback / sandbox demo mode if credentials are not configured on server
    if (!apiToken || !phoneNumberId) {
      logInfo('whatsapp_notify_demo_simulated', {
        recipient_phone: cleanPhone.slice(0, 4) + 'XXXX' + cleanPhone.slice(-2),
        event_type,
        template_name,
        parameters,
      });

      return jsonResponse({
        ok: true,
        status: 'demo_simulated',
        mode: 'Demo Mode (Simulated)',
        message: 'WhatsApp notification simulated. Configure WHATSAPP_CLOUD_API_TOKEN and WHATSAPP_PHONE_NUMBER_ID for live delivery.',
        recipient_masked: cleanPhone.slice(0, 4) + 'XXXX' + cleanPhone.slice(-2),
        event_type,
      });
    }

    // 4. Send official template message via Meta Graph API v20.0
    const metaApiUrl = `https://graph.facebook.com/v20.0/${phoneNumberId}/messages`;
    const payload = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: cleanPhone,
      type: 'template',
      template: {
        name: template_name,
        language: {
          code: language_code,
        },
        components: parameters.length > 0 ? [
          {
            type: 'body',
            parameters: parameters.map((param) => ({
              type: 'text',
              text: param,
            })),
          },
        ] : undefined,
      },
    };

    const res = await fetch(metaApiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const errText = await res.text();
      logError('whatsapp_api_error', { status: res.status, error: errText });
      return errorResponse('whatsapp_delivery_failed', 'Failed to dispatch WhatsApp notification', 502, errText);
    }

    const data = await res.json();
    logInfo('whatsapp_notification_sent', {
      messageId: data.messages?.[0]?.id,
      recipient_masked: cleanPhone.slice(0, 4) + 'XXXX' + cleanPhone.slice(-2),
      event_type,
    });

    return jsonResponse({
      ok: true,
      status: 'sent',
      message_id: data.messages?.[0]?.id,
    });
  } catch (err) {
    logError('whatsapp_notify_unhandled', err);
    return errorResponse('internal_error', 'Internal server error processing WhatsApp notification', 500);
  }
});
