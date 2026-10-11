-- ============================================================================
-- Migration: 0653_privacy_and_debug_lockdown.sql
-- Description: Privacy and security lockdown:
--              1. Removes client INSERT and UPDATE on qr_tokens (SELECT only).
--              2. Revokes anon execution on worker discovery functions.
--              3. Masks phone and exact coordinates in get_worker_profile_detail
--                 for all callers except actively booked/hired employers.
--              4. Drops all public debug seed and simulation functions.
-- ============================================================================

-- 1. LOCK DOWN qr_tokens RLS (NO CLIENT INSERT OR UPDATE)
ALTER TABLE public.qr_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS qr_tokens_insert ON public.qr_tokens;
DROP POLICY IF EXISTS qr_tokens_update ON public.qr_tokens;
DROP POLICY IF EXISTS qr_tokens_delete ON public.qr_tokens;

-- Only SELECT is permitted for user's own tokens
DROP POLICY IF EXISTS qr_tokens_select ON public.qr_tokens;
CREATE POLICY qr_tokens_select ON public.qr_tokens FOR SELECT
USING ((user_id = auth.uid()) OR public.is_admin());

-- Revoke table modification grants from anon and authenticated
REVOKE INSERT, UPDATE, DELETE ON public.qr_tokens FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.qr_tokens TO authenticated;
GRANT ALL ON public.qr_tokens TO service_role;

-- 2. DROP DEBUG FUNCTIONS
DROP FUNCTION IF EXISTS public.simulate_training_status CASCADE;
DROP FUNCTION IF EXISTS public.debug_seed_overlapping_requests CASCADE;
DROP FUNCTION IF EXISTS public.set_ticket_timing_debug CASCADE;

-- 3. DROP OVERLOADS FOR WORKER DISCOVERY
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
      AND p.proname IN ('nearby_workers', 'get_worker_profile_detail')
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
  END LOOP;
END $$;

-- 4. PRIVACY-HARDENED nearby_workers (ONE version, real columns, NO phone/exact coords)
CREATE OR REPLACE FUNCTION public.nearby_workers(
  p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_radius_m DOUBLE PRECISION DEFAULT 50000,
  p_seeker_type public.seeker_type DEFAULT NULL, p_category_id UUID DEFAULT NULL,
  p_language TEXT DEFAULT NULL, p_availability TEXT DEFAULT NULL,
  p_min_rate_paise BIGINT DEFAULT NULL, p_max_rate_paise BIGINT DEFAULT NULL,
  p_gender TEXT DEFAULT NULL, p_min_rating NUMERIC DEFAULT NULL,
  p_min_jobs_completed INT DEFAULT NULL, p_verified_only BOOLEAN DEFAULT false,
  p_search_query TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
)
RETURNS TABLE (
  worker_id UUID, full_name TEXT, avatar_path TEXT, seeker_type TEXT,
  hourly_rate_paise BIGINT, daily_rate_paise BIGINT, rating_avg NUMERIC,
  rating_count INT, jobs_completed INT, is_verified_badge BOOLEAN,
  distance_m DOUBLE PRECISION, headline TEXT, languages TEXT[]
) AS $$
DECLARE
  v_ref_point extensions.geography(Point, 4326);
BEGIN
  IF p_lat IS NULL OR p_lng IS NULL THEN RETURN; END IF;
  v_ref_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  RETURN QUERY
  SELECT
    p.id AS worker_id,
    -- Return display name, but never phone number
    p.full_name,
    p.avatar_path,
    COALESCE(wp.seeker_type::TEXT, 'informal')::TEXT AS seeker_type,
    wp.hourly_rate_paise,
    wp.daily_rate_paise,
    wp.rating_avg,
    COALESCE(wp.rating_count, 0)::INT AS rating_count,
    COALESCE(wp.jobs_completed, 0)::INT AS jobs_completed,
    COALESCE(wp.is_verified_badge, false) AS is_verified_badge,
    extensions.ST_Distance(v_ref_point, p.home_location) AS distance_m,
    wp.headline,
    COALESCE(wp.languages, ARRAY['kn']::TEXT[]) AS languages
  FROM public.worker_profiles wp
  JOIN public.profiles p ON wp.user_id = p.id
  WHERE p.is_suspended = false AND p.home_location IS NOT NULL
    AND extensions.ST_DWithin(v_ref_point, p.home_location, p_radius_m)
    AND (p_seeker_type IS NULL OR wp.seeker_type = p_seeker_type)
    AND (p_gender IS NULL OR p.gender = p_gender)
    AND (p_min_rating IS NULL OR wp.rating_avg >= p_min_rating)
    AND (p_min_jobs_completed IS NULL OR wp.jobs_completed >= p_min_jobs_completed)
    AND (NOT p_verified_only OR wp.is_verified_badge = true)
    AND (p_search_query IS NULL OR (p.full_name ILIKE '%' || p_search_query || '%' OR wp.headline ILIKE '%' || p_search_query || '%'))
  ORDER BY distance_m ASC LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 5. PRIVACY-HARDENED get_worker_profile_detail
