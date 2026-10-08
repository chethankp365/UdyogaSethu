-- Migration 0420: Job Execution, Assignment Timeline, Realtime Triggers & Worker Schedule
-- Step P4.7 of UdyogaSethu

-- 1. Add 'verification_completed' enum value to assignment_status if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'public.assignment_status'::regtype
      AND enumlabel = 'verification_completed'
  ) THEN
    ALTER TYPE public.assignment_status ADD VALUE 'verification_completed' BEFORE 'in_progress_verified';
  END IF;
END $$;

-- 2. Realtime Replica Identity & Publication
ALTER TABLE public.assignment_events REPLICA IDENTITY FULL;
ALTER TABLE public.job_assignments REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'assignment_events'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.assignment_events;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'job_assignments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.job_assignments;
  END IF;
END $$;

-- 3. Automatic Assignment Event Logger on Status Change
-- Ensures that ANY direct SQL UPDATE on job_assignments.status or function call
-- automatically records a matching assignment_events row for Realtime streams.
CREATE OR REPLACE FUNCTION public.trg_job_assignment_status_event()
RETURNS TRIGGER AS $$
DECLARE
  v_actor UUID;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    -- Check if an event for this status was already inserted in this exact transaction
    IF NOT EXISTS (
      SELECT 1 FROM public.assignment_events
      WHERE assignment_id = NEW.id
        AND event_type = NEW.status::TEXT
        AND created_at >= NOW() - INTERVAL '2 seconds'
    ) THEN
      v_actor := auth.uid();
      IF v_actor IS NULL THEN
        -- Fallback to worker or provider
        SELECT worker_id INTO v_actor FROM public.job_assignments WHERE id = NEW.id;
      END IF;

      INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta, created_at)
      VALUES (
        NEW.id,
        NEW.status::TEXT,
        v_actor,
        jsonb_build_object(
          'from_status', OLD.status::TEXT,
          'to_status', NEW.status::TEXT,
          'auto_logged', true
        ),
        NOW()
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_job_assignment_status_event ON public.job_assignments;
CREATE TRIGGER trg_job_assignment_status_event
AFTER UPDATE OF status ON public.job_assignments
FOR EACH ROW
EXECUTE FUNCTION public.trg_job_assignment_status_event();

-- 4. Advance Assignment Stage RPC
-- Allows authenticated parties (worker or provider) to progress the assignment lifecycle
CREATE OR REPLACE FUNCTION public.advance_assignment_stage(
  p_assignment_id UUID,
  p_next_status TEXT,
  p_meta JSONB DEFAULT '{}'::JSONB
)
RETURNS JSONB AS $$
DECLARE
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_caller UUID;
  v_status_enum public.assignment_status;
  v_now TIMESTAMPTZ := NOW();
  v_elapsed INT;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_assignment
  FROM public.job_assignments
  WHERE id = p_assignment_id
  FOR UPDATE;

  IF v_assignment.id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  SELECT * INTO v_job
  FROM public.jobs
  WHERE id = v_assignment.job_id;

  -- Verify caller is worker or provider
  IF v_assignment.worker_id != v_caller AND v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized to advance this assignment.';
  END IF;

  BEGIN
    v_status_enum := p_next_status::public.assignment_status;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Invalid assignment status: %', p_next_status;
  END;

  -- Timestamp adjustments based on lifecycle
  IF v_status_enum = 'arrived' AND v_assignment.arrived_at IS NULL THEN
    v_assignment.arrived_at := v_now;
  ELSIF v_status_enum IN ('verification_completed', 'in_progress_verified') AND v_assignment.started_at IS NULL THEN
    v_assignment.started_at := v_now;
  ELSIF v_status_enum = 'completed' AND v_assignment.ended_at IS NULL THEN
    v_assignment.ended_at := v_now;
    IF v_assignment.started_at IS NOT NULL THEN
      v_elapsed := EXTRACT(EPOCH FROM (v_now - v_assignment.started_at))::INT;
      v_assignment.elapsed_seconds := GREATEST(0, v_elapsed);
    END IF;
  END IF;

  -- Update job assignment
  UPDATE public.job_assignments
  SET status = v_status_enum,
      arrived_at = COALESCE(arrived_at, v_assignment.arrived_at),
      started_at = COALESCE(started_at, v_assignment.started_at),
      ended_at = COALESCE(ended_at, v_assignment.ended_at),
      elapsed_seconds = COALESCE(elapsed_seconds, v_assignment.elapsed_seconds),
      updated_at = v_now
  WHERE id = p_assignment_id;

  -- Insert event record
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta, created_at)
  VALUES (
    p_assignment_id,
    p_next_status,
    v_caller,
    COALESCE(p_meta, '{}'::JSONB) || jsonb_build_object(
      'from_status', v_assignment.status::TEXT,
      'to_status', p_next_status,
      'actor_role', CASE WHEN v_caller = v_assignment.worker_id THEN 'worker' ELSE 'provider' END
    ),
    v_now
  );

  RETURN jsonb_build_object(
    'assignment_id', p_assignment_id,
    'status', p_next_status,
    'updated_at', v_now
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.advance_assignment_stage(UUID, TEXT, JSONB) TO authenticated;

-- 5. Get Active Job Details RPC
CREATE OR REPLACE FUNCTION public.get_active_job_details(p_assignment_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_res JSONB;
BEGIN
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
    'elapsed_seconds', ja.elapsed_seconds,
    'job_title', j.title,
    'job_description', j.description,
    'start_at', j.start_at,
    'est_duration_minutes', COALESCE(j.est_duration_minutes, 480),
    'address_text', j.address_text,
    'job_lat', extensions.ST_Y(j.location::geometry),
    'job_lng', extensions.ST_X(j.location::geometry),
    'category_name', sc.name->>'en',
    'category_slug', sc.slug,
    'category_icon', sc.icon,
    'provider_id', pp.id,
    'provider_name', pp.full_name,
    'provider_phone', pp.phone,
    'provider_avatar', pp.avatar_url,
    'provider_verified', pp.is_verified_badge,
    'worker_id', wp.id,
    'worker_name', wp.full_name,
    'worker_phone', wp.phone,
    'worker_avatar', wp.avatar_url,
    'worker_verified', wp.is_verified_badge,
    'worker_lat', extensions.ST_Y(wp.last_location::geometry),
    'worker_lng', extensions.ST_X(wp.last_location::geometry)
  )
  INTO v_res
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  LEFT JOIN public.profiles pp ON j.provider_id = pp.id
  LEFT JOIN public.profiles wp ON ja.worker_id = wp.id
  WHERE ja.id = p_assignment_id;

  IF v_res IS NULL THEN
    RAISE EXCEPTION 'Active job assignment % not found.', p_assignment_id;
  END IF;

  RETURN v_res;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_active_job_details(UUID) TO authenticated;

-- 6. Get Worker Schedule with Overlaps and Gaps RPC
CREATE OR REPLACE FUNCTION public.get_worker_schedule(
  p_worker_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSONB AS $$
DECLARE
  v_res JSONB;
BEGIN
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
      extensions.ST_Y(j.location::geometry) AS job_lat,
      extensions.ST_X(j.location::geometry) AS job_lng,
      COALESCE(sc.slug, 'general') AS category_slug,
      COALESCE(sc.icon, 'handyman') AS category_icon,
      COALESCE(pp.full_name, 'Verified Employer') AS provider_name,
      LAG(j.start_at + (COALESCE(j.est_duration_minutes, 480) || ' minutes')::INTERVAL)
        OVER (ORDER BY j.start_at ASC) AS prev_job_end_at,
      LEAD(j.start_at)
        OVER (ORDER BY j.start_at ASC) AS next_job_start_at
    FROM public.job_assignments ja
    JOIN public.jobs j ON ja.job_id = j.id
    LEFT JOIN public.service_categories sc ON j.category_id = sc.id
    LEFT JOIN public.profiles pp ON j.provider_id = pp.id
    WHERE ja.worker_id = p_worker_id
      AND ja.status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'verification_completed', 'in_progress_verified', 'completed')
      AND j.start_at >= p_start_date
      AND j.start_at <= p_end_date
    ORDER BY j.start_at ASC
  )
  SELECT jsonb_agg(
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
  )
  INTO v_res
  FROM schedule_rows s;

  RETURN COALESCE(v_res, '[]'::JSONB);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_worker_schedule(UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
