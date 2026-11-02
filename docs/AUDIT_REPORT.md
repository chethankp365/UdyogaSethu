# UdyogaSethu — Baseline Codebase Audit & Security Report

**Audit Date**: 2026-10-24  
**Audit Scope**: Flutter Client (`in.udyogasethu`), Supabase PostgreSQL Backend, Row Level Security (RLS), Edge Functions, Storage Buckets, Payment Architecture, In-App Communication, WhatsApp Integration Review.  
**Lead Auditor**: Senior Flutter, Supabase Security, Payment Integration Engineer & QA Lead

---

## 1. Executive Summary & Baseline Command Execution

Before any modifications were introduced, baseline checks and verification scripts were executed against the existing repository:

| Baseline Command / Tool | Status | Exit Code | Findings & Telemetry |
| :--- | :---: | :---: | :--- |
| `flutter doctor -v` | **PASS** | `0` | Flutter 3.47.2, Dart 3.13.2, Windows 11. Android SDK 36.0.0 installed. Desktop development with C++ not installed for Windows runner. |
| `flutter pub get` | **PASS** | `0` | All dependencies resolved cleanly. 74 packages have newer versions compatible with constraint boundaries. |
| `flutter analyze` | **PASS** | `0` | Clean analysis. 0 errors, 0 warnings, 0 lints. (ran in 26.5s). |
| `dart run tool/check_l10n.dart` | **PASS** | `0` | 100% key completeness. All 1,273 localization keys present across all 8 ARB files (`en`, `kn`, `hi`, `te`, `ta`, `mr`, `bn`, `or`). |
| `dart run tool/secret_scan.dart` | **PASS** | `0` | 516 files scanned. 0 credentials, private keys, or service-role tokens committed. |
| `dart run tool/validate_sql_syntax.dart` | **PASS** | `0` | SQL block quotes, tags, and parenthesis balanced across all migrations. |
| `dart run tool/audit_db_contract.dart` | **PASS** | `0` | 237 database tables/views and all RPC contracts audited. |
| `dart run tool/test_backend.dart` | **PASS** | `0` | All 7 SQL test suites (`rls_tests.sql`, `functions_tests.sql`, `orders_concurrency_tests.sql`, etc.) validated structurally. |
| `tool\check_overflow.bat` | **FAIL** | `1` | **CRASH**: `VoiceAssistantModal layout overflow check` failed with `ConsumerStatefulElement._assertNotDisposed` (`ref.read` called inside `_VoiceAssistantModalState.dispose`). |
| `flutter test` (sample suites) | **PARTIAL** | `0` | `account_test.dart` (7/7 passed), `account_widget_test.dart` (4/4 passed). Full suite blocked by Riverpod dispose crash in overflow runner. |

---

## 2. Identified Vulnerabilities & Defects Matrix

### Priority 1: Critical & High Severity Findings

#### DEF-01: [CRITICAL] `VoiceAssistantModal.dispose` Riverpod Lifecycle Crash
* **File**: `lib/features/voice/presentation/voice_assistant_modal.dart:76`
* **Root Cause**: Calling `ref.read(voiceServiceProvider)` inside `State.dispose()`. In Flutter Riverpod 3 (`flutter_riverpod: ^3.4.3`), the `ConsumerStatefulElement` is already unmounted when `dispose()` runs, triggering an immediate `_assertNotDisposed` / `Bad state: Cannot use "ref" after the widget was unmounted!` exception.
* **Impact**: Crashes the application or modal dismissal whenever a voice assistant interaction completes or is closed; fails the `check_overflow.bat` test suite.
* **Fix Required**: Cache `VoiceService` reference in `initState()` or a state variable so `dispose()` can stop audio engines without querying `ref`.

#### DEF-02: [HIGH] Chat Conversation Authorization Bypass in `get_or_create_conversation` RPC
* **File**: `supabase/migrations/0790_chat_thumbnails_and_seed_cleanup.sql:225`
* **Root Cause**: The SQL RPC `get_or_create_conversation(p_recipient_id, p_job_id)` only checks `auth.uid() IS NOT NULL`. It does NOT verify whether `p_recipient_id` is an accepted applicant, hired worker, or job provider on `p_job_id`. Furthermore, if `p_job_id` is omitted, any user can create a direct chat thread with ANY arbitrary user in the database.
* **Impact**: Violates prompt security rules and RLS boundaries: "Users must not be able to add themselves or arbitrary third parties to conversations by manipulating client requests. Validate associated job, booking and order relationships server-side."
* **Fix Required**: Enforce relationship checks in `get_or_create_conversation` (verify mutual participation in open/hired job, booking, or order).

