-- Migration: 0610_job_execution_ticket_qr_polish.sql
-- Description: Polished server-authoritative job execution lifecycle, atomic check-in verification with stable error codes, timing window configuration, and debug window helpers.
--
-- Relies on:
--   Migrations:
--     - 0010_identity.sql
--     - 0020_marketplace.sql
--     - 0030_money_trust.sql
--     - 0040_engagement_admin.sql
--     - 0580_job_execution_tickets_qr_lifecycle.sql
--   Tables:
--     - public.admin_settings (key, value, updated_at)
--     - public.job_assignments (id, job_id, worker_id, status, booking_code, agreed_wage_paise, protection_selected, arrived_at, started_at, ended_at, start_selfie_path, start_geo_ok, employer_scan_location, payment_eligible, updated_at)
--     - public.jobs (id, provider_id, title, description, start_at, est_duration_minutes, address_text, location, geofence_radius_m, wage_amount_paise, wage_type, payment_mode, category_id, is_demo)
--     - public.qr_tokens (id, token_id_hash, user_id, purpose, assignment_id, expires_at, revoked, used, used_at, created_at)
--     - public.attendance_logs (id, assignment_id, scanned_by, token_id, location, result, created_at)
--     - public.assignment_events (id, assignment_id, event_type, actor_id, actor_role, meta, created_at)
--     - public.profiles (id, full_name, phone_number, avatar_path, is_active)
--     - public.worker_profiles (user_id, seeker_type, is_verified_badge)
--     - public.notifications (user_id, type, title_key, body_key, params, created_at)
--   Functions:
--     - auth.uid()
--     - public.is_admin()
--     - extensions.digest(text, text)
--     - extensions.ST_SetSRID(geometry, int)
--     - extensions.ST_MakePoint(double, double)

-- 1. Ensure admin settings for ticket validation windows and token rotation
INSERT INTO public.admin_settings (key, value)
VALUES
  ('ticket_valid_minutes_before', '60'::jsonb),
  ('ticket_valid_minutes_after', '120'::jsonb),
  ('ticket_token_ttl_seconds', '120'::jsonb),
  ('ticket_debug_short_ttl_seconds', 'null'::jsonb)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value, updated_at = NOW();

-- 2. Debug Helper RPC: set_ticket_timing_debug (for quick expiry & window testing)
CREATE OR REPLACE FUNCTION public.set_ticket_timing_debug(
  p_short_ttl_seconds INT DEFAULT NULL,
  p_minutes_before INT DEFAULT NULL,
  p_minutes_after INT DEFAULT NULL
)
RETURNS JSONB AS $$
BEGIN
  IF p_short_ttl_seconds IS NOT NULL THEN
    INSERT INTO public.admin_settings (key, value, updated_at)
    VALUES ('ticket_debug_short_ttl_seconds', to_jsonb(p_short_ttl_seconds), NOW())
    ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
  ELSE
    UPDATE public.admin_settings SET value = 'null'::jsonb, updated_at = NOW()
    WHERE key = 'ticket_debug_short_ttl_seconds';
  END IF;

  IF p_minutes_before IS NOT NULL THEN
    INSERT INTO public.admin_settings (key, value, updated_at)
    VALUES ('ticket_valid_minutes_before', to_jsonb(p_minutes_before), NOW())
    ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
  END IF;

  IF p_minutes_after IS NOT NULL THEN
    INSERT INTO public.admin_settings (key, value, updated_at)
    VALUES ('ticket_valid_minutes_after', to_jsonb(p_minutes_after), NOW())
    ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'short_ttl', p_short_ttl_seconds,
    'minutes_before', p_minutes_before,
    'minutes_after', p_minutes_after
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.set_ticket_timing_debug(INT, INT, INT) TO authenticated;

