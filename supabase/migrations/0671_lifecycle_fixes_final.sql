-- Migration 0671: Lifecycle Fixes Final Sync
-- Applies clean definitions for:
--   1. get_job_applicants (correct columns, safe fields, assignment_id)
--   2. get_active_job_details (defensive ID resolver, valid geometry, safe party fields)
--   3. get_worker_schedule (extensions.geometry, timezone padding, inclusive statuses)
--   4. verify_ticket_scan (FOR UPDATE OF ja)

-- ============================================================================
-- 1. GET_JOB_APPLICANTS (SECURITY DEFINER, Verified Job Owner, Safe Public Fields)
-- ============================================================================
DROP FUNCTION IF EXISTS public.get_job_applicants(UUID);

CREATE OR REPLACE FUNCTION public.get_job_applicants(p_job_id UUID)
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
  review_count INT,
  jobs_completed_count INT,
  distance_m DOUBLE PRECISION,
  languages TEXT[],
  skills TEXT[],
  assignment_id UUID
) AS $$
DECLARE
  v_provider_id UUID := auth.uid();
  v_job_loc extensions.geography(Point, 4326);
BEGIN
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT location INTO v_job_loc
  FROM public.jobs
  WHERE id = p_job_id AND (provider_id = v_provider_id OR public.is_admin());

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found or caller is not authorized.';
  END IF;

  RETURN QUERY
  SELECT
    ja.id AS application_id,
    ja.job_id,
    ja.worker_id,
    ja.status::TEXT,
    ja.message,
    ja.created_at,
    COALESCE(NULLIF(TRIM(p.full_name), ''), 'Name not set')::TEXT AS worker_name,
    p.avatar_path::TEXT AS worker_avatar,
    COALESCE(wp.seeker_type::TEXT, 'informal')::TEXT AS seeker_type,
    CASE 
      WHEN COALESCE(wp.is_verified_badge, false) THEN 'Verified Worker'
      ELSE 'Registered Worker'
    END::TEXT AS badge_name,
    1::INT AS level_number,
    COALESCE(wp.is_verified_badge, false) AS is_verified,
    COALESCE(wp.rating_avg, 4.8)::NUMERIC AS rating,
    COALESCE(wp.rating_count, 0)::INT AS review_count,
    COALESCE(wp.jobs_completed, 0)::INT AS jobs_completed_count,
    CASE 
      WHEN v_job_loc IS NOT NULL AND p.home_location IS NOT NULL THEN
        extensions.ST_Distance(v_job_loc, p.home_location)
      ELSE 800.0
    END AS distance_m,
    COALESCE(wp.languages, ARRAY['kn']::TEXT[]),
    ARRAY(
      SELECT COALESCE(sk.names->>'en', sk.slug)
      FROM public.worker_skills ws
      JOIN public.skills sk ON ws.skill_id = sk.id
      WHERE ws.user_id = ja.worker_id
    )::TEXT[] AS skills,
    asg.id AS assignment_id
  FROM public.job_applications ja
  JOIN public.profiles p ON ja.worker_id = p.id
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  LEFT JOIN public.job_assignments asg ON asg.job_id = ja.job_id AND asg.worker_id = ja.worker_id
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
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- ============================================================================
-- 2. GET_ACTIVE_JOB_DETAILS (Defensive ID resolution, Safe Party Gating, ST_X/ST_Y)
-- ============================================================================
DROP FUNCTION IF EXISTS public.get_active_job_details(UUID);

