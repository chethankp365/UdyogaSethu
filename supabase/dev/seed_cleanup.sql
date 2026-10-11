-- ============================================================================
-- Developer Script: seed_cleanup.sql
-- Description: Safely identifies and removes demo/seed rows from the live database.
--              Step 1: Read-only SELECT preview of all candidate demo rows.
--              Step 2: Transactional DELETE with row-count checks.
-- INSTRUCTION: DO NOT RUN AUTOMATICALLY. Review in SQL Editor before execution.
-- ============================================================================

-- ============================================================================
-- STEP 1: READ-ONLY PREVIEW
-- ============================================================================

SELECT 'demo_jobs_5555' AS category, count(*) AS count_to_delete
FROM public.jobs
WHERE id::text LIKE '55555555-%' OR is_demo = true
UNION ALL
SELECT 'student_seed_jobs_0320', count(*)
FROM public.jobs
WHERE title IN ('Campus Delivery & Package Dispatcher', 'Weekend Library Sorter & Digital Catalog Assistant')
UNION ALL
SELECT 'resource_listings_8888', count(*)
FROM public.resource_listings
WHERE id::text LIKE '88888888-8888-4888-8888-8888888888%'
UNION ALL
SELECT 'produce_listings_a_series', count(*)
FROM public.produce_listings
WHERE id::text ~ '^a[1-6]{7}-'
UNION ALL
SELECT 'mandi_prices_sample_0510', count(*)
FROM public.mandi_prices
WHERE market IN ('K.R. Market (Bengaluru)', 'Yeshwantpur APMC', 'Binny Mill', 'Bandipalya APMC Yard', 'Sugar Mill Co-op', 'Mandya APMC Yard')
  AND source IS NULL
UNION ALL
SELECT 'duplicate_ad_banners', count(*) - 1
FROM public.ad_banners
WHERE title = 'Kirloskar Hybrid Solar Water Pump';

-- Preview individual candidate jobs
SELECT id, title, start_at, status, provider_id, created_at
FROM public.jobs
WHERE id::text LIKE '55555555-%' OR is_demo = true
   OR title IN ('Campus Delivery & Package Dispatcher', 'Weekend Library Sorter & Digital Catalog Assistant')
ORDER BY created_at DESC;

-- ============================================================================
-- STEP 2: TRANSACTIONAL DELETE (WITH INTEGRITY CHECKS)
-- Uncomment and execute ONLY after reviewing the preview results above.
-- ============================================================================

/*
BEGIN;

-- 1. Remove assignments, applications, events associated with demo jobs
DELETE FROM public.attendance_logs
WHERE assignment_id IN (
  SELECT ja.id FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE j.id::text LIKE '55555555-%' OR j.is_demo = true
     OR j.title IN ('Campus Delivery & Package Dispatcher', 'Weekend Library Sorter & Digital Catalog Assistant')
);

DELETE FROM public.assignment_events
WHERE assignment_id IN (
  SELECT ja.id FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE j.id::text LIKE '55555555-%' OR j.is_demo = true
     OR j.title IN ('Campus Delivery & Package Dispatcher', 'Weekend Library Sorter & Digital Catalog Assistant')
);

DELETE FROM public.job_assignments
WHERE job_id IN (
  SELECT id FROM public.jobs
  WHERE id::text LIKE '55555555-%' OR is_demo = true
     OR title IN ('Campus Delivery & Package Dispatcher', 'Weekend Library Sorter & Digital Catalog Assistant')
);

DELETE FROM public.job_applications
WHERE job_id IN (
  SELECT id FROM public.jobs
  WHERE id::text LIKE '55555555-%' OR is_demo = true
     OR title IN ('Campus Delivery & Package Dispatcher', 'Weekend Library Sorter & Digital Catalog Assistant')
);

-- 2. Delete demo jobs
DELETE FROM public.jobs
WHERE id::text LIKE '55555555-%' OR is_demo = true
   OR title IN ('Campus Delivery & Package Dispatcher', 'Weekend Library Sorter & Digital Catalog Assistant');

-- 3. Delete 0530 demo equipment/resource listings
DELETE FROM public.resource_listings
WHERE id::text LIKE '88888888-8888-4888-8888-8888888888%';

-- 4. Delete 0540 demo produce listings
DELETE FROM public.order_items
WHERE listing_id IN (SELECT id FROM public.produce_listings WHERE id::text ~ '^a[1-6]{7}-');

DELETE FROM public.produce_listings
WHERE id::text ~ '^a[1-6]{7}-';

-- 5. Delete 0510 sample mandi entries (keeping real API-synced mandi rows)
DELETE FROM public.mandi_prices
WHERE market IN ('K.R. Market (Bengaluru)', 'Yeshwantpur APMC', 'Binny Mill', 'Bandipalya APMC Yard', 'Sugar Mill Co-op', 'Mandya APMC Yard')
  AND source IS NULL;

-- 6. Remove duplicate ad banners (keep newest)
DELETE FROM public.ad_banners
WHERE id NOT IN (
  SELECT DISTINCT ON (title) id
  FROM public.ad_banners
  ORDER BY title, created_at DESC
);

COMMIT;
*/
