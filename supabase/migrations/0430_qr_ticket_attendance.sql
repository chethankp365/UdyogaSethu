-- Migration: 0430_qr_ticket_attendance.sql
-- Description: Enhancements for P4.8 QR job ticket issuance, replay protection and attendance scan

-- 1. Add used tracking and assignment_id to qr_tokens if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'qr_tokens' AND column_name = 'used'
  ) THEN
    ALTER TABLE public.qr_tokens ADD COLUMN used BOOLEAN NOT NULL DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'qr_tokens' AND column_name = 'used_at'
  ) THEN
    ALTER TABLE public.qr_tokens ADD COLUMN used_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'qr_tokens' AND column_name = 'assignment_id'
  ) THEN
    ALTER TABLE public.qr_tokens ADD COLUMN assignment_id UUID REFERENCES public.job_assignments(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_qr_tokens_assignment ON public.qr_tokens(assignment_id);
CREATE INDEX IF NOT EXISTS idx_qr_tokens_used ON public.qr_tokens(used);

-- 2. Add index on attendance_logs(token_id) for instant replay checking
CREATE INDEX IF NOT EXISTS idx_attendance_logs_token_id ON public.attendance_logs(token_id);

-- 3. Seed ticket expiry setting in admin_settings (default 120 seconds / 2 minutes)
INSERT INTO public.admin_settings (key, value)
VALUES ('qr_ticket_expiry_seconds', '120'::jsonb)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value, updated_at = NOW();

-- 4. RPC: get_job_ticket_details(p_assignment_id)
-- Returns all metadata needed to render the BookMyShow-style ticket for the assigned worker
CREATE OR REPLACE FUNCTION public.get_job_ticket_details(p_assignment_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_worker public.profiles%ROWTYPE;
  v_worker_profile public.worker_profiles%ROWTYPE;
  v_provider public.profiles%ROWTYPE;
  v_category_name TEXT := 'General Labour';
  v_category_icon TEXT := 'work';
  v_caller UUID;
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
    RAISE EXCEPTION 'Unauthorized to view ticket for this assignment.';
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

  -- If status is accepted, auto-advance to ticket_issued when worker views the ticket
  IF v_assignment.status = 'accepted' AND v_assignment.worker_id = v_caller THEN
    UPDATE public.job_assignments
    SET status = 'ticket_issued', updated_at = NOW()
    WHERE id = p_assignment_id;
    v_assignment.status := 'ticket_issued';
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

GRANT EXECUTE ON FUNCTION public.get_job_ticket_details(UUID) TO authenticated;

-- 5. RPC: record_ticket_attendance(p_assignment_id, p_token_id, p_lat, p_lng)
-- Security definer handler called during attendance scan
CREATE OR REPLACE FUNCTION public.record_ticket_attendance(
  p_assignment_id UUID,
  p_token_id TEXT,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION
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
  v_caller := auth.uid();
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

GRANT EXECUTE ON FUNCTION public.record_ticket_attendance(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
