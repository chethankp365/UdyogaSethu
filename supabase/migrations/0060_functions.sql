-- Migration: 0060_functions.sql
-- Description: Geo search functions, job state machine RPCs, double-booking prevention,
--              service-role verification handlers, idempotent wallet/escrow functions,
--              rating aggregate triggers, and badge recomputation helpers.

-- ============================================================================
-- 1. GEO SEARCH FUNCTIONS (ST_DWithin & GIST Indexes)
-- ============================================================================

-- NEARBY JOBS
CREATE OR REPLACE FUNCTION public.nearby_jobs(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 10000,
  p_category_id UUID DEFAULT NULL,
  p_min_wage_paise BIGINT DEFAULT NULL,
  p_max_wage_paise BIGINT DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  category_id UUID,
  title TEXT,
  description TEXT,
  wage_type public.wage_type,
  wage_paise BIGINT,
  start_at TIMESTAMPTZ,
  slots_total INT,
  slots_filled INT,
  address_text TEXT,
  distance_m DOUBLE PRECISION,
  location extensions.geography
) AS $$
DECLARE
  v_point extensions.geography;
BEGIN
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  RETURN QUERY
  SELECT
    j.id,
    j.provider_id,
    j.category_id,
    j.title,
    j.description,
    j.wage_type,
    j.wage_paise,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    j.address_text,
    extensions.ST_Distance(j.location, v_point) AS distance_m,
    j.location
  FROM public.jobs j
  WHERE j.status = 'open'
    AND j.location IS NOT NULL
    AND extensions.ST_DWithin(j.location, v_point, p_radius_m)
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    AND (p_min_wage_paise IS NULL OR j.wage_paise >= p_min_wage_paise)
    AND (p_max_wage_paise IS NULL OR j.wage_paise <= p_max_wage_paise)
    AND (p_search_query IS NULL OR (j.title ILIKE '%' || p_search_query || '%' OR j.description ILIKE '%' || p_search_query || '%'))
  ORDER BY distance_m ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- NEARBY WORKERS (Hides offline & suspended workers)
CREATE OR REPLACE FUNCTION public.nearby_workers(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 10000,
  p_seeker_type public.seeker_type DEFAULT NULL,
  p_min_rating NUMERIC DEFAULT NULL,
  p_verified_only BOOLEAN DEFAULT false,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  avatar_path TEXT,
  headline TEXT,
  seeker_type public.seeker_type,
  hourly_rate_paise BIGINT,
  daily_rate_paise BIGINT,
  rating_avg NUMERIC(3,2),
  rating_count INT,
  is_verified_badge BOOLEAN,
  distance_m DOUBLE PRECISION
) AS $$
DECLARE
  v_point extensions.geography;
BEGIN
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  RETURN QUERY
  SELECT
    wp.user_id,
    p.full_name,
    p.avatar_path,
    wp.headline,
    wp.seeker_type,
    wp.hourly_rate_paise,
    wp.daily_rate_paise,
    wp.rating_avg,
    wp.rating_count,
    wp.is_verified_badge,
    extensions.ST_Distance(p.home_location, v_point) AS distance_m
  FROM public.worker_profiles wp
  JOIN public.profiles p ON wp.user_id = p.id
  WHERE p.is_suspended = false
    AND wp.availability != 'offline'
    AND p.home_location IS NOT NULL
    AND extensions.ST_DWithin(p.home_location, v_point, p_radius_m)
    AND (p_seeker_type IS NULL OR wp.seeker_type = p_seeker_type)
    AND (p_min_rating IS NULL OR wp.rating_avg >= p_min_rating)
    AND (p_verified_only = false OR wp.is_verified_badge = true)
    AND (p_search_query IS NULL OR (p.full_name ILIKE '%' || p_search_query || '%' OR wp.headline ILIKE '%' || p_search_query || '%'))
  ORDER BY distance_m ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- NEARBY PRODUCE
CREATE OR REPLACE FUNCTION public.nearby_produce(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 20000,
  p_category public.produce_category DEFAULT NULL,
  p_min_price_paise BIGINT DEFAULT NULL,
  p_max_price_paise BIGINT DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  farmer_id UUID,
  name TEXT,
  category public.produce_category,
  price_paise BIGINT,
  unit TEXT,
  stock_qty NUMERIC(10,2),
  images TEXT[],
  distance_m DOUBLE PRECISION
) AS $$
DECLARE
  v_point extensions.geography;
