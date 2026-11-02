# Edge Functions Specification & Matrix

All Edge Functions are located in `supabase/functions/` and use common helpers from `supabase/functions/_shared/`.

## Shared Infrastructure (`_shared/`)
- `cors.ts`: CORS headers and OPTIONS preflight handler.
- `logger.ts`: Structured JSON logging with automatic scrubbing of JWT tokens, phone numbers, Aadhaar, and PAN numbers.
- `response.ts`: Typed `jsonResponse` (200 OK) and `errorResponse` helpers.
- `supabase.ts`: `getUserClient(req)` (validates user JWT from Authorization header) and `getServiceClient()` (uses `SUPABASE_SERVICE_ROLE_KEY`).
- `validation.ts`: `validateBody<T>(req, requiredFields)` JSON body validation.
- `rate_limiter.ts`: `checkRateLimit(identifier, action, limit, windowSeconds)` backed by `rate_limits` table with in-memory fallback.

---

## Edge Function Matrix

| Function | Purpose | Authentication | Secrets Needed | Phase / Implementation Scope |
| :--- | :--- | :--- | :--- | :--- |
| `kyc-start` | Initiates Aadhaar/PAN/DL verification flow with external provider | User JWT (`Bearer <token>`) | `KYC_PROVIDER_KEY`, `KYC_PROVIDER_SECRET` | Phase 4 (Trust & Verification) |
| `kyc-callback` | Webhook handler receiving status updates from KYC partner | Webhook Signature (`x-webhook-signature`) | `KYC_WEBHOOK_SECRET` | Phase 4 (Trust & Verification) |
| `face-enroll` | Enrolls baseline face 128d float32 embedding vector and verifies liveness challenges | User JWT (`Bearer <token>`) | `FACE_MATCHER` (`ondevice` default, `mock`) | Phase 3.4 (Done) |
| `face-verify` | Verifies selfie image against enrolled face embedding during check-in | User JWT (`Bearer <token>`) | `FACE_API_KEY` | Phase 4 (Trust & Verification) |
| `qr-issue` | Issues signed, expiring QR token for digital ID profile verification and ticket check-in | User JWT (`Bearer <token>`) | `QR_SIGNING_SECRET` | Phase 3.7 (Done) |
| `qr-verify` | Verifies signed QR token, checks revocation/expiry in constant time, calls get_public_verification | User JWT (`Bearer <token>`) | `QR_SIGNING_SECRET` | Phase 3.7 (Done) |
| `payment-create-order` | Creates Razorpay order for job escrow, produce buying, or equipment rent | User JWT (`Bearer <token>`) | `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Phase 3 (Payments & Escrow) |
| `payment-webhook` | Webhook handler receiving Razorpay payment state changes | Webhook Signature (`x-razorpay-signature`) | `RAZORPAY_WEBHOOK_SECRET` | Phase 3 (Payments & Escrow) |
| `sos-trigger` | Triggers emergency SOS alert, broadcasts location, & notifies emergency contacts | User JWT (`Bearer <token>`) | `SMS_GATEWAY_KEY` | Phase 4 (Safety & Escalation) |
| `send-push` | Sends FCM push notification to specific user devices | User JWT or Service Authorization | `FCM_SERVICE_ACCOUNT_KEY` | Phase 4 (Communication) |
| `mandi-sync` | Syncs latest Mandi crop prices from Agmarknet / Government API | Service JWT / Cron trigger | `MANDI_API_KEY` | Phase 7 (Farmer Hub) |
| `ai-assist` | 5-Provider intelligent AI orchestrator (Groq, Gemini, OpenRouter, Deepgram, Hugging Face) for low-latency conversational voice, multimodal advisory, zero-shot intent routing, neural TTS and STT | User JWT (`Bearer <token>`) | `GROQ_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY`, `DEEPGRAM_API_KEY`, `HUGGINGFACE_API_KEY` | Phase 8 / Phase C7 (Production 5-Provider) |
| `masked-call` | Sets up privacy-masked call connection between provider and worker | User JWT (`Bearer <token>`) | `EXOTEL_API_KEY`, `EXOTEL_API_TOKEN`, `EXOTEL_SID` | Phase 4 (Communication & Privacy) |
| `assignment-verify` | Two-step verified start (selfie + PostGIS geofence), mock location detection, mid-job check, and completion with evidence | User JWT (`Bearer <token>`) | None (PostGIS + internal RPCs) | Phase 4.9 (Done) |

---

## 5-Provider AI Assistant Orchestration Architecture (`ai-assist`)

The `ai-assist` Edge Function acts as a secure server-side gateway that decouples the mobile client from underlying AI vendor APIs. Client applications never hold private API keys.

### 1. Provider Roles
- **Groq** (`GROQ_API_KEY`, `GROQ_MODEL=qwen/qwen3.8-27b`): Preferred fast primary LLM for natural, conversational dialogue. Delivers ultra-low latency (~100ms TTFT) responses. Verified live.
- **Google Gemini** (`GEMINI_API_KEY`, `GEMINI_MODEL=gemini-3.5-flash-lite`): Multimodal reasoning engine. Handles photo analysis (crop disease diagnosis, pest identification, soil report cards) and complex agricultural reasoning. Verified live.
- **OpenRouter** (`OPENROUTER_API_KEY`, `OPENROUTER_MODEL=meta-llama/llama-3.1-8b-instruct`): Multi-model routing and resilient multi-cloud fallback when primary providers experience outages or rate limits. Verified live.
- **Deepgram** (`DEEPGRAM_API_KEY`, `DEEPGRAM_TTS_MODEL=aura-asteria-en`, `DEEPGRAM_STT_MODEL=nova-2`): Speech intelligence. Provides high-fidelity neural text-to-speech (Aura) and accurate audio transcription (Nova-2). Verified live (TTS & STT).
- **Hugging Face** (`HUGGINGFACE_API_KEY`, `HUGGINGFACE_MODEL=facebook/bart-large-mnli`): Specialist zero-shot intent classification to categorize ambiguous user utterances before LLM execution. (Note: Serverless inference requires pre-paid credits on the user's HF account; gracefully bypassed when uncredited).

### 2. Task Routing Policy
- **Conversational Voice** (`voice_query`): Routed to **Groq** for rapid conversational answers. Falls back to **Gemini**, then **OpenRouter**.
- **Multimodal Tasks** (`farmer_pest`, `farmer_soil`, or any query with `image_base64`): Routed directly to **Gemini**. Falls back to **OpenRouter**.
- **Speech Synthesis** (`voice_tts`): Routed directly to **Deepgram Aura** returning base64 audio.
- **Speech Transcription** (`voice_stt`): Routed directly to **Deepgram Nova-2**.
- **Specialist Classification**: Queries **Hugging Face** BART-MNLI for intent candidate scoring when enabled.
- **Emergency / System Failure**: If all configured cloud providers fail or are unconfigured, graceful deterministic fallback response is generated with `provider: 'fallback_rules'`.

### 3. Reliability & Circuit Breaker
- In-memory circuit breaker (`CircuitBreakerRegistry`) tracks rolling failures per provider.
- Trips to OPEN after 3 consecutive failures.
- Enters HALF-OPEN after a 30-second cooldown period to probe provider health.
- Prevents cascading timeouts and wasted latency.

### 4. Client Integration
- `EdgeApiClient.queryAssistant()` passes user text, image, role, language, and conversation history.
- Returns `VoiceIntentResult` with provider telemetry (`provider`, `model`, `latency_ms`, `audio_base64`, `audio_mime`).
- If `audio_base64` is returned by Deepgram Aura, Flutter plays it via `audioplayers`. If unconfigured, the app falls back to on-device `flutter_tts`.

