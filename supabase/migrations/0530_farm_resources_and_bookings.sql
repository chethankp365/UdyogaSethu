-- Migration: 0530_farm_resources_and_bookings.sql
-- Description: Enhances resource listings and bookings schema with specs, address, ratings,
--              booking quantities, payment integration, and updated nearby_resources RPC.
--              Includes compute_payment_bill extension and atomic book_resource procedure.

-- ============================================================================
-- 1. EXTEND RESOURCE LISTINGS AND BOOKINGS TABLES
-- ============================================================================

ALTER TABLE public.resource_listings
  ADD COLUMN IF NOT EXISTS specs TEXT,
  ADD COLUMN IF NOT EXISTS address_text TEXT,
  ADD COLUMN IF NOT EXISTS rating_avg NUMERIC(3,2) DEFAULT 4.8,
  ADD COLUMN IF NOT EXISTS rating_count INT DEFAULT 12,
  ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT true;

ALTER TABLE public.resource_bookings
  ADD COLUMN IF NOT EXISTS quantity NUMERIC DEFAULT 1,
  ADD COLUMN IF NOT EXISTS unit TEXT DEFAULT 'hour',
  ADD COLUMN IF NOT EXISTS delivery_address TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL;

-- ============================================================================
-- 2. RLS POLICIES FOR RESOURCE BOOKINGS
-- ============================================================================

ALTER TABLE public.resource_bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS resource_bookings_select ON public.resource_bookings;
CREATE POLICY resource_bookings_select ON public.resource_bookings FOR SELECT USING (
  renter_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.resource_listings rl WHERE rl.id = resource_id AND rl.owner_id = auth.uid())
  OR public.is_admin()
);

DROP POLICY IF EXISTS resource_bookings_insert ON public.resource_bookings;
CREATE POLICY resource_bookings_insert ON public.resource_bookings FOR INSERT WITH CHECK (
  renter_id = auth.uid()
);

DROP POLICY IF EXISTS resource_bookings_update ON public.resource_bookings;
CREATE POLICY resource_bookings_update ON public.resource_bookings FOR UPDATE USING (
  renter_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.resource_listings rl WHERE rl.id = resource_id AND rl.owner_id = auth.uid())
  OR public.is_admin()
);

-- ============================================================================
-- 3. ENHANCED NEARBY_RESOURCES RPC WITH COORDINATES & VENDOR METADATA
-- ============================================================================

DROP FUNCTION IF EXISTS public.nearby_resources(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, public.resource_type, TEXT, INT, INT);
DROP FUNCTION IF EXISTS public.nearby_resources;

CREATE OR REPLACE FUNCTION public.nearby_resources(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 50000,
  p_type public.resource_type DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 40,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  owner_id UUID,
  type public.resource_type,
  name TEXT,
  price_paise BIGINT,
  unit TEXT,
  images TEXT[],
  distance_m DOUBLE PRECISION,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  description TEXT,
  specs TEXT,
  address_text TEXT,
  rating_avg NUMERIC,
  verified BOOLEAN,
  owner_name TEXT
) AS $$
DECLARE
  v_point extensions.geography;
BEGIN
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL AND p_lat <> 0 AND p_lng <> 0 THEN
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  ELSE
    -- Default central anchor (Mandya / Bengaluru cluster)
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(76.8951, 12.5244), 4326)::extensions.geography;
  END IF;

  RETURN QUERY
  SELECT
    rl.id,
    rl.owner_id,
    rl.type,
    rl.name,
    rl.price_paise,
    rl.unit,
    rl.images,
    extensions.ST_Distance(COALESCE(rl.location, p.home_location, v_point), v_point) AS distance_m,
    extensions.ST_Y(COALESCE(rl.location, p.home_location, v_point)::extensions.geometry) AS lat,
    extensions.ST_X(COALESCE(rl.location, p.home_location, v_point)::extensions.geometry) AS lng,
    rl.description,
    rl.specs,
    COALESCE(rl.address_text, p.district, 'Karnataka Agri Hub') AS address_text,
    COALESCE(rl.rating_avg, 4.8) AS rating_avg,
    COALESCE(rl.verified, true) AS verified,
    COALESCE(p.full_name, 'Agri Service Vendor') AS owner_name
  FROM public.resource_listings rl
  JOIN public.profiles p ON rl.owner_id = p.id
  WHERE rl.active = true
    AND (p_type IS NULL OR rl.type = p_type)
    AND (p_search_query IS NULL OR (
      rl.name ILIKE '%' || p_search_query || '%' OR
      rl.description ILIKE '%' || p_search_query || '%' OR
      COALESCE(rl.specs, '') ILIKE '%' || p_search_query || '%' OR
      COALESCE(rl.address_text, '') ILIKE '%' || p_search_query || '%'
    ))
  ORDER BY distance_m ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.nearby_resources TO anon, authenticated, service_role;

