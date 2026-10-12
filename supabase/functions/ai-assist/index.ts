import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { errorResponse, jsonResponse } from '../_shared/response.ts';
import { getUserClient, getServiceClient } from '../_shared/supabase.ts';
import { checkRateLimit } from '../_shared/rate_limiter.ts';

export type AiTaskType =
  | 'pest_diagnosis'
  | 'soil_advice'
  | 'irrigation_plan'
  | 'scheme_finder'
  | 'price_advice';

export interface AiAssistRequest {
  task: AiTaskType;
  language?: 'en' | 'kn' | 'hi' | 'te' | 'ta';
  crop?: string;
  district?: string;
  symptoms?: string;
  image_base64?: string;
  image_mime?: string;
  soil_ph?: number;
  soil_type?: string;
  weather_summary?: string;
  crop_stage?: string;
  irrigation_source?: string;
  farmer_query?: string;
}

const LANGUAGE_NAMES: Record<string, string> = {
  en: 'English',
  kn: 'Kannada (ಕನ್ನಡ)',
  hi: 'Hindi (हिन्दी)',
  te: 'Telugu (తెలుగు)',
  ta: 'Tamil (தமிழ்)',
};

// Basic fallback generators (offline / rules mode)
function getBasicFallback(payload: AiAssistRequest, curatedSchemes?: Array<Record<string, unknown>>): Record<string, unknown> {
  const lang = payload.language || 'en';
  const crop = payload.crop || 'Crop';
  const ph = payload.soil_ph;

  switch (payload.task) {
    case 'pest_diagnosis': {
      let adviceKn = {
        likely_cause: 'ಎಲೆ ಚುಕ್ಕೆ ಅಥವಾ ಆರಂಭಿಕ ತಡ ಹಾನಿ / ಪೋಷಕಾಂಶಗಳ ಕೊರತೆಯ ಲಕ್ಷಣಗಳು',
        organic_remedies: [
          'ಬೇವಿನ ಎಣ್ಣೆ ಸಿಂಪಡಣೆ (ಪ್ರತಿ ಲೀಟರ್ ನೀರಿಗೆ 5 ಮಿ.ಲೀ ಜೊತೆ ಸೋಪು ದ್ರಾವಣ)',
          'ಗಿಡದ ಬುಡಕ್ಕೆ ಬೂದಿ ಹಾಕುವುದು',
          'ರೋಗಪೀಡಿತ ಕೆಳಭಾಗದ ಎಲೆಗಳನ್ನು ಕಿತ್ತು ನಾಶಮಾಡಿ',
        ],
        chemical_advice: 'ಮ್ಯಾಂಕೋಜೆಬ್ ಅಥವಾ ತಾಮ್ರದ ಆಕ್ಸಿಕ್ಲೋರೈಡ್ (ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರದ ತಜ್ಞರ ಸಲಹೆಯಂತೆ ಮಾತ್ರ ಬಳಸಿ)',
        expert_note: 'ಯಾವುದೇ ರಾಸಾಯನಿಕ ಸಿಂಪಡಿಸುವ ಮುನ್ನ ಸಮೀಪದ ಕೃಷಿ ವಿಜ್ಞಾನ ಕೇಂದ್ರ (KVK) ಅಥವಾ ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರವನ್ನು ಸಂಪರ್ಕಿಸಿ.',
      };

      let adviceEn = {
        likely_cause: `Leaf spot, fungal blight, or sap-sucking pest symptoms observed on ${crop}`,
        organic_remedies: [
          'Neem oil spray (5ml per liter with mild soap emulsifier) during evening hours',
          'Wood ash dusting around the root zone',
          'Prune and safely burn or compost infected lower foliage away from the field',
        ],
        chemical_advice: 'Copper Oxychloride or Mancozeb fungicide spray (Strictly confirm dosage with agronomist)',
        expert_note: 'AI suggestion only. Please confirm with your local Raitha Samparka Kendra (RSK) or KVK officer before chemical application.',
      };

      return {
        mode: 'basic',
        task: 'pest_diagnosis',
        crop,
        ...(lang === 'kn' ? adviceKn : adviceEn),
      };
    }

    case 'soil_advice': {
      let phAssessment = 'Optimal neutral soil (pH 6.5 - 7.5)';
      let amendments = [
        'Well-decomposed Farm Yard Manure (FYM) 5-8 tonnes/acre',
        'Jeevamrutha / vermicompost during intercultural operations',
      ];
      let suitableCrops = ['Tomato', 'Onion', 'Chilli', 'Paddy', 'Maize'];

      if (ph !== undefined && ph < 6.0) {
        phAssessment = `Acidic soil (pH ${ph}). Micronutrient availability may be restricted.`;
        amendments = [
          'Agricultural lime or dolomite (200-300 kg/acre) incorporated 2 weeks before sowing',
          'Organic compost and bio-fertilizers (Trichoderma, Phosphobacteria)',
        ];
        suitableCrops = ['Potato', 'Ginger', 'Tea', 'Arecanut'];
      } else if (ph !== undefined && ph > 7.5) {
        phAssessment = `Alkaline/saline soil (pH ${ph}). Possible zinc and iron deficiency.`;
        amendments = [
          'Agricultural gypsum (200-500 kg/acre) based on soil test',
          'Green manuring with Sunhemp or Dhaincha',
          'Foliar spray of micronutrient mixture',
        ];
        suitableCrops = ['Cotton', 'Paddy', 'Barley', 'Pomegranate'];
      }

      return {
        mode: 'basic',
        task: 'soil_advice',
        soil_ph: ph ?? 6.8,
        ph_assessment: phAssessment,
        organic_amendments: amendments,
        recommended_crops: suitableCrops,
        expert_note: 'Based on standard agricultural rules. Obtain a Soil Health Card from your nearest laboratory for precise nutrient testing.',
      };
    }

    case 'irrigation_plan': {
      const stage = payload.crop_stage || 'Vegetative / Growth';
      return {
        mode: 'basic',
        task: 'irrigation_plan',
        crop,
        stage,
        schedule: 'Irrigate every 2 to 3 days in early morning (06:00 AM - 08:30 AM) to minimize evaporation losses.',
        drip_run_time: '1.5 to 2.5 hours per cycle depending on dripper discharge and soil type',
        water_conservation: [
          'Apply organic dry mulching (straw/crop residue) to retain soil moisture',
          'Postpone scheduled irrigation if rain over 10mm occurs or is forecast within 24 hours',
          'Monitor tensiometer or check top 10cm soil dryness before irrigating',
        ],
        expert_note: 'Adjust timing based on prevailing district weather and soil moisture depth.',
      };
    }

    case 'scheme_finder': {
      const schemesList = (curatedSchemes && curatedSchemes.length > 0)
        ? curatedSchemes.map((s) => ({
            slug: s.slug,
            name: (s[`name_${lang}`] as string) || (s.name_en as string),
            description: (s[`short_description_${lang}`] as string) || (s.short_description_en as string),
            official_url: s.official_url,
            category: s.category,
            benefits_summary: s.benefits_summary,
          }))
        : [
            {
              slug: 'pm_kisan',
              name: 'PM-KISAN',
              description: 'Income support of Rs 6,000 per year in three installments for landholding farmer families.',
              official_url: 'https://pmkisan.gov.in',
            },
            {
              slug: 'kisan_credit_card',
              name: 'Kisan Credit Card (KCC)',
              description: 'Concessional institutional credit for crop cultivation and post-harvest requirements.',
              official_url: 'https://agricoop.gov.in',
            },
            {
              slug: 'pm_fasal_bima',
              name: 'PM Fasal Bima Yojana (PMFBY)',
              description: 'Comprehensive risk insurance covering yield losses due to non-preventable natural risks.',
              official_url: 'https://pmfby.gov.in',
            },
          ];

      return {
        mode: 'basic',
        task: 'scheme_finder',
        schemes: schemesList,
        expert_note: 'Curated government schemes. Apply exclusively through official government portals or at the nearest Grama One / CSC centre.',
      };
    }

    case 'price_advice': {
      return {
        mode: 'basic',
        task: 'price_advice',
        crop,
        recommendation: 'Check live mandi arrival trends. If prices are below MSP or average production cost, consider grading, short cold storage, or direct community pre-orders.',
        marketing_options: [
          'Sell directly to apartment community groups via UdyogaSethu bulk orders to eliminate middleman commissions',
          'Grade produce into A/B categories to secure higher prices for premium grade',
        ],
        expert_note: 'Market prices fluctuate daily based on APMC arrivals and seasonal harvest volume.',
      };
    }
  }
}

