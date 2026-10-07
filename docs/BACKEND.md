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

---

## Phase 4.3: Job Detail, Pre-Application Eligibility & Direct-Booking Requests

### Remote RPCs
1. **`public.check_job_eligibility(p_job_id UUID)`**:
   Evaluates DL requirement, verified worker requirement, category audience compatibility, and checks whether the applicant already has an overlapping active/accepted shift.
2. **`public.get_job_detail(p_job_id UUID)`**:
   Returns enriched job metadata including employer verified badge, ratings, reviews count, category icon/slug, and open slots count.
3. **`public.debug_seed_overlapping_requests(p_worker_id UUID DEFAULT NULL)`**:
   Creates 2 demo direct-booking requests from demo employers (`Sharma Builders` and `Sai Electricals`) with overlapping time slots:
   - Slot A: 10:00 AM – 02:00 PM (4 hrs, ₹900)
   - Slot B: 01:00 PM – 05:00 PM (4 hrs, ₹850) — overlaps with Slot A between 1:00 PM and 2:00 PM!

### Manual SQL Snippet for Overlapping Direct Bookings
If testing directly via the Supabase SQL editor for your logged-in worker ID:
```sql
-- 1. Call debug seed RPC for your worker UUID:
SELECT public.debug_seed_overlapping_requests('<YOUR-LOGGED-IN-WORKER-UUID>');

-- Or execute manually:
DO $$
DECLARE
  v_worker_id UUID := '<YOUR-LOGGED-IN-WORKER-UUID>';
  v_prov1 UUID;
  v_prov2 UUID;
  v_cat UUID;
  v_job1 UUID;
  v_job2 UUID;
  v_today DATE := CURRENT_DATE + INTERVAL '1 day';
BEGIN
  SELECT id INTO v_prov1 FROM public.profiles WHERE full_name = 'Sharma Builders' LIMIT 1;
  SELECT id INTO v_prov2 FROM public.profiles WHERE full_name = 'Sai Electricals' LIMIT 1;
  SELECT id INTO v_cat FROM public.service_categories WHERE slug = 'electrician' LIMIT 1;

  -- Create Job 1 (10 AM - 2 PM)
  INSERT INTO public.jobs (
    provider_id, category_id, title, description,
    wage_type, wage_paise, est_duration_minutes, start_at,
    status, slots_total, slots_filled, address_text
  ) VALUES (
    v_prov1, v_cat, 'Commercial Electrician - Slot A', 'Conduit and cabling work',
    'daily', 90000, 240, (v_today || ' 10:00:00+05:30')::TIMESTAMPTZ,
    'open', 1, 0, 'Koramangala 4th Block, Bengaluru'
  ) RETURNING id INTO v_job1;

  -- Create Job 2 (1 PM - 5 PM, overlaps 1 PM - 2 PM)
  INSERT INTO public.jobs (
    provider_id, category_id, title, description,
    wage_type, wage_paise, est_duration_minutes, start_at,
    status, slots_total, slots_filled, address_text
  ) VALUES (
    v_prov2, v_cat, 'Site Electrical Maintenance - Slot B', 'Circuit maintenance',
    'daily', 85000, 240, (v_today || ' 13:00:00+05:30')::TIMESTAMPTZ,
    'open', 1, 0, 'HSR Layout, Bengaluru'
  ) RETURNING id INTO v_job2;

  -- Send direct booking assignments
  INSERT INTO public.job_assignments (
    job_id, worker_id, status, assigned_by, scheduled_start, scheduled_end
  ) VALUES
    (v_job1, v_worker_id, 'invited', v_prov1, (v_today || ' 10:00:00+05:30')::TIMESTAMPTZ, (v_today || ' 14:00:00+05:30')::TIMESTAMPTZ),
    (v_job2, v_worker_id, 'invited', v_prov2, (v_today || ' 13:00:00+05:30')::TIMESTAMPTZ, (v_today || ' 17:00:00+05:30')::TIMESTAMPTZ);

---

## Phase 4.4: Provider Jobs Management & Applicant Hiring

### Remote RPCs
1. **`public.post_provider_job(...)`**:
   - Inserts a job posting for the authenticated provider into `public.jobs`.
   - Accepts category, title, description, wage type (`daily`, `hourly`, `fixed`), wage in paise, estimated duration minutes, start timestamp (`start_at`), total slots (`slots_total`), materials provided boolean, payment mode (`cash`, `upi`, `escrow`), requirements (`verified_only`, `licence_required`, `students_ok`), address text, latitude/longitude, and geofence radius (defaulting to 150m).
   - Automatically computes PostGIS geography point `ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography`.
   - Enforces provider profile ownership (`provider_id = auth.uid()`) and non-empty title/wage.

2. **`public.update_provider_job(...)`**:
   - Updates title, description, wage, duration, start time, total slots, materials, payment mode, requirements, address, location, and geofence.
   - Prevents updating if the job is already `cancelled` or `completed`.
   - Ensures `slots_total >= slots_filled`.

3. **`public.get_provider_jobs(p_provider_id UUID DEFAULT NULL)`**:
   - Returns provider's jobs list with enriched counts: `applicant_count` and `hired_count`.
   - Includes category name and icon slug from `service_categories`.
   - Filters by owner (`auth.uid()`) by default.

4. **`public.get_job_applicants(p_job_id UUID)`**:
   - Returns all applicants for a given job owned by the calling provider.
   - Joins `job_applications` with `profiles` and `worker_profiles`.
   - Returns worker display name, phone, avatar URL, verification status, rating, completed jobs count, worker skills array, spoken languages array, applicant distance in meters (`distance_m`) computed from job location, application status (`pending`, `shortlisted`, `rejected`, `hired`, `withdrawn`), application note, applied timestamp, and hired assignment ID if hired.

5. **`public.update_provider_job_status(p_job_id UUID, p_status job_status)`**:
   - Allows provider to toggle status between `open`, `draft` (paused), `cancelled`, and `closed`.
   - When cancelling a job with active/hired workers, marks pending assignments as `cancelled` with reason note.

6. **`public.respond_to_application(p_application_id UUID, p_action text, p_notes text DEFAULT NULL)`**:
   - Handles applicant management actions: `hire`, `shortlist`, `reject`.
   - When `hire`:
     - Checks that job is not full (`slots_filled < slots_total`).
     - Verifies application is not already hired.
     - Increments `jobs.slots_filled`.
     - Automatically transitions job status to `'filled'` if `slots_filled = slots_total`.
     - Creates/activates a `job_assignments` record with status `'assigned'` or `'accepted'`, setting `scheduled_start` and `scheduled_end`.
     - Inserts an in-app notification in `public.notifications` alerting the worker that they have been hired.
