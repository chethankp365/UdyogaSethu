-- ============================================================================
-- Migration: 0651_tickets_qr.sql
-- Description: Ticket and QR management RPCs strictly built against live inventory.
--              Enforces worker-only ticket generation, provider-only QR scans,
--              removal of booking-code fallback, and real columns only.
-- ============================================================================

-- 1. DROP ALL EXISTING OVERLOADS BY NAME
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
      AND p.proname IN ('issue_job_ticket', 'get_rotating_ticket_token', 'verify_ticket_scan', 'record_ticket_attendance', 'get_active_job_details', 'get_next_accepted_ticket', 'record_verified_start')
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
  END LOOP;
END $$;

-- 2. issue_job_ticket (WORKER ONLY, real columns)
CREATE OR REPLACE FUNCTION public.issue_job_ticket(p_assignment_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_rec RECORD;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;

  SELECT
    ja.id AS assignment_id, ja.booking_code, ja.status::TEXT AS status, ja.job_id,
    ja.worker_id, ja.agreed_wage_paise, ja.started_at, ja.ended_at,
    j.title AS job_title, j.wage_type::TEXT AS wage_type, j.payment_mode::TEXT AS payment_mode,
    j.start_at, j.est_duration_minutes, j.address_text,
    extensions.ST_Y(j.location::extensions.geometry) AS lat,
    extensions.ST_X(j.location::extensions.geometry) AS lng,
    j.provider_id,
    COALESCE(sc.names->>'en', 'Work')::TEXT AS category_name,
    COALESCE(sc.icon, 'work')::TEXT AS category_icon,
    COALESCE(wp_prof.full_name, 'Worker')::TEXT AS worker_name,
    wp_prof.avatar_path::TEXT AS worker_avatar,
    COALESCE(wp.is_verified_badge, false) AS is_worker_verified,
    COALESCE(wp.seeker_type::TEXT, 'informal')::TEXT AS worker_seeker_type,
    COALESCE(prov_prof.full_name, 'Employer')::TEXT AS provider_name
  INTO v_rec
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  JOIN public.profiles wp_prof ON ja.worker_id = wp_prof.id
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  JOIN public.profiles prov_prof ON j.provider_id = prov_prof.id
  WHERE ja.id = p_assignment_id;

  IF v_rec.assignment_id IS NULL THEN RAISE EXCEPTION 'Assignment not found.'; END IF;
  IF v_rec.worker_id != v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only assigned worker can issue job ticket.';
  END IF;

  IF v_rec.status = 'accepted' THEN
    UPDATE public.job_assignments SET status = 'ticket_issued', updated_at = NOW() WHERE id = p_assignment_id;
    v_rec.status := 'ticket_issued';
  END IF;

  RETURN jsonb_build_object(
    'assignment_id', v_rec.assignment_id, 'booking_code', v_rec.booking_code,
    'status', v_rec.status, 'job_id', v_rec.job_id, 'job_title', v_rec.job_title,
    'category_name', v_rec.category_name, 'category_icon', v_rec.category_icon,
    'start_at', v_rec.start_at, 'est_duration_minutes', v_rec.est_duration_minutes,
    'agreed_wage_paise', v_rec.agreed_wage_paise, 'wage_type', v_rec.wage_type,
    'payment_mode', v_rec.payment_mode, 'address_text', v_rec.address_text,
    'lat', v_rec.lat, 'lng', v_rec.lng, 'worker_id', v_rec.worker_id,
    'worker_name', v_rec.worker_name, 'worker_avatar', v_rec.worker_avatar,
    'is_worker_verified', v_rec.is_worker_verified, 'worker_seeker_type', v_rec.worker_seeker_type,
    'provider_id', v_rec.provider_id, 'provider_name', v_rec.provider_name
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 3. get_rotating_ticket_token (WORKER ONLY, 120s TTL)
CREATE OR REPLACE FUNCTION public.get_rotating_ticket_token(
  p_assignment_id UUID, p_debug_short_ttl BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_worker_id UUID; v_token TEXT; v_hash TEXT;
  v_ttl INT := 120; v_expires TIMESTAMPTZ;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;
  SELECT worker_id INTO v_worker_id FROM public.job_assignments WHERE id = p_assignment_id;
  IF v_worker_id IS NULL THEN RAISE EXCEPTION 'Assignment not found.'; END IF;
  IF v_worker_id != v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only assigned worker can obtain rotating QR token.';
  END IF;

  IF p_debug_short_ttl THEN v_ttl := 15; END IF;
  v_expires := NOW() + (v_ttl || ' seconds')::INTERVAL;
  v_token := 'TKT-' || UPPER(SUBSTRING(encode(extensions.gen_random_bytes(16), 'hex'), 1, 24));
  v_hash := encode(extensions.digest(v_token, 'sha256'), 'hex');

  INSERT INTO public.qr_tokens (token_id_hash, user_id, purpose, expires_at, revoked, used, assignment_id)
  VALUES (v_hash, v_uid, 'ticket', v_expires, false, false, p_assignment_id);

  RETURN jsonb_build_object(
    'qr_token', v_token, 'expires_at', v_expires, 'expires_in_seconds', v_ttl, 'status', 'ticket_issued'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 4. verify_ticket_scan (PROVIDER ONLY, NO booking-code fallback, all stable rejection codes)
CREATE OR REPLACE FUNCTION public.verify_ticket_scan(
  p_token TEXT, p_provider_lat DOUBLE PRECISION DEFAULT NULL, p_provider_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_hash TEXT; v_qr RECORD; v_ja RECORD;
  v_loc extensions.geography(Point, 4326) := NULL;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'NOT_AUTHENTICATED', 'error_message', 'Sign in required.');
  END IF;
  IF p_token IS NULL OR LENGTH(TRIM(p_token)) = 0 THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'INVALID_TOKEN', 'error_message', 'Empty token provided.');
  END IF;

  IF p_provider_lat IS NOT NULL AND p_provider_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_provider_lng, p_provider_lat), 4326)::extensions.geography;
  END IF;

  v_hash := encode(extensions.digest(p_token, 'sha256'), 'hex');
  SELECT * INTO v_qr FROM public.qr_tokens WHERE token_id_hash = v_hash;

  IF v_qr.id IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'INVALID_TOKEN', 'error_message', 'Ticket QR token is invalid or tampered.');
  END IF;
  IF v_qr.revoked THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'TOKEN_REVOKED', 'error_message', 'Ticket has been revoked.');
  END IF;
  IF v_qr.used THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'TOKEN_ALREADY_USED', 'error_message', 'Ticket token has already been scanned.');
  END IF;
  IF v_qr.expires_at < NOW() THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'TOKEN_EXPIRED', 'error_message', 'Ticket token expired. Ask worker to refresh QR.');
  END IF;

  SELECT ja.*, j.provider_id, j.title AS job_title, j.location AS job_location, j.geofence_radius_m,
         p.full_name AS worker_name, p.avatar_path AS worker_avatar, COALESCE(wp.is_verified_badge, false) AS is_verified_badge
  INTO v_ja
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  JOIN public.profiles p ON ja.worker_id = p.id
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  WHERE ja.id = v_qr.assignment_id;

  IF v_ja.id IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'ASSIGNMENT_NOT_FOUND', 'error_message', 'Assignment not found.');
  END IF;
  IF v_ja.provider_id != v_uid AND NOT public.is_admin() THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'UNAUTHORIZED_SCANNER', 'error_message', 'Only designated job provider can scan attendance.');
  END IF;

  IF v_loc IS NOT NULL AND v_ja.job_location IS NOT NULL THEN
    IF extensions.ST_Distance(v_loc, v_ja.job_location) > COALESCE(v_ja.geofence_radius_m, 250) + 100 THEN
      INSERT INTO public.attendance_logs (assignment_id, scanned_by, token_id, location, result)
      VALUES (v_ja.id, v_uid, v_hash, v_loc, 'GEOFENCE_FAILED');
      RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'GEOFENCE_FAILED', 'error_message', 'Attendance scan outside permitted work geofence.');
    END IF;
  END IF;

  UPDATE public.qr_tokens SET used = true, used_at = NOW() WHERE id = v_qr.id;
  UPDATE public.job_assignments SET status = 'arrived', arrived_at = NOW(), employer_scan_location = v_loc, updated_at = NOW()
  WHERE id = v_ja.id;

  INSERT INTO public.attendance_logs (assignment_id, scanned_by, token_id, location, result)
  VALUES (v_ja.id, v_uid, v_hash, v_loc, 'SUCCESS');

  RETURN jsonb_build_object(
    'valid', true, 'status', 'verified', 'purpose', 'ticket',
    'assignment_id', v_ja.id, 'booking_code', v_ja.booking_code,
    'worker_id', v_ja.worker_id, 'worker_name', v_ja.worker_name,
    'worker_avatar', v_ja.worker_avatar, 'is_verified_badge', v_ja.is_verified_badge,
    'job_title', v_ja.job_title, 'arrived_at', NOW(), 'message', 'Attendance verified successfully.'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 5. record_ticket_attendance (delegating wrapper)
CREATE OR REPLACE FUNCTION public.record_ticket_attendance(
  p_assignment_id UUID, p_token_id TEXT, p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_scanned_by UUID DEFAULT NULL
)
RETURNS JSONB AS $$
BEGIN
  RETURN public.verify_ticket_scan(p_token_id, p_lat, p_lng);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 6. record_verified_start (Step-2 verification)
CREATE OR REPLACE FUNCTION public.record_verified_start(
  p_assignment_id UUID, p_selfie_path TEXT, p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_actor_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_uid UUID := COALESCE(p_actor_id, auth.uid());
  v_ja RECORD;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;
  SELECT ja.*, j.provider_id INTO v_ja FROM public.job_assignments ja JOIN public.jobs j ON ja.job_id = j.id WHERE ja.id = p_assignment_id;
  IF v_ja.id IS NULL THEN RAISE EXCEPTION 'Assignment not found.'; END IF;
  IF v_ja.worker_id != v_uid AND v_ja.provider_id != v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized.';
  END IF;

  UPDATE public.job_assignments
  SET status = 'in_progress_verified', started_at = COALESCE(started_at, NOW()),
      start_selfie_path = COALESCE(p_selfie_path, start_selfie_path), start_geo_ok = true, updated_at = NOW()
  WHERE id = p_assignment_id;
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 7. get_active_job_details & get_next_accepted_ticket
CREATE OR REPLACE FUNCTION public.get_active_job_details(p_assignment_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_res JSONB;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;

  SELECT jsonb_build_object(
    'assignment_id', ja.id, 'status', ja.status, 'booking_code', ja.booking_code,
    'started_at', ja.started_at, 'ended_at', ja.ended_at, 'arrived_at', ja.arrived_at,
    'elapsed_seconds', ja.elapsed_seconds, 'agreed_wage_paise', ja.agreed_wage_paise,
    'job_id', j.id, 'title', j.title, 'description', j.description,
    'address_text', j.address_text, 'lat', extensions.ST_Y(j.location::extensions.geometry),
    'lng', extensions.ST_X(j.location::extensions.geometry),
    'worker_id', ja.worker_id, 'worker_name', wp.full_name, 'worker_avatar', wp.avatar_path,
    'provider_id', j.provider_id, 'provider_name', pp.full_name
  ) INTO v_res
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  JOIN public.profiles wp ON ja.worker_id = wp.id
  JOIN public.profiles pp ON j.provider_id = pp.id
  WHERE ja.id = p_assignment_id AND (ja.worker_id = v_uid OR j.provider_id = v_uid OR public.is_admin());

  IF v_res IS NULL THEN RAISE EXCEPTION 'Assignment not found or unauthorized.'; END IF;
  RETURN v_res;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

CREATE OR REPLACE FUNCTION public.get_next_accepted_ticket()
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_rec RECORD;
BEGIN
  IF v_uid IS NULL THEN RETURN jsonb_build_object('has_ticket', false); END IF;
  SELECT ja.id AS assignment_id, j.id AS job_id, j.title, j.start_at
  INTO v_rec
  FROM public.job_assignments ja JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.worker_id = v_uid AND ja.status IN ('accepted', 'ticket_issued', 'arrived')
  ORDER BY j.start_at ASC LIMIT 1;

  IF v_rec.assignment_id IS NULL THEN RETURN jsonb_build_object('has_ticket', false); END IF;
  RETURN jsonb_build_object('has_ticket', true, 'assignment_id', v_rec.assignment_id, 'job_id', v_rec.job_id, 'title', v_rec.title, 'start_at', v_rec.start_at);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 8. PERMISSIONS & GRANTS
GRANT EXECUTE ON FUNCTION public.issue_job_ticket(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_rotating_ticket_token(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_ticket_scan(TEXT, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_ticket_attendance(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_verified_start(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_active_job_details(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_next_accepted_ticket() TO authenticated;

-- Verification query
SELECT proname, pg_get_function_identity_arguments(oid) AS args
FROM pg_proc WHERE pronamespace = 'public'::regnamespace
  AND proname IN ('issue_job_ticket', 'get_rotating_ticket_token', 'verify_ticket_scan', 'record_ticket_attendance', 'record_verified_start', 'get_active_job_details', 'get_next_accepted_ticket');

NOTIFY pgrst, 'reload schema';
