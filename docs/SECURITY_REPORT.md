# UdyogaSethu: Security & Privacy Audit Report (P10.3)

**Date**: 2026-10-12  
**Auditor**: Antigravity Security & Privacy Engineering  
**Scope**: Full Stack (Supabase PostgreSQL, RLS, Storage Buckets, Deno Edge Functions, Flutter Mobile Client)  
**Standard**: OWASP Mobile Top 10, OWASP API Security Top 10, Aadhaar Act / DPDP Act Privacy Safeguards, RBI Escrow Integrity Principles  

---

## Executive Summary

An attacker-minded threat modeling and penetration review was conducted across all 75 database tables, 13 Edge Functions, Flutter application code, authentication lifecycles, and storage buckets. All identified high- and medium-severity authorization gaps have been remediated in migration `supabase/migrations/0770_security_audit_hardening.sql` and backed by regression tests in `supabase/tests/security_audit_tests.sql`.

---

## 1. Supabase RLS & Authorization Inventory

### 1.1 Complete Table Permissions & RLS Matrix

Every table in the database has Row Level Security enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`). Client access via PostgREST is governed strictly by RLS policies:

| Table Name | SELECT Policy | INSERT Policy | UPDATE Policy | DELETE Policy | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `profiles` | `id = auth.uid() OR is_admin()` | `id = auth.uid()` | `id = auth.uid()` | `is_admin()` | Enforced |
| `user_roles` | `user_id = auth.uid() OR is_admin()` | `is_admin()` | `is_admin()` | `is_admin()` | Enforced |
| `worker_profiles` | Authenticated users | `user_id = auth.uid()` | `user_id = auth.uid()` (guarded) | `user_id = auth.uid() OR is_admin()` | Enforced |
| `provider_profiles`| Authenticated users | `user_id = auth.uid()` | `user_id = auth.uid()` (guarded) | `user_id = auth.uid() OR is_admin()` | Enforced |
| `farmer_profiles`  | Authenticated users | `user_id = auth.uid()` | `user_id = auth.uid()` (guarded) | `user_id = auth.uid() OR is_admin()` | Enforced |
| `addresses` | `user_id = auth.uid()` | `user_id = auth.uid()` | `user_id = auth.uid()` | `user_id = auth.uid()` | Enforced |
| `jobs` | Public open/filled or `provider_id = auth.uid()` | `provider_id = auth.uid()` | `provider_id = auth.uid()` | `provider_id = auth.uid()` | Enforced |
| `job_applications` | Worker or Job Provider | `worker_id = auth.uid()` | Worker or Job Provider | `worker_id = auth.uid()` | Enforced |
| `job_assignments` | Assignment parties or Admin | Job Provider only | Parties or Admin (guarded against wage tampering) | Denied (soft lifecycle transitions) | Enforced |
| `assignment_events`| Assignment parties or Admin | Parties only | Denied (append-only timeline) | Denied | Enforced |
| `attendance_logs` | Assignment parties or Admin | Parties only | Denied | Denied | Enforced |
| `job_evidence` | Assignment parties or Admin | `uploader = auth.uid()` | Denied | `uploader = auth.uid()` | Enforced |
| `produce_listings` | Active produce or Farmer | `farmer_id = auth.uid()` | `farmer_id = auth.uid()` | `farmer_id = auth.uid()` | Enforced |
| `delivery_slots` | Active slots or Farmer owner | `farmer_id = auth.uid()` | `farmer_id = auth.uid()` | `farmer_id = auth.uid()` | Enforced |
| `carts` & `cart_items` | Cart owner only | Cart owner only | Cart owner only | Cart owner only | Enforced |
| `orders` | Customer or Farmer | `customer_id = auth.uid()` | Parties (guarded against financial tampering) | Denied | Enforced |
| `order_items` | Customer or Farmer | Customer owner | Denied | Denied | Enforced |
| `order_events` | Order parties or Admin | Order parties or Admin | Denied (append-only) | Denied | Enforced |
| `subscriptions` | Customer or Admin | `customer_id = auth.uid()` | `customer_id = auth.uid()` | Denied | Enforced |
| `group_orders` | Organizer or Admin | `organizer_id = auth.uid()`| `organizer_id = auth.uid()` | Denied | Enforced |
| `group_order_members`| Member or Admin | `user_id = auth.uid()` | Denied | Denied | Enforced |
| `resource_listings`| Active listings or Owner | `owner_id = auth.uid()` | `owner_id = auth.uid()` | `owner_id = auth.uid()` | Enforced |
| `resource_bookings`| Renter or Owner | `renter_id = auth.uid()` | Renter or Owner | `renter_id = auth.uid()` | Enforced |
| `recurring_bookings`| Provider or Worker | `provider_id = auth.uid()`| Provider or Worker | `provider_id = auth.uid()` | Enforced |
| `wallets` | Wallet owner or Admin | Denied (created by system) | Denied (system balance triggers) | Denied | Enforced |
| `ledger_entries` | Wallet owner or Admin | Denied (service_role only)| Denied (`trg_prevent_ledger_mutation` blocks UPDATE/DELETE) | Denied | Enforced |
| `payments` | Payer, Payee, or Admin | `payer_id = auth.uid() AND status='created' AND signature_verified=false` | Denied to clients (service_role only) | Denied | Enforced |
| `payouts` | Account owner or Admin | `user_id = auth.uid() AND status='requested'` | Denied to clients (service_role only) | Denied | Enforced |
| `kyc_records` | Document owner or Admin | Denied to clients (Edge Function only) | Denied to clients | Denied | Enforced |
| `face_profiles` | Profile owner or Admin | Denied to clients (Edge Function / RPC only) | Denied to clients | Denied | Enforced |
| `verification_attempts`| User or Admin | Denied to clients (Edge Function only) | Denied to clients | Denied | Enforced |
| `fraud_flags` | User or Admin | Denied to clients (Edge Function only) | Denied to clients | Denied | Enforced |
| `ratings_reviews` | Public if unhidden; rater/target | `rater_id = auth.uid() AND target_id != auth.uid()` | `rater_id = auth.uid()` | `rater_id = auth.uid() OR is_admin()` | Enforced |
| `favourites` | User only | `user_id = auth.uid()` | Denied | `user_id = auth.uid()` | Enforced |
| `disputes` | Raised by or against or Admin | `raised_by = auth.uid()` | Admin only | Denied | Enforced |
| `dispute_evidence` | Dispute parties or Admin | `uploader = auth.uid()` | Denied | Denied | Enforced |
| `emergency_contacts`| User only | `user_id = auth.uid()` | `user_id = auth.uid()` | `user_id = auth.uid()` | Enforced |
| `sos_incidents` | Incident user or Admin | `user_id = auth.uid()` | Denied | Denied | Enforced |
| `protection_claims`| Claimant or Admin | `claimant_id = auth.uid()` | Denied | Denied | Enforced |
| `notifications` | Notification recipient only | Denied to clients (system triggers) | Recipient only | Recipient only | Enforced |
| `device_tokens` | Device owner only | `user_id = auth.uid()` | `user_id = auth.uid()` | `user_id = auth.uid()` | Enforced |
| `savings_goals` | Goal owner only | `user_id = auth.uid()` | `user_id = auth.uid()` | `user_id = auth.uid()` | Enforced |
| `consent_logs` | Consent granter or Admin | `user_id = auth.uid()` | Denied (immutable log) | Denied | Enforced |
| `chat_threads` | Conversation members or Admin| `participant_a = auth.uid() OR participant_b = auth.uid()` | Denied | Denied | Enforced |
| `chat_messages` | Thread members or Admin | `sender_id = auth.uid() AND is_thread_member()` | Thread members | Denied | Enforced |
| `xp_events`, `user_badges`, `streaks` | User or Admin | Denied to clients (server triggers only) | Denied to clients | Denied | Enforced |
| `referral_codes` | Code owner or Admin | `user_id = auth.uid()` | Denied | Denied | Enforced |
| `referrals` | Referrer, Referred, or Admin | Denied to clients (server validated) | Denied to clients | Denied | Enforced |
| `reward_redemptions`| User or Admin | `user_id = auth.uid()` | Denied | Denied | Enforced |
| `reward_items`, `badges`, `levels` | Authenticated users | Admin only | Admin only | Admin only | Enforced |
| `learning_modules` | Authenticated users | Admin only | Admin only | Admin only | Enforced |
| `learning_progress`| User or Admin | `user_id = auth.uid()` | `user_id = auth.uid()` | Denied | Enforced |
| `credentials` | Credential owner or Admin | Denied to clients (RPC only)| Denied to clients | Denied | Enforced |
| `training_events` | Authenticated users | Admin only | Admin only | Admin only | Enforced |
| `event_registrations`| Registrant or Admin | `user_id = auth.uid()` | Denied | Denied | Enforced |
| `community_posts` | Published posts or Author | `author_id = auth.uid()` | Admin only | Admin only | Enforced |
| `wage_benchmarks`, `mandi_prices` | Authenticated users | Admin only | Admin only | Admin only | Enforced |
| `ad_banners` | Active ads or Admin | Admin only | Admin only | Admin only | Enforced |
| `admin_settings`, `admin_logs`, `audit_log` | Admin only | Admin only | Admin only | Admin only | Enforced |
| `qr_tokens` | Token owner or Admin | Denied (Edge Function only)| Denied | Denied | Enforced |
| `demo_users` | Demo user themselves or Admin | Admin only | Admin only | Admin only | Enforced |

---

### 1.2 Storage Bucket Privacy & Access Review

| Bucket Name | Public Flag | Size Limit | MIME Restrictions | Access Policy & Evidence | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `avatars` | `true` | 5 MB | JPEG, PNG, WebP | Owner folder write (`{user_id}/*`). Read is public. | Verified |
| `produce-images`| `true` | 10 MB | JPEG, PNG, WebP | Owner folder write (`{user_id}/*`). Read is public. | Verified |
| `listing-images`| `true` | 10 MB | JPEG, PNG, WebP | Owner folder write (`{user_id}/*`). Read is public. | Verified |
| `community` | `true` | 10 MB | JPEG, PNG, WebP | Admin write only. Read is public. | Verified |
| `kyc-docs` | `false` | 10 MB | JPEG, PNG, PDF | **Strictly Private**: Owner folder read/write (`{user_id}/*`) or Admin only. Anonymous access denied. | Verified |
| `face-refs` | `false` | 5 MB | JPEG, PNG | **Strictly Private**: Owner folder read/write (`{user_id}/*`) or Admin only. Public read denied. | Verified |
| `job-evidence` | `false` | 25 MB | JPEG, PNG, MP4, Audio | **Strictly Private**: Owner folder read/write or Admin only. Signed URLs used for review. | Verified |
| `dispute-evidence`| `false` | 25 MB | JPEG, PNG, PDF, Audio | **Strictly Private**: Owner folder read/write or Admin only. | Verified |
| `chat-attachments`| `false` | 15 MB | JPEG, PNG, PDF, Audio | **Strictly Private**: Uploader owner folder write. Select permitted for conversation participants (`is_thread_member`) or Admin. | Verified (Hardened in 0770) |

---

## 2. SQL Functions & Edge Functions Audit

### 2.1 Fixed `search_path` on `SECURITY DEFINER` Functions
* **Vulnerability Class**: Insecure search path execution leading to potential privilege escalation via malicious objects.
* **Audit Finding**: Recent migrations (0710–0750) added functions (`create_produce_subscription`, `evaluate_group_orders`, `mask_chat_message_content`, `get_credit_readiness_metrics`, `trg_notify_on_assignment_status`) without explicit `SET search_path = public, extensions`.
* **Remediation**: Implemented in `supabase/migrations/0770_security_audit_hardening.sql` applying `SET search_path = public, extensions` across all `SECURITY DEFINER` functions in the `public` schema.
* **Evidence**: Verified via `tool/audit_security_schema.dart` (32 previously unpinned functions now fixed).

### 2.2 Edge Functions Security
* **Authentication**: All 13 Edge Functions (`kyc-start`, `kyc-callback`, `face-enroll`, `face-verify`, `qr-issue`, `qr-verify`, `payment-create-order`, `payment-webhook`, `sos-trigger`, `send-push`, `mandi-sync`, `ai-assist`, `masked-call`) invoke `getUserClient(req)` or verify provider webhook signatures. Unauthenticated requests return `401 Unauthorized`.
* **Rate Limiting**: Rate limits enforced via `checkRateLimit` (e.g. 30 requests/minute on payment creation, 10 requests/minute on face verification, 30 requests/minute on QR verification).
* **CORS**: Preflight `OPTIONS` requests handled via `handleCors(req)`.
* **Secret Isolation**:
  * `GEMINI_API_KEY`: Kept strictly in Deno server environment; never returned in HTTP responses or exposed to mobile clients.
  * `RAZORPAY_WEBHOOK_SECRET` / `RAZORPAY_KEY_SECRET`: Processed only inside `payment-create-order` and `payment-webhook`.
  * `SUPABASE_SERVICE_ROLE_KEY`: Used strictly via `getServiceClient()` inside Deno isolates for authoritative mutations; completely absent from client bundles.

---

## 3. Privacy, Consent, Authentication & Biometrics Audit

### 3.1 PII & Financial Masking Verification
* **Aadhaar Data Minimization**: Full 12-digit numbers are never stored in the database, local storage, or logs. All records store masked references (`XXXX-XXXX-4321`). In Edge Function logs, regex `\b\d{12}\b` automatically scrubs any accidental occurrences to `[AADHAAR_REDACTED]`.
* **Phone Number Masking**:
  * Unauthenticated / unbooked callers invoking `get_worker_profile_detail` receive masked phone numbers (`XXXXXX1234`) and city-level locations (`Karnataka`). Full phone and exact coordinates are revealed only after an employer books and hires the worker.
  * Realtime chat automatically masks phone numbers (including spaced variants like `98765 43210`) and UPI handles (`[MASKED UPI HANDLE]`) via database trigger `mask_chat_message_content()`.
* **Biometric Face Embeddings**: Raw face photos are processed on-device (via MobileFaceNet) or in temporary memory. Stored vectors (`embedding DOUBLE PRECISION[]`) are mathematical embeddings, not reconstructable face photos. Biometric processing strictly requires JIT consent (`ConsentPurpose.face`).
* **Suspended Accounts**: `profiles.is_suspended = true` causes `BootstrapNotifier` and `AppRouter` redirect guards to lock the interface to `SuspendedScreen` and block job applications and worker search listings.

---

## 4. Payments, Wallet & Ledger Integrity Audit

### 4.1 Anti-Fraud & Concurrency Invariants
* **Webhook Replay Protection**: `payment-webhook` verifies HMAC-SHA256 signatures in constant time (`verifyRazorpayWebhookSignature`). Deduplication is enforced via `payment_webhook_events.event_id`; replayed webhooks return `{ status: 'already_processed' }` with zero duplicate ledger entries.
* **Server-Authoritative Calculations**: Clients cannot pass arbitrary amounts to `payment-create-order`. The server invokes `compute_payment_bill` directly against database jobs/orders to derive base paise, platform fees, and protection fees.
* **Frozen Escrow on Disputes**: While a dispute is active (`status = 'open'`), escrow release is blocked. Funds cannot be released until dispute arbitration completes in the Admin Console.
* **Double Release & Double Refund Prevention**:
  * `release_escrow` updates `payments.status = 'released'` and uses idempotency key `'REL-' || payment_id` on ledger insertion.
  * `refund_escrow` updates `payments.status = 'refunded'` and uses idempotency key `'REF-' || payment_id`. Repeated executions are no-ops.
* **Append-Only Ledger**: The `trg_prevent_ledger_mutation` trigger on `ledger_entries` throws an exception on any attempt to `UPDATE` or `DELETE` existing ledger records. Direct client inserts into `ledger_entries` are rejected by RLS.

---

## 5. Security Findings & Remediations Log

| ID | Component | Vulnerability / Observation | Severity | Remediated In | Regression Test |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SEC-01** | `demo_users` | Table created in 0760 without explicit `ENABLE ROW LEVEL SECURITY`. | **High** | `0770_security_audit_hardening.sql` | `security_audit_tests.sql` (Test 1) |
| **SEC-02** | `job_assignments` | Client could attempt direct `UPDATE` of `agreed_wage_paise` or `worker_id` via PostgREST. | **High** | Added `guard_job_assignments_immutable_columns()` trigger in 0770. | `security_audit_tests.sql` (Test 3) |
| **SEC-03** | `orders` | Client could attempt direct `UPDATE` of `total_paise` or `fee_paise` via PostgREST. | **High** | Added `guard_orders_immutable_columns()` trigger in 0770. | `security_audit_tests.sql` (Test 4) |
| **SEC-04** | `payments` | Client could theoretically insert a payment with pre-set `status='released'`. | **High** | Tightened `payments_insert` policy to require `status='created'` & `signature_verified=false`. | `security_audit_tests.sql` (Test 5) |
| **SEC-05** | `payouts` | Client could insert a payout with `status='processed'`. | **Medium** | Tightened `payouts_insert` policy to require `status='requested'`. | `security_audit_tests.sql` (Test 6) |
| **SEC-06** | `ratings_reviews`| Users could attempt self-rating to artificially inflate scores. | **Medium** | Added `target_id != auth.uid()` constraint to `ratings_reviews_insert`. | `security_audit_tests.sql` (Test 7) |
| **SEC-07** | Functions | 32 `SECURITY DEFINER` functions lacked explicit `SET search_path = public, extensions`. | **Medium** | Fixed via dynamic `ALTER FUNCTION ... SET search_path` in 0770. | Verified via `audit_security_schema.dart` |
| **SEC-08** | Storage | `chat-attachments` select policy restricted reads to uploader, preventing recipient from viewing shared images. | **Medium** | Updated `storage_chat_attachments_select` to include thread members. | Verified via storage policy in 0770 |
| **SEC-09** | `recurring_bookings` & `order_events` | Tables had RLS enabled but lacked explicit policies, defaulting to total denial. | **Low** | Added explicit party policies in 0770. | Verified via `audit_security_schema.dart` |

---

## 6. Accepted Risks & Architectural Boundaries

1. **Simulated Sandbox Payments in Demo Flavour**:
   * *Status*: Accepted Risk (Design Decision D14 & D77).
   * *Mitigation*: Razorpay test keys (`rzp_test_*`) are used; real money is never handled in test environments. Production builds require server-side provisioning of production merchant credentials.
2. **Admin Operations in External Workspace**:
   * *Status*: Architectural Boundary (Decision D77).
   * *Mitigation*: The Admin Console is intentionally excluded from the mobile app. All admin RPCs require role `'admin'` in `user_roles` or `profiles`. Evaluator preview is read-only.
3. **Machine-Translated Indic Languages (mr, bn, or)**:
   * *Status*: Accepted Risk (Documented in `docs/L10N_REVIEW.md`).
   * *Mitigation*: Fallback translations are functional but require native field certification prior to large-scale rural rollout.

---

## 7. Audit Conclusion

The application architecture meets defense-in-depth requirements. All database mutations require authenticated JWTs or service-role authority, financial calculations are authoritative on the server, biometrics are protected, sensitive data is masked, and release builds strictly isolate debug and demo entry points.
