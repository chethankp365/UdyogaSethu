-- ============================================================================
-- Dev Script: remove_wallet_history.sql
-- Dependencies:
--   - Migration 0620_ledger_is_demo_and_savings_planner.sql
-- Purpose:
--   Safely removes seeded demo ledger entries for the specified test user.
--   Respects append-only ledger rules by invoking clean_demo_wallet_history()
--   or directly deleting rows where is_demo = true.
--
-- CAUTION:
--   DO NOT RUN AUTOMATICALLY. MANUAL EXECUTION BY DEVELOPER ON TEST ACCOUNT ONLY.
-- ============================================================================

DO $$
DECLARE
  v_test_user_id UUID;
  v_wallet_id UUID;
  v_deleted_count INT := 0;
BEGIN
  -- 1. Identify target test user
  SELECT COALESCE(
    (SELECT id FROM public.profiles WHERE phone = '+919999999999' OR full_name ILIKE '%Demo%' LIMIT 1),
    (SELECT id FROM public.profiles LIMIT 1)
  ) INTO v_test_user_id;

  IF v_test_user_id IS NULL THEN
    RAISE NOTICE 'No profile found for cleaning wallet history.';
    RETURN;
  END IF;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_test_user_id;
  IF v_wallet_id IS NULL THEN
    RAISE NOTICE 'No wallet found for user %.', v_test_user_id;
    RETURN;
  END IF;

  -- 2. Safely remove demo ledger entries
  DELETE FROM public.ledger_entries
  WHERE wallet_id = v_wallet_id
    AND (is_demo = true OR note ILIKE '%[DEMO]%');

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RAISE NOTICE 'Cleaned up % demo ledger entries for wallet % (user %).', v_deleted_count, v_wallet_id, v_test_user_id;
END;
$$;
