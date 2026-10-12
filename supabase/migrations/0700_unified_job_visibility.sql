-- Migration 0700: Unified Job Visibility, Single Source of Truth, Audience Isolation & Location Fallback

-- 1. Helper function: Single source of truth for job visibility to a worker
CREATE OR REPLACE FUNCTION public.job_visible_to(
  p_worker_id UUID,
  p_job_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_job RECORD;
  v_wp RECORD;
  v_worker_type TEXT;
  v_has_licence BOOLEAN := false;
  v_is_verified BOOLEAN := false;
BEGIN
  -- Read job details
  SELECT
    j.id,
    j.status,
    j.suitable_for,
    j.is_demo,
    j.provider_id,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    COALESCE(sc.requires_licence, false) OR COALESCE((j.requirements->>'licence_required')::BOOLEAN, false) AS licence_required,
    COALESCE((j.requirements->>'verified_only')::BOOLEAN, false) AS verified_only
  INTO v_job
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  IF v_job.id IS NULL THEN
    RETURN false;
  END IF;

  -- 1a. Core job lifecycle rules
  IF v_job.status != 'open'::public.job_status THEN
    RETURN false;
  END IF;

  IF v_job.start_at <= NOW() THEN
    RETURN false;
  END IF;

  IF v_job.slots_total > 0 AND v_job.slots_filled >= v_job.slots_total THEN
    RETURN false;
  END IF;

  -- 1b. Empty or missing audience = visible to NOBODY
  IF v_job.suitable_for IS NULL OR array_length(v_job.suitable_for, 1) IS NULL OR array_length(v_job.suitable_for, 1) = 0 THEN
    RETURN false;
  END IF;

  -- 1c. Provider cannot see own job as a worker recommendation
  IF p_worker_id IS NOT NULL AND v_job.provider_id = p_worker_id THEN
    RETURN false;
  END IF;

  -- 1d. Worker-specific audience matching & qualifications
  IF p_worker_id IS NOT NULL THEN
    SELECT seeker_type, has_driving_licence, is_verified_badge
    INTO v_wp
    FROM public.worker_profiles
    WHERE user_id = p_worker_id;

    v_worker_type := COALESCE(v_wp.seeker_type::TEXT, 'informal');
    v_has_licence := COALESCE(v_wp.has_driving_licence, false);
    v_is_verified := COALESCE(v_wp.is_verified_badge, false);

    -- Audience isolation: worker seeker_type MUST be contained in suitable_for
    IF NOT (COALESCE(v_wp.seeker_type, 'informal'::public.seeker_type) = ANY(v_job.suitable_for)) THEN
      RETURN false;
    END IF;

    -- Mandatory licence gating
    IF v_job.licence_required AND NOT v_has_licence THEN
      RETURN false;
    END IF;

    -- Mandatory verification gating
    IF v_job.verified_only AND NOT v_is_verified THEN
      RETURN false;
    END IF;
  END IF;

  RETURN true;
END;
$$;

-- 2. Diagnostic visibility reason explainer for debug screen and UI reasons
CREATE OR REPLACE FUNCTION public.get_job_visibility_diagnostic(
  p_worker_id UUID,
  p_job_id UUID,
  p_worker_lat DOUBLE PRECISION DEFAULT NULL,
  p_worker_lng DOUBLE PRECISION DEFAULT NULL,
  p_radius_m DOUBLE PRECISION DEFAULT 50000
) RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_job RECORD;
  v_wp RECORD;
  v_worker_type TEXT;
  v_has_licence BOOLEAN := false;
  v_is_verified BOOLEAN := false;
  v_distance_m DOUBLE PRECISION := NULL;
  v_already_applied BOOLEAN := false;
  v_hired BOOLEAN := false;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_status TEXT := 'VISIBLE';
BEGIN
  SELECT
    j.id,
    j.title,
    j.status,
    j.suitable_for,
    j.is_demo,
    j.provider_id,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    j.location,
    COALESCE(sc.requires_licence, false) OR COALESCE((j.requirements->>'licence_required')::BOOLEAN, false) AS licence_required,
    COALESCE((j.requirements->>'verified_only')::BOOLEAN, false) AS verified_only
  INTO v_job
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  IF v_job.id IS NULL THEN
    RETURN jsonb_build_object('is_visible', false, 'status', 'NOT_FOUND', 'reasons', ARRAY['Job does not exist']);
  END IF;

  IF p_worker_id IS NOT NULL THEN
    SELECT seeker_type, has_driving_licence, is_verified_badge
    INTO v_wp
    FROM public.worker_profiles
    WHERE user_id = p_worker_id;

    v_worker_type := COALESCE(v_wp.seeker_type::TEXT, 'informal');
    v_has_licence := COALESCE(v_wp.has_driving_licence, false);
    v_is_verified := COALESCE(v_wp.is_verified_badge, false);

    SELECT EXISTS(
      SELECT 1 FROM public.job_applications
      WHERE job_id = p_job_id AND worker_id = p_worker_id AND status != 'withdrawn'
    ) INTO v_already_applied;

    SELECT EXISTS(
      SELECT 1 FROM public.job_assignments
      WHERE job_id = p_job_id AND worker_id = p_worker_id AND status NOT IN ('cancelled')
    ) INTO v_hired;
  END IF;

  IF p_worker_lat IS NOT NULL AND p_worker_lng IS NOT NULL AND v_job.location IS NOT NULL
     AND p_worker_lat != 0.0 AND p_worker_lng != 0.0 THEN
    v_distance_m := extensions.ST_Distance(
      extensions.ST_SetSRID(extensions.ST_MakePoint(p_worker_lng, p_worker_lat), 4326)::extensions.geography,
      v_job.location
    );
  END IF;

  IF v_job.status != 'open'::public.job_status THEN
    v_reasons := array_append(v_reasons, 'Status is ' || v_job.status::TEXT || ' (not open)');
  END IF;

  IF v_job.start_at <= NOW() THEN
    v_reasons := array_append(v_reasons, 'Job start time has passed (' || v_job.start_at::TEXT || ')');
  END IF;

  IF v_job.slots_total > 0 AND v_job.slots_filled >= v_job.slots_total THEN
    v_reasons := array_append(v_reasons, 'All slots filled (' || v_job.slots_filled || '/' || v_job.slots_total || ')');
  END IF;

  IF v_job.suitable_for IS NULL OR array_length(v_job.suitable_for, 1) IS NULL OR array_length(v_job.suitable_for, 1) = 0 THEN
    v_reasons := array_append(v_reasons, 'Missing or empty audience (visible to nobody)');
  ELSIF p_worker_id IS NOT NULL AND NOT (COALESCE(v_wp.seeker_type, 'informal'::public.seeker_type) = ANY(v_job.suitable_for)) THEN
    v_reasons := array_append(v_reasons, 'Audience mismatch: Job is for ' || array_to_string(v_job.suitable_for, ', ') || ' but worker is ' || v_worker_type);
  END IF;

  IF p_worker_id IS NOT NULL AND v_job.provider_id = p_worker_id THEN
    v_reasons := array_append(v_reasons, 'Posted by this user (own job)');
  END IF;

  IF v_job.licence_required AND NOT v_has_licence THEN
    v_reasons := array_append(v_reasons, 'Requires driving licence');
  END IF;

  IF v_job.verified_only AND NOT v_is_verified THEN
    v_reasons := array_append(v_reasons, 'Requires verified profile');
  END IF;

  IF v_distance_m IS NOT NULL AND v_distance_m > p_radius_m THEN
    v_reasons := array_append(v_reasons, 'Outside search radius (' || ROUND((v_distance_m / 1000.0)::NUMERIC, 1) || ' km > ' || ROUND((p_radius_m / 1000.0)::NUMERIC, 1) || ' km)');
  END IF;

  IF array_length(v_reasons, 1) IS NOT NULL AND array_length(v_reasons, 1) > 0 THEN
    v_status := 'HIDDEN';
  END IF;

  RETURN jsonb_build_object(
    'is_visible', (v_status = 'VISIBLE'),
    'status', v_status,
    'job_id', p_job_id,
    'job_title', v_job.title,
    'suitable_for', v_job.suitable_for,
    'worker_type', v_worker_type,
    'distance_m', v_distance_m,
    'already_applied', v_already_applied,
    'hired', v_hired,
    'reasons', v_reasons
  );
END;
$$;

-- 3. Update recommended_jobs with unified visibility, coordinate sanitization and profile location fallback
DROP FUNCTION IF EXISTS public.recommended_jobs(UUID, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER);
CREATE OR REPLACE FUNCTION public.recommended_jobs(
  p_worker_id UUID,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_radius_m DOUBLE PRECISION DEFAULT 50000,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  category_id UUID,
  title TEXT,
  description TEXT,
  wage_type TEXT,
  wage_paise BIGINT,
  est_duration_minutes INTEGER,
  start_at TIMESTAMPTZ,
  slots_total INTEGER,
  slots_filled INTEGER,
  address_text TEXT,
  distance_m DOUBLE PRECISION,
  employer_name TEXT,
  employer_avatar TEXT,
  employer_verified BOOLEAN,
  employer_rating NUMERIC,
  category_names JSONB,
  category_icon TEXT,
  category_slug TEXT,
  site_photo_url TEXT,
  students_ok BOOLEAN,
  is_student BOOLEAN,
  is_part_time BOOLEAN,
  match_score DOUBLE PRECISION,
  match_reasons TEXT[],
  application_status TEXT,
  assignment_status TEXT,
  application_id UUID,
  assignment_id UUID,
  is_location_fallback BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_ref_point extensions.geography(Point, 4326) := NULL;
  v_caller UUID := COALESCE(auth.uid(), p_worker_id);
  v_worker_home extensions.geography(Point, 4326) := NULL;
  v_is_fallback BOOLEAN := false;
  v_clean_lat DOUBLE PRECISION := NULL;
  v_clean_lng DOUBLE PRECISION := NULL;
BEGIN
  -- Sanitize 0.0, 0.0 Null Island coordinates
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL AND (p_lat != 0.0 OR p_lng != 0.0) THEN
    v_clean_lat := p_lat;
    v_clean_lng := p_lng;
    v_ref_point := extensions.ST_SetSRID(extensions.ST_MakePoint(v_clean_lng, v_clean_lat), 4326)::extensions.geography;
  ELSE
    -- Fallback 1: Worker's saved profile home_location
    SELECT p.home_location::extensions.geography INTO v_worker_home
    FROM public.profiles p
    WHERE p.id = v_caller AND p.home_location IS NOT NULL;

    IF v_worker_home IS NOT NULL THEN
      v_ref_point := v_worker_home;
      v_is_fallback := true;
    ELSE
      -- Fallback 2: No coordinates at all -> city-wide / global feed
      v_is_fallback := true;
    END IF;
  END IF;

  RETURN QUERY
  SELECT
    j.id,
    j.provider_id,
    j.category_id,
    j.title,
    j.description,
    j.wage_type::TEXT,
    j.wage_paise,
    j.est_duration_minutes,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    j.address_text,
    CASE
      WHEN v_ref_point IS NOT NULL AND j.location IS NOT NULL THEN extensions.ST_Distance(v_ref_point, j.location)
      ELSE 0.0
    END AS distance_m,
    COALESCE(pp.full_name, 'Employer')::TEXT AS employer_name,
    pp.avatar_path::TEXT AS employer_avatar,
    COALESCE(prp.is_verified_badge, false) AS employer_verified,
    prp.rating_avg AS employer_rating,
    sc.names AS category_names,
    COALESCE(sc.icon, 'work')::TEXT AS category_icon,
    COALESCE(sc.slug, 'general')::TEXT AS category_slug,
    j.site_photo_url,
    COALESCE((j.requirements->>'students_ok')::BOOLEAN, false) AS students_ok,
    ('student'::public.seeker_type = ANY(j.suitable_for)) AS is_student,
    ('part_time'::public.seeker_type = ANY(j.suitable_for)) AS is_part_time,
    100.0::DOUBLE PRECISION AS match_score,
    ARRAY['Open position']::TEXT[] AS match_reasons,
    COALESCE(my_app.status, 'none')::TEXT AS application_status,
    my_asg.status::TEXT AS assignment_status,
    my_app.id AS application_id,
    my_asg.id AS assignment_id,
    v_is_fallback AS is_location_fallback
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
  WHERE public.job_visible_to(v_caller, j.id) = true
    AND (
      v_ref_point IS NULL
      OR j.location IS NULL
      OR extensions.ST_DWithin(v_ref_point, j.location, p_radius_m)
      OR v_is_fallback = true -- City-wide fallback allows seeing matching jobs if worker has no GPS
    )
  ORDER BY
    CASE WHEN v_ref_point IS NOT NULL AND j.location IS NOT NULL THEN extensions.ST_Distance(v_ref_point, j.location) ELSE 0.0 END ASC,
    j.created_at DESC
  LIMIT p_limit;
END;
$$;

-- 4. Update nearby_jobs with unified visibility, coordinate sanitization and profile location fallback
DROP FUNCTION IF EXISTS public.nearby_jobs(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, UUID, TEXT, INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION public.nearby_jobs(
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_radius_m DOUBLE PRECISION DEFAULT 50000,
  p_category_id UUID DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  category_id UUID,
  title TEXT,
  description TEXT,
  wage_type TEXT,
  wage_paise BIGINT,
  start_at TIMESTAMPTZ,
  slots_total INTEGER,
  slots_filled INTEGER,
  address_text TEXT,
  distance_m DOUBLE PRECISION,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  employer_name TEXT,
  employer_avatar TEXT,
  employer_verified BOOLEAN,
  employer_rating NUMERIC,
  category_names JSONB,
  category_icon TEXT,
  category_slug TEXT,
  application_status TEXT,
  assignment_status TEXT,
  application_id UUID,
  assignment_id UUID
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_ref_point extensions.geography(Point, 4326) := NULL;
  v_caller UUID := auth.uid();
  v_worker_home extensions.geography(Point, 4326) := NULL;
  v_clean_lat DOUBLE PRECISION := NULL;
  v_clean_lng DOUBLE PRECISION := NULL;
BEGIN
  -- Sanitize 0.0, 0.0 coordinates
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL AND (p_lat != 0.0 OR p_lng != 0.0) THEN
    v_clean_lat := p_lat;
    v_clean_lng := p_lng;
    v_ref_point := extensions.ST_SetSRID(extensions.ST_MakePoint(v_clean_lng, v_clean_lat), 4326)::extensions.geography;
  ELSE
    -- Fallback: worker profile home location
    IF v_caller IS NOT NULL THEN
      SELECT p.home_location::extensions.geography INTO v_worker_home
      FROM public.profiles p
      WHERE p.id = v_caller AND p.home_location IS NOT NULL;
      IF v_worker_home IS NOT NULL THEN
        v_ref_point := v_worker_home;
      END IF;
    END IF;
  END IF;

  RETURN QUERY
  SELECT
    j.id,
    j.provider_id,
    j.category_id,
    j.title,
    j.description,
    j.wage_type::TEXT,
    j.wage_paise,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    j.address_text,
    CASE
      WHEN v_ref_point IS NOT NULL AND j.location IS NOT NULL THEN extensions.ST_Distance(v_ref_point, j.location)
      ELSE 0.0
    END AS distance_m,
    extensions.ST_Y(j.location::extensions.geometry) AS lat,
    extensions.ST_X(j.location::extensions.geometry) AS lng,
    COALESCE(pp.full_name, 'Employer')::TEXT AS employer_name,
    pp.avatar_path::TEXT AS employer_avatar,
    COALESCE(prp.is_verified_badge, false) AS employer_verified,
    prp.rating_avg AS employer_rating,
    sc.names AS category_names,
    COALESCE(sc.icon, 'work')::TEXT AS category_icon,
    COALESCE(sc.slug, 'general')::TEXT AS category_slug,
    COALESCE(my_app.status, 'none')::TEXT AS application_status,
    my_asg.status::TEXT AS assignment_status,
    my_app.id AS application_id,
    my_asg.id AS assignment_id
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
  WHERE public.job_visible_to(v_caller, j.id) = true
    AND (v_ref_point IS NULL OR j.location IS NULL OR extensions.ST_DWithin(v_ref_point, j.location, p_radius_m))
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    AND (p_search_query IS NULL OR j.title ILIKE '%' || p_search_query || '%')
  ORDER BY
    CASE WHEN v_ref_point IS NOT NULL AND j.location IS NOT NULL THEN extensions.ST_Distance(v_ref_point, j.location) ELSE 0.0 END ASC,
    j.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 5. Update check_job_eligibility and apply_to_job to enforce strict audience matching
CREATE OR REPLACE FUNCTION public.check_job_eligibility(
  p_job_id UUID,
  p_worker_id UUID DEFAULT auth.uid()
) RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := COALESCE(p_worker_id, auth.uid());
  v_job RECORD;
  v_wp RECORD;
  v_worker_type TEXT;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_code TEXT := 'ELIGIBLE';
  v_overlap_title TEXT := NULL;
  v_licence_needed BOOLEAN := false;
  v_has_licence BOOLEAN := false;
  v_verified_needed BOOLEAN := false;
  v_is_verified BOOLEAN := false;
  v_already_applied BOOLEAN := false;
  v_is_own_job BOOLEAN := false;
  v_is_past_start BOOLEAN := false;
  v_is_slots_filled BOOLEAN := false;
  v_schedule_overlap BOOLEAN := false;
  v_audience_mismatch BOOLEAN := false;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('is_eligible', false, 'reason_code', 'NOT_AUTHENTICATED', 'reasons', ARRAY['Sign in required.']);
  END IF;

  SELECT j.*, sc.requires_licence, sc.audience INTO v_job
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  IF v_job.id IS NULL THEN
    RETURN jsonb_build_object('is_eligible', false, 'reason_code', 'JOB_NOT_FOUND', 'reasons', ARRAY['Job not found.']);
  END IF;

  SELECT seeker_type, has_driving_licence, is_verified_badge INTO v_wp
  FROM public.worker_profiles
  WHERE user_id = v_uid;

  v_worker_type := COALESCE(v_wp.seeker_type::TEXT, 'informal');
  v_has_licence := COALESCE(v_wp.has_driving_licence, false);
  v_is_verified := COALESCE(v_wp.is_verified_badge, false);
  v_licence_needed := COALESCE(v_job.requires_licence, false) OR COALESCE((v_job.requirements->>'licence_required')::BOOLEAN, false);
  v_verified_needed := COALESCE((v_job.requirements->>'verified_only')::BOOLEAN, false);

  IF v_job.provider_id = v_uid THEN
    v_is_own_job := true;
    v_code := 'OWN_JOB';
    v_reasons := array_append(v_reasons, 'Cannot apply to own job.');
  END IF;

  IF v_job.start_at <= NOW() THEN
    v_is_past_start := true;
    v_code := 'EXPIRED';
    v_reasons := array_append(v_reasons, 'Job start time has passed.');
  END IF;

  IF v_job.status != 'open'::public.job_status OR (v_job.slots_total > 0 AND v_job.slots_filled >= v_job.slots_total) THEN
    v_is_slots_filled := true;
    v_code := 'SLOTS_FILLED';
    v_reasons := array_append(v_reasons, 'All job slots are filled.');
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM public.job_applications
    WHERE job_id = p_job_id AND worker_id = v_uid AND status != 'withdrawn'
  ) INTO v_already_applied;

  IF v_already_applied THEN
    v_code := 'ALREADY_APPLIED';
    v_reasons := array_append(v_reasons, 'Already applied to this job.');
  END IF;

  IF v_licence_needed AND NOT v_has_licence THEN
    v_code := 'LICENCE_REQUIRED';
    v_reasons := array_append(v_reasons, 'Driving licence is required.');
  END IF;

  IF v_verified_needed AND NOT v_is_verified THEN
    v_code := 'VERIFICATION_REQUIRED';
    v_reasons := array_append(v_reasons, 'Verified profile required.');
  END IF;

  -- Unified Audience isolation enforcement across all worker roles
  IF v_job.suitable_for IS NULL OR array_length(v_job.suitable_for, 1) IS NULL OR array_length(v_job.suitable_for, 1) = 0 THEN
    v_audience_mismatch := true;
    v_code := 'NO_AUDIENCE_SET';
    v_reasons := array_append(v_reasons, 'This job has no target audience set.');
  ELSIF NOT (COALESCE(v_wp.seeker_type, 'informal'::public.seeker_type) = ANY(v_job.suitable_for)) THEN
    v_audience_mismatch := true;
    v_code := 'AUDIENCE_MISMATCH';
    v_reasons := array_append(v_reasons, 'Job is designated for ' || array_to_string(v_job.suitable_for, ', ') || ' only.');
  END IF;

  -- Schedule overlap check
  SELECT j2.title INTO v_overlap_title
  FROM public.job_assignments ja
  JOIN public.jobs j2 ON ja.job_id = j2.id
  WHERE ja.worker_id = v_uid
    AND ja.status NOT IN ('cancelled', 'completed', 'payment_released')
    AND ja.started_at IS NOT NULL
    AND ja.ended_at IS NULL
    AND j2.start_at < (v_job.start_at + (v_job.est_duration_minutes || ' minutes')::INTERVAL)
    AND (j2.start_at + (j2.est_duration_minutes || ' minutes')::INTERVAL) > v_job.start_at
  LIMIT 1;

  IF v_overlap_title IS NOT NULL THEN
    v_schedule_overlap := true;
    v_code := 'SCHEDULE_CLASH';
    v_reasons := array_append(v_reasons, 'Schedule overlaps with job: ' || v_overlap_title);
  END IF;

  RETURN jsonb_build_object(
    'is_eligible', (array_length(v_reasons, 1) IS NULL OR array_length(v_reasons, 1) = 0),
    'reason_code', v_code,
    'licence_needed', v_licence_needed,
    'has_licence', v_has_licence,
    'verified_needed', v_verified_needed,
    'is_verified', v_is_verified,
    'audience_mismatch', v_audience_mismatch,
    'schedule_overlap', v_schedule_overlap,
    'overlap_job_title', v_overlap_title,
    'already_applied', v_already_applied,
    'is_own_job', v_is_own_job,
    'is_past_start', v_is_past_start,
    'is_slots_filled', v_is_slots_filled,
    'reasons', v_reasons
  );
END;
$$;

-- 8. Diagnostics list for all jobs in database for the debug screen /dev/job-visibility
CREATE OR REPLACE FUNCTION public.get_all_jobs_visibility_diagnostics(
  p_worker_id UUID DEFAULT auth.uid(),
  p_worker_lat DOUBLE PRECISION DEFAULT NULL,
  p_worker_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_results JSONB := '[]'::jsonb;
  v_job RECORD;
  v_diag JSONB;
BEGIN
  FOR v_job IN 
    SELECT j.id
    FROM public.jobs j
    ORDER BY j.created_at DESC
  LOOP
    v_diag := public.get_job_visibility_diagnostic(p_worker_id, v_job.id, p_worker_lat, p_worker_lng);
    v_results := v_results || jsonb_build_array(v_diag);
  END LOOP;
  RETURN v_results;
END;
$$;

