-- ============================================================================
-- Migration 0827: Fix verify_ticket_scan and issue_job_ticket QR Generation
-- Description:
--   1. Fixes verify_ticket_scan() enum type cast bug (invalid input value for enum assignment_status: "rejected")
--   2. Supports p_job_id matching either jobs.id OR job_assignments.id
--   3. Adds fallback support for scanning booking codes (BOOK-XXXXXX or TICKET-BOOK-XXXXXX)
--   4. Relaxes arrival window check so designated provider is never blocked by rigid timing
--   5. Enhances issue_job_ticket() to automatically generate and return a fresh qr_token
-- ============================================================================

-- 1. ENHANCE issue_job_ticket() TO GENERATE & RETURN FRESH QR TOKEN IMMEDIATELY
CREATE OR REPLACE FUNCTION public.issue_job_ticket(p_assignment_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_rec RECORD;
  v_resolved_id UUID := p_assignment_id;
  v_token TEXT;
  v_hash TEXT;
  v_ttl INT := 120;
  v_expires TIMESTAMPTZ;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Check direct assignment match
  SELECT id INTO v_resolved_id
  FROM public.job_assignments
  WHERE id = p_assignment_id;

  -- Defensive fallback: resolve via application_id
  IF v_resolved_id IS NULL THEN
    SELECT ja.id INTO v_resolved_id
    FROM public.job_assignments ja
    JOIN public.job_applications app ON ja.job_id = app.job_id AND ja.worker_id = app.worker_id
    WHERE app.id = p_assignment_id
    ORDER BY ja.created_at DESC
    LIMIT 1;
  END IF;

  -- Defensive fallback: resolve via job_id
  IF v_resolved_id IS NULL THEN
    SELECT ja.id INTO v_resolved_id
    FROM public.job_assignments ja
    WHERE ja.job_id = p_assignment_id AND ja.worker_id = v_uid
    ORDER BY ja.created_at DESC
    LIMIT 1;
  END IF;

  IF v_resolved_id IS NULL THEN
    RAISE EXCEPTION 'Assignment not found.';
  END IF;

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
  WHERE ja.id = v_resolved_id;

  IF v_rec.assignment_id IS NULL THEN
    RAISE EXCEPTION 'Assignment not found.';
  END IF;

  IF v_rec.worker_id != v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only assigned worker can issue job ticket.';
  END IF;

  IF v_rec.status IN ('accepted', 'requested') THEN
    UPDATE public.job_assignments SET status = 'ticket_issued', updated_at = NOW() WHERE id = v_resolved_id;
    v_rec.status := 'ticket_issued';
  END IF;

  -- Generate immediate rotating QR token
  v_expires := NOW() + (v_ttl || ' seconds')::INTERVAL;
  v_token := 'TKT-' || UPPER(SUBSTRING(encode(extensions.gen_random_bytes(16), 'hex') FROM 1 FOR 24));
  v_hash := encode(extensions.digest(v_token, 'sha256'), 'hex');

  INSERT INTO public.qr_tokens (
    assignment_id,
    user_id,
    token_id_hash,
    purpose,
    expires_at,
    created_at
  )
  VALUES (
    v_resolved_id,
    v_rec.worker_id,
    v_hash,
    'ticket',
    v_expires,
    NOW()
  );

  RETURN jsonb_build_object(
    'assignment_id', v_rec.assignment_id,
    'booking_code', v_rec.booking_code,
    'status', v_rec.status,
    'job_id', v_rec.job_id,
    'job_title', v_rec.job_title,
    'category_name', v_rec.category_name,
    'category_icon', v_rec.category_icon,
    'start_at', v_rec.start_at,
    'est_duration_minutes', v_rec.est_duration_minutes,
    'agreed_wage_paise', v_rec.agreed_wage_paise,
    'wage_type', v_rec.wage_type,
    'payment_mode', v_rec.payment_mode,
    'address_text', v_rec.address_text,
    'lat', v_rec.lat,
    'lng', v_rec.lng,
    'worker_id', v_rec.worker_id,
    'worker_name', v_rec.worker_name,
    'worker_avatar', v_rec.worker_avatar,
    'is_worker_verified', v_rec.is_worker_verified,
    'worker_seeker_type', v_rec.worker_seeker_type,
    'provider_id', v_rec.provider_id,
    'provider_name', v_rec.provider_name,
    'qr_token', v_token,
    'expires_in_seconds', v_ttl,
    'expires_at', v_expires
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.issue_job_ticket(UUID) TO authenticated, anon;


-- 2. ROBUST verify_ticket_scan() FUNCTION
CREATE OR REPLACE FUNCTION public.verify_ticket_scan(
  p_token TEXT,
  p_provider_lat DOUBLE PRECISION DEFAULT NULL,
  p_provider_lng DOUBLE PRECISION DEFAULT NULL,
  p_job_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_hash TEXT;
  v_qr RECORD;
  v_ja RECORD;
  v_loc extensions.geography(Point, 4326) := NULL;
  v_clean_token TEXT;
  v_asg_id UUID := NULL;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'NOT_AUTHENTICATED', 'error_message', 'Sign in required.');
  END IF;

  IF p_token IS NULL OR LENGTH(TRIM(p_token)) = 0 THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'TAMPERED', 'error_message', 'Empty or missing QR token.');
  END IF;

  v_clean_token := TRIM(p_token);

  IF p_provider_lat IS NOT NULL AND p_provider_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_provider_lng, p_provider_lat), 4326)::extensions.geography;
  END IF;

  -- 1. Try resolving as rotating token hash from qr_tokens
  v_hash := encode(extensions.digest(v_clean_token, 'sha256'), 'hex');

  SELECT * INTO v_qr FROM public.qr_tokens WHERE token_id_hash = v_hash FOR UPDATE;

  IF v_qr.id IS NOT NULL THEN
    IF v_qr.revoked THEN
      RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'TOKEN_REVOKED', 'error_message', 'This ticket QR has been revoked.');
    END IF;

    IF v_qr.used THEN
      RETURN jsonb_build_object(
        'valid', false,
        'status', 'error',
        'error_code', 'ALREADY_USED',
        'error_message', 'Already scanned at ' || to_char(COALESCE(v_qr.used_at, NOW())::TIME, 'HH24:MI'),
        'scanned_at', to_char(COALESCE(v_qr.used_at, NOW())::TIME, 'HH24:MI')
      );
    END IF;

    IF v_qr.expires_at < NOW() THEN
      RETURN jsonb_build_object(
        'valid', false,
        'status', 'error',
        'error_code', 'EXPIRED',
        'error_message', 'QR expired at ' || to_char(v_qr.expires_at::TIME, 'HH24:MI') || ', ask the worker to refresh',
        'expired_at', to_char(v_qr.expires_at::TIME, 'HH24:MI')
      );
    END IF;

    -- Atomically consume token
    UPDATE public.qr_tokens SET used = true, used_at = NOW() WHERE id = v_qr.id;
    v_asg_id := v_qr.assignment_id;

  ELSE
    -- 2. Fallback: Check if token is a direct booking code (BOOK-XXXXXX or TICKET-BOOK-XXXXXX)
    DECLARE
      v_code_candidate TEXT := UPPER(REPLACE(v_clean_token, 'TICKET-', ''));
    BEGIN
      SELECT id INTO v_asg_id
      FROM public.job_assignments
      WHERE UPPER(booking_code) = v_code_candidate
      LIMIT 1;

      IF v_asg_id IS NULL THEN
        -- Also check if token is assignment UUID directly
        BEGIN
          SELECT id INTO v_asg_id
          FROM public.job_assignments
          WHERE id = v_clean_token::UUID;
        EXCEPTION WHEN OTHERS THEN
          v_asg_id := NULL;
        END;
      END IF;
    END;

    IF v_asg_id IS NULL THEN
      RETURN jsonb_build_object(
        'valid', false,
        'status', 'error',
        'error_code', 'TAMPERED',
        'error_message', 'Ticket QR code could not be verified or was tampered.'
      );
    END IF;
  END IF;

  -- 3. Lock and retrieve assignment row
  SELECT ja.*, j.provider_id, j.title AS job_title, j.location AS job_location, j.geofence_radius_m,
         j.start_at, j.status AS job_status, p.full_name AS worker_name, p.avatar_path AS worker_avatar,
         COALESCE(p.is_suspended, false) AS worker_suspended, COALESCE(wp.is_verified_badge, false) AS is_verified_badge
  INTO v_ja
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  JOIN public.profiles p ON ja.worker_id = p.id
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  WHERE ja.id = v_asg_id
  FOR UPDATE OF ja;

  IF v_ja.id IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'ASSIGNMENT_NOT_FOUND', 'error_message', 'Assignment not found.');
  END IF;

  -- 4. Employer authorization check
  IF v_ja.provider_id != v_uid AND NOT public.is_admin() THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'WRONG_EMPLOYER', 'error_message', 'You are not the designated employer for this job assignment.');
  END IF;

  -- 5. Match p_job_id against EITHER jobs.id OR job_assignments.id
  IF p_job_id IS NOT NULL AND v_ja.job_id != p_job_id AND v_ja.id != p_job_id THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'WRONG_JOB', 'error_message', 'This ticket is for a different job assignment.');
  END IF;

  -- 6. Worker suspended check
  IF v_ja.worker_suspended THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'WORKER_SUSPENDED', 'error_message', 'This worker account is currently suspended.');
  END IF;

  -- 7. Safe text comparison on assignment status (prevents enum cast crash)
  IF v_ja.status::TEXT IN ('cancelled', 'rejected') OR v_ja.job_status::TEXT = 'cancelled' THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'CANCELLED', 'error_message', 'This job assignment was cancelled.');
  END IF;

  IF v_ja.status::TEXT IN ('arrived', 'in_progress', 'in_progress_verified', 'completed', 'payment_released') THEN
    RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'DUPLICATE_CHECKIN', 'error_message', 'Worker has already checked in on site.');
  END IF;

  -- 8. Arrival time check (relaxed to permit early arrivals by designated employer on same/next day)
  IF v_ja.start_at IS NOT NULL THEN
    IF NOW() < v_ja.start_at - INTERVAL '48 hours' THEN
      RETURN jsonb_build_object('valid', false, 'status', 'error', 'error_code', 'NOT_YET_VALID', 'error_message', 'Ticket is not yet valid. Check-in opens on the job date.');
    END IF;
  END IF;

  -- 9. Successfully record arrival
  UPDATE public.job_assignments
  SET status = 'arrived',
      arrived_at = NOW(),
      employer_scan_location = v_loc,
      updated_at = NOW()
  WHERE id = v_ja.id;

  INSERT INTO public.attendance_logs (assignment_id, scanned_by, token_id, location, result)
  VALUES (v_ja.id, v_uid, COALESCE(v_hash, encode(extensions.digest(v_clean_token, 'sha256'), 'hex')), v_loc, 'SUCCESS');

  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
  VALUES (v_ja.id, 'arrived', v_uid, jsonb_build_object('arrived_at', NOW()));

  RETURN jsonb_build_object(
    'valid', true,
    'status', 'arrived',
    'purpose', 'ticket',
    'assignment_id', v_ja.id,
    'booking_code', v_ja.booking_code,
    'worker_id', v_ja.worker_id,
    'worker_name', v_ja.worker_name,
    'worker_avatar', v_ja.worker_avatar,
    'is_verified_badge', v_ja.is_verified_badge,
    'job_title', v_ja.job_title,
    'arrived_at', NOW(),
    'message', 'Attendance verified successfully.'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_ticket_scan(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, UUID) TO authenticated, anon;
