-- Migration: 0480_payments_receipts_escrow.sql
-- Description: Receipt sequence and generator, webhook event deduplication, server-side bill computation,
--              enhanced gateway-aware hold_escrow, and idempotent payment success recording.

-- 1. Receipt Sequence & Number Generator
CREATE SEQUENCE IF NOT EXISTS public.receipt_no_seq START WITH 10001;

CREATE OR REPLACE FUNCTION public.generate_payment_receipt_no()
RETURNS TEXT AS $$
BEGIN
  RETURN 'RCP-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(NEXTVAL('public.receipt_no_seq')::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

ALTER TABLE public.payments ALTER COLUMN receipt_no SET DEFAULT public.generate_payment_receipt_no();

CREATE OR REPLACE FUNCTION public.trg_set_payment_receipt_no()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.receipt_no IS NULL OR NEW.receipt_no = '' THEN
    NEW.receipt_no := public.generate_payment_receipt_no();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_payment_receipt_no_trg ON public.payments;
CREATE TRIGGER set_payment_receipt_no_trg
  BEFORE INSERT ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.trg_set_payment_receipt_no();

-- 2. Webhook Event Deduplication Log
CREATE TABLE IF NOT EXISTS public.payment_webhook_events (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  event_id TEXT UNIQUE NOT NULL,
  event_type TEXT NOT NULL,
  razorpay_payment_id TEXT,
  payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL,
  payload JSONB,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.payment_webhook_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS payment_webhook_events_service ON public.payment_webhook_events;
CREATE POLICY payment_webhook_events_service ON public.payment_webhook_events
  FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS payment_webhook_events_select ON public.payment_webhook_events;
CREATE POLICY payment_webhook_events_select ON public.payment_webhook_events
  FOR SELECT TO authenticated USING (
    payment_id IN (
      SELECT p.id FROM public.payments p WHERE p.payer_id = auth.uid() OR p.payee_id = auth.uid()
    )
  );

-- 3. Seed Default Fee Settings in admin_settings
INSERT INTO public.admin_settings (key, value)
VALUES
  ('platform_fee_paise', '2000'::jsonb),
  ('protection_addon_paise', '1500'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- 4. Server-Side Bill Computation (Never Trust Client Amounts)
CREATE OR REPLACE FUNCTION public.compute_payment_bill(
  p_ref_type TEXT,
  p_ref_id UUID,
  p_protection_override BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
  base_amount_paise BIGINT,
  platform_fee_paise BIGINT,
  protection_fee_paise BIGINT,
  total_paise BIGINT,
  payer_id UUID,
  payee_id UUID,
  is_protected BOOLEAN,
  description TEXT
) AS $$
DECLARE
  v_base BIGINT := 0;
  v_plat_fee BIGINT := 2000; -- ₹20 default
  v_prot_fee BIGINT := 1500; -- ₹15 default
  v_total BIGINT := 0;
  v_payer UUID;
  v_payee UUID;
  v_prot BOOLEAN := false;
  v_desc TEXT := 'Payment';
  v_fee_setting JSONB;
BEGIN
  -- Read fee overrides from admin_settings
  SELECT value INTO v_fee_setting FROM public.admin_settings WHERE key = 'platform_fee_paise';
  IF v_fee_setting IS NOT NULL THEN
    v_plat_fee := (v_fee_setting::TEXT)::BIGINT;
  END IF;

  SELECT value INTO v_fee_setting FROM public.admin_settings WHERE key = 'protection_addon_paise';
  IF v_fee_setting IS NOT NULL THEN
    v_prot_fee := (v_fee_setting::TEXT)::BIGINT;
  END IF;

  IF p_ref_type = 'assignment' THEN
    SELECT
      ja.agreed_wage_paise,
      j.provider_id,
      ja.worker_id,
      ja.protection_selected,
      j.title
    INTO v_base, v_payer, v_payee, v_prot, v_desc
    FROM public.job_assignments ja
    JOIN public.jobs j ON j.id = ja.job_id
    WHERE ja.id = p_ref_id;

    IF v_payer IS NULL THEN
      RAISE EXCEPTION 'Job assignment % not found.', p_ref_id;
    END IF;

    v_desc := 'Daily Wage: ' || COALESCE(v_desc, 'Service');

  ELSIF p_ref_type = 'order' THEN
    SELECT
      o.total_paise,
      o.customer_id,
      o.farmer_id,
      o.protected,
      'Farm Produce Order #' || o.order_code
    INTO v_base, v_payer, v_payee, v_prot, v_desc
    FROM public.orders o
    WHERE o.id = p_ref_id;

    IF v_payer IS NULL THEN
      RAISE EXCEPTION 'Order % not found.', p_ref_id;
    END IF;

  ELSIF p_ref_type = 'group_order' THEN
    SELECT
      COALESCE(SUM(gom.contribution_paise), 50000),
      auth.uid(),
      go.farmer_id,
      true,
      'Group Order: ' || COALESCE(go.pool_code, 'Community Pool')
    INTO v_base, v_payer, v_payee, v_prot, v_desc
    FROM public.group_orders go
    LEFT JOIN public.group_order_members gom ON gom.group_order_id = go.id
    WHERE go.id = p_ref_id
    GROUP BY go.id, go.farmer_id, go.pool_code;

    IF v_payer IS NULL THEN
      v_payer := auth.uid();
    END IF;

  ELSIF p_ref_type = 'subscription' THEN
    v_base := 49900; -- ₹499
    v_plat_fee := 0;
    v_prot_fee := 0;
    v_payer := auth.uid();
    v_payee := NULL;
    v_prot := false;
    v_desc := 'UdyogaSethu Pro Membership';

  ELSE
    RAISE EXCEPTION 'Unsupported ref_type %', p_ref_type;
  END IF;

  -- Allow explicit protection override if provided
  IF p_protection_override IS NOT NULL THEN
    v_prot := p_protection_override;
  END IF;

  IF NOT v_prot THEN
    v_prot_fee := 0;
  END IF;

  v_total := v_base + v_plat_fee + v_prot_fee;

  RETURN QUERY SELECT
    v_base AS base_amount_paise,
    v_plat_fee AS platform_fee_paise,
    v_prot_fee AS protection_fee_paise,
    v_total AS total_paise,
    v_payer AS payer_id,
    v_payee AS payee_id,
    v_prot AS is_protected,
    v_desc AS description;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 5. Enhanced hold_escrow (handles both wallet and external gateway payments)
CREATE OR REPLACE FUNCTION public.hold_escrow(p_payment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_payer_id UUID;
  v_amount BIGINT;
  v_status public.payment_status;
  v_method public.payment_method;
  v_avail BIGINT;
  v_wallet_id UUID;
  v_key_deposit TEXT;
  v_key_debit TEXT;
  v_key_credit TEXT;
BEGIN
  SELECT payer_id, amount_paise, status, method
  INTO v_payer_id, v_amount, v_status, v_method
  FROM public.payments WHERE id = p_payment_id;

  IF v_payer_id IS NULL THEN
    RAISE EXCEPTION 'Payment % not found.', p_payment_id;
  END IF;

  -- Idempotent exit if already held, released, or refunded
  IF v_status IN ('held', 'released', 'refunded') THEN
    RETURN true;
  END IF;

  -- Ensure payer has a wallet row
  INSERT INTO public.wallets (user_id)
  VALUES (v_payer_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_payer_id;

  -- Check available balance in wallet_balances
  SELECT COALESCE(available_paise, 0) INTO v_avail
  FROM public.wallet_balances
  WHERE wallet_id = v_wallet_id;

  -- For gateway payments (UPI/Card), deposit into available bucket first if not sufficient
  IF v_method IN ('upi', 'card') AND COALESCE(v_avail, 0) < v_amount THEN
    v_key_deposit := 'gw-deposit-' || p_payment_id;
    PERFORM public.wallet_credit(
      v_payer_id,
      v_amount,
      'available',
      'payment',
      p_payment_id,
      v_key_deposit,
      'Gateway payment received (' || v_method::TEXT || ')'
    );
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

-- 6. RPC: Record Payment Success (Called by Webhook / Checkout)
CREATE OR REPLACE FUNCTION public.record_payment_success(
  p_payment_id UUID,
  p_razorpay_payment_id TEXT,
  p_signature_verified BOOLEAN DEFAULT true
)
RETURNS public.payments AS $$
DECLARE
  v_payment public.payments;
  v_job_id UUID;
BEGIN
  SELECT * INTO v_payment FROM public.payments WHERE id = p_payment_id;

  IF v_payment.id IS NULL THEN
    RAISE EXCEPTION 'Payment % not found.', p_payment_id;
  END IF;

  -- If already held or released, return existing record idempotently
  IF v_payment.status IN ('held', 'released') THEN
    RETURN v_payment;
  END IF;

  -- Update payment status and gateway details
  UPDATE public.payments
  SET
    status = 'captured',
    razorpay_payment_id = COALESCE(p_razorpay_payment_id, razorpay_payment_id),
    signature_verified = COALESCE(p_signature_verified, signature_verified)
  WHERE id = p_payment_id
  RETURNING * INTO v_payment;

  -- If protected (Escrow), hold funds in escrow bucket
  IF v_payment.protected THEN
    PERFORM public.hold_escrow(p_payment_id);
    SELECT * INTO v_payment FROM public.payments WHERE id = p_payment_id;
  END IF;

  -- Lifecycle updates for assignments or orders
  IF v_payment.ref_type = 'assignment' THEN
    -- Advance assignment status to accepted if requested
    UPDATE public.job_assignments
    SET status = 'accepted'
    WHERE id = v_payment.ref_id AND status = 'requested';

    -- Log payment event to assignment_events
    INSERT INTO public.assignment_events (assignment_id, event_type, actor_id, meta)
    VALUES (
      v_payment.ref_id,
      CASE WHEN v_payment.protected THEN 'payment_held_escrow' ELSE 'payment_captured' END,
      v_payment.payer_id,
      jsonb_build_object(
        'payment_id', v_payment.id,
        'amount_paise', v_payment.amount_paise,
        'method', v_payment.method::TEXT,
        'receipt_no', v_payment.receipt_no
      )
    );

  ELSIF v_payment.ref_type = 'order' THEN
    UPDATE public.orders
    SET status = 'confirmed'
    WHERE id = v_payment.ref_id AND status = 'pending';
  END IF;

  RETURN v_payment;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7. Grant access to authenticated and service_role
DROP POLICY IF EXISTS payments_service ON public.payments;
CREATE POLICY payments_service ON public.payments
  FOR ALL TO service_role USING (true) WITH CHECK (true);

GRANT ALL ON public.payments TO service_role;
GRANT SELECT ON public.payment_webhook_events TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.compute_payment_bill TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.hold_escrow TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.record_payment_success TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_payment_receipt_no TO authenticated, service_role;
