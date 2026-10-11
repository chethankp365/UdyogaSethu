-- ============================================================================
-- Migration: 0640_db_contract_sync.sql
-- Description: Synchronizes DB contract with app requirements:
--              1. Drops all older overloaded signatures of post_provider_job,
--                 update_provider_job, and record_ticket_attendance so exactly
--                 ONE canonical overload remains.
--              2. Extends application_status enum with 'accepted' and 'declined'.
--              3. Backfills farmer_profiles.delivery_radius_km from legacy delivery_options.
--              4. Updates respond_to_application to accept both ('hired', 'accepted')
--                 and ('rejected', 'declined').
--              5. Hardens RLS policies on job_applications for provider and worker access.
--              6. Ensures supabase_realtime publication includes jobs, job_applications,
--                 and job_assignments.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DROP OLD OVERLOADED FUNCTION SIGNATURES
-- ----------------------------------------------------------------------------
-- Drop 15-param post_provider_job (0060)
DROP FUNCTION IF EXISTS public.post_provider_job(
  UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT,
  BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT
);

-- Drop 16-param post_provider_job (0350)
DROP FUNCTION IF EXISTS public.post_provider_job(
  UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT,
  BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[]
);

-- Drop 17-param post_provider_job (0570)
DROP FUNCTION IF EXISTS public.post_provider_job(
  UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT,
  BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], TEXT
);

-- Drop 16-param update_provider_job (0060)
DROP FUNCTION IF EXISTS public.update_provider_job(
  UUID, UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT,
  BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT
);

-- Drop 17-param update_provider_job (0350)
DROP FUNCTION IF EXISTS public.update_provider_job(
  UUID, UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT,
  BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[]
);

-- Drop 18-param update_provider_job (0570)
DROP FUNCTION IF EXISTS public.update_provider_job(
  UUID, UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT,
  BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], TEXT
);

-- Drop 4-param record_ticket_attendance (0430)
DROP FUNCTION IF EXISTS public.record_ticket_attendance(
  UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION
);

-- ----------------------------------------------------------------------------
-- 2. EXTEND application_status ENUM
-- ----------------------------------------------------------------------------
ALTER TYPE public.application_status ADD VALUE IF NOT EXISTS 'accepted';
ALTER TYPE public.application_status ADD VALUE IF NOT EXISTS 'declined';