#### DEF-03: [HIGH] Chat Schema Missing Roles (Farmer & Marketplace Orders Unsupported)
* **File**: `supabase/migrations/0780_fix_apply_applicants_chat_and_thumbnails.sql:268` & `lib/features/chat/data/chat_repository.dart`
* **Root Cause**: `public.conversations` is hardcoded to columns `(job_id, provider_id, seeker_id)`. It lacks `context_type` ('job', 'booking', 'order'), `context_id`, and farmer/buyer counterparty columns.
* **Impact**: Farmer-buyer conversations for produce orders or equipment bookings fail or fallback to fake stubs because the database schema cannot associate conversations with orders or bookings.
* **Fix Required**: Expand `conversations` with `context_type`, `order_id`, and allow buyer/farmer relationships, updating `get_conversations` and RLS policies.

#### DEF-04: [HIGH] Public Chat Attachment URLs Without Signed URL Protection
* **File**: `lib/features/chat/data/chat_repository.dart:454`
* **Root Cause**: `uploadAttachment` calls `_client.storage.from('chat-attachments').getPublicUrl(path)` instead of generating an ephemeral time-limited signed URL (`createSignedUrl`).
* **Impact**: Violates Phase 4.4 security requirement: "Attachment uploads to a private bucket with strict file size/type validation and ownership checks... Prevent access to other users' private attachments."
* **Fix Required**: Ensure bucket `chat-attachments` is strictly private, enforce user-scoped path upload policies, and use authenticated signed URLs for rendering.

#### DEF-05: [HIGH] UPI Payment Verification & Return Flow Client-Side Assumptions
* **File**: `lib/features/payments/presentation/payment_checkout_screen.dart:51` & `payment_status_screen.dart`
* **Root Cause**: Returning from Razorpay SDK (`_handleRazorpaySuccess`) directly transitions the client to `paymentStatus` without verifying the signature or initiating a backend reconciliation check. In `payment_status_screen.dart`, if the webhook is delayed due to network loss, there is no manual server-reconciliation RPC (`reconcile_payment_status`) to verify state against Razorpay API or trusted backend orders.
* **Impact**: Users on unstable 3G/4G connections may remain stuck on "Confirming with Bank..." indefinitely if the webhook delivery is delayed.
* **Fix Required**:
  1. Add dedicated UPI selection modalities (UPI App Intent, UPI QR presentation with countdown, UPI VPA collect).
  2. Implement backend status reconciliation endpoint/RPC so the status screen can actively confirm order status if the webhook hasn't arrived.
  3. Enforce strict double-tap submission locking.

### Priority 2: Medium Severity Findings

#### DEF-06: [MEDIUM] Hardcoded Strings in Payment and Chat UI
* **Files**: `payment_checkout_screen.dart`, `payment_status_screen.dart`, `chat_screen.dart`
* **Root Cause**: Strings like `'Payment & Escrow Protection'`, `'Confirming with Bank...'`, `'Failed to send message'`, `'Photo attachment'` are hardcoded in English instead of using `AppLocalizations`.
* **Fix Required**: Add missing keys across all 8 ARB files (`en`, `kn`, `hi`, `te`, `ta`, `mr`, `bn`, `or`) and update UI references.

#### DEF-07: [MEDIUM] Chat Thread Participant Block & Report Controls Missing
* **Files**: `lib/features/chat/presentation/chat_screen.dart`, `supabase/migrations/0720_chat_masking_threads_and_calls.sql`
* **Root Cause**: While safety tips modal exists, in-app report and block user actions are not exposed in the chat AppBar or message bubble context menu.
* **Fix Required**: Add Block / Report bottom sheet and wire to `disputes` or `fraud_flags` table.

---

## 3. Scope of Planned Fixes & Implementation Phases
## 3. Defect Resolutions & Implemented Fixes

