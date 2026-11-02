# UdyogaSethu — Complete Technology Stack & Technical Inventory

> **Document Version**: 1.0.0  
> **Target Audience**: Technical Architects, Engineering Leads, and System Administrators  
> **Repository**: `in.udyogasethu.udyogasethu`

---

## 1. Complete Technology Inventory Table

| Component Category | Technology / Library | Version / Specification | Architectural Purpose in UdyogaSethu |
| :--- | :--- | :--- | :--- |
| **Mobile Framework** | Flutter | Latest Stable (Dart ^3.13.2) | Cross-platform client application framework |
| **Mobile Runtime Language** | Dart | ^3.13.2 | Strong-mode sound null-safe client business logic |
| **Android Toolchain** | Android Gradle Plugin / Kotlin | CompileSdk 37, MinSdk 21, JVM 17 | Native Android compilation, permissions & packaging |
| **State Management** | `flutter_riverpod` | ^3.4.3 | Reactive, unidirectional dependency injection & state management |
| **Navigation & Routing** | `go_router` | ^18.0.2 | Declarative, role-gated URL routing & deep linking |
| **Backend as a Service** | Supabase Platform | Remote ref: `mmzbpeqkfomnywuzoqii` | Managed PostgreSQL, Auth, Realtime, Storage & Edge Functions |
| **Database Engine** | PostgreSQL | 15.x (with PostGIS, pgcrypto, pg_trgm) | Relational database, spatial matching & append-only financial ledger |
| **Serverless Runtime** | Deno | 1.x (TypeScript) | Isolated execution environment for Supabase Edge Functions |
| **Primary Conversational AI** | Groq LPU API | Model: `qwen/qwen3.8-27b` / `llama-3.3-70b` | Ultra-low-latency (~100ms) natural language conversational dialogue |
| **Multimodal Vision & AI** | Google Gemini API | Model: `gemini-1.5-flash` / `gemini-3.5-flash-lite` | Agricultural crop disease diagnosis, soil card reading & multimodal analysis |
| **Cloud AI Fallback** | OpenRouter API | Model: `meta-llama/llama-3.1-8b-instruct` | Multi-cloud failover redundancy across upstream model providers |
| **Speech Intelligence (TTS/STT)** | Deepgram API | Models: `aura-asteria-en` & `nova-2` | Neural English speech synthesis and multilingual cloud audio transcription |
| **Specialist Classification** | Hugging Face Inference API | Model: `facebook/bart-large-mnli` | Zero-shot candidate intent scoring (gated behind circuit breaker) |
| **On-Device Face Landmark** | Google ML Kit Face Detection | `google_mlkit_face_detection: ^0.15.1` | Real-time on-device facial landmark detection & head pose estimation |
| **On-Device Biometric Model** | TensorFlow Lite Flutter | `tflite_flutter: ^0.12.1` | 128-dimensional Float32 vector extraction (`mobilefacenet.tflite`) |
| **Cloud Face Comparison** | Eden AI REST API | Provider: `amazon` (`face_compare`) | Production server-side face similarity comparison between photos |
| **Payment Gateway** | Razorpay Flutter | `razorpay_flutter: ^1.4.7` | UPI, NetBanking, Cards, and Wallet payment checkout |
| **Geospatial Mapping** | Flutter Map / Leaflet | `flutter_map: ^8.3.2`, `latlong2: ^0.10.1` | OpenStreetMap interactive job and resource maps |
| **Device Geolocation** | Geolocator / Geocoding | `geolocator: ^14.0.1`, `geocoding: ^5.0.0` | High-accuracy GPS capture, geofencing & reverse geocoding |
| **QR Code Processing** | Mobile Scanner & QR Flutter | `mobile_scanner: ^7.4.2`, `qr_flutter: ^4.1.0` | Camera-based attendance scanning & dynamic QR ticket rendering |
| **Native Device Speech** | Speech to Text / Flutter TTS | `speech_to_text: ^7.5.0`, `flutter_tts: ^4.2.5` | Android hardware microphone recognition & regional Indic speech output |
| **Audio Playback & Recording** | AudioPlayers & Record | `audioplayers: ^6.8.1`, `record: ^7.1.2` | Neural base64 audio streaming & cloud STT audio capture |
| **Secure Key Storage** | Flutter Secure Storage | `flutter_secure_storage: ^11.2.0` | Hardware-backed encrypted key/token storage |
| **Local Persistence** | SharedPreferences | `shared_preferences: ^2.5.5` | Offline caching for tickets, mandi prices, and UI preferences |
| **Typography & Styling** | Google Fonts | `google_fonts: ^9.0.0` | Dynamic font resolution (`Lilita One`, `Noto Indic`, `Inter`) |
| **Data Visualization** | FL Chart | `fl_chart: ^1.2.0` | Earnings trend line charts, 6-month bar charts, and progress rings |
| **Document Generation** | PDF & Share Plus | `pdf: ^3.13.1`, `share_plus: ^13.3.1` | Official payment receipt PDF generation & system sharing |
| **Push Notifications** | Firebase Cloud Messaging | `firebase_messaging: ^16.7.0`, `local_notifications` | Push notification delivery & heads-up background alerts |