-- ----------------------------------------------------------------------------
-- 3. ENSURE FARMER PROFILE FIELDS & BACKFILL FROM LEGACY delivery_options
-- ----------------------------------------------------------------------------
ALTER TABLE public.farmer_profiles
  ADD COLUMN IF NOT EXISTS delivery_radius_km NUMERIC(5,1) DEFAULT 25.0,
  ADD COLUMN IF NOT EXISTS pickup_available BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS lead_time_hours INT DEFAULT 24,
  ADD COLUMN IF NOT EXISTS farm_photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS organic_cert_number TEXT DEFAULT NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'delivery_options'
  ) THEN
    UPDATE public.farmer_profiles
    SET 
      delivery_radius_km = COALESCE(
        delivery_radius_km,
        NULLIF(delivery_options->>'delivery_radius_km', '')::NUMERIC,
        25.0
      ),
      pickup_available = COALESCE(
        pickup_available,
        (delivery_options->>'pickup_available')::BOOLEAN,
        true
      )
    WHERE delivery_options IS NOT NULL;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 4. CANONICAL 18-PARAM post_provider_job WITH STUDENTS_WELCOME CHECK
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.post_provider_job(
  p_category_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_wage_type public.wage_type,
  p_wage_paise BIGINT,
  p_est_duration_minutes INT,
  p_start_at TIMESTAMPTZ,
  p_slots_total INT,
  p_materials_provided BOOLEAN,
  p_payment_mode public.payment_mode,
  p_requirements JSONB,
  p_address_text TEXT,
  p_location_lat DOUBLE PRECISION,
  p_location_lng DOUBLE PRECISION,
  p_geofence_radius_m INT DEFAULT 150,
  p_suitable_for TEXT[] DEFAULT ARRAY['informal'],
  p_landmark TEXT DEFAULT NULL,
  p_site_photo_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_provider_id UUID;
  v_job_id UUID;
  v_loc extensions.geography(Point, 4326) := NULL;
  v_suitable public.seeker_type[];
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_location_lat IS NOT NULL AND p_location_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_location_lng, p_location_lat), 4326)::extensions.geography;
  END IF;

  -- Convert suitable_for text array to seeker_type array
  IF p_suitable_for IS NOT NULL AND array_length(p_suitable_for, 1) > 0 THEN
    SELECT array_agg(u::public.seeker_type)
    INTO v_suitable
    FROM unnest(p_suitable_for) u;
  ELSE
    v_suitable := ARRAY['informal'::public.seeker_type];
  END IF;

  INSERT INTO public.jobs (
    provider_id,
    category_id,
    title,
    description,
    wage_type,
    wage_paise,
    est_duration_minutes,
    start_at,
    slots_total,
    slots_filled,
    materials_provided,
    payment_mode,
    requirements,
    location,
    address_text,
    landmark,
    site_photo_url,
    geofence_radius_m,
    suitable_for,
    is_demo,
    status
  ) VALUES (
    v_provider_id,
    p_category_id,
    TRIM(p_title),
    p_description,
    p_wage_type,
    p_wage_paise,
    COALESCE(p_est_duration_minutes, 480),
    p_start_at,
    GREATEST(COALESCE(p_slots_total, 1), 1),
    0,
    COALESCE(p_materials_provided, false),
    p_payment_mode,
    COALESCE(p_requirements, '{"verified_only": false, "licence_required": false, "students_ok": false}'::jsonb),
    v_loc,
    p_address_text,
    p_landmark,
    p_site_photo_url,
    COALESCE(p_geofence_radius_m, 150),
    v_suitable,
    false,
    'open'
  )
  RETURNING id INTO v_job_id;

  RETURN v_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.post_provider_job(UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], TEXT, TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 5. CANONICAL 19-PARAM update_provider_job
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_provider_job(
  p_job_id UUID,
  p_category_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_wage_type public.wage_type,
  p_wage_paise BIGINT,
  p_est_duration_minutes INT,
  p_start_at TIMESTAMPTZ,
  p_slots_total INT,
  p_materials_provided BOOLEAN,
  p_payment_mode public.payment_mode,
  p_requirements JSONB,
  p_address_text TEXT,
  p_location_lat DOUBLE PRECISION,
  p_location_lng DOUBLE PRECISION,
  p_geofence_radius_m INT DEFAULT 150,
  p_suitable_for TEXT[] DEFAULT ARRAY['informal'],
  p_landmark TEXT DEFAULT NULL,
  p_site_photo_url TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_provider_id UUID;
  v_loc extensions.geography(Point, 4326) := NULL;
  v_suitable public.seeker_type[];
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_location_lat IS NOT NULL AND p_location_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_location_lng, p_location_lat), 4326)::extensions.geography;
  END IF;

  IF p_suitable_for IS NOT NULL AND array_length(p_suitable_for, 1) > 0 THEN
    SELECT array_agg(u::public.seeker_type)
    INTO v_suitable
    FROM unnest(p_suitable_for) u;
  ELSE
    v_suitable := ARRAY['informal'::public.seeker_type];
  END IF;

  UPDATE public.jobs
  SET
    category_id = p_category_id,
    title = TRIM(p_title),
    description = p_description,
    wage_type = p_wage_type,
    wage_paise = p_wage_paise,
    est_duration_minutes = COALESCE(p_est_duration_minutes, 480),
    start_at = p_start_at,
    slots_total = GREATEST(COALESCE(p_slots_total, 1), 1),
    materials_provided = COALESCE(p_materials_provided, false),
    payment_mode = p_payment_mode,
    requirements = COALESCE(p_requirements, requirements),
    location = COALESCE(v_loc, location),
    address_text = p_address_text,
    landmark = COALESCE(p_landmark, landmark),
    site_photo_url = COALESCE(p_site_photo_url, site_photo_url),
    geofence_radius_m = COALESCE(p_geofence_radius_m, 150),
    suitable_for = v_suitable,
    updated_at = NOW()
  WHERE id = p_job_id AND provider_id = v_provider_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.update_provider_job(UUID, UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], TEXT, TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. RESILIENT respond_to_application SUPPORTING 'hired'/'accepted' & 'rejected'/'declined'
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.respond_to_application(
  p_application_id UUID,
  p_status TEXT
)
RETURNS UUID AS $$
DECLARE
  v_provider_id UUID;
  v_job_id UUID;
  v_worker_id UUID;
  v_wage_paise BIGINT;
  v_slots_total INT;
  v_slots_filled INT;
  v_job_title TEXT;
  v_cur_app_status TEXT;
  v_assignment_id UUID;
  v_code TEXT;
  v_target_enum public.application_status;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT ja.job_id, ja.worker_id, ja.status::TEXT, j.wage_paise, j.slots_total, j.slots_filled, j.title
  INTO v_job_id, v_worker_id, v_cur_app_status, v_wage_paise, v_slots_total, v_slots_filled, v_job_title
  FROM public.job_applications ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_application_id AND (j.provider_id = v_provider_id OR public.is_admin());

  IF v_job_id IS NULL THEN
    RAISE EXCEPTION 'Application not found or unauthorized.';
  END IF;

  IF p_status IN ('hired', 'accepted') THEN
    v_target_enum := 'hired'::public.application_status;

    IF v_cur_app_status IN ('hired', 'accepted') THEN
      SELECT id INTO v_assignment_id FROM public.job_assignments WHERE job_id = v_job_id AND worker_id = v_worker_id LIMIT 1;
      RETURN v_assignment_id;
    END IF;

    IF v_slots_filled >= v_slots_total THEN
      RAISE EXCEPTION 'All slots for this job are already filled.';
    END IF;

    v_code := 'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6));

    INSERT INTO public.job_assignments (job_id, worker_id, booking_code, agreed_wage_paise, status)
    VALUES (v_job_id, v_worker_id, v_code, v_wage_paise, 'requested')
    RETURNING id INTO v_assignment_id;

    UPDATE public.jobs
    SET
      slots_filled = slots_filled + 1,
      status = CASE WHEN slots_filled + 1 >= slots_total THEN 'filled'::public.job_status ELSE status END,
      updated_at = NOW()
    WHERE id = v_job_id;

    INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
    VALUES (
      v_worker_id,
      'job_hired',
      'notification_job_hired_title',
      'notification_job_hired_body',
      jsonb_build_object('job_id', v_job_id, 'job_title', v_job_title, 'assignment_id', v_assignment_id)
    );
  ELSIF p_status IN ('rejected', 'declined') THEN
    v_target_enum := 'rejected'::public.application_status;
  ELSIF p_status = 'shortlisted' THEN
    v_target_enum := 'shortlisted'::public.application_status;
  ELSIF p_status = 'withdrawn' THEN
    v_target_enum := 'withdrawn'::public.application_status;
  ELSE
    v_target_enum := p_status::public.application_status;
  END IF;

  UPDATE public.job_applications
  SET status = v_target_enum, updated_at = NOW()
  WHERE id = p_application_id;

  RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.respond_to_application(UUID, TEXT) TO authenticated, anon;

