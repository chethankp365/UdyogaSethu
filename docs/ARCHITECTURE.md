# UdyogaSethu — End-to-End System Architecture & Data Flow

> **Document Version**: 1.0.0  
> **Target Audience**: Technical Architects, Backend Engineers, and Security Auditors  
> **Repository**: `in.udyogasethu.udyogasethu`

---

## 1. Architectural Blueprint & Layered Topology

UdyogaSethu is built using a **Feature-First, Clean Layered Architecture** with strict boundaries between presentation, domain entities, data repositories, and remote cloud infrastructure.

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   LAYER 1: PRESENTATION & UI                                │
│   Screens, Dialogs, Adaptive Bottom Sheets, Touch-Target Widgets, Theme Tokens, Canvas      │
└──────────────────────────────────────────────┬──────────────────────────────────────────────┘
                                               │ Watches & Dispatches Events
                                               ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                            LAYER 2: STATE MANAGEMENT & SERVICES                             │
│   Riverpod 3 Notifiers, StreamProviders, LiveLocationService, BootstrapService, Routing    │
└──────────────────────────────────────────────┬──────────────────────────────────────────────┘
                                               │ Invokes Use-Cases / Repository Interfaces
                                               ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                               LAYER 3: DATA & REPOSITORY LAYER                              │
│   Plain Dart DTOs, Exception Mapping (AppException), Offline Cache, Realtime Listeners      │
└──────────────────────────────────────────────┬──────────────────────────────────────────────┘
                                               │ HTTPS / WSS / JWT
                                               ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                             LAYER 4: BACKEND AS A SERVICE (BaaS)                            │
│   Supabase Auth (GoTrue), PostgREST REST APIs, WebSocket Realtime, Encrypted S3 Storage     │
└───────────────────────┬─────────────────────────────────────────────┬───────────────────────┘
                        │                                             │
                        ▼                                             ▼
┌───────────────────────────────────────────────┐ ┌───────────────────────────────────────────┐
│        LAYER 5: POSTGRESQL & POSTGIS          │ │      LAYER 6: SERVERLESS EDGE FUNCTIONS   │
│  ├── 75+ Tables with 100% RLS Policy Coverage │ │  ├── TypeScript Deno Microservices        │
│  ├── Append-Only Financial Ledger             │ │  ├── Constant-Time Webhook Verification   │
│  ├── Spatial Search (ST_DWithin, GIST)        │ │  ├── 5-Provider AI Assistant Orchestrator │
│  └── Atomic Stored Procedures (PL/pgSQL)      │ │  └── Biometric Comparison (Eden AI)       │
└───────────────────────────────────────────────┘ └─────────────────────┬─────────────────────┘
                                                                        │ External API Calls
                                                                        ▼
                                                  ┌───────────────────────────────────────────┐
                                                  │       LAYER 7: EXTERNAL PLATFORM APIS     │
                                                  │  ├── Groq LPU (Conversational Dialogue)   │
                                                  │  ├── Google Gemini (Multimodal Vision)    │
                                                  │  ├── Deepgram (Neural Voice & Cloud STT)  │
                                                  │  ├── OpenRouter (Multi-Cloud Failover)    │
                                                  │  ├── Eden AI (AWS Rekognition Comparison) │
                                                  │  └── Razorpay India (Payment Gateway)     │
                                                  └───────────────────────────────────────────┘
