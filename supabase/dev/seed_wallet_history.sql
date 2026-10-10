-- ============================================================================
-- Dev Script: seed_wallet_history.sql
-- Purpose: Seed realistic demo ledger history for wallet & escrow verification.
-- Compliance:
--   - All entries marked strictly with is_demo = true.
--   - Net balance effect is strictly ₹0.00 (all credits paired with debits/payouts).
-- CAUTION: DO NOT RUN AUTOMATICALLY. MANUAL REVIEW REQUIRED BEFORE EXECUTION.
-- ============================================================================

BEGIN;

DO $$
DECLARE
  v_demo_user_id UUID;
  v_wallet_id UUID;
BEGIN
  -- 1. Identify or retrieve a demo user profile
  SELECT id INTO v_demo_user_id
  FROM public.profiles
  WHERE is_demo = true OR phone = '+919999999999' OR full_name ILIKE '%Demo%'
  LIMIT 1;

  IF v_demo_user_id IS NULL THEN
    -- Fallback to the first available user in development environment
    SELECT id INTO v_demo_user_id FROM public.profiles LIMIT 1;
  END IF;

  IF v_demo_user_id IS NULL THEN
    RAISE NOTICE 'No profile found to seed wallet history. Skipping.';
    RETURN;
  END IF;

  -- 2. Ensure wallet exists
  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_demo_user_id;
  IF v_wallet_id IS NULL THEN
    INSERT INTO public.wallets (user_id, is_demo)
    VALUES (v_demo_user_id, true)
    RETURNING id INTO v_wallet_id;
  END IF;

  -- 3. Insert realistic demo ledger transactions (Net = ₹0)
  -- Entry 1: Daily wage credited (+₹800.00)
  INSERT INTO public.ledger_entries (
    wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at
  ) VALUES (
    v_wallet_id, 'credit', 80000, 'available', 'job_assignment', gen_random_uuid(),
    '[DEMO] Daily Wage - Campus Package Dispatch', true, NOW() - INTERVAL '2 hours'
  );

  -- Entry 2: Platform fee debited (-₹40.00)
  INSERT INTO public.ledger_entries (
    wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at
  ) VALUES (
    v_wallet_id, 'debit', 4000, 'available', 'platform_fee', gen_random_uuid(),
    '[DEMO] Platform Fee & Insurance Protection (5%)', true, NOW() - INTERVAL '1 hour 50 minutes'
  );

  -- Entry 3: UPI withdrawal to bank (-₹760.00)
  INSERT INTO public.ledger_entries (
    wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at
  ) VALUES (
    v_wallet_id, 'debit', 76000, 'available', 'payout', gen_random_uuid(),
    '[DEMO] Instant UPI Transfer to worker@okhdfcbank', true, NOW() - INTERVAL '1 hour'
  );

  -- Entry 4: Job escrow deposited (+₹1,200.00)
  INSERT INTO public.ledger_entries (
    wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at
  ) VALUES (
    v_wallet_id, 'credit', 120000, 'escrow', 'escrow_deposit', gen_random_uuid(),
    '[DEMO] SafeEscrow Locked - Electrical Repair Site', true, NOW() - INTERVAL '3 days'
  );

  -- Entry 5: Job escrow released (-₹1,200.00)
  INSERT INTO public.ledger_entries (
    wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at
  ) VALUES (
    v_wallet_id, 'debit', 120000, 'escrow', 'escrow_release', gen_random_uuid(),
    '[DEMO] SafeEscrow Released upon OTP Verification', true, NOW() - INTERVAL '2 days'
  );

  RAISE NOTICE 'Seeded 5 demo wallet transactions with net ₹0 balance for wallet %', v_wallet_id;
END;
$$;

COMMIT;