---

## 2. Frontend & Mobile Architecture

### 2.1 Toolchain & Platform Configuration
* **Flutter Version**: Channel Stable (Flutter 3.24+ / Dart ^3.13.2).
* **Android Target**:
  * Namespace: `in.udyogasethu.udyogasethu`
  * Compile SDK: `37`
  * Min SDK: `21` (Android 5.0 Lollipop — supports 99.5% of active Android devices in India)
  * Target SDK: `34` (Android 14)
  * NDK Version: `28.2.13676358`
  * JVM Bytecode Target: `JavaVersion.VERSION_17` (configured across all subprojects)
  * Core Library Desugaring: Enabled via `com.android.tools:desugar_jdk_libs:2.1.4`

### 2.2 Complete Flutter Package Inventory (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management & Routing
  flutter_riverpod: ^3.4.3
  go_router: ^18.0.2

  # Backend & Network
  supabase_flutter: ^2.18.0
  http: ^1.6.0
  connectivity_plus: ^7.3.1
  cached_network_image: ^4.0.4

  # Security & Device Storage
  flutter_secure_storage: ^11.2.0
  shared_preferences: ^2.5.5
  crypto: ^3.0.7
  uuid: ^4.6.0

  # UI Design, Icons & Typography
  cupertino_icons: ^1.0.8
  google_fonts: ^9.0.0
  flutter_svg: ^2.3.0
  fl_chart: ^1.2.0

  # Authentication & Input Helpers
  pinput: ^6.0.2
  smart_auth: ^3.2.0
  google_sign_in: 6.2.2

  # Location, Maps & Hardware APIs
  flutter_map: ^8.3.2
  latlong2: ^0.10.1
  geolocator: ^14.0.1
  geocoding: ^5.0.0
  permission_handler: ^13.0.2
  package_info_plus: ^10.2.1
  url_launcher: ^6.3.2

  # Biometrics & Camera
  camera: ^0.12.1
  image_picker: ^1.2.3
  image: ^4.10.1
  google_mlkit_face_detection: ^0.15.1
  tflite_flutter: ^0.12.1

  # QR Codes & Barcodes
  qr_flutter: ^4.1.0
  mobile_scanner: ^7.4.2

  # Payments & Documents
  razorpay_flutter: ^1.4.7
  pdf: ^3.13.1
  share_plus: ^13.3.1

  # Voice, Audio & Media
  speech_to_text: ^7.5.0
  flutter_tts: ^4.2.5
  audioplayers: ^6.8.1
  record: ^7.1.2

  # Notifications
  firebase_core: ^4.15.0
  firebase_messaging: ^16.7.0
  flutter_local_notifications: ^22.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### 2.3 Localization Framework (`gen-l10n`)
* Fully localized across **8 Indian languages**: English (`en`), Kannada (`kn`), Hindi (`hi`), Telugu (`te`), Tamil (`ta`), Marathi (`mr`), Bengali (`bn`), and Odia (`or`).
* **1,343 individual localization keys** maintained across all 8 `.arb` files with **100% parity verified** via automated script `dart run tool/check_l10n.dart`.
* Native pluralization rules, Indian Rupee currency formatting (`WalletBalance.formatIndianCurrency` handling Lakhs and Crores), and contextual script fallbacks.

