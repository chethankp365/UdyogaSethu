-- supabase/dev/remove_sample_jobs.sql
-- Deletes only the [TEST] rows created by sample_jobs.sql.
-- Safe to run repeatedly.

DELETE FROM public.job_applications
WHERE job_id IN (
  SELECT id FROM public.jobs WHERE title LIKE '[TEST]%'
);

DELETE FROM public.jobs
WHERE title LIKE '[TEST]%';

DELETE FROM public.ad_banners
WHERE title LIKE '[TEST]%';

-- Verification query: confirm zero [TEST] rows remain
SELECT 
  (SELECT COUNT(*) FROM public.jobs WHERE title LIKE '[TEST]%') AS remaining_test_jobs,
  (SELECT COUNT(*) FROM public.ad_banners WHERE title LIKE '[TEST]%') AS remaining_test_banners;