BEGIN
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  RETURN QUERY
  SELECT
    pl.id,
    pl.farmer_id,
    pl.name,
    pl.category,
    pl.price_paise,
    pl.unit,
    pl.stock_qty,
    pl.images,
    extensions.ST_Distance(COALESCE(pl.location, p.home_location), v_point) AS distance_m
  FROM public.produce_listings pl
  JOIN public.profiles p ON pl.farmer_id = p.id
  WHERE pl.status = 'active'
    AND COALESCE(pl.location, p.home_location) IS NOT NULL
    AND extensions.ST_DWithin(COALESCE(pl.location, p.home_location), v_point, p_radius_m)
    AND (p_category IS NULL OR pl.category = p_category)
    AND (p_min_price_paise IS NULL OR pl.price_paise >= p_min_price_paise)
    AND (p_max_price_paise IS NULL OR pl.price_paise <= p_max_price_paise)
    AND (p_search_query IS NULL OR (pl.name ILIKE '%' || p_search_query || '%' OR pl.description ILIKE '%' || p_search_query || '%'))
  ORDER BY distance_m ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- NEARBY RESOURCES
CREATE OR REPLACE FUNCTION public.nearby_resources(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 25000,
  p_type public.resource_type DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  owner_id UUID,
  type public.resource_type,
  name TEXT,
  price_paise BIGINT,
  unit TEXT,
  images TEXT[],
  distance_m DOUBLE PRECISION
) AS $$
DECLARE
  v_point extensions.geography;
BEGIN
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  RETURN QUERY
  SELECT
    rl.id,
    rl.owner_id,
    rl.type,
    rl.name,
    rl.price_paise,
    rl.unit,
    rl.images,
    extensions.ST_Distance(COALESCE(rl.location, p.home_location), v_point) AS distance_m
  FROM public.resource_listings rl
  JOIN public.profiles p ON rl.owner_id = p.id
  WHERE rl.active = true
    AND COALESCE(rl.location, p.home_location) IS NOT NULL
    AND extensions.ST_DWithin(COALESCE(rl.location, p.home_location), v_point, p_radius_m)
    AND (p_type IS NULL OR rl.type = p_type)
    AND (p_search_query IS NULL OR (rl.name ILIKE '%' || p_search_query || '%' OR rl.description ILIKE '%' || p_search_query || '%'))
  ORDER BY distance_m ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 2. JOB STATE MACHINE & ASSIGNMENT TRANSITIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.assignment_transition(
  p_assignment_id UUID,
  p_to_status public.assignment_status,
  p_actor_id UUID,
  p_meta JSONB DEFAULT NULL
)
RETURNS public.assignment_status AS $$
DECLARE
  v_current_status public.assignment_status;
  v_allowed BOOLEAN := false;
BEGIN
  SELECT status INTO v_current_status
  FROM public.job_assignments
  WHERE id = p_assignment_id
  FOR UPDATE;

  IF v_current_status IS NULL THEN
    RAISE EXCEPTION 'Job assignment % not found.', p_assignment_id;
  END IF;

  -- Disputed status can be entered from any active live state
  IF p_to_status = 'disputed' AND v_current_status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified', 'completed') THEN
    v_allowed := true;
  -- State machine transition matrix
  ELSIF v_current_status = 'requested' AND p_to_status IN ('accepted', 'cancelled') THEN
    v_allowed := true;
  ELSIF v_current_status = 'accepted' AND p_to_status IN ('ticket_issued', 'cancelled') THEN
    v_allowed := true;
  ELSIF v_current_status = 'ticket_issued' AND p_to_status IN ('arrived', 'no_show', 'cancelled') THEN
    v_allowed := true;
  ELSIF v_current_status = 'arrived' AND p_to_status IN ('in_progress_verified', 'cancelled') THEN
    v_allowed := true;
  ELSIF v_current_status = 'in_progress_verified' AND p_to_status = 'completed' THEN
    v_allowed := true;
  ELSIF v_current_status = 'completed' AND p_to_status = 'payment_released' THEN
    v_allowed := true;
  END IF;

  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Illegal state transition from % to % for assignment %.', v_current_status, p_to_status, p_assignment_id;
  END IF;

  -- Update assignment status
  UPDATE public.job_assignments
  SET status = p_to_status,
      updated_at = NOW()
  WHERE id = p_assignment_id;

  -- Write assignment timeline event
  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
  VALUES (
    p_assignment_id,
    p_to_status::TEXT,
    p_actor_id,
    COALESCE(p_meta, jsonb_build_object('from_status', v_current_status, 'to_status', p_to_status))
  );

  RETURN p_to_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- PUBLIC RPCs