-- ============================================================================
-- 4. EXTEND COMPUTE_PAYMENT_BILL FOR RESOURCE BOOKINGS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.compute_payment_bill(
  p_ref_type TEXT,
  p_ref_id UUID,
  p_protection_override BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
  base_amount_paise BIGINT,
  platform_fee_paise BIGINT,
  protection_fee_paise BIGINT,
  total_paise BIGINT,
  payer_id UUID,
  payee_id UUID,
  is_protected BOOLEAN,
  description TEXT
) AS $$
DECLARE
  v_base BIGINT := 0;
  v_plat_fee BIGINT := 0;
  v_prot_fee BIGINT := 0;
  v_total BIGINT := 0;
  v_payer UUID;
  v_payee UUID;
  v_prot BOOLEAN := true;
  v_desc TEXT := '';
  v_plat_pct NUMERIC := 0.05;
BEGIN
  IF p_ref_type = 'job' THEN
    SELECT
      j.wage_paise,
      ja.employer_id,
      ja.worker_id,
      ja.protected,
      'Job Wage: ' || j.title
    INTO v_base, v_payer, v_payee, v_prot, v_desc
    FROM public.job_assignments ja
    JOIN public.jobs j ON j.id = ja.job_id
    WHERE ja.id = p_ref_id;

    IF v_payer IS NULL THEN
      RAISE EXCEPTION 'Assignment % not found.', p_ref_id;
    END IF;

    v_plat_fee := ROUND(v_base * v_plat_pct);
    v_prot_fee := 2500; -- Flat ₹25 protection fee

  ELSIF p_ref_type = 'order' THEN
    SELECT
      o.total_paise,
      o.customer_id,
      o.farmer_id,
      o.protected,
      'Farm Produce Order #' || o.order_code
    INTO v_base, v_payer, v_payee, v_prot, v_desc
    FROM public.orders o
    WHERE o.id = p_ref_id;

    IF v_payer IS NULL THEN
      RAISE EXCEPTION 'Order % not found.', p_ref_id;
    END IF;

  ELSIF p_ref_type = 'resource_booking' THEN
    SELECT
      rb.total_paise,
      rb.renter_id,
      rl.owner_id,
      true,
      'Equipment Rental: ' || rl.name
    INTO v_base, v_payer, v_payee, v_prot, v_desc
    FROM public.resource_bookings rb
    JOIN public.resource_listings rl ON rl.id = rb.resource_id
    WHERE rb.id = p_ref_id;

    IF v_payer IS NULL THEN
      RAISE EXCEPTION 'Resource booking % not found.', p_ref_id;
    END IF;

    v_plat_fee := ROUND(v_base * v_plat_pct);
    v_prot_fee := 2500; -- Flat ₹25 escrow guarantee

  ELSIF p_ref_type = 'group_order' THEN
    SELECT
      COALESCE(SUM(gom.contribution_paise), 50000),
      auth.uid(),
      go.farmer_id,
      true,
      'Group Order: ' || COALESCE(go.pool_code, 'Community Pool')
    INTO v_base, v_payer, v_payee, v_prot, v_desc
    FROM public.group_orders go
    LEFT JOIN public.group_order_members gom ON gom.group_order_id = go.id
    WHERE go.id = p_ref_id
    GROUP BY go.id, go.farmer_id, go.pool_code;

    IF v_payer IS NULL THEN
      v_payer := auth.uid();
    END IF;

  ELSIF p_ref_type = 'subscription' THEN
    v_base := 49900; -- ₹499
    v_plat_fee := 0;
    v_prot_fee := 0;
    v_payer := auth.uid();
    v_payee := NULL;
    v_prot := false;
    v_desc := 'UdyogaSethu Pro Membership';

  ELSE
    RAISE EXCEPTION 'Unsupported ref_type %', p_ref_type;
  END IF;

  IF p_protection_override IS NOT NULL THEN
    v_prot := p_protection_override;
  END IF;

  IF NOT v_prot THEN
    v_prot_fee := 0;
  END IF;

  v_total := v_base + v_plat_fee + v_prot_fee;

  RETURN QUERY SELECT
    v_base AS base_amount_paise,
    v_plat_fee AS platform_fee_paise,
    v_prot_fee AS protection_fee_paise,
    v_total AS total_paise,
    v_payer AS payer_id,
    v_payee AS payee_id,
    v_prot AS is_protected,
    v_desc AS description;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.compute_payment_bill TO authenticated, service_role;

