-- Migration: 0470_wallet_payouts_transactions.sql
-- Description: P5.1 Stored procedures and queries for Wallet Balances, Ledger Transactions, and Demo Payout Withdrawal.

-- 1. Ensure permissions on wallet_balances view
GRANT SELECT ON public.wallet_balances TO authenticated;

-- 2. GET WALLET SUMMARY (Live balances strictly from wallet_balances view + today's earnings)
CREATE OR REPLACE FUNCTION public.get_wallet_summary()
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_wallet_id UUID;
  v_available BIGINT := 0;
  v_pending BIGINT := 0;
  v_escrow BIGINT := 0;
  v_reward BIGINT := 0;
  v_total BIGINT := 0;
  v_today_credit BIGINT := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Ensure wallet exists for user
  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_uid;
  IF v_wallet_id IS NULL THEN
    INSERT INTO public.wallets (user_id)
    VALUES (v_uid)
    ON CONFLICT (user_id) DO NOTHING
    RETURNING id INTO v_wallet_id;

    IF v_wallet_id IS NULL THEN
      SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_uid;
    END IF;
  END IF;

  -- Read balances strictly from wallet_balances view (never client math)
  SELECT
    COALESCE(wb.available_paise, 0),
    COALESCE(wb.pending_paise, 0),
    COALESCE(wb.escrow_paise, 0),
    COALESCE(wb.reward_paise, 0),
    COALESCE(wb.total_balance_paise, 0)
  INTO
    v_available,
    v_pending,
    v_escrow,
    v_reward,
    v_total
  FROM public.wallet_balances wb
  WHERE wb.wallet_id = v_wallet_id;

  -- Calculate today's available earnings (credits into available bucket since start of local day)
  SELECT COALESCE(SUM(l.amount_paise), 0)
  INTO v_today_credit
  FROM public.ledger_entries l
  WHERE l.wallet_id = v_wallet_id
    AND l.direction = 'credit'
    AND l.bucket = 'available'
    AND l.created_at >= date_trunc('day', NOW());

  RETURN jsonb_build_object(
    'wallet_id', v_wallet_id,
    'available_paise', v_available,
    'pending_paise', v_pending,
    'escrow_paise', v_escrow,
    'reward_paise', v_reward,
    'total_balance_paise', v_total,
    'today_credit_paise', v_today_credit
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_wallet_summary() TO authenticated;


-- 3. GET WALLET TRANSACTIONS (Enriched ledger entries with type icons, fee lines, filters & pagination)
CREATE OR REPLACE FUNCTION public.get_wallet_transactions(
  p_type TEXT DEFAULT 'all',
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_wallet_id UUID;
  v_result JSONB;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_uid;
  IF v_wallet_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT COALESCE(jsonb_agg(item), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT
      l.id,
      l.direction::text AS direction,
      l.amount_paise,
      l.bucket::text AS bucket,
      l.ref_type,
      l.ref_id,
      l.note,
      l.created_at,
      
      -- Categorized Transaction Type
      CASE
        WHEN l.bucket = 'reward' OR l.ref_type = 'reward' OR l.note ILIKE '%Reward%' THEN 'reward_credit'
        WHEN l.ref_type = 'refund' OR l.note ILIKE '%Refund%' THEN 'refund'
        WHEN l.ref_type = 'platform_fee' OR l.note ILIKE '%Platform Fee%' OR l.note ILIKE '%Commission%' THEN 'platform_fee'
        WHEN l.ref_type = 'auto_payout' OR l.note ILIKE '%Auto-Payout%' THEN 'auto_payout'
        WHEN l.ref_type = 'payout' OR l.note ILIKE '%UPI Transfer%' OR l.note ILIKE '%Withdrawal%' THEN 'upi_transfer'
        WHEN l.ref_type IN ('order', 'produce_order') OR l.note ILIKE '%Farm Produce%' THEN 'produce_sale'
        WHEN l.ref_type = 'job_assignment' OR l.note ILIKE '%Daily Wage%' OR l.note ILIKE '%Earnings credited%' THEN 'daily_wage'
        ELSE 'other'
      END AS tx_type,

      -- Platform fee & commission breakdown if attached to payment
      COALESCE(
        (SELECT p.platform_fee_paise FROM public.payments p WHERE p.id = l.ref_id AND l.ref_type = 'payment'),
        0
      ) AS fee_paise

    FROM public.ledger_entries l
    WHERE l.wallet_id = v_wallet_id
      AND (p_start_date IS NULL OR l.created_at >= p_start_date)
      AND (p_end_date IS NULL OR l.created_at <= p_end_date)
      AND (
        p_type IS NULL
        OR p_type = ''
        OR p_type = 'all'
        OR (p_type = 'wages' AND (l.ref_type = 'job_assignment' OR l.note ILIKE '%Daily Wage%' OR l.note ILIKE '%Earnings%'))
        OR (p_type = 'transfers' AND (l.ref_type IN ('payout', 'auto_payout') OR l.note ILIKE '%UPI%' OR l.note ILIKE '%Withdrawal%'))
        OR (p_type = 'farm_sales' AND (l.ref_type IN ('order', 'produce_order') OR l.note ILIKE '%Farm Produce%'))
        OR (p_type = 'rewards' AND (l.bucket = 'reward' OR l.ref_type = 'reward' OR l.note ILIKE '%Reward%'))
        OR (p_type = 'refunds' AND (l.ref_type = 'refund' OR l.note ILIKE '%Refund%'))
      )
    ORDER BY l.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) item;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_wallet_transactions(TEXT, TIMESTAMPTZ, TIMESTAMPTZ, INT, INT) TO authenticated;


-- 4. REQUEST WALLET WITHDRAWAL (Enforces available balance in SQL, creates payouts row, executes wallet_debit)
CREATE OR REPLACE FUNCTION public.request_wallet_withdrawal(
  p_amount_paise BIGINT,
  p_method TEXT DEFAULT 'upi',
  p_payout_ref TEXT DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_wallet_id UUID;
  v_available BIGINT := 0;
  v_payout_id UUID;
  v_ledger_id UUID;
  v_key TEXT;
  v_ref TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_amount_paise <= 0 THEN
    RAISE EXCEPTION 'Withdrawal amount must be greater than zero.';
  END IF;

  -- Ensure wallet exists
  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_uid;
  IF v_wallet_id IS NULL THEN
    INSERT INTO public.wallets (user_id) VALUES (v_uid) RETURNING id INTO v_wallet_id;
  END IF;

  -- Strictly enforce available balance from wallet_balances view
  SELECT COALESCE(available_paise, 0) INTO v_available
  FROM public.wallet_balances
  WHERE wallet_id = v_wallet_id;

  IF v_available < p_amount_paise THEN
    RAISE EXCEPTION 'Insufficient available balance. Required: % paise, Available: % paise.',
      p_amount_paise, v_available;
  END IF;

  v_ref := COALESCE(p_payout_ref, 'DEMO-UPI-' || floor(random() * 900000 + 100000)::text);

  -- Insert payouts record
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
    'completed', -- Demo payout automatically marks completed
    COALESCE(p_method, 'upi'),
    v_ref,
    NOW()
  )
  RETURNING id INTO v_payout_id;

  -- Ledger debit via wallet_debit (which also has its own invariant check)
  v_key := COALESCE(p_idempotency_key, 'payout-debit-' || v_payout_id);
  v_ledger_id := public.wallet_debit(
    v_uid,
    p_amount_paise,
    'available'::public.ledger_bucket,
    'payout',
    v_payout_id,
    v_key,
    'Demo payout withdrawal to ' || COALESCE(p_method, 'UPI') || ' (' || v_ref || ')'
  );

  RETURN jsonb_build_object(
    'payout_id', v_payout_id,
    'ledger_id', v_ledger_id,
    'amount_paise', p_amount_paise,
    'payout_ref', v_ref,
    'status', 'completed',
    'is_demo', true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.request_wallet_withdrawal(BIGINT, TEXT, TEXT, TEXT) TO authenticated;