```

---

## 2. Core Architectural Design Principles

1. **Feature-First Organization**:  
   Code is organized by business feature (`lib/features/<feature>/`) rather than technical role. Each feature strictly encapsulates:
   * `data/`: Repositories, Supabase PostgREST clients, DTOs with `fromJson`/`toJson`.
   * `domain/`: Pure Dart immutable models, enums, calculation helpers, and repository contracts.
   * `presentation/`: Riverpod state notifiers, screens, and micro-widgets.
2. **UI Never Directly Calls Supabase**:  
   Widgets only interact with Riverpod providers and repositories. Raw database calls, JSON parsing, and PostgREST exceptions are trapped in repositories and mapped to typed `AppException` classes.
3. **Single Active Role Policy (D4)**:  
   A user account is strictly bound to one active role (`UserRole.seeker`, `UserRole.provider`, or `UserRole.farmer`). The navigation shell and security guards enforce absolute role segregation.
4. **Server-Authoritative Business Logic & Money**:  
   Client applications never calculate wages, platform fees, or wallet balances. Prices, commissions, and escrow releases are computed inside PostgreSQL stored procedures or Deno Edge Functions using server-held secrets.
5. **Zero-Trust Biometrics & Dynamic Tokens**:  
   Physical attendance requires two independent, cryptographically validated factors: an employer scan of a rotating 120-second signed QR token, followed by a front-camera selfie validated against enrolled face vectors within a 150m PostGIS geofence.

---

## 3. End-to-End Request Tracing (Mermaid Sequence Diagrams)

### 3.1 Trace 1: Submitting a Job Application & Real-time Hiring

The sequence illustrates pre-application eligibility checking, database application creation, real-time sync across devices, employer applicant review, and slot allocation.

```mermaid
sequenceDiagram
    autonumber
    actor Seeker as Job Seeker (Worker)
    participant UI as Seeker Home / JobDetailScreen
    participant Repo as SeekerJobsRepository
    participant DB as Supabase PostgreSQL
    actor Provider as Job Provider (Employer)
    participant ProvUI as JobApplicantsScreen

    Seeker->>UI: Taps "Apply Now"
    UI->>Repo: checkEligibility(jobId)
    Repo->>DB: RPC public.check_job_eligibility(jobId)
    Note over DB: Evaluates DL requirement, verified status,<br/>audience mismatch & active schedule overlaps
    DB-->>Repo: Returns { is_eligible: true, reasons: [] }
    Repo-->>UI: Eligibility Verified

    Seeker->>UI: Enters application note & confirms
    UI->>Repo: applyToJob(jobId, note)
    Repo->>DB: RPC public.apply_to_job(jobId, note)
    Note over DB: Inserts into public.job_applications<br/>(unique partial index prevents duplicates)
    DB-->>Repo: Returns application UUID
    Repo-->>UI: Updates myApplicationsProvider (Optimistic Green Applied)

    par Realtime Event Broadcast
        DB--)ProvUI: Realtime Event: INSERT on job_applications
        ProvUI->>ProvUI: Auto-refreshes applicants list & slot count
    end

    Provider->>ProvUI: Inspects applicant profile & taps "Hire"
    ProvUI->>DB: RPC public.respond_to_application(appId, 'hire')
    Note over DB: Checks slots_filled < slots_total.<br/>Increments slots_filled.<br/>Creates row in public.job_assignments.<br/>Inserts row in public.notifications.
    DB-->>ProvUI: Status updated to 'hired'

    par Realtime Status Sync
        DB--)UI: Realtime Event: UPDATE on job_applications ('hired')
        UI->>UI: myApplicationsProvider transitions to "Hired / Show Ticket"
    end
```

---

### 3.2 Trace 2: Voice AI Assistant Query & Intent Routing

This sequence demonstrates speech capture, edge function orchestration across AI vendors, circuit breakers, structured intent parsing, and client-side navigation.

```mermaid
sequenceDiagram
    autonumber
    actor User as Mobile App User
    participant Mic as Android SpeechRecognizer
    participant Voice as VoiceService / VoiceAssistantModal
    participant Edge as Deno Edge Function (ai-assist)
    participant AI as 5-Provider Orchestrator (Groq / Gemini)
    participant TTS as Deepgram Aura / Device TTS
    participant Router as GoRouter Navigation

    User->>Voice: Taps Center Floating Mic FAB
    Voice->>Mic: Initializes audio stream with user locale (e.g. kn-IN)
    Mic-->>Voice: Streams live partial transcription text
    User->>Voice: Finishes speaking: "Find me electrical jobs nearby"
    Voice->>Voice: Stops mic & validates transcript length

    Voice->>Edge: POST /functions/v1/ai-assist { text, locale: 'kn', role: 'seeker' }
    Note over Edge: Validates JWT token.<br/>Fetches authoritative role from profiles table.<br/>Scrubs PII & phone numbers.
    Edge->>AI: queryGroqChatCompletion(systemPrompt, userText)
    Note over AI: Preferred fast LPU (qwen/qwen3.8).<br/>Falls back to Gemini on failure.
    AI-->>Edge: Structured JSON: { reply_text, intent: 'open_nearby_jobs', params: { category: 'electrician' } }

    opt Audio Speech Synthesis
        Edge->>TTS: Synthesizes speech (Deepgram Aura for EN / Native TTS for Indic)
        TTS-->>Edge: base64 audio stream
    end

    Edge-->>Voice: Returns VoiceIntentResult with telemetry (145ms latency)
    Voice->>Voice: Plays spoken reply & renders animated soundwave
    Voice->>Router: Executes client action: router.push('/seeker/jobs?category=electrician')
    Router-->>User: Displays filtered electrical jobs screen
