import { logError, logInfo } from '../_shared/logger.ts';
import { circuitBreakers } from './circuit_breaker.ts';
import { DeepgramProvider } from './providers/deepgram.ts';
import { GeminiProvider } from './providers/gemini.ts';
import { GroqProvider } from './providers/groq.ts';
import { HuggingFaceProvider } from './providers/huggingface.ts';
import { OpenRouterProvider } from './providers/openrouter.ts';
import {
  AiAssistRequest,
  LANGUAGE_NAMES,
  OrchestrationResult,
  ProviderCapability,
  ProviderId,
} from './types.ts';

export class AiOrchestrator {
  /**
   * Return capability metadata and configuration status for all 5 providers
   * WITHOUT exposing secret keys.
   */
  static getProviderCapabilities(): ProviderCapability[] {
    return [
      {
        id: 'deepgram',
        name: 'Deepgram Nova-2 & Aura',
        isAvailable: DeepgramProvider.isConfigured() && circuitBreakers.isAvailable('deepgram'),
        supportsStreaming: true,
        supportsMultimodal: false,
        supportsTts: true,
        supportsStt: true,
        primaryRole: 'Low-latency Speech-to-Text and Natural Neural Voice Synthesis',
      },
      {
        id: 'groq',
        name: 'Groq LPU Inference (Llama 3.1 & Whisper)',
        isAvailable: GroqProvider.isConfigured() && circuitBreakers.isAvailable('groq'),
        supportsStreaming: true,
        supportsMultimodal: false,
        supportsTts: false,
        supportsStt: true,
        primaryRole: 'Fast Primary LLM and Multilingual Indic Whisper STT (<400ms)',
      },
      {
        id: 'openrouter',
        name: 'OpenRouter Multi-Model Routing',
        isAvailable: OpenRouterProvider.isConfigured() && circuitBreakers.isAvailable('openrouter'),
        supportsStreaming: true,
        supportsMultimodal: true,
        supportsTts: false,
        supportsStt: false,
        primaryRole: 'Dynamic Model Routing and Multi-Cloud Resilient Fallback Layer',
      },
      {
        id: 'gemini',
        name: 'Google Gemini (1.5 Flash)',
        isAvailable: GeminiProvider.isConfigured() && circuitBreakers.isAvailable('gemini'),
        supportsStreaming: true,
        supportsMultimodal: true,
        supportsTts: false,
        supportsStt: true,
        primaryRole: 'Advanced Multilingual Reasoning, Multimodal Camera & Audio Understanding',
      },
      {
        id: 'huggingface',
        name: 'Hugging Face Inference (BART-MNLI)',
        isAvailable: HuggingFaceProvider.isConfigured() && circuitBreakers.isAvailable('huggingface'),
        supportsStreaming: false,
        supportsMultimodal: false,
        supportsTts: false,
        supportsStt: false,
        primaryRole: 'Specialist Zero-Shot Intent Classification and Semantic Scoring',
      },
    ];
  }