-- 3. Atomic verify_ticket_scan with stable error codes and race safety
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
  v_clean_token TEXT;
  v_parts TEXT[];
  v_payload_json JSONB;
  v_tid TEXT;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'AUTH_REQUIRED',
      'error_code', 'AUTH_REQUIRED',
      'message', 'Authentication required to scan tickets.'
    );
  END IF;

  IF p_token IS NULL OR LENGTH(TRIM(p_token)) < 4 THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'TAMPERED',
      'error_code', 'TAMPERED',
      'message', 'Malformed or invalid ticket token.'
    );
  END IF;

  v_clean_token := TRIM(p_token);

  -- Check if token is signed format: <payload_base64>.<signature_base64>
  IF v_clean_token LIKE '%.%' THEN
    v_parts := string_to_array(v_clean_token, '.');
    BEGIN
      v_payload_json := convert_from(extensions.decode(replace(replace(v_parts[1], '-', '+'), '_', '/'), 'base64'), 'UTF8')::JSONB;
      v_tid := v_payload_json ->> 'tid';
      IF v_tid IS NULL THEN
        v_tid := v_payload_json ->> 'jti';
      END IF;
      IF v_tid IS NOT NULL THEN
        v_hash := encode(extensions.digest(v_tid, 'sha256'), 'hex');
      ELSE
        v_hash := encode(extensions.digest(v_clean_token, 'sha256'), 'hex');
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_hash := encode(extensions.digest(v_clean_token, 'sha256'), 'hex');
    END;
  ELSE
    v_hash := encode(extensions.digest(v_clean_token, 'sha256'), 'hex');
  END IF;

  -- 1. Atomic row lock on token row (race safe: two concurrent scans lock on same row)
  SELECT * INTO v_qr
  FROM public.qr_tokens
  WHERE (token_id_hash = v_hash OR token_id_hash = encode(extensions.digest(v_clean_token, 'sha256'), 'hex'))
    AND purpose = 'ticket'
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  -- 2. If token row not found, fallback to booking code lookup
  IF v_qr.id IS NULL THEN
    SELECT ja.* INTO v_assignment
    FROM public.job_assignments ja
    WHERE ja.booking_code = REPLACE(UPPER(v_clean_token), 'TICKET-', '')
    LIMIT 1;

    IF v_assignment.id IS NULL THEN
      RETURN jsonb_build_object(
        'valid', false,
        'status_code', 'TAMPERED',
        'error_code', 'TAMPERED',
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
      'status_code', 'TAMPERED',
      'error_code', 'TAMPERED',
      'message', 'Job assignment not found for this ticket.'
    );
  END IF;

  -- 3. Check revoked
  IF v_qr.id IS NOT NULL AND v_qr.revoked THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'CANCELLED',
      'error_code', 'CANCELLED',
      'message', 'This ticket token has been revoked.'
    );
  END IF;

  -- 4. Check already used (atomic replay refusal)
  IF v_qr.id IS NOT NULL AND v_qr.used THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'ALREADY_USED',
      'error_code', 'ALREADY_USED',
      'scanned_at', to_char(COALESCE(v_qr.used_at, v_now) AT TIME ZONE 'Asia/Kolkata', 'hh:mi AM'),
      'message', 'Already scanned at ' || to_char(COALESCE(v_qr.used_at, v_now) AT TIME ZONE 'Asia/Kolkata', 'hh:mi AM')
    );
  END IF;

  -- 5. Check token expiry
  IF v_qr.id IS NOT NULL AND v_qr.expires_at < v_now THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'EXPIRED',
      'error_code', 'EXPIRED',
      'expired_at', to_char(v_qr.expires_at AT TIME ZONE 'Asia/Kolkata', 'hh:mi AM'),
      'message', 'QR expired at ' || to_char(v_qr.expires_at AT TIME ZONE 'Asia/Kolkata', 'hh:mi AM') || ', ask the worker to refresh'
    );
  END IF;

  -- 6. Fetch job
  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;
  IF v_job.id IS NULL THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'TAMPERED',
      'error_code', 'TAMPERED',
      'message', 'Associated job not found.'
    );
  END IF;

  -- 7. Check provider authority (WRONG_EMPLOYER)
  IF v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'WRONG_EMPLOYER',
      'error_code', 'WRONG_EMPLOYER',
      'message', 'You are not the designated employer for this job assignment.'
    );
  END IF;

  -- 8. Check worker account active status (WORKER_SUSPENDED)
  SELECT * INTO v_worker FROM public.profiles WHERE id = v_assignment.worker_id;
  IF v_worker.is_active = false THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'WORKER_SUSPENDED',
      'error_code', 'WORKER_SUSPENDED',
      'message', 'Worker account has been suspended.'
    );
  END IF;

  -- 9. Check assignment status (CANCELLED / DUPLICATE_CHECKIN)
  IF v_assignment.status IN ('cancelled', 'provider_cancelled', 'worker_cancelled', 'rejected') THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'CANCELLED',
      'error_code', 'CANCELLED',
      'message', 'This job assignment was cancelled.'
    );
  END IF;

  IF v_assignment.status IN ('arrived', 'in_progress_verified', 'job_started', 'in_progress', 'completed', 'payment_released') THEN
    RETURN jsonb_build_object(
      'valid', false,
      'status_code', 'DUPLICATE_CHECKIN',
      'error_code', 'DUPLICATE_CHECKIN',
      'message', 'Worker has already checked in.'
    );
  END IF;

  -- 10. Check timing window against start_at (NOT_YET_VALID / TOO_LATE)
  IF v_job.start_at IS NOT NULL THEN
    SELECT COALESCE((value #>> '{}')::INT, 60) INTO v_min_before
    FROM public.admin_settings WHERE key = 'ticket_valid_minutes_before';

    SELECT COALESCE((value #>> '{}')::INT, 120) INTO v_min_after
    FROM public.admin_settings WHERE key = 'ticket_valid_minutes_after';

    IF v_now < (v_job.start_at - (v_min_before || ' minutes')::INTERVAL) THEN
      RETURN jsonb_build_object(
        'valid', false,
        'status_code', 'NOT_YET_VALID',
        'error_code', 'NOT_YET_VALID',
        'message', 'Ticket is not yet valid. Check-in opens ' || v_min_before || ' minutes before start time.'
      );
    END IF;

    IF v_now > (v_job.start_at + (v_min_after || ' minutes')::INTERVAL) THEN
      RETURN jsonb_build_object(
        'valid', false,
        'status_code', 'TOO_LATE',
        'error_code', 'TOO_LATE',
        'message', 'Ticket is no longer valid. Permitted check-in window has elapsed.'
      );
    END IF;
  END IF;

  -- 11. Consume token atomically
  IF v_qr.id IS NOT NULL THEN
    UPDATE public.qr_tokens
    SET used = true, used_at = v_now
    WHERE id = v_qr.id;
  END IF;

  IF p_provider_lat IS NOT NULL AND p_provider_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_provider_lng, p_provider_lat), 4326)::extensions.geography;
  END IF;

  -- 12. Record in attendance_logs
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
    COALESCE(v_qr.token_id_hash, v_clean_token),
    v_loc,
    'arrived',
    v_now
  );

  -- 13. Advance assignment status to 'arrived'
  UPDATE public.job_assignments
  SET status = 'arrived',
      arrived_at = v_now,
      employer_scan_location = v_loc,
      updated_at = v_now
  WHERE id = v_assignment.id;

  -- 14. Record transition event in assignment_events
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

  -- 15. Realtime notification to worker for Step 2
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
    jsonb_build_object(
      'assignment_id', v_assignment.id,
      'job_title', v_job.title,
      'step', 2
    ),
    v_now
  );

  SELECT * INTO v_worker_profile FROM public.worker_profiles WHERE user_id = v_assignment.worker_id;

  RETURN jsonb_build_object(
    'valid', true,
    'status_code', 'SUCCESS',
    'status', 'arrived',
    'assignment_id', v_assignment.id,
    'booking_code', v_assignment.booking_code,
    'worker_id', v_worker.id,
    'worker_name', COALESCE(v_worker.full_name, 'Worker'),
    'worker_avatar', v_worker.avatar_path,
    'is_worker_verified', COALESCE(v_worker_profile.is_verified_badge, false),
    'job_title', v_job.title,
    'arrived_at', v_now
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.verify_ticket_scan(TEXT, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
