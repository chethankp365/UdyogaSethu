-- Migration: 0350_audience_and_jobs_rules.sql
-- Description: Enforces strict audience rules (D-AUDIENCE) across recommended_jobs, nearby_jobs,
--              and apply_to_job RPCs; aligns consent_logs RPCs with real schema; fixes admin_settings.

-- 1. Ensure admin_settings seed uses correct columns (key, value)
INSERT INTO public.admin_settings (key, value)
VALUES ('qr_expiry_seconds', '300'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 2. Aligned Consent Logs RPCs matching actual consent_logs schema (id, user_id, purpose, granted, version, created_at)
CREATE OR REPLACE FUNCTION public.get_user_consents()
RETURNS TABLE (
  purpose TEXT,
  granted BOOLEAN,
  version TEXT,
  created_at TIMESTAMPTZ
) AS $$
  SELECT DISTINCT ON (cl.purpose)
    cl.purpose::TEXT,
    cl.granted,
    cl.version,
    cl.created_at
  FROM public.consent_logs cl
  WHERE cl.user_id = auth.uid()
  ORDER BY cl.purpose, cl.created_at DESC;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_user_consents() TO authenticated;

CREATE OR REPLACE FUNCTION public.record_user_consent_v2(
  p_purpose TEXT,
  p_granted BOOLEAN,
  p_version TEXT DEFAULT '1.0'
)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID;
  v_purpose_enum public.consent_purpose;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to record consent.';
  END IF;

  v_purpose_enum := p_purpose::public.consent_purpose;

  INSERT INTO public.consent_logs (user_id, purpose, granted, version, created_at)
  VALUES (v_user_id, v_purpose_enum, p_granted, p_version, NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.record_user_consent_v2(TEXT, BOOLEAN, TEXT) TO authenticated;

-- 3. Strict Audience Gating in apply_to_job
CREATE OR REPLACE FUNCTION public.apply_to_job(
  p_job_id UUID,
  p_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_worker_id UUID;
  v_seeker_type TEXT := 'informal';
  v_job_status public.job_status;
  v_slots_total INT;
  v_slots_filled INT;
  v_cat_audience TEXT[];
  v_app_id UUID;
BEGIN
  v_worker_id := auth.uid();
  IF v_worker_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to apply for jobs.' USING ERRCODE = '42501';
  END IF;

  -- 1. Derive seeker type
  SELECT COALESCE(s.st, 'informal') INTO v_seeker_type
  FROM (
    SELECT seeker_type::text AS st FROM public.seeker_profiles WHERE user_id = v_worker_id
    UNION ALL
    SELECT seeker_type::text AS st FROM public.worker_profiles WHERE user_id = v_worker_id
    LIMIT 1
  ) s;
  IF v_seeker_type IS NULL THEN
    v_seeker_type := 'informal';
  END IF;

  -- 2. Fetch job state and category audience
  SELECT j.status, j.slots_total, j.slots_filled, sc.audience
  INTO v_job_status, v_slots_total, v_slots_filled, v_cat_audience
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  IF v_job_status IS NULL THEN
    RAISE EXCEPTION 'Job not found.' USING ERRCODE = 'P0002';
  END IF;

  IF v_job_status <> 'open' OR v_slots_filled >= v_slots_total THEN
    RAISE EXCEPTION 'This job is no longer accepting applications.' USING ERRCODE = 'P0003';
  END IF;

  -- 3. Strict Audience check (D-AUDIENCE)
  IF v_cat_audience IS NOT NULL AND cardinality(v_cat_audience) > 0 THEN
    IF v_seeker_type IN ('student', 'part_time') THEN
      IF NOT (v_cat_audience && ARRAY['student', 'part_time']::TEXT[]) THEN
        RAISE EXCEPTION 'This job is reserved for trade and informal workers.' USING ERRCODE = 'P0004';
      END IF;
    ELSE
      -- Informal worker
      IF NOT (v_cat_audience @> ARRAY['informal']::TEXT[]) THEN
        RAISE EXCEPTION 'This job is reserved for student or part-time workers.' USING ERRCODE = 'P0004';
      END IF;
    END IF;
  END IF;

  -- 4. Check if already applied
  IF EXISTS (SELECT 1 FROM public.job_applications WHERE job_id = p_job_id AND worker_id = v_worker_id) THEN
    SELECT id INTO v_app_id FROM public.job_applications WHERE job_id = p_job_id AND worker_id = v_worker_id LIMIT 1;
    RETURN v_app_id;
  END IF;

  -- 5. Insert application
  INSERT INTO public.job_applications (job_id, worker_id, message, status)
  VALUES (p_job_id, v_worker_id, p_message, 'applied')
  RETURNING id INTO v_app_id;

  RETURN v_app_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.apply_to_job(UUID, TEXT) TO authenticated;

-- 4. Strict Audience Gating in recommended_jobs RPC
CREATE OR REPLACE FUNCTION public.recommended_jobs(
  p_worker_id UUID,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_radius_m DOUBLE PRECISION DEFAULT 50000
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
  v_effective_id UUID;
  v_point extensions.geography;
  v_seeker_type TEXT := 'informal';
  v_daily_rate_paise BIGINT := 65000;
  v_hourly_rate_paise BIGINT := 10000;
  v_worker_rating NUMERIC := 4.5;
  v_working_days TEXT[] := '{}'::TEXT[];
  v_has_dl BOOLEAN := false;
  v_has_verified_badge BOOLEAN := false;
BEGIN
  v_effective_id := COALESCE(auth.uid(), p_worker_id);

  -- Determine worker location point
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL AND p_lat <> 0 AND p_lng <> 0 THEN
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  ELSE
    SELECT p.home_location INTO v_point FROM public.profiles p WHERE p.id = v_effective_id;
    IF v_point IS NULL THEN
      -- Default Bengaluru anchor
      v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(77.5946, 12.9716), 4326)::extensions.geography;
    END IF;
  END IF;

  -- Derive seeker type strictly from profiles (auth.uid() first)
  SELECT COALESCE(s.st, 'informal') INTO v_seeker_type
  FROM (
    SELECT seeker_type::text AS st FROM public.seeker_profiles WHERE user_id = v_effective_id
    UNION ALL
    SELECT seeker_type::text AS st FROM public.worker_profiles WHERE user_id = v_effective_id
    LIMIT 1
  ) s;
  IF v_seeker_type IS NULL THEN
    v_seeker_type := 'informal';
  END IF;

  -- Load worker profile attributes
  SELECT
    COALESCE(wp.daily_rate_paise, 65000),
    COALESCE(wp.hourly_rate_paise, 10000),
    COALESCE(wp.rating_avg, 4.5),
    COALESCE(wp.working_days, '{}'::TEXT[]),
    COALESCE(wp.has_driving_licence, false),
    COALESCE(wp.is_verified_badge, false)
  INTO
    v_daily_rate_paise,
    v_hourly_rate_paise,
    v_worker_rating,
    v_working_days,
    v_has_dl,
    v_has_verified_badge
  FROM public.worker_profiles wp
  WHERE wp.user_id = v_effective_id;

  -- Check verified driving licence in kyc_records
  IF NOT v_has_dl THEN
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
      COALESCE(pr.org_name, pr_p.full_name, 'Local Employer') AS emp_name,
      pr_p.avatar_path AS emp_avatar,
      COALESCE(pr.rating_avg >= 4.0, true) AS emp_verified,
      COALESCE(pr.rating_avg, 4.8) AS emp_rating,
      sc.names AS cat_names,
      COALESCE(sc.icon, 'work') AS cat_icon,
      COALESCE(sc.slug, 'general') AS cat_slug,
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
      AND (j.location IS NULL OR p_radius_m <= 0 OR extensions.ST_DWithin(j.location, v_point, p_radius_m))
      -- Strict Audience Gating (D-AUDIENCE): Trades NEVER to students; Student gigs NEVER to informal
      AND (
        sc.audience IS NULL OR
        (
          CASE 
            WHEN v_seeker_type IN ('student', 'part_time') THEN
              sc.audience && ARRAY['student', 'part_time']::TEXT[]
            ELSE
              sc.audience @> ARRAY['informal']::TEXT[]
          END
        )
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
    -- Calculate Score
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
      -- Type-specific boosting
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
    -- Construct explanation reasons
    (
      SELECT jsonb_agg(r)
      FROM (
        SELECT r FROM unnest(ARRAY[
          CASE WHEN v_seeker_type IN ('student', 'part_time') AND sj.stu_ok THEN 'Students Welcome 🎓' ELSE NULL END,
          CASE WHEN v_seeker_type = 'part_time' AND sj.flex_shift THEN 'Flexible Shift ⏰' ELSE NULL END,
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

-- 5. Strict Audience Gating in nearby_jobs RPC
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
  v_caller_id := auth.uid();
  IF v_caller_id IS NOT NULL THEN
    SELECT COALESCE(s.st, 'informal') INTO v_seeker_type
    FROM (
      SELECT seeker_type::text AS st FROM public.seeker_profiles WHERE user_id = v_caller_id
      UNION ALL
      SELECT seeker_type::text AS st FROM public.worker_profiles WHERE user_id = v_caller_id
      LIMIT 1
    ) s;
    IF v_seeker_type IS NULL THEN
      v_seeker_type := 'informal';
    END IF;
  END IF;

  -- Build geography reference point
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL AND p_lat <> 0 AND p_lng <> 0 THEN
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  ELSE
    -- Default central anchor (Bengaluru) if null
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(77.5946, 12.9716), 4326)::extensions.geography;
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
    COALESCE(pp.org_name, p.full_name, 'Direct Employer') AS employer_name,
    COALESCE(p.avatar_path, '') AS employer_avatar,
    (COALESCE(pp.rating_avg, 0) >= 4.0 OR j.provider_id IS NOT NULL) AS employer_verified,
    COALESCE(pp.rating_avg, 4.8) AS employer_rating,
    sc.names AS category_name,
    COALESCE(sc.icon, 'work') AS category_icon,
    COALESCE(sc.slug, 'general') AS category_slug
  FROM public.jobs j
  LEFT JOIN public.profiles p ON p.id = j.provider_id
  LEFT JOIN public.provider_profiles pp ON pp.user_id = j.provider_id
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.status = 'open'
    AND j.location IS NOT NULL
    AND extensions.ST_DWithin(j.location, v_point, p_radius_m)
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    AND (p_min_wage_paise IS NULL OR j.wage_paise >= p_min_wage_paise)
    AND (p_max_wage_paise IS NULL OR j.wage_paise <= p_max_wage_paise)
    AND (
      p_search_query IS NULL 
      OR p_search_query = ''
      OR j.title ILIKE '%' || p_search_query || '%' 
      OR j.description ILIKE '%' || p_search_query || '%'
      OR j.address_text ILIKE '%' || p_search_query || '%'
    )
    -- Strict Audience Gating (D-AUDIENCE)
    AND (
      sc.audience IS NULL OR
      (
        CASE 
          WHEN v_seeker_type IN ('student', 'part_time') THEN
            sc.audience && ARRAY['student', 'part_time']::TEXT[]
          ELSE
            sc.audience @> ARRAY['informal']::TEXT[]
        END
      )
    )
  ORDER BY distance_m ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.nearby_jobs TO authenticated, anon;
