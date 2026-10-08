-- Migration: 0410_fix_polish_p4.sql
-- Description: Fix and polish step for P4.1 to P4.6:
--              1. Fix is_verified_badge resolution (worker badge from worker_profiles, provider verified from KYC / ratings / is_verified_badge).
--              2. Add jobs.suitable_for seeker_type[] and jobs.is_demo boolean.
--              3. Exclude is_demo jobs from worker-facing queries (recommended_jobs, nearby_jobs, apply_to_job).
--              4. Enforce strict suitable_for matching across recommended_jobs, nearby_jobs, apply_to_job, and request_worker.
--              5. Provider Hub cleanup: exclude logged-in user in nearby_workers, only real workers, real distance, fix active booking.

-- ============================================================================
-- 1. Schema Extensions: suitable_for, is_demo, provider_profiles.is_verified_badge
-- ============================================================================
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS suitable_for public.seeker_type[] NOT NULL DEFAULT '{informal,student,part_time}'::public.seeker_type[],
  ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.jobs.suitable_for IS 'Target worker categories (informal, student, part_time) suitable for this job.';
COMMENT ON COLUMN public.jobs.is_demo IS 'Flag indicating demo/seed jobs that must be excluded from real worker queries.';

ALTER TABLE public.provider_profiles
  ADD COLUMN IF NOT EXISTS is_verified_badge BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.provider_profiles.is_verified_badge IS 'Server-computed or admin-approved verified badge for job providers/employers.';

-- Backfill existing real jobs so none disappear
UPDATE public.jobs
SET suitable_for = ARRAY['informal'::public.seeker_type, 'student'::public.seeker_type, 'part_time'::public.seeker_type]
WHERE suitable_for IS NULL OR array_length(suitable_for, 1) IS NULL;

-- Mark existing P1.7 demo seed jobs as is_demo = true
UPDATE public.jobs
SET is_demo = true
WHERE provider_id IN (SELECT user_id FROM public.demo_users)
   OR provider_id IN ('33333333-3333-4333-8333-333333333301', '33333333-3333-4333-8333-333333333302', '33333333-3333-4333-8333-333333333303')
   OR id IN (
     '11111111-1111-4111-8111-111111111101',
     '11111111-1111-4111-8111-111111111102',
     '11111111-1111-4111-8111-111111111103',
     '11111111-1111-4111-8111-111111111104',
     '11111111-1111-4111-8111-111111111105'
   );

CREATE INDEX IF NOT EXISTS idx_jobs_suitable_for ON public.jobs USING GIN (suitable_for);
CREATE INDEX IF NOT EXISTS idx_jobs_is_demo ON public.jobs (is_demo);

