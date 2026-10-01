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
- [ ] **P1.7**: Demo seed data (Status: Todo)
- [ ] **P1.8**: Edge Functions scaffold and Flutter API client (Status: Todo)

## Phase 2 (Onboarding and real authentication)
- [ ] **P2.1**: Splash and intro screens with real bootstrapping (Status: Todo)
- [ ] **P2.2**: Localization and language selection (Status: Todo)
- [ ] **P2.3**: The new role tree: Worker or Farmer, then Seeker or Provider, then type (Status: Todo)
- [ ] **P2.4**: Real phone OTP login (Status: Todo)
- [ ] **P2.5**: Real Google sign-in and account linking (Status: Todo)
- [ ] **P2.6**: Post-login bootstrap, role assignment and route guards (Status: Todo)
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
*None currently pending (0000_ping.sql migration pushed and verified).*

## Known issues
*None currently logged.*
