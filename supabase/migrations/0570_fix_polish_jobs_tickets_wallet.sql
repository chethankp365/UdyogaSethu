-- ============================================================================
-- Migration: 0570_fix_polish_jobs_tickets_wallet.sql
-- Description: Core server-side fixes for real jobs flow, applicants management,
--              accurate eligibility evaluation with stable reason codes,
--              and hiding expired/filled/unlocated jobs.
--
-- Dependencies:
--   Tables:
--     - public.jobs (columns: id, provider_id, category_id, title, description,
--                    wage_type, wage_paise, start_at, slots_total, slots_filled,
--                    address_text, landmark, location, suitable_for, requirements,
--                    is_demo, status)
--     - public.job_applications (columns: id, job_id, worker_id, status, message, created_at)
--     - public.job_assignments (columns: id, job_id, worker_id, provider_id, status, start_at, est_duration_minutes)
--     - public.profiles (columns: id, full_name, avatar_path, language, is_verified, rating, review_count)
--     - public.worker_profiles (columns: user_id, seeker_type, location, daily_rate_paise, hourly_rate_paise,
--                               rating_avg, working_days, has_driving_licence, is_verified_badge, languages)
--     - public.provider_profiles (columns: user_id, org_name, rating_avg)
--     - public.service_categories (columns: id, slug, names, icon, audience)
--     - public.skills, public.worker_skills
--     - public.kyc_records
--     - public.user_gamification (columns: user_id, level, current_xp)
--   Functions:
--     - public.is_admin()
--     - public.is_provider_verified(UUID)
--   Policies:
--     - public.job_applications RLS
--     - public.jobs RLS
-- ============================================================================

-- 1. Ensure landmark column exists on public.jobs
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS landmark TEXT;