  /**
   * Safe, minimal live provider diagnostic probe.
   * Runs a strictly bounded minimal test (max 5-10 tokens) against each configured provider
   * to verify actual API endpoint availability, credentials, and model IDs.
   * NEVER exposes secrets, never accepts arbitrary user prompts.
   */
  static async probeProviders(): Promise<Record<ProviderId, {
    status: 'PASS' | 'FAIL' | 'NOT_CONFIGURED';
    latency_ms?: number;
    model?: string;
    error?: string;
    details?: string;
  }>> {
    const results: Record<string, any> = {};

    // 1. Probe Groq
    if (GroqProvider.isConfigured()) {
      const t0 = Date.now();
      try {
        const res = await GroqProvider.completeChat(
          'Output valid JSON: {"ping": "pong"}',
          'ping',
          { maxTokens: 15, requireJson: true },
        );
        results.groq = {
          status: 'PASS',
          latency_ms: Date.now() - t0,
          model: res.model,
        };
      } catch (err) {
        let available: string[] = [];
        try {
          const mRes = await fetch('https://api.groq.com/openai/v1/models', {
            headers: { 'Authorization': `Bearer ${Deno.env.get('GROQ_API_KEY')}` },
          });
          const mData = await mRes.json();
          available = (mData?.data || []).map((m: any) => m.id);
        } catch (_) {}

        results.groq = {
          status: 'FAIL',
          latency_ms: Date.now() - t0,
          error: (err instanceof Error ? err.message : String(err)).replace(/Bearer\s+[A-Za-z0-9_\-\.]+/gi, 'Bearer [REDACTED]'),
          available_models: available,
        };
      }
    } else {
      results.groq = { status: 'NOT_CONFIGURED' };
    }

    // 2. Probe Gemini
    if (GeminiProvider.isConfigured()) {
      const t0 = Date.now();
      try {
        const res = await GeminiProvider.generateContent(
          'Output valid JSON: {"ping": "pong"}',
          'ping',
          { maxOutputTokens: 15 },
        );
        results.gemini = {
          status: 'PASS',
          latency_ms: Date.now() - t0,
          model: res.model,
        };
      } catch (err) {
        let available: string[] = [];
        try {
          const mRes = await fetch('https://generativelanguage.googleapis.com/v1beta/models', {
            headers: { 'x-goog-api-key': Deno.env.get('GEMINI_API_KEY') || '' },
          });
          const mData = await mRes.json();
          available = (mData?.models || []).map((m: any) => (m.name || '').replace('models/', ''));
        } catch (_) {}

        results.gemini = {
          status: 'FAIL',
          latency_ms: Date.now() - t0,
          error: (err instanceof Error ? err.message : String(err)).replace(/key=[A-Za-z0-9_\-\.]+/gi, 'key=[REDACTED]'),
          available_models: available.slice(0, 10),
        };
      }
    } else {
      results.gemini = { status: 'NOT_CONFIGURED' };
    }

    // 3. Probe OpenRouter
    if (OpenRouterProvider.isConfigured()) {
      const t0 = Date.now();
      try {
        const res = await OpenRouterProvider.completeChat(
          'Output valid JSON: {"ping": "pong"}',
          'ping',
          { maxTokens: 15, requireJson: true },
        );
        results.openrouter = {
          status: 'PASS',
          latency_ms: Date.now() - t0,
          model: res.model,
        };
      } catch (err) {
        results.openrouter = {
          status: 'FAIL',
          latency_ms: Date.now() - t0,
          error: (err instanceof Error ? err.message : String(err)).replace(/Bearer\s+[A-Za-z0-9_\-\.]+/gi, 'Bearer [REDACTED]'),
        };
      }
    } else {
      results.openrouter = { status: 'NOT_CONFIGURED' };
    }

    // 4. Probe Deepgram (TTS synthesis and STT transcription)
    if (DeepgramProvider.isConfigured()) {
      const t0 = Date.now();
      try {
        const ttsRes = await DeepgramProvider.synthesizeSpeech('OK', { voice: 'aura-asteria-en' });
        
        // Also test Nova-2 STT with minimal valid WAV audio
        let sttStatus = 'not_verified';
        try {
          const minimalWav = new Uint8Array([
            0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45,
            0x66, 0x6d, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
            0x40, 0x1f, 0x00, 0x00, 0x80, 0x3e, 0x00, 0x00, 0x02, 0x00, 0x10, 0x00,
            0x64, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00, 0x00,
          ]);
          await DeepgramProvider.transcribeAudio(minimalWav, 'audio/wav', 'en');
          sttStatus = 'PASS (nova-2)';
        } catch (sttErr) {
          sttStatus = `STT note: ${String(sttErr).substring(0, 50)}`;
        }

        results.deepgram = {
          status: 'PASS',
          latency_ms: Date.now() - t0,
          model: 'aura-asteria-en / nova-2',
          details: `TTS: ${ttsRes.audioBase64.length} base64 chars | STT: ${sttStatus}`,
        };
      } catch (err) {
        results.deepgram = {
          status: 'FAIL',
          latency_ms: Date.now() - t0,
          error: (err instanceof Error ? err.message : String(err)).replace(/Token\s+[A-Za-z0-9_\-\.]+/gi, 'Token [REDACTED]'),
        };
      }
    } else {
      results.deepgram = { status: 'NOT_CONFIGURED' };
    }

    // 5. Probe Hugging Face
    if (HuggingFaceProvider.isConfigured()) {
      const t0 = Date.now();
      try {
        const res = await HuggingFaceProvider.classifyZeroShot('hello', ['greeting', 'other']);
        results.huggingface = {
          status: 'PASS',
          latency_ms: Date.now() - t0,
          model: res.model,
          details: `Top label: ${res.topLabel} (score: ${res.topScore.toFixed(2)})`,
        };
      } catch (err) {
        results.huggingface = {
          status: 'FAIL',
          latency_ms: Date.now() - t0,
          error: (err instanceof Error ? err.message : String(err)).replace(/Bearer\s+[A-Za-z0-9_\-\.]+/gi, 'Bearer [REDACTED]'),
        };
      }
    } else {
      results.huggingface = { status: 'NOT_CONFIGURED' };
    }

    return results as any;
  }


