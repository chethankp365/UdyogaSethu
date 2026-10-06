-- Migration: 0330_recommendations_fix.sql
-- Description: Fix recommended_jobs RPC columns (use home_location, avatar_path, and provider ratings)

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
  v_point extensions.geography;
  v_seeker_type TEXT := 'informal';
  v_daily_rate_paise BIGINT := 65000;
  v_hourly_rate_paise BIGINT := 10000;
  v_worker_rating NUMERIC := 4.5;
  v_working_days TEXT[] := '{}'::TEXT[];
  v_has_dl BOOLEAN := false;
  v_has_verified_badge BOOLEAN := false;
BEGIN
  -- Determine worker location point
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL AND p_lat <> 0 AND p_lng <> 0 THEN
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  ELSE
    SELECT p.home_location INTO v_point FROM public.profiles p WHERE p.id = p_worker_id;
    IF v_point IS NULL THEN
      -- Default Bengaluru city centre anchor for realistic distance calculation
      v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(77.5946, 12.9716), 4326)::extensions.geography;
    END IF;
  END IF;

  -- Load worker profile attributes
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
  WHERE wp.user_id = p_worker_id;

  -- Check verified driving licence in kyc_records
  IF NOT v_has_dl THEN
    SELECT EXISTS (
      SELECT 1 FROM public.kyc_records
      WHERE user_id = p_worker_id
        AND doc_type = 'driving_licence'
        AND status = 'verified'
    ) INTO v_has_dl;
  END IF;

  -- Check verified badge in worker_profiles
  IF NOT v_has_verified_badge THEN
    SELECT COALESCE(is_verified_badge, false)
    INTO v_has_verified_badge
    FROM public.worker_profiles
    WHERE user_id = p_worker_id;
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
      -- Skill match check
      EXISTS (
        SELECT 1 FROM public.worker_skills ws
        JOIN public.skills s ON ws.skill_id = s.id
        WHERE ws.user_id = p_worker_id
          AND (s.category_id = j.category_id OR j.title ILIKE '%' || (s.names->>'en') || '%')
      ) AS has_skill_match,
      -- Licence gate
      (COALESCE(sc.requires_licence, false) OR COALESCE((j.requirements->>'licence_required')::boolean, false)) AS req_dl,
      -- Verified only gate
      COALESCE((j.requirements->>'verified_only')::boolean, false) AS req_verified
    FROM public.jobs j
    LEFT JOIN public.service_categories sc ON j.category_id = sc.id
    LEFT JOIN public.profiles pr_p ON j.provider_id = pr_p.id
    LEFT JOIN public.provider_profiles pr ON j.provider_id = pr.user_id
    WHERE j.status = 'open'
      AND j.slots_filled < j.slots_total
      -- Radius check when location is provided
      AND (j.location IS NULL OR p_radius_m <= 0 OR extensions.ST_DWithin(j.location, v_point, p_radius_m))
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
        SELECT 'Skill Match' AS r WHERE sj.has_skill_match
        UNION ALL
        SELECT CASE
          WHEN sj.dist_m <= 2000 THEN 'Near you (' || ROUND((sj.dist_m / 1000)::numeric, 1) || ' km)'
          WHEN sj.dist_m <= 5000 THEN 'Nearby (' || ROUND((sj.dist_m / 1000)::numeric, 1) || ' km)'
          ELSE ROUND((sj.dist_m / 1000)::numeric, 1) || ' km away'
        END AS r
        UNION ALL
        SELECT 'Students Welcome 🎓' AS r WHERE v_seeker_type = 'student' AND sj.stu_ok
        UNION ALL
        SELECT 'Flexible Shift ⏰' AS r WHERE sj.flex_shift
        UNION ALL
        SELECT 'Good Wage (₹' || (sj.wage_paise / 100) || ')' AS r WHERE sj.wage_paise >= v_daily_rate_paise
        UNION ALL
        SELECT 'Top Employer ⭐' AS r WHERE sj.emp_rating >= 4.7
      ) reasons_table
    ) AS reasons
  FROM scored_jobs sj
  WHERE
    -- Enforce licence gate
    (NOT sj.req_dl OR v_has_dl)
    -- Enforce verified-only gate
    AND (NOT sj.req_verified OR v_has_verified_badge)
  ORDER BY
    score DESC,
    distance_m ASC,
    sj.start_at ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
