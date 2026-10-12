-- SQL Test Suite: verify_safety_and_notifications.sql (Steps P7.3 & P7.4)

DO $$
DECLARE
  v_test_user UUID;
  v_contact_res JSONB;
  v_contacts JSONB;
  v_claim_res JSONB;
  v_eligibility JSONB;
  v_job_id UUID;
  v_assignment_id UUID;
  v_unread_count INT;
  v_token_res JSONB;
BEGIN
  RAISE NOTICE '=== Running Safety, Claims & Notifications Verification ===';

  -- 1. Get or create test user
  SELECT id INTO v_test_user FROM public.profiles LIMIT 1;
  IF v_test_user IS NULL THEN
    RAISE EXCEPTION 'No profile found in test database';
  END IF;

  -- Set mock auth context for testing RPCs that call auth.uid()
  PERFORM set_config('request.jwt.claim.sub', v_test_user::TEXT, true);

  -- 2. Test Emergency Contacts CRUD
  -- Clean existing test contacts
  DELETE FROM public.emergency_contacts WHERE user_id = v_test_user;

  -- Insert contacts up to 5
  INSERT INTO public.emergency_contacts (user_id, name, phone, relation)
  VALUES
    (v_test_user, 'Ramesh Kumar (Brother)', '+919845011111', 'Family'),
    (v_test_user, 'Sunita Devi (Mother)', '+919845022222', 'Family'),
    (v_test_user, 'Anand Patel (Supervisor)', '+919845033333', 'Colleague');

  SELECT COUNT(*) INTO v_unread_count
  FROM public.emergency_contacts
  WHERE user_id = v_test_user;

  IF v_unread_count <> 3 THEN
    RAISE EXCEPTION 'Emergency contacts count mismatch: expected 3, got %', v_unread_count;
  END IF;
  RAISE NOTICE '[TEST 1 PASSED] Emergency contacts created: 3 contacts verified';

  -- 3. Test Claim Eligibility RPC
  -- Find an existing assignment or create mock
  SELECT id INTO v_assignment_id FROM public.job_assignments WHERE status IN ('in_progress_verified', 'completed') LIMIT 1;
  IF v_assignment_id IS NOT NULL THEN
    -- Evaluate eligibility
    SELECT public.check_claim_eligibility(v_assignment_id) INTO v_eligibility;
    RAISE NOTICE '[TEST 2 PASSED] Claim eligibility evaluated: %', v_eligibility;
  ELSE
    RAISE NOTICE '[TEST 2 SKIPPED] No completed assignment found for direct RPC evaluation';
  END IF;

  -- 4. Test Device Tokens Registration
  INSERT INTO public.device_tokens (user_id, token, platform, updated_at)
  VALUES (v_test_user, 'fcm_test_token_abc_123', 'android', NOW())
  ON CONFLICT (token) DO UPDATE SET updated_at = NOW();

  IF NOT EXISTS (SELECT 1 FROM public.device_tokens WHERE token = 'fcm_test_token_abc_123') THEN
    RAISE EXCEPTION 'Device token registration failed';
  END IF;
  RAISE NOTICE '[TEST 3 PASSED] Device token registered successfully';

  -- 5. Test Notification Row Trigger / In-App Notification
  INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
  VALUES (
    v_test_user,
    'test_notification',
    'notif_test_title',
    'notif_test_body',
    '{"test": true}'::jsonb
  );

  SELECT COUNT(*) INTO v_unread_count
  FROM public.notifications
  WHERE user_id = v_test_user AND read_at IS NULL;

  IF v_unread_count < 1 THEN
    RAISE EXCEPTION 'Notification insert verification failed';
  END IF;
  RAISE NOTICE '[TEST 4 PASSED] Notification row inserted and counted: % unread', v_unread_count;

  -- 6. Cleanup test records
  DELETE FROM public.device_tokens WHERE token = 'fcm_test_token_abc_123';
  DELETE FROM public.notifications WHERE user_id = v_test_user AND type = 'test_notification';

  RAISE NOTICE '=== All Safety and Notification SQL Tests PASSED! ===';
END;
$$;
