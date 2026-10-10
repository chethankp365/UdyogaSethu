-- Migration: 0580_job_execution_tickets_qr_lifecycle.sql
-- Description: Part E - Server-authoritative job execution lifecycle, rotating ticket QR tokens, atomic check-in verification, and step-2 presence verification.
--
-- Relies on:
--   Tables:
--     - public.admin_settings (key, value, updated_at)
--     - public.job_assignments (id, job_id, worker_id, status, booking_code, agreed_wage_paise, protection_selected, arrived_at, started_at, ended_at, start_selfie_path, start_geo_ok, employer_scan_location, payment_eligible, extended_grace_minutes, late_notified_at, running_late_eta_minutes, running_late_reported_at, no_show_timer_paused, replaced_by, updated_at)
--     - public.jobs (id, provider_id, title, description, start_at, est_duration_minutes, address_text, location, geofence_radius_m, wage_amount_paise, wage_type, payment_mode, category_id, is_demo)
--     - public.qr_tokens (id, token_id_hash, user_id, purpose, assignment_id, expires_at, revoked, used, used_at, created_at)
--     - public.attendance_logs (id, assignment_id, scanned_by, token_id, location, result, created_at)
--     - public.assignment_events (id, assignment_id, event_type, actor_id, actor_role, meta, payload, created_at)
--     - public.profiles (id, full_name, phone_number, avatar_path, is_active)
--     - public.worker_profiles (user_id, seeker_type, is_verified_badge)
--     - public.service_categories (id, name, slug, icon)
--     - public.notifications (user_id, type, title_key, body_key, params, created_at)
--   Functions:
--     - auth.uid()
--     - public.is_admin()
--     - extensions.gen_random_uuid()
--     - extensions.digest(text, text)
--     - extensions.ST_Y(geometry)
--     - extensions.ST_X(geometry)
--     - extensions.ST_SetSRID(geometry, int)
--     - extensions.ST_MakePoint(double, double)
--     - extensions.ST_Distance(geography, geography)

-- 1. Ensure columns on assignment_events
ALTER TABLE public.assignment_events ADD COLUMN IF NOT EXISTS actor_role TEXT;
ALTER TABLE public.assignment_events ADD COLUMN IF NOT EXISTS payload JSONB;

-- 2. Seed admin settings for ticket validation and token rotation TTL
INSERT INTO public.admin_settings (key, value)
VALUES
  ('ticket_valid_minutes_before', '60'::jsonb),
  ('ticket_valid_minutes_after', '120'::jsonb),
  ('ticket_token_ttl_seconds', '120'::jsonb),
  ('ticket_debug_short_ttl_seconds', 'null'::jsonb)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value, updated_at = NOW();

