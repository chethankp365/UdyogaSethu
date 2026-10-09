# Architectural & Product Decisions Log

This document records key design, architectural, role model, and implementation decisions made during the development of UdyogaSethu.

| Decision ID | Summary | Status | Notes |
| ----------- | ------- | ------ | ----- |
| D1 | Job Provider = households and employers who hire workers; providers can also buy farm produce and subscriptions | Adopted | Core Role Definition |
| D2 | Seeker types: informal, student, part_time | Adopted | Seeker Classification |
| D3 | Role tree appears before login for new users; choice is stored locally then written after first sign-in | Adopted | Pre-login Role Onboarding |
| D4 | ONE ACCOUNT = ONE ROLE policy. A phone number or Google account registered under one role (seeker, provider, farmer) is strictly bound to that role. Seeker type changes (informal, student, part_time) stay allowed within seeker role. To change roles, the user must delete their account in Settings and re-register. Switchable via public.allow_multi_role() SQL function (0190) and kAllowMultiRole constant in env.dart. (Notes for P4-P6: role switching UI is hidden while kAllowMultiRole = false). | Replaced D4 | Single-Role Enforcement |
| D5 | Admin is the same Flutter codebase, responsive, role-gated | Adopted | Unified Architecture |
| D6 | Five languages fully translated (en, kn, hi, te, ta); mr, bn, or fall back to English until P10.2 | Adopted | Multilingual Strategy |
| D7 | Riverpod without codegen, go_router, supabase_flutter | Adopted | State & Navigation Stack |
| D8 | AI = Gemini API via ai-assist | Adopted | AI Assistant Backend |
| D9 | Temporarily removed permission_handler during P0.2 scaffold to avoid Android compileSdk 37 conflict with AGP 9.1.0; will be re-added in the specific prompt/phase that needs it (e.g. Phase 3/4) | Adopted | Build Compatibility |
| D10 | Account Linking Rules: Worker or farmer accounts must always have a verified phone number. Google-first auth forces phone verification via updateUser(phone) & OTP. Phone-first auth allows linking Google in Settings via manual identity linking; duplicate Google emails across different phone numbers are blocked. | Adopted | Auth & Identity Linking |
| D11 | Account Deletion & Legal Data Retention: Account deletion permanently erases personal profile data (`profiles`, `worker_profiles`, `provider_profiles`, `farmer_profiles`, `user_roles`, `addresses`, `consent_logs`, `emergency_contacts`, `kyc_records`), storage bucket objects (`avatars/{uid}`, `kyc-docs/{uid}`), and the auth user record. To comply with Indian financial and tax audit laws (RBI/GST regulations), financial ledger entries (`ledger_entries`), payment transactions (`payments`), and dispute logs are retained in anonymized format with personal identifiers scrubbed (`review_text = '[Account Deleted]'`). | Adopted | Account Deletion & Compliance |
| D15 | Role & Seeker Type Verification Visibility Matrix: Single source of truth (`verification_visibility.dart`). Aadhaar & Face: All roles. Driving Licence: Seekers only. Student Verification: Student seekers ONLY. Bank/UPI Payout: Seekers & Farmers. Background Check: Seekers & Providers. Enforced in UI, router guards, and database trigger (0230). | Adopted | Verification Visibility Matrix |
| D-QR | QR Verification Contract, Non-PII HMAC Payload, and Role Separation (`digitalId` for Seekers, `scanVerify` for Providers with single-phone demo testing) | Adopted | QR Verification Architecture |
| D-VISIBILITY | Strict Multi-Layer Role & Seeker Type Feature Gating: UI, Route Guards (`app_router.dart`), Edge Function health checks, and Server-Side RPC/Trigger boundaries | Adopted | Role Gating & Security |
| D-AUDIENCE | Job Audience Enforcement: Server-side PostgreSQL RPC filtering (`apply_to_job`, `recommended_jobs`, `nearby_jobs`) with informal seeker gating | Adopted | Job Matching & Audience Rules |
| D-REF-UI | UI Reference Mapping: Every UI prompt matches `docs/reference/UdyogaSetu_Built_Project.pdf` (Page 2 Phone 2 = Home, Page 3 Phone 4 & Page 4 Phone 2 = Profile, Page 4 Phone 4 = Category Change) | Adopted | Design System & UI Truth |
| D-HOME-CLEAN | Removal of Safety Onboarding Card from Home: Redundant card moved exclusively to Profile & Safety Hub to match Page 2 Phone 2 | Adopted | Home Screen Cleanliness |
| D-GOAL-DEFAULT | Today's Goal Default: Standard daily earnings target set to ₹1,500 with interactive modal chip adjuster | Adopted | Daily Goal Gamification |
| D50 | Wallet Balances from View, Ledger-backed Transactions, DB-enforced Overdraw Guard, Demo Withdrawal & UPI Scanner | Adopted | Wallet & Payout Architecture |
| D51 | Razorpay Checkout, Constant-Time Webhook Verification, Escrow Hold & Digital PDF Receipts | Adopted | Payment Processing & Escrow Hold |
| D52 | Escrow Release, Idempotent Settlement, Double-Entry Reconciliation, Dispute Freeze & Auto-Release | Adopted | Escrow Settlement & Release |
| D53 | SQL-Backed Earnings Dashboard & Savings Goal Planner | Adopted | Earnings & Virtual Savings Planner |
| D54 | Farmer Home Workspace, APMC Karnataka Mandi Feed, Open-Meteo Advisory & Essential Suite | Adopted | Farmer Home & Agri Advisory |
| D55 | Farmer Profile Page, Produce Inventory Management, Auto-Status & Buyer Gating | Adopted | Farmer Profile & Produce Listings |

## Known Issues & Planned Fixes (Pre-P5.1)

