-- ============================================================================
-- Dev Script: remove_wallet_history.sql
-- Purpose: Safely delete all seeded demo ledger entries and payouts.
-- Filters: is_demo = true OR note ILIKE '%[DEMO]%'
-- CAUTION: DO NOT RUN AUTOMATICALLY. MANUAL REVIEW REQUIRED BEFORE EXECUTION.
-- ============================================================================

BEGIN;

DO $$
DECLARE
  v_deleted_count INT := 0;
BEGIN
  -- 1. Delete demo ledger entries
  DELETE FROM public.ledger_entries
  WHERE is_demo = true
     OR note ILIKE '%[DEMO]%';

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RAISE NOTICE 'Deleted % demo ledger entries.', v_deleted_count;

  -- 2. Delete demo payouts
  DELETE FROM public.payouts
  WHERE is_demo = true
     OR payout_ref ILIKE '%DEMO%';

  RAISE NOTICE 'Cleaned up demo wallet and payout records successfully.';
END;
$$;

COMMIT;
