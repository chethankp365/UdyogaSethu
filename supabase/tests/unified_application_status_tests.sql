-- ============================================================================
-- Test Suite: unified_application_status_tests.sql
-- Description: Tests for migration 0680:
--              1. recommended_jobs returns caller's application status
--              2. Two-user isolation: User A applied, User B sees 'none'
--              3. Idempotent apply_to_job
--              4. withdraw_job_application transitions status
-- ============================================================================

DO $$
DECLARE
  v_user_a UUID;
  v_user_b UUID;
  v_provider UUID;
  v_job_id UUID;
  v_app_id_1 UUID;
  v_app_id_2 UUID;
  v_cat_id UUID;
  v_status_a TEXT;
  v_status_b TEXT;
  v_withdrawn BOOLEAN;
BEGIN
  -- 1. Create or obtain test users
  SELECT id INTO v_provider FROM public.profiles WHERE role = 'job_provider' LIMIT 1;
  IF v_provider IS NULL THEN
    v_provider := extensions.gen_random_uuid();
    INSERT INTO public.profiles (id, full_name, phone, role)
    VALUES (v_provider, 'Test Provider 0680', '+919900000991', 'job_provider');
  END IF;

  v_user_a := extensions.gen_random_uuid();
  INSERT INTO public.profiles (id, full_name, phone, role)
  VALUES (v_user_a, 'Worker A 0680', '+919900000992', 'job_seeker');
  INSERT INTO public.worker_profiles (user_id, seeker_type, is_verified_badge, has_driving_licence)
  VALUES (v_user_a, 'informal', true, true);

  v_user_b := extensions.gen_random_uuid();
  INSERT INTO public.profiles (id, full_name, phone, role)
  VALUES (v_user_b, 'Worker B 0680', '+919900000993', 'job_seeker');
  INSERT INTO public.worker_profiles (user_id, seeker_type, is_verified_badge, has_driving_licence)
  VALUES (v_user_b, 'informal', true, true);

  SELECT id INTO v_cat_id FROM public.service_categories LIMIT 1;

  -- 2. Create test job
  INSERT INTO public.jobs (
    provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, start_at, location, address_text, suitable_for
  ) VALUES (
    v_provider, v_cat_id, 'Test Unified Status Job', 'Status test description', 'daily', 80000,
    3, 0, 'open', NOW() + INTERVAL '2 days',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6245, 12.9352), 4326)::extensions.geography,
    'Koramangala, Bengaluru', ARRAY['informal'::public.seeker_type, 'student'::public.seeker_type]
  ) RETURNING id INTO v_job_id;

  -- 3. Prior to applying: User A and User B both see 'none'
  SELECT my_application_status INTO v_status_a
  FROM public.recommended_jobs(v_user_a, 12.9352, 77.6245, 10, 50000)
  WHERE id = v_job_id;
  ASSERT v_status_a = 'none', 'Expected User A status none before applying, got: ' || COALESCE(v_status_a, 'NULL');

  -- 4. User A applies to job (Simulate auth.uid() as User A)
  -- Since apply_to_job checks auth.uid(), we temporarily set request.jwt.claim.sub
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  v_app_id_1 := public.apply_to_job(v_job_id, 'Worker A applying');
  ASSERT v_app_id_1 IS NOT NULL, 'Failed to insert application for User A';

  -- 5. Test idempotency: User A applies again -> must return v_app_id_1
  v_app_id_2 := public.apply_to_job(v_job_id, 'Worker A applying second time');
  ASSERT v_app_id_1 = v_app_id_2, 'apply_to_job was not idempotent: returned different ID';

  -- 6. Check recommended_jobs status for User A
  SELECT my_application_status INTO v_status_a
  FROM public.recommended_jobs(v_user_a, 12.9352, 77.6245, 10, 50000)
  WHERE id = v_job_id;
  ASSERT v_status_a = 'applied', 'Expected User A status applied, got: ' || COALESCE(v_status_a, 'NULL');

  -- 7. Two-user isolation: User B checks recommended_jobs
  PERFORM set_config('request.jwt.claim.sub', v_user_b::text, true);
  SELECT my_application_status INTO v_status_b
  FROM public.recommended_jobs(v_user_b, 12.9352, 77.6245, 10, 50000)
  WHERE id = v_job_id;
  ASSERT v_status_b = 'none', 'User B saw User A status! Expected none, got: ' || COALESCE(v_status_b, 'NULL');

  -- 8. User A withdraws application
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  v_withdrawn := public.withdraw_job_application(v_job_id);
  ASSERT v_withdrawn = true, 'withdraw_job_application failed to return true';

  -- User A now sees 'withdrawn'
  SELECT my_application_status INTO v_status_a
  FROM public.recommended_jobs(v_user_a, 12.9352, 77.6245, 10, 50000)
  WHERE id = v_job_id;
  ASSERT v_status_a = 'withdrawn', 'Expected User A status withdrawn, got: ' || COALESCE(v_status_a, 'NULL');

  -- 9. Clean up test records
  DELETE FROM public.job_applications WHERE job_id = v_job_id;
  DELETE FROM public.jobs WHERE id = v_job_id;
  DELETE FROM public.worker_profiles WHERE user_id IN (v_user_a, v_user_b);
  DELETE FROM public.profiles WHERE id IN (v_user_a, v_user_b);

  RAISE NOTICE 'SUCCESS: unified_application_status_tests passed cleanly!';
END $$;