-- ============================================================================
-- 5. ATOMIC BOOK_RESOURCE RPC WITH ESCROW HOLD
-- ============================================================================

CREATE OR REPLACE FUNCTION public.book_resource(
  p_resource_id UUID,
  p_start_at TIMESTAMPTZ,
  p_end_at TIMESTAMPTZ,
  p_quantity NUMERIC,
  p_delivery_address TEXT,
  p_notes TEXT DEFAULT NULL,
  p_payment_method TEXT DEFAULT 'upi'
)
RETURNS JSONB AS $$
DECLARE
  v_renter_id UUID := auth.uid();
  v_resource public.resource_listings%ROWTYPE;
  v_total_paise BIGINT;
  v_booking_id UUID;
  v_payment_id UUID;
  v_receipt_no TEXT;
  v_seq_val BIGINT;
BEGIN
  IF v_renter_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_resource FROM public.resource_listings WHERE id = p_resource_id AND active = true;
  IF v_resource.id IS NULL THEN
    RAISE EXCEPTION 'Resource listing not found or inactive.';
  END IF;

  v_total_paise := (v_resource.price_paise * COALESCE(p_quantity, 1))::BIGINT;

  -- 1. Insert Booking Record
  INSERT INTO public.resource_bookings (
    resource_id,
    renter_id,
    start_at,
    end_at,
    quantity,
    unit,
    delivery_address,
    notes,
    total_paise,
    status
  ) VALUES (
    p_resource_id,
    v_renter_id,
    p_start_at,
    p_end_at,
    COALESCE(p_quantity, 1),
    v_resource.unit,
    p_delivery_address,
    p_notes,
    v_total_paise,
    'confirmed'
  ) RETURNING id INTO v_booking_id;

  -- 2. Format Sequential Receipt Number
  SELECT nextval('public.receipt_no_seq') INTO v_seq_val;
  v_receipt_no := 'RCP-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(v_seq_val::TEXT, 6, '0');

  -- 3. Create Payment Record with Protected Escrow
  INSERT INTO public.payments (
    payer_id,
    payee_id,
    ref_type,
    ref_id,
    amount_paise,
    platform_fee_paise,
    method,
    status,
    protected,
    receipt_no
  ) VALUES (
    v_renter_id,
    v_resource.owner_id,
    'resource_booking',
    v_booking_id,
    v_total_paise,
    ROUND(v_total_paise * 0.05),
    COALESCE(p_payment_method, 'upi')::public.payment_method,
    'created',
    true,
    v_receipt_no
  ) RETURNING id INTO v_payment_id;

  -- 4. Link Payment to Booking
  UPDATE public.resource_bookings SET payment_id = v_payment_id WHERE id = v_booking_id;

  -- 5. Trigger Escrow Hold (locks funds in Escrow bucket)
  PERFORM public.hold_escrow(v_payment_id);

  RETURN jsonb_build_object(
    'booking_id', v_booking_id,
    'payment_id', v_payment_id,
    'receipt_no', v_receipt_no,
    'total_paise', v_total_paise,
    'status', 'confirmed',
    'escrow_held', true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.book_resource TO authenticated, service_role;

-- ============================================================================
-- 6. SEED SCREEN 23 & 26 REALISTIC KARNATAKA AGRI RESOURCES
-- ============================================================================

DO $$
DECLARE
  v_f1 UUID;
  v_f3 UUID;
BEGIN
  -- Grab existing demo farmers
  SELECT user_id INTO v_f1 FROM public.demo_users WHERE role = 'farmer' LIMIT 1;
  IF v_f1 IS NULL THEN
    SELECT id INTO v_f1 FROM public.profiles LIMIT 1;
  END IF;

  v_f3 := v_f1;

  IF v_f1 IS NOT NULL THEN
    -- Screen 23 & 26 Equipment Pins in Mandya, Devanahalli, Yelahanka
    INSERT INTO public.resource_listings (
      id, owner_id, type, name, price_paise, unit, description, specs, address_text, rating_avg, rating_count, verified, location, active
    ) VALUES
      (
        '88888888-8888-4888-8888-888888888801',
        v_f3,
        'tractor',
        'Mahindra 575 DI Tractor + Rotavator',
        85000,
        'hr',
        '50 HP diesel tractor equipped with 48-blade heavy duty rotavator for dry/wet soil preparation. Experienced driver included.',
        '50 HP • Fuel Included',
        'Kisan Machinery Hub • Devanahalli Road',
        4.9,
        38,
        true,
        'POINT(77.7127 13.2483)'::extensions.geography,
        true
      ),
      (
        '88888888-8888-4888-8888-888888888802',
        v_f3,
        'harvester',
        'Multi-Crop Harvester & Thresher',
        140000,
        'hr',
        'High-capacity rubber-track paddy, ragi and grain harvester with zero grain loss technology. Suitable for wet fields.',
        'High Yield Grain Cutter',
        'AgriTech Rentals Mandya • Mandya Town',
        4.8,
        24,
        true,
        'POINT(76.8951 12.5244)'::extensions.geography,
        true
      ),
      (
        '88888888-8888-4888-8888-888888888803',
        v_f1,
        'drone',
        'Agricultural Drone Spraying Kit',
        45000,
        'acre',
        'DGCA certified agri drone for uniform pesticide, micronutrient and bio-fertilizer spraying. Covers 1 acre in 7 minutes.',
        '10L Tank • Precision GPS',
        'DroneKisan Karnataka • Yelahanka Rural',
        5.0,
        42,
        true,
        'POINT(77.5946 13.1007)'::extensions.geography,
        true
      ),
      (
        '88888888-8888-4888-8888-888888888804',
        v_f1,
        'fertilizer',
        'Bio-NPK & Vermicompost Depot',
        45000,
        'bag',
        'Certified rich organic vermicompost enriched with Trichoderma and Neem cake. 50kg moisture-sealed bags.',
        '50kg Sealed Bag • 100% Organic',
        'GreenSoil Organic Depot • Yelahanka Mandi Gate',
        4.7,
        19,
        true,
        'POINT(77.5960 13.1020)'::extensions.geography,
        true
      ),
      (
        '88888888-8888-4888-8888-888888888805',
        v_f3,
        'cold_storage',
        'Solar Cold Storage Facility',
        1500,
        'crate/day',
        'Micro-climate controlled solar cold room maintain 4-8°C with 90% humidity for tomatoes, capsicum and leafy vegetables.',
        'Temp 4-8°C • Backup Generator',
        'Karnataka Agri Cold Chain • Devanahalli',
        4.9,
        15,
        true,
        'POINT(77.7140 13.2500)'::extensions.geography,
        true
      ),
      (
        '88888888-8888-4888-8888-888888888806',
        v_f1,
        'labour_equipment',
        'Soil Quality Testing & Lab Service',
        20000,
        'sample',
        'Complete 14-parameter soil health analysis card (N, P, K, pH, EC, Organic Carbon, Micronutrients) delivered in 24 hours.',
        '14 Parameters • 24hr Digital Report',
        'Krishi Vigyan Kendra Mobile Lab • Mandya Yard',
        4.8,
        29,
        true,
        'POINT(76.8970 12.5260)'::extensions.geography,
        true
      ),
      (
        '88888888-8888-4888-8888-888888888807',
        v_f3,
        'tractor',
        'Tractor Rotavator Attachment Only',
        35000,
        'hr',
        'Shaktiman 6-foot heavy rotavator compatible with 45-60 HP 3-point hitch tractors.',
        '6 Foot Width • Multi-Speed Gearbox',
        'Mandya Rural Machinery Co-op • Sugar Town',
        4.6,
        11,
        true,
        'POINT(76.8930 12.5220)'::extensions.geography,
        true
      )
    ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      price_paise = EXCLUDED.price_paise,
      specs = EXCLUDED.specs,
      address_text = EXCLUDED.address_text,
      rating_avg = EXCLUDED.rating_avg,
      rating_count = EXCLUDED.rating_count,
      verified = EXCLUDED.verified,
      active = EXCLUDED.active;
  END IF;
END $$;
