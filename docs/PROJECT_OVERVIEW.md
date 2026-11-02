# UdyogaSethu — Project Overview & Comprehensive Functional Specification

> **Document Version**: 1.0.0  
> **Target Audience**: Technical Architects, Engineering Leads, Academic Evaluators, and Core Developers  
> **Repository**: `in.udyogasethu.udyogasethu` (Flutter Mobile Client + Supabase Backend)

---

## 1. Executive Summary & Purpose

**UdyogaSethu** (Kannada/Sanskrit: *"The Employment Bridge"*) is a production-grade, multilingual, trust-centric mobile ecosystem designed specifically for India's unorganized and informal economy. It unites three foundational pillars of the rural and semi-urban labor ecosystem onto a single unified platform:

1. **Informal & Skilled Labor Marketplace**: Proximity-based, geofenced matching for daily-wage workers, skilled tradespersons, and college students seeking flexible gigs.
2. **Direct Farm-to-Consumer / Business Agri-Commerce**: Middleman-free agricultural marketplace enabling smallholders and farm cooperatives to sell fresh produce, publish verified crop lots, manage subscriptions, and rent farm equipment.
3. **Cryptographic Trust, Biometrics & Escrow Settlement**: Zero-trust identity verification utilizing on-device MobileFaceNet facial embeddings, government document checks (eKYC/DigiLocker), two-step QR attendance passes, and an append-only double-entry financial escrow ledger.

---

## 2. Problem Statement & Real-World Challenges

India's informal sector employs over 80% of the national workforce (over 400 million individuals) and accounts for nearly half of the GDP, yet operates almost entirely on informal, unwritten, and volatile arrangements.

### Key Pain Points Addressed:
* **The Middleman Trap (The "Mandi & Contractor Tax")**: Daily-wage workers frequently surrender 15%–30% of their daily earnings to labor middlemen (*thekedars*). Similarly, smallholder farmers lose 30%–60% of crop value to commission agents in traditional APMC mandis.
* **Payment Insecurity & Wage Theft**: Unorganized laborers routinely face arbitrary wage deductions, delayed payouts, or total non-payment after full days of physical labor. Conversely, employers fear upfront payments to unvetted workers due to rampant no-show rates.
* **Identity & Safety Deficit in Households**: Household employers, gated communities, and small businesses hesitate to invite informal workers into domestic spaces without verified identity, police verification, or skill credentialing.
* **Biometric & Attendance Fraud**: Ghost attendance, proxy worker check-ins, and remote "sofa check-ins" undermine trust in site-based daily work.
* **Digital Literacy & Linguistic Exclusion**: Standard gig-economy platforms feature dense English UI text, complex nested navigation, and high data consumption, completely alienating low-literacy, regional-language-first workers.

---

## 3. Target Users & Needs Analysis

```
                              ┌─────────────────────────────────────────┐
                              │            UDYOGASETHU ROLES            │
                              └────────────────────┬────────────────────┘
                                                   │
         ┌─────────────────────────────────────────┼─────────────────────────────────────────┐
         │                                         │                                         │
┌────────┴────────┐                       ┌────────┴────────┐                       ┌────────┴────────┐
│   JOB SEEKER    │                       │  JOB PROVIDER   │                       │     FARMER      │
└────────┬────────┘                       └────────┬────────┘                       └────────┴────────┘
         │                                         │                                         │
 ├── Informal Daily Wage                   ├── Households                            ├── Smallholders
 ├── Skilled Trade Pro                     ├── Small Contractors                     ├── Dairy Farmers
 └── Student Part-Time                     └── Site Supervisors                      └── Agri-Cooperatives
```

### 3.1 Job Seekers (Workers)
* **Informal Daily Wage Workers**: Masons, loaders, domestic helpers, painters, cleaners.
  * *Needs*: Immediate cash visibility, proximity jobs within walking or cycling distance, fair wage guidance, simple audio-visual UI, guaranteed payment release upon job completion.
