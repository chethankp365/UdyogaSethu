# UdyogaSethu Backend & Supabase Architecture Guide

## Supabase CLI Workflow Commands

The project uses Supabase CLI for database migrations, Edge Functions deployment, and secret management.

### Project Reference
Project Reference ID: `mmzbpeqkfomnywuzoqii`

### Key Commands

1. **Initialize / Link Project**
   ```bash
   npx supabase init
   npx supabase link --project-ref mmzbpeqkfomnywuzoqii
   ```

2. **Database Migrations**
   - Apply pending local migrations to remote Supabase DB:
     ```bash
     npx supabase db push
     ```
   - Lint migration files for syntax and RLS safety:
     ```bash
     npx supabase db lint
     ```

3. **Edge Functions & Secrets**
   - Set environment secrets on remote Supabase project:
     ```bash
     npx supabase secrets set KEY=value
     ```
   - Deploy an Edge Function:
     ```bash
     npx supabase functions deploy <function_name>
     ```

---

## Ping Verification Function (`public.ping()`)
- Defined in `supabase/migrations/0000_ping.sql`.
- Returns a JSONB object containing `server_time`, `postgres_version`, and `status`.
- Granted execute access to `anon` and `authenticated` roles.

---

## Security Architecture & Row Level Security (RLS) Policy Matrix

All 69 tables in the `public` schema have Row Level Security (RLS) enabled by default (`0050_rls_storage.sql`).
Direct client updates to server-computed fields (such as ratings, completed jobs count, and verification badges) are blocked by database trigger guards (`guard_worker_profile_computed_columns`, etc.).

### Helper Functions
- `public.has_role(p_role app_role)`: Checks if current user has the specified role (`STABLE SECURITY DEFINER`).
- `public.is_admin()`: Returns `true` if current user is an admin (`STABLE SECURITY DEFINER`).
- `public.is_assignment_party(assignment_id UUID)`: Checks if current user is worker or employer (`STABLE SECURITY DEFINER`).
- `public.is_order_party(order_id UUID)`: Checks if current user is customer or seller (`STABLE SECURITY DEFINER`).
- `public.is_thread_member(thread_id UUID)`: Checks if current user is participant_a or participant_b (`STABLE SECURITY DEFINER`).

### Table Access Policy Matrix

| Table Category | Tables Included | SELECT Policy | INSERT Policy | UPDATE Policy | DELETE Policy |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Core Identity** | `profiles` | Owner (`auth.uid() = id`) OR Admin | Owner (`id = auth.uid()`) | Owner (`id = auth.uid()`) | Admin only |
| **Public Profiles View** | `public_profiles` (View) | Public / Authenticated | N/A | N/A | N/A |
| **Sub-Profiles** | `worker_profiles`, `provider_profiles`, `farmer_profiles` | Authenticated | Owner (`user_id = auth.uid()`) | Owner (non-computed via trigger) | Owner / Admin |
| **User Data** | `addresses`, `user_roles` | Owner | Owner / Admin | Owner / Admin | Owner / Admin |
| **Marketplace Jobs** | `jobs`, `produce_listings`, `resource_listings` | Authenticated (if active/open) OR Owner | Owner | Owner | Owner |
| **Applications** | `job_applications` | Applicant OR Job Provider | Applicant (`worker_id = auth.uid()`) | Applicant OR Job Provider | Applicant |
| **Assignments & Work** | `job_assignments`, `assignment_events`, `attendance_logs`, `job_evidence` | Assignment Party OR Admin | Assignment Party / Service Role | Deny / Service Role | Deny |
| **Agri-Commerce** | `carts`, `cart_items`, `orders`, `order_items` | Order Party / Owner | Owner / Buyer | Order Party / Service Role | Deny / Owner (carts) |
| **Financial & Ledger** | `wallets`, `ledger_entries`, `payments`, `payouts` | Owner (`user_id = auth.uid()`) OR Admin | Service Role / Function | Deny (Append-Only) | Deny |
| **Trust & KYC** | `kyc_records`, `face_profiles`, `verification_attempts`, `fraud_flags` | Owner (`user_id = auth.uid()`) OR Admin | Service Role / Function | Service Role / Function | Deny |
| **Reviews & Favourites**| `ratings_reviews`, `favourites` | Authenticated (if not hidden) / Owner | Rater (`rater_id = auth.uid()`) / Owner | Rater | Rater / Owner |
| **Disputes & Safety** | `disputes`, `dispute_evidence`, `sos_incidents`, `protection_claims` | Raised By OR Against OR Admin | Raised By / Claimant | Admin / Service Role | Deny |
| **Private User Logs** | `notifications`, `device_tokens`, `emergency_contacts`, `savings_goals`, `consent_logs` | Owner | Owner | Owner (except `consent_logs`: Deny Update) | Owner |
| **Chat & Messaging** | `chat_threads`, `chat_messages` | Thread Member | Thread Member (`sender_id = auth.uid()`) | Thread Member (`read_at` mark) | Deny |
| **Gamification** | `xp_events`, `user_badges`, `streaks`, `referrals`, `referral_codes` | Owner | Service Role / Trigger | Service Role / Function | Deny |
| **Catalog & Content** | `reward_items`, `badges`, `levels`, `learning_modules`, `training_events`, `community_posts`, `wage_benchmarks`, `mandi_prices`, `ad_banners`, `service_categories`, `skills` | Authenticated | Admin only | Admin only | Admin only |
| **Admin & Security** | `admin_settings`, `admin_logs`, `audit_log` | Admin only (`is_admin()`) | Admin / System | Admin | Admin |

---

## Storage Buckets Architecture

| Bucket Name | Public | Max File Size | Allowed MIME Types | Read Access | Write Access |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `avatars` | **Yes** | 5 MB | `image/jpeg`, `image/png`, `image/webp` | Public (Anyone) | Owner folder (`{user_id}/*`) |
| `produce-images` | **Yes** | 10 MB | `image/jpeg`, `image/png`, `image/webp` | Public (Anyone) | Owner folder (`{user_id}/*`) |
| `listing-images` | **Yes** | 10 MB | `image/jpeg`, `image/png`, `image/webp` | Public (Anyone) | Owner folder (`{user_id}/*`) |
| `community` | **Yes** | 10 MB | `image/jpeg`, `image/png`, `image/webp` | Public (Anyone) | Admin only |
| `kyc-docs` | **No** | 10 MB | `image/jpeg`, `image/png`, `application/pdf` | Owner folder (`{user_id}/*`) OR Admin | Owner folder (`{user_id}/*`) |
| `face-refs` | **No** | 5 MB | `image/jpeg`, `image/png` | Owner folder (`{user_id}/*`) OR Admin | Owner folder (`{user_id}/*`) |
| `job-evidence` | **No** | 25 MB | Images, MP4, MP3, WAV, AAC | Assignment Party OR Admin | Owner folder (`{user_id}/*`) |
| `dispute-evidence` | **No** | 25 MB | Images, PDF, MP3, WAV | Dispute Party OR Admin | Owner folder (`{user_id}/*`) |
| `chat-attachments` | **No** | 15 MB | Images, PDF, MP3, WAV | Thread Member | Owner folder (`{user_id}/*`) |