CREATE OR REPLACE FUNCTION public.get_active_job_details(p_assignment_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_resolved_assignment_id UUID;
  v_result JSONB;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- 1. Defensively resolve assignment id
  -- Attempt A: Direct match on job_assignments.id
  SELECT id INTO v_resolved_assignment_id
  FROM public.job_assignments
  WHERE id = p_assignment_id;

  -- Attempt B: Match on jobs.id (caller passed job_id)
  IF v_resolved_assignment_id IS NULL THEN
    SELECT ja.id INTO v_resolved_assignment_id
    FROM public.job_assignments ja
    JOIN public.jobs j ON ja.job_id = j.id
    WHERE ja.job_id = p_assignment_id
      AND (ja.worker_id = v_uid OR j.provider_id = v_uid OR public.is_admin())
    ORDER BY ja.created_at DESC
    LIMIT 1;
  END IF;

  -- Attempt C: Match on job_applications.id (caller passed application_id)
  IF v_resolved_assignment_id IS NULL THEN
    SELECT ja.id INTO v_resolved_assignment_id
    FROM public.job_assignments ja
    JOIN public.job_applications app ON ja.job_id = app.job_id AND ja.worker_id = app.worker_id
    WHERE app.id = p_assignment_id
    ORDER BY ja.created_at DESC
    LIMIT 1;
  END IF;

  IF v_resolved_assignment_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_build_object(
    'assignment_id', ja.id,
    'job_id', j.id,
    'booking_code', ja.booking_code,
    'status', ja.status::TEXT,
    'agreed_wage_paise', ja.agreed_wage_paise,
    'protection_selected', ja.protection_selected,
    'arrived_at', ja.arrived_at,
    'started_at', ja.started_at,
    'ended_at', ja.ended_at,
    'elapsed_seconds', CASE
      WHEN ja.started_at IS NOT NULL THEN
        GREATEST(0, EXTRACT(EPOCH FROM (COALESCE(ja.ended_at, NOW()) - ja.started_at))::INT)
      ELSE 0
    END,
    'midjob_verified_at', ja.midjob_verified_at,
    'payment_eligible', ja.payment_eligible,
    'extended_grace_minutes', COALESCE(ja.extended_grace_minutes, 0),
    'late_notified_at', ja.late_notified_at,
    'running_late_eta_minutes', ja.running_late_eta_minutes,
    'running_late_reported_at', ja.running_late_reported_at,
    'no_show_timer_paused', COALESCE(ja.no_show_timer_paused, false),
    'replaced_by', ja.replaced_by,
    'job_title', j.title,
    'job_description', j.description,
    'start_at', j.start_at,
    'est_duration_minutes', COALESCE(j.est_duration_minutes, 480),
    'address_text', j.address_text,
    'job_lat', CASE WHEN j.location IS NOT NULL THEN extensions.ST_Y(j.location::extensions.geometry) ELSE NULL END,
    'job_lng', CASE WHEN j.location IS NOT NULL THEN extensions.ST_X(j.location::extensions.geometry) ELSE NULL END,
    'category_name', COALESCE(sc.names->>'en', sc.slug, 'General Work'),
    'category_slug', COALESCE(sc.slug, 'general'),
    'category_icon', COALESCE(sc.icon, 'handyman'),
    'provider_id', pp.id,
    'provider_name', COALESCE(NULLIF(TRIM(pp.full_name), ''), 'Job Provider'),
    'provider_phone', CASE WHEN ja.status IN ('accepted', 'ticket_issued', 'arrived', 'in_progress_verified') THEN pp.phone ELSE NULL END,
    'provider_avatar', pp.avatar_path,
    'provider_verified', COALESCE(prp.is_verified_badge, true),
    'worker_id', wp_prof.id,
    'worker_name', COALESCE(NULLIF(TRIM(wp_prof.full_name), ''), 'Name not set'),
    'worker_phone', CASE WHEN ja.status IN ('accepted', 'ticket_issued', 'arrived', 'in_progress_verified') THEN wp_prof.phone ELSE NULL END,
    'worker_avatar', wp_prof.avatar_path,
    'worker_verified', COALESCE(wp.is_verified_badge, false),
    'worker_lat', CASE WHEN wp_prof.home_location IS NOT NULL THEN extensions.ST_Y(wp_prof.home_location::extensions.geometry) ELSE NULL END,
    'worker_lng', CASE WHEN wp_prof.home_location IS NOT NULL THEN extensions.ST_X(wp_prof.home_location::extensions.geometry) ELSE NULL END
  ) INTO v_result
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  LEFT JOIN public.profiles pp ON j.provider_id = pp.id
  LEFT JOIN public.provider_profiles prp ON j.provider_id = prp.user_id
  LEFT JOIN public.profiles wp_prof ON ja.worker_id = wp_prof.id
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  WHERE ja.id = v_resolved_assignment_id
    AND (ja.worker_id = v_uid OR j.provider_id = v_uid OR public.is_admin());

  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- ============================================================================
-- 3. GET_WORKER_SCHEDULE (Geometry schema-qualified, Asia/Kolkata date padding)
-- ============================================================================
DROP FUNCTION IF EXISTS public.get_worker_schedule(UUID, TIMESTAMPTZ, TIMESTAMPTZ);

CREATE OR REPLACE FUNCTION public.get_worker_schedule(
  p_worker_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_result JSONB;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_worker_id != v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized to view schedule for worker %', p_worker_id;
  END IF;

  WITH schedule_rows AS (
    SELECT
      ja.id AS assignment_id,
      j.id AS job_id,
      j.title,
      ja.status::TEXT AS status,
      ja.booking_code,
      ja.agreed_wage_paise,
      j.start_at,
      COALESCE(j.est_duration_minutes, 480) AS est_duration_minutes,
      (j.start_at + (COALESCE(j.est_duration_minutes, 480) || ' minutes')::INTERVAL) AS end_at,
      j.address_text,
      CASE WHEN j.location IS NOT NULL THEN extensions.ST_Y(j.location::extensions.geometry) ELSE NULL END AS job_lat,
      CASE WHEN j.location IS NOT NULL THEN extensions.ST_X(j.location::extensions.geometry) ELSE NULL END AS job_lng,
      COALESCE(sc.slug, 'general') AS category_slug,
      COALESCE(sc.icon, 'handyman') AS category_icon,
      COALESCE(NULLIF(TRIM(pp.full_name), ''), 'Verified Employer') AS provider_name,
      LAG(j.start_at + (COALESCE(j.est_duration_minutes, 480) || ' minutes')::INTERVAL)
        OVER (ORDER BY j.start_at ASC) AS prev_job_end_at,
      LEAD(j.start_at)
        OVER (ORDER BY j.start_at ASC) AS next_job_start_at
    FROM public.job_assignments ja
    JOIN public.jobs j ON ja.job_id = j.id
    LEFT JOIN public.service_categories sc ON j.category_id = sc.id
    LEFT JOIN public.profiles pp ON j.provider_id = pp.id
    WHERE ja.worker_id = p_worker_id
      AND ja.status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified', 'completed')
      AND j.start_at >= (p_start_date - INTERVAL '1 day')
      AND j.start_at <= (p_end_date + INTERVAL '1 day')
    ORDER BY j.start_at ASC
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'assignment_id', s.assignment_id,
        'job_id', s.job_id,
        'title', s.title,
        'status', s.status,
        'booking_code', s.booking_code,
        'agreed_wage_paise', s.agreed_wage_paise,
        'start_at', s.start_at,
        'end_at', s.end_at,
        'est_duration_minutes', s.est_duration_minutes,
        'address_text', s.address_text,
        'job_lat', s.job_lat,
        'job_lng', s.job_lng,
        'category_slug', s.category_slug,
        'category_icon', s.category_icon,
        'provider_name', s.provider_name,
        'gap_from_prev_minutes', CASE
          WHEN s.prev_job_end_at IS NOT NULL
          THEN EXTRACT(EPOCH FROM (s.start_at - s.prev_job_end_at)) / 60.0
          ELSE NULL
        END,
        'gap_to_next_minutes', CASE
          WHEN s.next_job_start_at IS NOT NULL
          THEN EXTRACT(EPOCH FROM (s.next_job_start_at - s.end_at)) / 60.0
          ELSE NULL
        END
      )
    ),
    '[]'::jsonb
  ) INTO v_result
  FROM schedule_rows s;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- ============================================================================
