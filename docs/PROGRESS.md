# UdyogaSethu Build Progress & Task Tracker

## Phase 0 (Foundation)
- [x] **P0.1**: Rules, memory files and UI reference (Status: Done | Completed: Phase 0 Step 0.1 documentation & setup)
- [x] **P0.2**: Create the Flutter project (Status: Done | Scaffolded Flutter app `in.udyogasethu`, added base dependencies, configured analysis options & Android permissions)
- [x] **P0.3**: Design system and component gallery (Status: Done | Built design tokens, typography fallbacks, light/DarkPanelTheme, 21 reusable core widgets, responsive container, and debug-only /dev/gallery route)
- [x] **P0.4**: Connect Supabase (Status: Done | Initialized Supabase in main.dart, created SupabaseService/providers, AppException error mapping, AppLogger, 0000_ping.sql migration, BACKEND.md, and debug route /dev/connection)
- [ ] **P0.5**: Router and role-based app shells (Status: Todo)

## Phase 1 (Database, security and server logic)
- [ ] **P1.1**: Schema part 1: identity, roles and profiles (Status: Todo)
- [ ] **P1.2**: Schema part 2: jobs, bookings and farm marketplace (Status: Todo)
- [ ] **P1.3**: Schema part 3: money, trust and safety (Status: Todo)
- [ ] **P1.4**: Schema part 4: engagement, admin and content (Status: Todo)
- [ ] **P1.5**: Row Level Security and storage buckets (Status: Todo)
- [ ] **P1.6**: SQL functions: nearby search, job state machine and wallet (Status: Todo)
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

## Phase 9 (Admin console)
- [ ] **P9.1**: Admin shell, operations dashboard and social impact (Status: Todo)
- [ ] **P9.2**: Verification review queue and training attendance (Status: Todo)
- [ ] **P9.3**: Fraud monitoring and dispute resolution (Status: Todo)
- [ ] **P9.4**: Policy studio, moderation and governance content (Status: Todo)

## Phase 10 (Polish, security, tests and release)
- [ ] **P10.1**: Guided demo scenarios (Status: Todo)
- [ ] **P10.2**: Translation pass and empty/loading/error audit (Status: Todo)
- [ ] **P10.3**: Security and privacy audit (red team yourself) (Status: Todo)
- [ ] **P10.4**: Automated tests for the critical flows (Status: Todo)
- [ ] **P10.5**: Release build, documentation and final handover (Status: Todo)

---

## Manual steps pending
- Run `npx supabase login` (or set `SUPABASE_ACCESS_TOKEN` / DB password) and execute `npx supabase db push` to apply `supabase/migrations/0000_ping.sql` (`public.ping()`) to remote project `mmzbpeqkfomnywuzoqii`.

## Known issues
*None currently logged.*