```

---

### 3.3 Trace 3: Two-Step Verified Attendance Check-in

This sequence outlines the two-factor site check-in flow: an employer dynamic QR code scan followed by worker facial liveness and PostGIS geofencing.

```mermaid
sequenceDiagram
    autonumber
    actor Worker as Job Seeker (Worker)
    participant WorkerUI as JobTicketScreen
    actor Employer as Job Provider (Employer)
    participant EmpUI as AttendanceScannerScreen
    participant Edge as Edge Functions (qr-verify & assignment-verify)
    participant DB as Supabase PostgreSQL

    Worker->>WorkerUI: Opens Job Ticket Pass
    WorkerUI->>Edge: POST /functions/v1/qr-issue { assignment_id }
    Note over Edge: Validates worker assignment ownership.<br/>Generates 120s HMAC-SHA256 signed token.<br/>Logs token hash into qr_tokens table.
    Edge-->>WorkerUI: Returns dynamic signed token string
    WorkerUI->>WorkerUI: Renders dynamic QR code with 120s countdown ring

    Employer->>EmpUI: Scans Worker QR with MobileScanner
    EmpUI->>Edge: POST /functions/v1/qr-verify { token, employer_lat, employer_lng }
    Note over Edge: Constant-time HMAC validation.<br/>Checks token expiry & replay status in qr_tokens.<br/>Validates employer is within job site geofence.
    Edge->>DB: RPC public.record_ticket_attendance(assignment_id, employer_gps)
    Note over DB: Updates job_assignments.status = 'arrived'.<br/>Inserts into public.attendance_logs.<br/>Logs timeline event 'Worker Arrived'.
    DB-->>Edge: Check-in recorded
    Edge-->>EmpUI: Displays Verified Worker arrival card

    par Step 2 Presence Trigger
        DB--)WorkerUI: Realtime Event: status = 'arrived'
        WorkerUI->>WorkerUI: Automatically pops up VerifyPresenceScreen
    end

    Worker->>WorkerUI: Performs front-camera liveness challenges (Blink, Smile)
    WorkerUI->>WorkerUI: Captures high-res selfie & reads device GPS
    WorkerUI->>Edge: POST /functions/v1/assignment-verify { action: 'start', selfie, lat, lng }
    Note over Edge: Validates PostGIS distance <= 150m.<br/>Checks mock location flags.<br/>Compares selfie against face-refs via Eden AI.
    Edge->>DB: RPC public.record_verified_start(assignment_id, worker_gps)
    Note over DB: Updates status = 'in_progress_verified'.<br/>Sets started_at = NOW().<br/>Activates work duration timer.
    DB-->>Edge: Verified start confirmed
    Edge-->>WorkerUI: Verification passed! Starts live ticking timer on both devices
