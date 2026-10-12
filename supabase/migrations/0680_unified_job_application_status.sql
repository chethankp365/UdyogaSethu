-- ============================================================================
-- Migration: 0680_unified_job_application_status.sql
-- Description: Unified single source of truth for job application and assignment
--              statuses per worker.
--              1. Adds partial unique index on job_applications for active status.
--              2. Makes apply_to_job idempotent (returns existing application if active).
--              3. Adds withdraw_job_application RPC for worker-side withdrawal.
--              4. Updates recommended_jobs & nearby_jobs & get_job_detail to return
--                 the caller's own application and assignment status joined by auth.uid().
--              5. Adds get_my_job_application_statuses RPC for bootstrap / refresh.
-- ============================================================================

-- 1. UNIQUE RULE FOR ACTIVE JOB APPLICATIONS
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_job_application 
ON public.job_applications (job_id, worker_id) 
WHERE status != 'withdrawn';

-- 2. DROP OBSOLETE OVERLOADS TO SAFELY UPDATE RETURN TABLES
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
      AND p.proname IN ('recommended_jobs', 'nearby_jobs', 'apply_to_job', 'withdraw_job_application', 'get_my_job_application_statuses')
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
  END LOOP;
END $$;

-- 3. IDEMPOTENT apply_to_job
CREATE OR REPLACE FUNCTION public.apply_to_job(p_job_id UUID, p_message TEXT DEFAULT NULL)
RETURNS UUID AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_existing_id UUID;
  v_eligibility JSONB;
  v_app_id UUID;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;

  -- 3a. Idempotency Check: Return existing active application if found
  SELECT id INTO v_existing_id
  FROM public.job_applications
  WHERE job_id = p_job_id
    AND worker_id = v_uid
    AND status != 'withdrawn'
  LIMIT 1;

  IF v_existing_id IS NOT NULL THEN
    RETURN v_existing_id;
  END IF;

  -- 3b. Verify Eligibility
  v_eligibility := public.check_job_eligibility(p_job_id);
  IF NOT (v_eligibility->>'is_eligible')::BOOLEAN THEN
    -- If the only reason was already applied, handle gracefully
    IF v_eligibility->>'reason_code' = 'ALREADY_APPLIED' THEN
      SELECT id INTO v_existing_id
      FROM public.job_applications
      WHERE job_id = p_job_id AND worker_id = v_uid AND status != 'withdrawn'
      LIMIT 1;
      IF v_existing_id IS NOT NULL THEN
        RETURN v_existing_id;
      END IF;
    END IF;
    RAISE EXCEPTION 'Ineligible to apply: %', (v_eligibility->>'reasons');
  END IF;

  -- 3c. Insert new active application
  INSERT INTO public.job_applications (job_id, worker_id, status, message)
  VALUES (p_job_id, v_uid, 'applied'::public.application_status, TRIM(p_message))
  ON CONFLICT (job_id, worker_id) WHERE status != 'withdrawn'
  DO UPDATE SET updated_at = NOW()
  RETURNING id INTO v_app_id;

  RETURN v_app_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 4. WITHDRAW JOB APPLICATION RPC
