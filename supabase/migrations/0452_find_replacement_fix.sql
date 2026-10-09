-- Migration: 0452_find_replacement_fix.sql
-- Description: Fix find_replacement to select explicit columns instead of positional j.* expansion.

CREATE OR REPLACE FUNCTION public.find_replacement(p_assignment_id UUID)
RETURNS TABLE (
  worker_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  rating NUMERIC,
  distance_meters DOUBLE PRECISION,
  jobs_completed INT,
  is_verified BOOLEAN,
  skills TEXT[]
) AS $$
DECLARE
  v_late_worker_id UUID;
  v_job_location extensions.geography;
  v_category_id UUID;
BEGIN
  -- Explicit named column selection to avoid positional shift bugs
  SELECT ja.worker_id, j.location, j.category_id
  INTO v_late_worker_id, v_job_location, v_category_id
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_assignment_id;

  IF v_late_worker_id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  RETURN QUERY
  WITH candidates AS (
    SELECT
      p.id AS c_worker_id,
      p.full_name AS c_full_name,
      p.avatar_path AS c_avatar_url,
      COALESCE(wp.rating_avg, 4.8)::NUMERIC AS c_rating,
      CASE
        WHEN v_job_location IS NOT NULL AND p.home_location IS NOT NULL
          THEN extensions.ST_Distance(v_job_location, p.home_location)
        ELSE 1200.0::DOUBLE PRECISION
      END AS c_dist,
      COALESCE(wp.jobs_completed, 12)::INT AS c_completed,
      COALESCE(wp.is_verified_badge, false) AS c_verified,
      EXISTS (
        SELECT 1 FROM public.worker_skills ws
        JOIN public.skills s ON ws.skill_id = s.id
        WHERE ws.worker_id = p.id AND (v_category_id IS NULL OR s.category_id = v_category_id)
      ) AS c_skill_match,
      ARRAY(
        SELECT COALESCE(s.name->>'en', s.name->>'kn', 'General')
        FROM public.worker_skills ws
        JOIN public.skills s ON ws.skill_id = s.id
        WHERE ws.worker_id = p.id
        LIMIT 4
      ) AS c_skills
    FROM public.profiles p
    LEFT JOIN public.worker_profiles wp ON p.id = wp.user_id
    WHERE p.id != v_late_worker_id
      AND (
        p.active_role = 'seeker'
        OR wp.user_id IS NOT NULL
        OR EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = p.id AND ur.role = 'seeker')
      )
      AND p.is_suspended = false
  )
  SELECT
    c.c_worker_id,
    c.c_full_name,
    c.c_avatar_url,
    ROUND(c.c_rating, 1),
    ROUND(c.c_dist),
    c.c_completed,
    c.c_verified,
    c.c_skills
  FROM candidates c
  ORDER BY
    c.c_skill_match DESC,
    c.c_verified DESC,
    c.c_rating DESC,
    c.c_dist ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.find_replacement_candidates(p_assignment_id UUID)
RETURNS TABLE (
  worker_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  rating NUMERIC,
  distance_meters DOUBLE PRECISION,
  jobs_completed INT,
  is_verified BOOLEAN,
  skills TEXT[]
) AS $$
BEGIN
  RETURN QUERY SELECT * FROM public.find_replacement(p_assignment_id);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.find_replacement(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.find_replacement_candidates(UUID) TO authenticated, anon;