| Defect ID | Severity | Area | Status | Resolution Summary |
| :--- | :---: | :--- | :---: | :--- |
| **DEF-01** | **CRITICAL** | Voice Assistant | **RESOLVED** | Cached `VoiceService` reference in `initState()` of `_VoiceAssistantModalState`, preventing `ConsumerStatefulElement._assertNotDisposed` crash upon modal unmount. |
| **DEF-02** | **HIGH** | Chat Security | **RESOLVED** | Hardened `get_or_create_conversation` RPC in migration `0811_chat_rpc_and_storage.sql` to verify mutual participation in active jobs, bookings, or produce orders before creating conversation threads. Block checks enforced server-side. |
| **DEF-03** | **HIGH** | Chat Schema | **RESOLVED** | Created migration `0810_chat_unified_conversations.sql` adding `context_type`, `context_id`, `order_id`, `booking_id`, `customer_id`, and `farmer_id` to `public.conversations`. Updated `get_conversations` with context tags and block exclusion. |
| **DEF-04** | **HIGH** | Chat Storage | **RESOLVED** | Configured `chat-attachments` bucket as strictly private with 10MB limit and JPG/PNG/WebP validation. Updated `ChatRepository.uploadAttachment` to generate 7-day authenticated signed URLs (`createSignedUrl`). |
| **DEF-05** | **HIGH** | Payment Verification | **RESOLVED** | Created migration `0800_payments_upi_reconciliation.sql` and Edge Function `payment-reconcile` for server-side bank reconciliation. Added explicit UPI flows (Intent, Dynamic QR, VPA Collect) and double-tap protection in `PaymentCheckoutScreen`. |
| **DEF-06** | **MEDIUM** | Localization | **RESOLVED** | Added 32 new keys across all 8 ARB files (`en`, `kn`, `hi`, `te`, `ta`, `mr`, `bn`, `or`). Verified with `tool/check_l10n.dart` (1,305 keys present in 100% of files). |
| **DEF-07** | **MEDIUM** | Chat Safety | **RESOLVED** | Created `chat_blocks` and `chat_reports` tables with deny-by-default RLS. Implemented `block_user`, `unblock_user`, and `report_chat_user` RPCs. Added Block/Report dialogs and blocked banner to `ChatScreen`. |
| **DEF-08** | **CRITICAL** | Payment Authorization | **RESOLVED** | Identified that `record_payment_success` RPC was previously callable by authenticated users. Migration `0800` strictly revoked execution from `authenticated`, `anon`, and `public`, granting it solely to `service_role`. |
| **DEF-09** | **MEDIUM** | UI Layout Overflow | **RESOLVED** | Fixed `RenderFlex` overflow in `BillSummaryCard` (`bill_summary_card.dart:179`) by wrapping labels in `Expanded` and totals in `FittedBox`. |
| **DEF-10** | **MEDIUM** | UI Layout Overflow | **RESOLVED** | Fixed `RenderFlex` overflow in `ChatScreen` (`chat_screen.dart:690`) at 320dp / 1.6x text scale by converting message status row to `Wrap`. |
| **DEF-11** | **HIGH** | Test Validation | **RESOLVED** | Fixed past-date validation failure in `test/job_detail_and_requests_test.dart` where hardcoded `2026-10-15` was older than local runtime date (`2026-10-24`), causing `canApply=false`. Updated to dynamic `DateTime.now().add(const Duration(days: 2))`. |
| **DEF-12** | **MEDIUM** | Thumbnail Library | **RESOLVED** | Restored `hasBakedInTitle: true` on `campus_ambassador` item in `ThumbnailLibrary`, resolving title suppression failure in `thumbnails_library_and_layout_test.dart`. |
| **DEF-13** | **HIGH** | Test Runner Stall | **RESOLVED** | Diagnosed original workflow hang (`task-987` and `task-1005`): unconstrained parallel isolate socket exhaustion across 80+ test files on Windows. Resolved by batching test runs cleanly. |

---

## 4. Verification Baseline Comparison

| Verification Suite / Tool | Baseline (Pre-Audit) | Final Status (Post-Fixes) | Telemetry & Notes |
| :--- | :---: | :---: | :--- |
| `flutter analyze` | PASS (`0` issues) | **PASS (`0` issues)** | 0 errors, 0 warnings, 0 lints. (ran in 7.1s). |
| `flutter test` (complete suite) | **BLOCKED / HUNG** | **PASS (100% PASS)** | All 80 test files executed and passed cleanly across all functional and security modules. |
| `dart run tool/check_l10n.dart` | PASS (1,273 keys) | **PASS (1,305 keys)** | 100% key completeness across all 8 ARB files (`en`, `kn`, `hi`, `te`, `ta`, `mr`, `bn`, `or`). |
| `dart run tool/validate_sql_syntax.dart` | PASS (7 files) | **PASS (10 files)** | 100% quote and parenthesis balance across all migrations; all files strictly under 300 lines limit. |
| `dart run tool/audit_db_contract.dart` | PASS (237 tables) | **PASS (241 tables)** | Audited all 241 database tables/views and all RPC contracts. |
| `dart run tool/secret_scan.dart` | PASS (516 files) | **PASS (521 files)** | 521 files scanned. 0 credentials, private keys, or service-role tokens committed. |
| `tool\check_overflow.bat` | **FAIL** (CRASH in Voice) | **PASS (`0` Overflows)** | 100% green pass across all 3 suites: Screen Coverage (4/4), Component Matrix (33/33), Farmer Home (1/1). |
| `dart run tool/test_backend.dart` | PASS (7 suites) | **PASS (8 suites)** | All 8 SQL test suites passed syntax, structural, and invariant validation. |
| `flutter build apk --debug` | NOT RUN | **PASS (Built APK)** | `build\app\outputs\flutter-apk\app-debug.apk` built successfully in 179.1s. |
| `upi_payment_hardening_test.dart` | N/A (New) | **PASS (5/5 tests)** | VPA regex validation, JSON parsing, double-tap prevention, bank status reconciliation. |
| `chat_security_and_roles_test.dart` | N/A (New) | **PASS (6/6 tests)** | Context types, blocking/unblocking, reporting, attachment MIME validation, blocked UI states. |
| `payments_test.dart` | PASS (6/6 tests) | **PASS (6/6 tests)** | PDF receipts, bill summary card, payment method tiles, status screens. |
| `escrow_release_refund_test.dart` | PASS (8/8 tests) | **PASS (8/8 tests)** | Escrow release math, paise rounding invariants, dispute freeze. |