-- Helper function: check if provider is verified
CREATE OR REPLACE FUNCTION public.is_provider_verified(p_provider_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_verified BOOLEAN := false;
BEGIN
  IF p_provider_id IS NULL THEN
    RETURN false;
  END IF;

  SELECT (
    COALESCE(pp.is_verified_badge, false)
    OR COALESCE(pp.rating_avg, 0.0) >= 4.0
    OR EXISTS (
      SELECT 1 FROM public.kyc_records kr
      WHERE kr.user_id = p_provider_id AND kr.status = 'verified'
    )
  ) INTO v_verified
  FROM public.profiles p
  LEFT JOIN public.provider_profiles pp ON pp.user_id = p.id
  WHERE p.id = p_provider_id;

  RETURN COALESCE(v_verified, false);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.is_provider_verified(UUID) TO authenticated, anon;

-- ============================================================================
-- 2. Fixed recommended_jobs RPC
-- ============================================================================
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
  v_caller_id UUID;
  v_effective_id UUID;
  v_seeker_type TEXT := 'informal';
  v_daily_rate_paise BIGINT := 65000;
  v_hourly_rate_paise BIGINT := 10000;
  v_worker_rating NUMERIC := 4.5;
  v_working_days TEXT[] := '{}'::TEXT[];
  v_has_dl BOOLEAN := false;
  v_has_verified_badge BOOLEAN := false;
BEGIN
  -- 1. Identify caller priority: auth.uid() first, fallback to p_worker_id
  v_caller_id := auth.uid();
  IF v_caller_id IS NOT NULL THEN
    v_effective_id := v_caller_id;
  ELSE
    v_effective_id := p_worker_id;
  END IF;

  -- 2. Determine worker location point
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL AND p_lat <> 0 AND p_lng <> 0 THEN
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  ELSE
    -- Use home_location from profiles (NOT location which belongs to jobs)
    SELECT p.home_location INTO v_point FROM public.profiles p WHERE p.id = v_effective_id;
    IF v_point IS NULL THEN
      -- Default Bengaluru city centre anchor
      v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(77.5946, 12.9716), 4326)::extensions.geography;
    END IF;
  END IF;

  -- 3. Load worker profile attributes and derive seeker_type
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

  -- 4. Check verified driving licence in kyc_records
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
      COALESCE(pr.org_name, pr_p.full_name, 'Local Employer') AS emp_name,
      pr_p.avatar_path AS emp_avatar,
      -- Provider verified tick from real provider status
      public.is_provider_verified(j.provider_id) AS emp_verified,
      COALESCE(pr.rating_avg, 4.8) AS emp_rating,
      sc.names AS cat_names,
      COALESCE(sc.icon, 'work') AS cat_icon,
      COALESCE(sc.slug, 'general') AS cat_slug,
      sc.audience AS cat_audience,
      (v_seeker_type = 'student' OR COALESCE((j.requirements->>'students_ok')::boolean, false)) AS stu_ok,
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
      -- Exclude demo seed jobs
      AND j.is_demo = false
      AND (j.location IS NULL OR p_radius_m <= 0 OR extensions.ST_DWithin(j.location, v_point, p_radius_m))
      -- STRICT AUDIENCE GATING BY jobs.suitable_for:
      AND (
        v_seeker_type::public.seeker_type = ANY(j.suitable_for)
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
-- 3. Fixed nearby_jobs RPC
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

  -- Derive caller seeker type from auth.uid()
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
    COALESCE(pr.org_name, pr_p.full_name, 'Local Employer') AS employer_name,
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
    -- Exclude demo jobs
    AND j.is_demo = false
    AND (j.location IS NOT NULL AND extensions.ST_DWithin(j.location, v_point, p_radius_m))
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
-- 4. Fixed nearby_workers RPC (exclude provider caller, real distance, only seekers)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.nearby_workers(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 20000,
  p_seeker_type public.seeker_type DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_language TEXT DEFAULT NULL,
  p_availability TEXT DEFAULT NULL,
  p_min_rate_paise BIGINT DEFAULT NULL,
  p_max_rate_paise BIGINT DEFAULT NULL,
  p_gender TEXT DEFAULT NULL,
  p_min_rating NUMERIC DEFAULT NULL,
  p_min_jobs_completed INT DEFAULT NULL,
  p_verified_only BOOLEAN DEFAULT false,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  avatar_path TEXT,
  headline TEXT,
  bio TEXT,
  seeker_type public.seeker_type,
  hourly_rate_paise BIGINT,
  daily_rate_paise BIGINT,
  rating_avg NUMERIC(3,2),
  rating_count INT,
  jobs_completed INT,
  is_verified_badge BOOLEAN,
  distance_m DOUBLE PRECISION,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  languages TEXT[],
  skills JSONB,
  availability TEXT,
  gender TEXT,
  experience_years NUMERIC
) AS $$
DECLARE
  v_point extensions.geography;
  v_caller_id UUID;
BEGIN
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  v_caller_id := auth.uid();

  RETURN QUERY
  SELECT
    wp.user_id,
    p.full_name,
    p.avatar_path,
    COALESCE(wp.headline, 'Skilled Worker'),
    COALESCE(wp.bio, ''),
    wp.seeker_type,
    wp.hourly_rate_paise,
    wp.daily_rate_paise,
    COALESCE(wp.rating_avg, 0.00),
    COALESCE(wp.rating_count, 0),
    COALESCE(wp.jobs_completed, 0),
    COALESCE(wp.is_verified_badge, false),
    CASE 
      WHEN p.home_location IS NOT NULL THEN extensions.ST_Distance(p.home_location, v_point)
      ELSE NULL
    END AS distance_m,
    CASE 
      WHEN p.home_location IS NOT NULL THEN extensions.ST_Y(p.home_location::extensions.geometry)
      ELSE NULL
    END AS lat,
    CASE 
      WHEN p.home_location IS NOT NULL THEN extensions.ST_X(p.home_location::extensions.geometry)
      ELSE NULL
    END AS lng,
    COALESCE(
      (SELECT array_agg(u::text) FROM unnest(wp.languages) u),
      ARRAY[p.language::text]
    ) AS languages,
    COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', s.id,
        'name', COALESCE(s.names->>'en', s.names->>'kn', 'Skill'),
        'category_id', s.category_id,
        'category_name', COALESCE(sc.names->>'en', sc.names->>'kn', 'General')
      ))
      FROM public.worker_skills ws
      JOIN public.skills s ON s.id = ws.skill_id
      LEFT JOIN public.service_categories sc ON sc.id = s.category_id
      WHERE ws.user_id = wp.user_id
    ), '[]'::jsonb) AS skills,
    wp.availability::text,
    p.gender,
    COALESCE(wp.experience_years, 0)
  FROM public.worker_profiles wp
  JOIN public.profiles p ON wp.user_id = p.id
  WHERE p.is_suspended = false
    AND wp.availability != 'offline'
    -- Exclude caller (e.g. logged-in provider)
    AND (v_caller_id IS NULL OR wp.user_id <> v_caller_id)
    -- Must have seeker role
    AND EXISTS (
      SELECT 1 FROM public.user_roles ur
      WHERE ur.user_id = wp.user_id AND ur.role = 'seeker'
    )
    -- Location filter if location exists; if home_location is null, allow within reasonable search when no coords
    AND (
      p.home_location IS NULL 
      OR extensions.ST_DWithin(p.home_location, v_point, p_radius_m)
    )
    -- Seeker Type filter
    AND (p_seeker_type IS NULL OR wp.seeker_type = p_seeker_type)
    -- Category filter (via worker_skills)
    AND (p_category_id IS NULL OR EXISTS (
      SELECT 1 FROM public.worker_skills ws
      JOIN public.skills s ON s.id = ws.skill_id
      WHERE ws.user_id = wp.user_id AND s.category_id = p_category_id
    ))
    -- Language filter
    AND (
      p_language IS NULL 
      OR p_language = '' 
      OR p_language = 'all'
      OR (wp.languages IS NOT NULL AND p_language = ANY(SELECT unnest(wp.languages)::text))
      OR (p.language::text = p_language)
    )
    -- Availability filter
    AND (
      p_availability IS NULL 
      OR p_availability = '' 
      OR p_availability = 'all' 
      OR wp.availability::text = p_availability
    )
    -- Rate Range filter
    AND (
      p_min_rate_paise IS NULL 
      OR COALESCE(wp.daily_rate_paise, wp.hourly_rate_paise * 8, 0) >= p_min_rate_paise
    )
    AND (
      p_max_rate_paise IS NULL 
      OR COALESCE(wp.daily_rate_paise, wp.hourly_rate_paise * 8, 99999999) <= p_max_rate_paise
    )
    -- Gender preference
    AND (
      p_gender IS NULL 
      OR p_gender = '' 
      OR p_gender = 'any' 
      OR p.gender = p_gender
    )
    -- Minimum rating
    AND (p_min_rating IS NULL OR wp.rating_avg >= p_min_rating)
    -- Minimum completed jobs
    AND (p_min_jobs_completed IS NULL OR wp.jobs_completed >= p_min_jobs_completed)
    -- Verified only
    AND (p_verified_only = false OR wp.is_verified_badge = true)
    -- Text search query
    AND (
      p_search_query IS NULL 
      OR p_search_query = '' 
      OR p.full_name ILIKE '%' || p_search_query || '%' 
      OR wp.headline ILIKE '%' || p_search_query || '%'
      OR wp.bio ILIKE '%' || p_search_query || '%'
    )
  ORDER BY 
    CASE WHEN p.home_location IS NOT NULL THEN extensions.ST_Distance(p.home_location, v_point) ELSE 999999 END ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.nearby_workers TO authenticated, anon;

