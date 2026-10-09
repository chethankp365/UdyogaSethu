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









