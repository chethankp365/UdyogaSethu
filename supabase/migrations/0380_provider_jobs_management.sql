-- Migration: 0380_provider_jobs_management.sql
-- Description: Provider job posting, management, applicant retrieval, status transitions,
--              and enhanced application responses with slot counting & notification.

-- 1. Function: post_provider_job
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
  p_geofence_radius_m INT DEFAULT 150
)
RETURNS UUID AS $$
DECLARE
  v_provider_id UUID;
  v_job_id UUID;
  v_loc extensions.geography(Point, 4326) := NULL;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_location_lat IS NOT NULL AND p_location_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_location_lng, p_location_lat), 4326)::extensions.geography;
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
    'open'
  )
  RETURNING id INTO v_job_id;

  RETURN v_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Function: update_provider_job
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
  p_geofence_radius_m INT DEFAULT 150
)
RETURNS BOOLEAN AS $$
DECLARE
  v_provider_id UUID;
  v_loc extensions.geography(Point, 4326) := NULL;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_location_lat IS NOT NULL AND p_location_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_location_lng, p_location_lat), 4326)::extensions.geography;
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
    slots_total = GREATEST(COALESCE(p_slots_total, slots_total), slots_filled),
    materials_provided = COALESCE(p_materials_provided, materials_provided),
    payment_mode = p_payment_mode,
    requirements = COALESCE(p_requirements, requirements),
    location = COALESCE(v_loc, location),
    address_text = COALESCE(p_address_text, address_text),
    geofence_radius_m = COALESCE(p_geofence_radius_m, geofence_radius_m),
    updated_at = NOW()
  WHERE id = p_job_id AND provider_id = v_provider_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Function: get_provider_jobs
CREATE OR REPLACE FUNCTION public.get_provider_jobs(
  p_provider_id UUID DEFAULT auth.uid()
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  category_id UUID,
  category_name TEXT,
  category_icon TEXT,
  title TEXT,
  description TEXT,
  wage_type TEXT,
  wage_paise BIGINT,
  est_duration_minutes INT,
  start_at TIMESTAMPTZ,
  slots_total INT,
  slots_filled INT,
  materials_provided BOOLEAN,
  payment_mode TEXT,
  requirements JSONB,
  address_text TEXT,
  geofence_radius_m INT,
  status TEXT,
  created_at TIMESTAMPTZ,
  applicant_count BIGINT,
  hired_count BIGINT
) AS $$
DECLARE
  v_uid UUID;
BEGIN
  v_uid := COALESCE(p_provider_id, auth.uid());
  RETURN QUERY
  SELECT
    j.id,
    j.provider_id,
    j.category_id,
    COALESCE(sc.names->>'en', sc.slug, 'General')::TEXT AS category_name,
    sc.icon::TEXT AS category_icon,
    j.title,
    j.description,
    j.wage_type::TEXT,
    j.wage_paise,
    j.est_duration_minutes,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    j.materials_provided,
    j.payment_mode::TEXT,
    j.requirements,
    j.address_text,
    j.geofence_radius_m,
    j.status::TEXT,
    j.created_at,
    (SELECT COUNT(*) FROM public.job_applications ja WHERE ja.job_id = j.id) AS applicant_count,
    (SELECT COUNT(*) FROM public.job_assignments ass WHERE ass.job_id = j.id AND ass.status NOT IN ('cancelled', 'no_show')) AS hired_count
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  WHERE j.provider_id = v_uid
  ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 4. Function: get_job_applicants
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
    p.avatar_url::TEXT AS worker_avatar,
    COALESCE(p.is_verified, false) AS is_verified,
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
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  WHERE ja.job_id = p_job_id
  ORDER BY 
    CASE ja.status
      WHEN 'applied' THEN 1
      WHEN 'shortlisted' THEN 2
      WHEN 'hired' THEN 3
      WHEN 'rejected' THEN 4
      ELSE 5
    END,
    ja.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 5. Function: update_provider_job_status
CREATE OR REPLACE FUNCTION public.update_provider_job_status(
  p_job_id UUID,
  p_status public.job_status
)
RETURNS JSONB AS $$
DECLARE
  v_provider_id UUID;
  v_cur_status public.job_status;
  v_hired_count INT := 0;
  v_affected_assignments INT := 0;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT status INTO v_cur_status
  FROM public.jobs
  WHERE id = p_job_id AND (provider_id = v_provider_id OR public.is_admin());

  IF v_cur_status IS NULL THEN
    RAISE EXCEPTION 'Job not found or unauthorized.';
  END IF;

  IF p_status = 'cancelled' THEN
    -- Count active hired assignments
    SELECT COUNT(*) INTO v_hired_count
    FROM public.job_assignments
    WHERE job_id = p_job_id AND status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified');

    IF v_hired_count > 0 THEN
      -- Cancel all active assignments
      UPDATE public.job_assignments
      SET status = 'cancelled', updated_at = NOW()
      WHERE job_id = p_job_id AND status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified');
      GET DIAGNOSTICS v_affected_assignments = ROW_COUNT;
    END IF;
  END IF;

  UPDATE public.jobs
  SET status = p_status, updated_at = NOW()
  WHERE id = p_job_id;

  RETURN jsonb_build_object(
    'success', true,
    'new_status', p_status,
    'affected_assignments', v_affected_assignments,
    'had_hired_workers', v_hired_count > 0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6. Enhanced respond_to_application
CREATE OR REPLACE FUNCTION public.respond_to_application(
  p_application_id UUID,
  p_status public.application_status
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
  v_cur_app_status public.application_status;
  v_assignment_id UUID;
  v_code TEXT;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT ja.job_id, ja.worker_id, ja.status, j.wage_paise, j.slots_total, j.slots_filled, j.title
  INTO v_job_id, v_worker_id, v_cur_app_status, v_wage_paise, v_slots_total, v_slots_filled, v_job_title
  FROM public.job_applications ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_application_id AND (j.provider_id = v_provider_id OR public.is_admin());

  IF v_job_id IS NULL THEN
    RAISE EXCEPTION 'Application not found or unauthorized.';
  END IF;

  IF p_status = 'hired' THEN
    IF v_cur_app_status = 'hired' THEN
      -- Already hired, find existing assignment
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

    -- Send notification to worker
    INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
    VALUES (
      v_worker_id,
      'job_hired',
      'notification_job_hired_title',
      'notification_job_hired_body',
      jsonb_build_object('job_id', v_job_id, 'job_title', v_job_title, 'assignment_id', v_assignment_id)
    );
  END IF;

  UPDATE public.job_applications
  SET status = p_status, updated_at = NOW()
  WHERE id = p_application_id;

  RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.post_provider_job TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.update_provider_job TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_provider_jobs TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_job_applicants TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.update_provider_job_status TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.respond_to_application TO authenticated, anon;