-- Returns phone & exact location ONLY to the booked/hired party; masked otherwise.
CREATE OR REPLACE FUNCTION public.get_worker_profile_detail(
  p_worker_id UUID, p_caller_lat DOUBLE PRECISION DEFAULT NULL, p_caller_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID; v_is_booked BOOLEAN := false; v_p RECORD; v_wp RECORD;
  v_phone TEXT := NULL; v_addr TEXT := NULL; v_ref extensions.geography(Point, 4326) := NULL;
  v_dist DOUBLE PRECISION := NULL;
BEGIN
  v_uid := auth.uid();

  SELECT * INTO v_p FROM public.profiles WHERE id = p_worker_id;
  IF v_p.id IS NULL THEN RAISE EXCEPTION 'Worker not found.'; END IF;

  SELECT * INTO v_wp FROM public.worker_profiles WHERE user_id = p_worker_id;

  -- Check if caller is actively booked/hired employer
  IF v_uid IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.job_assignments ja
      JOIN public.jobs j ON ja.job_id = j.id
      WHERE ja.worker_id = p_worker_id AND j.provider_id = v_uid
        AND ja.status NOT IN ('cancelled', 'completed', 'payment_released')
    ) INTO v_is_booked;
  END IF;

  IF v_is_booked OR public.is_admin() THEN
    v_phone := v_p.phone;
    v_addr := v_p.home_address;
  ELSIF v_p.phone IS NOT NULL AND LENGTH(v_p.phone) >= 4 THEN
    v_phone := 'XXXXXX' || RIGHT(v_p.phone, 4);
    v_addr := COALESCE(v_p.city, 'Karnataka');
  END IF;

  IF p_caller_lat IS NOT NULL AND p_caller_lng IS NOT NULL AND v_p.home_location IS NOT NULL THEN
    v_ref := extensions.ST_SetSRID(extensions.ST_MakePoint(p_caller_lng, p_caller_lat), 4326)::extensions.geography;
    v_dist := extensions.ST_Distance(v_ref, v_p.home_location);
  END IF;

  RETURN jsonb_build_object(
    'user_id', v_p.id,
    'full_name', v_p.full_name,
    'avatar_path', v_p.avatar_path,
    'phone', v_phone,
    'home_address', v_addr,
    'city', v_p.city,
    'distance_m', v_dist,
    'seeker_type', COALESCE(v_wp.seeker_type::TEXT, 'informal'),
    'headline', v_wp.headline,
    'bio', v_wp.bio,
    'experience_years', v_wp.experience_years,
    'hourly_rate_paise', v_wp.hourly_rate_paise,
    'daily_rate_paise', v_wp.daily_rate_paise,
    'rating_avg', v_wp.rating_avg,
    'rating_count', COALESCE(v_wp.rating_count, 0),
    'jobs_completed', COALESCE(v_wp.jobs_completed, 0),
    'is_verified_badge', COALESCE(v_wp.is_verified_badge, false),
    'languages', COALESCE(v_wp.languages, ARRAY['kn']::TEXT[]),
    'skills', ARRAY(
      SELECT sk.names->>'en' FROM public.worker_skills ws
      JOIN public.skills sk ON ws.skill_id = sk.id
      WHERE ws.user_id = p_worker_id
    )
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 6. PERMISSIONS & GRANTS
-- Strictly revoke anon execution on worker profiles
REVOKE ALL ON FUNCTION public.nearby_workers(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, public.seeker_type, UUID, TEXT, TEXT, BIGINT, BIGINT, TEXT, NUMERIC, INT, BOOLEAN, TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.nearby_workers(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, public.seeker_type, UUID, TEXT, TEXT, BIGINT, BIGINT, TEXT, NUMERIC, INT, BOOLEAN, TEXT, INT, INT) TO authenticated;

REVOKE ALL ON FUNCTION public.get_worker_profile_detail(UUID, DOUBLE PRECISION, DOUBLE PRECISION) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_worker_profile_detail(UUID, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- Verification query
SELECT proname, pg_get_function_identity_arguments(oid) AS args
FROM pg_proc WHERE pronamespace = 'public'::regnamespace
  AND proname IN ('nearby_workers', 'get_worker_profile_detail');

NOTIFY pgrst, 'reload schema';
