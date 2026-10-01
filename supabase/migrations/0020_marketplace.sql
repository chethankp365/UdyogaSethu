-- Migration: 0020_marketplace.sql
-- Description: Job marketplace (jobs, applications, assignments, timeline, attendance, evidence, recurring)
--              and Farm produce marketplace (listings, slots, carts, orders, subscriptions, group orders, resources)

-- 1. Enums for Job Marketplace
CREATE TYPE public.wage_type AS ENUM ('daily', 'hourly', 'fixed');
CREATE TYPE public.payment_mode AS ENUM ('cash', 'upi', 'escrow');
CREATE TYPE public.job_source AS ENUM ('posted', 'direct_booking');
CREATE TYPE public.job_status AS ENUM ('draft', 'open', 'filled', 'closed', 'cancelled');
CREATE TYPE public.application_status AS ENUM ('applied', 'shortlisted', 'rejected', 'withdrawn', 'hired');
CREATE TYPE public.assignment_status AS ENUM (
  'requested',
  'accepted',
  'ticket_issued',
  'arrived',
  'in_progress_verified',
  'completed',
  'payment_released',
  'cancelled',
  'no_show',
  'disputed'
);
CREATE TYPE public.evidence_kind AS ENUM (
  'selfie_start',
  'selfie_completion',
  'photo_work',
  'photo_issue',
  'receipt',
  'other'
);

-- 2. Enums for Farm Marketplace
CREATE TYPE public.produce_category AS ENUM ('vegetable', 'fruit', 'grain', 'dairy', 'flower', 'other');
CREATE TYPE public.produce_status AS ENUM ('active', 'low_stock', 'sold_out', 'paused');
CREATE TYPE public.availability_mode AS ENUM ('same_day', 'next_day', 'pre_order');
CREATE TYPE public.fulfilment_type AS ENUM ('delivery', 'pickup');
CREATE TYPE public.order_status AS ENUM (
  'pending',
  'accepted',
  'packed',
  'out_for_delivery',
  'delivered',
  'cancelled',
  'disputed'
);
CREATE TYPE public.subscription_status AS ENUM ('active', 'paused', 'cancelled');
CREATE TYPE public.group_order_status AS ENUM ('open', 'target_met', 'closed', 'cancelled');
CREATE TYPE public.resource_type AS ENUM (
  'tractor',
  'harvester',
  'drone',
  'seeds',
  'fertilizer',
  'cold_storage',
  'labour_equipment'
);

-- ============================================================================
-- JOB MARKETPLACE TABLES
-- ============================================================================

