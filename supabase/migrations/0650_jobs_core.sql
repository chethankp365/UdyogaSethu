-- ============================================================================
-- Migration: 0650_jobs_core.sql
-- Description: Core job management RPCs strictly matching live schema inventory.
--              Enforces single canonical overload, real columns only, PostGIS
--              via extensions schema, stable reason codes, and RLS security.
-- ============================================================================

-- 1. DROP ALL EXISTING OVERLOADS BY NAME
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
      AND p.proname IN ('apply_to_job', 'check_job_eligibility', 'get_job_applicants', 'respond_to_application', 'recommended_jobs', 'nearby_jobs')
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
  END LOOP;
END $$;

-- 2. check_job_eligibility (ONE version, stable reason codes, real columns)
CREATE OR REPLACE FUNCTION public.check_job_eligibility(p_job_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_job RECORD; v_wp RECORD;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_code TEXT := 'ELIGIBLE';
  v_overlap_title TEXT := NULL;
  v_licence_needed BOOLEAN := false; v_has_licence BOOLEAN := false;
  v_verified_needed BOOLEAN := false; v_is_verified BOOLEAN := false;
  v_student_gated BOOLEAN := false; v_already_applied BOOLEAN := false;
  v_is_own_job BOOLEAN := false; v_is_past_start BOOLEAN := false;
  v_is_slots_filled BOOLEAN := false; v_schedule_overlap BOOLEAN := false;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('is_eligible', false, 'reason_code', 'NOT_AUTHENTICATED', 'reasons', ARRAY['Sign in required.']);
  END IF;

  SELECT j.*, sc.requires_licence, sc.audience INTO v_job
  FROM public.jobs j LEFT JOIN public.service_categories sc ON sc.id = j.category_id WHERE j.id = p_job_id;

  IF v_job.id IS NULL THEN
    RETURN jsonb_build_object('is_eligible', false, 'reason_code', 'JOB_NOT_FOUND', 'reasons', ARRAY['Job not found.']);
  END IF;

  SELECT seeker_type, has_driving_licence, is_verified_badge INTO v_wp FROM public.worker_profiles WHERE user_id = v_uid;
  v_has_licence := COALESCE(v_wp.has_driving_licence, false);
  v_is_verified := COALESCE(v_wp.is_verified_badge, false);
  v_licence_needed := COALESCE(v_job.requires_licence, false) OR COALESCE((v_job.requirements->>'licence_required')::BOOLEAN, false);
  v_verified_needed := COALESCE((v_job.requirements->>'verified_only')::BOOLEAN, false);

  IF v_job.provider_id = v_uid THEN
    v_is_own_job := true; v_code := 'OWN_JOB'; v_reasons := array_append(v_reasons, 'Cannot apply to own job.');
  END IF;
  IF v_job.start_at <= NOW() THEN
    v_is_past_start := true; v_code := 'EXPIRED'; v_reasons := array_append(v_reasons, 'Job start time has passed.');
  END IF;
  IF v_job.status != 'open' OR v_job.slots_filled >= v_job.slots_total THEN
    v_is_slots_filled := true; v_code := 'SLOTS_FILLED'; v_reasons := array_append(v_reasons, 'All job slots are filled.');
  END IF;

  SELECT EXISTS(SELECT 1 FROM public.job_applications WHERE job_id = p_job_id AND worker_id = v_uid AND status != 'withdrawn') INTO v_already_applied;
  IF v_already_applied THEN
    v_code := 'ALREADY_APPLIED'; v_reasons := array_append(v_reasons, 'Already applied to this job.');
  END IF;
  IF v_licence_needed AND NOT v_has_licence THEN
    v_code := 'LICENCE_REQUIRED'; v_reasons := array_append(v_reasons, 'Driving licence is required.');
  END IF;
  IF v_verified_needed AND NOT v_is_verified THEN
    v_code := 'VERIFICATION_REQUIRED'; v_reasons := array_append(v_reasons, 'Verified profile required.');
  END IF;

  -- Students welcome & audience rules
  IF v_wp.seeker_type = 'student' THEN
    IF NOT (COALESCE((v_job.requirements->>'students_ok')::BOOLEAN, false) OR 'student' = ANY(v_job.suitable_for)) THEN
      v_student_gated := true; v_code := 'STUDENT_GATED'; v_reasons := array_append(v_reasons, 'Job is not designated for students.');
    END IF;
  END IF;

  -- Schedule overlap check
  SELECT j2.title INTO v_overlap_title FROM public.job_assignments ja JOIN public.jobs j2 ON ja.job_id = j2.id
  WHERE ja.worker_id = v_uid AND ja.status NOT IN ('cancelled', 'completed', 'payment_released')
    AND ja.started_at IS NOT NULL AND ja.ended_at IS NULL
    AND j2.start_at < (v_job.start_at + (v_job.est_duration_minutes || ' minutes')::INTERVAL)
    AND (j2.start_at + (j2.est_duration_minutes || ' minutes')::INTERVAL) > v_job.start_at LIMIT 1;

  IF v_overlap_title IS NOT NULL THEN
    v_schedule_overlap := true; v_code := 'SCHEDULE_CLASH'; v_reasons := array_append(v_reasons, 'Schedule overlaps with job: ' || v_overlap_title);
  END IF;

  RETURN jsonb_build_object(
    'is_eligible', (array_length(v_reasons, 1) IS NULL), 'reason_code', v_code,
    'licence_needed', v_licence_needed, 'has_licence', v_has_licence,
    'verified_needed', v_verified_needed, 'is_verified', v_is_verified,
    'student_gated', v_student_gated, 'schedule_overlap', v_schedule_overlap,
    'overlap_job_title', v_overlap_title, 'already_applied', v_already_applied,
    'is_own_job', v_is_own_job, 'is_past_start', v_is_past_start,
    'is_slots_filled', v_is_slots_filled, 'reasons', v_reasons
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 3. apply_to_job (ONE version, verifies eligibility before insert)
CREATE OR REPLACE FUNCTION public.apply_to_job(p_job_id UUID, p_message TEXT DEFAULT NULL)
RETURNS UUID AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_eligibility JSONB; v_app_id UUID;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;
  v_eligibility := public.check_job_eligibility(p_job_id);
  IF NOT (v_eligibility->>'is_eligible')::BOOLEAN THEN
    RAISE EXCEPTION 'Ineligible to apply: %', (v_eligibility->>'reasons');
  END IF;

  INSERT INTO public.job_applications (job_id, worker_id, status, message)
  VALUES (p_job_id, v_uid, 'applied', TRIM(p_message)) RETURNING id INTO v_app_id;
  RETURN v_app_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 4. get_job_applicants (ONE version, real columns, provider only, real ratings)
CREATE OR REPLACE FUNCTION public.get_job_applicants(p_job_id UUID)
RETURNS TABLE (
  application_id UUID, job_id UUID, worker_id UUID, status TEXT, message TEXT, created_at TIMESTAMPTZ,
  worker_name TEXT, worker_avatar TEXT, seeker_type TEXT, badge_name TEXT, level_number INT,
  is_verified BOOLEAN, rating NUMERIC, review_count INT, jobs_completed_count INT, distance_m DOUBLE PRECISION,
  languages TEXT[], skills TEXT[]
) AS $$
DECLARE
  v_provider_id UUID := auth.uid();
  v_job_loc extensions.geography(Point, 4326);
BEGIN
  SELECT location INTO v_job_loc FROM public.jobs WHERE id = p_job_id AND (provider_id = v_provider_id OR public.is_admin());
  IF NOT FOUND THEN RAISE EXCEPTION 'Job not found or unauthorized.'; END IF;

  RETURN QUERY
  SELECT
    ja.id AS application_id, ja.job_id, ja.worker_id, ja.status::TEXT, ja.message, ja.created_at,
    COALESCE(p.full_name, 'Worker')::TEXT, p.avatar_path::TEXT,
    COALESCE(wp.seeker_type::TEXT, 'informal')::TEXT,
    CASE WHEN COALESCE(wp.is_verified_badge, false) THEN 'Verified Worker' ELSE 'Registered Worker' END::TEXT,
    1::INT, COALESCE(wp.is_verified_badge, false),
    wp.rating_avg, COALESCE(wp.rating_count, 0)::INT, COALESCE(wp.jobs_completed, 0)::INT,
    CASE WHEN v_job_loc IS NOT NULL AND p.home_location IS NOT NULL THEN extensions.ST_Distance(v_job_loc, p.home_location) ELSE NULL END,
    COALESCE(wp.languages, ARRAY['kn']::TEXT[]),
    ARRAY(SELECT sk.names->>'en' FROM public.worker_skills ws JOIN public.skills sk ON ws.skill_id = sk.id WHERE ws.user_id = ja.worker_id)::TEXT[]
  FROM public.job_applications ja
  JOIN public.profiles p ON ja.worker_id = p.id
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  WHERE ja.job_id = p_job_id ORDER BY ja.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 5. respond_to_application (ONE version, resilient status handling)
CREATE OR REPLACE FUNCTION public.respond_to_application(p_application_id UUID, p_status TEXT)
RETURNS UUID AS $$
DECLARE
  v_provider_id UUID := auth.uid();
  v_job_id UUID; v_worker_id UUID; v_wage_paise BIGINT;
  v_slots_total INT; v_slots_filled INT; v_cur_status TEXT; v_assignment_id UUID;
  v_target_enum public.application_status;
BEGIN
  IF v_provider_id IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;

  SELECT ja.job_id, ja.worker_id, ja.status::TEXT, j.wage_paise, j.slots_total, j.slots_filled
  INTO v_job_id, v_worker_id, v_cur_status, v_wage_paise, v_slots_total, v_slots_filled
  FROM public.job_applications ja JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_application_id AND (j.provider_id = v_provider_id OR public.is_admin());

  IF v_job_id IS NULL THEN RAISE EXCEPTION 'Application not found or unauthorized.'; END IF;

  IF p_status IN ('hired', 'accepted') THEN
    v_target_enum := 'hired'::public.application_status;
    IF v_cur_status = 'hired' THEN
      SELECT id INTO v_assignment_id FROM public.job_assignments WHERE job_id = v_job_id AND worker_id = v_worker_id LIMIT 1;
      RETURN v_assignment_id;
    END IF;
    IF v_slots_filled >= v_slots_total THEN RAISE EXCEPTION 'All slots are already filled.'; END IF;

    INSERT INTO public.job_assignments (job_id, worker_id, booking_code, agreed_wage_paise, status)
    VALUES (v_job_id, v_worker_id, 'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6)), v_wage_paise, 'requested')
    RETURNING id INTO v_assignment_id;

    UPDATE public.jobs SET slots_filled = slots_filled + 1,
      status = CASE WHEN slots_filled + 1 >= slots_total THEN 'filled'::public.job_status ELSE status END,
      updated_at = NOW() WHERE id = v_job_id;
  ELSIF p_status IN ('rejected', 'declined') THEN v_target_enum := 'rejected'::public.application_status;
  ELSIF p_status = 'shortlisted' THEN v_target_enum := 'shortlisted'::public.application_status;
  ELSE v_target_enum := p_status::public.application_status;
  END IF;

  UPDATE public.job_applications SET status = v_target_enum, updated_at = NOW() WHERE id = p_application_id;
  RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 6. recommended_jobs (ONE version, hides expired/filled/no-coord, real columns)
CREATE OR REPLACE FUNCTION public.recommended_jobs(
  p_worker_id UUID, p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_limit INT DEFAULT 20, p_radius_m DOUBLE PRECISION DEFAULT 50000
)
RETURNS TABLE (
  id UUID, provider_id UUID, category_id UUID, title TEXT, description TEXT,
  wage_type TEXT, wage_paise BIGINT, est_duration_minutes INT, start_at TIMESTAMPTZ,
  slots_total INT, slots_filled INT, address_text TEXT, distance_m DOUBLE PRECISION,
  employer_name TEXT, employer_avatar TEXT, employer_verified BOOLEAN, employer_rating NUMERIC,
  category_names JSONB, category_icon TEXT, category_slug TEXT, site_photo_url TEXT,
  students_ok BOOLEAN, is_student_friendly BOOLEAN, is_flexible_shift BOOLEAN, score DOUBLE PRECISION, reasons TEXT[]
) AS $$
DECLARE
  v_ref_point extensions.geography(Point, 4326) := NULL;
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
    100.0::DOUBLE PRECISION, ARRAY['Open position']::TEXT[]
  FROM public.jobs j
  JOIN public.profiles pp ON j.provider_id = pp.id
  LEFT JOIN public.provider_profiles prp ON j.provider_id = prp.user_id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  WHERE j.status = 'open' AND j.slots_filled < j.slots_total AND j.start_at > NOW() AND j.location IS NOT NULL
    AND (v_ref_point IS NULL OR extensions.ST_DWithin(v_ref_point, j.location, p_radius_m))
  ORDER BY j.created_at DESC LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 7. nearby_jobs (ONE version, hides expired/filled/no-coord, real columns)
CREATE OR REPLACE FUNCTION public.nearby_jobs(
  p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_radius_m DOUBLE PRECISION DEFAULT 50000,
  p_category_id UUID DEFAULT NULL, p_search_query TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, provider_id UUID, category_id UUID, title TEXT, description TEXT,
  wage_type TEXT, wage_paise BIGINT, start_at TIMESTAMPTZ, slots_total INT, slots_filled INT,
  address_text TEXT, distance_m DOUBLE PRECISION, lat DOUBLE PRECISION, lng DOUBLE PRECISION,
  employer_name TEXT, employer_avatar TEXT, employer_verified BOOLEAN, employer_rating NUMERIC,
  category_name JSONB, category_icon TEXT, category_slug TEXT
) AS $$
DECLARE
  v_ref_point extensions.geography(Point, 4326);
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
    sc.names, COALESCE(sc.icon, 'work')::TEXT, COALESCE(sc.slug, 'general')::TEXT
  FROM public.jobs j
  JOIN public.profiles pp ON j.provider_id = pp.id
  LEFT JOIN public.provider_profiles prp ON j.provider_id = prp.user_id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  WHERE j.status = 'open' AND j.slots_filled < j.slots_total AND j.start_at > NOW() AND j.location IS NOT NULL
    AND extensions.ST_DWithin(v_ref_point, j.location, p_radius_m)
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    AND (p_search_query IS NULL OR j.title ILIKE '%' || p_search_query || '%')
  ORDER BY distance_m ASC LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 8. PERMISSIONS & GRANTS
REVOKE EXECUTE ON FUNCTION public.apply_to_job(UUID, TEXT) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.apply_to_job(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_job_eligibility(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_job_applicants(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.respond_to_application(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.recommended_jobs(UUID, DOUBLE PRECISION, DOUBLE PRECISION, INT, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nearby_jobs(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, UUID, TEXT, INT, INT) TO authenticated, anon;

-- Verification query
SELECT proname, pg_get_function_identity_arguments(oid) AS args
FROM pg_proc WHERE pronamespace = 'public'::regnamespace
  AND proname IN ('apply_to_job', 'check_job_eligibility', 'get_job_applicants', 'respond_to_application', 'recommended_jobs', 'nearby_jobs');

NOTIFY pgrst, 'reload schema';