- **Profile & Auth Foreign Key Cascade vs D11 Legal Financial Retention**:
  - **Issue**: In the live database schema (`0010`, `0020`, `0030`), `profiles.id` references `auth.users(id)` with `ON DELETE CASCADE`, and child tables (`wallets`, `payouts`, `orders` (`customer_id`, `farmer_id`), `group_orders` (`organizer_id`), `group_order_members`, `disputes` (`against`, `raised_by`), `dispute_evidence` (`uploader`), `job_assignments`, `job_evidence` (`uploader`), and `ratings_reviews` (`rater_id`, `target_id`)) reference `profiles(id)` with `ON DELETE CASCADE`.
  - **Crucial Limitation**: The tombstone profile plan alone (updating `profiles` instead of deleting it) does **not** work by itself, because calling `auth.admin.deleteUser` deletes the row in `auth.users`, which cascades to delete the `profiles` row, which in turn cascades to delete all child financial and order records.
  - **Planned Migration Fix (Before P5.1 Wallet & Payments)**:
    1. **Modify `profiles.id` Foreign Key**: Remove `ON DELETE CASCADE` from `profiles.id -> auth.users(id)` (or change to `ON DELETE SET NULL` / `RESTRICT`), so that when `auth.admin.deleteUser` deletes the auth user, the scrubbed tombstone profile row in `profiles` survives.
    2. **Or Child FK Alteration & Snapshots**: Alter foreign key constraints on `wallets`, `payouts`, `orders`, `disputes`, `job_assignments`, and `ratings_reviews` from `ON DELETE CASCADE` to `ON DELETE SET NULL` with nullable columns plus snapshot columns (`customer_name_snapshot`), ensuring financial audit records are detached from the deleted auth ID and retained in scrubbed format.
    3. **Mandatory Test Verification**: In P5.1, re-verify that account deletion RPC/Edge Function never fails, financial audit trails survive in anonymized format, and re-registering a new account with the same phone number succeeds cleanly.

- **Settings & Delete Account Navigation (Phase 3.1)**:
  - Settings and the "Delete my account" dialog exist and are tested in code (`lib/features/account/`), but are not reachable via app navigation because the Profile tab is currently a placeholder shell. Phase 3.1 will add a minimal Profile screen that links to Settings and Account Control.

## Technical & Simulation Decisions

* **D12 — eKYC Adapter Simulation (MockProvider & Masking)**:
  * **Simulation Details**: When `KYC_PROVIDER=mock` (default), eKYC identity verification is handled by `MockProvider` in Deno Edge Functions (`kyc-start`, `kyc-callback`) and `SupabaseKycRepository` in Flutter.
  * **Masking & Redaction Guarantee**: Raw 12-digit Aadhaar numbers are never logged or stored. A redaction utility in Deno scrubs any 12-digit number pattern (`\b\d{12}\b`), and only masked IDs (`XXXX-XXXX-4321`), masked names (`R***** S****`), document type, and verification timestamps are saved to `kyc_records`.
  * **Honesty Rule**: A visible amber "Demo mode — Simulated eKYC Provider" banner is rendered on `KycScreen`.

* **D13 — Extra Verification Flows & Penny-Drop Simulation**:
  * **Simulation Details**: Driving Licence, Student Verification, Bank / UPI Payout Verification, and Background Check flows are fully integrated with Supabase storage (`kyc-docs` private bucket) and `kyc_records` DB table.
  * **DL & Category Gating**: Indian DL format validation, vehicle class selection, expiry tracking, and front/back photo upload. Database migration `0210` adds `requires_licence = true` to `driver`, `delivery`, and `delivery-gig-work` categories in `service_categories` and enforces gating in `nearby_jobs_for_worker` RPC.
  * **Student Privacy**: Reg/USN is stored in masked format (`1MS2-***-****`). Rendered with explicit privacy notice: *"All student documents and USN records remain strictly private"*.
  * **Penny-Drop Payout**: Bank account and UPI ID verification use simulated penny-drop with a clearly labelled amber **"Demo mode — Simulated Penny-Drop Verification"** banner.
  * **Background Check**: Sensitive job gating for unverified workers, tracking statuses (`Not Requested`, `Pending`, `Verified`, `Failed`, `Review Required`).

* **D14 — On-Device Face Enrolment, TFLite MobileFaceNet & Anti-Spoofing Mitigations**:
  * **Architecture & Model Details**: Face enrolment uses an open-source MobileFaceNet TFLite flatbuffer model (`assets/models/mobilefacenet.tflite`, Apache License 2.0) with `tflite_flutter` (v0.12.1) and `google_mlkit_face_detection` (v0.15.1). The phone crops the face, normalizes to a 112x112 RGB Float32 tensor, runs local TFLite inference, and extracts a normalized 128-float32 embedding vector ($\|\mathbf{v}\|_2 = 1.0$).
  * **Privacy Guarantee**: Raw camera photos are never sent to external servers for matching or returned to clients; only the 128-dimensional embedding vector and liveness status are transmitted to the `face-enroll` Edge Function and stored securely in `face_profiles.embedding`. RLS policies block clients from reading other users' embeddings.
  * **Anti-Spoofing & Honesty Note**: On-device liveness and local embedding extraction are inherently weaker against determined video replay or 3D mask spoofing compared to a managed cloud liveness service (e.g. AWS Rekognition / iBeta Level 2 certified service). Mitigations implemented: random 2-step challenge sequence (blink, turn head left/right, smile), strict 15s session timer limit, ML Kit eye-open and pose angle quality gates, and server-side vector numerical range validation.
  * **Honesty Rule**: A visible amber "Demo mode — Mock Face Matcher Active" banner is displayed IF `FACE_MATCHER` is set to `mock`.

* **D15 — Role & Seeker Type Verification Visibility Matrix**:
  * **Single Source of Truth**: Centralized in `lib/features/trust/domain/verification_visibility.dart` via `verificationItemsFor(role, seekerType)` and `isVerificationItemVisible(...)`.
  * **Visibility Matrix**:
    * **Aadhaar eKYC**: All roles (`seeker` [informal, student, part_time], `provider`, `farmer`).
    * **Driving Licence**: `seeker` ONLY (informal, student, part_time). Hidden for `provider` and `farmer`.
    * **Student Verification**: `seeker_type == 'student'` ONLY. Hidden for informal, part_time, provider, and farmer.
    * **Bank / UPI Payout**: `seeker` and `farmer` ONLY. Hidden for `provider` (providers make payments, not receive worker/produce payouts).
    * **Background Check**: `seeker` and `provider` ONLY. Hidden for `farmer`.
    * **Face Enrolment & Liveness**: All roles.
  * **Student Verification States**: `Not verified (tap to start)`, `Pending`, `Verified`, `Rejected (Tap to resubmit)`. "Not Student" label eliminated.
  * **Category Change Persistence**: Changing `seeker_type` away from `student` hides the Student Verification item in UI but retains the `kyc_records` database row. Changing back to `student` restores the saved verification status.
  * **Server-Side Enforcement**: Migration `0230_verification_visibility_guard.sql` adds a database trigger `trg_check_kyc_record_visibility` on `kyc_records` BEFORE INSERT OR UPDATE, rejecting `college_id` for non-students and `driving_licence` for non-seekers.