### 2.4 Device Permissions Requested
* `android.permission.INTERNET`: REST APIs, Supabase PostgREST, Edge Functions, real-time channels.
* `android.permission.CAMERA`: Front-facing facial liveness, document KYC capture, attendance QR scanning, completion evidence photos.
* `android.permission.RECORD_AUDIO`: Voice assistant speech input, audio query processing.
* `android.permission.ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION`: Proximity job search, Mandi weather radar, PostGIS 150m geofence validation.
* `android.permission.POST_NOTIFICATIONS`: In-app status alerts, hiring updates, escrow milestone alerts.
* `android.permission.VIBRATE`: Haptic feedback on QR ticket scan, timer countdowns, emergency SOS alert.
* `android.permission.READ_MEDIA_IMAGES` & `READ_EXTERNAL_STORAGE`: Profile avatars, organic certifications, dispute photo evidence.

---

## 3. Backend & API Architecture

```
                               ┌────────────────────────────────────────────────────────┐
                               │                    FLUTTER CLIENT                      │
                               └───────────────────────────┬────────────────────────────┘
                                                           │
                                ┌──────────────────────────┴──────────────────────────┐
                                │                                                     │
                     HTTPS / PostgREST RPC                                   HTTPS / Edge Functions
                                │                                                     │
                                ▼                                                     ▼
┌───────────────────────────────────────────────────────────────┐ ┌─────────────────────────────────────────┐
│                     SUPABASE POSTGRESQL                       │ │          DENO EDGE FUNCTIONS            │
│  ├── 75+ Relational Tables                                    │ │  ├── ai-assist (5-Provider Orchestrator)│
│  ├── 100% RLS Security Coverage                               │ │  ├── face-verify (Eden AI Comparison)  │
│  ├── Stored Procedures (SECURITY DEFINER)                     │ │  ├── face-enroll (Biometric Reference)  │
│  ├── PostGIS Spatial Geometries (ST_DWithin, ST_MakePoint)    │ │  ├── qr-issue & qr-verify (HMAC Sign)   │
│  └── Append-Only Financial Ledger                             │ │  ├── payment-create-order & webhook     │
└───────────────────────────────────────────────────────────────┘ │  ├── payment-reconcile & validate-vpa   │
                                                                  │  ├── mandi-sync & no-show-check         │
                                                                  │  └── sos-trigger & whatsapp-notify      │
                                                                  └─────────────────────────────────────────┘
```

### 3.1 Platform Specifications
* **Supabase Project Reference**: `mmzbpeqkfomnywuzoqii`
* **Region**: AWS `ap-southeast-1` (Singapore) / Nearest Indian Gateway
* **Database Engine**: PostgreSQL 15.6 with extensions:
  * `postgis`: Spatial distance, geographic points, and geofencing.
  * `pgcrypto`: Cryptographic hashing, UUID generation, HMAC signing.
  * `pg_trgm`: Trigram fuzzy text matching for worker and skill discovery.
  * `pg_cron` & `pg_net`: Automated scheduled background jobs (e.g. daily morning delivery generator).

### 3.2 Supabase Edge Functions Matrix
All functions execute on Deno in `supabase/functions/` and inherit shared security, CORS, and logging logic from `supabase/functions/_shared/`:

| Edge Function Name | HTTP Auth Requirement | Environment Secrets Utilized | Operational Purpose |
| :--- | :--- | :--- | :--- |
| `ai-assist` | User JWT (`Bearer <token>`) | `GROQ_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY`, `DEEPGRAM_API_KEY`, `HUGGINGFACE_API_KEY` | 5-provider AI orchestrator for voice dialogue, crop pest vision, and audio STT/TTS |
| `face-verify` | User JWT (`Bearer <token>`) | `EDENAI_API_KEY` | Verifies selfie against stored reference photo via Eden AI cloud engine |
| `face-enroll` | User JWT (`Bearer <token>`) | `FACE_MATCHER` | Enrolls initial baseline photo and 128d Float32 biometric embedding |
| `qr-issue` | User JWT (`Bearer <token>`) | `QR_SIGNING_SECRET` | Issues short-lived (120s), signed HMAC-SHA256 attendance QR tokens |
| `qr-verify` | User JWT (`Bearer <token>`) | `QR_SIGNING_SECRET` | Verifies and consumes signed QR attendance tokens in constant time |
| `payment-create-order` | User JWT (`Bearer <token>`) | `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Server-authoritative bill calculation & Razorpay order generation |
| `payment-webhook` | Signature Header (`x-razorpay-signature`) | `RAZORPAY_WEBHOOK_SECRET` | Webhook receiver verifying constant-time HMAC signature & holding escrow |
| `payment-reconcile` | User JWT (`Bearer <token>`) | `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Out-of-band bank status verification for pending UPI payments |
| `validate-vpa` | User JWT (`Bearer <token>`) | `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Validates customer UPI VPA formats against banking NPCI records |
| `no-show-check` | Service Role Auth | `SUPABASE_SERVICE_ROLE_KEY` | Scheduled scanner flagging overdue worker check-ins and initiating replacement |
| `assignment-verify` | User JWT (`Bearer <token>`) | None (PostGIS + RPCs) | Two-step attendance check, mock location detection, and mid-job verification |
| `mandi-sync` | Service Role Auth | `DATA_GOV_API_KEY` | Syncs APMC wholesale crop prices from Government open data portal |
| `sos-trigger` | User JWT (`Bearer <token>`) | `SMS_GATEWAY_KEY` | Broadcasts emergency SOS alerts, logs GPS coordinates, and alerts contacts |
| `send-push` | Service Role Auth | `FCM_SERVICE_ACCOUNT_KEY` | Dispatches localized Firebase Cloud Messaging push notifications |
| `whatsapp-notify` | Service Role Auth | `WHATSAPP_CLOUD_API_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID` | Dispatches WhatsApp booking receipts and alerts via Meta Cloud API |
| `delete-account` | User JWT (`Bearer <token>`) | `SUPABASE_SERVICE_ROLE_KEY` | GDPR/DPDP compliant account anonymization and storage object purging |

---

## 4. AI & Voice Assistant Technology

### 4.1 5-Provider Orchestration Topology
The `ai-assist` Edge Function decouples the mobile client from underlying AI vendor APIs, preventing secret leakage into APK bundles:

```
                                ┌──────────────────────────────────────┐
                                │       Flutter Client Voice UI        │
                                └──────────────────┬───────────────────┘
                                                   │
                                     POST /functions/v1/ai-assist
                                                   │
                                                   ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                               DENO ORCHESTRATOR (ai-assist/index.ts)                                  │
│                                                                                                        │
│   ├── CircuitBreakerRegistry (3-failure threshold, 30s cooldown probe)                                 │
│   ├── Language Context Injector (preserves Indic script, rupee units, crop terminology)                │
│   └── PII Scrubber (strips phone numbers, Aadhaar patterns, exact GPS before cloud dispatch)          │
└──────────────┬───────────────────────────┬───────────────────────────┬─────────────────────────┬───────┘
               │                           │                           │                         │
               ▼                           ▼                           ▼                         ▼
      ┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐       ┌────────────────┐
      │      GROQ       │         │  GOOGLE GEMINI  │         │   OPENROUTER    │       │    DEEPGRAM    │
      │  qwen/qwen3.8   │         │ gemini-1.5-flash│         │  llama-3.1-8b   │       │ Aura (TTS)     │
      │  Whisper Turbo  │         │ Multimodal Agro │         │ Multi-Cloud Fall│       │ Nova-2 (STT)   │
      └─────────────────┘         └─────────────────┘         └─────────────────┘       └────────────────┘
