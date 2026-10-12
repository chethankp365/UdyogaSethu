import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getServiceClient } from '../_shared/supabase.ts';
import { getGoogleAccessToken, sendFcmMessage } from '../_shared/fcm.ts';

// Regional localization templates for push notifications
const NOTIF_TEMPLATES: Record<string, Record<string, string>> = {
  notif_new_applicant_title: {
    en: 'New Job Applicant',
    kn: 'ಹೊಸ ಉದ್ಯೋಗ ಅರ್ಜಿದಾರರು',
    hi: 'नया नौकरी आवेदक',
    te: 'కొత్త ఉద్యోగ దరఖాస్తుదారు',
    ta: 'புதிய வேலை விண்ணப்பதாரர்',
  },
  notif_new_applicant_body: {
    en: '{worker_name} applied for {job_title}',
    kn: '{worker_name} ಅವರು {job_title} ಗೆ ಅರ್ಜಿ ಸಲ್ಲಿಸಿದ್ದಾರೆ',
    hi: '{worker_name} ने {job_title} के लिए आवेदन किया',
    te: '{worker_name} {job_title} కోసం దరఖాస్తు చేసుకున్నారు',
    ta: '{worker_name} {job_title}க்கு விண்ணப்பித்துள்ளார்',
  },
  notif_application_status_title: {
    en: 'Application Update',
    kn: 'ಅರ್ಜಿ ನವೀಕರಣ',
    hi: 'आवेदन अपडेट',
    te: 'దరఖాస్తు నవీకరణ',
    ta: 'விண்ணப்ப புதுப்பிப்பு',
  },
  notif_application_status_body: {
    en: 'Your application for {job_title} was updated: {status}',
    kn: '{job_title} ಗಾಗಿ ನಿಮ್ಮ ಅರ್ಜಿಯನ್ನು ನವೀಕರಿಸಲಾಗಿದೆ: {status}',
    hi: '{job_title} के लिए आपका आवेदन अपडेट किया गया: {status}',
    te: '{job_title} కోసం మీ దరఖాస్తు నవీకరించబడింది: {status}',
    ta: '{job_title}க்கான உங்கள் விண்ணப்பம் புதுப்பிக்கப்பட்டது: {status}',
  },
  notif_assignment_status_title: {
    en: 'Booking Status Update',
    kn: 'ಬುಕಿಂಗ್ ಸ್ಥಿತಿ ನವೀಕರಣ',
    hi: 'बुकिंग स्थिति अपडेट',
    te: 'బుకింగ్ స్థితి నవీకరణ',
    ta: 'முன்பதிவு நிலை புதுப்பிப்பு',
  },
  notif_assignment_status_body: {
    en: 'Booking {booking_code} ({job_title}) is now {status}',
    kn: 'ಬುಕಿಂಗ್ {booking_code} ({job_title}) ಈಗ {status} ಆಗಿದೆ',
    hi: 'बुकिंग {booking_code} ({job_title}) अब {status} है',
    te: 'బుకింగ్ {booking_code} ({job_title}) ఇప్పుడు {status}',
    ta: 'முன்பதிவு {booking_code} ({job_title}) இப்போது {status}',
  },
  notif_new_order_title: {
    en: 'New Farm Produce Order',
    kn: 'ಹೊಸ ಕೃಷಿ ಉತ್ಪನ್ನ ಆದೇಶ',
    hi: 'नया कृषि उत्पाद आदेश',
    te: 'కొత్త వ్యవసాయ ఉత్పత్తుల ఆర్డర్',
    ta: 'புதிய பண்ணை உற்பத்தி ஆர்டர்',
  },
  notif_new_order_body: {
    en: 'New order received: {order_code}',
    kn: 'ಹೊಸ ಆದೇಶ ಸ್ವೀಕರಿಸಲಾಗಿದೆ: {order_code}',
    hi: 'नया आदेश प्राप्त हुआ: {order_code}',
    te: 'కొత్త ఆర్డర్ వచ్చింది: {order_code}',
    ta: 'புதிய ஆர்டர் பெறப்பட்டது: {order_code}',
  },
  notif_order_status_title: {
    en: 'Produce Order Update',
    kn: 'ಉತ್ಪನ್ನ ಆದೇಶ ನವೀಕರಣ',
    hi: 'उत्पाद आदेश अपडेट',
    te: 'ఉత్పత్తి ఆర్డర్ నవీకరణ',
    ta: 'உற்பத்தி ஆர்டர் புதுப்பிப்பு',
  },
  notif_order_status_body: {
    en: 'Your order {order_code} is now {status}',
    kn: 'ನಿಮ್ಮ ಆದೇಶ {order_code} ಈಗ {status} ಆಗಿದೆ',
    hi: 'आपका आदेश {order_code} अब {status} है',
    te: 'మీ ఆర్డర్ {order_code} ఇప్పుడు {status}',
    ta: 'உங்கள் ஆர்டர் {order_code} இப்போது {status}',
  },
  notif_sos_alert_title: {
    en: 'EMERGENCY SOS ALERT',
    kn: 'ತುರ್ತು ಎಸ್‌ಒಎಸ್ ಎಚ್ಚರಿಕೆ',
    hi: 'आपातकालीन एसओएस चेतावनी',
    te: 'అత్యవసర SOS హెచ్చరిక',
    ta: 'அவசர SOS எச்சரிக்கை',
  },
  notif_sos_alert_body: {
    en: 'Emergency SOS incident registered. Safety team alerted.',
    kn: 'ತುರ್ತು ಎಸ್‌ಒಎಸ್ ಘಟನೆ ದಾಖಲಾಗಿದೆ. ಸುರಕ್ಷತಾ ತಂಡವನ್ನು ಎಚ್ಚರಿಸಲಾಗಿದೆ.',
    hi: 'आपातकालीन एसओएस घटना दर्ज की गई। सुरक्षा टीम सतर्क।',
    te: 'అత్యవసర SOS సంఘటన నమోదైంది. భద్రతా బృందం అప్రమత్తమైంది.',
    ta: 'அவசர SOS சம்பவம் பதிவு செய்யப்பட்டது. பாதுகாப்பு குழு எச்சரிக்கப்பட்டது.',
  },
  notif_claim_submitted_title: {
    en: 'Job Protection Claim Submitted',
    kn: 'ಉದ್ಯೋಗ ರಕ್ಷಣೆ ಕ್ಲೈಮ್ ಸಲ್ಲಿಸಲಾಗಿದೆ',
    hi: 'कार्य सुरक्षा दावा प्रस्तुत किया गया',
    te: 'ఉద్యోగ రక్షణ క్లెయిమ్ సమర్పించబడింది',
    ta: 'வேலை பாதுகாப்பு கோரிக்கை சமர்ப்பிக்கப்பட்டது',
  },
  notif_claim_submitted_body: {
    en: 'Claim for {claim_type} submitted for admin review.',
    kn: '{claim_type} ಗಾಗಿ ಕ್ಲೈಮ್ ಅನ್ನು ನಿರ್ವಾಹಕರ ಪರಿಶೀಲನೆಗೆ ಸಲ್ಲಿಸಲಾಗಿದೆ.',
    hi: '{claim_type} के लिए दावा व्यवस्थापक समीक्षा के लिए प्रस्तुत किया गया।',
    te: '{claim_type} కోసం క్లెయిమ్ అడ్మిన్ సమీక్ష కోసం సమర్పించబడింది.',
    ta: '{claim_type}க்கான கோரிக்கை நிர்வாகியின் மதிப்பாய்வுக்கு சமர்ப்பிக்கப்பட்டது.',
  },
};

