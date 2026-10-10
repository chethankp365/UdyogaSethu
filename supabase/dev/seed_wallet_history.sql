-- ============================================================================
-- Dev Script: seed_wallet_history.sql
-- Dependencies:
--   - Migration 0620_ledger_is_demo_and_savings_planner.sql (is_demo column on ledger_entries)
-- Purpose:
--   Seeds realistic, balanced (Net = 0, Pending Escrow = 0) demo ledger history
--   for a specified TEST USER across the previous 5 months (Prompt D4).
--
-- Features included across 5 months:
--   - Wage credits via escrow releases
--   - Platform commission fees
--   - Bank withdrawals with valid 12-digit UTR numbers
--   - Direct UPI transfers
--   - Exactly one escrow dispute refund
--   - Balanced: Total Credits = Total Debits (Net Balance = 0, Pending Escrow = 0)
--   - All rows flagged with is_demo = true
--
-- CAUTION:
--   DO NOT RUN AUTOMATICALLY. MANUAL EXECUTION BY DEVELOPER ON TEST ACCOUNT ONLY.
-- ============================================================================

DO $$
DECLARE
  v_test_user_id UUID;
  v_wallet_id UUID;
BEGIN
  -- --------------------------------------------------------------------------
  -- 1. SPECIFY TEST USER ID (Replace with your authenticated test user's UUID)
  -- --------------------------------------------------------------------------
  -- CTE / Variable for target test user:
  SELECT COALESCE(
    (SELECT id FROM public.profiles WHERE phone = '+919999999999' OR full_name ILIKE '%Demo%' LIMIT 1),
    (SELECT id FROM public.profiles LIMIT 1)
  ) INTO v_test_user_id;

  IF v_test_user_id IS NULL THEN
    RAISE NOTICE 'No profile found for seeding wallet history. Specify user_id manually.';
    RETURN;
  END IF;

  -- 2. Ensure wallet exists
  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_test_user_id;
  IF v_wallet_id IS NULL THEN
    INSERT INTO public.wallets (user_id)
    VALUES (v_test_user_id)
    RETURNING id INTO v_wallet_id;
  END IF;

  -- --------------------------------------------------------------------------
  -- 3. INSERT 5-MONTH BALANCED DEMO LEDGER HISTORY (Net = ₹0, Escrow = ₹0)
  -- --------------------------------------------------------------------------

  -- MONTH -5 (5 months ago):
  -- Job: Campus Logistics Assistant | Escrow hold & release -> ₹1,000 wage, ₹50 fee, ₹950 bank payout
  -- Escrow cycle:
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'credit', 100000, 'escrow', 'job_assignment', gen_random_uuid(), '[DEMO] Escrow Held - Campus Courier Dispatch', true, NOW() - INTERVAL '150 days');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 100000, 'escrow', 'escrow_release', gen_random_uuid(), '[DEMO] Escrow Released - Campus Courier Dispatch', true, NOW() - INTERVAL '149 days 2 hours');
  -- Available credit & payouts:
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'credit', 100000, 'available', 'job_assignment', gen_random_uuid(), '[DEMO] Daily Wage - Campus Courier Dispatch', true, NOW() - INTERVAL '149 days 2 hours');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 5000, 'available', 'platform_fee', gen_random_uuid(), '[DEMO] Platform Fee & Insurance (5%)', true, NOW() - INTERVAL '149 days 1 hour');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 95000, 'available', 'payout', gen_random_uuid(), '[DEMO] Bank Transfer UTR: UTR260512345678 (•••• 9481)', true, NOW() - INTERVAL '148 days');

  -- MONTH -4 (4 months ago):
  -- Agri Produce Sale -> ₹2,500 produce sale, ₹125 fee, ₹2,375 UPI withdrawal
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'credit', 250000, 'available', 'order', gen_random_uuid(), '[DEMO] Farm Produce - 50kg Organic Tomatoes', true, NOW() - INTERVAL '120 days');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 12500, 'available', 'platform_fee', gen_random_uuid(), '[DEMO] Platform Commission (5%)', true, NOW() - INTERVAL '119 days 23 hours');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 237500, 'available', 'payout', gen_random_uuid(), '[DEMO] UPI Transfer to suresh@okhdfcbank (UTR260623456789)', true, NOW() - INTERVAL '119 days');

  -- MONTH -3 (3 months ago):
  -- Daily Wage Shift -> ₹1,600 wage, ₹80 fee, ₹1,520 bank payout with 12-digit UTR
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'credit', 160000, 'available', 'job_assignment', gen_random_uuid(), '[DEMO] Daily Wage - Electrical Wiring & Fitting', true, NOW() - INTERVAL '90 days');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 8000, 'available', 'platform_fee', gen_random_uuid(), '[DEMO] Platform Safety Fee (5%)', true, NOW() - INTERVAL '89 days 23 hours');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 152000, 'available', 'payout', gen_random_uuid(), '[DEMO] Bank Transfer UTR: UTR260734567890 (•••• 4120)', true, NOW() - INTERVAL '88 days');

  -- MONTH -2 (2 months ago):
  -- Daily Wage Shift + ONE REFUND:
  -- Wage: ₹2,000 credit, ₹100 fee debit
  -- Dispute Refund: ₹600 debit (refunded to employer due to hours variance)
  -- Net UPI Withdrawal: ₹1,300 debit
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'credit', 200000, 'available', 'job_assignment', gen_random_uuid(), '[DEMO] Daily Wage - Warehouse Inventory Sorting', true, NOW() - INTERVAL '60 days');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 10000, 'available', 'platform_fee', gen_random_uuid(), '[DEMO] Platform Commission (5%)', true, NOW() - INTERVAL '59 days 23 hours');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 60000, 'available', 'refund', gen_random_uuid(), '[DEMO] Escrow Dispute Partial Refund #DSP-9041', true, NOW() - INTERVAL '59 days 12 hours');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 130000, 'available', 'payout', gen_random_uuid(), '[DEMO] UPI Transfer to worker@ybl (UTR260845678901)', true, NOW() - INTERVAL '58 days');

  -- MONTH -1 (1 month ago):
  -- Farm Produce Sale -> ₹3,000 credit, ₹150 fee debit, ₹2,850 bank payout with 12-digit UTR
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'credit', 300000, 'available', 'order', gen_random_uuid(), '[DEMO] Farm Produce - 100kg Bell Peppers Lot', true, NOW() - INTERVAL '30 days');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 15000, 'available', 'platform_fee', gen_random_uuid(), '[DEMO] Platform Commission (5%)', true, NOW() - INTERVAL '29 days 23 hours');
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, note, is_demo, created_at)
  VALUES (v_wallet_id, 'debit', 285000, 'available', 'payout', gen_random_uuid(), '[DEMO] Bank Transfer UTR: UTR260956789012 (•••• 9481)', true, NOW() - INTERVAL '28 days');

  RAISE NOTICE 'Successfully seeded 5 months of balanced demo ledger entries for wallet % (Net = ₹0, Escrow = ₹0).', v_wallet_id;
END;
$$;