CREATE OR REPLACE FUNCTION public.apply_to_job(
  p_job_id UUID,
  p_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_worker_id UUID;
  v_app_id UUID;
BEGIN
  v_worker_id := auth.uid();
  IF v_worker_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to apply for jobs.';
  END IF;

  INSERT INTO public.job_applications (job_id, worker_id, message, status)
  VALUES (p_job_id, v_worker_id, p_message, 'applied')
  RETURNING id INTO v_app_id;

  RETURN v_app_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.respond_to_application(
  p_application_id UUID,
  p_status public.application_status
)
RETURNS UUID AS $$
DECLARE
  v_provider_id UUID;
  v_job_id UUID;
  v_worker_id UUID;
  v_wage_paise BIGINT;
  v_assignment_id UUID;
  v_code TEXT;
BEGIN
  v_provider_id := auth.uid();

  SELECT ja.job_id, ja.worker_id, j.wage_paise INTO v_job_id, v_worker_id, v_wage_paise
  FROM public.job_applications ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_application_id AND j.provider_id = v_provider_id;

  IF v_job_id IS NULL THEN
    RAISE EXCEPTION 'Application not found or unauthorized.';
  END IF;

  UPDATE public.job_applications SET status = p_status, updated_at = NOW() WHERE id = p_application_id;

  IF p_status = 'hired' THEN
    v_code := 'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6));

    INSERT INTO public.job_assignments (job_id, worker_id, booking_code, agreed_wage_paise, status)
    VALUES (v_job_id, v_worker_id, v_code, v_wage_paise, 'requested')
    RETURNING id INTO v_assignment_id;

    UPDATE public.jobs SET slots_filled = slots_filled + 1 WHERE id = v_job_id;
  END IF;

  RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.request_worker(
  p_worker_id UUID,
  p_category_id UUID,
  p_title TEXT,
  p_start_at TIMESTAMPTZ,
  p_agreed_wage_paise BIGINT,
  p_est_duration_minutes INT DEFAULT 480
)
RETURNS UUID AS $$
DECLARE
  v_provider_id UUID;
  v_job_id UUID;
  v_assignment_id UUID;
  v_code TEXT;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Create direct booking job
  INSERT INTO public.jobs (
    provider_id, category_id, title, wage_type, wage_paise,
    est_duration_minutes, start_at, slots_total, slots_filled,
    source, status
  ) VALUES (
    v_provider_id, p_category_id, p_title, 'fixed', p_agreed_wage_paise,
    p_est_duration_minutes, p_start_at, 1, 1,
    'direct_booking', 'filled'
  ) RETURNING id INTO v_job_id;

  v_code := 'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6));

  INSERT INTO public.job_assignments (
    job_id, worker_id, booking_code, agreed_wage_paise, status
  ) VALUES (
    v_job_id, p_worker_id, v_code, p_agreed_wage_paise, 'requested'
  ) RETURNING id INTO v_assignment_id;

  INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
  VALUES (v_assignment_id, 'requested', v_provider_id, jsonb_build_object('direct_booking', true));

  RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ACCEPT ASSIGNMENT WITH DOUBLE-BOOKING PREVENTION & TRAVEL WARNING
CREATE OR REPLACE FUNCTION public.accept_assignment(
  p_assignment_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_worker_id UUID;
  v_start_at TIMESTAMPTZ;
  v_duration INT;
  v_end_at TIMESTAMPTZ;
  v_overlap_count INT;
  v_prev_end TIMESTAMPTZ;
  v_gap_minutes NUMERIC;
  v_travel_warning BOOLEAN := false;
  v_meta JSONB;
BEGIN
  v_worker_id := auth.uid();

  SELECT ja.worker_id, j.start_at, COALESCE(j.est_duration_minutes, 480)
  INTO v_worker_id, v_start_at, v_duration
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_assignment_id;

  IF v_worker_id IS NULL OR v_worker_id != auth.uid() THEN
    RAISE EXCEPTION 'Assignment not found or unauthorized.';
  END IF;

  v_end_at := v_start_at + (v_duration || ' minutes')::INTERVAL;

  -- 1. Double-booking check: Overlapping active assignments
  SELECT COUNT(*) INTO v_overlap_count
  FROM public.job_assignments ja2
  JOIN public.jobs j2 ON ja2.job_id = j2.id
  WHERE ja2.worker_id = v_worker_id
    AND ja2.id != p_assignment_id
    AND ja2.status IN ('accepted', 'ticket_issued', 'arrived', 'in_progress_verified')
    AND j2.start_at < v_end_at
    AND (j2.start_at + (COALESCE(j2.est_duration_minutes, 480) || ' minutes')::INTERVAL) > v_start_at;

  IF v_overlap_count > 0 THEN
    RAISE EXCEPTION 'Worker has an overlapping job assignment at this time.';
  END IF;

  -- 2. Travel gap warning check (< 60 minutes gap from previous completed/accepted job)
  SELECT MAX(j2.start_at + (COALESCE(j2.est_duration_minutes, 480) || ' minutes')::INTERVAL)
  INTO v_prev_end
  FROM public.job_assignments ja2
  JOIN public.jobs j2 ON ja2.job_id = j2.id
  WHERE ja2.worker_id = v_worker_id
    AND ja2.id != p_assignment_id
    AND ja2.status IN ('accepted', 'ticket_issued', 'completed')
    AND (j2.start_at + (COALESCE(j2.est_duration_minutes, 480) || ' minutes')::INTERVAL) <= v_start_at;

  IF v_prev_end IS NOT NULL THEN
    v_gap_minutes := EXTRACT(EPOCH FROM (v_start_at - v_prev_end)) / 60.0;
    IF v_gap_minutes < 60 THEN
      v_travel_warning := true;
    END IF;
  END IF;

  v_meta := jsonb_build_object(
    'accepted_by', v_worker_id,
    'travel_warning', v_travel_warning,
    'gap_minutes', v_gap_minutes
  );

  -- Transition assignment to accepted
  PERFORM public.assignment_transition(p_assignment_id, 'accepted', v_worker_id, v_meta);

  RETURN jsonb_build_object(
    'status', 'accepted',
    'assignment_id', p_assignment_id,
    'travel_warning', v_travel_warning,
    'gap_minutes', v_gap_minutes
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.decline_assignment(p_assignment_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  PERFORM public.assignment_transition(p_assignment_id, 'cancelled', auth.uid(), jsonb_build_object('reason', 'declined_by_worker'));
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.cancel_assignment(p_assignment_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
  PERFORM public.assignment_transition(p_assignment_id, 'cancelled', auth.uid(), jsonb_build_object('reason', COALESCE(p_reason, 'user_cancelled')));
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.confirm_completion(p_assignment_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  PERFORM public.assignment_transition(p_assignment_id, 'completed', auth.uid(), jsonb_build_object('confirmed_by', auth.uid()));
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- SERVICE-ROLE ONLY VERIFICATION HANDLERS (REVOKED FROM AUTHENTICATED/ANON)

CREATE OR REPLACE FUNCTION public.record_arrival(
  p_assignment_id UUID,
  p_location extensions.geography
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.job_assignments
  SET arrived_at = NOW(),
      employer_scan_location = p_location
  WHERE id = p_assignment_id;

  PERFORM public.assignment_transition(p_assignment_id, 'arrived', NULL, jsonb_build_object('location', p_location));
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.record_verified_start(
  p_assignment_id UUID,
  p_selfie_path TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.job_assignments
  SET started_at = NOW(),
      start_selfie_path = p_selfie_path,
      start_geo_ok = true
  WHERE id = p_assignment_id;

  PERFORM public.assignment_transition(p_assignment_id, 'in_progress_verified', NULL, jsonb_build_object('selfie_path', p_selfie_path));
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.record_completion(
  p_assignment_id UUID,
  p_selfie_path TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_started_at TIMESTAMPTZ;
  v_elapsed INT;
BEGIN
  SELECT started_at INTO v_started_at FROM public.job_assignments WHERE id = p_assignment_id;
  IF v_started_at IS NOT NULL THEN
    v_elapsed := EXTRACT(EPOCH FROM (NOW() - v_started_at))::INT;
  END IF;

  UPDATE public.job_assignments
  SET ended_at = NOW(),
      elapsed_seconds = v_elapsed,
      completion_selfie_path = p_selfie_path
  WHERE id = p_assignment_id;

  PERFORM public.assignment_transition(p_assignment_id, 'completed', NULL, jsonb_build_object('selfie_path', p_selfie_path, 'elapsed_seconds', v_elapsed));
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.mark_no_show(p_assignment_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  PERFORM public.assignment_transition(p_assignment_id, 'no_show', NULL, jsonb_build_object('auto_flagged', true));
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Revoke service-role execution permissions from authenticated and anon
REVOKE EXECUTE ON FUNCTION public.record_arrival FROM authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.record_verified_start FROM authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.record_completion FROM authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.mark_no_show FROM authenticated, anon;

-- ============================================================================
-- 3. WALLET & ESCROW FUNCTIONS (IDEMPOTENT, APPEND-ONLY)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.wallet_credit(
  p_user_id UUID,
  p_amount_paise BIGINT,
  p_bucket public.ledger_bucket,
  p_ref_type TEXT,
  p_ref_id UUID,
  p_idempotency_key TEXT,
  p_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_wallet_id UUID;
  v_entry_id UUID;
BEGIN
  IF p_amount_paise <= 0 THEN
    RAISE EXCEPTION 'Credit amount must be greater than zero.';
  END IF;

  -- Idempotency check FIRST
  IF p_idempotency_key IS NOT NULL THEN
    SELECT id INTO v_entry_id
    FROM public.ledger_entries
    WHERE idempotency_key = p_idempotency_key;

    IF v_entry_id IS NOT NULL THEN
      RETURN v_entry_id;
    END IF;
  END IF;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = p_user_id;
  IF v_wallet_id IS NULL THEN
    INSERT INTO public.wallets (user_id) VALUES (p_user_id) RETURNING id INTO v_wallet_id;
  END IF;

  INSERT INTO public.ledger_entries (
    wallet_id, direction, amount_paise, bucket, ref_type, ref_id, idempotency_key, note
  ) VALUES (
    v_wallet_id, 'credit', p_amount_paise, p_bucket, p_ref_type, p_ref_id, p_idempotency_key, p_note
  )
  ON CONFLICT (idempotency_key) DO NOTHING
  RETURNING id INTO v_entry_id;

  RETURN v_entry_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.wallet_debit(
  p_user_id UUID,
  p_amount_paise BIGINT,
  p_bucket public.ledger_bucket,
  p_ref_type TEXT,
  p_ref_id UUID,
  p_idempotency_key TEXT,
  p_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_wallet_id UUID;
  v_balance BIGINT;
  v_entry_id UUID;
BEGIN
  IF p_amount_paise <= 0 THEN
    RAISE EXCEPTION 'Debit amount must be greater than zero.';
  END IF;

  -- Idempotency check FIRST
  IF p_idempotency_key IS NOT NULL THEN
    SELECT id INTO v_entry_id
    FROM public.ledger_entries
    WHERE idempotency_key = p_idempotency_key;

    IF v_entry_id IS NOT NULL THEN
      RETURN v_entry_id;
    END IF;
  END IF;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = p_user_id;
  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user %.', p_user_id;
  END IF;

  -- Balance check invariant
  SELECT
    CASE p_bucket::TEXT
      WHEN 'available' THEN available_paise
      WHEN 'pending' THEN pending_paise
      WHEN 'escrow' THEN escrow_paise
      WHEN 'reward' THEN reward_paise
      ELSE 0
    END INTO v_balance
  FROM public.wallet_balances
  WHERE wallet_id = v_wallet_id;

  IF COALESCE(v_balance, 0) < p_amount_paise THEN
    RAISE EXCEPTION 'Insufficient balance in % bucket. Required: %, Available: %', p_bucket, p_amount_paise, COALESCE(v_balance, 0);
  END IF;

  INSERT INTO public.ledger_entries (
    wallet_id, direction, amount_paise, bucket, ref_type, ref_id, idempotency_key, note
  ) VALUES (
    v_wallet_id, 'debit', p_amount_paise, p_bucket, p_ref_type, p_ref_id, p_idempotency_key, p_note
  )
  ON CONFLICT (idempotency_key) DO NOTHING
  RETURNING id INTO v_entry_id;

  RETURN v_entry_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- HOLD ESCROW
CREATE OR REPLACE FUNCTION public.hold_escrow(p_payment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_payer_id UUID;
  v_amount BIGINT;
  v_status public.payment_status;
  v_key_debit TEXT;
  v_key_credit TEXT;
BEGIN
  SELECT payer_id, amount_paise, status INTO v_payer_id, v_amount, v_status
  FROM public.payments WHERE id = p_payment_id;

  IF v_payer_id IS NULL THEN
    RAISE EXCEPTION 'Payment % not found.', p_payment_id;
  END IF;

  -- Idempotent exit if already held, released, or refunded
  IF v_status IN ('held', 'released', 'refunded') THEN
    RETURN true;
  END IF;

  v_key_debit := 'hold-debit-available-' || p_payment_id;
  v_key_credit := 'hold-credit-escrow-' || p_payment_id;

  -- Debit available bucket
  PERFORM public.wallet_debit(
    v_payer_id, v_amount, 'available', 'payment', p_payment_id, v_key_debit, 'Escrow held from available'
  );

  -- Credit escrow bucket
  PERFORM public.wallet_credit(
    v_payer_id, v_amount, 'escrow', 'payment', p_payment_id, v_key_credit, 'Escrow held for payment'
  );

  UPDATE public.payments SET status = 'held' WHERE id = p_payment_id;
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- RELEASE ESCROW
CREATE OR REPLACE FUNCTION public.release_escrow(p_payment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_payer_id UUID;
  v_payee_id UUID;
  v_amount BIGINT;
  v_status public.payment_status;
  v_bps BIGINT := 500;
  v_fee BIGINT;
  v_net BIGINT;
  v_key_debit TEXT;
  v_key_credit TEXT;
BEGIN
  SELECT payer_id, payee_id, amount_paise, status INTO v_payer_id, v_payee_id, v_amount, v_status
  FROM public.payments WHERE id = p_payment_id;

  IF v_payer_id IS NULL OR v_payee_id IS NULL THEN
    RAISE EXCEPTION 'Payment % not found or invalid payee.', p_payment_id;
  END IF;

  -- Idempotent exit if already released
  IF v_status = 'released' THEN
    RETURN true;
  END IF;

  -- Fetch commission_bps from admin_settings
  SELECT (value::TEXT)::BIGINT INTO v_bps
  FROM public.admin_settings WHERE key = 'commission_bps';
  IF v_bps IS NULL THEN v_bps := 500; END IF;

  v_fee := (v_amount * v_bps) / 10000;
  v_net := v_amount - v_fee;

  v_key_debit := 'release-debit-escrow-' || p_payment_id;
  v_key_credit := 'release-credit-available-' || p_payment_id;

  -- Debit payer escrow bucket
  PERFORM public.wallet_debit(
    v_payer_id, v_amount, 'escrow', 'payment', p_payment_id, v_key_debit, 'Escrow released'
  );

  -- Credit payee available bucket with net amount
  PERFORM public.wallet_credit(
    v_payee_id, v_net, 'available', 'payment', p_payment_id, v_key_credit, 'Earnings credited from escrow'
  );

  UPDATE public.payments
  SET status = 'released', platform_fee_paise = v_fee
  WHERE id = p_payment_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- REFUND ESCROW
CREATE OR REPLACE FUNCTION public.refund_escrow(p_payment_id UUID, p_refund_paise BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  v_payer_id UUID;
  v_status public.payment_status;
  v_key_debit TEXT;
  v_key_credit TEXT;
BEGIN
  SELECT payer_id, status INTO v_payer_id, v_status FROM public.payments WHERE id = p_payment_id;
  IF v_payer_id IS NULL THEN
    RAISE EXCEPTION 'Payment % not found.', p_payment_id;
  END IF;

  -- Idempotent exit if already refunded
  IF v_status = 'refunded' THEN
    RETURN true;
  END IF;

  v_key_debit := 'refund-debit-escrow-' || p_payment_id;
  v_key_credit := 'refund-credit-available-' || p_payment_id;

  PERFORM public.wallet_debit(
    v_payer_id, p_refund_paise, 'escrow', 'payment', p_payment_id, v_key_debit, 'Escrow refunded'
  );

  PERFORM public.wallet_credit(
    v_payer_id, p_refund_paise, 'available', 'payment', p_payment_id, v_key_credit, 'Refund credited to available'
  );

  UPDATE public.payments SET status = 'refunded' WHERE id = p_payment_id;
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 4. RATING AGGREGATION & VERIFICATION HELPERS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recompute_ratings_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_target_id UUID;
  v_avg NUMERIC(3,2);
  v_count INT;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    v_target_id := OLD.target_id;
  ELSE
    v_target_id := NEW.target_id;
  END IF;

  SELECT COALESCE(AVG(stars), 0.00)::NUMERIC(3,2), COUNT(*)::INT
  INTO v_avg, v_count
  FROM public.ratings_reviews
  WHERE target_id = v_target_id AND hidden = false;

  -- Update worker_profiles
  UPDATE public.worker_profiles
  SET rating_avg = v_avg, rating_count = v_count, updated_at = NOW()
  WHERE user_id = v_target_id;

  -- Update provider_profiles
  UPDATE public.provider_profiles
  SET rating_avg = v_avg, rating_count = v_count, updated_at = NOW()
  WHERE user_id = v_target_id;

  -- Update farmer_profiles
  UPDATE public.farmer_profiles
  SET rating_avg = v_avg, rating_count = v_count, updated_at = NOW()
  WHERE user_id = v_target_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_recompute_ratings ON public.ratings_reviews;
CREATE TRIGGER trg_recompute_ratings
  AFTER INSERT OR UPDATE OR DELETE ON public.ratings_reviews
  FOR EACH ROW EXECUTE FUNCTION public.recompute_ratings_trigger();

-- RECOMPUTE VERIFICATION BADGE
CREATE OR REPLACE FUNCTION public.recompute_verification_badge(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_kyc_ok BOOLEAN := false;
  v_face_ok BOOLEAN := false;
  v_badge BOOLEAN := false;
BEGIN
  SELECT (status = 'verified') INTO v_kyc_ok
  FROM public.kyc_records WHERE user_id = p_user_id LIMIT 1;

  SELECT (status = 'verified') INTO v_face_ok
  FROM public.face_profiles WHERE user_id = p_user_id LIMIT 1;

  v_badge := (COALESCE(v_kyc_ok, false) AND COALESCE(v_face_ok, false));

  UPDATE public.worker_profiles
  SET is_verified_badge = v_badge, updated_at = NOW()
  WHERE user_id = p_user_id;

  RETURN v_badge;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- GET PUBLIC VERIFICATION
CREATE OR REPLACE FUNCTION public.get_public_verification(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_name TEXT;
  v_initial TEXT;
  v_badge BOOLEAN;
  v_kyc_date TIMESTAMPTZ;
  v_face_date TIMESTAMPTZ;
BEGIN
  SELECT full_name INTO v_name FROM public.profiles WHERE id = p_user_id;
  IF v_name IS NOT NULL AND LENGTH(v_name) > 0 THEN
    v_initial := UPPER(SUBSTRING(v_name, 1, 1)) || '.';
  ELSE
    v_initial := 'U.';
  END IF;

  SELECT is_verified_badge INTO v_badge FROM public.worker_profiles WHERE user_id = p_user_id;
  SELECT verified_at INTO v_kyc_date FROM public.kyc_records WHERE user_id = p_user_id AND status = 'verified' LIMIT 1;
  SELECT liveness_passed_at INTO v_face_date FROM public.face_profiles WHERE user_id = p_user_id LIMIT 1;

  RETURN jsonb_build_object(
    'name_initial', v_initial,
    'is_verified_badge', COALESCE(v_badge, false),
    'kyc_verified_at', v_kyc_date,
    'face_verified_at', v_face_date
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- SUGGEST WAGE BAND
CREATE OR REPLACE FUNCTION public.suggest_wage_band(
  p_category_id UUID,
  p_area TEXT DEFAULT 'default'
)
RETURNS TABLE (
  min_paise BIGINT,
  max_paise BIGINT,
  unit TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT wb.min_paise, wb.max_paise, wb.unit
  FROM public.wage_benchmarks wb
  WHERE (wb.category_id = p_category_id OR wb.category_id IS NULL)
    AND (wb.area = p_area OR wb.area = 'default')
  ORDER BY wb.category_id IS NOT NULL DESC, wb.area = p_area DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;