```

* **Conversational Dialogue**: Routed to **Groq** for high-speed inference. Falls back to **Gemini**, then **OpenRouter**.
* **Multimodal Crop Vision**: Routed directly to **Gemini** for leaf disease, pest diagnosis, and soil card interpretation.
* **Audio Transcription**: Processed locally via Android `SpeechToText`; falls back to Cloud STT on **Groq Whisper Large v3 Turbo** or **Deepgram Nova-2**.
* **Speech Synthesis**: Output synthesized via **Deepgram Aura** (`aura-asteria-en`) for English, or native on-device Android TTS (`FlutterTts`) for regional Indic scripts (`kn`, `hi`, `te`, `ta`, etc.).

---

## 5. Biometric Identity & Face Verification Architecture

* **Camera Stream**: Configured via `camera: ^0.12.1` with resolution preset `medium` (optimal for mobile tensor pipelines).
* **Face Detection & Liveness**: Google ML Kit (`google_mlkit_face_detection`) processes frames at 25–30 FPS:
  * Computes bounding box size (must occupy 12%–70% of frame).
  * Validates head pose angles: Euler Y (yaw) $\pm 15^\circ$, Euler Z (roll) $\pm 15^\circ$.
  * Randomized 2-step challenge state machine: Blink detection (open $\to$ closed $\to$ open transition), Head turn (Euler Y $<-15^\circ$ or $>+15^\circ$), or Smile ($>0.6$ probability).
* **Feature Extraction**: MobileFaceNet model (`assets/models/mobilefacenet.tflite`) normalizes face crops to $112 \times 112$ pixels and outputs a 128-element Float32 vector.
* **Server Verification Pipeline**: Live selfie captured via `takePicture()` is dispatched over HTTPS to `face-verify`. Eden AI compares live selfie against reference photo stored in private bucket `face-refs/{user_id}/ref.jpg`. Cosine similarity RPC `compare_face_embeddings` validates vector norms. Threshold locked at **0.65 similarity** (FAR $<0.01\%$).

---

## 6. Payments, Escrow Vault & Financial Integrity

* **Payment Gateway**: Integration with Razorpay India (`razorpay_flutter: ^1.4.7`). Supports UPI Intent, Dynamic QR, NetBanking, and RuPay/Cards.
* **Double-Entry Financial Ledger**: Table `public.ledger_entries` enforces financial integrity. A database trigger (`trg_prevent_ledger_mutation`) strictly blocks `UPDATE` and `DELETE` operations on ledger rows.
* **Server-Authoritative Pricing**: Amounts are never calculated on the mobile device. RPC `compute_payment_bill` calculates base wage, 5% platform commission, 18% GST, and protection fee in integer paise.
* **Escrow Lifecycle**:
  * On payment capture, `hold_escrow` locks funds in the payer's escrow debit bucket.
  * On verified job completion, `release_escrow` credits the worker's available wallet balance net of platform fees.
  * If a dispute is raised, `create_assignment_dispute` immediately sets `status = 'disputed'`, freezing all automated escrow releases until administrative arbitration.

---

## 7. Storage Buckets & Policies

| Bucket Identifier | Visibility | Maximum Size | Allowed MIME Types | Read Policy | Write Policy |
| :--- | :---: | :---: | :--- | :--- | :--- |
| `avatars` | **Public** | 5 MB | `image/jpeg`, `image/png`, `image/webp` | Anyone (Public) | Folder owner (`{user_id}/*`) |
| `produce-images` | **Public** | 10 MB | `image/jpeg`, `image/png`, `image/webp` | Anyone (Public) | Authenticated farmer owner |
| `listing-images` | **Public** | 10 MB | `image/jpeg`, `image/png`, `image/webp` | Anyone (Public) | Authenticated poster owner |
| `community` | **Public** | 10 MB | `image/jpeg`, `image/png`, `image/webp` | Anyone (Public) | Platform Admin only |
| `kyc-docs` | **Private** | 10 MB | Images, PDF | Owner or Admin | Folder owner (`{user_id}/*`) |
| `face-refs` | **Private** | 5 MB | `image/jpeg`, `image/png` | Owner or Admin | Folder owner (`{user_id}/*`) |
| `job-evidence` | **Private** | 25 MB | Images, MP4, MP3, WAV | Assignment Counterparties | Folder owner (`{user_id}/*`) |
| `dispute-evidence`| **Private** | 25 MB | Images, PDF, Audio | Dispute Counterparties | Folder owner (`{user_id}/*`) |
| `chat-attachments`| **Private** | 15 MB | Images, PDF, Audio | Thread Participants | Conversation Member |

---

## 8. Document Metadata
* **Author**: Senior Software Architect & Technical Documentation Engineer
* **Source Validation**: Verified directly against `pubspec.yaml`, `pubspec.lock`, `build.gradle.kts`, `AndroidManifest.xml`, and Supabase migration files.