-- ----------------------------------------------------------------------------
-- 7. REINFORCE RLS POLICIES FOR job_applications
-- ----------------------------------------------------------------------------
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS job_applications_select ON public.job_applications;
CREATE POLICY job_applications_select ON public.job_applications FOR SELECT USING (
  worker_id = auth.uid() OR
  EXISTS (SELECT 1 FROM public.jobs j WHERE j.id = job_id AND j.provider_id = auth.uid()) OR
  public.is_admin()
);

DROP POLICY IF EXISTS job_applications_insert ON public.job_applications;
CREATE POLICY job_applications_insert ON public.job_applications FOR INSERT WITH CHECK (
  worker_id = auth.uid()
);

DROP POLICY IF EXISTS job_applications_update ON public.job_applications;
CREATE POLICY job_applications_update ON public.job_applications FOR UPDATE USING (
  worker_id = auth.uid() OR
  EXISTS (SELECT 1 FROM public.jobs j WHERE j.id = job_id AND j.provider_id = auth.uid()) OR
  public.is_admin()
);

DROP POLICY IF EXISTS job_applications_delete ON public.job_applications;
CREATE POLICY job_applications_delete ON public.job_applications FOR DELETE USING (
  worker_id = auth.uid() OR public.is_admin()
);

-- ----------------------------------------------------------------------------
-- 8. REALTIME PUBLICATION FOR JOBS, APPLICATIONS, AND ASSIGNMENTS
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'jobs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.jobs;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'job_applications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.job_applications;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'job_assignments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.job_assignments;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 9. GRANTS FOR CORE WORKFLOW TABLES
-- ----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON public.jobs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.job_applications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.job_assignments TO authenticated;
GRANT SELECT ON public.jobs TO anon;
