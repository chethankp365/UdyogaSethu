-- Migration: 0400_guided_booking_and_protection.sql
-- Description: P4.6 Guided direct booking with double-booking prevention, protection cover, saved addresses, and recurring schedules

-- 1. Helper function to check worker booked slots in a date range
CREATE OR REPLACE FUNCTION public.get_worker_booked_slots(
  p_worker_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  assignment_id UUID,
  job_id UUID,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ,
  status public.assignment_status
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ja.id AS assignment_id,
    j.id AS job_id,
    j.start_at,
    (j.start_at + (COALESCE(j.est_duration_minutes, 480) || ' minutes')::interval) AS end_at,
    ja.status
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.worker_id = p_worker_id
    AND ja.status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified')
    AND j.start_at >= p_start_date::timestamptz
    AND j.start_at < (p_end_date + INTERVAL '1 day')::timestamptz
  ORDER BY j.start_at ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 2. Enhanced request_worker with double-booking prevention, address, protection, and recurring support
CREATE OR REPLACE FUNCTION public.request_worker(
  p_worker_id UUID,
  p_category_id UUID,
  p_title TEXT,
  p_start_at TIMESTAMPTZ,
  p_agreed_wage_paise BIGINT,
  p_est_duration_minutes INT DEFAULT 480,
  p_address_text TEXT DEFAULT NULL,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_payment_mode public.payment_mode DEFAULT 'escrow',
  p_protection_selected BOOLEAN DEFAULT false,
  p_recurring_rule TEXT DEFAULT NULL,
  p_preferred_time TIME DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_provider_id UUID;
  v_job_id UUID;
  v_assignment_id UUID;
  v_recurring_id UUID;
  v_code TEXT;
  v_worker_name TEXT;
  v_provider_name TEXT;
  v_conflict_count INT;
  v_end_at TIMESTAMPTZ;
  v_geom extensions.geography;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  v_end_at := p_start_at + (COALESCE(p_est_duration_minutes, 480) || ' minutes')::interval;

  -- DOUBLE-BOOKING CHECK
  SELECT COUNT(*) INTO v_conflict_count
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.worker_id = p_worker_id
    AND ja.status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified')
    AND tstzrange(j.start_at, j.start_at + (COALESCE(j.est_duration_minutes, 480) || ' minutes')::interval) && tstzrange(p_start_at, v_end_at);

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'Worker is already booked for this time window. Please choose another slot.'
      USING ERRCODE = 'P4001';
  END IF;

  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_geom := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  END IF;

  -- Create direct booking job
  INSERT INTO public.jobs (
    provider_id, category_id, title, wage_type, wage_paise,
    est_duration_minutes, start_at, slots_total, slots_filled,
    payment_mode, address_text, location,
    source, status
  ) VALUES (
    v_provider_id, p_category_id, p_title, 'fixed', p_agreed_wage_paise,
    p_est_duration_minutes, p_start_at, 1, 1,
    p_payment_mode, p_address_text, v_geom,
    'direct_booking', 'filled'
  ) RETURNING id INTO v_job_id;

  v_code := 'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6));

  -- Insert assignment with protection_selected
  INSERT INTO public.job_assignments (
    job_id, worker_id, booking_code, agreed_wage_paise,
    protection_selected, status
  ) VALUES (
    v_job_id, p_worker_id, v_code, p_agreed_wage_paise,
    p_protection_selected, 'requested'
  ) RETURNING id INTO v_assignment_id;

  -- Log assignment event
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
  VALUES (
    v_assignment_id,
    'requested',
    v_provider_id,
    jsonb_build_object(
      'direct_booking', true,
      'protection_selected', p_protection_selected,
      'payment_mode', p_payment_mode::text,
      'recurring_rule', p_recurring_rule
    )
  );

  -- Handle recurring booking record if requested
  IF p_recurring_rule IS NOT NULL AND TRIM(p_recurring_rule) <> '' THEN
    INSERT INTO public.recurring_bookings (
      provider_id, worker_id, category_id,
      schedule_rule, preferred_time, status
    ) VALUES (
      v_provider_id, p_worker_id, p_category_id,
      p_recurring_rule, COALESCE(p_preferred_time, p_start_at::time), 'active'
    ) RETURNING id INTO v_recurring_id;
  END IF;

  -- Notify the worker
  SELECT full_name INTO v_provider_name FROM public.profiles WHERE id = v_provider_id;
  INSERT INTO public.notifications (
    user_id, title, body, type, data
  ) VALUES (
    p_worker_id,
    'Direct Booking Request',
    'You received a direct booking request for ' || p_title || COALESCE(' from ' || v_provider_name, ''),
    'job_request',
    jsonb_build_object(
      'assignment_id', v_assignment_id,
      'job_id', v_job_id,
      'booking_code', v_code,
      'start_at', p_start_at,
      'wage_paise', p_agreed_wage_paise,
      'protection_selected', p_protection_selected
    )
  );

  RETURN jsonb_build_object(
    'assignment_id', v_assignment_id,
    'job_id', v_job_id,
    'booking_code', v_code,
    'status', 'requested',
    'protection_selected', p_protection_selected,
    'start_at', p_start_at,
    'recurring_id', v_recurring_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Saved Addresses RPCs
CREATE OR REPLACE FUNCTION public.get_user_addresses(
  p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  label TEXT,
  line1 TEXT,
  landmark TEXT,
  city TEXT,
  pincode TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  is_default BOOLEAN,
  created_at TIMESTAMPTZ
) AS $$
DECLARE
  v_uid UUID;
BEGIN
  v_uid := COALESCE(p_user_id, auth.uid());
  RETURN QUERY
  SELECT
    a.id,
    a.user_id,
    a.label,
    a.line1,
    a.landmark,
    a.city,
    a.pincode,
    extensions.ST_Y(a.location::extensions.geometry) AS lat,
    extensions.ST_X(a.location::extensions.geometry) AS lng,
    a.is_default,
    a.created_at
  FROM public.addresses a
  WHERE a.user_id = v_uid
  ORDER BY a.is_default DESC, a.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.save_user_address(
  p_label TEXT,
  p_line1 TEXT,
  p_landmark TEXT,
  p_city TEXT,
  p_pincode TEXT,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_is_default BOOLEAN DEFAULT false
)
RETURNS UUID AS $$
DECLARE
  v_uid UUID;
  v_addr_id UUID;
  v_geom extensions.geography;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_geom := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  END IF;

  IF p_is_default THEN
    UPDATE public.addresses SET is_default = false WHERE user_id = v_uid;
  END IF;

  INSERT INTO public.addresses (
    user_id, label, line1, landmark, city, pincode, location, is_default
  ) VALUES (
    v_uid, p_label, p_line1, p_landmark, p_city, p_pincode, v_geom, p_is_default
  ) RETURNING id INTO v_addr_id;

  RETURN v_addr_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Recurring Bookings Management RPCs
CREATE OR REPLACE FUNCTION public.get_provider_recurring_bookings(
  p_provider_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  worker_id UUID,
  worker_name TEXT,
  worker_avatar TEXT,
  category_id UUID,
  category_name TEXT,
  schedule_rule TEXT,
  preferred_time TIME,
  status public.subscription_status,
  skip_dates DATE[],
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
DECLARE
  v_uid UUID;
BEGIN
  v_uid := COALESCE(p_provider_id, auth.uid());
  RETURN QUERY
  SELECT
    rb.id,
    rb.provider_id,
    rb.worker_id,
    COALESCE(p.full_name, 'Worker') AS worker_name,
    p.avatar_url AS worker_avatar,
    rb.category_id,
    COALESCE(sc.name, 'Service') AS category_name,
    rb.schedule_rule,
    rb.preferred_time,
    rb.status,
    rb.skip_dates,
    rb.created_at,
    rb.updated_at
  FROM public.recurring_bookings rb
  LEFT JOIN public.profiles p ON rb.worker_id = p.id
  LEFT JOIN public.service_categories sc ON rb.category_id = sc.id
  WHERE rb.provider_id = v_uid
  ORDER BY rb.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_recurring_booking(
  p_recurring_id UUID,
  p_status public.subscription_status DEFAULT NULL,
  p_schedule_rule TEXT DEFAULT NULL,
  p_preferred_time TIME DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_uid UUID;
BEGIN
  v_uid := auth.uid();
  UPDATE public.recurring_bookings
  SET
    status = COALESCE(p_status, status),
    schedule_rule = COALESCE(p_schedule_rule, schedule_rule),
    preferred_time = COALESCE(p_preferred_time, preferred_time),
    updated_at = NOW()
  WHERE id = p_recurring_id
    AND (v_uid IS NULL OR provider_id = v_uid);

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.skip_recurring_booking_date(
  p_recurring_id UUID,
  p_skip_date DATE
)
RETURNS BOOLEAN AS $$
DECLARE
  v_uid UUID;
BEGIN
  v_uid := auth.uid();
  UPDATE public.recurring_bookings
  SET
    skip_dates = array_append(COALESCE(skip_dates, '{}'), p_skip_date),
    updated_at = NOW()
  WHERE id = p_recurring_id
    AND (v_uid IS NULL OR provider_id = v_uid);

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
