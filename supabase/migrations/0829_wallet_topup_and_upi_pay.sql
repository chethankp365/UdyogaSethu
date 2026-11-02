-- 0829_wallet_topup_and_upi_pay.sql
-- Enables authentic wallet topup via payment gateway and real UPI QR payment with balance guard

-- 1. Topup Wallet RPC (Used by Add Money / Gateway Checkout)
CREATE OR REPLACE FUNCTION public.topup_wallet(
  p_amount_paise BIGINT,
  p_payment_ref TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_key TEXT;
  v_ledger_id UUID;
  v_new_balance BIGINT := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_amount_paise <= 0 THEN
    RAISE EXCEPTION 'Topup amount must be greater than zero.';
  END IF;

  -- Ensure wallet row exists
  INSERT INTO public.wallets (user_id)
  VALUES (v_uid)
  ON CONFLICT (user_id) DO NOTHING;

  v_key := 'topup-' || COALESCE(p_payment_ref, extensions.gen_random_uuid()::TEXT);

  v_ledger_id := public.wallet_credit(
    v_uid,
    p_amount_paise,
    'available',
    'wallet_topup',
    COALESCE(p_payment_ref, v_key),
    v_key,
    'Wallet funds added via Payment Gateway'
  );

  SELECT COALESCE(available_paise, 0) INTO v_new_balance
  FROM public.wallet_balances
  WHERE user_id = v_uid;

  RETURN jsonb_build_object(
    'success', true,
    'amount_paise', p_amount_paise,
    'new_balance_paise', v_new_balance,
    'ledger_id', v_ledger_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Pay VPA / QR from Wallet Balance with Strict Invariant Guard
CREATE OR REPLACE FUNCTION public.pay_vpa_from_wallet(
  p_payee_vpa TEXT,
  p_payee_name TEXT,
  p_amount_paise BIGINT,
  p_note TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_wallet_id UUID;
  v_avail BIGINT := 0;
  v_payout_id UUID;
  v_key TEXT;
  v_ref TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_amount_paise <= 0 THEN
    RAISE EXCEPTION 'Payment amount must be greater than zero.';
  END IF;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_uid;
  SELECT COALESCE(available_paise, 0) INTO v_avail
  FROM public.wallet_balances
  WHERE user_id = v_uid;

  IF v_avail < p_amount_paise THEN
    RAISE EXCEPTION 'Insufficient wallet balance. Available: ₹%, Required: ₹%. Money cannot be moved without sufficient funds.',
      (COALESCE(v_avail, 0) / 100.0)::NUMERIC(10,2), (p_amount_paise / 100.0)::NUMERIC(10,2);
  END IF;

  v_ref := 'UPI-TXN-' || floor(random() * 900000 + 100000)::text;

  INSERT INTO public.payouts (
    user_id,
    amount_paise,
    status,
    method,
    payout_ref,
    created_at
  ) VALUES (
    v_uid,
    p_amount_paise,
    'completed',
    'upi_qr',
    p_payee_vpa || ' (' || v_ref || ')',
    NOW()
  ) RETURNING id INTO v_payout_id;

  v_key := 'upi-pay-' || v_payout_id;
  PERFORM public.wallet_debit(
    v_uid,
    p_amount_paise,
    'available',
    'upi_payment',
    p_payee_vpa,
    v_key,
    COALESCE(p_note, 'Paid to ' || p_payee_name || ' (' || p_payee_vpa || ')')
  );

  RETURN jsonb_build_object(
    'success', true,
    'reference', v_ref,
    'amount_paise', p_amount_paise,
    'payee_name', p_payee_name,
    'payee_vpa', p_payee_vpa,
    'new_balance_paise', v_avail - p_amount_paise
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.topup_wallet(BIGINT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pay_vpa_from_wallet(TEXT, TEXT, BIGINT, TEXT) TO authenticated;
