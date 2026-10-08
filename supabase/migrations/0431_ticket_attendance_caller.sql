-- Migration: 0431_ticket_attendance_caller.sql
-- Description: Allow passing p_scanned_by UUID in record_ticket_attendance for Edge Function service-role calls

CREATE OR REPLACE FUNCTION public.record_ticket_attendance(
  p_assignment_id UUID,
  p_token_id TEXT,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_scanned_by UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID;
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_worker public.profiles%ROWTYPE;
  v_worker_profile public.worker_profiles%ROWTYPE;
  v_now TIMESTAMPTZ := NOW();
  v_loc extensions.geography := NULL;
  v_token_hash TEXT;
BEGIN
  v_caller := COALESCE(auth.uid(), p_scanned_by);
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_assignment FROM public.job_assignments WHERE id = p_assignment_id FOR UPDATE;
  IF v_assignment.id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;
  IF v_job.id IS NULL THEN
    RAISE EXCEPTION 'Job % not found.', v_assignment.job_id;
  END IF;

  -- Must be the employer/provider of the job or admin
  IF v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the assigned job provider can record attendance.';
  END IF;

  -- Assignment status check: must be ticket_issued (or accepted)
  IF v_assignment.status != 'ticket_issued' AND v_assignment.status != 'accepted' THEN
    RAISE EXCEPTION 'Illegal status for attendance check-in: %. Expected ticket_issued.', v_assignment.status;
  END IF;

  -- Replay check in attendance_logs
  IF EXISTS (SELECT 1 FROM public.attendance_logs WHERE token_id = p_token_id) THEN
    RAISE EXCEPTION 'This QR ticket token has already been used.';
  END IF;

  -- Build geography point if coordinates supplied
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  END IF;

  -- Insert into attendance_logs
  INSERT INTO public.attendance_logs (
    assignment_id,
    scanned_by,
    token_id,
    location,
    result,
    created_at
  ) VALUES (
    p_assignment_id,
    v_caller,
    p_token_id,
    v_loc,
    'arrived',
    v_now
  );

  -- Mark token used in qr_tokens
  v_token_hash := encode(digest(p_token_id, 'sha256'), 'hex');
  UPDATE public.qr_tokens
  SET used = true, used_at = v_now
  WHERE token_id_hash = v_token_hash;

  -- Update job assignment to arrived
  UPDATE public.job_assignments
  SET status = 'arrived',
      arrived_at = v_now,
      employer_scan_location = v_loc,
      updated_at = v_now
  WHERE id = p_assignment_id;

  -- Log assignment event
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta, created_at)
  VALUES (
    p_assignment_id,
    'arrived',
    v_caller,
    jsonb_build_object(
      'from_status', v_assignment.status::TEXT,
      'to_status', 'arrived',
      'scan_type', 'qr_ticket',
      'token_id', p_token_id,
      'location', jsonb_build_object('lat', p_lat, 'lng', p_lng)
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
    jsonb_build_object('assignment_id', p_assignment_id, 'job_title', v_job.title),
    v_now
  );

  SELECT * INTO v_worker FROM public.profiles WHERE id = v_assignment.worker_id;
  SELECT * INTO v_worker_profile FROM public.worker_profiles WHERE user_id = v_assignment.worker_id;

  RETURN jsonb_build_object(
    'valid', true,
    'assignment_id', p_assignment_id,
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

GRANT EXECUTE ON FUNCTION public.record_ticket_attendance(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, UUID) TO authenticated;
