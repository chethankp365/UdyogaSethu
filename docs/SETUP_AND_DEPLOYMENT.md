# UdyogaSethu — Environment Setup, Build, Testing & Deployment Guide

> **Document Version**: 1.0.0  
> **Target Audience**: Core Developers, DevOps Engineers, and Release Managers  
> **Repository**: `in.udyogasethu.udyogasethu`

---

## 1. Prerequisites & Toolchain Specifications

Ensure the following tools and development environments are installed on your host system:

| Tool / Runtime | Minimum Version | Recommended Version | Verification Command |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | 3.24.0 | 3.24.5+ (Stable Channel) | `flutter --version` |
| **Dart SDK** | 3.5.0 | 3.5.4+ (Bundled with Flutter) | `dart --version` |
| **Java Development Kit (JDK)** | OpenJDK 17 | Eclipse Temurin 17 (LTS) | `java -version` |
| **Android SDK Build-Tools** | 34.0.0 | 34.0.0 / 37.0.0 | `sdkmanager --list` |
| **Android NDK** | 25.x | 28.2.13676358 | Inspected in `android/app/build.gradle.kts` |
| **Node.js & npm** | Node 18.x | Node 20.x LTS | `node -v` |
| **Deno Runtime** | 1.40.0 | 1.45.0+ | `deno --version` |
| **Supabase CLI** | 1.150.0 | Latest (`npx supabase -v`) | `npx supabase --version` |

---

## 2. Configuration & Secret Management

### 2.1 Client-Side Environment Variables (`env.json`)
The Flutter client reads configuration variables during compilation via `--dart-define-from-file=env.json` or individual `--dart-define=KEY=VALUE` flags. 

Create `env.json` in the root project directory (modeled after `env.example.json`):

```json
{
  "SUPABASE_URL": "https://<your-project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<your-public-anon-jwt-token>",
  "GOOGLE_WEB_CLIENT_ID": "<your-google-oauth-web-client-id>.apps.googleusercontent.com",
  "RAZORPAY_KEY_ID": "rzp_test_<your-razorpay-key-id>",
  "DEMO_BUILD": "true"
}
```

> [!CAUTION]
> **Zero Client Secret Invariant**: Never store private API keys, Razorpay secret keys, service-role keys, or LLM tokens in `env.json` or Flutter assets. The client bundle holds only public identifiers. All privileged operations execute exclusively within Supabase Edge Functions.

### 2.2 Server-Side Supabase Secrets
Privileged credentials must be configured strictly on the remote Supabase project using the Supabase CLI:

```bash
npx supabase secrets set --project-ref <your-project-ref> \
  GROQ_API_KEY="gsk_..." \
  GEMINI_API_KEY="AIzaSy..." \
  OPENROUTER_API_KEY="sk-or-..." \
  DEEPGRAM_API_KEY="token..." \
  HUGGINGFACE_API_KEY="hf_..." \
  EDENAI_API_KEY="eyJ..." \
  RAZORPAY_KEY_ID="rzp_test_..." \
  RAZORPAY_KEY_SECRET="..." \
  RAZORPAY_WEBHOOK_SECRET="..." \
  QR_SIGNING_SECRET="<random-32-byte-hex-string>" \
  DATA_GOV_API_KEY="..." \
  SMS_GATEWAY_KEY="..." \
  FCM_SERVICE_ACCOUNT_KEY="..." \
  WHATSAPP_CLOUD_API_TOKEN="..." \
  WHATSAPP_PHONE_NUMBER_ID="..."
```

---

## 3. Database Migration & Deployment

### 3.1 Initializing & Linking Remote Supabase Project
```bash
# 1. Login to Supabase CLI
npx supabase login

# 2. Link repository to remote project ref
npx supabase link --project-ref <your-project-ref>
```

### 3.2 Pushing Database Migrations
Database migrations are strictly sequential (`0000_ping.sql` through `0811_chat_rpc_and_storage.sql`):

```bash
# Lint migrations for syntax and RLS safety
npx supabase db lint --linked

# Push local migrations to remote PostgreSQL database
npx supabase db push
```

### 3.3 Deploying Edge Functions
Deploy serverless microservices to Supabase Deno infrastructure:

```bash
# Deploy 5-Provider AI Assistant (with public health probe enabled)
npx supabase functions deploy ai-assist --no-verify-jwt

# Deploy Razorpay Webhook Receiver (requires unauthenticated inbound signature verification)
npx supabase functions deploy payment-webhook --no-verify-jwt

# Deploy Authenticated Core Edge Functions
npx supabase functions deploy payment-create-order
npx supabase functions deploy payment-reconcile
npx supabase functions deploy validate-vpa
npx supabase functions deploy face-enroll
npx supabase functions deploy face-verify
npx supabase functions deploy qr-issue
npx supabase functions deploy qr-verify
npx supabase functions deploy assignment-verify
npx supabase functions deploy no-show-check
npx supabase functions deploy sos-trigger
npx supabase functions deploy send-push
npx supabase functions deploy whatsapp-notify
npx supabase functions deploy mandi-sync
npx supabase functions deploy delete-account
```

