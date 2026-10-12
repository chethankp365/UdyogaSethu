-- ============================================================================
-- Migration: 0660_real_qr_ticket_flow.sql
-- Description: Real QR ticket flow end-to-end:
--              1. Rotating token generation (120s TTL, admin_settings controlled)
--              2. Atomic race-safe verify_ticket_scan with 10 stable rejection codes:
--                 EXPIRED, ALREADY_USED, WRONG_EMPLOYER, WRONG_JOB, NOT_YET_VALID,
--                 TOO_LATE, CANCELLED, WORKER_SUSPENDED, TAMPERED, DUPLICATE_CHECKIN
--              3. Step-2 live selfie & GPS geofence verification
--              4. Next accepted ticket query for Digital ID card (omits checked-in)
-- ============================================================================

-- 1. Seed timing controls in admin_settings
INSERT INTO public.admin_settings (key, value)
VALUES 
  ('ticket_valid_before_minutes', '60'::jsonb),
  ('ticket_valid_after_minutes', '120'::jsonb),
  ('qr_ticket_expiry_seconds', '120'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 2. Drop existing function overloads to prevent ambiguous signature issues
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
      AND p.proname IN ('get_rotating_ticket_token', 'verify_ticket_scan', 'record_step2_verification', 'get_next_accepted_ticket')
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
  END LOOP;
END $$;

-- 3. get_rotating_ticket_token (WORKER ONLY, 2-minute rotation, non-PII token)
CREATE OR REPLACE FUNCTION public.get_rotating_ticket_token(
  p_assignment_id UUID, p_debug_short_ttl BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_worker_id UUID; v_token TEXT; v_hash TEXT;
  v_ttl INT := 120; v_expires TIMESTAMPTZ; v_setting TEXT;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;
  SELECT worker_id INTO v_worker_id FROM public.job_assignments WHERE id = p_assignment_id;
  IF v_worker_id IS NULL THEN RAISE EXCEPTION 'Assignment not found.'; END IF;
  IF v_worker_id != v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only assigned worker can obtain rotating QR token.';
  END IF;

  SELECT value INTO v_setting FROM public.admin_settings WHERE key = 'qr_ticket_expiry_seconds';
  IF v_setting IS NOT NULL AND v_setting ~ '^\d+$' THEN v_ttl := v_setting::INT; END IF;
  IF p_debug_short_ttl THEN v_ttl := 15; END IF;
  v_expires := NOW() + (v_ttl || ' seconds')::INTERVAL;
  v_token := 'TKT-' || UPPER(SUBSTRING(encode(extensions.gen_random_bytes(16), 'hex'), 1, 24));
  v_hash := encode(extensions.digest(v_token, 'sha256'), 'hex');

  INSERT INTO public.qr_tokens (token_id_hash, user_id, purpose, expires_at, revoked, used, assignment_id)
  VALUES (v_hash, v_uid, 'ticket', v_expires, false, false, p_assignment_id);

  UPDATE public.job_assignments SET status = 'ticket_issued', updated_at = NOW()
  WHERE id = p_assignment_id AND status = 'accepted';

  RETURN jsonb_build_object('qr_token', v_token, 'expires_at', v_expires, 'expires_in_seconds', v_ttl, 'status', 'ticket_issued');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 4. verify_ticket_scan (PROVIDER ONLY, atomic race-safe check, 10 stable rejection codes)
CREATE OR REPLACE FUNCTION public.verify_ticket_scan(
  p_token TEXT, p_provider_lat DOUBLE PRECISION DEFAULT NULL, p_provider_lng DOUBLE PRECISION DEFAULT NULL, p_job_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_hash TEXT; v_qr RECORD; v_ja RECORD;
  v_loc extensions.geography(Point, 4326) := NULL;
  v_before_min INT := 60; v_after_min INT := 120; v_setting TEXT;
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

  SELECT value INTO v_setting FROM public.admin_settings WHERE key = 'ticket_valid_before_minutes';
  IF v_setting IS NOT NULL AND v_setting ~ '^\d+$' THEN v_before_min := v_setting::INT; END IF;
  SELECT value INTO v_setting FROM public.admin_settings WHERE key = 'ticket_valid_after_minutes';
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

  -- Lock assignment row
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

-- 5. record_step2_verification (Live selfie + GPS reading with geofence check)
CREATE OR REPLACE FUNCTION public.record_step2_verification(
  p_assignment_id UUID, p_selfie_path TEXT, p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_face_score DOUBLE PRECISION DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_ja RECORD; v_loc extensions.geography(Point, 4326) := NULL;
  v_dist DOUBLE PRECISION := 0; v_rad INT := 150;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;
  SELECT ja.*, j.provider_id, j.location AS job_location, COALESCE(j.geofence_radius_m, 150) AS job_radius
  INTO v_ja FROM public.job_assignments ja JOIN public.jobs j ON ja.job_id = j.id WHERE ja.id = p_assignment_id;

  IF v_ja.id IS NULL THEN RAISE EXCEPTION 'Assignment not found.'; END IF;
  IF v_ja.worker_id != v_uid AND v_ja.provider_id != v_uid AND NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized.'; END IF;
  v_rad := v_ja.job_radius;

  IF p_lat IS NOT NULL AND p_lng IS NOT NULL AND v_ja.job_location IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
    v_dist := extensions.ST_Distance(v_loc, v_ja.job_location);
    IF v_dist > v_rad THEN
      INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
      VALUES (v_ja.id, 'step2_failed', v_uid, jsonb_build_object('reason', 'outside_geofence', 'distance_meters', v_dist, 'radius_meters', v_rad));
      RETURN jsonb_build_object('success', false, 'reason_code', 'outside_geofence', 'distance_meters', v_dist, 'radius_meters', v_rad,
        'message', 'Outside the site geofence by ' || ROUND((v_dist - v_rad)::NUMERIC, 0) || 'm.');
    END IF;
  END IF;

  UPDATE public.job_assignments SET status = 'in_progress_verified', started_at = COALESCE(started_at, NOW()),
    start_selfie_path = COALESCE(p_selfie_path, start_selfie_path), start_geo_ok = true, updated_at = NOW() WHERE id = p_assignment_id;
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
  VALUES (v_ja.id, 'selfie_gps_verified', v_uid, jsonb_build_object('selfie_path', p_selfie_path, 'distance_meters', v_dist, 'face_score', p_face_score));
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
  VALUES (v_ja.id, 'in_progress_verified', v_uid, jsonb_build_object('started_at', NOW()));

  RETURN jsonb_build_object('success', true, 'status', 'in_progress_verified', 'started_at', NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 6. get_next_accepted_ticket (Earliest accepted assignment that has NOT yet checked in)
CREATE OR REPLACE FUNCTION public.get_next_accepted_ticket()
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid(); v_rec RECORD;
BEGIN
  IF v_uid IS NULL THEN RETURN jsonb_build_object('has_ticket', false); END IF;
  SELECT ja.id AS assignment_id, ja.booking_code, j.id AS job_id, j.title, j.start_at,
         COALESCE(p.full_name, 'Employer') AS provider_name
  INTO v_rec
  FROM public.job_assignments ja JOIN public.jobs j ON ja.job_id = j.id JOIN public.profiles p ON j.provider_id = p.id
  WHERE ja.worker_id = v_uid AND ja.status IN ('accepted', 'ticket_issued')
  ORDER BY j.start_at ASC LIMIT 1;

  IF v_rec.assignment_id IS NULL THEN RETURN jsonb_build_object('has_ticket', false); END IF;
  RETURN jsonb_build_object('has_ticket', true, 'assignment_id', v_rec.assignment_id, 'booking_code', v_rec.booking_code,
    'job_id', v_rec.job_id, 'title', v_rec.title, 'start_at', v_rec.start_at, 'provider_name', v_rec.provider_name);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 7. Permissions and Grants
GRANT EXECUTE ON FUNCTION public.get_rotating_ticket_token(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_ticket_scan(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_step2_verification(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_next_accepted_ticket() TO authenticated;

SELECT proname, pg_get_function_identity_arguments(oid) AS args
FROM pg_proc WHERE pronamespace = 'public'::regnamespace
  AND proname IN ('get_rotating_ticket_token', 'verify_ticket_scan', 'record_step2_verification', 'get_next_accepted_ticket');

NOTIFY pgrst, 'reload schema';
