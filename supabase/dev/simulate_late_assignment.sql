-- Script to simulate a late assignment starting 20 minutes ago for P4.10 testing
-- Run in Supabase SQL editor or via Supabase CLI

DO $$
DECLARE
  v_provider_id UUID;
  v_worker_id UUID;
  v_category_id UUID;
  v_job_id UUID;
  v_assignment_id UUID;
  v_flagged INT;
  v_replacement_count INT;
BEGIN
  -- 1. Find a provider and worker from demo accounts
  SELECT id INTO v_provider_id FROM public.profiles WHERE active_role = 'provider' LIMIT 1;
  SELECT id INTO v_worker_id FROM public.profiles WHERE active_role = 'seeker' AND id != v_provider_id LIMIT 1;
  SELECT id INTO v_category_id FROM public.service_categories LIMIT 1;

  IF v_provider_id IS NULL OR v_worker_id IS NULL THEN
    RAISE NOTICE 'Role-filtered profiles not found. Using first available profiles.';
    SELECT id INTO v_provider_id FROM public.profiles LIMIT 1;
    SELECT id INTO v_worker_id FROM public.profiles WHERE id != v_provider_id LIMIT 1;
  END IF;

  -- 2. Create job starting 20 minutes ago
  v_job_id := extensions.gen_random_uuid();
  INSERT INTO public.jobs (
    id,
    provider_id,
    category_id,
    title,
    description,
    wage_type,
    wage_paise,
    start_at,
    address_text,
    location,
    status
  ) VALUES (
    v_job_id,
    v_provider_id,
    v_category_id,
    'Urgent Electrical Wiring - Simulated Late',
    'Simulated job starting 20 minutes ago to test No-Show Recovery Engine',
    'daily',
    85000,
    NOW() - INTERVAL '20 minutes',
    'Indiranagar 100ft Road, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6412, 12.9716), 4326)::extensions.geography,
    'open'
  );

  -- 3. Create assignment in ticket_issued state
  v_assignment_id := extensions.gen_random_uuid();
  INSERT INTO public.job_assignments (
    id,
    job_id,
    worker_id,
    booking_code,
    status,
    agreed_wage_paise,
    created_at,
    updated_at
  ) VALUES (
    v_assignment_id,
    v_job_id,
    v_worker_id,
    'LATE-' || UPPER(SUBSTR(extensions.gen_random_uuid()::TEXT, 1, 6)),
    'ticket_issued',
    85000,
    NOW() - INTERVAL '25 minutes',
    NOW() - INTERVAL '25 minutes'
  );

  RAISE NOTICE 'Created late assignment: % (Job: %)', v_assignment_id, v_job_id;

  -- 4. Execute check_no_show_assignments() to verify idempotency and detection
  SELECT public.check_no_show_assignments() INTO v_flagged;
  RAISE NOTICE 'check_no_show_assignments flagged % late assignments.', v_flagged;

  -- 5. Test idempotency: running again should flag 0 new notifications
  SELECT public.check_no_show_assignments() INTO v_flagged;
  RAISE NOTICE 'Idempotency check: second run flagged % assignments (expected 0).', v_flagged;

  -- 6. Test find_replacement RPC for this late assignment
  SELECT COUNT(*) INTO v_replacement_count FROM public.find_replacement(v_assignment_id);
  RAISE NOTICE 'find_replacement returned % available replacement candidates.', v_replacement_count;
END $$;