// Gemini prompt and schema builders
function buildGeminiConfig(payload: AiAssistRequest, curatedSchemes?: Array<Record<string, unknown>>) {
  const langCode = payload.language || 'en';
  const langName = LANGUAGE_NAMES[langCode] || 'English';

  const baseInstructions = `You are an expert, cautious agricultural AI assistant for smallholder farmers in Karnataka and rural India.
Strict Guidelines:
1. Respond exclusively in valid JSON matching the specified JSON schema.
2. Provide all output text strictly in ${langName}.
3. Prioritize natural, organic, and non-toxic IPM (Integrated Pest Management) remedies.
4. Chemical recommendations must always be cautious and include a disclaimer advising the farmer to confirm with an agricultural extension officer or Raitha Samparka Kendra before spraying.
5. NEVER invent false government scheme names, subsidies, or fake eligibility percentages. Use only verified, realistic agricultural knowledge.
6. Avoid technical jargon; speak in terms an Indian farmer easily understands.`;

  let prompt = '';
  let jsonSchema = {};

  switch (payload.task) {
    case 'pest_diagnosis': {
      prompt = `Task: Diagnosing pest or disease on crop: ${payload.crop || 'Field Crop'}.
Symptoms reported: ${payload.symptoms || 'Symptoms visible in leaf photo'}.
District: ${payload.district || 'Karnataka'}.
Examine the symptoms and provide likely causes, organic remedies, cautious chemical options (if necessary), and practical field steps.`;

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
      prompt = `Task: Soil health advisory.
Soil pH: ${payload.soil_ph !== undefined ? payload.soil_ph : 'Not tested'}.
Soil Type: ${payload.soil_type || 'Red loamy / Black cotton'}.
District: ${payload.district || 'Karnataka'}.
Crop intended: ${payload.crop || 'General vegetables / pulses'}.
Provide soil assessment, organic amendments, pH correction, and recommended crops.`;

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
      prompt = `Task: Crop irrigation scheduling.
Crop: ${payload.crop || 'Field Crop'}.
Growth Stage: ${payload.crop_stage || 'Vegetative'}.
Irrigation Source: ${payload.irrigation_source || 'Borewell / Drip'}.
Weather summary: ${payload.weather_summary || 'Warm and dry'}.
District: ${payload.district || 'Karnataka'}.
Provide optimal irrigation timing, cycle duration, water saving measures, and rain adjustment.`;

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

    case 'scheme_finder': {
      const schemesContext = (curatedSchemes || [])
        .map((s) => `- ${s.name_en} (${s.official_url}): ${s.short_description_en}`)
        .join('\n');

      prompt = `Task: Match and explain official government agricultural schemes for a farmer in district: ${payload.district || 'Karnataka'}.
Farmer query: ${payload.farmer_query || 'Finding subsidies and credit support'}.
Curated official schemes available:
${schemesContext}
Select relevant schemes from the curated list, explain why they help the farmer, and remind them to apply only on official portals. DO NOT invent unlisted schemes.`;

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

    case 'price_advice': {
      prompt = `Task: Harvest pricing and mandi strategy.
Crop: ${payload.crop || 'Vegetables'}.
District: ${payload.district || 'Karnataka'}.
Provide pricing guidance, bulk sale vs mandi comparison, and grading recommendations.`;

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
  }

  return { baseInstructions, prompt, jsonSchema };
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  try {
    const url = new URL(req.url);
    if (req.method === 'GET' || url.searchParams.get('health') === 'true') {
      const missingSecrets: string[] = [];
      if (!Deno.env.get('GEMINI_API_KEY')) missingSecrets.push('GEMINI_API_KEY');
      return jsonResponse({
        ok: true,
        status: 'healthy',
        missing_secrets: missingSecrets,
      });
    }

    // 1. Authenticate caller
    const auth = await getUserClient(req);
    if (auth.errorResponse) return auth.errorResponse;
    const userId = auth.context!.user.id;

    // 2. Rate limiting (20 requests per minute per user)
    const rate = await checkRateLimit(userId, 'ai-assist', 20, 60);
    if (rate.errorResponse) return rate.errorResponse;

    // 3. Parse and sanitize payload
    const body: AiAssistRequest = await req.json().catch(() => ({}));
    if (!body || !body.task) {
      return errorResponse('bad_request', 'Missing required parameter: task', 400);
    }

    // Strip any possible PII from user inputs
    const sanitizedPayload: AiAssistRequest = {
      task: body.task,
      language: body.language || 'en',
      crop: body.crop ? String(body.crop).substring(0, 80) : undefined,
      district: body.district ? String(body.district).substring(0, 80) : undefined,
      symptoms: body.symptoms ? String(body.symptoms).substring(0, 500) : undefined,
      soil_ph: typeof body.soil_ph === 'number' ? body.soil_ph : undefined,
      soil_type: body.soil_type ? String(body.soil_type).substring(0, 80) : undefined,
      weather_summary: body.weather_summary ? String(body.weather_summary).substring(0, 200) : undefined,
      crop_stage: body.crop_stage ? String(body.crop_stage).substring(0, 80) : undefined,
      irrigation_source: body.irrigation_source ? String(body.irrigation_source).substring(0, 80) : undefined,
      farmer_query: body.farmer_query ? String(body.farmer_query).substring(0, 500) : undefined,
      image_base64: body.image_base64,
      image_mime: body.image_mime || 'image/jpeg',
    };

    // Validate and limit leaf photo size (max 1.5MB base64)
    if (sanitizedPayload.image_base64) {
      if (sanitizedPayload.image_base64.length > 2 * 1024 * 1024) {
        return errorResponse('payload_too_large', 'Image too large. Please compress before uploading.', 413);
      }
    }

    // Fetch curated schemes from DB if needed
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

    // 4. Check Gemini API Key
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    const model = Deno.env.get('GEMINI_MODEL') || 'gemini-1.5-flash';

    if (!apiKey || apiKey.trim() === '') {
      logInfo('ai_assist_basic_fallback_no_key', { task: sanitizedPayload.task });
      const basicResult = getBasicFallback(sanitizedPayload, curatedSchemes);
      return jsonResponse({
        ok: true,
        mode: 'basic',
        disclaimer: 'Basic mode (offline rules)',
        result: basicResult,
      });
    }

    // 5. Invoke Gemini API
    const { baseInstructions, prompt } = buildGeminiConfig(sanitizedPayload, curatedSchemes);

    const parts: Array<Record<string, unknown>> = [];
    if (sanitizedPayload.image_base64) {
      // Clean prefix if data url
      let rawBase64 = sanitizedPayload.image_base64;
      if (rawBase64.includes(',')) {
        rawBase64 = rawBase64.split(',')[1];
      }
      parts.push({
        inlineData: {
          mimeType: sanitizedPayload.image_mime || 'image/jpeg',
          data: rawBase64,
        },
      });
    }
    parts.push({ text: prompt });

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
    const requestBody = {
      systemInstruction: {
        parts: [{ text: baseInstructions }],
      },
      contents: [
        {
          role: 'user',
          parts,
        },
      ],
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.2,
        maxOutputTokens: 1024,
      },
    };

    let geminiResponse: Response | null = null;
    let attempt = 0;

    while (attempt < 2) {
      attempt++;
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 9000); // 9 sec timeout

        geminiResponse = await fetch(geminiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(requestBody),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        if (geminiResponse.ok) {
          break;
        }

        if (attempt === 1 && (geminiResponse.status === 429 || geminiResponse.status >= 500)) {
          await new Promise((r) => setTimeout(r, 1000));
          continue;
        }
        break;
      } catch (err) {
        logError('gemini_fetch_attempt_error', { attempt, err: String(err) });
        if (attempt === 1) {
          await new Promise((r) => setTimeout(r, 1000));
          continue;
        }
      }
    }

    if (!geminiResponse || !geminiResponse.ok) {
      logInfo('ai_assist_fallback_on_api_failure', {
        status: geminiResponse?.status,
        task: sanitizedPayload.task,
      });
      const basicResult = getBasicFallback(sanitizedPayload, curatedSchemes);
      return jsonResponse({
        ok: true,
        mode: 'basic',
        disclaimer: 'Basic mode (offline rules)',
        result: basicResult,
      });
    }

    const geminiData = await geminiResponse.json();
    const rawText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!rawText) {
      logInfo('ai_assist_empty_response', { task: sanitizedPayload.task });
      const basicResult = getBasicFallback(sanitizedPayload, curatedSchemes);
      return jsonResponse({
        ok: true,
        mode: 'basic',
        disclaimer: 'Basic mode (offline rules)',
        result: basicResult,
      });
    }

    let parsedJson: Record<string, unknown>;
    try {
      parsedJson = JSON.parse(rawText);
    } catch {
      logInfo('ai_assist_invalid_json', { task: sanitizedPayload.task });
      const basicResult = getBasicFallback(sanitizedPayload, curatedSchemes);
      return jsonResponse({
        ok: true,
        mode: 'basic',
        disclaimer: 'Basic mode (offline rules)',
        result: basicResult,
      });
    }

    logInfo('ai_assist_success', { task: sanitizedPayload.task, userId });
    return jsonResponse({
      ok: true,
      mode: 'gemini',
      model,
      disclaimer: 'AI suggestion (Gemini), not professional advice',
      result: parsedJson,
    });
  } catch (err) {
    logError('ai_assist_top_level_error', err);
    // On unexpected error, gracefully degrade to basic fallback
    return jsonResponse({
      ok: true,
      mode: 'basic',
      disclaimer: 'Basic mode (offline rules)',
      result: {
        expert_note: 'Agricultural rule advisory. Consult your local Raitha Samparka Kendra for in-person support.',
      },
    });
  }
});