* **D16 — Biometric Template Privacy & Column-Level Grants on face_profiles**:
  * **Biometric Template Protection**: Direct `SELECT` on `public.face_profiles` is revoked from `authenticated` and `anon` roles to prevent client access to the raw biometric vector (`embedding`).
  * **Explicit Column Grants**: `GRANT SELECT (id, user_id, reference_path, matcher_ref, liveness_passed_at, consent_log_id, status, created_at, updated_at) ON public.face_profiles TO authenticated;` is applied.
  * **Pitfall & Developer Warning**: Because `face_profiles` relies on column-level SELECT grants, any NEW column added to `face_profiles` in future migrations that the Flutter client app must read MUST have an explicit `GRANT SELECT (new_column) ON public.face_profiles TO authenticated;` included in that same migration file. Otherwise, PostgREST queries attempting to read that column will fail with `permission denied`.

* **D17 — Profile QR Tokens & Public Verification Boundary**:
  * **Non-PII Token Payload**: Profile QR codes encode a compact JSON payload signed with HMAC-SHA256 using `QR_SIGNING_SECRET`. The payload contains ONLY `{ "tid": "<uuid>", "pur": "profile", "iat": <epoch>, "exp": <epoch> }`. Raw user IDs, phone numbers, names, or emails are NEVER included in the QR token.
  * **Server-Side Token Hash & Revocation**: The server records the SHA-256 hash of `tid` in `public.qr_tokens` along with the issuing `user_id`. When verifying, the hash is looked up to ensure the token exists and is not revoked.
  * **Public-Only Verification Policy**: `qr-verify` executes signature verification in constant-time, checks expiry (default 300s configurable in `admin_settings.qr_expiry_seconds`), verifies revocation, enforces scanner rate-limiting (30 requests/minute per caller/IP), and invokes `get_public_verification` RPC. It strictly returns ONLY public fields: `name_initial`, `display_id` (`UDY{YYYY}{XXXX}`), `is_verified_badge`, `level`, `level_name`, `kyc_verified_at`, `face_verified_at`, and `training_verified_at`.

* **D-QR — QR Verification Contract, Role Separation & Single-Phone Testing**:
  * **Role Separation**: `DigitalIdScreen` (`/trust/digital-id`) is exclusively available to workers/job seekers (`role == UserRole.seeker`) to present their digital trust badge. `ScanVerifyScreen` (`/trust/scan-verify`) is exclusively available to employers/job providers (`role == UserRole.provider`) to inspect worker identity cards on site. Route guards in `app_router.dart` strictly redirect unauthorized roles back to their respective home dashboards.
  * **Edge Function Contract**: `qr-issue` and `qr-verify` Edge Functions implement standardized `{ "health": true }` probes and support both GET and POST requests for continuous uptime monitoring without client session dependencies.
  * **Single-Phone Test Ergonomics**: Because developers and evaluators often test on a single physical phone without a second camera device, `ScanVerifyScreen` provides a single-phone verification debugging panel (in `kDebugMode`) allowing instant one-tap simulated scanning of the active user's generated QR token.

* **D-VISIBILITY — Multi-Layer Role & Seeker-Type Verification Gating**:
  * **Multi-Layer Enforcement**: Verification flows are enforced across 3 distinct boundaries: (1) UI visibility logic (`verification_visibility.dart`), (2) declarative GoRouter route guards (`app_router.dart`), and (3) PostgreSQL triggers and RLS policies (`0230_verification_visibility_guard.sql`).
  * **Student Gating**: `/kyc/student` is accessible ONLY when `role == UserRole.seeker` AND `seekerType == 'student'`. If an informal worker, part-time worker, provider, or farmer attempts to navigate directly to `/kyc/student`, the route guard halts navigation and redirects to their dashboard.
  * **Driving Licence Gating**: `/kyc/dl` is accessible ONLY to seekers. Providers and farmers are redirected away.
  * **Payout Gating**: `/kyc/bank` is accessible to seekers and farmers only (parties that receive wages and crop payouts).
  * **Edge Functions Uptime Integration**: 7 primary Edge Functions (`qr-issue`, `qr-verify`, `face-enroll`, `face-verify`, `kyc-start`, `kyc-callback`, `ai-assist`) support standardized health checks to enable automated integration testing without requiring valid third-party API keys.

* **D-AUDIENCE — Database Job Audience Rules & Informal Seeker Gating**:
  * **Database-Driven Gating**: Migration `0350_audience_and_jobs_rules.sql` establishes `public.job_audience` enum (`all_workers`, `informal_workers`, `students_only`, `part_time_only`) and `target_audiences` array column on `jobs` table.
  * **RPC Protection**: Gating is strictly enforced server-side inside `public.apply_to_job` RPC. An informal worker attempting to apply to a `students_only` job is rejected with an explicit database exception: `'Informal job seekers cannot apply to jobs restricted exclusively to students.'`.
  * **Recommendation & Map Alignment**: `recommended_jobs` and `nearby_jobs` RPCs automatically evaluate the caller's `seeker_type` from `worker_profiles` and filter out incompatible jobs from recommendation feeds and GPS pin clusters.