-- ============================================================================
-- 5. Fixed get_job_detail & check_job_eligibility
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_job_detail(
  p_job_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_res JSONB;
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
    'is_demo', j.is_demo
  )
  INTO v_res
  FROM public.jobs j
  LEFT JOIN public.profiles p ON p.id = j.provider_id
  LEFT JOIN public.provider_profiles pp ON pp.user_id = j.provider_id
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  RETURN v_res;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_job_detail(UUID) TO authenticated, anon;

CREATE OR REPLACE FUNCTION public.check_job_eligibility(
  p_job_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_worker_id UUID;
  v_seeker_type TEXT;
  v_has_dl BOOLEAN;
  v_is_verified BOOLEAN;
  v_job RECORD;
  v_reasons TEXT[] := '{}';
  v_eligible BOOLEAN := true;
BEGIN
  v_worker_id := auth.uid();
  IF v_worker_id IS NULL THEN
    RETURN jsonb_build_object(
      'is_eligible', false,
      'reasons', ARRAY['Authentication required.']::TEXT[]
    );
  END IF;

  -- 1. Fetch worker profile details
  SELECT COALESCE(wp.seeker_type::text, 'informal'),
         COALESCE(wp.has_driving_licence, false),
         COALESCE(wp.is_verified_badge, false)
  INTO v_seeker_type, v_has_dl, v_is_verified
  FROM public.profiles p
  LEFT JOIN public.worker_profiles wp ON wp.user_id = p.id
  WHERE p.id = v_worker_id;

  -- 2. Fetch job details
  SELECT j.*, sc.names AS category_names, sc.slug AS category_slug
  INTO v_job
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  IF v_job.id IS NULL THEN
    RETURN jsonb_build_object('is_eligible', false, 'reasons', ARRAY['Job not found.']::TEXT[]);
  END IF;

  -- 3. Check suitable_for
  IF NOT (v_seeker_type::public.seeker_type = ANY(v_job.suitable_for)) THEN
    v_eligible := false;
    v_reasons := array_append(v_reasons, 'This job is reserved for other worker categories (' || array_to_string(v_job.suitable_for, ', ') || ').');
  END IF;

  -- 4. Driving licence check
  IF (v_job.requirements->>'licence_required')::boolean = true AND NOT v_has_dl THEN
    v_eligible := false;
    v_reasons := array_append(v_reasons, 'Valid driving licence required for this job.');
  END IF;

  -- 5. Verified-only check
  IF (v_job.requirements->>'verified_only')::boolean = true AND NOT v_is_verified THEN
    v_eligible := false;
    v_reasons := array_append(v_reasons, 'UdyogaSethu Verified badge required.');
  END IF;

  RETURN jsonb_build_object(
    'is_eligible', v_eligible,
    'reasons', v_reasons,
    'seeker_type', v_seeker_type,
    'has_driving_licence', v_has_dl,
    'is_verified', v_is_verified
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.check_job_eligibility(UUID) TO authenticated;

-- ============================================================================
-- 6. Enhanced apply_to_job RPC with strict suitable_for enforcement
-- ============================================================================
CREATE OR REPLACE FUNCTION public.apply_to_job(
  p_job_id UUID,
  p_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_worker_id UUID;
  v_seeker_type TEXT := 'informal';
  v_job RECORD;
  v_app_id UUID;
BEGIN
  v_worker_id := auth.uid();
  IF v_worker_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to apply for jobs.' USING ERRCODE = '42501';
  END IF;

  -- 1. Derive seeker type from profile
  SELECT COALESCE(wp.seeker_type::text, 'informal') INTO v_seeker_type
  FROM public.profiles p
  LEFT JOIN public.worker_profiles wp ON wp.user_id = p.id
  WHERE p.id = v_worker_id;

  IF v_seeker_type IS NULL THEN
    v_seeker_type := 'informal';
  END IF;

  -- 2. Fetch job state
  SELECT j.*
  INTO v_job
  FROM public.jobs j
  WHERE j.id = p_job_id;

  IF v_job.id IS NULL THEN
    RAISE EXCEPTION 'Job not found.' USING ERRCODE = 'P0002';
  END IF;

  IF v_job.is_demo = true THEN
    RAISE EXCEPTION 'Demo jobs do not accept applications.' USING ERRCODE = 'P0005';
  END IF;

  IF v_job.status <> 'open' OR v_job.slots_filled >= v_job.slots_total THEN
    RAISE EXCEPTION 'This job is no longer accepting applications.' USING ERRCODE = 'P0003';
  END IF;

  -- 3. Strict Audience check (suitable_for)
  IF NOT (v_seeker_type::public.seeker_type = ANY(v_job.suitable_for)) THEN
    RAISE EXCEPTION 'This job is not suitable for your worker category (%s).', v_seeker_type USING ERRCODE = 'P0004';
  END IF;

  -- 4. Check if already applied
  IF EXISTS (SELECT 1 FROM public.job_applications WHERE job_id = p_job_id AND worker_id = v_worker_id) THEN
    SELECT id INTO v_app_id FROM public.job_applications WHERE job_id = p_job_id AND worker_id = v_worker_id LIMIT 1;
    RETURN v_app_id;
  END IF;

  -- 5. Insert new application
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
-- 7. Provider Job Posting RPCs with suitable_for
-- ============================================================================
-- Drop old 15-arg versions to prevent overload ambiguity
DROP FUNCTION IF EXISTS public.post_provider_job(UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT);
DROP FUNCTION IF EXISTS public.update_provider_job(UUID, UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT);

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
  p_suitable_for TEXT[] DEFAULT ARRAY['informal', 'student', 'part_time']
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
    COALESCE(p_requirements, '{"verified_only": false, "licence_required": false, "students_ok": true}'::jsonb),
    v_loc,
    p_address_text,
    COALESCE(p_geofence_radius_m, 150),
    v_suitable,
    false,
    'open'
  )
  RETURNING id INTO v_job_id;

  RETURN v_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.post_provider_job(UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[]) TO authenticated;

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
  p_suitable_for TEXT[] DEFAULT ARRAY['informal', 'student', 'part_time']
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
    est_duration_minutes = COALESCE(p_est_duration_minutes, 480),
    start_at = p_start_at,
    slots_total = GREATEST(COALESCE(p_slots_total, 1), 1),
    materials_provided = COALESCE(p_materials_provided, false),
    payment_mode = p_payment_mode,
    requirements = COALESCE(p_requirements, requirements),
    location = COALESCE(v_loc, location),
    address_text = COALESCE(p_address_text, address_text),
    geofence_radius_m = COALESCE(p_geofence_radius_m, 150),
    suitable_for = v_suitable,
    updated_at = NOW()
  WHERE id = p_job_id
    AND provider_id = v_provider_id
    AND status IN ('open', 'draft');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found or cannot be edited.';
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.update_provider_job(UUID, UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[]) TO authenticated;

-- ============================================================================
-- 8. Enhanced request_worker with validation and suitable_for binding
-- ============================================================================
-- Drop older signatures of request_worker to eliminate overload ambiguity
DROP FUNCTION IF EXISTS public.request_worker(UUID, UUID, TEXT, TIMESTAMPTZ, INT, BIGINT, TEXT, extensions.geography, TEXT, TIME);
DROP FUNCTION IF EXISTS public.request_worker(UUID, UUID, TEXT, TIMESTAMPTZ, INT, BIGINT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, BOOLEAN, public.payment_mode, TEXT, TIME);

CREATE OR REPLACE FUNCTION public.request_worker(
  p_worker_id UUID,
  p_category_id UUID,
  p_title TEXT,
  p_start_at TIMESTAMPTZ,
  p_est_duration_minutes INT,
  p_agreed_wage_paise BIGINT,
  p_address_text TEXT,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_protection_selected BOOLEAN,
  p_payment_mode public.payment_mode DEFAULT 'escrow',
  p_recurring_rule TEXT DEFAULT NULL,
  p_preferred_time TIME DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_provider_id UUID;
  v_job_id UUID;
  v_assignment_id UUID;
  v_recurring_id UUID;
  v_code TEXT;
  v_end_at TIMESTAMPTZ;
  v_conflict_count INT;
  v_geom extensions.geography(Point, 4326) := NULL;
  v_provider_name TEXT;
  v_worker_type public.seeker_type;
  v_worker_avail TEXT;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.' USING ERRCODE = '42501';
  END IF;

  IF v_provider_id = p_worker_id THEN
    RAISE EXCEPTION 'Cannot book your own profile.' USING ERRCODE = 'P4002';
  END IF;

  -- 1. Validate worker profile, category and availability
  SELECT wp.seeker_type, wp.availability::text
  INTO v_worker_type, v_worker_avail
  FROM public.worker_profiles wp
  WHERE wp.user_id = p_worker_id;

  IF v_worker_type IS NULL THEN
    RAISE EXCEPTION 'Selected user is not registered as a worker.' USING ERRCODE = 'P4003';
  END IF;

  IF v_worker_avail = 'offline' THEN
    RAISE EXCEPTION 'Worker is currently offline and not accepting direct bookings.' USING ERRCODE = 'P4004';
  END IF;

  v_end_at := p_start_at + (COALESCE(p_est_duration_minutes, 480) || ' minutes')::interval;

  -- 2. DOUBLE-BOOKING CHECK
  SELECT COUNT(*) INTO v_conflict_count
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.worker_id = p_worker_id
    AND ja.status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified')
    AND tstzrange(j.start_at, j.start_at + (COALESCE(j.est_duration_minutes, 480) || ' minutes')::interval) && tstzrange(p_start_at, v_end_at);

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'Worker is already booked for this time window. Please choose another slot.'
      USING ERRCODE = 'P4001';
  END IF;

  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_geom := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  END IF;

  -- 3. Create direct booking job with suitable_for bound to worker's type
  INSERT INTO public.jobs (
    provider_id, category_id, title, wage_type, wage_paise,
    est_duration_minutes, start_at, slots_total, slots_filled,
    payment_mode, address_text, location,
    suitable_for, is_demo,
    source, status
  ) VALUES (
    v_provider_id, p_category_id, p_title, 'fixed', p_agreed_wage_paise,
    p_est_duration_minutes, p_start_at, 1, 1,
    p_payment_mode, p_address_text, v_geom,
    ARRAY[v_worker_type], false,
    'direct_booking', 'filled'
  ) RETURNING id INTO v_job_id;

  v_code := 'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6));

  -- 4. Insert assignment with protection_selected
  INSERT INTO public.job_assignments (
    job_id, worker_id, booking_code, agreed_wage_paise,
    protection_selected, status
  ) VALUES (
    v_job_id, p_worker_id, v_code, p_agreed_wage_paise,
    p_protection_selected, 'requested'
  ) RETURNING id INTO v_assignment_id;

  -- 5. Log assignment event
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
  VALUES (
    v_assignment_id,
    'requested',
    v_provider_id,
    jsonb_build_object(
      'direct_booking', true,
      'protection_selected', p_protection_selected,
      'payment_mode', p_payment_mode::text,
      'recurring_rule', p_recurring_rule
    )
  );

  -- 6. Recurring booking if requested
  IF p_recurring_rule IS NOT NULL AND TRIM(p_recurring_rule) <> '' THEN
    INSERT INTO public.recurring_bookings (
      provider_id, worker_id, category_id,
      schedule_rule, preferred_time, status
    ) VALUES (
      v_provider_id, p_worker_id, p_category_id,
      p_recurring_rule, COALESCE(p_preferred_time, p_start_at::time), 'active'
    ) RETURNING id INTO v_recurring_id;
  END IF;

  -- 7. Notify the worker
  SELECT full_name INTO v_provider_name FROM public.profiles WHERE id = v_provider_id;
  INSERT INTO public.notifications (
    user_id, title, body, type, data
  ) VALUES (
    p_worker_id,
    'New Direct Booking Request',
    COALESCE(v_provider_name, 'A client') || ' has requested your services for ' || p_title || '.',
    'booking_requested',
    jsonb_build_object('assignment_id', v_assignment_id, 'job_id', v_job_id, 'booking_code', v_code)
  );

  RETURN jsonb_build_object(
    'assignment_id', v_assignment_id,
    'job_id', v_job_id,
    'booking_code', v_code,
    'status', 'requested',
    'protection_selected', p_protection_selected,
    'recurring_id', v_recurring_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.request_worker(UUID, UUID, TEXT, TIMESTAMPTZ, INT, BIGINT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, BOOLEAN, public.payment_mode, TEXT, TIME) TO authenticated;

-- ============================================================================
-- 9. Fixed get_provider_active_booking (worker_verified from worker_profiles)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_provider_active_booking(
  p_provider_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_prov_id UUID := COALESCE(p_provider_id, auth.uid());
  v_res JSONB;
BEGIN
  IF v_prov_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_build_object(
    'assignment_id', ja.id,
    'job_id', j.id,
    'booking_code', ja.booking_code,
    'job_title', j.title,
    'role_name', COALESCE(sc.names->>'en', sc.names->>'kn', 'Worker'),
    'worker_id', ja.worker_id,
    'worker_name', COALESCE(p.full_name, 'Assigned Worker'),
    'worker_avatar', p.avatar_path,
    'worker_verified', COALESCE(wp.is_verified_badge, false),
    'address_text', COALESCE(j.address_text, 'Site Address'),
    'scheduled_start', COALESCE(j.start_at, ja.created_at),
    'scheduled_end', COALESCE(j.start_at + (COALESCE(j.est_duration_minutes, 480) || ' minutes')::INTERVAL, ja.created_at + INTERVAL '8 hours'),
    'escrow_wage_paise', COALESCE(ja.agreed_wage_paise, j.wage_paise, 0),
    'status', ja.status::text,
    'arrived_at', ja.arrived_at,
    'is_worker_late', (COALESCE(j.start_at, ja.created_at) <= NOW() AND ja.arrived_at IS NULL)
  )
  INTO v_res
  FROM public.job_assignments ja
  JOIN public.jobs j ON j.id = ja.job_id
  JOIN public.profiles p ON p.id = ja.worker_id
  LEFT JOIN public.worker_profiles wp ON wp.user_id = ja.worker_id
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.provider_id = v_prov_id
    AND ja.status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified')
  ORDER BY ja.created_at DESC
  LIMIT 1;

  RETURN v_res;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_provider_active_booking(UUID) TO authenticated;
