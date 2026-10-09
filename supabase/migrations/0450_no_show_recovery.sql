-- Migration: 0450_no_show_recovery.sql
-- Description: Smart No-Show Recovery Engine: grace extensions, worker running late reporting,
--              automated cron/edge job detection, smart replacement ranking, replacement booking,
--              and fraud flags for 3 no-shows in 30 days.

-- 1. Extend job_assignments table with grace & late tracking columns
ALTER TABLE public.job_assignments
  ADD COLUMN IF NOT EXISTS extended_grace_minutes INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS late_notified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS running_late_eta_minutes INT,
  ADD COLUMN IF NOT EXISTS running_late_reported_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS no_show_timer_paused BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Check and notify late assignments (Idempotent cron / scheduled engine)
CREATE OR REPLACE FUNCTION public.check_no_show_assignments()
RETURNS INT AS $$
DECLARE
  v_default_grace INT := 15;
  v_setting_grace INT;
  v_count INT := 0;
  r RECORD;
  v_now TIMESTAMPTZ := NOW();
  v_deadline TIMESTAMPTZ;
  v_mins_late INT;
BEGIN
  -- Read admin setting if present
  SELECT CASE WHEN jsonb_typeof(value) = 'number' THEN (value::text)::INT ELSE 15 END
  INTO v_setting_grace
  FROM public.admin_settings
  WHERE key = 'no_show_grace_minutes';

  IF v_setting_grace IS NOT NULL THEN
    v_default_grace := v_setting_grace;
  END IF;

  FOR r IN
    SELECT ja.id AS assignment_id,
           ja.job_id,
           ja.worker_id,
           ja.booking_code,
           ja.extended_grace_minutes,
           ja.running_late_eta_minutes,
           ja.late_notified_at,
           j.provider_id,
           j.title AS job_title,
           j.start_at,
           wp.full_name AS worker_name,
           pp.full_name AS provider_name
    FROM public.job_assignments ja
    JOIN public.jobs j ON ja.job_id = j.id
    LEFT JOIN public.profiles wp ON ja.worker_id = wp.id
    LEFT JOIN public.profiles pp ON j.provider_id = pp.id
    WHERE ja.status = 'ticket_issued'
      AND ja.arrived_at IS NULL
  LOOP
    -- Calculate deadline: start_at + default_grace + extended_grace + running_late_eta
    v_deadline := r.start_at + ((v_default_grace + COALESCE(r.extended_grace_minutes, 0) + COALESCE(r.running_late_eta_minutes, 0)) * INTERVAL '1 minute');

    IF v_now >= v_deadline THEN
      -- Only notify once (idempotent): check late_notified_at IS NULL
      IF r.late_notified_at IS NULL THEN
        v_mins_late := GREATEST(1, EXTRACT(EPOCH FROM (v_now - r.start_at))::INT / 60);

        -- Update assignment timestamp
        UPDATE public.job_assignments
        SET late_notified_at = v_now,
            updated_at = v_now
        WHERE id = r.assignment_id;

        -- Record event in assignment_events
        INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta, created_at)
        VALUES (
          r.assignment_id,
          'late_arrival_warning',
          NULL,
          jsonb_build_object(
            'minutes_late', v_mins_late,
            'default_grace', v_default_grace,
            'extended_grace', r.extended_grace_minutes,
            'running_late_eta', r.running_late_eta_minutes,
            'notified_at', v_now
          ),
          v_now
        );

        -- Notify Provider
        IF r.provider_id IS NOT NULL THEN
          INSERT INTO public.notifications (user_id, type, title_key, body_key, params, created_at)
          VALUES (
            r.provider_id,
            'worker_late_arrival',
            'notif_worker_late_title',
            'notif_worker_late_body',
            jsonb_build_object(
              'assignment_id', r.assignment_id,
              'worker_name', COALESCE(r.worker_name, 'Worker'),
              'job_title', r.job_title,
              'minutes_late', v_mins_late
            ),
            v_now
          );
        END IF;

        -- Notify Worker
        IF r.worker_id IS NOT NULL THEN
          INSERT INTO public.notifications (user_id, type, title_key, body_key, params, created_at)
          VALUES (
            r.worker_id,
            'worker_arrival_grace_expired',
            'notif_arrival_grace_expired_title',
            'notif_arrival_grace_expired_body',
            jsonb_build_object(
              'assignment_id', r.assignment_id,
              'job_title', r.job_title,
              'minutes_late', v_mins_late
            ),
            v_now
          );
        END IF;

        v_count := v_count + 1;
      END IF;
    END IF;
  END LOOP;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Extend wait (Provider adds grace period)
