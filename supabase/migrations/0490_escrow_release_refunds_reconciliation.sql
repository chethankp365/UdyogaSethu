-- Migration: 0490_escrow_release_refunds_reconciliation.sql
-- Description: Connect verified completion to escrow release, refunds (full/partial),
--              dispute freeze invariants, auto-release scheduler, and Phase 6 order compatibility.

-- 1. Ensure Commission and Auto-Release Settings in admin_settings
INSERT INTO public.admin_settings (key, value)
VALUES
  ('commission_bps', '500'::jsonb),         -- 5% platform fee (500 basis points)
  ('auto_release_hours', '24'::jsonb)       -- 24 hours auto-release window after completion
ON CONFLICT (key) DO NOTHING;

-- 2. Enhanced release_escrow: Handles fee deduction in paise, dispute freeze, double-entry ledger,
--    assignment state sync, timeline logging, and worker notification.
CREATE OR REPLACE FUNCTION public.release_escrow(p_payment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_payment RECORD;
  v_assignment RECORD;
  v_order RECORD;
  v_bps BIGINT := 500;
  v_fee BIGINT;
  v_net BIGINT;
  v_key_debit TEXT;
  v_key_credit TEXT;
  v_key_fee TEXT;
  v_dispute_count INT := 0;
  v_bps_setting JSONB;
BEGIN
  -- 1. Fetch payment with exclusive lock
  SELECT * INTO v_payment
  FROM public.payments
  WHERE id = p_payment_id
  FOR UPDATE;

  IF v_payment.id IS NULL THEN
    RAISE EXCEPTION 'Payment % not found.', p_payment_id;
  END IF;

  -- 2. Idempotent exit if already released
  IF v_payment.status = 'released' THEN
    RETURN true;
  END IF;

  -- 3. Payment must be in 'held' or 'captured' status to be released
  IF v_payment.status NOT IN ('held', 'captured') THEN
    RAISE EXCEPTION 'Cannot release payment %: current status is % (expected held).',
      p_payment_id, v_payment.status;
  END IF;

  -- 4. Check for active disputes freezing release
  IF v_payment.ref_type = 'assignment' THEN
    SELECT * INTO v_assignment
    FROM public.job_assignments
    WHERE id = v_payment.ref_id;

    IF v_assignment.status = 'disputed' THEN
      RAISE EXCEPTION 'Cannot release escrow: assignment % is disputed.', v_assignment.id;
    END IF;

    SELECT COUNT(*) INTO v_dispute_count
    FROM public.disputes
    WHERE ref_type = 'job_assignment'
      AND ref_id = v_payment.ref_id
      AND status IN ('open', 'in_review');

    IF v_dispute_count > 0 THEN
      RAISE EXCEPTION 'Cannot release escrow: active dispute exists for assignment %.', v_payment.ref_id;
    END IF;

  ELSIF v_payment.ref_type = 'order' THEN
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = v_payment.ref_id;

    IF v_order.status = 'disputed' THEN
      RAISE EXCEPTION 'Cannot release escrow: order % is disputed.', v_order.id;
    END IF;

    SELECT COUNT(*) INTO v_dispute_count
    FROM public.disputes
    WHERE ref_type = 'order'
      AND ref_id = v_payment.ref_id
      AND status IN ('open', 'in_review');

    IF v_dispute_count > 0 THEN
      RAISE EXCEPTION 'Cannot release escrow: active dispute exists for order %.', v_payment.ref_id;
    END IF;
  END IF;

  -- 5. Calculate platform commission with exact paise rounding
  SELECT value INTO v_bps_setting
  FROM public.admin_settings
  WHERE key = 'commission_bps';

  IF v_bps_setting IS NOT NULL THEN
    v_bps := (v_bps_setting::TEXT)::BIGINT;
  END IF;

  -- If payment already has platform_fee_paise set (e.g. at checkout), use it or compute bps
  IF v_payment.platform_fee_paise IS NOT NULL AND v_payment.platform_fee_paise > 0 THEN
    v_fee := v_payment.platform_fee_paise;
  ELSE
    v_fee := ROUND((v_payment.amount_paise * v_bps)::NUMERIC / 10000.0)::BIGINT;
  END IF;

  -- Guarantee net is never negative
  IF v_fee > v_payment.amount_paise THEN
    v_fee := 0;
  END IF;
  v_net := v_payment.amount_paise - v_fee;

  -- 6. Double-entry ledger postings
  v_key_debit := 'release-debit-escrow-' || p_payment_id;
  v_key_credit := 'release-credit-available-' || p_payment_id;
  v_key_fee := 'release-platform-fee-' || p_payment_id;

  -- Debit payer escrow bucket
  PERFORM public.wallet_debit(
    v_payment.payer_id,
    v_payment.amount_paise,
    'escrow',
    'payment',
    p_payment_id,
    v_key_debit,
    'Escrow released for verified service'
  );

  -- Credit payee available bucket with net earnings
  PERFORM public.wallet_credit(
    v_payment.payee_id,
    v_net,
    'available',
    'payment',
    p_payment_id,
    v_key_credit,
    'Service earnings credited (net of platform fee)'
  );

  -- 7. Update payment record
  UPDATE public.payments
  SET status = 'released',
      platform_fee_paise = v_fee,
      updated_at = NOW()
  WHERE id = p_payment_id;

  -- 8. Synchronize underlying reference (Assignment or Order)
  IF v_payment.ref_type = 'assignment' AND v_assignment.id IS NOT NULL THEN
    -- Set assignment to payment_released
    UPDATE public.job_assignments
    SET status = 'payment_released',
        updated_at = NOW()
    WHERE id = v_assignment.id;

    -- Write event to assignment_events
    INSERT INTO public.assignment_events (
      assignment_id,
      event_type,
      actor_id,
      meta,
      created_at
    )
    VALUES (
      v_assignment.id,
      'payment_released',
      COALESCE(auth.uid(), v_payment.payer_id),
      jsonb_build_object(
        'payment_id', p_payment_id,
        'total_amount_paise', v_payment.amount_paise,
        'net_earned_paise', v_net,
        'platform_fee_paise', v_fee,
        'released_at', NOW()
      ),
      NOW()
    );

    -- Notify worker of earnings credit
    INSERT INTO public.notifications (
      user_id,
      type,
      title_key,
      body_key,
      params,
      created_at
    )
    VALUES (
      v_payment.payee_id,
      'payment_released',
      'notif_payment_released_title',
      'notif_payment_released_body',
      jsonb_build_object(
        'assignment_id', v_assignment.id,
        'net_rupees', (v_net / 100)::INT,
        'total_rupees', (v_payment.amount_paise / 100)::INT
      ),
      NOW()
    );

  ELSIF v_payment.ref_type = 'order' AND v_order.id IS NOT NULL THEN
    -- Set order to delivered if not already
    UPDATE public.orders
    SET status = 'delivered',
        updated_at = NOW()
    WHERE id = v_order.id;

    -- Write event to order_events
    INSERT INTO public.order_events (
      order_id,
      status,
      note,
      created_at
    )
    VALUES (
      v_order.id,
      'delivered',
      'Escrow released to farmer wallet upon delivery confirmation',
      NOW()
    );

    -- Notify farmer
    INSERT INTO public.notifications (
      user_id,
      type,
      title_key,
      body_key,
      params,
      created_at
    )
    VALUES (
      v_payment.payee_id,
      'payment_released',
      'notif_order_paid_title',
      'notif_order_paid_body',
      jsonb_build_object(
        'order_id', v_order.id,
        'net_rupees', (v_net / 100)::INT
      ),
      NOW()
    );
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 3. Release by Assignment ID Helper
CREATE OR REPLACE FUNCTION public.release_assignment_escrow(p_assignment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_payment_id UUID;
BEGIN
  -- Find held or captured payment for this assignment
  SELECT id INTO v_payment_id
  FROM public.payments
  WHERE ref_type = 'assignment'
    AND ref_id = p_assignment_id
    AND status IN ('held', 'captured')
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_payment_id IS NULL THEN
    -- Check if already released
    SELECT id INTO v_payment_id
    FROM public.payments
    WHERE ref_type = 'assignment'
      AND ref_id = p_assignment_id
      AND status = 'released'
    LIMIT 1;

    IF v_payment_id IS NOT NULL THEN
      RETURN true;
    END IF;

    RAISE EXCEPTION 'No held payment found for assignment %.', p_assignment_id;
  END IF;

  RETURN public.release_escrow(v_payment_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 4. Confirm Job Completion and Release (Called by Provider in App)
CREATE OR REPLACE FUNCTION public.confirm_job_completion_and_release(p_assignment_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_assignment RECORD;
  v_job RECORD;
  v_success BOOLEAN;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT ja.*, j.provider_id
  INTO v_assignment
  FROM public.job_assignments ja
  JOIN public.jobs j ON j.id = ja.job_id
  WHERE ja.id = p_assignment_id;

  IF v_assignment.id IS NULL THEN
    RAISE EXCEPTION 'Assignment % not found.', p_assignment_id;
  END IF;

  -- Caller must be provider or admin
  IF v_assignment.provider_id != v_caller AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the job provider can confirm completion and release payment.';
  END IF;

  -- Assignment must be completed or in_progress_verified
  IF v_assignment.status = 'payment_released' THEN
    RETURN jsonb_build_object(
      'success', true,
      'status', 'payment_released',
      'message', 'Payment already released.'
    );
  END IF;

  IF v_assignment.status NOT IN ('completed', 'in_progress_verified') THEN
    RAISE EXCEPTION 'Cannot release payment: job is currently % (expected completed).', v_assignment.status;
  END IF;

  -- If still in_progress_verified, mark completed first
  IF v_assignment.status = 'in_progress_verified' THEN
    UPDATE public.job_assignments
    SET status = 'completed',
        ended_at = NOW(),
        payment_eligible = true,
        updated_at = NOW()
    WHERE id = p_assignment_id;
  END IF;

  -- Release escrow
  v_success := public.release_assignment_escrow(p_assignment_id);

  RETURN jsonb_build_object(
    'success', v_success,
    'status', 'payment_released',
    'assignment_id', p_assignment_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 5. Refund Escrow (Full or Partial Refund to Payer)
CREATE OR REPLACE FUNCTION public.refund_escrow(
  p_payment_id UUID,
  p_refund_paise BIGINT DEFAULT NULL,
  p_reason TEXT DEFAULT 'Service cancelled or refunded'
)
RETURNS BOOLEAN AS $$
DECLARE
  v_payment RECORD;
  v_refund BIGINT;
  v_key_debit TEXT;
  v_key_credit TEXT;
BEGIN
  SELECT * INTO v_payment
  FROM public.payments
  WHERE id = p_payment_id
  FOR UPDATE;

  IF v_payment.id IS NULL THEN
    RAISE EXCEPTION 'Payment % not found.', p_payment_id;
  END IF;

  IF v_payment.status NOT IN ('held', 'captured') THEN
    RAISE EXCEPTION 'Cannot refund payment %: status is % (expected held).',
      p_payment_id, v_payment.status;
  END IF;

  -- Default to full refund if not specified
  IF p_refund_paise IS NULL OR p_refund_paise <= 0 THEN
    v_refund := v_payment.amount_paise;
  ELSE
    v_refund := p_refund_paise;
  END IF;

  IF v_refund > v_payment.amount_paise THEN
    RAISE EXCEPTION 'Refund amount (% paise) cannot exceed held amount (% paise).',
      v_refund, v_payment.amount_paise;
  END IF;

  v_key_debit := 'refund-debit-escrow-' || p_payment_id || '-' || v_refund;
  v_key_credit := 'refund-credit-available-' || p_payment_id || '-' || v_refund;

  -- Debit payer escrow bucket
  PERFORM public.wallet_debit(
    v_payment.payer_id,
    v_refund,
    'escrow',
    'payment',
    p_payment_id,
    v_key_debit,
    'Escrow refunded: ' || p_reason
  );

  -- Credit payer available bucket
  PERFORM public.wallet_credit(
    v_payment.payer_id,
    v_refund,
    'available',
    'payment',
    p_payment_id,
    v_key_credit,
    'Refund credited to available balance: ' || p_reason
  );

  -- Update payment status: full refund -> 'refunded'; partial -> remains 'held' with reduced balance
  IF v_refund = v_payment.amount_paise THEN
    UPDATE public.payments
    SET status = 'refunded',
        updated_at = NOW()
    WHERE id = p_payment_id;
  ELSE
    UPDATE public.payments
    SET amount_paise = amount_paise - v_refund,
        updated_at = NOW()
    WHERE id = p_payment_id;
  END IF;

  -- Notify payer
  INSERT INTO public.notifications (
    user_id,
    type,
    title_key,
    body_key,
    params,
    created_at
  )
  VALUES (
    v_payment.payer_id,
    'payment_refunded',
    'notif_refund_processed_title',
    'notif_refund_processed_body',
    jsonb_build_object(
      'refund_rupees', (v_refund / 100)::INT,
      'reason', p_reason
    ),
    NOW()
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 6. Refund by Assignment ID Helper
CREATE OR REPLACE FUNCTION public.refund_assignment_escrow(
  p_assignment_id UUID,
  p_refund_paise BIGINT DEFAULT NULL,
  p_reason TEXT DEFAULT 'Assignment cancelled/no-show'
)
RETURNS BOOLEAN AS $$
DECLARE
  v_payment_id UUID;
BEGIN
  SELECT id INTO v_payment_id
  FROM public.payments
  WHERE ref_type = 'assignment'
    AND ref_id = p_assignment_id
    AND status IN ('held', 'captured')
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_payment_id IS NULL THEN
    RETURN false; -- No held payment to refund
  END IF;

  RETURN public.refund_escrow(v_payment_id, p_refund_paise, p_reason);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 7. Automated Auto-Release Scheduler Procedure
CREATE OR REPLACE FUNCTION public.auto_release_escrow()
RETURNS JSONB AS $$
DECLARE
  v_hours_setting JSONB;
  v_auto_hours INT := 24;
  v_record RECORD;
  v_processed_count INT := 0;
  v_released_count INT := 0;
BEGIN
  -- Read hours threshold from admin_settings
  SELECT value INTO v_hours_setting
  FROM public.admin_settings
  WHERE key = 'auto_release_hours';

  IF v_hours_setting IS NOT NULL THEN
    v_auto_hours := (v_hours_setting::TEXT)::INT;
  END IF;

  -- Scan completed assignments with all verifications passed, no active dispute,
  -- and completed_at older than the auto_release_hours threshold
  FOR v_record IN
    SELECT ja.id AS assignment_id, p.id AS payment_id
    FROM public.job_assignments ja
    JOIN public.payments p ON p.ref_type = 'assignment' AND p.ref_id = ja.id
    WHERE ja.status = 'completed'
      AND ja.payment_eligible = true
      AND ja.ended_at <= NOW() - (v_auto_hours || ' hours')::INTERVAL
      AND p.status IN ('held', 'captured')
      AND NOT EXISTS (
        SELECT 1 FROM public.disputes d
        WHERE d.ref_type = 'job_assignment'
          AND d.ref_id = ja.id
          AND d.status IN ('open', 'in_review')
      )
  LOOP
    v_processed_count := v_processed_count + 1;
    BEGIN
      PERFORM public.release_escrow(v_record.payment_id);
      v_released_count := v_released_count + 1;
    EXCEPTION WHEN OTHERS THEN
      -- Log or ignore individually so batch continues
      NULL;
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'processed', v_processed_count,
    'released', v_released_count,
    'threshold_hours', v_auto_hours,
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 8. Release for Orders (Phase 6 Produce Commerce)
CREATE OR REPLACE FUNCTION public.release_order_escrow(p_order_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_payment_id UUID;
BEGIN
  SELECT id INTO v_payment_id
  FROM public.payments
  WHERE ref_type = 'order'
    AND ref_id = p_order_id
    AND status IN ('held', 'captured')
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_payment_id IS NULL THEN
    -- Check if already released
    SELECT id INTO v_payment_id
    FROM public.payments
    WHERE ref_type = 'order'
      AND ref_id = p_order_id
      AND status = 'released'
    LIMIT 1;

    IF v_payment_id IS NOT NULL THEN
      RETURN true;
    END IF;

    RAISE EXCEPTION 'No held payment found for order %.', p_order_id;
  END IF;

  RETURN public.release_escrow(v_payment_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 9. Wire Assignment Stage Transition on Payment Released
CREATE OR REPLACE FUNCTION public.advance_assignment_stage(
  p_assignment_id UUID,
  p_next_status TEXT,
  p_meta JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_assignment public.job_assignments;
  v_job public.jobs;
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

  -- If advancing to payment_released, trigger the actual escrow release
  IF v_status_enum = 'payment_released' THEN
    PERFORM public.confirm_job_completion_and_release(p_assignment_id);

    RETURN jsonb_build_object(
      'assignment_id', p_assignment_id,
      'status', 'payment_released',
      'updated_at', v_now
    );
  END IF;

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


-- 10. Grant Execute Permissions
GRANT EXECUTE ON FUNCTION public.release_escrow(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.release_assignment_escrow(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.confirm_job_completion_and_release(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.refund_escrow(UUID, BIGINT, TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.refund_assignment_escrow(UUID, BIGINT, TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.auto_release_escrow() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.release_order_escrow(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.advance_assignment_stage(UUID, TEXT, JSONB) TO authenticated, service_role;
