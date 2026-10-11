-- ============================================================================
-- Migration: 0652_money_security.sql
-- Description: Locks down all money, wallet, and escrow functions.
--              Revokes money operations from public/anon/authenticated.
--              Direct money mutations restricted strictly to service_role.
--              Provides provider-authenticated confirm_job_completion_and_release.
-- ============================================================================

-- 1. DROP ALL OVERLOADS FIRST
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
      AND p.proname IN ('hold_escrow', 'release_escrow', 'refund_escrow', 'auto_release_escrow',
                        'record_payment_success', 'confirm_job_completion_and_release',
                        'release_assignment_escrow', 'refund_assignment_escrow')
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
  END LOOP;
END $$;

-- 2. CANONICAL SERVICE-ROLE MONEY FUNCTIONS
-- A. hold_escrow (service_role only)
CREATE OR REPLACE FUNCTION public.hold_escrow(p_payment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_pmt RECORD;
BEGIN
  SELECT * INTO v_pmt FROM public.payments WHERE id = p_payment_id;
  IF v_pmt.id IS NULL THEN RAISE EXCEPTION 'Payment not found.'; END IF;

  UPDATE public.payments
  SET status = 'held', updated_at = NOW()
  WHERE id = p_payment_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- B. release_escrow (service_role only)
CREATE OR REPLACE FUNCTION public.release_escrow(p_payment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_pmt RECORD; v_wallet_id UUID;
BEGIN
  SELECT * INTO v_pmt FROM public.payments WHERE id = p_payment_id;
  IF v_pmt.id IS NULL THEN RAISE EXCEPTION 'Payment not found.'; END IF;

  UPDATE public.payments
  SET status = 'released', updated_at = NOW()
  WHERE id = p_payment_id;

  -- Credit payee wallet
  IF v_pmt.payee_id IS NOT NULL THEN
    INSERT INTO public.wallets (user_id) VALUES (v_pmt.payee_id)
    ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_pmt.payee_id;

    INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, idempotency_key, note)
    VALUES (v_wallet_id, 'credit', v_pmt.amount_paise, 'available', v_pmt.ref_type, v_pmt.ref_id, 'REL-' || p_payment_id::text, 'Escrow payout released')
    ON CONFLICT (idempotency_key) DO NOTHING;
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- C. refund_escrow (service_role only, ONE canonical version)
CREATE OR REPLACE FUNCTION public.refund_escrow(
  p_payment_id UUID, p_refund_paise BIGINT, p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_pmt RECORD; v_wallet_id UUID;
BEGIN
  SELECT * INTO v_pmt FROM public.payments WHERE id = p_payment_id;
  IF v_pmt.id IS NULL THEN RAISE EXCEPTION 'Payment not found.'; END IF;

  UPDATE public.payments
  SET status = 'refunded', updated_at = NOW()
  WHERE id = p_payment_id;

  -- Credit payer wallet with refunded amount
  IF v_pmt.payer_id IS NOT NULL THEN
    INSERT INTO public.wallets (user_id) VALUES (v_pmt.payer_id)
    ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_pmt.payer_id;

    INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, idempotency_key, note)
    VALUES (v_wallet_id, 'credit', p_refund_paise, 'available', 'refund', p_payment_id, 'REF-' || p_payment_id::text, COALESCE(p_reason, 'Payment refund'))
    ON CONFLICT (idempotency_key) DO NOTHING;
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- D. auto_release_escrow (service_role only)
CREATE OR REPLACE FUNCTION public.auto_release_escrow()
RETURNS INT AS $$
DECLARE
  v_count INT := 0; r RECORD;
BEGIN
  FOR r IN (
    SELECT p.id
    FROM public.payments p
    JOIN public.job_assignments ja ON p.ref_type = 'assignment' AND p.ref_id = ja.id
    WHERE p.status = 'held' AND ja.status = 'completed' AND ja.ended_at < (NOW() - INTERVAL '48 hours')
  ) LOOP
    PERFORM public.release_escrow(r.id);
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- E. record_payment_success (service_role only, called from verified webhook)
CREATE OR REPLACE FUNCTION public.record_payment_success(
  p_payment_id UUID, p_razorpay_payment_id TEXT, p_signature_verified BOOLEAN
)
RETURNS BOOLEAN AS $$
DECLARE
  v_pmt RECORD;
BEGIN
  IF NOT p_signature_verified THEN
    RAISE EXCEPTION 'Signature verification failed.';
  END IF;

  SELECT * INTO v_pmt FROM public.payments WHERE id = p_payment_id;
  IF v_pmt.id IS NULL THEN RAISE EXCEPTION 'Payment not found.'; END IF;

  UPDATE public.payments
  SET status = CASE WHEN protected THEN 'held'::public.payment_status ELSE 'captured'::public.payment_status END,
      razorpay_payment_id = p_razorpay_payment_id,
      signature_verified = true,
      updated_at = NOW()
  WHERE id = p_payment_id;

  -- Update associated assignment if applicable
  IF v_pmt.ref_type = 'assignment' THEN
    UPDATE public.job_assignments SET status = 'accepted', updated_at = NOW() WHERE id = v_pmt.ref_id;
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 3. AUTH-CHECKED WRAPPER: confirm_job_completion_and_release
-- Callable by the provider of the job or admin only!
CREATE OR REPLACE FUNCTION public.confirm_job_completion_and_release(p_assignment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_uid UUID; v_ja RECORD; v_pmt RECORD;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Authentication required.'; END IF;

  SELECT ja.*, j.provider_id
  INTO v_ja
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_assignment_id;

  IF v_ja.id IS NULL THEN RAISE EXCEPTION 'Assignment not found.'; END IF;
  IF v_ja.provider_id != v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only job provider can confirm completion and release payment.';
  END IF;

  -- Update assignment status
  UPDATE public.job_assignments
  SET status = 'payment_released', payment_eligible = true, ended_at = COALESCE(ended_at, NOW()), updated_at = NOW()
  WHERE id = p_assignment_id;

  -- Release escrow payment if one exists
  SELECT * INTO v_pmt FROM public.payments WHERE ref_type = 'assignment' AND ref_id = p_assignment_id AND status = 'held' LIMIT 1;
  IF v_pmt.id IS NOT NULL THEN
    PERFORM public.release_escrow(v_pmt.id);
  END IF;

  -- Notify worker
  INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
  VALUES (
    v_ja.worker_id, 'payment_released', 'notification_payment_released_title', 'notification_payment_released_body',
    jsonb_build_object('assignment_id', p_assignment_id, 'amount_paise', v_ja.agreed_wage_paise)
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 4. STRICT PERMISSIONS LOCKDOWN
-- Revoke all direct money functions from public, anon, and authenticated
REVOKE ALL ON FUNCTION public.hold_escrow(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.release_escrow(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.refund_escrow(UUID, BIGINT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.auto_release_escrow() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.record_payment_success(UUID, TEXT, BOOLEAN) FROM PUBLIC, anon, authenticated;

-- Grant service_role only
GRANT EXECUTE ON FUNCTION public.hold_escrow(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.release_escrow(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.refund_escrow(UUID, BIGINT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.auto_release_escrow() TO service_role;
GRANT EXECUTE ON FUNCTION public.record_payment_success(UUID, TEXT, BOOLEAN) TO service_role;

-- Grant safe provider wrapper to authenticated
REVOKE ALL ON FUNCTION public.confirm_job_completion_and_release(UUID) FROM anon, PUBLIC;
GRANT EXECUTE ON FUNCTION public.confirm_job_completion_and_release(UUID) TO authenticated;

-- Revoke wallet debit/credit helper functions if they exist in schema
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'wallet_credit' AND pronamespace = 'public'::regnamespace) THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.wallet_credit FROM PUBLIC, anon, authenticated;';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.wallet_credit TO service_role;';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'wallet_debit' AND pronamespace = 'public'::regnamespace) THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.wallet_debit FROM PUBLIC, anon, authenticated;';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.wallet_debit TO service_role;';
  END IF;
END $$;

-- Verification query
SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args,
       COALESCE(string_agg(quote_ident(r.rolname), ', '), 'NO_EXECUTE') AS granted_roles
FROM pg_proc p
LEFT JOIN (
  SELECT (aclexplode(COALESCE(proacl, acldefault('f', pronamespace)))).grantee AS grantee_oid, oid AS proc_oid
  FROM pg_proc
) privs ON p.oid = privs.proc_oid
LEFT JOIN pg_roles r ON privs.grantee_oid = r.oid
WHERE p.pronamespace = 'public'::regnamespace
  AND p.proname IN ('hold_escrow', 'release_escrow', 'refund_escrow', 'auto_release_escrow',
                    'record_payment_success', 'confirm_job_completion_and_release')
GROUP BY p.proname, p.oid;

NOTIFY pgrst, 'reload schema';
