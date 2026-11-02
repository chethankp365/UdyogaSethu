import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';
import { AiOrchestrator } from './orchestrator.ts';
import { AiAssistRequest } from './types.ts';

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const url = new URL(req.url);

    // 1. Health & Provider Discovery Endpoint (GET only)
    if (req.method === 'GET') {
      const capabilities = AiOrchestrator.getProviderCapabilities();
      const configuredCount = capabilities.filter((c) => c.isAvailable).length;

      let liveProbeResults: Record<string, unknown> | undefined;
      // Live probes invoke upstream provider APIs with keys and must be authenticated
      if (url.searchParams.get('probe') === 'live') {
        const auth = await getUserClient(req);
        if (auth.errorResponse) {
          return auth.errorResponse;
        }
        liveProbeResults = await AiOrchestrator.probeProviders();
      }

      return jsonResponse({
        ok: true,
        status: 'healthy',
        active_providers_count: configuredCount,
        providers: capabilities,
        live_probe: liveProbeResults,
      });
    }

    // 2. Authenticate caller (Supabase Auth JWT)
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;
    const userId = auth.context!.user.id;

    // 2b. Validate caller's authoritative role from database profiles
    let authoritativeRole = 'seeker';
    try {
      const { data: profile } = await auth.context!.supabase
        .from('profiles')
        .select('active_role')
        .eq('id', userId)
        .maybeSingle();

      const dbRole = profile?.active_role?.toLowerCase()?.trim();
      if (dbRole === 'provider' || dbRole === 'farmer' || dbRole === 'seeker') {
        authoritativeRole = dbRole;
      }
    } catch (_) {
      authoritativeRole = 'seeker';
    }

    // 3. Rate limiting (40 requests per minute per user)
    const rate = await checkRateLimit(userId, 'ai-assist', 40, 60);
    if (rate.errorResponse) return rate.errorResponse;

    // 4. Parse and sanitize payload
    const body: AiAssistRequest = await req.json().catch(() => ({}));
    if ((body as any)?.health === true) {
      const capabilities = AiOrchestrator.getProviderCapabilities();
      return jsonResponse({
        ok: true,
        status: 'healthy',
        active_providers_count: capabilities.filter((c) => c.isAvailable).length,
        providers: capabilities,
      });
    }

    if (!body || !body.task) {
      return errorResponse('bad_request', 'Missing required parameter: task', 400);
    }

    // Never trust client supplied role if it differs from database-authoritative role
    const validRoles = ['seeker', 'provider', 'farmer'];
    const requestedRole = body.user_role?.toLowerCase()?.trim();
    const finalRole = (requestedRole && validRoles.includes(requestedRole) && requestedRole === authoritativeRole)
      ? requestedRole
      : authoritativeRole;

    const sanitizedPayload: AiAssistRequest = {
      task: body.task,
      language: body.language || 'en',
      user_role: finalRole,
      spoken_text: body.spoken_text ? String(body.spoken_text).substring(0, 1000) : undefined,
      query: body.query ? String(body.query).substring(0, 1000) : undefined,
      crop: body.crop ? String(body.crop).substring(0, 80) : undefined,
      district: body.district ? String(body.district).substring(0, 80) : undefined,
      symptoms: body.symptoms ? String(body.symptoms).substring(0, 1000) : undefined,
      soil_ph: typeof body.soil_ph === 'number' ? body.soil_ph : undefined,
      soil_type: body.soil_type ? String(body.soil_type).substring(0, 80) : undefined,
      weather_summary: body.weather_summary ? String(body.weather_summary).substring(0, 200) : undefined,
      crop_stage: body.crop_stage ? String(body.crop_stage).substring(0, 80) : undefined,
      irrigation_source: body.irrigation_source ? String(body.irrigation_source).substring(0, 80) : undefined,
      farmer_query: body.farmer_query ? String(body.farmer_query).substring(0, 1000) : undefined,
      conversation_history: Array.isArray(body.conversation_history)
        ? body.conversation_history.slice(-8)
        : undefined,
      context: body.context,
      category: body.category ? String(body.category).substring(0, 80) : undefined,
      title: body.title ? String(body.title).substring(0, 120) : undefined,
      notes: body.notes ? String(body.notes).substring(0, 800) : undefined,
      image_base64: body.image_base64,
      image_mime: body.image_mime || 'image/jpeg',
      audio_base64: body.audio_base64,
      audio_mime: body.audio_mime || 'audio/m4a',
      tts_text: body.tts_text ? String(body.tts_text).substring(0, 1200) : undefined,
      tts_voice: body.tts_voice,
      preferred_provider: body.preferred_provider,
    };

    // Validate image size limit (max 3.5MB base64)
    if (sanitizedPayload.image_base64 && sanitizedPayload.image_base64.length > 3.5 * 1024 * 1024) {
      return errorResponse('payload_too_large', 'Image too large. Please compress before uploading.', 413);
    }

    // Validate audio limits (voice commands are 5-30s max; 1.5MB base64 is ~1.1MB binary)
    if (sanitizedPayload.task === 'voice_stt') {
      if (!sanitizedPayload.audio_base64 || sanitizedPayload.audio_base64.trim().length < 100) {
        return errorResponse('bad_request', 'Missing or empty audio recording for transcription.', 400);
      }
      if (sanitizedPayload.audio_base64.length > 1.5 * 1024 * 1024) {
        return errorResponse('payload_too_large', 'Audio recording exceeds 1.5MB limit.', 413);
      }
      const allowedAudioMimes = ['audio/m4a', 'audio/mp4', 'audio/aac', 'audio/wav', 'audio/webm', 'audio/ogg', 'audio/mpeg'];
      if (sanitizedPayload.audio_mime && !allowedAudioMimes.includes(sanitizedPayload.audio_mime)) {
        return errorResponse('bad_request', 'Unsupported audio format. Allowed: m4a, mp4, aac, wav, webm, ogg, mp3', 400);
      }
    }

    if (sanitizedPayload.task === 'voice_tts') {
      if (!sanitizedPayload.tts_text || !sanitizedPayload.tts_text.trim()) {
        return errorResponse('bad_request', 'Missing text to synthesize for speech playback.', 400);
      }
    }

    // Curated schemes if needed for smallholder farmer advice
    let curatedSchemes: Array<Record<string, unknown>> = [];
    if (sanitizedPayload.task === 'scheme_finder') {
      try {
        const adminClient = getServiceClient();
        const { data } = await adminClient.from('government_schemes').select('*').limit(10);
        if (data && data.length > 0) {
          curatedSchemes = data;
        }
      } catch (err) {
        logError('fetch_schemes_error', err);
      }
    }

    // 5. Execute 5-Provider Orchestration
    logInfo('ai_assist_request_start', {
      task: sanitizedPayload.task,
      userId,
      role: sanitizedPayload.user_role,
      language: sanitizedPayload.language,
    });

    const result = await AiOrchestrator.orchestrate(sanitizedPayload, curatedSchemes);

    logInfo('ai_assist_request_success', {
      task: sanitizedPayload.task,
      provider: result.provider_used,
      model: result.model_used,
      latencyMs: result.latency_ms,
      fallbackOccurred: !!result.fallback_chain,
    });

    return jsonResponse({
      ok: true,
      mode: result.provider_used,
      model: result.model_used,
      latency_ms: result.latency_ms,
      disclaimer: 'AI suggestion powered by UdyogaSethu AI Orchestrator. Always verify official advice.',
      result: result.result,
      audio_base64: result.audio_base64,
      audio_mime: result.audio_mime,
      fallback_chain: result.fallback_chain,
      circuit_breaker: result.circuit_breaker_stats,
    });
  } catch (err) {
    logError('ai_assist_handler_error', err);
    const errMessage = err instanceof Error ? err.message : String(err);

    if (
      errMessage.includes('circuit breaker is OPEN') ||
      errMessage.includes('All AI providers failed') ||
      errMessage.includes('All speech transcription providers failed')
    ) {
      return errorResponse(
        'ai_unavailable',
        'AI assistant services are currently experiencing high load. Please retry in a few moments.',
        503,
      );
    }

    // Mask internal error details from client to avoid leaking infrastructure/secrets
    return errorResponse(
      'server_error',
      'An unexpected error occurred while processing the AI request.',
      500,
    );
  }
});
