# UdyogaSethu Build Progress & Task Tracker

## Phase 0 (Foundation)
- [x] **P0.1**: Rules, memory files and UI reference (Status: Done | Completed: Phase 0 Step 0.1 documentation & setup)
- [x] **P0.2**: Create the Flutter project (Status: Done | Scaffolded Flutter app `in.udyogasethu`, added base dependencies, configured analysis options & Android permissions)
- [x] **P0.3**: Design system and component gallery (Status: Done | Built design tokens, typography fallbacks, light/DarkPanelTheme, 21 reusable core widgets, responsive container, and debug-only /dev/gallery route)
- [x] **P0.4**: Connect Supabase (Status: Done | Initialized Supabase in main.dart, created SupabaseService/providers, AppException error mapping, AppLogger, 0000_ping.sql migration, BACKEND.md, and debug route /dev/connection)
- [x] **P0.5**: Router and role-based app shells (Status: Done | Configured GoRouter with StatefulShellRoute.indexedStack for 4 role shells, AppSessionNotifier, typed AppRoutes, RoleBottomNavBar with raised mic FAB, responsive AdminShell with NavigationRail, /dev/role debug switcher, NotFoundScreen, and udyogasethu:// Android deep links)

## Phase 1 (Database, security and server logic)
- [x] **P1.1**: Schema part 1: identity, roles and profiles (Status: Done | Created migration 0010_identity.sql with PostGIS/pgcrypto/trgm extensions, enums, 9 tables, GIST/trigram indexes, updated_at & handle_new_user triggers, RLS enabled, and server-computed column comments. Pushed & linted cleanly on Supabase)
- [x] **P1.2**: Schema part 2: jobs, bookings and farm marketplace (Status: Done | Created migration 0020_marketplace.sql with 15 enums including assignment_status & order_status, 19 tables for jobs/assignments/timeline/evidence/produce/carts/orders/subscriptions/group_orders/resources, bigint paise money checks, GIST/btree indexes, updated_at triggers, and RLS enabled. Pushed & linted cleanly on Supabase)
- [x] **P1.3**: Schema part 3: money, trust and safety (Status: Done | Created migration 0030_money_trust.sql with 11 custom enums, 16 tables including wallets, append-only ledger_entries, payments, payouts, kyc_records, face_profiles, verification_attempts, consent_logs, fraud_flags, ratings_reviews, favourites, disputes, dispute_evidence, emergency_contacts, sos_incidents, and protection_claims. Includes trg_prevent_ledger_mutation trigger blocking UPDATE/DELETE, wallet_balances view, GIST/btree indexes, updated_at triggers, and RLS enabled. Pushed & verified append-only exception on Supabase)
- [x] **P1.4**: Schema part 4: engagement, admin and content (Status: Done | Created migration 0040_engagement_admin.sql with 5 custom enums, 26 tables for communication, gamification, rewards, community, learning, savings goals, wage benchmarks, mandi prices with UNIQUE constraint, ad banners, admin settings seeded with defaults, admin logs, and audit_log. Includes generic audit triggers, locality_trust_index & admin_kpis views, RLS enabled, and Realtime publication enabled for chat_messages, notifications, job_assignments, orders, and assignment_events)
- [x] **P1.5**: Row Level Security and storage buckets (Status: Done | Created migration 0050_rls_storage.sql with STABLE SECURITY DEFINER helpers has_role/is_admin/is_assignment_party/is_order_party/is_thread_member, public_profiles view, server-computed column mutation guard triggers, 100% RLS policy coverage across all 69 tables, 9 storage buckets with strict folder-based owner write policies, schema GRANTs to authenticated/anon, and automated RLS security test suite in supabase/tests/rls_tests.sql. Documented policy matrix in docs/BACKEND.md)
- [x] **P1.6**: SQL functions: nearby search, job state machine and wallet (Status: Done | Created migration 0060_functions.sql with PostGIS ST_DWithin GIST search RPCs nearby_jobs/nearby_workers/nearby_produce/nearby_resources, SECURITY DEFINER job state machine assignment_transition with timeline logging, public RPCs apply_to_job/respond_to_application/request_worker/accept_assignment/decline_assignment/cancel_assignment/confirm_completion, service-role verification handlers record_arrival/record_verified_start/record_completion/mark_no_show with REVOKE from authenticated/anon, wallet_credit/wallet_debit/hold_escrow/release_escrow/refund_escrow with early idempotency checks & balance invariants, recompute_ratings_trigger, recompute_verification_badge, get_public_verification, and suggest_wage_band. Verified 100% pass on security test suite in supabase/tests/functions_tests.sql)
- [x] **P1.7**: Demo seed data (Status: Done | Created supabase/seed/seed_demo.ts, supabase/seed/seed_demo.sql and supabase/seed/reset_demo.sql tracking demo users in demo_users table. Created 15 demo auth users around Bengaluru across Koramangala, Jayanagar, HSR Layout, Indiranagar, Devanahalli, Yelahanka with test phones +919900000001..+919900000304: 1 admin, 7 seekers, 3 providers, 4 farmers. Populated 12 service categories with multi-lingual names in en/kn/hi/te/ta and skills, open jobs, produce listings, resource listings, mandi prices, wage benchmarks, levels, 12 badges, reward items, 4 training events, 6 learning modules, sponsored ad banner, impact stories, completed assignments, reviews, payments and ledger entries in paise. Tested idempotency and clean reset)
- [x] **P1.8**: Edge Functions scaffold and Flutter API client (Status: Done | Created `supabase/functions/_shared` with cors.ts, logger.ts with token/phone/document scrubbing, response.ts with typed json/error helpers, supabase.ts with getUserClient/getServiceClient, validation.ts, and rate_limiter.ts backed by DB with in-memory fallback. Created 13 Edge Functions in `supabase/functions/` with typed request contracts, JWT verification, input validation, and rate limiting returning 501 `not_implemented` (`kyc-start`, `kyc-callback`, `face-enroll`, `face-verify`, `qr-issue`, `qr-verify`, `payment-create-order`, `payment-webhook`, `sos-trigger`, `send-push`, `mandi-sync`, `ai-assist`, `masked-call`). Documented function specs, auth, secrets, and prompts in `docs/EDGE_FUNCTIONS.md`. Created Flutter client `lib/core/supabase/edge_api.dart` calling `functions.invoke` and mapping to `AppException`/`EdgeFunctionException` with typed methods. Verified 401 unauthenticated and 501 authenticated JSON responses with curl, and `flutter analyze` is 100% clean)

## Phase 2 (Onboarding and real authentication)
- [x] **P2.1**: Splash and intro screens with real bootstrapping (Status: Done | Created `SplashScreen` matching Screen 1 in UI_REFERENCE.md with logo, green/orange split tagline, city-bridge vector SVG, progress bar, `AI Matching`/`Secure`/`Verified` feature pills, and dynamic version label via package_info_plus. Implemented `BootstrapNotifier` in `bootstrap_service.dart` performing real bootstrapping (checking package info, reading SharedPreferences, restoring Supabase auth session & profiles table, with minimum 1.2s display time). Created `IntroScreen` matching Screen 2 with headline, subtitle, hero SVG, 3 feature tiles, Skip and Next actions persisted via SharedPreferences `has_seen_intro`. Added localization ARB files `app_en.arb`, `app_kn.arb`, `app_hi.arb`, `app_te.arb`, `app_ta.arb` with AppLocalizations generation. Added comprehensive unit & widget tests in `test/onboarding_test.dart` covering UI and session routing logic)
- [x] **P2.2**: Localization and language selection (Status: Done | Configured Flutter gen-l10n with ARB files for 8 locales (`en`, `kn`, `hi`, `te`, `ta`, `mr`, `bn`, `or`) with 100+ common keys, ICU plurals, placeholders, and Indian rupee formatting. Built Riverpod `LocaleNotifier` in `locale_controller.dart` persisting language selection in `SharedPreferences` and updating `profiles.language` on sign-in. Built `LanguageScreen` (`Screen 3` in UI_REFERENCE.md) with 8 country-coded language selector cards, audio preview button using `flutter_tts` speaking localized welcome sentence with fallback hint for missing voice engines, and `CompactLanguageSelector` chip row for header/login screens. Created `tool/check_l10n.dart` checking key completeness across all ARB files, verified Noto Indic font fallbacks, clean `flutter analyze`, and unit/widget tests in `test/l10n_test.dart`)
- [x] **P2.3**: The new role tree: Worker or Farmer, then Seeker or Provider, then type (Status: Done | Built guided decision tree in `RoleTreeScreen` and `RoleTreeNotifier` with 3-step navigation: Step 1 (Worker vs Farmer), Step 2 (Job Seeker vs Job Provider), Step 3 (Informal vs Student vs Part-Time Seeker). Includes step dots, breadcrumbs, low-literacy TTS voice narration button, `CompactLanguageSelector`, direct login shortcut, and local persistence of `PendingRoleSelection` via `SharedPreferences`. Added 100% complete localization keys across all 8 ARB files (`en`, `kn`, `hi`, `te`, `ta`, `mr`, `bn`, `or`), verified with `check_l10n.dart`, clean `flutter analyze`, and unit/widget test coverage in `test/role_tree_test.dart` and `test/role_tree_widget_test.dart`)

- [x] **P2.4**: Real phone OTP login (Status: Done | Built `LoginScreen` matching Screen 4 in UI_REFERENCE.md with `CompactLanguageSelector`, 10-digit Indian phone field (+91), terms checkbox, and Google sign-in preview button. Built `OtpScreen` with 6-box `Pinput` field, Android SMS User Consent autofill via `smart_auth`, 30s resend timer countdown, max 3 resends limit, and "Change number" link. Created migration `0070_record_consent.sql` with `record_user_consent` RPC logging terms consent in `consent_logs`. Integrated Supabase Auth `signInWithOtp` and `verifyOTP`. Never logs phone numbers or tokens. Added 100% complete localization across all 8 ARB files (`en`, `kn`, `hi`, `te`, `ta`, `mr`, `bn`, `or`), clean `flutter analyze`, and unit & widget test coverage in `test/auth_test.dart` and `test/login_widget_test.dart`)

- [x] **P2.5**: Real Google sign-in and account linking (Status: Done | Integrated `google_sign_in` with `GOOGLE_WEB_CLIENT_ID` (`147218087454-84onmnof89drjjktvenajia8qp3p0g3l.apps.googleusercontent.com`) and Supabase `signInWithIdToken`/`linkIdentity`. Documented D10 Account Linking Rules in `docs/DECISIONS.md`. Enforced mobile phone number verification for Google-first users via `VerifyPhoneScreen` calling `updateUser(phone)` and confirming with `verifyPhoneChangeOtp`. Prevented duplicate account creation for existing linked emails with polite error messaging. Added `google_logo.svg` asset and updated `LoginScreen` Google button. Automatically syncs Google full name and avatar URL to `profiles` table when profile fields are empty. Sign out signs out of Google and Supabase. Clean `flutter analyze`, 150 l10n keys across 8 ARB files verified via `check_l10n.dart`, and 37 unit/widget tests passing)
- [x] **P2.6**: Post-login bootstrap, role assignment and route guards (Status: Done | Created migration `0080_bootstrap.sql` with `apply_role_selection` SECURITY DEFINER RPC (rejecting admin self-assignment and setting up role profile rows) and `get_bootstrap_state` RPC (returning profile, assigned roles, active role, onboarding status, suspension status, and wizard completion in a single round-trip). Extended `doc_type` enum with `background_check`. Built `BootstrapNotifier` in `bootstrap_service.dart` restoring session, applying pending role selections, syncing language to `profiles.language`, updating `last_active_at`, and driving `AuthSessionStatus` (`needsOnboarding`, `signedOut`, `needsRole`, `needsProfile`, `ready`, `suspended`). Added `SuspendedScreen` with appeal support. Updated `AppRouter` redirect guards and deep link replay. Clean `flutter analyze` and 45 passing unit/widget tests)
- [ ] **P2.7**: Job seeker profile wizard (informal, student, part-time) (Status: Todo)
- [ ] **P2.8**: Farmer profile wizard (Status: Todo)
- [ ] **P2.9**: Job provider profile wizard (Status: Todo)
- [ ] **P2.10**: Settings, role switching, category change and account control (Status: Todo)

## Phase 3 (Trust and verification)
- [ ] **P3.1**: Consent centre and privacy controls (Status: Todo)
- [ ] **P3.2**: KYC with DigiLocker / eKYC adapter and masked results (Status: Todo)
- [ ] **P3.3**: Driving licence, student, bank/UPI and background-check status (Status: Todo)
- [ ] **P3.4**: Face enrolment with on-device liveness (Status: Todo)
- [ ] **P3.5**: Face verification, face-verified login and fraud signals (Status: Todo)
- [ ] **P3.6**: Safety onboarding and UdyogaSethu Verified badge (Status: Todo)
- [ ] **P3.7**: Identity kit, profile QR, Trust & Safety Centre and Rights page (Status: Todo)

## Phase 4 (Jobs marketplace: seekers, providers and verified work)
- [ ] **P4.1**: Seeker home with real data and recommendations (Status: Todo)
- [ ] **P4.2**: GPS job map (Status: Todo)
- [ ] **P4.3**: Job detail, applying and job requests (Status: Todo)
- [ ] **P4.4**: Provider: post a job and manage applicants (Status: Todo)
- [ ] **P4.5**: Provider hub, worker search and worker profile (Status: Todo)
- [ ] **P4.6**: Direct booking flow with unverified-worker notice and job protection (Status: Todo)
- [ ] **P4.7**: Job timeline, active job screen, schedule and route ETA (Status: Todo)
- [ ] **P4.8**: QR job ticket and employer attendance scan (Status: Todo)
- [ ] **P4.9**: Two-step verified start, timer, mid-job check, completion and evidence (Status: Todo)
- [ ] **P4.10**: Smart no-show recovery (Status: Todo)
- [ ] **P4.11**: Ratings, reviews, favourites, rebooking and disputes (Status: Todo)

## Phase 5 (Money: wallet, payments and escrow-style protection)
- [ ] **P5.1**: Wallet screen and transaction history (Status: Todo)
- [ ] **P5.2**: Razorpay test checkout, payment methods and receipts (Status: Todo)
- [ ] **P5.3**: Escrow release, refunds and auto-release (Status: Todo)
- [ ] **P5.4**: Earnings dashboard and savings goal planner (Status: Todo)

## Phase 6 (Farmer and produce marketplace)
- [ ] **P6.1**: Farmer home with live mandi prices and weather advisory (Status: Todo)
- [ ] **P6.2**: Farm profile and produce listing management (Status: Todo)
- [ ] **P6.3**: Farm resources, equipment rental and labour hiring (Status: Todo)
- [ ] **P6.4**: Buyer marketplace: browse, filters, map and traceability (Status: Todo)
- [ ] **P6.5**: Cart, delivery slots and checkout (Status: Todo)
- [ ] **P6.6**: Order tracking and farmer order management (Status: Todo)
- [ ] **P6.7**: Subscriptions and apartment group orders (Status: Todo)
- [ ] **P6.8**: Farmer AI tools through a secure Edge Function (Status: Todo)

## Phase 7 (Communication and safety)
- [ ] **P7.1**: Protected inbox and realtime chat (Status: Todo)
- [ ] **P7.2**: Masked voice call (Status: Todo)
- [ ] **P7.3**: SOS, Safety Hub, emergency contacts and job protection claims (Status: Todo)
- [ ] **P7.4**: Push notifications and notification centre (Status: Todo)

## Phase 8 (Voice, intelligence and engagement)
- [ ] **P8.1**: Multilingual voice assistant (Status: Todo)
- [ ] **P8.2**: Smart matching, fair wage, price suggestions and route order (Status: Todo)
- [ ] **P8.3**: XP, levels, streaks, badges and referrals (Status: Todo)
- [ ] **P8.4**: Rewards store, community, events and learning hub (Status: Todo)
- [ ] **P8.5**: Financial inclusion helper, wellness benefits and trust circles (Status: Todo)
- [ ] **P8.6**: Simple mode, low-data mode, text size, voice hints and offline view (Status: Todo)

## Phase 9 (Admin console - SKIPPED)
*Note: The Admin Console is built in a separate web/desktop project and is out of scope for this Flutter app.*

## Phase 10 (Polish, security, tests and release)
- [ ] **P10.1**: Guided demo scenarios (Status: Todo)
- [ ] **P10.2**: Translation pass and empty/loading/error audit (Status: Todo)
- [ ] **P10.3**: Security and privacy audit (red team yourself) (Status: Todo)
- [ ] **P10.4**: Automated tests for the critical flows (Status: Todo)
- [ ] **P10.5**: Release build, documentation and final handover (Status: Todo)

---

## Manual steps pending
*None currently pending.*

## Known issues
*None currently logged.*

