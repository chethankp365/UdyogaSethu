-- ============================================================================
-- Dev Script: list_jobs_missing_coordinates.sql
-- Purpose: SELECT-only inspection script that lists all jobs that do not have
--          valid geographic coordinates or full address text.
-- These jobs are excluded from GPS map listings and nearby seeker feeds.
-- ============================================================================

SELECT 
  j.id AS job_id,
  j.title,
  j.status,
  j.address_text,
  j.landmark,
  j.location,
  j.created_at,
  p.full_name AS provider_name,
  CASE 
    WHEN j.location IS NULL THEN 'Missing location POINT coordinates'
    WHEN j.address_text IS NULL OR TRIM(j.address_text) = '' THEN 'Missing address text'
    ELSE 'Incomplete address details'
  END AS missing_reason
FROM public.jobs j
LEFT JOIN public.profiles p ON j.provider_id = p.id
WHERE j.location IS NULL 
   OR j.address_text IS NULL 
   OR TRIM(j.address_text) = ''
ORDER BY j.created_at DESC;