-- 3. Table: jobs
CREATE TABLE public.jobs (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.service_categories(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  wage_type public.wage_type NOT NULL DEFAULT 'daily',
  wage_paise BIGINT NOT NULL CHECK (wage_paise >= 0),
  est_duration_minutes INT CHECK (est_duration_minutes > 0),
  start_at TIMESTAMPTZ NOT NULL,
  slots_total INT NOT NULL DEFAULT 1 CHECK (slots_total > 0),
  slots_filled INT NOT NULL DEFAULT 0 CHECK (slots_filled >= 0),
  materials_provided BOOLEAN NOT NULL DEFAULT false,
  payment_mode public.payment_mode NOT NULL DEFAULT 'escrow',
  requirements JSONB DEFAULT '{"verified_only": false, "licence_required": false, "students_ok": true}'::jsonb,
  location extensions.geography(Point, 4326),
  address_text TEXT,
  geofence_radius_m INT NOT NULL DEFAULT 150 CHECK (geofence_radius_m > 0),
  source public.job_source NOT NULL DEFAULT 'posted',
  status public.job_status NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Table: job_applications
CREATE TABLE public.job_applications (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status public.application_status NOT NULL DEFAULT 'applied',
  message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_job_applications_job_worker UNIQUE (job_id, worker_id)
);

-- 5. Table: job_assignments
CREATE TABLE public.job_assignments (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  booking_code TEXT UNIQUE NOT NULL,
  status public.assignment_status NOT NULL DEFAULT 'requested',
  agreed_wage_paise BIGINT NOT NULL CHECK (agreed_wage_paise >= 0),
  protection_selected BOOLEAN NOT NULL DEFAULT false,
  ticket_seed TEXT NOT NULL DEFAULT encode(extensions.gen_random_bytes(16), 'hex'),
  arrived_at TIMESTAMPTZ,
  employer_scan_location extensions.geography(Point, 4326),
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  elapsed_seconds INT CHECK (elapsed_seconds >= 0),
  start_selfie_path TEXT,
  start_geo_ok BOOLEAN,
  completion_selfie_path TEXT,
  completion_location extensions.geography(Point, 4326),
  replaced_by UUID REFERENCES public.job_assignments(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Table: assignment_events
CREATE TABLE public.assignment_events (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES public.job_assignments(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  meta JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Table: attendance_logs
CREATE TABLE public.attendance_logs (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES public.job_assignments(id) ON DELETE CASCADE,
  scanned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  token_id TEXT,
  location extensions.geography(Point, 4326),
  result TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Table: job_evidence
CREATE TABLE public.job_evidence (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES public.job_assignments(id) ON DELETE CASCADE,
  uploader UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  kind public.evidence_kind NOT NULL,
  path TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Table: recurring_bookings
CREATE TABLE public.recurring_bookings (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.service_categories(id) ON DELETE SET NULL,
  schedule_rule TEXT NOT NULL,
  preferred_time TIME,
  status public.subscription_status NOT NULL DEFAULT 'active',
  skip_dates DATE[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- FARM PRODUCE & MARKETPLACE TABLES
-- ============================================================================

-- 10. Table: produce_listings
CREATE TABLE public.produce_listings (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category public.produce_category NOT NULL DEFAULT 'vegetable',
  description TEXT,
  price_paise BIGINT NOT NULL CHECK (price_paise >= 0),
  unit TEXT NOT NULL,
  stock_qty NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (stock_qty >= 0),
  status public.produce_status NOT NULL DEFAULT 'active',
  harvest_at TIMESTAMPTZ,
  quality_notes TEXT,
  farming_method TEXT,
  images TEXT[],
  delivery_available BOOLEAN NOT NULL DEFAULT true,
  pickup_available BOOLEAN NOT NULL DEFAULT true,
  availability_mode public.availability_mode NOT NULL DEFAULT 'same_day',
  location extensions.geography(Point, 4326),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. Table: delivery_slots
CREATE TABLE public.delivery_slots (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  slot_date DATE NOT NULL,
  window_start TIME NOT NULL,
  window_end TIME NOT NULL,
  capacity INT NOT NULL DEFAULT 10 CHECK (capacity > 0),
  used INT NOT NULL DEFAULT 0 CHECK (used >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. Table: carts
CREATE TABLE public.carts (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. Table: cart_items
CREATE TABLE public.cart_items (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  cart_id UUID NOT NULL REFERENCES public.carts(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES public.produce_listings(id) ON DELETE CASCADE,
  quantity NUMERIC(10,2) NOT NULL DEFAULT 1.00 CHECK (quantity > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_cart_items_cart_listing UNIQUE (cart_id, listing_id)
);

-- 14. Table: orders
CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  order_code TEXT UNIQUE NOT NULL,
  customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status public.order_status NOT NULL DEFAULT 'pending',
  total_paise BIGINT NOT NULL CHECK (total_paise >= 0),
  fee_paise BIGINT NOT NULL DEFAULT 0 CHECK (fee_paise >= 0),
  fulfilment public.fulfilment_type NOT NULL DEFAULT 'delivery',
  address_id UUID REFERENCES public.addresses(id) ON DELETE SET NULL,
  slot_id UUID REFERENCES public.delivery_slots(id) ON DELETE SET NULL,
  protected BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. Table: order_items
CREATE TABLE public.order_items (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  listing_id UUID REFERENCES public.produce_listings(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  unit TEXT NOT NULL,
  unit_price_paise BIGINT NOT NULL CHECK (unit_price_paise >= 0),
  quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
  subtotal_paise BIGINT NOT NULL CHECK (subtotal_paise >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 16. Table: order_events
CREATE TABLE public.order_events (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  meta JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 17. Table: subscriptions
CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES public.produce_listings(id) ON DELETE CASCADE,
  quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
  frequency TEXT NOT NULL,
  weekdays INT[],
  status public.subscription_status NOT NULL DEFAULT 'active',
  next_delivery_date DATE,
  skip_dates DATE[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 18. Table: group_orders
CREATE TABLE public.group_orders (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  organizer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES public.produce_listings(id) ON DELETE CASCADE,
  community_name TEXT NOT NULL,
  target_qty NUMERIC(10,2) NOT NULL CHECK (target_qty > 0),
  price_tiers JSONB NOT NULL,
  deadline TIMESTAMPTZ NOT NULL,
  status public.group_order_status NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 19. Table: group_order_members
CREATE TABLE public.group_order_members (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  group_order_id UUID NOT NULL REFERENCES public.group_orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
  amount_paise BIGINT NOT NULL CHECK (amount_paise >= 0),
  paid BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 20. Table: resource_listings
CREATE TABLE public.resource_listings (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type public.resource_type NOT NULL,
  name TEXT NOT NULL,
  price_paise BIGINT NOT NULL CHECK (price_paise >= 0),
  unit TEXT NOT NULL,
  description TEXT,
  location extensions.geography(Point, 4326),
  images TEXT[],
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 21. Table: resource_bookings
CREATE TABLE public.resource_bookings (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  resource_id UUID NOT NULL REFERENCES public.resource_listings(id) ON DELETE CASCADE,
  renter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  total_paise BIGINT NOT NULL CHECK (total_paise >= 0),
  status public.assignment_status NOT NULL DEFAULT 'requested',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- ENABLE RLS ON ALL TABLES (No policies yet - P1.5)
-- ============================================================================

ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recurring_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produce_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_order_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_bookings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Geography GIST Indexes
CREATE INDEX idx_jobs_location ON public.jobs USING GIST (location);
CREATE INDEX idx_job_assignments_scan_loc ON public.job_assignments USING GIST (employer_scan_location);
CREATE INDEX idx_job_assignments_comp_loc ON public.job_assignments USING GIST (completion_location);
CREATE INDEX idx_attendance_logs_location ON public.attendance_logs USING GIST (location);
CREATE INDEX idx_produce_listings_location ON public.produce_listings USING GIST (location);
CREATE INDEX idx_resource_listings_location ON public.resource_listings USING GIST (location);

-- Btree Indexes on Status & Foreign Keys
CREATE INDEX idx_jobs_provider_status ON public.jobs (provider_id, status);
CREATE INDEX idx_jobs_status_start ON public.jobs (status, start_at);
CREATE INDEX idx_job_apps_job_status ON public.job_applications (job_id, status);
CREATE INDEX idx_job_apps_worker ON public.job_applications (worker_id);
CREATE INDEX idx_job_assign_job ON public.job_assignments (job_id);
CREATE INDEX idx_job_assign_worker_status ON public.job_assignments (worker_id, status);
CREATE INDEX idx_job_assign_code ON public.job_assignments (booking_code);
CREATE INDEX idx_assign_events_assign ON public.assignment_events (assignment_id);
CREATE INDEX idx_produce_farmer_status ON public.produce_listings (farmer_id, status);
CREATE INDEX idx_orders_customer ON public.orders (customer_id);
CREATE INDEX idx_orders_farmer_status ON public.orders (farmer_id, status);
CREATE INDEX idx_orders_code ON public.orders (order_code);
CREATE INDEX idx_resource_owner ON public.resource_listings (owner_id);

-- ============================================================================
-- TRIGGERS FOR updated_at
-- ============================================================================

CREATE TRIGGER trg_jobs_updated_at BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_job_applications_updated_at BEFORE UPDATE ON public.job_applications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_job_assignments_updated_at BEFORE UPDATE ON public.job_assignments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_recurring_bookings_updated_at BEFORE UPDATE ON public.recurring_bookings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_produce_listings_updated_at BEFORE UPDATE ON public.produce_listings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_carts_updated_at BEFORE UPDATE ON public.carts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_cart_items_updated_at BEFORE UPDATE ON public.cart_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_group_orders_updated_at BEFORE UPDATE ON public.group_orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_resource_listings_updated_at BEFORE UPDATE ON public.resource_listings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_resource_bookings_updated_at BEFORE UPDATE ON public.resource_bookings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- TABLE COMMENTS
-- ============================================================================

COMMENT ON TABLE public.jobs IS 'Job postings with wage, location geofence, and slots.';
COMMENT ON TABLE public.job_applications IS 'Worker applications for posted jobs.';
COMMENT ON TABLE public.job_assignments IS 'Core lifecycle unit for hired worker booking assignment with two-step QR/GPS verification.';
COMMENT ON TABLE public.assignment_events IS 'Audit timeline log of job assignment status transitions.';
COMMENT ON TABLE public.attendance_logs IS 'Employer attendance scan logs for QR tickets.';
COMMENT ON TABLE public.job_evidence IS 'Uploaded photos and receipts for job start/completion/issues.';
COMMENT ON TABLE public.recurring_bookings IS 'Standing repeat job bookings between provider and worker.';
COMMENT ON TABLE public.produce_listings IS 'Farmer produce inventory listings.';
COMMENT ON TABLE public.delivery_slots IS 'Farmer delivery and pickup time window capacity slots.';
COMMENT ON TABLE public.carts IS 'Customer active shopping cart.';
COMMENT ON TABLE public.cart_items IS 'Individual items inside a customer cart.';
COMMENT ON TABLE public.orders IS 'Farm produce orders placed by buyers/customers.';
COMMENT ON TABLE public.order_items IS 'Item breakdown for agri-produce orders.';
COMMENT ON TABLE public.order_events IS 'Order status history timeline.';
COMMENT ON TABLE public.subscriptions IS 'Recurring produce subscription orders (e.g. daily milk, weekly vegetables).';
COMMENT ON TABLE public.group_orders IS 'Apartment & community bulk agri-buy group orders.';
COMMENT ON TABLE public.group_order_members IS 'Individual buyer contributions to a group order.';
COMMENT ON TABLE public.resource_listings IS 'Agricultural equipment and resource rentals (tractors, drones, cold storage).';
COMMENT ON TABLE public.resource_bookings IS 'Renter bookings for agricultural equipment.';