  /**
   * Build base prompt & JSON schema based on the application task.
   */
  static buildPromptConfig(payload: AiAssistRequest, curatedSchemes?: Array<Record<string, unknown>>) {
    const langCode = (payload.language || 'en').toLowerCase().substring(0, 2);
    const langName = LANGUAGE_NAMES[langCode] || 'English';

    const baseInstructions = `You are the official AI intelligence engine for UdyogaSethu, India's trust-first platform connecting informal workers, job providers, and smallholder farmers.
Strict Rules:
1. Output MUST be valid, well-formed JSON matching the required schema.
2. The user's preferred language is ${langName} (${langCode}). All user-facing text, spoken replies, and descriptions MUST be in ${langName}.
3. Be completely realistic, respectful, practical, and grounded in Indian context (Karnataka, South & Rural India).
4. NEVER invent fake government schemes, fake subsidies, or false promises.
5. If medical, pesticide or chemical advice is involved, always advise confirmation with a local Raitha Samparka Kendra (RSK) or certified agronomist.`;

    let prompt = '';
    let jsonSchema: Record<string, unknown> = {};

    switch (payload.task) {
      case 'pest_diagnosis': {
        prompt = `Task: Agricultural Pest & Plant Disease Diagnosis using leaf/crop observation.
Crop: ${payload.crop || 'Field crop'}
District / Region: ${payload.district || 'Karnataka, India'}
Reported Symptoms: ${payload.symptoms || 'Visual observation of attached photo'}
Analyze the symptoms and provide likely cause, confidence level, organic/natural remedies (IPM), cautious chemical advice (if needed), prevention tips, and an expert disclaimer.
Return JSON with keys: likely_cause, confidence_level, symptoms_analysis, organic_remedies (array), chemical_options, prevention_tips (array), expert_warning.`;

        jsonSchema = {
          type: 'OBJECT',
          properties: {
            likely_cause: { type: 'STRING' },
            confidence_level: { type: 'STRING' },
            symptoms_analysis: { type: 'STRING' },
            organic_remedies: { type: 'ARRAY', items: { type: 'STRING' } },
            chemical_options: { type: 'STRING' },
            prevention_tips: { type: 'ARRAY', items: { type: 'STRING' } },
            expert_warning: { type: 'STRING' },
          },
          required: ['likely_cause', 'organic_remedies', 'expert_warning'],
        };
        break;
      }

      case 'soil_advice': {
        prompt = `Task: Soil health advisory and fertilizer/amendment planning.
Soil pH: ${payload.soil_ph !== undefined ? payload.soil_ph : 'Not specified'}
Soil Type: ${payload.soil_type || 'Red loamy / Black cotton'}
Intended Crop: ${payload.crop || 'Field vegetables & crops'}
District: ${payload.district || 'Karnataka, India'}
Examine the soil data and provide pH assessment, organic amendments, recommended crops, nutrient management tips, and an expert note.
Return JSON with keys: ph_assessment, organic_amendments (array), recommended_crops (array), nutrient_management (array), expert_note.`;

        jsonSchema = {
          type: 'OBJECT',
          properties: {
            ph_assessment: { type: 'STRING' },
            organic_amendments: { type: 'ARRAY', items: { type: 'STRING' } },
            recommended_crops: { type: 'ARRAY', items: { type: 'STRING' } },
            nutrient_management: { type: 'ARRAY', items: { type: 'STRING' } },
            expert_note: { type: 'STRING' },
          },
          required: ['ph_assessment', 'organic_amendments', 'recommended_crops'],
        };
        break;
      }

      case 'irrigation_plan': {
        prompt = `Task: Crop irrigation scheduling and water conservation.
Crop: ${payload.crop || 'General Field Crop'}
Growth Stage: ${payload.crop_stage || 'Vegetative'}
Irrigation Source: ${payload.irrigation_source || 'Borewell / Drip'}
Weather Summary: ${payload.weather_summary || 'Warm and dry'}
District: ${payload.district || 'Karnataka, India'}
Provide optimal watering frequency, best time of day, drip run duration, rainfall pause rule, and water-saving tips.
Return JSON with keys: watering_frequency, best_time_of_day, drip_duration_hours, weather_adjustments, water_saving_tips (array), expert_note.`;

        jsonSchema = {
          type: 'OBJECT',
          properties: {
            watering_frequency: { type: 'STRING' },
            best_time_of_day: { type: 'STRING' },
            drip_duration_hours: { type: 'STRING' },
            weather_adjustments: { type: 'STRING' },
            water_saving_tips: { type: 'ARRAY', items: { type: 'STRING' } },
            expert_note: { type: 'STRING' },
          },
          required: ['watering_frequency', 'best_time_of_day', 'water_saving_tips'],
        };
        break;
      }

      case 'price_advice': {
        prompt = `Task: Mandi pricing, APMC arrivals, and marketing strategy.
Crop: ${payload.crop || 'Vegetables / Produce'}
District: ${payload.district || 'Karnataka, India'}
Query: ${payload.farmer_query || 'Best time and channel to sell produce'}
Provide realistic price outlook, direct community group sale vs APMC advice, grading and sorting tips, and advisory note.
Return JSON with keys: market_outlook, selling_channels (array), grading_tips (array), advisory_note.`;

        jsonSchema = {
          type: 'OBJECT',
          properties: {
            market_outlook: { type: 'STRING' },
            selling_channels: { type: 'ARRAY', items: { type: 'STRING' } },
            grading_tips: { type: 'ARRAY', items: { type: 'STRING' } },
            advisory_note: { type: 'STRING' },
          },
          required: ['market_outlook', 'selling_channels'],
        };
        break;
      }

      case 'scheme_finder': {
        const schemesContext = (curatedSchemes || [])
          .map((s) => `- ${s.name_en} (${s.official_url}): ${s.short_description_en}`)
          .join('\n');

        prompt = `Task: Match official government agriculture schemes for a smallholder farmer.
District: ${payload.district || 'Karnataka'}
Farmer Query: ${payload.farmer_query || 'Government subsidies and credit support'}
Curated Official Schemes:
${schemesContext}
Recommend only relevant schemes from the curated list or verified central schemes (PM-KISAN, PMFBY, KUSUM), explain how each helps, and emphasize applying exclusively via official portals.
Return JSON with keys: matched_schemes (array of {name, official_url, how_it_helps, eligibility_hint}), application_advice, disclaimer.`;

        jsonSchema = {
          type: 'OBJECT',
          properties: {
            matched_schemes: {
              type: 'ARRAY',
              items: {
                type: 'OBJECT',
                properties: {
                  name: { type: 'STRING' },
                  official_url: { type: 'STRING' },
                  how_it_helps: { type: 'STRING' },
                  eligibility_hint: { type: 'STRING' },
                },
                required: ['name', 'official_url', 'how_it_helps'],
              },
            },
            application_advice: { type: 'STRING' },
            disclaimer: { type: 'STRING' },
          },
          required: ['matched_schemes', 'disclaimer'],
        };
        break;
      }

      case 'voice_intent':
      case 'assistant_query': {
        const userText = payload.spoken_text || payload.query || '';
        const userRole = payload.user_role || 'seeker';
        const historyStr = (payload.conversation_history || [])
          .map((h) => `${h.role}: ${h.text}`)
          .join('\n');

        prompt = `Task: Natural Language Voice Assistant Intent Extraction & Structured Execution.
User Role: ${userRole}
Spoken Query: "${userText}"
User Preferred Language: ${langName} (${langCode})
Conversation History:
${historyStr || 'None'}

Multilingual Response Rules:
1. "reply_text" MUST be generated in ${langName} using its official native script (e.g., Kannada script for kn, Devanagari for hi/mr, Telugu script for te, Tamil script for ta, Bengali script for bn, Odia script for or, Latin for en).
2. Do NOT merely transliterate English into the regional script. Provide simple, natural, conversational phrasing tailored for informal workers, homemakers, and farmers.
3. Understand mixed-language speech (e.g. Kannada with English job terms like "electrician job ideya", Hindi with "delivery work chahiye"). Extract the correct intent regardless of code-mixing.
4. Preserve proper nouns, Indian names, rupee amounts (e.g., ₹500, ₹1,200), and place names (e.g., Koramangala, Bengaluru).
5. If the spoken query is vague or ambiguous, generate a short, friendly clarifying question in ${langName} asking the user for details.

Allowed Intents:
- "open_nearby_jobs": worker looking for work/jobs (e.g., "find delivery jobs above 400", "plumbing work near me").
  params: { "category": string | null, "min_wage": number | null, "search_query": string | null }
- "open_wallet": checking wallet, balance, payments, bank transfer.
- "open_safety": safety hub, emergency guide, safe hiring.
- "open_profile": profile view, verification badge, skills.
- "check_earnings": checking earnings today or recent income.
- "confirm_sos": emergency, danger, assault, panic.
  CRITICAL SAFETY RULE: Never trigger SOS silently! Set reply_text to ask for confirmation in ${langName} (e.g., "Emergency alert requested. Please confirm to notify emergency contacts and emergency services.").
- "post_job": provider posting a new job listing.
  ROLE RULE: Only allowed if userRole is "provider". If user is "seeker", reply_text must politely clarify in ${langName} that job posting is for providers.
- "check_mandi": mandi crop prices, APMC rates, farmer produce market.
- "answer_question": general questions, help with the app, tips, FAQs.

Create JSON with:
1. "reply_text": concise, natural, polite spoken reply in ${langName}.
2. "intent": one of the allowed intents.
3. "params": structured parameters (e.g. category, min_wage, search_query).`;

        jsonSchema = {
          type: 'OBJECT',
          properties: {
            reply_text: { type: 'STRING' },
            intent: { type: 'STRING' },
            params: {
              type: 'OBJECT',
              properties: {
                category: { type: 'STRING' },
                min_wage: { type: 'NUMBER' },
                search_query: { type: 'STRING' },
              },
            },
          },
          required: ['reply_text', 'intent'],
        };
        break;
      }

      case 'job_description_helper': {
        prompt = `Task: Write an engaging, clear job post title, description, and requirements for an Indian employer hiring local workers.
Category: ${payload.category || 'General Work'}
Initial Title / Notes: ${payload.title || ''} ${payload.notes || ''}
Provide an attractive title, a polite, clear description specifying expectations, and a bulleted list of 3-4 key requirements.
Return JSON with keys: title, description, key_requirements (array).`;

        jsonSchema = {
          type: 'OBJECT',
          properties: {
            title: { type: 'STRING' },
            description: { type: 'STRING' },
            key_requirements: { type: 'ARRAY', items: { type: 'STRING' } },
          },
          required: ['title', 'description', 'key_requirements'],
        };
        break;
      }

      case 'support_chat': {
        const userText = payload.query || payload.spoken_text || '';
        prompt = `Task: Customer support for UdyogaSethu.
User Role: ${payload.user_role || 'seeker'}
Query: "${userText}"
Provide a polite, helpful resolution in ${langName}, citing app features (e.g., Safety Hub, Digital ID, Razorpay Escrow, DigiLocker verification), and list 2-3 quick actionable steps.
Return JSON with keys: reply_text, suggested_actions (array).`;

        jsonSchema = {
          type: 'OBJECT',
          properties: {
            reply_text: { type: 'STRING' },
            suggested_actions: { type: 'ARRAY', items: { type: 'STRING' } },
          },
          required: ['reply_text', 'suggested_actions'],
        };
        break;
      }

      default: {
        prompt = `Respond helpfully to: "${payload.query || payload.spoken_text || ''}" in ${langName}. Return JSON with reply_text.`;
        jsonSchema = {
          type: 'OBJECT',
          properties: {
            reply_text: { type: 'STRING' },
          },
          required: ['reply_text'],
        };
        break;
      }
    }

    return { baseInstructions, prompt, jsonSchema };
  }

