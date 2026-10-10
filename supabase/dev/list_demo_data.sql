-- ============================================================================
-- Dev Script: list_demo_data.sql
-- Purpose: SELECT-only inspection script that lists test-looking jobs,
--          applications, invitations, and assignments in the database.
-- Filters: titles with '[TEST]', 'Escrow E2E Job', provider 'Local Employer',
--          or flagged with is_demo = true.
-- DO NOT MODIFY DATA. READ-ONLY.
-- ============================================================================

-- 1. Demo & Test Jobs
SELECT 
  j.id AS job_id,
  j.title,
  j.status,
  j.is_demo,
  j.start_at,
  j.slots_total,
  j.slots_filled,
  j.address_text,
  j.created_at,
  p.full_name AS provider_name,
  pr.org_name AS provider_org
FROM public.jobs j
LEFT JOIN public.profiles p ON j.provider_id = p.id
LEFT JOIN public.provider_profiles pr ON j.provider_id = pr.user_id
WHERE j.is_demo = true
   OR j.title ILIKE '%[TEST]%'
   OR j.title ILIKE '%Escrow E2E Job%'
   OR j.title ILIKE '%Sharma Site%'
   OR p.full_name ILIKE '%Local Employer%'
   OR pr.org_name ILIKE '%Local Employer%'
ORDER BY j.created_at DESC;

-- 2. Demo & Test Job Applications
SELECT 
  ja.id AS application_id,
  ja.job_id,
  j.title AS job_title,
  ja.worker_id,
  p.full_name AS worker_name,
  ja.status AS application_status,
  ja.message,
  ja.created_at
FROM public.job_applications ja
JOIN public.jobs j ON ja.job_id = j.id
LEFT JOIN public.profiles p ON ja.worker_id = p.id
WHERE j.is_demo = true
   OR j.title ILIKE '%[TEST]%'
   OR j.title ILIKE '%Escrow E2E Job%'
   OR j.title ILIKE '%Sharma Site%'
   OR ja.message ILIKE '%[TEST]%'
ORDER BY ja.created_at DESC;

-- 3. Demo & Test Job Assignments (Invitations & Bookings)
SELECT 
  ass.id AS assignment_id,
  ass.booking_code,
  ass.job_id,
  j.title AS job_title,
  ass.worker_id,
  pw.full_name AS worker_name,
  ass.provider_id,
  pp.full_name AS provider_name,
  ass.status AS assignment_status,
  ass.agreed_wage_paise,
  ass.created_at
FROM public.job_assignments ass
JOIN public.jobs j ON ass.job_id = j.id
LEFT JOIN public.profiles pw ON ass.worker_id = pw.id
LEFT JOIN public.profiles pp ON ass.provider_id = pp.id
WHERE j.is_demo = true
   OR j.title ILIKE '%[TEST]%'
   OR j.title ILIKE '%Escrow E2E Job%'
   OR j.title ILIKE '%Sharma Site%'
   OR ass.booking_code ILIKE '%TEST%'
   OR ass.booking_code ILIKE '%BOOK-7842%'
   OR ass.booking_code ILIKE '%DEMO%'
ORDER BY ass.created_at DESC;

-- 4. Assignment Events Linked to Demo Assignments
SELECT 
  ae.id AS event_id,
  ae.assignment_id,
  ae.stage,
  ae.actor_id,
  ae.note,
  ae.created_at
FROM public.assignment_events ae
JOIN public.job_assignments ass ON ae.assignment_id = ass.id
JOIN public.jobs j ON ass.job_id = j.id
WHERE j.is_demo = true
   OR j.title ILIKE '%[TEST]%'
   OR j.title ILIKE '%Escrow E2E Job%'
   OR j.title ILIKE '%Sharma Site%'
ORDER BY ae.created_at DESC;
