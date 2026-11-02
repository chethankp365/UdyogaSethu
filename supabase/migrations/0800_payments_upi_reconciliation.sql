-- ============================================================================
-- Migration: 0800_payments_upi_reconciliation.sql
-- Description: Payment Security Hardening, Revoke Client Payment Falsification,
--              UPI Flow Metadata, and Idempotent Server Reconciliation.
-- ============================================================================

-- 1. ADD UPI METADATA COLUMNS TO PAYMENTS TABLE
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS upi_vpa TEXT,
  ADD COLUMN IF NOT EXISTS upi_flow TEXT CHECK (upi_flow IN ('intent', 'qr', 'collect', 'standard')),
  ADD COLUMN IF NOT EXISTS reconciled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS gateway_response JSONB;

CREATE INDEX IF NOT EXISTS idx_payments_razorpay_order_id
  ON public.payments (razorpay_order_id)
  WHERE razorpay_order_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_payments_status_payer
  ON public.payments (status, payer_id);

-- 2. SECURITY FIX: REVOKE record_payment_success FROM authenticated
-- A client must NEVER be able to mark their own payment as captured or release escrow!
-- Only service_role (Edge Functions / Webhooks) may record verified payment success.
REVOKE EXECUTE ON FUNCTION public.record_payment_success(UUID, TEXT, BOOLEAN) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.record_payment_success(UUID, TEXT, BOOLEAN) FROM anon;
REVOKE EXECUTE ON FUNCTION public.record_payment_success(UUID, TEXT, BOOLEAN) FROM public;
GRANT EXECUTE ON FUNCTION public.record_payment_success(UUID, TEXT, BOOLEAN) TO service_role;

-- 3. SECURE RECONCILIATION RPC
-- Allows authenticated users to query their payment's reconciliation data
CREATE OR REPLACE FUNCTION public.get_payment_reconciliation_info(p_payment_id UUID)
RETURNS TABLE (
  payment_id UUID,
  payer_id UUID,
  payee_id UUID,
  amount_paise BIGINT,
  status public.payment_status,
  method public.payment_method,
  razorpay_order_id TEXT,
  razorpay_payment_id TEXT,
  receipt_no TEXT,
  created_at TIMESTAMPTZ,
  is_protected BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  RETURN QUERY
  SELECT
    p.id AS payment_id,
    p.payer_id,
    p.payee_id,
    p.amount_paise,
    p.status,
    p.method,
    p.razorpay_order_id,
    p.razorpay_payment_id,
    p.receipt_no,
    p.created_at,
    p.protected AS is_protected
  FROM public.payments p
  WHERE p.id = p_payment_id
    AND (p.payer_id = v_uid OR p.payee_id = v_uid OR public.is_admin());

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment not found or access denied.';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_payment_reconciliation_info(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_payment_reconciliation_info(UUID) TO service_role;