  /**
   * Execute intelligent 5-provider orchestration with primary routing,
   * specialized boosts, and automatic fallback.
   */
  static async orchestrate(
    payload: AiAssistRequest,
    curatedSchemes?: Array<Record<string, unknown>>,
  ): Promise<OrchestrationResult> {
    const startTime = Date.now();

    // 1. Audio Voice Synthesis (Deepgram Aura for English, device TTS routing for Regional)
    if (payload.task === 'voice_tts') {
      const textToSpeak = payload.tts_text || payload.spoken_text || payload.query || '';
      if (!textToSpeak.trim()) {
        throw new Error('Missing text to synthesize');
      }

      const langCode = (payload.language || 'en').toLowerCase().substring(0, 2);

      // Deepgram Aura only supports English. For regional Indic languages, instruct client to use device TTS.
      if (langCode !== 'en') {
        return {
          ok: true,
          provider_used: 'deepgram',
          model_used: 'device_regional_tts',
          latency_ms: Date.now() - startTime,
          result: {
            text: textToSpeak,
            use_client_tts: true,
            language: payload.language,
          },
        };
      }

      const { audioBase64, mimeType } = await DeepgramProvider.synthesizeSpeech(textToSpeak, {
        voice: payload.tts_voice || 'aura-asteria-en',
        language: 'en',
      });

      return {
        ok: true,
        provider_used: 'deepgram',
        model_used: payload.tts_voice || 'aura-asteria-en',
        latency_ms: Date.now() - startTime,
        result: { text: textToSpeak },
        audio_base64: audioBase64,
        audio_mime: mimeType,
      };
    }

    // 2. Audio Voice Transcription (Deepgram Nova-2 + Groq Whisper + Gemini Multimodal Fallback)
    if (payload.task === 'voice_stt') {
      if (!payload.audio_base64) {
        throw new Error('Missing audio_base64 to transcribe');
      }

      let rawBase64 = payload.audio_base64;
      if (rawBase64.includes(',')) {
        rawBase64 = rawBase64.split(',')[1];
      }

      // Convert Base64 to Uint8Array
      const binaryString = atob(rawBase64);
      const audioBytes = new Uint8Array(binaryString.length);
      for (let i = 0; i < binaryString.length; i++) {
        audioBytes[i] = binaryString.charCodeAt(i);
      }

      const mimeType = payload.audio_mime || 'audio/wav';
      const langCode = (payload.language || 'en').toLowerCase().substring(0, 2);
      const fallbackChain: ProviderId[] = [];

      // Route 1: If language is English ('en') or Hindi ('hi'), Deepgram Nova-2 is primary
      if (DeepgramProvider.isLanguageSupported(langCode) && DeepgramProvider.isConfigured() && circuitBreakers.isAvailable('deepgram')) {
        try {
          const { transcript, confidence } = await DeepgramProvider.transcribeAudio(
            audioBytes,
            mimeType,
            langCode,
          );
          if (transcript.trim().length > 0) {
            return {
              ok: true,
              provider_used: 'deepgram',
              model_used: 'nova-2',
              latency_ms: Date.now() - startTime,
              result: { transcript, confidence },
            };
          }
        } catch (dgErr) {
          logInfo('deepgram_stt_fallback_to_groq', { error: String(dgErr), langCode });
          fallbackChain.push('deepgram');
        }
      }

      // Route 2: Groq Whisper (supports all Indic languages: kn, te, ta, mr, bn, or, hi, en)
      if (GroqProvider.isConfigured() && circuitBreakers.isAvailable('groq')) {
        try {
          const { transcript, confidence } = await GroqProvider.transcribeAudio(
            audioBytes,
            mimeType,
            langCode,
          );
          if (transcript.trim().length > 0) {
            return {
              ok: true,
              provider_used: 'groq',
              model_used: 'whisper-large-v3-turbo',
              latency_ms: Date.now() - startTime,
              result: { transcript, confidence },
              fallback_chain: fallbackChain.length > 0 ? fallbackChain : undefined,
            };
          }
        } catch (groqErr) {
          logInfo('groq_stt_fallback_to_gemini', { error: String(groqErr), langCode });
          fallbackChain.push('groq');
        }
      }

      // Route 3: Gemini 1.5 Flash Multimodal Audio Fallback
      if (GeminiProvider.isConfigured() && circuitBreakers.isAvailable('gemini')) {
        try {
          const { transcript, confidence } = await GeminiProvider.transcribeAudio(
            rawBase64,
            mimeType,
            langCode,
          );
          if (transcript.trim().length > 0) {
            return {
              ok: true,
              provider_used: 'gemini',
              model_used: 'gemini-1.5-flash',
              latency_ms: Date.now() - startTime,
              result: { transcript, confidence },
              fallback_chain: fallbackChain.length > 0 ? fallbackChain : undefined,
            };
          }
        } catch (geminiErr) {
          logError('gemini_stt_error', geminiErr);
          fallbackChain.push('gemini');
        }
      }

      throw new Error(`All speech transcription providers failed for language '${langCode}'. Attempted: ${fallbackChain.join(', ') || 'none'}`);
    }

    // 3. Specialist Pre-Flight: Hugging Face Zero-Shot Intent Classification
    // Excluded from active chain unless HF_ENABLED is 'true' due to HTTP 402 zero credit state
    let hfIntentSuggestion: string | null = null;
    const hfEnabled = Deno.env.get('HF_ENABLED') === 'true';
    if (
      hfEnabled &&
      (payload.task === 'voice_intent' || payload.task === 'assistant_query') &&
      HuggingFaceProvider.isConfigured() &&
      circuitBreakers.isAvailable('huggingface')
    ) {
      try {
        const queryText = payload.spoken_text || payload.query || '';
        if (queryText.trim().length > 3) {
          const candidateLabels = [
            'open_nearby_jobs',
            'open_wallet',
            'open_safety',
            'check_earnings',
            'confirm_sos',
            'post_job',
            'check_mandi',
            'answer_question',
          ];
          const hfRes = await HuggingFaceProvider.classifyZeroShot(queryText, candidateLabels);
          if (hfRes.topScore > 0.40) {
            hfIntentSuggestion = hfRes.topLabel;
            logInfo('hf_intent_hint', { topLabel: hfRes.topLabel, score: hfRes.topScore });
          }
        }
      } catch (err) {
        // Specialist call failure is non-fatal, proceed with primary LLM
        logInfo('hf_specialist_skipped', { reason: String(err) });
      }
    }

    // 4. Determine Routing Chain based on Task & Multimodal Inputs
    const { baseInstructions, prompt, jsonSchema } = this.buildPromptConfig(payload, curatedSchemes);
    const enrichedPrompt = hfIntentSuggestion
      ? `${prompt}\n(Specialist classifier candidate hint: ${hfIntentSuggestion})`
      : prompt;

    // Routing Strategy:
    // - Multimodal (has image): Gemini -> OpenRouter
    // - Complex reasoning: Gemini -> Groq -> OpenRouter
    // - Fast conversational / voice query: Groq -> Gemini -> OpenRouter
    const fallbackChain: ProviderId[] = [];

    if (payload.image_base64) {
      fallbackChain.push('gemini', 'openrouter');
    } else if (
      payload.task === 'pest_diagnosis' ||
      payload.task === 'soil_advice' ||
      payload.task === 'scheme_finder' ||
      payload.task === 'irrigation_plan'
    ) {
      fallbackChain.push('gemini', 'groq', 'openrouter');
    } else {
      // Default: Groq (fast primary) -> Gemini -> OpenRouter
      fallbackChain.push('groq', 'gemini', 'openrouter');
    }

    // Filter to configured and circuit-available providers
    const attemptedProviders: ProviderId[] = [];
    let lastError: string | null = null;

    for (const provider of fallbackChain) {
      attemptedProviders.push(provider);
      try {
        if (provider === 'groq') {
          if (!GroqProvider.isConfigured() || !circuitBreakers.isAvailable('groq')) {
            continue;
          }
          const res = await GroqProvider.completeChat(baseInstructions, enrichedPrompt, {
            conversationHistory: payload.conversation_history,
            requireJson: true,
          });

          const parsed = res.parsedJson || { reply_text: res.content };
          const latencyMs = Date.now() - startTime;

          return {
            ok: true,
            provider_used: 'groq',
            model_used: res.model,
            latency_ms: latencyMs,
            result: parsed,
            fallback_chain: attemptedProviders.length > 1 ? attemptedProviders : undefined,
            circuit_breaker_stats: circuitBreakers.getStats(),
          };
        }

        if (provider === 'gemini') {
          if (!GeminiProvider.isConfigured() || !circuitBreakers.isAvailable('gemini')) {
            continue;
          }
          const res = await GeminiProvider.generateContent(baseInstructions, enrichedPrompt, {
            jsonSchema,
            imageBase64: payload.image_base64,
            imageMime: payload.image_mime,
          });

          const parsed = res.parsedJson || { reply_text: res.content };
          const latencyMs = Date.now() - startTime;

          return {
            ok: true,
            provider_used: 'gemini',
            model_used: res.model,
            latency_ms: latencyMs,
            result: parsed,
            fallback_chain: attemptedProviders.length > 1 ? attemptedProviders : undefined,
            circuit_breaker_stats: circuitBreakers.getStats(),
          };
        }

        if (provider === 'openrouter') {
          if (!OpenRouterProvider.isConfigured() || !circuitBreakers.isAvailable('openrouter')) {
            continue;
          }
          const res = await OpenRouterProvider.completeChat(baseInstructions, enrichedPrompt, {
            conversationHistory: payload.conversation_history,
            requireJson: true,
          });

          const parsed = res.parsedJson || { reply_text: res.content };
          const latencyMs = Date.now() - startTime;

          return {
            ok: true,
            provider_used: 'openrouter',
            model_used: res.model,
            latency_ms: latencyMs,
            result: parsed,
            fallback_chain: attemptedProviders.length > 1 ? attemptedProviders : undefined,
            circuit_breaker_stats: circuitBreakers.getStats(),
          };
        }
      } catch (err) {
        lastError = String(err);
        logError('provider_attempt_failed', { provider, error: lastError });
        // Continue loop to try next fallback provider
      }
    }

    // All available providers failed
    logError('all_providers_exhausted', {
      task: payload.task,
      attempted: attemptedProviders,
      lastError,
    });

    throw new Error(
      `All AI providers failed (${attemptedProviders.join(' -> ')}). Last error: ${lastError}`,
    );
  }
}
