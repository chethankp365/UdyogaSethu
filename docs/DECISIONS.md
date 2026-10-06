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

---

## Known Issues & Pre-Launch Security Requirements

* **KI-01 — Mock Face Matcher (`FACE_MATCHER=mock`) Security Boundary**:
  * **Development Only**: The mock face matcher mode (`FACE_MATCHER=mock`) automatically passes by default (returning similarity `0.92`) unless the first vector element is negative, and mock unit tests supply client-side embeddings.
  * **Pre-Launch Requirement**: The mock matcher MUST NEVER be enabled in production environments. Before public launch, the production `face-verify` Edge Function must calculate face similarity server-side from the uploaded selfie image against the enrolled reference image (or via a certified vendor API). `face-verify` must NEVER trust client-supplied face embeddings or similarity scores.