* **Skilled Trade Professionals**: Electricians, plumbers, carpenters, drivers, appliance mechanics.
  * *Needs*: Digital trust credentials, review showcase, tool/license verification, repeat customer rosters, protection against client disputes.
* **Student Part-Time Workers**: College students seeking tutoring, event assistance, delivery, and data-entry gigs.
  * *Needs*: Strict time-slot filtering around academic schedules, campus gigs, student ID verification, and no requirement for heavy manual trade tools.

### 3.2 Job Providers (Employers)
* **Households & Apartment Dwellers**: Booking home repairs, cleaning, domestic help, or ordering bulk apartment farm produce.
  * *Needs*: Aadhaar/police background checks, face-verified worker check-in at doorstep, transparent billing, and escrow payment protection.
* **Small Contractors & Site Supervisors**: Hiring crews of 2–10 workers for commercial sites.
  * *Needs*: Multi-slot posting, applicant screening, arrival verification, replacement workers on no-shows, and GST payment receipts.

### 3.3 Farmers (Agri-Producers)
* **Smallholders & Organic Growers**: Growing vegetables, fruits, sugarcane, and grains.
  * *Needs*: Real-time APMC mandi benchmark pricing, direct buyer discovery, batch quality lot traceability, zero middleman deductions, and farm equipment rental.
* **Dairy & Perishable Producers**: Selling fresh morning milk and perishable greens.
  * *Needs*: Recurring daily subscriptions, apartment group bulk orders, delivery slot management, and fast escrow settlement.

---

## 4. Complete User Journey

### Phase 1: Onboarding, Language & Role Selection
1. **App Launch & Brand Intro**: Dynamic version verification, network liveness check, and initial asset caching.
2. **Language Selection**: First-run selection across 8 supported Indian languages (English, Kannada, Hindi, Telugu, Tamil, Marathi, Bengali, Odia). Dynamic locale switcher with immediate native TTS audio preview.
3. **Decision Tree (Role Tree)**:
   * Branch 1: Worker vs. Farmer.
   * Branch 2: (If Worker) Job Seeker vs. Job Provider.
   * Branch 3: (If Seeker) Informal Daily Wage vs. Student Part-Time vs. Flexible Gig Worker.
   * *Policy*: **ONE ACCOUNT = ONE ROLE**. Role choice is strictly persisted and enforced. Conflicting role logins are trapped by `RoleConflictScreen`.

### Phase 2: Authentication & Bootstrapping
1. **Phone OTP Sign-In**: Indian 10-digit mobile number (+91), terms consent recorded in `consent_logs`, 6-digit SMS OTP autofill via Android `smart_auth`, and Supabase Auth session token issuance.
2. **Google OAuth & Account Linking**: Optional Google Sign-In with mandatory mobile phone linking verification and email deduplication.
3. **Session Bootstrapping**: `BootstrapNotifier` restores active session, checks profile completion, evaluates account suspension, queries active role status, and routes to either the Role Profile Wizard or Role Home Shell.

### Phase 3: Role-Specific Profile Wizards
* **Seeker Wizard (7 Steps)**: Basics & photo upload -> Category & skill tagging (filtered by student/informal) -> Experience & rate with live `suggest_wage_band` benchmark -> Working days & shift availability -> OpenStreetMap home pin placement with reverse geocoding -> Student college/license details -> Final review.
* **Provider Wizard (5 Steps)**: Basics -> Provider type (Household vs. Contractor) -> Doorstep site address & landmark -> Permissions & JIT location consent -> Final review.
* **Farmer Wizard (5 Steps)**: Basics -> Farm location (OSM pin) -> Land acreage, primary crops & APMC registration -> Selling & delivery options (farm pickup / delivery radius) -> Final review.

### Phase 4: Core Workflows by Role

