-- ============================================================================
-- Dev Script: remove_demo_data.sql
-- Purpose: Safely delete demo & test data in strict foreign-key dependency order
--          within a single transaction.
-- Filters: rows matching [TEST], 'Escrow E2E Job', 'Sharma Site', or is_demo = true.
-- CAUTION: DO NOT RUN AUTOMATICALLY. MANUAL REVIEW REQUIRED BEFORE EXECUTION.
-- ============================================================================

BEGIN;

-- 1. Identify target demo jobs into a temporary table for atomic referencing
CREATE TEMP TABLE target_demo_jobs ON COMMIT DROP AS
SELECT id FROM public.jobs
WHERE is_demo = true
   OR title ILIKE '%[TEST]%'
   OR title ILIKE '%Escrow E2E Job%'
   OR title ILIKE '%Sharma Site%';

-- 2. Identify target demo assignments
CREATE TEMP TABLE target_demo_assignments ON COMMIT DROP AS
SELECT id FROM public.job_assignments
WHERE job_id IN (SELECT id FROM target_demo_jobs)
   OR booking_code ILIKE '%TEST%'
   OR booking_code ILIKE '%BOOK-7842%'
   OR booking_code ILIKE '%DEMO%';

-- 3. Delete evidence and timeline events attached to demo assignments
DELETE FROM public.assignment_events
WHERE assignment_id IN (SELECT id FROM target_demo_assignments);

DELETE FROM public.assignment_evidence
WHERE assignment_id IN (SELECT id FROM target_demo_assignments);

DELETE FROM public.job_timeline
WHERE assignment_id IN (SELECT id FROM target_demo_assignments);

-- 4. Delete payments and escrow ledger entries linked to demo assignments
DELETE FROM public.ledger_entries
WHERE reference_id IN (SELECT id::text FROM target_demo_assignments)
  AND is_demo = true;

DELETE FROM public.payments
WHERE assignment_id IN (SELECT id FROM target_demo_assignments);

-- 5. Delete assignments
DELETE FROM public.job_assignments
WHERE id IN (SELECT id FROM target_demo_assignments);

-- 6. Delete applications attached to demo jobs
DELETE FROM public.job_applications
WHERE job_id IN (SELECT id FROM target_demo_jobs);

-- 7. Delete demo jobs
DELETE FROM public.jobs
WHERE id IN (SELECT id FROM target_demo_jobs);

-- Sanity checks: Verify remaining count
DO $$
DECLARE
  v_remaining_jobs INT;
BEGIN
  SELECT COUNT(*) INTO v_remaining_jobs
  FROM public.jobs
  WHERE is_demo = true OR title ILIKE '%[TEST]%' OR title ILIKE '%Escrow E2E Job%';

  IF v_remaining_jobs > 0 THEN
    RAISE EXCEPTION 'Cleanup verification failed: % demo jobs still exist', v_remaining_jobs;
  END IF;
  RAISE NOTICE 'Demo data successfully purged in dependency order.';
END $$;

COMMIT;
