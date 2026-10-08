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
| `ai-assist` | Gemini-powered voice and text AI assistant for multilingual queries | User JWT (`Bearer <token>`) | `GEMINI_API_KEY`, `GEMINI_MODEL` | Phase 8 (AI Assistant & Voice) |
| `masked-call` | Sets up privacy-masked call connection between provider and worker | User JWT (`Bearer <token>`) | `EXOTEL_API_KEY`, `EXOTEL_API_TOKEN`, `EXOTEL_SID` | Phase 4 (Communication & Privacy) |
| `assignment-verify` | Two-step verified start (selfie + PostGIS geofence), mock location detection, mid-job check, and completion with evidence | User JWT (`Bearer <token>`) | None (PostGIS + internal RPCs) | Phase 4.9 (Done) |

> **Note**: Only `ai-assist` invokes Gemini API using `GEMINI_API_KEY` and `GEMINI_MODEL`.