-- 3. RPC: issue_job_ticket(p_assignment_id UUID)
CREATE OR REPLACE FUNCTION public.issue_job_ticket(p_assignment_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID;
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_worker public.profiles%ROWTYPE;
  v_worker_profile public.worker_profiles%ROWTYPE;
  v_provider public.profiles%ROWTYPE;
  v_category_name TEXT := 'General Labour';
  v_category_icon TEXT := 'work';
  v_lat DOUBLE PRECISION;
  v_lng DOUBLE PRECISION;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_assignment FROM public.job_assignments WHERE id = p_assignment_id;
  IF v_assignment.id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;
  IF v_job.id IS NULL THEN
    RAISE EXCEPTION 'Job % not found.', v_assignment.job_id;
  END IF;

  -- Caller must be worker, provider or admin
  IF v_assignment.worker_id != v_caller AND v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized to access ticket for this assignment.';
  END IF;

  SELECT * INTO v_worker FROM public.profiles WHERE id = v_assignment.worker_id;
  SELECT * INTO v_worker_profile FROM public.worker_profiles WHERE user_id = v_assignment.worker_id;
  SELECT * INTO v_provider FROM public.profiles WHERE id = v_job.provider_id;

  IF v_job.category_id IS NOT NULL THEN
    SELECT name, COALESCE(icon, 'work') INTO v_category_name, v_category_icon
    FROM public.service_categories WHERE id = v_job.category_id;
  END IF;

  IF v_job.location IS NOT NULL THEN
    v_lat := extensions.ST_Y(v_job.location::extensions.geometry);
    v_lng := extensions.ST_X(v_job.location::extensions.geometry);
  END IF;

  -- Advance accepted -> ticket_issued automatically
  IF v_assignment.status = 'accepted' THEN
    UPDATE public.job_assignments
    SET status = 'ticket_issued', updated_at = NOW()
    WHERE id = p_assignment_id;
    v_assignment.status := 'ticket_issued';

    INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, actor_role, meta, created_at)
    VALUES (
      p_assignment_id,
      'ticket_issued',
      v_caller,
      CASE WHEN v_assignment.worker_id = v_caller THEN 'worker' ELSE 'system' END,
      jsonb_build_object('booking_code', v_assignment.booking_code),
      NOW()
    );
  END IF;

  RETURN jsonb_build_object(
    'assignment_id', v_assignment.id,
    'booking_code', v_assignment.booking_code,
    'status', v_assignment.status::TEXT,
    'job_id', v_job.id,
    'job_title', v_job.title,
    'category_name', v_category_name,
    'category_icon', v_category_icon,
    'start_at', v_job.start_at,
    'est_duration_minutes', v_job.est_duration_minutes,
    'agreed_wage_paise', v_assignment.agreed_wage_paise,
    'wage_type', v_job.wage_type::TEXT,
    'payment_mode', v_job.payment_mode::TEXT,
    'address_text', v_job.address_text,
    'lat', v_lat,
    'lng', v_lng,
    'worker_id', v_worker.id,
    'worker_name', COALESCE(v_worker.full_name, 'Assigned Worker'),
    'worker_avatar', v_worker.avatar_path,
    'is_worker_verified', COALESCE(v_worker_profile.is_verified_badge, false),
    'worker_seeker_type', v_worker_profile.seeker_type,
    'provider_id', v_provider.id,
    'provider_name', COALESCE(v_provider.full_name, 'Job Provider')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.issue_job_ticket(UUID) TO authenticated;

-- 4. RPC: get_rotating_ticket_token(p_assignment_id UUID, p_debug_short_ttl BOOLEAN DEFAULT false)
CREATE OR REPLACE FUNCTION public.get_rotating_ticket_token(
  p_assignment_id UUID,
  p_debug_short_ttl BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID;
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_ttl INT := 120;
  v_short_ttl_val JSONB;
  v_token TEXT;
  v_hash TEXT;
  v_expires_at TIMESTAMPTZ;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_assignment FROM public.job_assignments WHERE id = p_assignment_id;
  IF v_assignment.id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;
  IF v_job.id IS NULL THEN
    RAISE EXCEPTION 'Job % not found.', v_assignment.job_id;
  END IF;

  IF v_assignment.worker_id != v_caller AND v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized to generate token for this assignment.';
  END IF;

  -- Determine TTL
  IF p_debug_short_ttl THEN
    SELECT value INTO v_short_ttl_val FROM public.admin_settings WHERE key = 'ticket_debug_short_ttl_seconds';
    IF v_short_ttl_val IS NOT NULL AND v_short_ttl_val != 'null'::jsonb THEN
      v_ttl := (v_short_ttl_val #>> '{}')::INT;
    ELSE
      v_ttl := 15;
    END IF;
  ELSE
    SELECT COALESCE((value #>> '{}')::INT, 120) INTO v_ttl
    FROM public.admin_settings WHERE key = 'ticket_token_ttl_seconds';
    IF v_ttl IS NULL OR v_ttl <= 0 THEN
      v_ttl := 120;
    END IF;
  END IF;

  v_expires_at := v_now + (v_ttl || ' seconds')::INTERVAL;

  -- Generate rotating random token (no PII in plaintext)
  v_token := 'TK-' || replace(extensions.gen_random_uuid()::text, '-', '') || '-' || floor(extract(epoch from v_now))::text;
  v_hash := encode(digest(v_token, 'sha256'), 'hex');

  -- Store hash in qr_tokens
  INSERT INTO public.qr_tokens (
    token_id_hash,
    user_id,
    purpose,
    assignment_id,
    expires_at,
    revoked,
    used,
    created_at
  ) VALUES (
    v_hash,
    v_assignment.worker_id,
    'ticket',
    p_assignment_id,
    v_expires_at,
    false,
    false,
    v_now
  );

  -- Advance accepted -> ticket_issued if not already
  IF v_assignment.status = 'accepted' THEN
    UPDATE public.job_assignments
    SET status = 'ticket_issued', updated_at = v_now
    WHERE id = p_assignment_id;
  END IF;

  RETURN jsonb_build_object(
    'qr_token', v_token,
    'assignment_id', p_assignment_id,
    'expires_in_seconds', v_ttl,
    'expires_at', v_expires_at
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_rotating_ticket_token(UUID, BOOLEAN) TO authenticated;

-- 5. RPC: verify_ticket_scan(p_token TEXT, p_provider_lat DOUBLE PRECISION, p_provider_lng DOUBLE PRECISION)
CREATE OR REPLACE FUNCTION public.verify_ticket_scan(
  p_token TEXT,
  p_provider_lat DOUBLE PRECISION DEFAULT NULL,
  p_provider_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID;
  v_hash TEXT;
  v_qr public.qr_tokens%ROWTYPE;
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_worker public.profiles%ROWTYPE;
  v_worker_profile public.worker_profiles%ROWTYPE;
  v_min_before INT := 60;
  v_min_after INT := 120;
  v_now TIMESTAMPTZ := NOW();
  v_loc extensions.geography := NULL;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'AUTH_REQUIRED',
      'message', 'Authentication required to scan tickets.'
    );
  END IF;

  IF p_token IS NULL OR LENGTH(TRIM(p_token)) < 8 THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'TAMPERED',
      'message', 'Malformed or invalid ticket token.'
    );
  END IF;

  v_hash := encode(digest(TRIM(p_token), 'sha256'), 'hex');

  -- Lock token row
  SELECT * INTO v_qr
  FROM public.qr_tokens
  WHERE token_id_hash = v_hash AND purpose = 'ticket'
  FOR UPDATE;

  IF v_qr.id IS NULL THEN
    -- Fallback: check if raw token string matches booking_code directly (e.g. TICKET-BOOK-xxxx)
    SELECT ja.* INTO v_assignment
    FROM public.job_assignments ja
    WHERE ja.booking_code = REPLACE(UPPER(TRIM(p_token)), 'TICKET-', '')
    LIMIT 1;

    IF v_assignment.id IS NULL THEN
      RETURN jsonb_build_object(
        'valid', false,
        'status_code', 'TAMPERED',
        'message', 'Ticket QR code could not be verified or was tampered.'
      );
    END IF;
  ELSE
    SELECT * INTO v_assignment
    FROM public.job_assignments
    WHERE id = v_qr.assignment_id
    FOR UPDATE;
  END IF;

  IF v_assignment.id IS NULL THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'JOB_NOT_FOUND',
      'message', 'Job assignment not found for this ticket.'
    );
  END IF;

  -- Check revoked
  IF v_qr.id IS NOT NULL AND v_qr.revoked THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'CANCELLED',
      'message', 'This ticket token has been revoked.'
    );
  END IF;

  -- Check already used
  IF v_qr.id IS NOT NULL AND v_qr.used THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'ALREADY_USED',
      'message', 'This ticket token has already been scanned. Ask worker to refresh.'
    );
  END IF;

  -- Check token expiry
  IF v_qr.id IS NOT NULL AND v_qr.expires_at < v_now THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'EXPIRED',
      'message', 'Ticket QR token has expired. Ask worker to refresh the ticket screen.'
    );
  END IF;

  -- Fetch job
  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;
  IF v_job.id IS NULL THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'JOB_NOT_FOUND',
      'message', 'Associated job not found.'
    );
  END IF;

  -- Check provider authority
  IF v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'WRONG_EMPLOYER',
      'message', 'You are not the designated employer for this job assignment.'
    );
  END IF;

  -- Check worker account status
  SELECT * INTO v_worker FROM public.profiles WHERE id = v_assignment.worker_id;
  IF v_worker.is_active = false THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'WORKER_SUSPENDED',
      'message', 'Worker account has been suspended.'
    );
  END IF;

  -- Check assignment status
  IF v_assignment.status IN ('cancelled', 'provider_cancelled', 'worker_cancelled', 'rejected') THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'CANCELLED',
      'message', 'This job assignment was cancelled.'
    );
  END IF;

  IF v_assignment.status IN ('arrived', 'in_progress_verified', 'completed', 'payment_released') THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'DUPLICATE_CHECKIN',
      'message', 'Worker has already checked in or job is in progress.'
    );
  END IF;

  -- Check timing window against start_at
  IF v_job.start_at IS NOT NULL THEN
    SELECT COALESCE((value #>> '{}')::INT, 60) INTO v_min_before
    FROM public.admin_settings WHERE key = 'ticket_valid_minutes_before';

    SELECT COALESCE((value #>> '{}')::INT, 120) INTO v_min_after
    FROM public.admin_settings WHERE key = 'ticket_valid_minutes_after';

    IF v_now < (v_job.start_at - (v_min_before || ' minutes')::INTERVAL) THEN
      RETURN jsonb_build_object(
        'valid', false,
        'status_code', 'NOT_YET_VALID',
        'message', 'Ticket is not yet valid. Check-in opens ' || v_min_before || ' minutes before start time.'
      );
    END IF;

    IF v_now > (v_job.start_at + (v_min_after || ' minutes')::INTERVAL) THEN
      RETURN jsonb_build_object(
        'valid', false,
        'status_code', 'TOO_LATE',
        'message', 'Ticket is no longer valid. Permitted check-in window has elapsed.'
      );
    END IF;
  END IF;

  -- Mark token used
  IF v_qr.id IS NOT NULL THEN
    UPDATE public.qr_tokens
    SET used = true, used_at = v_now
    WHERE id = v_qr.id;
  END IF;

  IF p_provider_lat IS NOT NULL AND p_provider_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_provider_lng, p_provider_lat), 4326)::extensions.geography;
  END IF;

  -- Record in attendance_logs
  INSERT INTO public.attendance_logs (
    assignment_id,
    scanned_by,
    token_id,
    location,
    result,
    created_at
  ) VALUES (
    v_assignment.id,
    v_caller,
    COALESCE(v_qr.token_id_hash, p_token),
    v_loc,
    'arrived',
    v_now
  );

  -- Advance assignment status to 'arrived'
  UPDATE public.job_assignments
  SET status = 'arrived',
      arrived_at = v_now,
      employer_scan_location = v_loc,
      updated_at = v_now
  WHERE id = v_assignment.id;

  -- Record event in assignment_events
  INSERT INTO public.assignment_events (
    assignment_id,
    event_type,
    actor_id,
    actor_role,
    meta,
    created_at
  ) VALUES (
    v_assignment.id,
    'arrived',
    v_caller,
    'provider',
    jsonb_build_object(
      'from_status', v_assignment.status::TEXT,
      'to_status', 'arrived',
      'scan_type', 'qr_ticket_rotating',
      'provider_lat', p_provider_lat,
      'provider_lng', p_provider_lng
    ),
    v_now
  );

  -- Notify the worker
  INSERT INTO public.notifications (
    user_id,
    type,
    title_key,
    body_key,
    params,
    created_at
  ) VALUES (
    v_assignment.worker_id,
    'attendance_verified',
    'notification_arrival_confirmed_title',
    'notification_arrival_confirmed_body',
    jsonb_build_object('assignment_id', v_assignment.id, 'job_title', v_job.title),
    v_now
  );

  SELECT * INTO v_worker_profile FROM public.worker_profiles WHERE user_id = v_assignment.worker_id;

  RETURN jsonb_build_object(
    'valid', true,
    'status_code', 'SUCCESS',
    'assignment_id', v_assignment.id,
    'booking_code', v_assignment.booking_code,
    'worker_id', v_worker.id,
    'worker_name', COALESCE(v_worker.full_name, 'Assigned Worker'),
    'worker_avatar', v_worker.avatar_path,
    'is_worker_verified', COALESCE(v_worker_profile.is_verified_badge, false),
    'job_title', v_job.title,
    'arrived_at', v_now,
    'status', 'arrived'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.verify_ticket_scan(TEXT, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- 6. RPC: record_step2_verification(p_assignment_id UUID, p_selfie_path TEXT, p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_face_score DOUBLE PRECISION)
CREATE OR REPLACE FUNCTION public.record_step2_verification(
  p_assignment_id UUID,
  p_selfie_path TEXT,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_face_score DOUBLE PRECISION DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID;
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_now TIMESTAMPTZ := NOW();
  v_job_loc extensions.geography;
  v_user_loc extensions.geography;
  v_dist DOUBLE PRECISION := 0.0;
  v_radius INT := 150;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_assignment FROM public.job_assignments WHERE id = p_assignment_id FOR UPDATE;
  IF v_assignment.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'reason_code', 'NOT_FOUND', 'message', 'Assignment not found.');
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;
  IF v_job.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'reason_code', 'JOB_NOT_FOUND', 'message', 'Job not found.');
  END IF;

  IF v_assignment.worker_id != v_caller AND v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RETURN jsonb_build_object('success', false, 'reason_code', 'UNAUTHORIZED', 'message', 'Unauthorized.');
  END IF;

  IF v_assignment.status != 'arrived' THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason_code', 'ILLEGAL_STATUS',
      'message', 'Job must be in arrived stage before two-step verification.'
    );
  END IF;

  -- Geofence check
  v_radius := COALESCE(v_job.geofence_radius_m, 150);
  IF v_job.location IS NOT NULL AND p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_job_loc := v_job.location;
    v_user_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
    v_dist := extensions.ST_Distance(v_job_loc, v_user_loc);

    IF v_dist > v_radius THEN
      RETURN jsonb_build_object(
        'success', false,
        'reason_code', 'OUTSIDE_GEOFENCE',
        'distance_meters', ROUND(v_dist::numeric, 1),
        'radius_meters', v_radius,
        'message', 'You are outside the required job site radius (' || ROUND(v_dist::numeric, 0) || 'm away, limit ' || v_radius || 'm).'
      );
    END IF;
  END IF;

  -- Advance assignment to in_progress_verified
  UPDATE public.job_assignments
  SET status = 'in_progress_verified',
      started_at = v_now,
      start_selfie_path = p_selfie_path,
      start_geo_ok = true,
      updated_at = v_now
  WHERE id = p_assignment_id;

  INSERT INTO public.assignment_events (
    assignment_id,
    event_type,
    actor_id,
    actor_role,
    meta,
    created_at
  ) VALUES (
    p_assignment_id,
    'in_progress_verified',
    v_caller,
    'worker',
    jsonb_build_object(
      'selfie_path', p_selfie_path,
      'lat', p_lat,
      'lng', p_lng,
      'distance_meters', v_dist,
      'face_score', p_face_score
    ),
    v_now
  );

  RETURN jsonb_build_object(
    'success', true,
    'status', 'in_progress_verified',
    'started_at', v_now
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.record_step2_verification(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- 7. RPC: get_next_accepted_ticket()
CREATE OR REPLACE FUNCTION public.get_next_accepted_ticket()
RETURNS JSONB AS $$
DECLARE
  v_caller UUID;
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_provider public.profiles%ROWTYPE;
  v_category_name TEXT := 'General Labour';
  v_category_icon TEXT := 'work';
  v_lat DOUBLE PRECISION;
  v_lng DOUBLE PRECISION;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RETURN jsonb_build_object('has_ticket', false);
  END IF;

  SELECT ja.* INTO v_assignment
  FROM public.job_assignments ja
  JOIN public.jobs j ON j.id = ja.job_id
  WHERE ja.worker_id = v_caller
    AND ja.status IN ('accepted', 'ticket_issued')
    AND COALESCE(j.is_demo, false) = false
    AND j.start_at >= NOW() - INTERVAL '4 hours'
  ORDER BY j.start_at ASC
  LIMIT 1;

  IF v_assignment.id IS NULL THEN
    RETURN jsonb_build_object('has_ticket', false);
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;
  SELECT * INTO v_provider FROM public.profiles WHERE id = v_job.provider_id;

  IF v_job.category_id IS NOT NULL THEN
    SELECT name, COALESCE(icon, 'work') INTO v_category_name, v_category_icon
    FROM public.service_categories WHERE id = v_job.category_id;
  END IF;

  IF v_job.location IS NOT NULL THEN
    v_lat := extensions.ST_Y(v_job.location::extensions.geometry);
    v_lng := extensions.ST_X(v_job.location::extensions.geometry);
  END IF;

  RETURN jsonb_build_object(
    'has_ticket', true,
    'assignment_id', v_assignment.id,
    'booking_code', v_assignment.booking_code,
    'status', v_assignment.status::TEXT,
    'job_id', v_job.id,
    'job_title', v_job.title,
    'category_name', v_category_name,
    'category_icon', v_category_icon,
    'start_at', v_job.start_at,
    'est_duration_minutes', v_job.est_duration_minutes,
    'agreed_wage_paise', v_assignment.agreed_wage_paise,
    'address_text', v_job.address_text,
    'lat', v_lat,
    'lng', v_lng,
    'provider_id', v_provider.id,
    'provider_name', COALESCE(v_provider.full_name, 'Job Provider'),
    'provider_avatar', v_provider.avatar_path,
    'provider_phone', v_provider.phone_number
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_next_accepted_ticket() TO authenticated;

-- 8. RPC: get_active_job_details(p_assignment_id UUID)
CREATE OR REPLACE FUNCTION public.get_active_job_details(p_assignment_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID;
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_worker public.profiles%ROWTYPE;
  v_worker_profile public.worker_profiles%ROWTYPE;
  v_provider public.profiles%ROWTYPE;
  v_category_name TEXT := 'General Labour';
  v_category_slug TEXT := 'general';
  v_category_icon TEXT := 'work';
  v_job_lat DOUBLE PRECISION;
  v_job_lng DOUBLE PRECISION;
  v_elapsed_seconds INT := 0;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_assignment FROM public.job_assignments WHERE id = p_assignment_id;
  IF v_assignment.id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;
  IF v_job.id IS NULL THEN
    RAISE EXCEPTION 'Job % not found.', v_assignment.job_id;
  END IF;

  IF v_assignment.worker_id != v_caller AND v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized to view active job details.';
  END IF;

  SELECT * INTO v_worker FROM public.profiles WHERE id = v_assignment.worker_id;
  SELECT * INTO v_worker_profile FROM public.worker_profiles WHERE user_id = v_assignment.worker_id;
  SELECT * INTO v_provider FROM public.profiles WHERE id = v_job.provider_id;

  IF v_job.category_id IS NOT NULL THEN
    SELECT name, slug, COALESCE(icon, 'work') INTO v_category_name, v_category_slug, v_category_icon
    FROM public.service_categories WHERE id = v_job.category_id;
  END IF;

  IF v_job.location IS NOT NULL THEN
    v_job_lat := extensions.ST_Y(v_job.location::extensions.geometry);
    v_job_lng := extensions.ST_X(v_job.location::extensions.geometry);
  END IF;

  IF v_assignment.started_at IS NOT NULL THEN
    v_elapsed_seconds := FLOOR(EXTRACT(EPOCH FROM (COALESCE(v_assignment.ended_at, v_now) - v_assignment.started_at)))::INT;
    IF v_elapsed_seconds < 0 THEN
      v_elapsed_seconds := 0;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'assignment_id', v_assignment.id,
    'job_id', v_job.id,
    'booking_code', v_assignment.booking_code,
    'status', v_assignment.status::TEXT,
    'agreed_wage_paise', v_assignment.agreed_wage_paise,
    'protection_selected', COALESCE(v_assignment.protection_selected, false),
    'arrived_at', v_assignment.arrived_at,
    'started_at', v_assignment.started_at,
    'ended_at', v_assignment.ended_at,
    'elapsed_seconds', v_elapsed_seconds,
    'payment_eligible', COALESCE(v_assignment.payment_eligible, false),
    'extended_grace_minutes', COALESCE(v_assignment.extended_grace_minutes, 0),
    'late_notified_at', v_assignment.late_notified_at,
    'running_late_eta_minutes', v_assignment.running_late_eta_minutes,
    'running_late_reported_at', v_assignment.running_late_reported_at,
    'no_show_timer_paused', COALESCE(v_assignment.no_show_timer_paused, false),
    'replaced_by', v_assignment.replaced_by,
    'job_title', v_job.title,
    'job_description', v_job.description,
    'start_at', v_job.start_at,
    'est_duration_minutes', COALESCE(v_job.est_duration_minutes, 240),
    'address_text', COALESCE(v_job.address_text, ''),
    'job_lat', COALESCE(v_job_lat, 0.0),
    'job_lng', COALESCE(v_job_lng, 0.0),
    'category_name', v_category_name,
    'category_slug', v_category_slug,
    'category_icon', v_category_icon,
    'provider_id', v_provider.id,
    'provider_name', COALESCE(v_provider.full_name, 'Job Provider'),
    'provider_phone', v_provider.phone_number,
    'provider_avatar', v_provider.avatar_path,
    'provider_verified', true,
    'worker_id', v_worker.id,
    'worker_name', COALESCE(v_worker.full_name, 'Assigned Worker'),
    'worker_phone', v_worker.phone_number,
    'worker_avatar', v_worker.avatar_path,
    'worker_verified', COALESCE(v_worker_profile.is_verified_badge, false)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_active_job_details(UUID) TO authenticated;