* **D-REF-UI — PDF Reference Alignment & Visual Truth**:
  * **Single Source of Truth**: Every UI prompt strictly matches `docs/reference/UdyogaSetu_Built_Project.pdf`:
    * Page 2 Phone 2: Seeker Home (dark green gradient header, SOS pill, GPS chevron, search bar with mic, frosted-glass Today's Goal ring and Wallet card, 4 quick actions, sponsored job card, and compact JobRow list).
    * Page 2 Phone 3: GPS Map & live nearby job clusters.
    * Page 3 Phone 2: Recommended Jobs feed with compact `JobRow` layout, category thumbnails, and one-tap application.
    * Page 3 Phone 4 & Page 4 Phone 2: Seeker Profile (dark green header, 3 tabs [Overview, Work Showcase, Safety Status], Role Credentials card, Language Switcher, My Skills with dialog, Verification Status, and Account & Safety card).
    * Page 4 Phone 4: Worker Category & Preferences change modal allowing post-login role specialization (Informal, Student, Part-Time).

* **D-HOME-CLEAN — Removal of Redundant Safety Onboarding Card from Home**:
  * **Layout Fidelity**: To match Page 2 Phone 2 exactly, the redundant `Safety Onboarding & Verified Badge` banner on Seeker Home was removed. Safety onboarding and verification lifecycle management is accessed via the Profile screen ("Safety Status" tab & "VERIFICATION STATUS" card) and the Trust & Safety Centre.

* **D-GOAL-DEFAULT — Today's Goal Gamification & Default Earnings Target**:
  * **Goal Target**: Daily earnings goal defaults to ₹1,500 (150,000 paise) across all seeker categories.
  * **Interactive Adjustment**: Seekers can tap the goal ring or edit button to open a quick modal to set custom targets (₹500, ₹1,000, ₹1,500, ₹2,000, ₹3,000), persisting the goal state in Riverpod `seekerDailyGoalProvider`.

* **D-JOB-DETAIL-APPLY — Job Posting, Pre-Application Eligibility & Double-Booking Prevention**:
  * **Screen 34 Prototype Fidelity**: Built Job Detail screen matching prototype "Job Posting & Payment Protection" with category WebP hero illustration, verified employer badge & rating card, rate/distance/walk chips, 5-row specs table (Duration, Start Time, Materials Provided, Escrow Protected, Slots Open), description, site photo, and bottom action bar (Chat, Apply Now).
  * **Pre-Application Eligibility Gate**: Tapping Apply Now opens a bottom sheet executing `public.check_job_eligibility(p_job_id)` RPC, verifying driving licence, verification badge, audience gating, and calendar schedule conflicts before submission.
  * **Seeker Jobs Tab 5 Segments**: 5 distinct segments (`Applied`, `Accepted`, `Active`, `Completed`, `Requests`). Requests segment lists direct booking invitations with Accept, Decline, and Request More Details actions.
  * **Double-Booking Prevention**: SQL RPC `public.accept_assignment` rejects overlapping assignments, throwing an exception which the UI catches to display an explanatory `Schedule Conflict` alert dialog.
  * **Travel Warning**: SQL returns travel time warning when a job starts < 60 minutes after another job, alerting the worker to plan travel.
  * **Offline Resilience**: Offline cached job view displays an amber warning banner and disables application with an explanatory snackbar.
* **D-BOOKING-PROTECTION — Unverified Worker Notice & Simulated Job Protection Cover**:
  * **Unverified Worker Dark Panel**: When a provider initiates a direct booking with an unverified worker (`is_worker_verified == false`), Step 6 of the guided booking flow displays the dark-panel warning screen (`#0B132B`, matching the prototype "Not UdyogaSethu Verified"). Verified workers bypass this notice directly.
  * **Simulated Job Protection Cover**: Offers an optional ₹40 (4,000 paise) Job Protection Cover covering property damage and claims. In compliance with the AGENTS.md Honesty Rule, this cover is simulated and explicitly badged with an amber "Demo mode" chip in the UI.
  * **Persistence**: Selection is persisted in `assignments.protection_selected` and `direct_hire_metadata->>'protection_selected'`.
  * **Booking Pass Ticket**: Upon confirmation via `request_worker` RPC, the provider receives a perforated Booking Pass Ticket showing booking code and "Waiting for worker" status.

* **D-SUITABLE-FOR — Job Visibility by Worker Type & Demo Jobs Separation**:
  * **Schema Migration (0410)**: Added `jobs.suitable_for seeker_type[] NOT NULL DEFAULT '{informal,student,part_time}'` with GIN index. Added `jobs.is_demo BOOLEAN NOT NULL DEFAULT false` with B-tree index. Added `provider_profiles.is_verified_badge BOOLEAN NOT NULL DEFAULT false`.
  * **Demo Jobs Exclusion**: Excluded all `is_demo = true` jobs from worker-facing queries (`recommended_jobs`, `nearby_jobs`, GPS map, search, and job detail lists). Seed demo jobs created in P1.7 are flagged `is_demo = true` and gated in `seed_demo.sql` behind an explicit boolean flag (`v_seed_demo_jobs := false`).
  * **Provider Post Job Wizard (Step 2)**: Added required "Target Workers" step ("Who is this job for?") with multi-select cards for Informal, Student, and Part-Time workers, with tailored hints and required selection validation.
  * **Server-Side Enforcement**: `recommended_jobs`, `nearby_jobs`, and `apply_to_job` enforce `jobs.suitable_for @> ARRAY[worker_type]` in PostgreSQL. Workers only see and can only apply for jobs matching their active `seeker_type`.
  * **Realtime Sync**: `SeekerHomeController` subscribes to Supabase Realtime channel on table `jobs`, reflecting newly posted or updated provider jobs instantly without app restart.

* **D-PROVIDER-HUB-CLEANUP — Provider Hub Scan QR, Real Bookings & Overflow Prevention**:
  * **Scan QR Quick Action**: Renamed quick action from "Scan Farm QR" to "Scan QR" across all 8 languages (`hubActionScanQr`). Routes to `AppRoutes.scanVerify` (`/trust/scan-verify`) for worker ID and job ticket validation. Farm produce scanning remains reserved for Phase 6.
  * **Confirmed Booking Integrity**: The Confirmed Booking card displays strictly real assignments of the logged-in provider queried via `get_provider_active_booking`. If no active booking exists in the database, renders a friendly empty state card (`_buildEmptyBookingCard`). Removed repository demo fallback (`BOOK-7842`, `Commercial Electrical Repair`, `Chethan Kumar`).
  * **Verified Local Workers Filter**: The "Verified on-demand local workers" section excludes the logged-in provider, excludes non-worker accounts, filters strictly for `is_verified_badge == true` (100% Aadhaar verified), and displays real distance ("Location not set" fallback when coordinates are absent) and actual rates.
  * **Header & Tabs Ergonomics**: Category TabBar configured with `isScrollable: true` and `tabAlignment: TabAlignment.start` to eliminate label truncation ("Workers & Servi", "Farm Produc"). Compact language switcher replaced with a clean translation icon button opening a bottom modal sheet, avoiding header crowding across screen sizes.

* **D-AVATAR-PIPELINE — Unified Avatar Pipeline with Local Preview & Initials Fallback**:
  * **Immediate Local Preview**: When an avatar photo is captured from camera or chosen from gallery in provider, seeker, or farmer wizards, raw bytes are immediately displayed in the UI via `UserAvatar(imageBytes: bytes)` while background upload occurs.
  * **Upload & Storage**: Image bytes are compressed and uploaded to `avatars/{uid}/` with upsert enabled. Repositories update `profiles.avatar_path` in the database and return the public storage URL (`client.storage.from('avatars').getPublicUrl(path)`).
  * **Unified Display**: `UserAvatar` widget utilizes `CachedNetworkImage` with progress placeholder, image loading spinner overlay during upload, and clean uppercase 1-2 letter initials fallback (`getInitials`) on load error or null path.
  * **Consistency Across Screens**: The resolved avatar appears across wizard steps (photo picker and step 5/7 review), header profile buttons, home screens, worker profile cards, applicant cards, job detail screens, and digital ID card.

* **D-LAYOUT-OVERFLOW-ELIMINATION — Zero Overflow Policy across Screen Sizes and Text Scales**:
  * **Resolution Pattern**: Replaced rigid horizontal `Row` layouts with `Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8)` for camera/gallery button pairs in all wizards. Wrapped text titles and subtitle details in `Expanded` or `Flexible` with `overflow: TextOverflow.ellipsis`. Wrapped currency and wage labels in `FittedBox(fit: BoxFit.scaleDown)`.
  * **Testing Rigor**: Verified zero yellow-and-black RenderFlex overflows across 360dp and 412dp screen widths, with text scale factors 1.0, 1.3, and 1.6 in English, Kannada, Hindi, Tamil, and Telugu via automated widget test suite `test/layout_overflow_test.dart` (60 passing tests).

* **D-ROUTING-AND-JOB-EXECUTION — OSRM Routing, Straight-Line Fallback, Realtime Timeline & Simple Mode**:
  * **RoutingService Implementation**: Uses the public OpenStreetMap OSRM routing API (`https://router.project-osrm.org/route/v1/driving/...`) with a 5-second timeout and GeoJSON polyline decoding.
  * **Rate Limiting & Straight-Line Fallback**: The public OSRM server is free and rate-limited. In case of network errors, timeouts, or HTTP 429 rate limiting, a straight-line Haversine fallback is automatically computed with an estimated urban driving speed of 25 km/h (~2.4 min/km). In compliance with the AGENTS.md Honesty Rule, straight-line estimates are explicitly badged with an amber "Demo mode: Straight-line" chip in the UI.
  * **External Maps Intent**: Route section includes an "Open in Maps" button launching external turn-by-turn navigation via `url_launcher` (`https://www.google.com/maps/dir/?api=1&destination=...` or generic `geo:` intent).
  * **Realtime Lifecycle Timeline**: `AssignmentTimelineWidget` subscribes to Supabase Realtime on `assignment_events` table for the active assignment. Renders the 9 canonical stages: Request Created, Accepted, Ticket Issued, Worker Arrived, Verification Completed, Job In Progress, Completed, Payment Released, and Dispute Raised.
  * **Status Change SQL Trigger**: PostgreSQL trigger `trg_job_assignment_status_event` on table `job_assignments` automatically logs an `assignment_events` entry whenever `job_assignments.status` changes, guaranteeing live phone timeline updates even when status is updated directly via SQL queries.
  * **Active Job Screen with Simple Mode**: Supports both Worker and Provider counterparties. In Simple Mode (`profiles.simple_mode` / `UserSettings.simpleMode`), the primary action is enlarged to a huge gradient card (76dp+ min height, 36dp icons, 20sp bold text) with a spoken TTS audio label via `flutter_tts` ("Accept Job", "Start Work", "Complete Job", "Ask for Help").
  * **Worker Schedule with Travel Warning**: Day and Week calendar views with SQL conflict checks. Displays a prominent amber warning chip whenever the time gap between consecutive assignments is shorter than the estimated travel time.

* **D48 — Smart No-Show Recovery Engine, Replacement Matching & Masked Call Simulation**:
  * **Idempotent Automatic Cron Engine**: Every minute, `check_no_show_assignments()` scans `job_assignments` in `ticket_issued` status where start time plus grace period (`no_show_grace_minutes` from `admin_settings`, default 15m) plus any extended wait and worker ETA has passed without arrival. Idempotently logs a single `late_arrival_warning` in `assignment_events`, records `late_notified_at`, and notifies both provider and worker once via `notifications`.
  * **Provider Recovery Actions**: When past scheduled arrival, provider receives dark-panel sheet (`#0B132B`) with:
    1. **Wait 10 Minutes**: calls `extend_wait(assignment, 10)` which adds grace to `extended_grace_minutes`, logs `grace_extended` event, notifies worker, and pauses the timer.
    2. **Call Worker Directly**: initiates private masked call. As per AGENTS.md honesty rules, marked with amber "Demo mode: Masked call arrives in P7.2".
    3. **Find Smart Replacement Worker**: calls `find_replacement(assignment)` ranking nearby available workers by skill match, verification, rating, and distance (excluding late worker). Tapping candidate triggers `confirm_replacement` (marks original as `no_show`, creates new assignment with `replaced_by` link, triggers escrow refund path for original, and notifies parties).
  * **Worker Running Late Action**: Worker side displays a "Running late?" action with delay options (+10m, +15m, +30m, +45m) calling `report_running_late(assignment, eta)`. Pauses no-show timer once, sets `no_show_timer_paused = true`, and notifies provider.
  * **Fraud Flags Rule**: 3 no-shows within 30 days automatically creates an `open` row in `fraud_flags` with `rule_key: 'excessive_no_shows'` and severity `high` for admin review.

* **D49 — Ratings & Reviews, Trust Circles (Favourites), Rebooking & Dispute Resolution**:
  * **Verified Reviews & SQL Aggregate Triggers**: Completed and payment-released assignments allow exactly one review per party. Enforced server-side in `submit_job_review(...)` which strictly checks caller role and blocks duplicate reviews. Reviews recompute `rating_avg` and `rating_count` across worker, provider, and farmer profile tables via `trg_recompute_ratings`. Guard triggers (`guard_worker_profile_computed_columns`, `guard_provider_profile_computed_columns`, `guard_farmer_profile_computed_columns`) updated to allow internal trigger updates (`pg_trigger_depth() > 1`) while keeping direct client column mutations blocked.
  * **Job History UI Prototype Match (Screen 37)**: Built `JobHistoryScreen` faithfully reflecting prototype Screen 37 with language banner card, filter chips (All, Completed, Disputed, In Progress, Cancelled), job cards with time ago, amount in rupees, star ratings, and action buttons (Rate, Dispute, Rebook). Added settings and support list entries (My Bookings, Privacy, Help & Support).
  * **Favourites & Trust Circles**: Heart toggle on profiles persists to `public.favourites`. Enhanced `nearby_workers(...)` SQL procedure ranks repeat, well-rated connections (rating >= 4.0) and saved favourites first in search results without filtering out new or other workers. Built dedicated `FavouritesScreen` with 1-tap rebooking.
  * **1-Tap Rebooking**: One-tap rebooking from history items or favourites pre-fills `BookingDraft` (worker ID, name, category, agreed daily wage) and opens the booking wizard directly.
  * **Dispute Reporting & Escrow Freeze**: Implemented 7 canonical dispute issue types (`no_show`, `incomplete_work`, `poor_quality`, `wrong_product`, `payment_issue`, `unsafe_conduct`, `verification_problem`) with multi-line explanation and photo evidence attachments. `create_assignment_dispute(...)` marks `job_assignments.status = 'disputed'`, logs timeline event `dispute_opened`, and notifies counterparty. Escrow release is frozen on disputed assignments (completed in P5.3).

* **D50 — Wallet Balances from View, Ledger-backed Transactions, DB-enforced Overdraw Guard, Demo Withdrawal & UPI Scanner**:
  * **Server-Authoritative Balances**: Sourced strictly from the PostgreSQL view `wallet_balances` (available, pending, escrow, reward, total) via RPC `get_wallet_summary()`. Client calculations of balances are strictly prohibited.
  * **Indian Grouping Formatter**: All currency balances and transactions are formatted using Indian grouping (`₹15,250`, `₹1,00,000`, `₹1,00,00,000`) implemented in `WalletBalance.formatIndianCurrency(paise)` with round-trip safety.
  * **Itemized Ledger Transactions**: Transactions are queried from `ledger_entries` via `get_wallet_transactions(...)` RPC, with typed categorization (`Daily Wage`, `UPI transfer`, `Farm Produce Direct Sale`, `UPI Auto-Payout`, `Platform Fee`, `Reward Credit`, `Refund`), fee/commission breakdown lines, filter chips (All, Wages, Payouts, Escrow, Direct Sales, Fees), and offset-based pagination.
  * **Database-Enforced Overdraw Guard**: Withdrawal amount validation is enforced at the database level inside `request_wallet_withdrawal(...)` procedure. Any request where requested amount exceeds `available_paise` throws an `RAISE EXCEPTION 'Insufficient available balance.'` before any ledger mutation occurs. Secondarily, double-entry trigger `wallet_debit` checks ledger invariants against `wallet_balances`.
  * **Honesty & Simulation Rules**:
    * **Withdrawal**: Until a live banking payout partner (e.g., RazorpayX / Cashfree) is integrated, all withdrawal actions are explicitly badged as demo mode with a visible amber/warning banner: *"Demo mode — Simulated withdrawal until banking partner integrated"*. A simulated payout row is recorded in `payouts` with reference ID.
    * **UPI QR Scanner**: Scans and parses `upi://pay` URI scheme (`pa`, `pn`, `am`, `cu`, `tn`). Marked with a prominent amber **Demo mode** disclaimer: *"Demo mode — Scanned details are displayed for verification only. No money is transferred or deducted."*
  * **Realtime Balance Updates**: `SupabaseWalletRepository` subscribes to Supabase Realtime channel on table `ledger_entries` for the authenticated user, automatically triggering wallet summary recalculation whenever new debits or credits are posted.

* **D51 — Razorpay Checkout, Constant-Time Webhook Verification, Escrow Hold & Digital PDF Receipts**:
  * **Server-Authoritative Bill Computation**: Amounts are never trusted from the client. `compute_payment_bill(ref_type, ref_id, protection_override)` in PostgreSQL calculates base wage/order total, fetches platform fee percentage and caps from `admin_settings`, and calculates total in paise.
  * **Public Key Returned by Server**: Edge Function `payment-create-order` creates the payment record, calls Razorpay Orders API, and returns the public `key_id` along with `order_id`. The Flutter application does not require any Razorpay API keys in client assets or `env.json`.
  * **Webhook Security & Constant-Time Verification**: `payment-webhook` runs with `verify_jwt = false` and is protected exclusively by constant-time HMAC-SHA256 signature comparison against `RAZORPAY_WEBHOOK_SECRET`. All requests with missing or bad signatures are rejected (HTTP 401/403).
  * **Idempotency Deduplication**: Table `public.payment_webhook_events` logs every event ID and payment ID. Duplicate webhook deliveries return HTTP 200 without double-crediting escrow or creating duplicate ledger entries.
  * **Automated Escrow Invariant**: On `payment.captured` for protected jobs, the webhook invokes `hold_escrow(payment_id)`, marking payment status as `held` and inserting an `escrow` credit in `ledger_entries` for the payee.
  * **Sequential SQL Receipt Numbers**: Receipt numbers are generated via PostgreSQL sequence `receipt_no_seq` and trigger `trg_set_payment_receipt_no` in the format `RCP-YYYYMMDD-XXXXXX`.
  * **Realtime State Tracking**: `PaymentStatusScreen` listens to Supabase Realtime updates on the `payments` row rather than relying solely on the client SDK callback, ensuring atomic consistency between payment capture, webhook receipt, and UI transition.
  * **Digital PDF Receipts**: Built `PaymentReceiptPdf` generating an itemized tax invoice and escrow certificate, shareable via `share_plus`.

* **D52 — Escrow Release, Idempotent Settlement, Double-Entry Reconciliation, Dispute Freeze & Auto-Release**:
  * **Idempotent Settlement (`release_escrow`)**: Settlement functions are strictly idempotent. If `release_escrow` is invoked on a payment that is already in status `released`, the function safely exits without writing duplicate ledger rows or firing duplicate notifications.
  * **Paise Rounding & Platform Fee (`commission_bps`)**: Fee calculations use integer paise math with exact rounding (`(amount_paise * commission_bps + 5000) / 10000`). Tested against edge case fractional amounts (e.g., 73,533 paise resulting in 3,677 paise platform fee and 69,856 paise net worker credit).
  * **Double-Entry Ledger Integrity**: Releasing escrow debits payer's `escrow` balance by the gross wage and credits worker's `available` balance by the net wage (deducting the platform commission to platform revenue). Trigger-driven ledger validation maintains mathematical parity at all times.
  * **Dispute Freeze Invariant**: When an active dispute exists on an assignment (`status = 'disputed'` or unresolved disputes in `assignment_disputes`), `release_escrow` raises an exception and freezes release until resolved by the external Admin console.
  * **Automated Batch Release (`auto_release_escrow`)**: A scheduled, idempotent database procedure automatically scans completed assignments older than `auto_release_hours` (default: 24h) where all verifications are green and no open dispute exists, releasing escrow automatically.
  * **Phase 6 Order Reusability**: `release_order_escrow(order_id)` and `release_escrow` seamlessly support orders when delivery is verified (`status = 'delivered'`).
  * **UI Escrow & Protection Transparency**: `ActiveJobScreen` presents emerald "Protected" badges on jobs with escrow protection, provides "Pending Escrow Release" status with informational breakdown sheet for workers, and an itemized "Confirm & Release Payment" bottom sheet for employers showing gross wage, 5% platform fee deduction, and net worker payout.
* **D53 — Earnings Dashboard & Savings Goal Planner**:
  * **SQL-Backed Aggregate Invariant (No Client-Side Summing)**: All daily, weekly, monthly, and lifetime earnings totals are computed directly in PostgreSQL via `get_earnings_dashboard(p_days)`. Sums are backed strictly by `ledger_entries` where `wallet_id = v_wallet_id AND direction = 'credit' AND bucket = 'available'`, guaranteeing 100% mathematical parity with the wallet transactions list.
  * **Virtual Tracker Invariant**: Savings goals are strictly virtual planning trackers stored in `public.savings_goals`. They calculate progress, supportive cheers, and suggested allocations per job and per week, but **never lock or freeze funds**. User money remains completely available in the wallet for withdrawal at all times.
  * **Suggested Savings Algorithm**:
    * If a deadline exists: Calculates weeks remaining and suggests `remaining_target / weeks_remaining` per week, and `per_week / 5` per completed job.
    * If no deadline exists: Computes suggestion dynamically using the worker's recent 7-day average daily earnings (`recent_avg_daily_earnings_paise`), recommending a sustainable 15% savings rate.
  * **Unified Daily Goal State**: Added `daily_earnings_goal_paise` to `public.profiles`. The "Today's Goal" circular ring on the Seeker Home Screen and the Daily Goal Card on the Earnings Dashboard synchronize to the same database setting via `update_daily_earnings_goal` RPC.
  * **Accessible Chart Invariant**: `EarningsTrendChart` uses `fl_chart` with interactive 14-day daily line chart and 6-month monthly bar chart, accompanied by a dynamic, screen-reader-friendly text summary directly beneath each chart.

* **D54 — Farmer Home Workspace, APMC Karnataka Mandi Feed, Open-Meteo Advisory & Essential Suite**:
  * **Strict Role Separation & Invariant Real Data**: The Farmer Home screen (`FarmerHomeScreen`) is strictly restricted to Farmer accounts. All top metrics (Produce Sold, Direct Earnings, Active Labor) are backed by real database records (`orders`). For fresh farmer accounts, values display natural zeros (`0 kg`, `₹0`, `0 Booked`) — no mock or placeholder numbers are rendered on real screens.
  * **Temporary Scope Isolation for Agricultural Labour (P6.3 Placeholder)**: In P6.3, farmers will post agricultural labour requests directly from their farmer account. Until P6.3, the "Hire Workers" tile in the Essential Suite and the "Book Harvest Helpers" CTA open an informational bottom sheet modal ("Coming in P6.3"), and the Active Labor metric displays `0 Booked`.
  * **APMC Karnataka Mandi Sync & Fault Tolerance**:
    * Candidate resource ID `9ef84268-d588-465a-a308-a864a43d0070` on data.gov.in provides daily APMC commodity prices (`state`, `district`, `market`, `commodity`, `variety`, `arrival_date`, `min_price`, `max_price`, `modal_price`).
    * Edge Function `mandi-sync` reads `DATA_GOV_API_KEY` from Edge Function secrets, but is kept switched off by default (`MANDI_SYNC_ENABLED=false`).
    * Fault-tolerant retention: When the external API is unreachable or returns errors, the Edge Function logs the event and retains the existing database prices in `public.mandi_prices`.
    * SQL function `get_mandi_prices_with_demand` calculates price per kg, percentage change vs previous arrival date, and demand indicators (`High Demand`, `Stable`, `Moderate`, `FRP Guaranteed`, `MSP Protected`, `Oversupply`).
    * Migration `0511_mandi_sync_schedule.sql` sets up a daily schedule at 06:00 AM IST (00:30 UTC) using `pg_cron` and `pg_net` with private bearer authentication.
  * **Rule-Based Weather Advisory via Open-Meteo**:
    * Uses Open-Meteo REST API based on farmer coordinates (`farmLatitude`, `farmLongitude`), falling back to Mandya district center (`12.52`, `76.89`).
    * Rule engine translates forecasts into actionable agricultural cards:
      * Precipitation $\ge 25\text{mm}$ or violent showers: Heavy rain alert with drainage furrow advice.
      * Rain probability $\ge 45\%$ or moderate rain code: Warning *"Moderate Rain Expected Tomorrow Afternoon - Protect ready tomato crops by harvesting before 12 PM"* with "Book Harvest Helpers" CTA.
      * High temperature $\ge 34^\circ\text{C}$: Heat stress irrigation warning.
      * Clear weather: Favourable field weather info card.
  * **Offline Persistence**:
    * Last fetched mandi prices and weather advisory are cached in device `SharedPreferences` (`cached_mandi_prices_v1`, `cached_weather_advisory_v1`). If disconnected, the app renders cached data along with the last updated date label.
  * **Debug Simulation Switch**:
    * An interactive toggle in the Dev Menu (`/dev/role`) and the Farmer Home screen options menu simulates a rain forecast (`simulatedRainForecastProvider`), enabling manual verification of weather advisory alerts and harvest helper actions.

* **D55 — Farmer Profile Page & Produce Inventory Management**:
  * **Visual Reference Compliance (Screen 25 / Page 7 Phone 1)**:
    * Forest green header card (`#064E3B`) with avatar, "VERIFIED FARMER ✓" badge, farm title & cluster pill, phone number, and 3 live metrics: Land (Acres), Sold This Month (kg), and Direct Sales (₹).
    * Farm Infrastructure & Crop Badges: Soil Classification (e.g. Red Loamy), Primary Crops, APMC Registration status, and KCC (Kisan Credit Card) Approved badge.
    * Zero-Pesticide Organic Certificate card with its review status ("VALIDATED ✓", "IN REVIEW", "REJECTED", "NOT APPLIED").
    * Language mode selector grid directly connected to `localeProvider`.
  * **Produce Listings Creation & Editing**:
    * Fields: Product name, produce category, photos, price per unit (paise/kg), stock quantity, unit (`kg`, `quintal`, `box`, `bunch`), harvest date, quality notes, farming method (`Zero-Pesticide Natural`, `Organic Certified`, `Traditional IPNM`, `Hydroponic`), delivery and pickup options, and availability mode (`same_day`, `next_day`, `pre_order`).
    * Image compression using `image` package (resizing max dimension 800px at 80% JPEG quality) and uploading to `produce-images/{userId}/{timestamp}.jpg` in Supabase Storage with public read policies.
  * **Automated Status Control via PostgreSQL Trigger**:
    * Database trigger `trg_sync_produce_listing_status` on `produce_listings` automatically calculates listing status on INSERT or UPDATE:
      * `paused` status is preserved if explicitly set by farmer.
      * If `stock_qty <= 0`, status automatically updates to `sold_out`.
      * If `stock_qty <= low_stock_threshold`, status automatically updates to `low_stock`.
      * Otherwise, status updates to `active`.
  * **Price Suggestion Band**:
    * PostgreSQL function `get_produce_price_suggestion(p_category_id, p_commodity_name)` calculates a dynamic price suggestion band based on current APMC mandi modal price (`modal_price - 10%` to `modal_price + 15%`) and recent platform orders.
    * The farmer always sets the final price; the suggested band is displayed in the listing editor modal along with a one-tap "Apply Mandi Modal Price" shortcut.
  * **Database-Enforced Stock Decrement on Order Acceptance**:
    * Stock decrements only through SQL via trigger `trg_order_accepted_decrement_stock` when order status transitions to `accepted` or `confirmed`, or through SECURITY DEFINER RPC `decrement_listing_stock(p_listing_id, p_quantity, p_order_id)`.
    * If ordered quantity exceeds available stock, the database raises an exception (`'Insufficient stock remaining for listing'`).
  * **Buyer Search Visibility Invariant**:
    * Function `get_buyer_produce_listings` strictly filters `WHERE status IN ('active', 'low_stock') AND stock_qty > 0`.
    * When stock reaches zero, the listing is immediately hidden from buyer feeds and search results.
* **D56 — Farm Resources Map, Equipment Escrow Booking & Agri Labour Hiring**:
  * **Visual Reference Compliance**:
    * **Screen 23 (Page 6 Phone 2)**: Map with price overlay pins (`₹850/hr`, `₹1,400/hr`, `₹450/acre`, `₹450/bag`, `₹15/crate/day`, `₹200/sample`), top category filter chips (`All`, `Tractors & Implements`, `Seeds & Bio-Fertilizers`, `Cold Storage`, `Drones & Spraying`), search bar, interactive zoom controls, and draggable bottom sheet with distance tags, owner verification, and "Book Item" CTA.
    * **Screen 26 (Page 7 Phone 2)**: Equipment rental cards on Farmer Home ("Mahindra 575 DI Tractor + Rotavator", "Multi-Crop Harvester & Thresher", "Agricultural Drone Spraying Kit") with verified owner badge, distance, rating, price per unit, "Escrow Guaranteed" badge, and "Book Now" CTA.
  * **Escrow-Protected Booking Lifecycle**:
    * Extended `compute_payment_bill` for `ref_type = 'resource_booking'` using standard P5 payment calculation (base amount + 5% platform fee + 18% GST on fee).
    * Atomic PostgreSQL function `book_resource` generates sequential receipt number (`REC-RSC-...`), records booking in `resource_bookings` with initial status `escrow_held`, and calls `hold_escrow` to lock payment until service completion.
  * **Agri Labour Hiring via Shared Jobs System**:
    * Gated labour hiring on the `provider` role. Farmers without the provider role are guided to activate it via `RoleSwitcherBottomSheet` (P2.10).
    * Reuses the jobs system with category `Agri Labour` (`b2222222-2222-4222-8222-222222222222`), allowing farmers to post harvest shifts (e.g. "Morning Harvest Shift - 6 AM to 2 PM, ₹450/day") visible directly on the seeker map and feed.
  * **Resource Vendor View**:
    * Created `VendorResourcesScreen` (`/farmer/vendor-resources`) for equipment and seed owners to manage listings, toggle active availability, and update booking lifecycle (`confirmed`, `in_progress`, `completed`, `cancelled`).
* **D57 — Produce Marketplace, Map View & Lot Traceability**:
  * **Visual Reference Compliance**:
    * **Screen 27 (Provider Hub Farm Produce Tab)**: Category chips (`Organic Veggies`, `Fresh Milk & Dairy`, `Fruit Orchards`, `Grains & Pulses`, `Flowers`, `Local Products`), produce listing cards with verified farmer tick, stock quantity, freshness label ("Harvested Today (4h ago)"), distance tag, delivery availability, trust badges, "Order Direct", and "Traceability" button.
    * **Screen 29 (Customer Required Farm Produce, Organic Sellers & Outlets Near Me Map)**: Interactive OpenStreetMap with price pins (`₹34/kg`, `₹60/Liter`, `₹120/kg`), amber "Walk-in Store" depot badges, search bar, filter bottom sheet, zoom controls, and bottom draggable list with direct "Order Now" action.
    * **Screen 28 (Farm Quality Traceability Dialog)**: Green inspection circle with magnifying glass, verified origin header, crop item, farmer origin (farm name & village), harvest time, organic certification status pill, farming method, and quality notes.
  * **Unified "Scan QR" Integration**:
    * Maintained the single quick action "Scan QR" in Provider Hub and Trust Centre without breaking worker ID scanning (P3.7/P4.8).
    * `ScanVerifyScreen` inspects the QR payload: if purpose is `produce_lot` or starts with `UDS:LOT:`, it resolves the lot record and displays `FarmTraceabilityModal`.
  * **Lot QR Security & HMAC-SHA256 Signing**:
    * Lot QR tokens are cryptographically signed using HMAC-SHA256 (`udyoga_setu_secure_lot_signing_secret_2026`) with 30-day expiration, containing only public lot identifiers (`lot_id`, `listing_id`, `pur: produce_lot`), never exposing raw database IDs or private personal data.
  * **Produce Listings Invariant**:
    * Produce listings are shown only if active and in-stock (`status IN ('active', 'low_stock') AND stock_qty > 0`). Inactive or demo farmers are excluded from verified labels.
  * **Single-Phone Debug Testing Helper**:
    * Gated strictly under `kDebugMode`: product detail screen provides "Show Lot QR Code for Scanning" dialog showing the live QR code on screen and one-tap "Copy Token String".
    * `ScanVerifyScreen` debug section provides "Test Scan Produce Lot QR" and "Paste QR Token" dialogs for complete single-phone validation.
  * **Simulation Honesty**:
    * Produce ordering triggers an instant order feedback labelled "(Demo mode)". Recorded in DECISIONS.md.