#### A. Job Seeker Journey (Finding Work & Getting Paid)
1. **Home Feed & GPS Map**: Views curated recommended jobs scored by skill match, distance, employer rating, and wage compliance. Interactive Leaflet/OSM map shows clustered pins with price tags (`₹850/day`).
2. **Job Application**: Checks pre-application eligibility via `check_job_eligibility` (DL check, audience check, student schedule conflict check, and active shift overlap check). Submits application with optional note.
3. **Real-time Status Sync**: `myApplicationsProvider` updates UI instantly across all screens. Employer reviews applicant in `JobApplicantsScreen` and taps "Hire".
4. **Digital QR Ticket**: Hired seeker receives digital ticket with BookMyShow-style cutouts, 120-second dynamic rotating HMAC-SHA256 QR token, and turn-by-turn route directions.
5. **Two-Step Attendance Verification**:
   * *Step 1*: Employer scans seeker's dynamic QR code using in-app `MobileScanner`. Validates single-use token in `qr_tokens` and verifies provider is within 150m geofence radius. Assignment transitions to `arrived`.
   * *Step 2*: Seeker's app prompts for mandatory presence verification. Seeker performs front-camera liveness challenges (blink/turn head/smile) and captures a selfie. Selfie is verified against enrolled biometric profile via Edge Function `face-verify`. Assignment transitions to `in_progress_verified`.
6. **Live Work Timer**: Server-authoritative timer ticks on both phones. High-value jobs trigger optional midpoint checks.
7. **Job Completion & Evidence**: Seeker captures completion selfie and optional work photos uploaded to private `job-evidence` bucket.
8. **Escrow Release**: Employer confirms completion and releases payment. Funds transfer from held escrow to worker's available wallet balance net of 5% platform fee.
9. **Wallet & Cashout**: Worker views itemized transaction receipt, checks daily earnings vs. goal ring, and initiates simulated bank payout.

#### B. Farmer Journey (Selling Crops & Renting Gear)
1. **Farmer Workspace**: Inspects live Mandi prices (APMC feeds for Tomato, Onion, Potato, Paddy, etc.) with trend indicators and weather radar advisory (precipitation, harvest timing recommendations).
2. **Produce Listing Management**: Adds harvest batches with photos, category, unit price, stock quantity, harvest date, and farming method (Zero-Pesticide Organic, Natural, Conventional). Mandi benchmark card suggests competitive price bands.
3. **Traceability QR Issuance**: System generates HMAC-signed Lot QR code for agricultural traceability.
4. **Order Processing**: Customer orders produce via `CartScreen`. Farmer Kanban board (`/farmer/orders`) moves orders through `Incoming` -> `Packing` -> `Dispatch` -> `Delivered`. Handover verified via 4-digit customer PIN.
5. **Escrow Settlement**: Successful delivery triggers automated escrow release to farmer's digital wallet.

---

## 5. User Roles & Permission Matrix

| Operation / Capability | Job Seeker | Job Provider | Farmer | Admin (Console) |
| :--- | :---: | :---: | :---: | :---: |
| Browse & Search Nearby Jobs | Yes | No | No | Read-only |
| Apply to Jobs | Yes | No | No | No |
| Post Job Listings | No | Yes | Yes (Agri Labour) | Yes (Manage) |
| Scan Attendance QR Tickets | No | Yes | No | Audit |
| View / Present Attendance QR Pass | Yes | No | No | No |
| Facial Liveness & Biometric Check | Yes | Optional | Optional | Audit |
| List Farm Produce & Manage Lots | No | No | Yes | Yes (Moderate) |
| Browse & Purchase Produce / Rent Gear | Yes | Yes | Yes | Audit |
| Setup Recurring Subscriptions | Yes | Yes | No | Audit |
| Wallet Withdrawal / Bank Payout | Yes | Yes (Refunds) | Yes | Oversee |
| Release Job Escrow Payment | No | Yes | No | Override |
| Raise Formal Dispute & Freeze Escrow | Yes | Yes | Yes | Arbitrate |
| AI Voice Assistant (Speech / Query) | Yes | Yes | Yes | No |
| Trigger Emergency SOS Broadcast | Yes | Yes | Yes | Monitor |

