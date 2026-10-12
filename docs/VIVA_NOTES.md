# UdyogaSethu — Viva & Evaluation Cheatsheet

A concise, high-impact summary of UdyogaSethu's architecture, key differentiators, limitations, and future roadmap for evaluators and technical interviewers.

---

## 1. Architecture & Technology Choices

```
[ Flutter 3.29.0 Client ]
  ├── Feature-First Modular Structure (lib/features/{auth,seeker,provider,farmer,wallet,trust,...})
  ├── Riverpod State Management (Notifier / AsyncNotifier, zero code-gen except l10n)
  ├── Declarative Navigation (GoRouter with multi-layered role & auth state guards)
  └── Offline Cache Service (Read cache + safe mutation queue; financial actions strictly blocked)
           │
           ▼
[ Supabase Backend Infrastructure ]
  ├── PostgreSQL 15 Engine (75 tables, 100% RLS coverage, immutable security triggers)
  ├── Row Level Security (Strict tenancy, role-based filters, zero cross-user leakage)
  ├── Server-Authoritative Logic (Double-entry ledger, escrow holds, gamification XP triggers)
  ├── Deno Edge Functions (payment-create-order, payment-webhook, face-enroll, kyc-callback)
  └── Private & Public Storage Buckets (Signed short-lived URLs for KYC, face vectors & evidence)
```

* **Why Flutter?** Single codebase targeting Android with zero UI compromises, fluid 60fps animations, rich typography, and native sensor integration (Camera, ML Kit, TTS, Haptics).
* **Why Supabase + PostgreSQL?** Built-in Row-Level Security (RLS) ensures authorization boundaries at the database level. Financial logic, commission deductions, and XP awards run inside PostgreSQL transactions, preventing client manipulation.
* **Why Riverpod?** Compile-time safety, lifecycle-bound scoping, effortless test overriding (`ProviderScope.overrides`), and decoupled dependency injection.

---

## 2. Five Strongest Differentiators

1. **Complete Indic Multilingual & Voice-First Access**:
   * Full localization across 8 languages (English, Kannada, Hindi, Telugu, Tamil, Marathi, Bengali, Odia) with 1,273 keys per language.
   * Offline keyword-based Intent Engine for all 5 primary Indic languages allowing hands-free navigation.
   * Simple Mode with high-contrast 6-action tactile dock and native Text-to-Speech (TTS) voice hints for low-literacy users.

2. **Server-Authoritative Trust & Double-Entry Escrow Ledger**:
   * Clients cannot alter payment amounts, wage rates, or balances. `compute_payment_bill` authoritatively derives base wages, 5% platform fees, and 18% GST in paise on the server.
   * Upfront escrow lock prevents employer non-payment; instant two-step QR ticket verification releases wages directly to worker wallets.
   * Active disputes instantly freeze escrow settlements with atomic isolation.

3. **Multi-Role Rural & Urban Ecosystem in One App**:
   * Unifies **Job Seekers** (informal laborers, students, part-time workers), **Job Providers** (households, contractors), and **Farmers** (produce marketplace, APMC Mandi feeds, farm machinery rental).
   * Strict `ONE ACCOUNT = ONE ROLE` policy with automated role conflicts resolution and multi-tier profile onboarding wizards.

4. **Zero Layout Overflow & Accessibility Guarantee**:
   * 100% automated test coverage across screen widths (320dp to 600dp), text scale factors (1.0× to 1.6×/2.0×), and regional scripts.
   * Minimum 48dp touch targets, semantic icons with textual labels, and high-contrast color palettes (Emerald `#0F5132`, Warm Orange `#D97706`).

5. **Privacy-Preserving Edge Verification & Anti-Fraud Gates**:
   * Facial embeddings (128-float32 vectors via MobileFaceNet TFLite) processed on-device with randomized ML Kit liveness challenges (blink, head turn, smile); raw face photos are never stored.
   * Dynamic non-PII HMAC QR tickets with 30-minute validity preventing ticket replay or attendance tampering.
   * Offline Cache service explicitly fails-fast with `BlockedOfflineActionException` on payments, payouts, or QR check-ins.

---

## 3. Current Limitations & Honest Engineering Disclosures

* **Simulated Financial Escrow**: Payment rails run on Razorpay Test Mode sandbox (`rzp_test_...`). The platform is not an RBI-regulated escrow NBFC/bank.
* **Mock eKYC & DigiLocker**: Verification uses `MockProvider` with synthetic Aadhaar masks; production deployment requires commercial DigiLocker/UIDAI ASP/KUA agreements.
* **In-App SOS Dispatch**: Emergency SOS triggers in-app push notifications and SMS intents to pre-configured personal contacts; it does **not** dial 112/100 police dispatch automatically.
* **Telephony Masking Simulation**: Phone call bridging uses in-app simulated timer interfaces unless configured with live Exotel / Twilio PSTN credentials.
* **On-Device Biometric Enclave**: On-device face embedding matching provides convenience verification but is not an iBeta Level 2 certified anti-spoofing cloud biometric enclave.

---

## 4. Production Roadmap & Required Integrations

| Milestone | Target Capability | Required Integration / External Service |
| :--- | :--- | :--- |
| **Q1 2027** | Live Payment & Escrow Settlement | Razorpay Live Gateway + RBI Nodal/Escrow Account Partner |
| **Q1 2027** | Production Aadhaar / DigiLocker eKYC | Protean / NSDL / Karza DigiLocker API + UIDAI OTP Gate |
| **Q2 2027** | National ERSS 112 Police Integration | State Police Emergency Response Support System (ERSS 112 API) |
| **Q2 2027** | Real Telephony Voice Masking | Exotel / Twilio Voice Proxy API with virtual DID number pool |
| **Q3 2027** | Live APMC Mandi & Weather Feeds | Agmarknet (CACP) Live Mandi API + IMD Agri-Meteorology API |
| **Q3 2027** | Certified Biometric Liveness | iBeta Level 2 Certified Cloud Face Liveness Gateway |
| **Q4 2027** | Production Micro-Insurance | IRDAI-regulated Insurer API (PMSBY / Parametric Crop Insurance) |