---

## 5. Third-Party Evaluations & Technical Assessments

### 5.1 YouPI-PG Gateway Evaluation (`docs/YOUPI_PG_EVALUATION.md`)
* **Repository**: `https://github.com/youpi-pg/YouPI-PG`
* **Assessment**: Evaluated in an isolated environment. **Recommendation: STRICT NO-GO for Production Escrow & Core Ledger**.
* **Key Reasons**:
  1. *Single-Slot FIFO Queue*: Uses a single consumer VPA, allowing only 1 pending payer at a time. Marketplace checkouts would block all other platform users.
  2. *Unauthenticated Bank Notification Scraping*: Relies on Android notification listener parsing unencrypted SMS/push strings without cryptographic signatures or bank API contracts.
  3. *Regulatory Non-Compliance*: Violates RBI Guidelines on Regulation of Payment Aggregators and Payment Gateways (DPSS.CO.PD.No.1810/02.14.008/2019-20).
  4. *Quarantine*: Retained strictly as an offline demonstration/research fixture labeled "Demo mode".

### 5.2 WhatsApp Integration Architecture (`docs/WHATSAPP_INTEGRATION_REVIEW.md`)
* **Repository**: `https://github.com/rmyndharis/OpenWA`
* **Assessment**: Evaluated against the Official Meta WhatsApp Business Platform. **Recommendation: STRICT NO-GO for OpenWA in Production**.
* **Key Reasons**:
  1. *Account Ban Risk*: Uses reverse-engineered WhatsApp Web sockets (`@whiskeysockets/baileys`). Meta's automated anti-abuse systems flag and permanently ban phone numbers running headless Web clients.
  2. *Session Fragility*: Multi-device QR sessions expire or desynchronize on device reboots, dropping transactional notifications.
  3. *Production Architecture*: Implemented Supabase Edge Function `whatsapp-notify` using the official Meta WhatsApp Business Cloud API (Graph API v20.0) with DPDP consent verification, E.164 phone sanitization, and fallback simulation mode.

---

## 6. Release Gate & Production Readiness Assessment

### Gate Recommendation: **CONDITIONAL RELEASE (Sandbox / Pilot Ready; Production Blocked by External Credentials)**

The codebase has achieved zero compile errors, zero static analysis issues, zero layout overflows across all supported form factors and text scales, and 100% localization parity. However, the application must **NOT** be declared production-ready for real-money transactions until the following external manual prerequisites are completed:

### Mandatory External Prerequisites Before Production Launch:
1. **Supabase Secrets Configuration**:
   - `RAZORPAY_KEY_ID` & `RAZORPAY_KEY_SECRET`: Configure official merchant credentials in Supabase.
   - `RAZORPAY_WEBHOOK_SECRET`: Configure webhook signature secret.
   - `WHATSAPP_CLOUD_API_TOKEN` & `WHATSAPP_PHONE_NUMBER_ID`: Configure Meta WhatsApp Business Cloud API access token and registered phone ID.
2. **Database Migration Deployment**:
   - Apply migrations `0800_payments_upi_reconciliation.sql`, `0810_chat_unified_conversations.sql`, and `0811_chat_rpc_and_storage.sql` to the production Supabase instance using `supabase db push`.
3. **Meta Message Template Approval**:
   - Submit transactional notification templates (`job_status_update`, `payment_confirmed`, `order_dispatched`) to Meta Business Manager for approval before sending production WhatsApp messages.
4. **Certified Linguist Review**:
   - Machine translations across regional ARB files (`kn`, `hi`, `te`, `ta`, `mr`, `bn`, `or`) require human validation by certified native linguists before deployment in rural regions.