---

## 6. Major Modules & System Interactions

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                 FLUTTER CLIENT                                  │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌─────────────────────┐  │
│  │ Seeker Module │ │Provider Module│ │ Farmer Module │ │  Shared Core Hub    │  │
│  │ (Jobs, Map,   │ │ (Post Jobs,   │ │(Mandi, Crops, │ │ (Voice AI, Wallet,  │  │
│  │  Tickets)     │ │  Applicants)  │ │ Resources)    │ │  Trust, Privacy)    │  │
│  └───────┬───────┘ └───────┬───────┘ └───────┬───────┘ └──────────┬──────────┘  │
└──────────┼─────────────────┼─────────────────┼────────────────────┼─────────────┘
           │                 │                 │                    │
           ▼                 ▼                 ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                             DATA ACCESS & REPOSITORIES                          │
│   Riverpod Notifiers -> Domain Models -> Repositories -> Supabase / Edge API   │
└────────────────────────────────────────┬────────────────────────────────────────┘
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        │                                │                                │
        ▼                                ▼                                ▼
┌──────────────────────┐      ┌──────────────────────┐      ┌─────────────────────┐
│  SUPABASE POSTGRES   │      │    EDGE FUNCTIONS    │      │    EXTERNAL APIS    │
│  ├── 75+ Tables      │      │  ├── ai-assist       │      │  ├── Gemini / Groq  │
│  ├── 100% RLS Policy │      │  ├── face-verify     │      │  ├── Deepgram       │
│  ├── PostGIS Spatial │      │  ├── qr-issue/verify │      │  ├── OpenRouter     │
│  └── Ledger Triggers │      │  ├── payment-webhook │      │  ├── Eden AI        │
│                      │      │  └── no-show-check   │      │  └── Razorpay       │
└──────────────────────┘      └──────────────────────┘      └─────────────────────┘
```

### Module Synergy Examples:
* **Jobs + Escrow + Wallet**: Creating a job does not touch wallets. Hiring an applicant reserves funds or checks payment commitment. Job completion triggers `confirm_job_completion_and_release`, transferring funds from buyer escrow debit to worker available credit with 5% platform commission deducted atomically.
* **Attendance + Geofence + Biometrics**: Employer QR scan logs physical coordinates and timestamp into `attendance_logs`. Seeker's subsequent selfie verifies front-facing liveness, calculates vector similarity against `face_profiles`, and validates that seeker coordinates fall within the job's PostGIS geofence circle.

---

## 7. Current Implementation Status Summary

* **Fully Implemented & Automated-Verified**: Role Onboarding, Language Engine (8 Locales), Job Discovery & Map, Job Posting Wizard, Application State Management, QR Ticket Attendance, Geofenced Presence Verification, Escrow Engine, Double-Entry Financial Ledger, Mandi Market Price Feed, Produce Listings & Cart Checkout, Order Lifecycle Tracking, Protected Realtime Chat, Subscriptions, AI Voice Assistant (5-provider orchestrator), Emergency SOS, and Zero Layout Overflow UI system.
* **Sandbox / Simulated Integrations**: Razorpay Payment Gateway (Test Mode / Mock Webhooks), DigiLocker eKYC (Simulated Sandbox Adapter), Masked Calling (Mock telephony proxy / Exotel placeholder), External Welfare Scheme links.
* **Out of Scope**: Web Admin Console (allocated to a separate web/desktop workspace).

---

## 8. Document Metadata
* **Author**: Senior Software Architect & Technical Documentation Engineer
* **Verification**: Grounded directly in repository source code, migrations 0000–0811, and 87 test suites.
