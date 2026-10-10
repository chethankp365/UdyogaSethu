-- ============================================================================
-- Migration: 0600_wallet_escrow_filters_and_validation.sql
-- Description: Adds 'escrow' filter to get_wallet_transactions RPC,
--              and provides validate_upi_payment RPC for QR validation.
-- ============================================================================

-- 1. UPDATE GET WALLET TRANSACTIONS WITH ESCROW FILTER
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
        OR (p_type = 'escrow' AND (l.bucket = 'escrow' OR l.ref_type ILIKE '%escrow%' OR l.note ILIKE '%Escrow%'))
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

-- 2. VALIDATE UPI PAYMENT RPC
CREATE OR REPLACE FUNCTION public.validate_upi_payment(
  p_vpa TEXT,
  p_amount_rupees NUMERIC DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_is_valid BOOLEAN;
  v_vpa_clean TEXT;
BEGIN
  v_vpa_clean := LOWER(TRIM(p_vpa));
  
  -- Basic regex check for VPA structure (user@handle)
  v_is_valid := v_vpa_clean ~ '^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$';

  IF NOT v_is_valid THEN
    RETURN jsonb_build_object(
      'is_valid', false,
      'error', 'Invalid Virtual Payment Address (VPA) format. Must match user@bank.'
    );
  END IF;

  RETURN jsonb_build_object(
    'is_valid', true,
    'vpa', v_vpa_clean,
    'amount', p_amount_rupees,
    'routed_gateway', 'NPCI_UPI_SANDBOX',
    'status', 'ACTIVE'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.validate_upi_payment(TEXT, NUMERIC) TO authenticated;