function formatTemplate(text: string, params: Record<string, unknown>): string {
  let result = text;
  for (const [key, val] of Object.entries(params)) {
    result = result.replaceAll(`{${key}}`, String(val ?? ''));
  }
  return result;
}

function resolveLocalized(
  key: string,
  lang: string,
  params?: Record<string, unknown>
): string {
  const tmpl = NOTIF_TEMPLATES[key];
  if (!tmpl) return key;
  const raw = tmpl[lang] || tmpl['en'] || key;
  return params ? formatTemplate(raw, params) : raw;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const url = new URL(req.url);
    if (req.method === 'GET' || url.searchParams.get('health') === 'true') {
      const hasSecret = !!Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
      return jsonResponse({
        ok: true,
        status: 'healthy',
        fcm_configured: hasSecret,
      });
    }

    let payload: Record<string, unknown> = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        payload = JSON.parse(text);
      }
    } catch (_) {}

    // Check if triggered by database webhook from public.notifications table
    // Webhook structure: { type: 'INSERT', table: 'notifications', record: { user_id, type, title_key, body_key, params } }
    let targetUserId = (payload.user_id as string) || '';
    let title = (payload.title as string) || '';
    let body = (payload.body as string) || '';
    let titleKey = (payload.title_key as string) || '';
    let bodyKey = (payload.body_key as string) || '';
    let params = (payload.params as Record<string, unknown>) || {};
    const dataPayload = (payload.data as Record<string, string>) || {};

    if (payload.record && typeof payload.record === 'object') {
      const rec = payload.record as Record<string, unknown>;
      targetUserId = rec.user_id as string;
      titleKey = rec.title_key as string;
      bodyKey = rec.body_key as string;
      params = (rec.params as Record<string, unknown>) || {};
      dataPayload.type = (rec.type as string) || 'general';
    }

    if (!targetUserId) {
      return errorResponse('validation_error', 'Target user_id is required', 400);
    }

    const adminClient = getServiceClient();

    // 1. Resolve user's preferred language from profiles
    const { data: profile } = await adminClient
      .from('profiles')
      .select('language')
      .eq('id', targetUserId)
      .maybeSingle();

    const userLang = (profile?.language as string) || 'en';

    // 2. Resolve localized title and body
    if (titleKey) {
      title = resolveLocalized(titleKey, userLang, params);
    }
    if (bodyKey) {
      body = resolveLocalized(bodyKey, userLang, params);
    }
    if (!title) title = 'UdyogaSethu Notification';
    if (!body) body = 'You have a new update in UdyogaSethu.';

    // 3. Check for FCM service account secret
    const rawServiceAccount = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
    if (!rawServiceAccount) {
      logInfo('fcm_secret_missing', { targetUserId, title, body });
      return jsonResponse({
        ok: true,
        sent: false,
        reason: 'FCM_SERVICE_ACCOUNT_JSON is not configured in Supabase secrets',
        target_user: targetUserId,
        title,
        body,
      });
    }

    // Parse service account (NEVER LOG OR PRINT IT)
    let serviceAccount: { client_email: string; private_key: string; project_id: string };
    try {
      serviceAccount = JSON.parse(rawServiceAccount);
    } catch (_) {
      logError('fcm_service_account_parse_error', 'Invalid JSON in FCM_SERVICE_ACCOUNT_JSON');
      return errorResponse('config_error', 'Invalid FCM service account secret configuration', 500);
    }

    // 4. Fetch target user's active device tokens
    const { data: deviceTokens } = await adminClient
      .from('device_tokens')
      .select('token, platform')
      .eq('user_id', targetUserId);

    if (!deviceTokens || deviceTokens.length === 0) {
      logInfo('no_device_tokens_found', { targetUserId });
      return jsonResponse({
        ok: true,
        sent: false,
        reason: 'No active device tokens found for target user',
        target_user: targetUserId,
      });
    }

    // 5. Obtain Google OAuth2 Access Token
    const accessToken = await getGoogleAccessToken(
      serviceAccount.client_email,
      serviceAccount.private_key
    );

    // 6. Dispatch FCM messages to each registered device token
    let successCount = 0;
    const tokensToRemove: string[] = [];

    for (const dt of deviceTokens) {
      try {
        const sendResult = await sendFcmMessage(
          accessToken,
          serviceAccount.project_id,
          dt.token,
          title,
          body,
          dataPayload
        );

        if (sendResult.ok) {
          successCount++;
        } else if (sendResult.unregistered) {
          tokensToRemove.push(dt.token);
        }
      } catch (err) {
        logError('fcm_token_send_error', err);
      }
    }

    // Clean up stale/unregistered tokens
    if (tokensToRemove.length > 0) {
      await adminClient
        .from('device_tokens')
        .delete()
        .in('token', tokensToRemove);
      logInfo('stale_device_tokens_removed', { count: tokensToRemove.length });
    }

    logInfo('send_push_completed', {
      targetUserId,
      tokensTotal: deviceTokens.length,
      successCount,
    });

    return jsonResponse({
      ok: true,
      sent: successCount > 0,
      tokens_count: deviceTokens.length,
      success_count: successCount,
      title,
      body,
    });
  } catch (err) {
    logError('send_push_unhandled', err);
    return errorResponse('internal_error', 'Internal server error in send-push', 500);
  }
});