CREATE OR REPLACE FUNCTION public.withdraw_job_application(p_job_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_rows_affected INT;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;

  UPDATE public.job_applications
  SET status = 'withdrawn'::public.application_status,
      updated_at = NOW()
  WHERE job_id = p_job_id
    AND worker_id = v_uid
    AND status NOT IN ('withdrawn', 'hired');

  GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
  RETURN v_rows_affected > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 5. recommended_jobs WITH CALLER APPLICATION STATUS
CREATE OR REPLACE FUNCTION public.recommended_jobs(
  p_worker_id UUID, p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_limit INT DEFAULT 20, p_radius_m DOUBLE PRECISION DEFAULT 50000
)
RETURNS TABLE (
  id UUID, provider_id UUID, category_id UUID, title TEXT, description TEXT,
  wage_type TEXT, wage_paise BIGINT, est_duration_minutes INT, start_at TIMESTAMPTZ,
  slots_total INT, slots_filled INT, address_text TEXT, distance_m DOUBLE PRECISION,
  employer_name TEXT, employer_avatar TEXT, employer_verified BOOLEAN, employer_rating NUMERIC,
  category_names JSONB, category_icon TEXT, category_slug TEXT, site_photo_url TEXT,
  students_ok BOOLEAN, is_student_friendly BOOLEAN, is_flexible_shift BOOLEAN, score DOUBLE PRECISION, reasons TEXT[],
  my_application_status TEXT, my_assignment_status TEXT, my_application_id UUID, my_assignment_id UUID
) AS $$
DECLARE
  v_ref_point extensions.geography(Point, 4326) := NULL;
  v_caller UUID := COALESCE(auth.uid(), p_worker_id);
BEGIN
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_ref_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  END IF;

  RETURN QUERY
  SELECT
    j.id, j.provider_id, j.category_id, j.title, j.description, j.wage_type::TEXT, j.wage_paise,
    j.est_duration_minutes, j.start_at, j.slots_total, j.slots_filled, j.address_text,
    CASE WHEN v_ref_point IS NOT NULL AND j.location IS NOT NULL THEN extensions.ST_Distance(v_ref_point, j.location) ELSE 0.0 END,
    COALESCE(pp.full_name, 'Employer')::TEXT, pp.avatar_path::TEXT,
    COALESCE(prp.is_verified_badge, false), prp.rating_avg,
    sc.names, COALESCE(sc.icon, 'work')::TEXT, COALESCE(sc.slug, 'general')::TEXT,
    j.site_photo_url, COALESCE((j.requirements->>'students_ok')::BOOLEAN, false),
    ('student' = ANY(j.suitable_for)), ('part_time' = ANY(j.suitable_for)),
    100.0::DOUBLE PRECISION, ARRAY['Open position']::TEXT[],
    COALESCE(my_app.status, 'none')::TEXT,
    my_asg.status::TEXT,
    my_app.id,
    my_asg.id
  FROM public.jobs j
  JOIN public.profiles pp ON j.provider_id = pp.id
  LEFT JOIN public.provider_profiles prp ON j.provider_id = prp.user_id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  LEFT JOIN LATERAL (
    SELECT ja.id, ja.status::TEXT
    FROM public.job_applications ja
    WHERE ja.job_id = j.id AND ja.worker_id = v_caller
    ORDER BY (ja.status != 'withdrawn') DESC, ja.created_at DESC
    LIMIT 1
  ) my_app ON true
  LEFT JOIN LATERAL (
    SELECT ja2.id, ja2.status::TEXT
    FROM public.job_assignments ja2
    WHERE ja2.job_id = j.id AND ja2.worker_id = v_caller
    ORDER BY ja2.created_at DESC
    LIMIT 1
  ) my_asg ON true
  WHERE j.status = 'open' AND j.slots_filled < j.slots_total AND j.start_at > NOW() AND j.location IS NOT NULL
    AND (v_ref_point IS NULL OR extensions.ST_DWithin(v_ref_point, j.location, p_radius_m))
  ORDER BY j.created_at DESC LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 6. nearby_jobs WITH CALLER APPLICATION STATUS
CREATE OR REPLACE FUNCTION public.nearby_jobs(
  p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_radius_m DOUBLE PRECISION DEFAULT 50000,
  p_category_id UUID DEFAULT NULL, p_search_query TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, provider_id UUID, category_id UUID, title TEXT, description TEXT,
  wage_type TEXT, wage_paise BIGINT, start_at TIMESTAMPTZ, slots_total INT, slots_filled INT,
  address_text TEXT, distance_m DOUBLE PRECISION, lat DOUBLE PRECISION, lng DOUBLE PRECISION,
  employer_name TEXT, employer_avatar TEXT, employer_verified BOOLEAN, employer_rating NUMERIC,
  category_name JSONB, category_icon TEXT, category_slug TEXT,
  my_application_status TEXT, my_assignment_status TEXT, my_application_id UUID, my_assignment_id UUID
) AS $$
DECLARE
  v_ref_point extensions.geography(Point, 4326);
  v_caller UUID := auth.uid();
BEGIN
  IF p_lat IS NULL OR p_lng IS NULL THEN RETURN; END IF;
  v_ref_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  RETURN QUERY
  SELECT
    j.id, j.provider_id, j.category_id, j.title, j.description, j.wage_type::TEXT, j.wage_paise,
    j.start_at, j.slots_total, j.slots_filled, j.address_text,
    extensions.ST_Distance(v_ref_point, j.location),
    extensions.ST_Y(j.location::extensions.geometry),
    extensions.ST_X(j.location::extensions.geometry),
    COALESCE(pp.full_name, 'Employer')::TEXT, pp.avatar_path::TEXT,
    COALESCE(prp.is_verified_badge, false), prp.rating_avg,
    sc.names, COALESCE(sc.icon, 'work')::TEXT, COALESCE(sc.slug, 'general')::TEXT,
    COALESCE(my_app.status, 'none')::TEXT,
    my_asg.status::TEXT,
    my_app.id,
    my_asg.id
  FROM public.jobs j
  JOIN public.profiles pp ON j.provider_id = pp.id
  LEFT JOIN public.provider_profiles prp ON j.provider_id = prp.user_id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  LEFT JOIN LATERAL (
    SELECT ja.id, ja.status::TEXT
    FROM public.job_applications ja
    WHERE ja.job_id = j.id AND ja.worker_id = v_caller
    ORDER BY (ja.status != 'withdrawn') DESC, ja.created_at DESC
    LIMIT 1
  ) my_app ON true
  LEFT JOIN LATERAL (
    SELECT ja2.id, ja2.status::TEXT
    FROM public.job_assignments ja2
    WHERE ja2.job_id = j.id AND ja2.worker_id = v_caller
    ORDER BY ja2.created_at DESC
    LIMIT 1
  ) my_asg ON true
  WHERE j.status = 'open' AND j.slots_filled < j.slots_total AND j.start_at > NOW() AND j.location IS NOT NULL
    AND extensions.ST_DWithin(v_ref_point, j.location, p_radius_m)
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    AND (p_search_query IS NULL OR j.title ILIKE '%' || p_search_query || '%')
  ORDER BY distance_m ASC LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 7. get_job_detail WITH CALLER APPLICATION STATUS
CREATE OR REPLACE FUNCTION public.get_job_detail(p_job_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_res JSONB;
  v_caller UUID := auth.uid();
BEGIN
  SELECT jsonb_build_object(
    'id', j.id,
    'provider_id', j.provider_id,
    'provider_name', COALESCE(p.full_name, pp.org_name, 'Verified Employer'),
    'provider_avatar', p.avatar_path,
    'provider_verified', public.is_provider_verified(j.provider_id),
    'provider_rating', COALESCE(pp.rating_avg, 4.8),
    'provider_reviews_count', COALESCE(pp.rating_count, 12),
    'background_verified', true,
    'title', j.title,
    'description', COALESCE(j.description, 'Reliable, verified work opportunity through UdyogaSethu.'),
    'category_id', j.category_id,
    'category_name', COALESCE(sc.names->>'en', sc.names->>'kn', 'General Work'),
    'category_slug', COALESCE(sc.slug, 'general'),
    'category_icon', COALESCE(sc.icon, 'handyman'),
    'wage_paise', j.wage_paise,
    'wage_type', j.wage_type,
    'est_duration_minutes', COALESCE(j.est_duration_minutes, 480),
    'start_at', j.start_at,
    'slots_total', j.slots_total,
    'slots_filled', j.slots_filled,
    'materials_provided', j.materials_provided,
    'payment_mode', j.payment_mode,
    'requirements', j.requirements,
    'address_text', j.address_text,
    'status', j.status,
    'suitable_for', to_jsonb(j.suitable_for),
    'is_demo', j.is_demo,
    'my_application_status', COALESCE(my_app.status, 'none'),
    'my_assignment_status', my_asg.status,
    'my_application_id', my_app.id,
    'my_assignment_id', my_asg.id
  )
  INTO v_res
  FROM public.jobs j
  LEFT JOIN public.profiles p ON p.id = j.provider_id
  LEFT JOIN public.provider_profiles pp ON pp.user_id = j.provider_id
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  LEFT JOIN LATERAL (
    SELECT ja.id, ja.status::TEXT
    FROM public.job_applications ja
    WHERE ja.job_id = j.id AND ja.worker_id = v_caller
    ORDER BY (ja.status != 'withdrawn') DESC, ja.created_at DESC
    LIMIT 1
  ) my_app ON true
  LEFT JOIN LATERAL (
    SELECT ja2.id, ja2.status::TEXT
    FROM public.job_assignments ja2
    WHERE ja2.job_id = j.id AND ja2.worker_id = v_caller
    ORDER BY ja2.created_at DESC
    LIMIT 1
  ) my_asg ON true
  WHERE j.id = p_job_id;

  RETURN v_res;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 8. BATCH QUERY: get_my_job_application_statuses
CREATE OR REPLACE FUNCTION public.get_my_job_application_statuses()
RETURNS TABLE (
  job_id UUID,
  application_id UUID,
  application_status TEXT,
  assignment_id UUID,
  assignment_status TEXT,
  applied_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RETURN; END IF;

  RETURN QUERY
  WITH user_apps AS (
    SELECT DISTINCT ON (ja.job_id)
      ja.job_id, ja.id AS app_id, ja.status::TEXT AS app_status, ja.created_at, ja.updated_at
    FROM public.job_applications ja
    WHERE ja.worker_id = v_uid
    ORDER BY ja.job_id, (ja.status != 'withdrawn') DESC, ja.created_at DESC
  ),
  user_asgs AS (
    SELECT DISTINCT ON (asg.job_id)
      asg.job_id, asg.id AS asg_id, asg.status::TEXT AS asg_status, asg.created_at, asg.updated_at
    FROM public.job_assignments asg
    WHERE asg.worker_id = v_uid
    ORDER BY asg.job_id, asg.created_at DESC
  ),
  all_job_ids AS (
    SELECT ua.job_id FROM user_apps ua
    UNION
    SELECT uasg.job_id FROM user_asgs uasg
  )
  SELECT
    j_id.job_id,
    ua.app_id AS application_id,
    COALESCE(ua.app_status, 'none') AS application_status,
    uasg.asg_id AS assignment_id,
    uasg.asg_status AS assignment_status,
    ua.created_at AS applied_at,
    COALESCE(uasg.updated_at, ua.updated_at, NOW()) AS updated_at
  FROM all_job_ids j_id
  LEFT JOIN user_apps ua ON ua.job_id = j_id.job_id
  LEFT JOIN user_asgs uasg ON uasg.job_id = j_id.job_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 9. PERMISSIONS & SCHEMA RELOAD
GRANT EXECUTE ON FUNCTION public.apply_to_job(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.withdraw_job_application(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.recommended_jobs(UUID, DOUBLE PRECISION, DOUBLE PRECISION, INT, DOUBLE PRECISION) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.nearby_jobs(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, UUID, TEXT, INT, INT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_job_detail(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_my_job_application_statuses() TO authenticated;

NOTIFY pgrst, 'reload schema';
