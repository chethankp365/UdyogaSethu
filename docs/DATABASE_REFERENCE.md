# UdyogaSethu — Database Reference, Schema Architecture & Security Matrix

> **Document Version**: 1.0.0  
> **Database Platform**: PostgreSQL 15.6 on Supabase (`mmzbpeqkfomnywuzoqii`)  
> **Migration Coverage**: 107 SQL Migration Files (`supabase/migrations/0000_ping.sql` through `0811_chat_rpc_and_storage.sql`)

---

## 1. Relational Database Overview & Extensions

The UdyogaSethu backend database is engineered to handle real-time geospatial matching, high-throughput double-entry financial accounting, and cryptographic token verification.

### Active PostgreSQL Extensions:
* **`postgis`**: Powers geospatial spatial queries (`ST_DWithin`, `ST_MakePoint`, `ST_Distance`) for job discovery, nearby farm produce search, and 150-meter geofenced attendance validation.
* **`pgcrypto`**: Used for UUID v4 generation (`gen_random_uuid()`), password hashing, and HMAC-SHA256 token validation.
* **`pg_trgm`**: Trigram index acceleration for multi-language fuzzy search across worker names, skills, and crop titles.
* **`pg_cron` & `pg_net`**: Schedulers for daily recurring morning delivery generation (`generate_tomorrow_deliveries`) and external mandi price synchronization.

---

## 2. Comprehensive Database Table Catalog

The database schema comprises **75 relational tables** organized into 8 functional domains:

```
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   UDYOGASETHU DATABASE SCHEMA                                 │
├───────────────────────────────┬───────────────────────────────┬───────────────────────────────┤
│ 1. Core Identity & Profiles   │ 2. Jobs & Attendance          │ 3. Agri-Commerce & Orders     │
│   ├── profiles                │   ├── jobs                    │   ├── produce_listings        │
│   ├── worker_profiles         │   ├── job_applications        │   ├── produce_lots            │
│   ├── provider_profiles       │   ├── job_assignments         │   ├── delivery_slots          │
│   ├── farmer_profiles         │   ├── assignment_events       │   ├── carts & cart_items      │
│   ├── addresses               │   ├── attendance_logs         │   ├── orders & order_items    │
│   └── user_roles              │   ├── job_evidence            │   ├── order_events            │
│                               │   └── qr_tokens               │   ├── subscriptions           │
│                               │                               │   ├── group_orders            │
│                               │                               │   └── resource_listings       │
├───────────────────────────────┼───────────────────────────────┼───────────────────────────────┤
│ 4. Financial & Escrow Vault   │ 5. Trust, KYC & Biometrics    │ 6. Realtime Communication     │
│   ├── wallets                 │   ├── kyc_records             │   ├── conversations           │
│   ├── ledger_entries          │   ├── face_profiles           │   ├── messages                │
│   ├── payments                │   ├── verification_attempts   │   ├── chat_blocks             │
│   ├── payouts                 │   ├── fraud_flags             │   ├── chat_reports            │
│   └── payment_webhook_events  │   ├── consent_logs            │   ├── notifications           │
│                               │   ├── ratings_reviews         │   └── user_device_tokens      │
│                               │   ├── favourites              │                               │
│                               │   ├── disputes & evidence     │                               │
│                               │   └── emergency_contacts      │                               │
├───────────────────────────────┴───────────────────────────────┴───────────────────────────────┤
│ 7. Gamification & Community: user_gamification, user_badges, user_streaks, reward_store_items│
│ 8. Catalogs & Settings: service_categories, skills, mandi_prices, wage_benchmarks, admin_settings│
└───────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.1 Domain 1: Identity & User Profiles
* **`public.profiles`**: Core master identity table linked to `auth.users(id)`.
  * *Important Columns*: `id (UUID PK)`, `phone (TEXT UNIQUE)`, `full_name (TEXT)`, `language (TEXT)`, `active_role (app_role)`, `avatar_path (TEXT)`, `daily_earnings_goal_paise (BIGINT)`, `is_suspended (BOOLEAN)`.
* **`public.worker_profiles`**: Extended profile for job seekers (informal, student, part-time).
  * *Important Columns*: `user_id (UUID FK)`, `seeker_type (seeker_type)`, `bio (TEXT)`, `hourly_rate_paise (BIGINT)`, `daily_rate_paise (BIGINT)`, `working_days (TEXT[])`, `has_driving_licence (BOOLEAN)`, `rating_avg (NUMERIC)`, `jobs_completed_count (INT)`, `is_verified_badge (BOOLEAN)`.
  * *Guard Trigger*: Trigger `guard_worker_profile_computed_columns` blocks direct client updates to `rating_avg`, `jobs_completed_count`, and `is_verified_badge`.
* **`public.provider_profiles`**: Extended profile for household employers and contractors.
  * *Important Columns*: `user_id (UUID FK)`, `provider_type (TEXT)`, `categories_hiring (UUID[])`, `typical_crew_size (INT)`, `is_verified_badge (BOOLEAN)`.
* **`public.farmer_profiles`**: Extended profile for smallholder farmers and dairy producers.
  * *Important Columns*: `user_id (UUID FK)`, `farm_name (TEXT)`, `cluster_name (TEXT)`, `total_land_acres (NUMERIC)`, `primary_crops (TEXT[])`, `delivery_radius_km (NUMERIC)`, `pickup_available (BOOLEAN)`, `organic_cert_number (TEXT)`.
* **`public.addresses`**: Multi-address book supporting PostGIS coordinates.
  * *Important Columns*: `id (UUID PK)`, `user_id (UUID FK)`, `address_text (TEXT)`, `landmark (TEXT)`, `location (GEOGRAPHY(POINT, 4326))`, `is_default (BOOLEAN)`.

### 2.2 Domain 2: Jobs, Applications & Attendance Execution
* **`public.jobs`**: Job postings published by providers and farmers (for agri-labour).
  * *Important Columns*: `id (UUID PK)`, `provider_id (UUID FK)`, `category_id (UUID FK)`, `title (TEXT)`, `wage_type (wage_type)`, `wage_paise (BIGINT)`, `slots_total (INT)`, `slots_filled (INT)`, `start_at (TIMESTAMPTZ)`, `location (GEOGRAPHY(POINT, 4326))`, `geofence_radius_m (INT DEFAULT 150)`, `status (job_status)`, `suitable_for (seeker_type[])`, `thumbnail_path (TEXT)`.
  * *Spatial Index*: GIST index on `location` for sub-millisecond proximity queries via `ST_DWithin`.
* **`public.job_applications`**: Applications submitted by workers.
  * *Important Columns*: `id (UUID PK)`, `job_id (UUID FK)`, `worker_id (UUID FK)`, `status (application_status)`, `note (TEXT)`, `created_at (TIMESTAMPTZ)`.
  * *Constraint*: Partial unique index `uq_active_job_application ON (job_id, worker_id) WHERE status != 'withdrawn'` preventing duplicate applications.
* **`public.job_assignments`**: Active and historic contracted work shifts.
  * *Important Columns*: `id (UUID PK)`, `job_id (UUID FK)`, `worker_id (UUID FK)`, `provider_id (UUID FK)`, `booking_code (TEXT UNIQUE)`, `agreed_wage_paise (BIGINT)`, `status (assignment_status)`, `started_at (TIMESTAMPTZ)`, `ended_at (TIMESTAMPTZ)`, `elapsed_seconds (INT)`, `start_selfie_path (TEXT)`, `payment_eligible (BOOLEAN)`.
* **`public.assignment_events`**: Audit timeline logging every shift state transition.
  * *Realtime*: REPLICA IDENTITY FULL enabled for real-time WebSocket broadcasting to Flutter clients.
* **`public.attendance_logs`**: Physical employer QR scan records.
  * *Important Columns*: `id (UUID PK)`, `assignment_id (UUID FK)`, `scanner_id (UUID FK)`, `scanned_at (TIMESTAMPTZ)`, `scanner_location (GEOGRAPHY(POINT, 4326))`, `token_id (UUID FK)`.
* **`public.qr_tokens`**: Short-lived cryptographic tokens for attendance and identity verification.
  * *Important Columns*: `id (UUID PK)`, `token_hash (TEXT UNIQUE)`, `user_id (UUID FK)`, `assignment_id (UUID FK)`, `purpose (TEXT)`, `expires_at (TIMESTAMPTZ)`, `used (BOOLEAN)`, `used_at (TIMESTAMPTZ)`.

### 2.3 Domain 3: Agri-Commerce, Farm Produce & Orders
* **`public.produce_listings`**: Active crop batches listed by farmers.
  * *Important Columns*: `id (UUID PK)`, `farmer_id (UUID FK)`, `crop_name (TEXT)`, `category (TEXT)`, `price_per_unit_paise (BIGINT)`, `unit (TEXT)`, `stock_qty (NUMERIC)`, `reserved_qty (NUMERIC)`, `harvest_date (DATE)`, `farming_method (TEXT)`, `status (produce_status)`.
* **`public.produce_lots`**: Batches tagged for quality traceability.
  * *Important Columns*: `id (UUID PK)`, `listing_id (UUID FK)`, `lot_number (TEXT UNIQUE)`, `lot_token (TEXT UNIQUE)`, `agronomist_notes (TEXT)`, `signature (TEXT)`.
* **`public.orders` & `public.order_items`**: Produce purchases.
  * *Important Columns*: `id (UUID PK)`, `order_code (TEXT UNIQUE)`, `customer_id (UUID FK)`, `farmer_id (UUID FK)`, `total_paise (BIGINT)`, `platform_fee_paise (BIGINT)`, `status (order_status)`, `handover_pin (TEXT)`, `slot_id (UUID FK)`.
* **`public.subscriptions`**: Recurring milk and veggie box delivery rules.
  * *Important Columns*: `id (UUID PK)`, `customer_id (UUID FK)`, `listing_id (UUID FK)`, `frequency (subscription_frequency)`, `quantity (NUMERIC)`, `next_delivery_date (DATE)`, `status (subscription_status)`.
* **`public.group_orders` & `public.group_order_participants`**: Apartment bulk buying pools.
  * *Important Columns*: `id (UUID PK)`, `listing_id (UUID FK)`, `organizer_id (UUID FK)`, `target_qty (NUMERIC)`, `current_qty (NUMERIC)`, `deadline (TIMESTAMPTZ)`, `status (TEXT)`.
* **`public.resource_listings` & `public.resource_bookings`**: Farm equipment rental (tractors, drones, cold storage).

### 2.4 Domain 4: Financial Vault & Append-Only Ledger
* **`public.wallets`**: User balance container linked to profile.
  * *Important Columns*: `id (UUID PK)`, `user_id (UUID FK UNIQUE)`, `currency (TEXT DEFAULT 'INR')`, `is_frozen (BOOLEAN)`.
* **`public.ledger_entries`**: Double-entry financial journal.
  * *Important Columns*: `id (UUID PK)`, `wallet_id (UUID FK)`, `direction (ledger_direction: 'credit' | 'debit')`, `bucket (ledger_bucket: 'available' | 'escrow' | 'reward')`, `amount_paise (BIGINT)`, `entry_type (ledger_entry_type)`, `ref_type (TEXT)`, `ref_id (UUID)`, `balance_after_paise (BIGINT)`, `created_at (TIMESTAMPTZ)`.
  * *Security Invariant*: Database trigger `trg_prevent_ledger_mutation` immediately raises an exception on any attempt to `UPDATE` or `DELETE` rows.
* **`public.payments`**: Gateway payment transaction records.
  * *Important Columns*: `id (UUID PK)`, `payer_id (UUID FK)`, `amount_paise (BIGINT)`, `platform_fee_paise (BIGINT)`, `protection_fee_paise (BIGINT)`, `status (payment_status: 'created' | 'held' | 'released' | 'refunded' | 'failed')`, `razorpay_order_id (TEXT)`, `razorpay_payment_id (TEXT)`, `receipt_no (TEXT UNIQUE)`.
* **`public.payouts`**: Bank account withdrawals.
  * *Important Columns*: `id (UUID PK)`, `wallet_id (UUID FK)`, `amount_paise (BIGINT)`, `method (TEXT)`, `status (payout_status)`, `utr_number (TEXT)`.
* **`public.payment_webhook_events`**: Webhook deduplication log ensuring exact-once event execution.

### 2.5 Domain 5: Trust, KYC, Biometrics & Disputes
* **`public.face_profiles`**: Biometric enrollment template storage.
  * *Important Columns*: `id (UUID PK)`, `user_id (UUID FK UNIQUE)`, `reference_photo_path (TEXT)`, `embedding (DOUBLE PRECISION[])`, `enrolled_at (TIMESTAMPTZ)`.
* **`public.verification_attempts`**: Audit trail of every biometric and KYC check.
* **`public.fraud_flags`**: Automated fraud detection registry.
  * *Rule Keys*: `repeated_face_fail`, `mock_location_detected`, `out_of_radius_start`, `excessive_no_shows`.
* **`public.ratings_reviews`**: Mutual peer ratings and quick tags.
* **`public.disputes` & `public.dispute_evidence`**: Formal grievance reporting with escrow freezing.
* **`public.emergency_contacts` & `public.sos_incidents`**: Safety center contacts and emergency dispatches.

---

## 3. Database Views

1. **`public.public_profiles` (View)**:  
   Exposes safe, non-PII profile information for search results. Automatically strips phone numbers, full residential addresses, and raw Aadhaar references.
2. **`public.wallet_balances` (View)**:  
   Computes authoritative balances dynamically by aggregating credit and debit sums from `ledger_entries` partitioned by wallet and bucket (`available_paise`, `escrow_paise`, `reward_paise`). Eliminates stale cached balance counters.
3. **`public.locality_trust_index` (View)**:  
   Aggregates safety scores, dispute-free job ratios, and verified worker density by geographic locality.

---

## 4. Row Level Security (RLS) Policy Matrix

Row Level Security is enabled across **100% of the 75 public tables**. Direct client writes to server-authoritative columns are denied by default.

### Helper Security Definer Functions:
* `public.has_role(p_role app_role)`: Evaluates if caller holds active role.
* `public.is_admin()`: Returns `true` if `auth.uid()` has admin privilege.
* `public.is_assignment_party(assignment_id UUID)`: Checks if caller is worker or employer of shift.
* `public.is_order_party(order_id UUID)`: Checks if caller is customer or farmer of order.
* `public.is_thread_member(thread_id UUID)`: Checks if caller is participant in chat conversation.

### Policy Rules by Category:

| Table Category | SELECT Access | INSERT Access | UPDATE Access | DELETE Access |
| :--- | :--- | :--- | :--- | :--- |
| **`profiles`** | Owner (`id = auth.uid()`) OR Admin | Owner (`id = auth.uid()`) | Owner (`id = auth.uid()`) | Admin only |
| **`worker_profiles`** | Authenticated (Public view) | Owner (`user_id = auth.uid()`) | Owner (Non-computed fields) | Deny / Admin |
| **`jobs`** | Authenticated (Active/Open) OR Owner | Owner (`provider_id = auth.uid()`) | Owner (`provider_id = auth.uid()`) | Owner |
| **`job_applications`** | Applicant OR Job Provider | Applicant (`worker_id = auth.uid()`) | Applicant OR Job Provider | Applicant (Withdraw) |
| **`job_assignments`** | Assignment Party OR Admin | Service Role / Function | Deny / Handled via RPC | Deny |
| **`attendance_logs`** | Assignment Party OR Admin | Service Role / Function | Deny (Append-only) | Deny |
| **`orders`** | Order Party (Buyer or Farmer) | Buyer (`customer_id = auth.uid()`) | Order Party / Service Role | Deny |
| **`ledger_entries`** | Wallet Owner OR Admin | Service Role / Function | **DENY ALL** (Trigger Enforced) | **DENY ALL** |
| **`payments`** | Payer OR Payee OR Admin | Authenticated (`status = 'created'`) | Service Role Only | Deny |
| **`face_profiles`** | Owner OR Admin | Service Role / Function | Service Role / Function | Deny |
| **`qr_tokens`** | Token Owner OR Admin | Service Role / Function | Service Role / Function | Deny |
| **`messages`** | Conversation Member | Sender (`sender_id = auth.uid()`) | Member (Read-receipt only) | Deny |

---

## 5. Storage Buckets & Policies

Supabase Storage is partitioned into 9 buckets with strict folder-level RLS policies:

```
storage.objects
 ├── avatars/             [Public]   Owner folder: avatars/{userId}/*
 ├── produce-images/      [Public]   Owner folder: produce-images/{userId}/*
 ├── listing-images/      [Public]   Owner folder: listing-images/{userId}/*
 ├── community/           [Public]   Admin upload only
 ├── kyc-docs/            [Private]  Owner folder: kyc-docs/{userId}/* (Owner & Admin read)
 ├── face-refs/           [Private]  Owner folder: face-refs/{userId}/* (Owner & Admin read)
 ├── job-evidence/        [Private]  Assignment parties: job-evidence/{assignmentId}/*
 ├── dispute-evidence/    [Private]  Dispute parties: dispute-evidence/{disputeId}/*
 └── chat-attachments/   [Private]  Conversation members: chat-attachments/{conversationId}/*
```

---

## 6. Migration Management Strategy

The schema is maintained through sequential, immutable SQL migration files located in `supabase/migrations/`:
* Migrations follow a strictly ascending numerical sequence: `0000_ping.sql` $\to$ `0811_chat_rpc_and_storage.sql`.
* All migrations are idempotent (`IF NOT EXISTS`, `CREATE OR REPLACE FUNCTION`).
* Overloaded functions are dropped prior to updating return signatures to prevent PostgreSQL error `42P13`.
* Every security definer function explicitly sets `SET search_path = public, extensions` to protect against search-path injection vulnerabilities.

---

## 7. Document Metadata
* **Author**: Senior Software Architect & Database Engineer
* **Source Validation**: Cross-checked against remote Supabase database `mmzbpeqkfomnywuzoqii` and 107 repository migration scripts.