CREATE OR REPLACE FUNCTION public.extend_wait(
  p_assignment_id UUID,
  p_minutes INT DEFAULT 10
)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_now TIMESTAMPTZ := NOW();
  v_new_grace INT;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_assignment FROM public.job_assignments WHERE id = p_assignment_id FOR UPDATE;
  IF v_assignment.id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;

  IF v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the job provider may extend the wait grace period.';
  END IF;

  v_new_grace := COALESCE(v_assignment.extended_grace_minutes, 0) + GREATEST(1, p_minutes);

  -- Update assignment: add grace and reset late_notified_at to allow warning if they miss the new extension
  UPDATE public.job_assignments
  SET extended_grace_minutes = v_new_grace,
      late_notified_at = NULL,
      updated_at = v_now
  WHERE id = p_assignment_id;

  -- Event
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta, created_at)
  VALUES (
    p_assignment_id,
    'grace_extended',
    v_caller,
    jsonb_build_object(
      'added_minutes', p_minutes,
      'total_extended_grace', v_new_grace
    ),
    v_now
  );

  -- Notify Worker that provider is waiting
  IF v_assignment.worker_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, type, title_key, body_key, params, created_at)
    VALUES (
      v_assignment.worker_id,
      'wait_extended',
      'notif_wait_extended_title',
      'notif_wait_extended_body',
      jsonb_build_object(
        'assignment_id', p_assignment_id,
        'added_minutes', p_minutes,
        'job_title', v_job.title
      ),
      v_now
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'assignment_id', p_assignment_id,
    'extended_grace_minutes', v_new_grace
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Worker reports running late with ETA (pauses no-show timer once)
CREATE OR REPLACE FUNCTION public.report_running_late(
  p_assignment_id UUID,
  p_eta_minutes INT
)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_assignment public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_now TIMESTAMPTZ := NOW();
  v_worker_name TEXT;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_assignment FROM public.job_assignments WHERE id = p_assignment_id FOR UPDATE;
  IF v_assignment.id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  IF v_assignment.worker_id != v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the assigned worker may report running late.';
  END IF;

  -- Pauses the no-show timer once as per spec
  IF v_assignment.running_late_reported_at IS NOT NULL THEN
    RAISE EXCEPTION 'Running late has already been reported for this assignment.';
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = v_assignment.job_id;
  SELECT full_name INTO v_worker_name FROM public.profiles WHERE id = v_assignment.worker_id;

  UPDATE public.job_assignments
  SET running_late_eta_minutes = GREATEST(5, p_eta_minutes),
      running_late_reported_at = v_now,
      no_show_timer_paused = TRUE,
      late_notified_at = NULL,
      updated_at = v_now
  WHERE id = p_assignment_id;

  -- Insert event
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta, created_at)
  VALUES (
    p_assignment_id,
    'running_late_reported',
    v_caller,
    jsonb_build_object('eta_minutes', p_eta_minutes),
    v_now
  );

  -- Notify Provider
  IF v_job.provider_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, type, title_key, body_key, params, created_at)
    VALUES (
      v_job.provider_id,
      'worker_running_late',
      'notif_worker_running_late_title',
      'notif_worker_running_late_body',
      jsonb_build_object(
        'assignment_id', p_assignment_id,
        'worker_name', COALESCE(v_worker_name, 'Worker'),
        'eta_minutes', p_eta_minutes,
        'job_title', v_job.title
      ),
      v_now
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'assignment_id', p_assignment_id,
    'eta_minutes', p_eta_minutes
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Find smart replacement worker candidates
CREATE OR REPLACE FUNCTION public.find_replacement(p_assignment_id UUID)
RETURNS TABLE (
  worker_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  rating NUMERIC,
  distance_meters DOUBLE PRECISION,
  jobs_completed INT,
  is_verified BOOLEAN,
  skills TEXT[]
) AS $$
DECLARE
  v_job public.jobs%ROWTYPE;
  v_late_worker_id UUID;
  v_job_location extensions.geography;
  v_category_id UUID;
BEGIN
  SELECT j.*, ja.worker_id
  INTO v_job.id, v_job.provider_id, v_job.category_id, v_job.title, v_job.description,
       v_job.wage_type, v_job.wage_paise, v_job.est_duration_minutes, v_job.start_at,
       v_job.slots_total, v_job.slots_filled, v_job.materials_provided, v_job.payment_mode,
       v_job.requirements, v_job.location, v_job.address_text, v_job.geofence_radius_m,
       v_job.source, v_job.status, v_job.created_at, v_job.updated_at,
       v_late_worker_id
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_assignment_id;

  IF v_late_worker_id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  v_job_location := v_job.location;
  v_category_id := v_job.category_id;

  RETURN QUERY
  WITH candidates AS (
    SELECT
      p.id AS c_worker_id,
      p.full_name AS c_full_name,
      p.avatar_url AS c_avatar_url,
      COALESCE(p.rating_avg, 4.8)::NUMERIC AS c_rating,
      CASE
        WHEN v_job_location IS NOT NULL AND p.last_location IS NOT NULL
          THEN extensions.ST_Distance(v_job_location, p.last_location)
        ELSE 1200.0::DOUBLE PRECISION
      END AS c_dist,
      COALESCE(p.jobs_completed_count, 12)::INT AS c_completed,
      COALESCE(p.is_verified_badge, false) AS c_verified,
      EXISTS (
        SELECT 1 FROM public.worker_skills ws
        JOIN public.skills s ON ws.skill_id = s.id
        WHERE ws.worker_id = p.id AND (v_category_id IS NULL OR s.category_id = v_category_id)
      ) AS c_skill_match,
      ARRAY(
        SELECT COALESCE(s.name->>'en', s.name->>'kn', 'General')
        FROM public.worker_skills ws
        JOIN public.skills s ON ws.skill_id = s.id
        WHERE ws.worker_id = p.id
        LIMIT 4
      ) AS c_skills
    FROM public.profiles p
    LEFT JOIN public.worker_profiles wp ON p.id = wp.user_id
    WHERE p.id != v_late_worker_id
      AND ('seeker' = ANY(p.roles) OR 'worker' = ANY(p.roles) OR wp.user_id IS NOT NULL)
      AND COALESCE(wp.is_available, true) = true
      AND p.is_suspended = false
  )
  SELECT
    c.c_worker_id,
    c.c_full_name,
    c.c_avatar_url,
    ROUND(c.c_rating, 1),
    ROUND(c.c_dist),
    c.c_completed,
    c.c_verified,
    c.c_skills
  FROM candidates c
  ORDER BY
    c.c_skill_match DESC,
    c.c_verified DESC,
    c.c_rating DESC,
    c.c_dist ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Alias for find_replacement_candidates
CREATE OR REPLACE FUNCTION public.find_replacement_candidates(p_assignment_id UUID)
RETURNS TABLE (
  worker_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  rating NUMERIC,
  distance_meters DOUBLE PRECISION,
  jobs_completed INT,
  is_verified BOOLEAN,
  skills TEXT[]
) AS $$
BEGIN
  RETURN QUERY SELECT * FROM public.find_replacement(p_assignment_id);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 6. Confirm replacement worker, mark original no_show, trigger refund path, and check fraud flags
CREATE OR REPLACE FUNCTION public.confirm_replacement(
  p_assignment_id UUID,
  p_replacement_worker_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_original public.job_assignments%ROWTYPE;
  v_job public.jobs%ROWTYPE;
  v_now TIMESTAMPTZ := NOW();
  v_new_assignment_id UUID;
  v_new_booking_code TEXT;
  v_no_show_count INT;
  v_payment_id UUID;
  v_payment_amount BIGINT;
  v_payment_status public.payment_status;
  v_replacement_name TEXT;
  v_rule_key TEXT := 'excessive_no_shows';
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_original FROM public.job_assignments WHERE id = p_assignment_id FOR UPDATE;
  IF v_original.id IS NULL THEN
    RAISE EXCEPTION 'Original assignment % not found.', p_assignment_id;
  END IF;

  SELECT * INTO v_job FROM public.jobs WHERE id = v_original.job_id;

  IF v_job.provider_id != v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the job provider may confirm a replacement.';
  END IF;

  IF v_original.worker_id = p_replacement_worker_id THEN
    RAISE EXCEPTION 'Replacement worker cannot be the late worker.';
  END IF;

  -- 1. Mark original assignment as no_show
  UPDATE public.job_assignments
  SET status = 'no_show',
      updated_at = v_now
  WHERE id = p_assignment_id;

  -- Log no_show event
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta, created_at)
  VALUES (
    p_assignment_id,
    'no_show',
    v_caller,
    jsonb_build_object(
      'reason', 'late_arrival_no_show',
      'replacement_worker_id', p_replacement_worker_id,
      'original_worker_id', v_original.worker_id
    ),
    v_now
  );

  -- 2. Trigger escrow refund path if payment exists (P5.3 integration)
  SELECT id, amount_paise, status INTO v_payment_id, v_payment_amount, v_payment_status
  FROM public.payments
  WHERE ref_type = 'job_assignment' AND ref_id = p_assignment_id
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_payment_id IS NOT NULL AND v_payment_status = 'held' THEN
    -- Call refund_escrow to credit back to provider's available balance
    PERFORM public.refund_escrow(v_payment_id, v_payment_amount);

    INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta, created_at)
    VALUES (
      p_assignment_id,
      'escrow_refund_triggered',
      v_caller,
      jsonb_build_object('payment_id', v_payment_id, 'amount_paise', v_payment_amount),
      v_now
    );
  END IF;

  -- 3. Create replacement assignment
  v_new_booking_code := 'REP-' || UPPER(SUBSTR(extensions.gen_random_uuid()::TEXT, 1, 8));
  v_new_assignment_id := extensions.gen_random_uuid();

  INSERT INTO public.job_assignments (
    id,
    job_id,
    worker_id,
    booking_code,
    status,
    agreed_wage_paise,
    protection_selected,
    created_at,
    updated_at
  ) VALUES (
    v_new_assignment_id,
    v_original.job_id,
    p_replacement_worker_id,
    v_new_booking_code,
    'accepted',
    v_original.agreed_wage_paise,
    v_original.protection_selected,
    v_now,
    v_now
  );

  -- Link original assignment to replacement
  UPDATE public.job_assignments
  SET replaced_by = v_new_assignment_id,
      updated_at = v_now
  WHERE id = p_assignment_id;

  -- Log replacement creation event
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta, created_at)
  VALUES (
    v_new_assignment_id,
    'replacement_created',
    v_caller,
    jsonb_build_object(
      'original_assignment_id', p_assignment_id,
      'booking_code', v_new_booking_code
    ),
    v_now
  );

  -- 4. Three no-shows in 30 days creates a fraud_flags row for review
  SELECT COUNT(*) INTO v_no_show_count
  FROM public.job_assignments
  WHERE worker_id = v_original.worker_id
    AND status = 'no_show'
    AND updated_at >= (v_now - INTERVAL '30 days');

  IF v_no_show_count >= 3 THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.fraud_flags
      WHERE user_id = v_original.worker_id
        AND rule_key = v_rule_key
        AND status = 'open'
    ) THEN
      INSERT INTO public.fraud_flags (
        user_id,
        rule_key,
        severity,
        ref_type,
        ref_id,
        evidence,
        status,
        created_at
      ) VALUES (
        v_original.worker_id,
        v_rule_key,
        'high',
        'job_assignment',
        p_assignment_id,
        jsonb_build_object(
          'no_show_count_30d', v_no_show_count,
          'assignment_id', p_assignment_id,
          'flagged_at', v_now
        ),
        'open',
        v_now
      );
    END IF;
  END IF;

  -- 5. Notifications
  SELECT full_name INTO v_replacement_name FROM public.profiles WHERE id = p_replacement_worker_id;

  -- Notify replacement worker
  INSERT INTO public.notifications (user_id, type, title_key, body_key, params, created_at)
  VALUES (
    p_replacement_worker_id,
    'urgent_replacement_booking',
    'notif_replacement_booking_title',
    'notif_replacement_booking_body',
    jsonb_build_object(
      'assignment_id', v_new_assignment_id,
      'job_title', v_job.title,
      'wage_paise', v_original.agreed_wage_paise
    ),
    v_now
  );

  -- Notify late worker of cancellation / no-show
  INSERT INTO public.notifications (user_id, type, title_key, body_key, params, created_at)
  VALUES (
    v_original.worker_id,
    'marked_no_show',
    'notif_marked_no_show_title',
    'notif_marked_no_show_body',
    jsonb_build_object(
      'assignment_id', p_assignment_id,
      'job_title', v_job.title
    ),
    v_now
  );

  RETURN jsonb_build_object(
    'success', true,
    'original_assignment_id', p_assignment_id,
    'new_assignment_id', v_new_assignment_id,
    'new_booking_code', v_new_booking_code,
    'no_show_count_30d', v_no_show_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7. Update get_active_job_details to expose grace and late recovery metadata
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

-- 8. Permissions
GRANT EXECUTE ON FUNCTION public.check_no_show_assignments() TO authenticated, anon;

GRANT EXECUTE ON FUNCTION public.extend_wait(UUID, INT) TO authenticated;

GRANT EXECUTE ON FUNCTION public.report_running_late(UUID, INT) TO authenticated;

GRANT EXECUTE ON FUNCTION public.find_replacement(UUID) TO authenticated;

GRANT EXECUTE ON FUNCTION public.find_replacement_candidates(UUID) TO authenticated;

GRANT EXECUTE ON FUNCTION public.confirm_replacement(UUID, UUID) TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_active_job_details(UUID) TO authenticated;

-- 9. Schedule with pg_cron if available
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule('check-no-show-every-minute');
    PERFORM cron.schedule('check-no-show-every-minute', '* * * * *', 'SELECT public.check_no_show_assignments();');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END $$;
