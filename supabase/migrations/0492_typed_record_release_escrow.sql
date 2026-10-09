-- Migration: 0492_typed_record_release_escrow.sql
-- Description: Use strongly typed row types in release_escrow to prevent unassigned record tuple errors.

CREATE OR REPLACE FUNCTION public.release_escrow(p_payment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_payment public.payments%ROWTYPE;
  v_assignment public.job_assignments%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_bps BIGINT := 500;
  v_fee BIGINT;
  v_net BIGINT;
  v_key_debit TEXT;
  v_key_credit TEXT;
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
