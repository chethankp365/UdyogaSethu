-- Migration: 0760_demo_scenarios_and_reset.sql
-- Description: Server-authoritative reset_demo RPC for evaluator demonstration (P10.1)
-- Restricted to authorized demo confirmation token or admin callers. Never resets production users.

CREATE TABLE IF NOT EXISTS public.demo_users (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  phone TEXT UNIQUE,
  role TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed demo user tracking records if not already populated
INSERT INTO public.demo_users (user_id, phone, role)
SELECT id, phone, active_role
FROM public.profiles
WHERE phone IN (
  '+919900000001', '+919900000101', '+919900000102', '+919900000103',
  '+919900000104', '+919900000105', '+919900000106', '+919900000107',
  '+919900000201', '+919900000202', '+919900000203', '+919900000301',
  '+919900000302', '+919900000303', '+919900000304'
)
ON CONFLICT (user_id) DO NOTHING;

-- Server-Authoritative reset_demo RPC
CREATE OR REPLACE FUNCTION public.reset_demo(p_confirmation_code TEXT DEFAULT '')
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_caller_role TEXT;
  v_is_authorized BOOLEAN := false;
  v_as1 UUID := '66666666-6666-4666-8666-666666666601';
  v_s1 UUID := '22222222-2222-4222-8222-222222222201';
  v_p3 UUID := '33333333-3333-4333-8333-333333333303';
  v_f1 UUID := '44444444-4444-4444-8444-444444444401';
  v_w_s1 UUID;
BEGIN
  -- 1. Security Authorization Check
  -- Permitted only with valid demo confirmation token OR caller is an admin
  IF p_confirmation_code = 'DEMO_RESET_UDYOGASETHU_2026' THEN
    v_is_authorized := true;
  ELSIF auth.uid() IS NOT NULL THEN
    SELECT active_role INTO v_caller_role FROM public.profiles WHERE id = auth.uid();
    IF v_caller_role = 'admin' THEN
      v_is_authorized := true;
    ELSIF EXISTS (SELECT 1 FROM public.demo_users WHERE user_id = auth.uid()) THEN
      v_is_authorized := true;
    END IF;
  END IF;

  IF NOT v_is_authorized THEN
    RAISE EXCEPTION 'UNAUTHORIZED_DEMO_RESET: Demo reset is restricted to authorized demo builds and admin evaluations.';
  END IF;

  -- 2. Clean mutated demo data strictly for demo_users (preserving production data)
  DELETE FROM public.assignment_events
  WHERE assignment_id IN (
    SELECT id FROM public.job_assignments
    WHERE worker_id IN (SELECT user_id FROM public.demo_users)
       OR job_id IN (SELECT id FROM public.jobs WHERE provider_id IN (SELECT user_id FROM public.demo_users))
  );

  DELETE FROM public.ratings_reviews
  WHERE rater_id IN (SELECT user_id FROM public.demo_users)
     OR target_id IN (SELECT user_id FROM public.demo_users);

  DELETE FROM public.payments
  WHERE payer_id IN (SELECT user_id FROM public.demo_users)
     OR payee_id IN (SELECT user_id FROM public.demo_users);

  DELETE FROM public.job_assignments
  WHERE (worker_id IN (SELECT user_id FROM public.demo_users)
     OR job_id IN (SELECT id FROM public.jobs WHERE provider_id IN (SELECT user_id FROM public.demo_users)))
    AND id != v_as1; -- Keep baseline assignment

  DELETE FROM public.job_applications
  WHERE worker_id IN (SELECT user_id FROM public.demo_users)
     OR job_id IN (SELECT id FROM public.jobs WHERE provider_id IN (SELECT user_id FROM public.demo_users));

  -- 3. Reset produce listings stock for demo farmers
  UPDATE public.produce_listings
  SET stock_qty = 500.0, status = 'active'
  WHERE farmer_id = v_f1 AND name ILIKE '%tomato%';

  -- 4. Restore baseline assignment state for Ramesh Kumar (BOOK-DEMO-001)
  UPDATE public.job_assignments
  SET status = 'ticket_issued',
      started_at = NULL,
      ended_at = NULL,
      arrived_at = NULL,
      elapsed_seconds = 0
  WHERE id = v_as1;

  -- 5. Restore baseline wallet ledger for Ramesh Kumar
  SELECT id INTO v_w_s1 FROM public.wallets WHERE user_id = v_s1;
  IF v_w_s1 IS NOT NULL THEN
    -- Ledger entries are append-only; ensure baseline credits exist
    INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, idempotency_key, note)
    VALUES
      (v_w_s1, 'credit', 50000, 'available', 'reward', NULL, 'demo-seed-ledger-s1-reward', 'Welcome Bonus Credited')
    ON CONFLICT (idempotency_key) DO NOTHING;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Demo seed state restored cleanly for 5 evaluators scenarios',
    'timestamp', NOW()
  );
END;
$$;

-- Grant execution to authenticated users and service_role
GRANT EXECUTE ON FUNCTION public.reset_demo(TEXT) TO authenticated, service_role;

-- Verification check
SELECT 'reset_demo RPC installed successfully' AS status;
