export type AiTaskType =
  | 'pest_diagnosis'
  | 'soil_advice'
  | 'irrigation_plan'
  | 'scheme_finder'
  | 'price_advice'
  | 'voice_intent'
  | 'assistant_query'
  | 'job_description_helper'
  | 'support_chat'
  | 'voice_tts'
  | 'voice_stt';

export type ProviderId = 'groq' | 'gemini' | 'openrouter' | 'deepgram' | 'huggingface';

export interface ProviderCapability {
  id: ProviderId;
  name: string;
  isAvailable: boolean;
  supportsStreaming: boolean;
  supportsMultimodal: boolean;
  supportsTts: boolean;
  supportsStt: boolean;
  primaryRole: string;
}

export interface AiAssistRequest {
  task: AiTaskType;
  language?: string;
  user_role?: 'seeker' | 'provider' | 'farmer';
  spoken_text?: string;
  query?: string;
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
  conversation_history?: Array<{ role: 'user' | 'assistant'; text: string }>;
  context?: Record<string, unknown>;
  category?: string;
  title?: string;
  notes?: string;

  // Voice/audio specific fields
  audio_base64?: string;
  audio_mime?: string;
  tts_text?: string;
  tts_voice?: string;
  preferred_provider?: ProviderId;
}

export interface OrchestrationResult {
  ok: boolean;
  provider_used: ProviderId;
  model_used: string;
  latency_ms: number;
  result: Record<string, unknown>;
  audio_base64?: string;
  audio_mime?: string;
  fallback_chain?: ProviderId[];
  circuit_breaker_stats?: Record<string, unknown>;
}

export const LANGUAGE_NAMES: Record<string, string> = {
  en: 'English',
  kn: 'Kannada (ಕನ್ನಡ)',
  hi: 'Hindi (हिन्दी)',
  te: 'Telugu (తెలుగు)',
  ta: 'Tamil (தமிழ்)',
  mr: 'Marathi (मराठी)',
  bn: 'Bengali (বাংলা)',
  or: 'Odia (ଓଡ଼ିଆ)',
};