-- 4. VERIFY_TICKET_SCAN (Atomic race-safe check with FOR UPDATE OF ja)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.verify_ticket_scan(
  p_token TEXT,
  p_provider_lat DOUBLE PRECISION DEFAULT NULL,
  p_provider_lng DOUBLE PRECISION DEFAULT NULL,
  p_job_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_hash TEXT;
  v_qr RECORD;
  v_ja RECORD;
  v_loc extensions.geography(Point, 4326) := NULL;
  v_before_min INT := 60;
  v_after_min INT := 120;
  v_setting TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'NOT_AUTHENTICATED', 'error_message', 'Sign in required.');
  END IF;
  IF p_token IS NULL OR LENGTH(TRIM(p_token)) = 0 THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'TAMPERED', 'error_message', 'Empty or missing token.');
  END IF;

  IF p_provider_lat IS NOT NULL AND p_provider_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_provider_lng, p_provider_lat), 4326)::extensions.geography;
  END IF;

  SELECT value->>0 INTO v_setting FROM public.admin_settings WHERE key = 'ticket_valid_before_minutes';
  IF v_setting IS NOT NULL AND v_setting ~ '^\d+$' THEN v_before_min := v_setting::INT; END IF;
  SELECT value->>0 INTO v_setting FROM public.admin_settings WHERE key = 'ticket_valid_after_minutes';
  IF v_setting IS NOT NULL AND v_setting ~ '^\d+$' THEN v_after_min := v_setting::INT; END IF;

  v_hash := encode(extensions.digest(p_token, 'sha256'), 'hex');

  -- Lock token row for atomic concurrency protection
  SELECT * INTO v_qr FROM public.qr_tokens WHERE token_id_hash = v_hash FOR UPDATE;
  IF v_qr.id IS NULL OR v_qr.revoked THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'TAMPERED', 'error_message', 'Ticket QR code could not be verified or was tampered.');
  END IF;

  IF v_qr.used THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'ALREADY_USED',
      'error_message', 'Already scanned at ' || to_char(COALESCE(v_qr.used_at, NOW())::TIME, 'HH24:MI'),
      'scanned_at', to_char(COALESCE(v_qr.used_at, NOW())::TIME, 'HH24:MI'));
  END IF;

  IF v_qr.expires_at < NOW() THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'EXPIRED',
      'error_message', 'QR expired at ' || to_char(v_qr.expires_at::TIME, 'HH24:MI') || ', ask the worker to refresh',
      'expired_at', to_char(v_qr.expires_at::TIME, 'HH24:MI'));
  END IF;

  -- Atomically consume token
  UPDATE public.qr_tokens SET used = true, used_at = NOW() WHERE token_id_hash = v_hash AND used = false RETURNING * INTO v_qr;
  IF NOT FOUND THEN
    SELECT * INTO v_qr FROM public.qr_tokens WHERE token_id_hash = v_hash;
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'ALREADY_USED',
      'error_message', 'Already scanned at ' || to_char(COALESCE(v_qr.used_at, NOW())::TIME, 'HH24:MI'),
      'scanned_at', to_char(COALESCE(v_qr.used_at, NOW())::TIME, 'HH24:MI'));
  END IF;

  -- Lock assignment row using FOR UPDATE OF ja
  SELECT ja.*, j.provider_id, j.title AS job_title, j.location AS job_location, j.geofence_radius_m,
         j.start_at, j.status AS job_status, p.full_name AS worker_name, p.avatar_path AS worker_avatar,
         COALESCE(p.is_suspended, false) AS worker_suspended, COALESCE(wp.is_verified_badge, false) AS is_verified_badge
  INTO v_ja
  FROM public.job_assignments ja JOIN public.jobs j ON ja.job_id = j.id
  JOIN public.profiles p ON ja.worker_id = p.id LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  WHERE ja.id = v_qr.assignment_id FOR UPDATE OF ja;

  IF v_ja.id IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'ASSIGNMENT_NOT_FOUND', 'error_message', 'Assignment not found.');
  END IF;
  IF v_ja.provider_id != v_uid AND NOT public.is_admin() THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'WRONG_EMPLOYER', 'error_message', 'You are not the designated employer for this job assignment.');
  END IF;
  IF p_job_id IS NOT NULL AND v_ja.job_id != p_job_id THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'WRONG_JOB', 'error_message', 'This ticket is for a different job assignment.');
  END IF;
  IF v_ja.worker_suspended THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'WORKER_SUSPENDED', 'error_message', 'This worker account is currently suspended.');
  END IF;
  IF v_ja.status IN ('cancelled', 'rejected') OR v_ja.job_status = 'cancelled' THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'CANCELLED', 'error_message', 'This job assignment was cancelled.');
  END IF;
  IF v_ja.status IN ('arrived', 'in_progress', 'in_progress_verified', 'completed') THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'DUPLICATE_CHECKIN', 'error_message', 'Worker has already checked in on site.');
  END IF;

  IF v_ja.start_at IS NOT NULL THEN
    IF NOW() < v_ja.start_at - (v_before_min || ' minutes')::INTERVAL THEN
      RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'NOT_YET_VALID', 'error_message', 'Ticket is not yet valid. Check-in opens ' || v_before_min || ' minutes before start time.');
    END IF;
    IF NOW() > v_ja.start_at + (v_after_min || ' minutes')::INTERVAL THEN
      RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'TOO_LATE', 'error_message', 'Ticket check-in window has closed. Permitted arrival period has elapsed.');
    END IF;
  END IF;

  UPDATE public.job_assignments SET status = 'arrived', arrived_at = NOW(), employer_scan_location = v_loc, updated_at = NOW() WHERE id = v_ja.id;
  INSERT INTO public.attendance_logs (assignment_id, scanned_by, token_id, location, result) VALUES (v_ja.id, v_uid, v_hash, v_loc, 'SUCCESS');
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta) VALUES (v_ja.id, 'arrived', v_uid, jsonb_build_object('arrived_at', NOW()));

  RETURN jsonb_build_object(
    'valid', true, 'status', 'arrived', 'purpose', 'ticket', 'assignment_id', v_ja.id, 'booking_code', v_ja.booking_code,
    'worker_id', v_ja.worker_id, 'worker_name', v_ja.worker_name, 'worker_avatar', v_ja.worker_avatar,
    'is_verified_badge', v_ja.is_verified_badge, 'job_title', v_ja.job_title, 'arrived_at', NOW(), 'message', 'Attendance verified successfully.'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- ============================================================================
-- 5. GRANTS & NOTIFY SCHEMA RELOAD
-- ============================================================================
GRANT EXECUTE ON FUNCTION public.get_job_applicants(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_active_job_details(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_worker_schedule(UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_ticket_scan(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
