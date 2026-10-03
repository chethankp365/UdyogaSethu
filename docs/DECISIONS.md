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

*No simulation decisions recorded yet.*