---

## 4. Running the Flutter Application Locally

### 4.1 Dependency Resolution & Asset Generation
```bash
# Fetch Dart & Flutter dependencies
flutter pub get

# Compile localized ARB files to Dart classes
flutter gen-l10n
```

### 4.2 Running in Development Mode
```bash
# Run on connected Android device / emulator with env.json
flutter run --dart-define-from-file=env.json

# Run in explicit Demo Mode (evaluator test accounts enabled)
flutter run --dart-define-from-file=env.json --dart-define=DEMO_BUILD=true
```

---

## 5. Quality Assurance & Automated Test Protocol

Always execute the complete verification suite before committing code:

```bash
# 1. Static Analysis (Enforces 0 warnings, 0 errors)
flutter analyze

# 2. Localization Parity Audit (Checks 100% key completeness across 8 languages)
dart run tool/check_l10n.dart

# 3. Secret Leakage Scanner (Scans 530+ files & APK bundles for credentials)
dart run tool/secret_scan.dart

# 4. Comprehensive Zero-Layout-Overflow Matrix Test
# Tests 1,200 layout checks across 320–600dp, text scales 1.0–2.0, and 5 locales
# Windows:
tool\check_overflow.bat
# Linux / macOS:
./tool/check_overflow.sh

# 5. Full Automated Unit & Widget Test Suite (87 test files)
flutter test

# 6. Deno Edge Function Orchestrator Test Suite
deno test --allow-net --allow-env supabase/functions/ai-assist/orchestrator_test.ts
```

---

## 6. Android Build & Release Packaging

### 6.1 JVM Memory Optimization for R8 Code Shrinking
In `android/gradle.properties`, ensure the JVM compiler daemon has sufficient heap memory allocated to prevent out-of-memory errors during ProGuard shrinking:
```properties
org.gradle.jvmargs=-Xmx2048M -XX:MaxMetaspaceSize=512M
```

### 6.2 Building Production Artifacts

```bash
# 1. Direct Physical Device Testing APK (arm64-v8a: ~68.2 MB)
# Recommended for installing directly on modern Indian Android phones
flutter build apk --release --target-platform=android-arm64 --dart-define-from-file=env.json

# 2. Split-per-ABI APKs (Builds arm64, armeabi-v7a, and x86_64 APKs)
flutter build apk --release --split-per-abi --dart-define-from-file=env.json

# 3. Universal Fat Release APK (~160.4 MB, contains all ABIs)
flutter build apk --release --dart-define-from-file=env.json

# 4. Google Play Store App Bundle (AAB: ~132.1 MB)
flutter build appbundle --release --dart-define-from-file=env.json
```

---

## 7. Troubleshooting & Common Pitfalls

1. **Android Microphone Error 5 (`ERROR_CLIENT`) / Error 7 (`ERROR_SPEECH_TIMEOUT`)**:  
   * *Root Cause*: Two audio clients simultaneously attempting to capture the native hardware microphone.
   * *Fix*: `VoiceService` enforces single coordinated audio ownership. `AudioRecorder` is decoupled during active `SpeechToText` listening sessions.
2. **PostgreSQL Migration Error `42P13` ("cannot change return type of existing function")**:  
   * *Root Cause*: Attempting `CREATE OR REPLACE FUNCTION` on a function whose return columns have changed.
   * *Fix*: Always issue `DROP FUNCTION IF EXISTS function_name(...)` immediately preceding the new signature in migration files.
3. **PostgREST Schema Cache Desynchronization**:  
   * *Symptom*: Client throws `PGRST202` or `PGRST204` stating a function or column is missing despite applying migrations.
   * *Fix*: Execute `NOTIFY pgrst, 'reload schema';` in the Supabase SQL editor to force immediate schema reload.
4. **Android App Bundle Debug Symbol Stripping Failure**:  
   * *Symptom*: `bundleRelease` succeeds, but Flutter reports symbol stripping failure exit code 1.
   * *Fix*: Install `Android SDK Command-line Tools (latest)` via Android Studio SDK Manager.

---

## 8. Document Metadata
* **Author**: Senior DevOps Engineer & Technical Documentation Specialist
* **Verification**: Grounded directly in `pubspec.yaml`, `android/app/build.gradle.kts`, `android/gradle.properties`, and `supabase/config.toml`.