-- ============================================================================
-- 2. Enhanced check_job_eligibility RPC
-- Returns structured JSON with comprehensive flags, booleans, and stable reason_code
-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_job_eligibility(
  p_job_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_worker_id UUID;
  v_seeker_type TEXT := 'informal';
  v_has_dl BOOLEAN := false;
  v_is_verified BOOLEAN := false;
  v_job RECORD;
  v_licence_needed BOOLEAN := false;
  v_verified_needed BOOLEAN := false;
  v_student_gated BOOLEAN := false;
  v_schedule_overlap BOOLEAN := false;
  v_overlap_job_title TEXT := NULL;
  v_already_applied BOOLEAN := false;
  v_is_own_job BOOLEAN := false;
  v_is_past_start BOOLEAN := false;
  v_is_slots_filled BOOLEAN := false;
  v_is_eligible BOOLEAN := true;
  v_reason_code TEXT := NULL;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_job_end TIMESTAMPTZ;
  v_effective_audience TEXT[];
BEGIN
  v_worker_id := auth.uid();
  IF v_worker_id IS NULL THEN
    RETURN jsonb_build_object(
      'is_eligible', false,
      'reason_code', 'AUTH_REQUIRED',
      'reasons', ARRAY['Authentication required to apply for jobs.']::TEXT[],
      'licence_needed', false,
      'has_licence', false,
      'verified_needed', false,
      'is_verified', false,
      'student_gated', false,
      'schedule_overlap', false,
      'overlap_job_title', NULL,
      'already_applied', false,
      'is_own_job', false,
      'is_past_start', false,
      'is_slots_filled', false
    );
  END IF;

  -- A. Fetch worker profile details
  SELECT COALESCE(wp.seeker_type::text, 'informal'),
         COALESCE(wp.has_driving_licence, false),
         COALESCE(p.is_verified, wp.is_verified_badge, false)
  INTO v_seeker_type, v_has_dl, v_is_verified
  FROM public.profiles p
  LEFT JOIN public.worker_profiles wp ON wp.user_id = p.id
  WHERE p.id = v_worker_id;

  -- Check driving licence in kyc_records
  IF NOT v_has_dl THEN
    SELECT EXISTS (
      SELECT 1 FROM public.kyc_records
      WHERE user_id = v_worker_id
        AND doc_type = 'driving_licence'
        AND status = 'verified'
    ) INTO v_has_dl;
  END IF;

  -- B. Fetch job details
  SELECT j.*, sc.names AS category_names, sc.slug AS category_slug, sc.audience AS category_audience
  INTO v_job
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  IF v_job.id IS NULL THEN
    RETURN jsonb_build_object(
      'is_eligible', false,
      'reason_code', 'JOB_NOT_FOUND',
      'reasons', ARRAY['Job not found.']::TEXT[],
      'licence_needed', false,
      'has_licence', v_has_dl,
      'verified_needed', false,
      'is_verified', v_is_verified,
      'student_gated', false,
      'schedule_overlap', false,
      'overlap_job_title', NULL,
      'already_applied', false,
      'is_own_job', false,
      'is_past_start', false,
      'is_slots_filled', false
    );
  END IF;

  -- C. Own job check
  IF v_job.provider_id = v_worker_id THEN
    v_is_own_job := true;
    v_is_eligible := false;
    v_reason_code := 'OWN_JOB';
    v_reasons := array_append(v_reasons, 'You cannot apply to a job you posted.');
  END IF;

  -- D. Expired start time check
  IF v_job.start_at <= NOW() THEN
    v_is_past_start := true;
    v_is_eligible := false;
    IF v_reason_code IS NULL THEN v_reason_code := 'EXPIRED'; END IF;
    v_reasons := array_append(v_reasons, 'This job start time has already passed.');
  END IF;

  -- E. Filled slots check
  IF v_job.status <> 'open' OR v_job.slots_filled >= v_job.slots_total THEN
    v_is_slots_filled := true;
    v_is_eligible := false;
    IF v_reason_code IS NULL THEN v_reason_code := 'SLOTS_FILLED'; END IF;
    v_reasons := array_append(v_reasons, 'All positions for this job are filled.');
  END IF;

  -- F. Already applied check
  SELECT EXISTS (
    SELECT 1 FROM public.job_applications
    WHERE job_id = p_job_id AND worker_id = v_worker_id
  ) INTO v_already_applied;

  IF v_already_applied THEN
    IF v_reason_code IS NULL THEN v_reason_code := 'ALREADY_APPLIED'; END IF;
    v_reasons := array_append(v_reasons, 'You have already applied for this job.');
  END IF;

  -- G. Driving licence check
  IF (v_job.requirements->>'licence_required')::BOOLEAN = true OR
     v_job.category_slug IN ('driver', 'delivery', 'delivery-gig-work') THEN
    v_licence_needed := true;
    IF NOT v_has_dl THEN
      v_is_eligible := false;
      IF v_reason_code IS NULL THEN v_reason_code := 'LICENCE_REQUIRED'; END IF;
      v_reasons := array_append(v_reasons, 'Valid driving licence required for this job.');
    END IF;
  END IF;

  -- H. Verified badge check
  IF (v_job.requirements->>'verified_only')::BOOLEAN = true THEN
    v_verified_needed := true;
    IF NOT v_is_verified THEN
      v_is_eligible := false;
      IF v_reason_code IS NULL THEN v_reason_code := 'VERIFIED_REQUIRED'; END IF;
      v_reasons := array_append(v_reasons, 'UdyogaSethu Verified badge is required.');
    END IF;
  END IF;

  -- I. Audience alignment check (D-AUDIENCE)
  IF v_job.suitable_for IS NOT NULL AND array_length(v_job.suitable_for, 1) > 0 THEN
    IF NOT (v_seeker_type::public.seeker_type = ANY(v_job.suitable_for)) THEN
      v_student_gated := true;
      v_is_eligible := false;
      IF v_reason_code IS NULL THEN v_reason_code := 'AUDIENCE_MISMATCH'; END IF;
      v_reasons := array_append(v_reasons, 'This job is reserved for ' || array_to_string(v_job.suitable_for, ', ') || ' workers.');
    END IF;
  END IF;

  -- J. Schedule clash check with accepted or active assignments
  v_job_end := v_job.start_at + (COALESCE(v_job.est_duration_minutes, 480) || ' minutes')::INTERVAL;
  SELECT j2.title INTO v_overlap_job_title
  FROM public.job_assignments ja2
  JOIN public.jobs j2 ON ja2.job_id = j2.id
  WHERE ja2.worker_id = v_worker_id
    AND ja2.status IN ('accepted', 'ticket_issued', 'arrived', 'in_progress_verified')
    AND j2.start_at < v_job_end
    AND (j2.start_at + (COALESCE(j2.est_duration_minutes, 480) || ' minutes')::INTERVAL) > v_job.start_at
  LIMIT 1;

  IF v_overlap_job_title IS NOT NULL THEN
    v_schedule_overlap := true;
    v_is_eligible := false;
    IF v_reason_code IS NULL THEN v_reason_code := 'SCHEDULE_CLASH'; END IF;
    v_reasons := array_append(v_reasons, 'Schedule overlap with "' || v_overlap_job_title || '".');
  END IF;

  RETURN jsonb_build_object(
    'is_eligible', v_is_eligible,
    'reason_code', v_reason_code,
    'reasons', v_reasons,
    'licence_needed', v_licence_needed,
    'has_licence', v_has_dl,
    'verified_needed', v_verified_needed,
    'is_verified', v_is_verified,
    'student_gated', v_student_gated,
    'schedule_overlap', v_schedule_overlap,
    'overlap_job_title', v_overlap_job_title,
    'already_applied', v_already_applied,
    'is_own_job', v_is_own_job,
    'is_past_start', v_is_past_start,
    'is_slots_filled', v_is_slots_filled
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.check_job_eligibility(UUID) TO authenticated, anon;

-- ============================================================================
-- 3. Enhanced apply_to_job RPC
-- Enforces server checks with stable exception message codes
-- ============================================================================
CREATE OR REPLACE FUNCTION public.apply_to_job(
  p_job_id UUID,
  p_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_worker_id UUID;
  v_seeker_type TEXT := 'informal';
  v_has_dl BOOLEAN := false;
  v_is_verified BOOLEAN := false;
  v_job RECORD;
  v_app_id UUID;
  v_job_end TIMESTAMPTZ;
  v_overlap_job_title TEXT;
BEGIN
  v_worker_id := auth.uid();
  IF v_worker_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED: Authentication required to apply for jobs.' USING ERRCODE = '42501';
  END IF;

  -- 1. Fetch profile details
  SELECT COALESCE(wp.seeker_type::text, 'informal'),
         COALESCE(wp.has_driving_licence, false),
         COALESCE(p.is_verified, wp.is_verified_badge, false)
  INTO v_seeker_type, v_has_dl, v_is_verified
  FROM public.profiles p
  LEFT JOIN public.worker_profiles wp ON wp.user_id = p.id
  WHERE p.id = v_worker_id;

  IF NOT v_has_dl THEN
    SELECT EXISTS (
      SELECT 1 FROM public.kyc_records
      WHERE user_id = v_worker_id
        AND doc_type = 'driving_licence'
        AND status = 'verified'
    ) INTO v_has_dl;
  END IF;

  -- 2. Fetch job state
  SELECT j.*, sc.slug AS category_slug
  INTO v_job
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  IF v_job.id IS NULL THEN
    RAISE EXCEPTION 'JOB_NOT_FOUND: Job not found.' USING ERRCODE = 'P0002';
  END IF;

  IF v_job.provider_id = v_worker_id THEN
    RAISE EXCEPTION 'OWN_JOB: You cannot apply to your own job.' USING ERRCODE = 'P0006';
  END IF;

  IF v_job.is_demo = true THEN
    RAISE EXCEPTION 'DEMO_JOB: Demo jobs do not accept applications.' USING ERRCODE = 'P0005';
  END IF;

  IF v_job.start_at <= NOW() THEN
    RAISE EXCEPTION 'EXPIRED: This job start time has already passed.' USING ERRCODE = 'P0007';
  END IF;

  IF v_job.status <> 'open' OR v_job.slots_filled >= v_job.slots_total THEN
    RAISE EXCEPTION 'SLOTS_FILLED: This job is no longer accepting applications.' USING ERRCODE = 'P0003';
  END IF;

  -- 3. Audience check
  IF v_job.suitable_for IS NOT NULL AND array_length(v_job.suitable_for, 1) > 0 THEN
    IF NOT (v_seeker_type::public.seeker_type = ANY(v_job.suitable_for)) THEN
      RAISE EXCEPTION 'AUDIENCE_MISMATCH: This job is not open for % workers.', v_seeker_type USING ERRCODE = 'P0004';
    END IF;
  END IF;

  -- 4. Driving licence check
  IF ((v_job.requirements->>'licence_required')::BOOLEAN = true OR
      v_job.category_slug IN ('driver', 'delivery', 'delivery-gig-work')) AND NOT v_has_dl THEN
    RAISE EXCEPTION 'LICENCE_REQUIRED: Valid driving licence required.' USING ERRCODE = 'P0008';
  END IF;

  -- 5. Verified badge check
  IF (v_job.requirements->>'verified_only')::BOOLEAN = true AND NOT v_is_verified THEN
    RAISE EXCEPTION 'VERIFIED_REQUIRED: UdyogaSethu Verified badge required.' USING ERRCODE = 'P0009';
  END IF;

  -- 6. Schedule clash check
  v_job_end := v_job.start_at + (COALESCE(v_job.est_duration_minutes, 480) || ' minutes')::INTERVAL;
  SELECT j2.title INTO v_overlap_job_title
  FROM public.job_assignments ja2
  JOIN public.jobs j2 ON ja2.job_id = j2.id
  WHERE ja2.worker_id = v_worker_id
    AND ja2.status IN ('accepted', 'ticket_issued', 'arrived', 'in_progress_verified')
    AND j2.start_at < v_job_end
    AND (j2.start_at + (COALESCE(j2.est_duration_minutes, 480) || ' minutes')::INTERVAL) > v_job.start_at
  LIMIT 1;

  IF v_overlap_job_title IS NOT NULL THEN
    RAISE EXCEPTION 'SCHEDULE_CLASH: Schedule overlap with "%".', v_overlap_job_title USING ERRCODE = 'P0010';
  END IF;

  -- 7. Existing application check (Idempotent return)
  IF EXISTS (SELECT 1 FROM public.job_applications WHERE job_id = p_job_id AND worker_id = v_worker_id) THEN
    SELECT id INTO v_app_id FROM public.job_applications WHERE job_id = p_job_id AND worker_id = v_worker_id LIMIT 1;
    RETURN v_app_id;
  END IF;

  -- 8. Insert new application
  INSERT INTO public.job_applications (
    job_id,
    worker_id,
    status,
    message,
    created_at
  ) VALUES (
    p_job_id,
    v_worker_id,
    'applied',
    p_message,
    NOW()
  ) RETURNING id INTO v_app_id;

  RETURN v_app_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.apply_to_job(UUID, TEXT) TO authenticated;

-- ============================================================================
-- 4. Enhanced nearby_jobs RPC
-- Hides jobs whose start time has passed, no free slots, or lacking coordinates
-- ============================================================================
CREATE OR REPLACE FUNCTION public.nearby_jobs(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 50000,
  p_category_id UUID DEFAULT NULL,
  p_min_wage_paise BIGINT DEFAULT NULL,
  p_max_wage_paise BIGINT DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 60,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  category_id UUID,
  title TEXT,
  description TEXT,
  wage_type public.wage_type,
  wage_paise BIGINT,
  start_at TIMESTAMPTZ,
  slots_total INT,
  slots_filled INT,
  address_text TEXT,
  distance_m DOUBLE PRECISION,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  employer_name TEXT,
  employer_avatar TEXT,
  employer_verified BOOLEAN,
  employer_rating NUMERIC,
  category_name JSONB,
  category_icon TEXT,
  category_slug TEXT
) AS $$
DECLARE
  v_point extensions.geography;
  v_caller_id UUID;
  v_seeker_type TEXT := 'informal';
BEGIN
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  v_caller_id := auth.uid();
  IF v_caller_id IS NOT NULL THEN
    SELECT COALESCE(wp.seeker_type::text, 'informal')
    INTO v_seeker_type
    FROM public.worker_profiles wp
    WHERE wp.user_id = v_caller_id;
  END IF;

  IF v_seeker_type IS NULL THEN
    v_seeker_type := 'informal';
  END IF;

  RETURN QUERY
  SELECT
    j.id,
    j.provider_id,
    j.category_id,
    j.title,
    j.description,
    j.wage_type,
    j.wage_paise,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    j.address_text,
    extensions.ST_Distance(j.location, v_point) AS distance_m,
    extensions.ST_Y(j.location::extensions.geometry) AS lat,
    extensions.ST_X(j.location::extensions.geometry) AS lng,
    COALESCE(pr.org_name, pr_p.full_name, 'Employer') AS employer_name,
    pr_p.avatar_path AS employer_avatar,
    public.is_provider_verified(j.provider_id) AS employer_verified,
    COALESCE(pr.rating_avg, 4.8) AS employer_rating,
    sc.names AS category_name,
    COALESCE(sc.icon, 'work') AS category_icon,
    COALESCE(sc.slug, 'general') AS category_slug
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  LEFT JOIN public.profiles pr_p ON j.provider_id = pr_p.id
  LEFT JOIN public.provider_profiles pr ON j.provider_id = pr.user_id
  WHERE j.status = 'open'
    AND j.slots_filled < j.slots_total
    AND j.start_at > NOW() -- Hide past start times
    AND j.is_demo = false  -- Exclude demo jobs
    AND j.location IS NOT NULL -- Must have valid coordinates
    AND extensions.ST_DWithin(j.location, v_point, p_radius_m)
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    AND (p_min_wage_paise IS NULL OR j.wage_paise >= p_min_wage_paise)
    AND (p_max_wage_paise IS NULL OR j.wage_paise <= p_max_wage_paise)
    AND (p_search_query IS NULL OR p_search_query = '' OR (
      j.title ILIKE '%' || p_search_query || '%' OR
      COALESCE(j.description, '') ILIKE '%' || p_search_query || '%'
    ))
    -- Strict suitable_for matching
    AND (
      v_seeker_type::public.seeker_type = ANY(j.suitable_for)
    )
  ORDER BY distance_m ASC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.nearby_jobs TO authenticated, anon;

-- ============================================================================
-- 5. Enhanced recommended_jobs RPC
-- Enforces future start time, free slots, real coordinates, and explicit students_welcome
-- ============================================================================
CREATE OR REPLACE FUNCTION public.recommended_jobs(
  p_worker_id UUID,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_radius_km DOUBLE PRECISION DEFAULT 50,
  p_limit INT DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  category_id UUID,
  title TEXT,
  description TEXT,
  wage_type public.wage_type,
  wage_paise BIGINT,
  est_duration_minutes INT,
  start_at TIMESTAMPTZ,
  slots_total INT,
  slots_filled INT,
  address_text TEXT,
  distance_m DOUBLE PRECISION,
  employer_name TEXT,
  employer_avatar TEXT,
  employer_verified BOOLEAN,
  employer_rating NUMERIC,
  category_name JSONB,
  category_icon TEXT,
  category_slug TEXT,
  is_student_friendly BOOLEAN,
  is_flexible_shift BOOLEAN,
  score DOUBLE PRECISION,
  reasons JSONB
) AS $$
DECLARE
  v_point extensions.geography;
  v_effective_id UUID;
  v_seeker_type TEXT := 'informal';
  v_daily_rate_paise BIGINT := 65000;
  v_hourly_rate_paise BIGINT := 10000;
  v_worker_rating NUMERIC := 4.5;
  v_working_days TEXT[] := '{}';
  v_has_dl BOOLEAN := false;
  v_has_verified_badge BOOLEAN := false;
  v_radius_m DOUBLE PRECISION;
BEGIN
  v_effective_id := COALESCE(p_worker_id, auth.uid());
  v_radius_m := p_radius_km * 1000.0;

  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  ELSE
    SELECT wp.location INTO v_point
    FROM public.worker_profiles wp
    WHERE wp.user_id = v_effective_id;
  END IF;

  IF v_point IS NULL THEN
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(77.5946, 12.9716), 4326)::extensions.geography;
  END IF;

  IF v_effective_id IS NOT NULL THEN
    SELECT
      COALESCE(wp.seeker_type::text, 'informal'),
      COALESCE(wp.daily_rate_paise, 65000),
      COALESCE(wp.hourly_rate_paise, 10000),
      COALESCE(wp.rating_avg, 4.5),
      COALESCE(wp.working_days, '{}'::TEXT[]),
      COALESCE(wp.has_driving_licence, false),
      COALESCE(wp.is_verified_badge, false)
    INTO
      v_seeker_type,
      v_daily_rate_paise,
      v_hourly_rate_paise,
      v_worker_rating,
      v_working_days,
      v_has_dl,
      v_has_verified_badge
    FROM public.worker_profiles wp
    WHERE wp.user_id = v_effective_id;
  END IF;

  IF v_seeker_type IS NULL THEN
    v_seeker_type := 'informal';
  END IF;

  IF NOT v_has_dl AND v_effective_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.kyc_records
      WHERE user_id = v_effective_id
        AND doc_type = 'driving_licence'
        AND status = 'verified'
    ) INTO v_has_dl;
  END IF;

  RETURN QUERY
  WITH scored_jobs AS (
    SELECT
      j.id,
      j.provider_id,
      j.category_id,
      j.title,
      j.description,
      j.wage_type,
      j.wage_paise,
      j.est_duration_minutes,
      j.start_at,
      j.slots_total,
      j.slots_filled,
      j.address_text,
      COALESCE(extensions.ST_Distance(j.location, v_point), 1500.0) AS dist_m,
      COALESCE(pr.org_name, pr_p.full_name, 'Employer') AS emp_name,
      pr_p.avatar_path AS emp_avatar,
      public.is_provider_verified(j.provider_id) AS emp_verified,
      COALESCE(pr.rating_avg, 4.8) AS emp_rating,
      sc.names AS cat_names,
      COALESCE(sc.icon, 'work') AS cat_icon,
      COALESCE(sc.slug, 'general') AS cat_slug,
      sc.audience AS cat_audience,
      -- Explicit students_ok toggle only:
      COALESCE((j.requirements->>'students_ok')::boolean, false) AS stu_ok,
      (COALESCE((j.requirements->>'part_time_ok')::boolean, false) OR COALESCE(j.est_duration_minutes, 480) <= 300) AS flex_shift,
      EXISTS (
        SELECT 1 FROM public.worker_skills ws
        JOIN public.skills s ON ws.skill_id = s.id
        WHERE ws.user_id = v_effective_id
          AND (s.category_id = j.category_id OR j.title ILIKE '%' || (s.names->>'en') || '%')
      ) AS has_skill_match
    FROM public.jobs j
    LEFT JOIN public.service_categories sc ON j.category_id = sc.id
    LEFT JOIN public.profiles pr_p ON j.provider_id = pr_p.id
    LEFT JOIN public.provider_profiles pr ON j.provider_id = pr.user_id
    WHERE j.status = 'open'
      AND j.slots_filled < j.slots_total
      AND j.start_at > NOW() -- Future start time only
      AND j.is_demo = false  -- Exclude demo jobs
      AND j.location IS NOT NULL -- Hide jobs without coordinates
      AND (v_radius_m <= 0 OR extensions.ST_DWithin(j.location, v_point, v_radius_m))
      AND (
        v_seeker_type::public.seeker_type = ANY(j.suitable_for)
      )
      AND (
        p_search_query IS NULL OR p_search_query = '' OR
        j.title ILIKE '%' || p_search_query || '%' OR
        COALESCE(j.description, '') ILIKE '%' || p_search_query || '%'
      )
  )
  SELECT
    sj.id,
    sj.provider_id,
    sj.category_id,
    sj.title,
    sj.description,
    sj.wage_type,
    sj.wage_paise,
    sj.est_duration_minutes,
    sj.start_at,
    sj.slots_total,
    sj.slots_filled,
    sj.address_text,
    sj.dist_m AS distance_m,
    sj.emp_name AS employer_name,
    sj.emp_avatar AS employer_avatar,
    sj.emp_verified AS employer_verified,
    sj.emp_rating AS employer_rating,
    sj.cat_names AS category_name,
    sj.cat_icon AS category_icon,
    sj.cat_slug AS category_slug,
    sj.stu_ok AS is_student_friendly,
    sj.flex_shift AS is_flexible_shift,
    (
      50.0
      + (CASE WHEN sj.has_skill_match THEN 30.0 ELSE 0.0 END)
      + (CASE
          WHEN sj.dist_m <= 2000 THEN 25.0
          WHEN sj.dist_m <= 5000 THEN 18.0
          WHEN sj.dist_m <= 10000 THEN 12.0
          WHEN sj.dist_m <= 20000 THEN 6.0
          ELSE 2.0
         END)
      + (CASE WHEN sj.emp_rating >= 4.7 THEN 12.0 WHEN sj.emp_rating >= 4.0 THEN 6.0 ELSE 0.0 END)
      + (CASE WHEN sj.wage_paise >= v_daily_rate_paise THEN 15.0 ELSE 5.0 END)
      + (CASE
          WHEN v_seeker_type = 'student' AND sj.stu_ok THEN 40.0
          WHEN v_seeker_type = 'student' AND sj.est_duration_minutes <= 240 THEN 20.0
          WHEN v_seeker_type = 'student' AND sj.est_duration_minutes > 480 THEN -25.0
          WHEN v_seeker_type = 'part_time' AND sj.flex_shift THEN 35.0
          WHEN v_seeker_type = 'part_time' AND sj.wage_type = 'hourly' THEN 15.0
          WHEN v_seeker_type = 'informal' AND sj.wage_type = 'daily' THEN 20.0
          ELSE 0.0
         END)
    )::DOUBLE PRECISION AS score,
    (
      SELECT jsonb_agg(r)
      FROM (
        SELECT r FROM unnest(ARRAY[
          CASE WHEN v_seeker_type IN ('student', 'part_time') AND sj.stu_ok THEN 'Students Welcome 🎓' ELSE NULL END,
          CASE WHEN v_seeker_type IN ('student', 'part_time') AND (sj.flex_shift OR (sj.est_duration_minutes IS NOT NULL AND sj.est_duration_minutes <= 240)) THEN 'Short Shift ⏱️' ELSE NULL END,
          CASE WHEN v_seeker_type IN ('student', 'part_time') AND sj.flex_shift THEN 'Flexible Hours ⏰' ELSE NULL END,
          CASE WHEN sj.has_skill_match THEN 'Matches Your Skills' ELSE NULL END,
          CASE WHEN sj.dist_m <= 3000 THEN 'Near Your Location' ELSE NULL END,
          CASE WHEN sj.emp_rating >= 4.8 THEN 'Top Rated Employer' ELSE NULL END,
          CASE WHEN sj.wage_paise > v_daily_rate_paise THEN 'High Pay' ELSE NULL END
        ]) AS r
        WHERE r IS NOT NULL
      ) sub
    ) AS reasons
  FROM scored_jobs sj
  ORDER BY score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.recommended_jobs TO authenticated, anon;

-- ============================================================================
-- 6. Enhanced get_job_applicants RPC
-- Returns photo, name, seeker type, badge, level, rating, skills, distance, message, created_at
-- Guarded by provider ownership or admin
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_job_applicants(
  p_job_id UUID
)
RETURNS TABLE (
  application_id UUID,
  job_id UUID,
  worker_id UUID,
  status TEXT,
  message TEXT,
  created_at TIMESTAMPTZ,
  worker_name TEXT,
  worker_avatar TEXT,
  seeker_type TEXT,
  badge_name TEXT,
  level_number INT,
  is_verified BOOLEAN,
  rating NUMERIC,
  review_count BIGINT,
  jobs_completed_count BIGINT,
  distance_m DOUBLE PRECISION,
  languages TEXT[],
  skills TEXT[]
) AS $$
DECLARE
  v_provider_id UUID;
  v_job_loc extensions.geography(Point, 4326);
BEGIN
  v_provider_id := auth.uid();
  SELECT location INTO v_job_loc FROM public.jobs WHERE id = p_job_id AND (provider_id = v_provider_id OR public.is_admin());
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found or unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    ja.id AS application_id,
    ja.job_id,
    ja.worker_id,
    ja.status::TEXT,
    ja.message,
    ja.created_at,
    COALESCE(p.full_name, 'Worker')::TEXT AS worker_name,
    p.avatar_path::TEXT AS worker_avatar,
    COALESCE(wp.seeker_type::text, 'informal')::TEXT AS seeker_type,
    CASE
      WHEN COALESCE(p.is_verified, wp.is_verified_badge, false) THEN 'Verified Worker'
      ELSE 'Registered Worker'
    END::TEXT AS badge_name,
    COALESCE(ug.level, 1)::INT AS level_number,
    COALESCE(p.is_verified, wp.is_verified_badge, false) AS is_verified,
    COALESCE(p.rating, 4.8)::NUMERIC AS rating,
    COALESCE(p.review_count, 0)::BIGINT AS review_count,
    (SELECT COUNT(*) FROM public.job_assignments ass WHERE ass.worker_id = ja.worker_id AND ass.status IN ('completed', 'payment_released'))::BIGINT AS jobs_completed_count,
    CASE 
      WHEN v_job_loc IS NOT NULL AND wp.location IS NOT NULL THEN
        extensions.ST_Distance(v_job_loc, wp.location)
      ELSE 800.0
    END AS distance_m,
    COALESCE(wp.languages, ARRAY[p.language])::TEXT[] AS languages,
    COALESCE(
      (
        SELECT ARRAY_AGG(COALESCE(s.names->>'en', s.slug))
        FROM public.worker_skills ws
        JOIN public.skills s ON ws.skill_id = s.id
        WHERE ws.worker_id = ja.worker_id
      ),
      ARRAY[]::TEXT[]
    ) AS skills
  FROM public.job_applications ja
  JOIN public.profiles p ON ja.worker_id = p.id
  LEFT JOIN public.worker_profiles wp ON wp.user_id = ja.worker_id
  LEFT JOIN public.user_gamification ug ON ug.user_id = ja.worker_id
  WHERE ja.job_id = p_job_id
  ORDER BY 
    CASE ja.status
      WHEN 'applied' THEN 1
      WHEN 'shortlisted' THEN 2
      WHEN 'hired' THEN 3
      ELSE 4
    END,
    ja.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_job_applicants(UUID) TO authenticated;

-- ============================================================================
-- 5. Enhanced post_provider_job and update_provider_job with landmark support
-- ============================================================================
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
  p_suitable_for TEXT[] DEFAULT ARRAY['informal', 'student', 'part_time'],
  p_landmark TEXT DEFAULT NULL
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
    v_suitable := ARRAY['informal'::public.seeker_type, 'student'::public.seeker_type, 'part_time'::public.seeker_type];
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
    COALESCE(p_geofence_radius_m, 150),
    v_suitable,
    false,
    'open'
  )
  RETURNING id INTO v_job_id;

  RETURN v_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.post_provider_job(UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], TEXT) TO authenticated;

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
  p_suitable_for TEXT[] DEFAULT ARRAY['informal', 'student', 'part_time'],
  p_landmark TEXT DEFAULT NULL
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
    v_suitable := ARRAY['informal'::public.seeker_type, 'student'::public.seeker_type, 'part_time'::public.seeker_type];
  END IF;

  UPDATE public.jobs
  SET
    category_id = p_category_id,
    title = TRIM(p_title),
    description = p_description,
    wage_type = p_wage_type,
    wage_paise = p_wage_paise,
    est_duration_minutes = COALESCE(p_est_duration_minutes, est_duration_minutes),
    start_at = p_start_at,
    slots_total = GREATEST(COALESCE(p_slots_total, slots_total), 1),
    materials_provided = COALESCE(p_materials_provided, materials_provided),
    payment_mode = p_payment_mode,
    requirements = COALESCE(p_requirements, requirements),
    location = COALESCE(v_loc, location),
    address_text = COALESCE(p_address_text, address_text),
    landmark = COALESCE(p_landmark, landmark),
    geofence_radius_m = COALESCE(p_geofence_radius_m, geofence_radius_m),
    suitable_for = v_suitable,
    updated_at = NOW()
  WHERE id = p_job_id
    AND (provider_id = v_provider_id OR public.is_admin());

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found or unauthorized.';
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.update_provider_job(UUID, UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], TEXT) TO authenticated;
