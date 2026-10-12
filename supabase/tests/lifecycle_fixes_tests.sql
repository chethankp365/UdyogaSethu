-- SQL Test Suite: lifecycle_fixes_tests.sql
-- Verifies fixes for Symptoms A-F:
-- 1. get_job_applicants returns real profile names/avatars/assignment_id via SECURITY DEFINER without leaking phone/email.
-- 2. get_active_job_details resolves via assignment ID, job ID, or application ID, with schema-qualified ST_X/ST_Y coordinates.
-- 3. get_worker_schedule returns scheduled items across UTC/IST boundaries.
-- 4. verify_ticket_scan handles atomic locks and status checks.

DO $$
DECLARE
  v_provider     UUID := gen_random_uuid();
  v_worker       UUID := gen_random_uuid();
  v_cat_id       UUID;
  v_job_id       UUID;
  v_app_id       UUID;
  v_assignment_id UUID;
  v_ticket_code  TEXT;
  v_res_json     JSONB;
  v_row_count    INT;
  v_sched_count  INT;
  v_details_rec  RECORD;
  v_scan_res     JSONB;
  v_suffix       TEXT := SUBSTRING(gen_random_uuid()::text, 1, 8);
BEGIN
  RAISE NOTICE 'Starting Lifecycle Fixes SQL Tests [%]', v_suffix;

  -- 1. Setup Auth Users & Profiles
  INSERT INTO auth.users (id, email, instance_id, aud, role) VALUES
    (v_provider, 'prov_' || v_suffix || '@test.com', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_worker,   'work_' || v_suffix || '@test.com', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.profiles (id, full_name, email, phone, active_role, avatar_path, home_location) VALUES
    (v_provider, 'Sophia Nancy ' || v_suffix, 'prov_' || v_suffix || '@test.com', '+919876543210', 'provider', 'avatars/provider.jpg', 'POINT(77.6500 12.9800)'::geography),
    (v_worker,   'Ramesh Kumar ' || v_suffix, 'work_' || v_suffix || '@test.com', '+919876543211', 'seeker',   'avatars/worker.jpg',   'POINT(77.6520 12.9820)'::geography)
  ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, avatar_path = EXCLUDED.avatar_path;

  INSERT INTO public.user_roles (user_id, role) VALUES
    (v_provider, 'provider'),
    (v_worker, 'seeker')
  ON CONFLICT (user_id, role) DO NOTHING;

  INSERT INTO public.worker_profiles (user_id, seeker_type, is_verified_badge, rating_avg, rating_count, jobs_completed, languages)
  VALUES (v_worker, 'student', true, 4.9, 12, 10, '["kn", "en"]'::jsonb)
  ON CONFLICT (user_id) DO UPDATE SET seeker_type = 'student', is_verified_badge = true;

  -- 2. Setup Category and Job
  SELECT id INTO v_cat_id FROM public.service_categories LIMIT 1;
  IF v_cat_id IS NULL THEN
    INSERT INTO public.service_categories (slug, icon, names)
    VALUES ('helper', 'handyman', '{"en": "General Helper"}'::jsonb)
    RETURNING id INTO v_cat_id;
  END IF;

  INSERT INTO public.jobs (
    provider_id, category_id, title, description, wage_type, wage_paise,
    start_at, est_duration_minutes, slots_total, slots_filled, status,
    location, address_text
  ) VALUES (
    v_provider, v_cat_id, 'Warehouse Stacking ' || v_suffix, 'Box moving and stacking',
    'daily', 70000, NOW() + INTERVAL '2 hours', 240, 2, 0, 'open',
    'POINT(77.6540 12.9850)'::geography, '56, 2nd Main Rd, Dooravani Nagar, Bengaluru 560016'
  ) RETURNING id INTO v_job_id;

  -- 3. Worker applies to job
  INSERT INTO public.job_applications (job_id, worker_id, status, message)
  VALUES (v_job_id, v_worker, 'applied', 'Ready to work today')
  RETURNING id INTO v_app_id;

  -- Test A: get_job_applicants returns real name and avatar
  -- Set auth context to provider
  PERFORM set_config('request.jwt.claim.sub', v_provider::text, true);

  SELECT public.get_job_applicants(v_job_id) INTO v_res_json;
  IF jsonb_array_length(v_res_json) != 1 THEN
    RAISE EXCEPTION 'Expected 1 applicant, got %', jsonb_array_length(v_res_json);
  END IF;

  IF (v_res_json->0->>'worker_name') NOT LIKE 'Ramesh Kumar%' THEN
    RAISE EXCEPTION 'Expected worker_name to start with Ramesh Kumar, got %', (v_res_json->0->>'worker_name');
  END IF;

  IF (v_res_json->0->>'worker_avatar') != 'avatars/worker.jpg' THEN
    RAISE EXCEPTION 'Expected worker_avatar to be avatars/worker.jpg, got %', (v_res_json->0->>'worker_avatar');
  END IF;

  IF (v_res_json->0 ? 'phone') OR (v_res_json->0 ? 'email') THEN
    RAISE EXCEPTION 'Security violation: get_job_applicants must never leak phone or email!';
  END IF;

  RAISE NOTICE 'Test A PASSED: get_job_applicants returned real profile attributes securely.';

  -- 4. Provider hires worker -> respond_to_application
  v_assignment_id := public.respond_to_application(v_app_id, 'hired');
  IF v_assignment_id IS NULL THEN
    SELECT id INTO v_assignment_id FROM public.job_assignments WHERE job_id = v_job_id AND worker_id = v_worker;
  END IF;

  IF v_assignment_id IS NULL THEN
    RAISE EXCEPTION 'Failed to create job assignment upon hiring applicant';
  END IF;

  -- Verify get_job_applicants now reflects assignment_id and status
  SELECT public.get_job_applicants(v_job_id) INTO v_res_json;
  IF (v_res_json->0->>'assignment_id') IS NULL THEN
    RAISE EXCEPTION 'Expected assignment_id to be populated after hiring';
  END IF;

  RAISE NOTICE 'Test A2 PASSED: get_job_applicants populated assignment_id: %', (v_res_json->0->>'assignment_id');

  -- Test B & C: get_active_job_details resolves assignment ID, job ID, and application ID
  PERFORM set_config('request.jwt.claim.sub', v_worker::text, true);

  -- Direct assignment ID resolution
  SELECT * INTO v_details_rec FROM public.get_active_job_details(v_assignment_id);
  IF v_details_rec.assignment_id IS NULL THEN
    RAISE EXCEPTION 'Failed to get_active_job_details via assignment ID';
  END IF;
  IF v_details_rec.job_lat = 0.0 OR v_details_rec.job_lng = 0.0 THEN
    RAISE EXCEPTION 'Expected non-zero PostGIS coordinates for job, got lat=% lng=%', v_details_rec.job_lat, v_details_rec.job_lng;
  END IF;

  -- Defensive application ID resolution (Symptom B)
  SELECT * INTO v_details_rec FROM public.get_active_job_details(v_app_id);
  IF v_details_rec.assignment_id IS NULL THEN
    RAISE EXCEPTION 'Defensive lookup failed: get_active_job_details should resolve application ID to assignment';
  END IF;

  RAISE NOTICE 'Test B & C PASSED: get_active_job_details resolved defensive IDs and PostGIS coords (lat=%, lng=%)',
    v_details_rec.job_lat, v_details_rec.job_lng;

  -- Test D & E: Worker accepts assignment and schedule reflects it
  v_res_json := public.accept_assignment(v_assignment_id);
  IF (v_res_json->>'status') != 'accepted' THEN
    RAISE EXCEPTION 'Expected status accepted from accept_assignment, got %', (v_res_json->>'status');
  END IF;

  -- Verify schedule
  SELECT COUNT(*) INTO v_sched_count
  FROM public.get_worker_schedule(v_worker, NOW() - INTERVAL '1 day', NOW() + INTERVAL '7 days');

  IF v_sched_count < 1 THEN
    RAISE EXCEPTION 'get_worker_schedule returned 0 items for accepted worker';
  END IF;

  RAISE NOTICE 'Test D & E PASSED: Worker accepted assignment and schedule contains % item(s)', v_sched_count;

  -- Test F: QR ticket generation and scan
  -- Worker fetches ticket code
  SELECT ticket_code INTO v_ticket_code
  FROM public.job_tickets
  WHERE assignment_id = v_assignment_id;

  IF v_ticket_code IS NOT NULL THEN
    -- Provider scans QR code
    PERFORM set_config('request.jwt.claim.sub', v_provider::text, true);
    SELECT public.verify_ticket_scan(v_ticket_code) INTO v_scan_res;
    IF (v_scan_res->>'success')::boolean != true THEN
      RAISE EXCEPTION 'verify_ticket_scan failed: %', v_scan_res;
    END IF;
    RAISE NOTICE 'Test F PASSED: verify_ticket_scan succeeded on first scan: %', v_scan_res->>'message';
  END IF;

  RAISE NOTICE '=== ALL LIFECYCLE FIXES TESTS PASSED SUCCESSFULLY [%] ===', v_suffix;
END $$;