```

---

### 3.4 Trace 4: Payment Escrow, Completion & Wallet Settlement

This sequence details server-authoritative bill generation, Razorpay checkout, escrow vault locking via webhooks, completed job verification, and double-entry wallet release.

```mermaid
sequenceDiagram
    autonumber
    actor Customer as Employer / Produce Buyer
    participant Client as PaymentCheckoutScreen / Razorpay SDK
    participant Edge as Edge Function (payment-create-order)
    participant DB as Supabase PostgreSQL
    participant RZP as Razorpay Payment Gateway
    participant Webhook as Edge Function (payment-webhook)
    actor Worker as Worker / Farmer

    Customer->>Client: Taps "Pay Securely via Escrow"
    Client->>Edge: POST /functions/v1/payment-create-order { ref_type: 'job', ref_id }
    Note over Edge: Validates user JWT.<br/>Calls compute_payment_bill(ref_type, ref_id).<br/>Calculates base wage + 5% platform fee + 18% GST.
    Edge->>RZP: POST https://api.razorpay.com/v1/orders { amount, currency: 'INR' }
    RZP-->>Edge: Returns { id: 'order_rzp_123', amount }
    Edge->>DB: Inserts row in public.payments (status: 'created')
    Edge-->>Client: Returns { order_id, amount_paise, receipt_no, key_id }

    Client->>RZP: Opens Razorpay Checkout sheet (UPI, NetBanking, Card)
    Customer->>RZP: Completes payment
    RZP-->>Client: Payment success callback

    par Razorpay Server Webhook
        RZP->>Webhook: POST /functions/v1/payment-webhook (with x-razorpay-signature)
        Note over Webhook: Constant-time HMAC-SHA256 signature verification.<br/>Idempotency check against payment_webhook_events.
        Webhook->>DB: Calls public.hold_escrow(payment_id)
        Note over DB: Updates payments.status = 'held'.<br/>Inserts into public.ledger_entries:<br/>Direction: DEBIT, Bucket: ESCROW.
        DB-->>Webhook: Escrow held successfully
        Webhook-->>RZP: HTTP 200 OK
    end

    Note over Customer,Worker: Work is executed and verified (Trace 3).<br/>Worker captures completion evidence photos.

    Customer->>Client: Taps "Confirm Work & Release Payment"
    Client->>DB: RPC public.confirm_job_completion_and_release(assignment_id)
    Note over DB: Verifies caller is job owner.<br/>Checks no open disputes exist on assignment.<br/>Atomically debits payer's escrow balance.<br/>Credits payee available wallet balance (net 5% fee).<br/>Credits platform revenue account.<br/>Updates payments.status = 'released'.<br/>Updates job_assignments.status = 'payment_released'.
    DB-->>Client: Release confirmed

    par Balance Update
        DB--)Worker: Realtime update on public.ledger_entries
        Worker->>Worker: Wallet balance updates immediately from "Pending Escrow" to "Available"
    end
```

---

## 4. Key Architectural Decisions (ADR Reference)

| Decision ID | Architectural Decision Title | Rationale & Trade-Offs |
| :--- | :--- | :--- |
| **D4** | **ONE ACCOUNT = ONE ROLE Policy** | Eliminates role-switching ambiguity on mobile devices, simplifies RLS security policies, and prevents self-hiring conflicts. |
| **D10** | **Mobile Phone Mandatory for Google OAuth** | Indian gig workers frequently possess multiple Google accounts but only one active mobile number tied to UPI. Mandatory phone OTP eliminates duplicate identities. |
| **D11** | **Append-Only Financial Ledger** | Updating wallet balances via direct row mutation invites race conditions and fraud. `ledger_entries` is strictly append-only; wallet balances are computed dynamically. |
| **D22** | **Server-Computed Payment Bills** | Client-submitted amounts are rejected. `compute_payment_bill` calculates wages, platform commissions, and taxes on PostgreSQL to prevent client-side payment tampering. |
| **D35** | **Zero-Storage DigiLocker Integration** | Masked Aadhaar numbers (`XXXX-XXXX-1234`) and certified names are stored; full raw 12-digit UIDAI numbers are scrubbed from all database rows and logs. |
| **D48** | **Dynamic Rotating QR Attendance Passes** | Fixed QR codes printed on badges invite proxy check-ins. QR tokens rotate every 120 seconds and require HMAC-SHA256 signature verification. |
| **D56** | **Hybrid 5-Provider AI Assistant** | Isolates mobile clients from private AI API keys. Groq provides conversational speed (~100ms), Gemini handles multimodal agro-vision, and OpenRouter offers failover redundancy. |

---

## 5. Document Metadata
* **Author**: Senior Software Architect & Technical Documentation Engineer
* **Verification**: All sequence diagrams and data models mapped directly to working source files in `lib/` and migrations in `supabase/migrations/`.
