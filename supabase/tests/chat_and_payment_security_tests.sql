-- ============================================================================
-- SQL Test Suite: chat_and_payment_security_tests.sql
-- Step Verification: Chat Participant Authorization, Blocking & Payment Security
-- ============================================================================

DO $$
DECLARE
  v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  v_user_b UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  v_user_c UUID := 'cccccccc-cccc-cccc-cccc-cccccccccccc'; -- Unrelated 3rd party
  v_conv_id UUID;
  v_job_id UUID;
  v_err_caught BOOLEAN;
  v_res JSONB;
BEGIN
  -- 0. Set up initial test fixtures
  PERFORM set_config('role', 'postgres', true);

  -- Users
  INSERT INTO auth.users (id, email, aud, role) VALUES
    (v_user_a, 'chat_user_a@test.com', 'authenticated', 'authenticated'),
    (v_user_b, 'chat_user_b@test.com', 'authenticated', 'authenticated'),
    (v_user_c, 'chat_user_c@test.com', 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  -- Profiles
  INSERT INTO public.profiles (id, full_name, email, active_role) VALUES
    (v_user_a, 'Chat User A', 'chat_user_a@test.com', 'seeker'),
    (v_user_b, 'Chat User B', 'chat_user_b@test.com', 'provider'),
    (v_user_c, 'Chat User C', 'chat_user_c@test.com', 'seeker')
  ON CONFLICT (id) DO NOTHING;

  -- 1. Test Self-Conversation Prevention
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a::text)::text, true);
  PERFORM set_config('role', 'authenticated', true);

  v_err_caught := false;
  BEGIN
    PERFORM public.get_or_create_conversation(v_user_a);
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST FAILED: Starting a conversation with oneself must throw an exception.';
  END IF;

  -- 2. Test Block / Unblock Security
  -- User A blocks User B
  v_res := public.block_user(v_user_b);
  IF (v_res->>'success')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'TEST FAILED: block_user failed for User A -> User B.';
  END IF;

  -- Verify conversation creation between A and B is rejected while blocked
  v_err_caught := false;
  BEGIN
    PERFORM public.get_or_create_conversation(v_user_b);
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST FAILED: Conversation creation must fail when counterpart is blocked.';
  END IF;

  -- User A unblocks User B
  v_res := public.unblock_user(v_user_b);
  IF (v_res->>'success')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'TEST FAILED: unblock_user failed for User A -> User B.';
  END IF;

  -- 3. Test Reporting
  v_res := public.report_chat_user(v_user_b, NULL, 'harassment', 'Offensive language used');
  IF (v_res->>'success')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'TEST FAILED: report_chat_user failed.';
  END IF;

  -- 4. Test Payment Capture Authorization Revocation
  -- Attempt to invoke record_payment_success as authenticated user (Must fail permission check)
  v_err_caught := false;
  BEGIN
    PERFORM public.record_payment_success(gen_random_uuid(), 'pay_fake_capture_id', '{"method":"upi"}'::jsonb);
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST FAILED: record_payment_success must not be callable by authenticated users.';
  END IF;

  -- Clean up
  PERFORM set_config('role', 'postgres', true);
  DELETE FROM public.chat_reports WHERE reporter_id = v_user_a;
  DELETE FROM public.chat_blocks WHERE blocker_id = v_user_a;

  RAISE NOTICE 'SUCCESS: All chat authorization, blocking, and payment security tests passed.';
END $$;
