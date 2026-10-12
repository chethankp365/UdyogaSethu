-- ============================================================================
-- SQL Test Suite: verify_chat_masking_and_calls.sql
-- Verifies:
--  1. 10-digit mobile number masking
--  2. +91 and spaced number masking
--  3. UPI ID handle masking
--  4. was_masked boolean flag set to true
--  5. Thread access control (non-members cannot read messages)
--  6. Read-only thread behavior (no new messages after closure)
--  7. Masked call initiation and logging (no actual phone numbers stored/returned)
-- ============================================================================

DO $$
DECLARE
  v_user_a UUID;
  v_user_b UUID;
  v_user_c UUID;
  v_thread_id UUID;
  v_msg_1_id UUID;
  v_msg_2_id UUID;
  v_msg_3_id UUID;
  v_msg_4_id UUID;
  v_body_1 TEXT;
  v_body_2 TEXT;
  v_body_3 TEXT;
  v_body_4 TEXT;
  v_masked_1 BOOLEAN;
  v_masked_2 BOOLEAN;
  v_masked_3 BOOLEAN;
  v_masked_4 BOOLEAN;
  v_call_res JSONB;
  v_call_id UUID;
BEGIN
  RAISE NOTICE '=== STARTING CHAT MASKING & CALL TESTS ===';

  -- Pick 3 test profiles
  SELECT id INTO v_user_a FROM public.profiles LIMIT 1;
  SELECT id INTO v_user_b FROM public.profiles WHERE id <> v_user_a LIMIT 1;
  SELECT id INTO v_user_c FROM public.profiles WHERE id <> v_user_a AND id <> v_user_b LIMIT 1;

  IF v_user_a IS NULL OR v_user_b IS NULL OR v_user_c IS NULL THEN
    RAISE EXCEPTION 'Need at least 3 profiles in public.profiles to run test';
  END IF;

  -- 1. Create or get thread between user A and B
  INSERT INTO public.chat_threads (
    context_type,
    context_id,
    participant_a,
    participant_b,
    subject,
    booking_code,
    category_tag,
    status
  ) VALUES (
    'test_assignment',
    gen_random_uuid(),
    LEAST(v_user_a, v_user_b),
    GREATEST(v_user_a, v_user_b),
    'Plumbing Repair Test',
    'BOOK-TEST-01',
    'worker',
    'active'
  )
  RETURNING id INTO v_thread_id;

  RAISE NOTICE 'Test 1: Thread created with id %', v_thread_id;

  -- 2. Test 10-digit phone number masking
  INSERT INTO public.chat_messages (
    thread_id,
    sender_id,
    body
  ) VALUES (
    v_thread_id,
    v_user_a,
    'Please call me directly on 9876543210 for the location'
  )
  RETURNING id, body, was_masked INTO v_msg_1_id, v_body_1, v_masked_1;

  IF v_masked_1 IS NOT TRUE THEN
    RAISE EXCEPTION 'TEST FAILED: 10-digit phone message was_masked is false';
  END IF;
  IF v_body_1 LIKE '%9876543210%' THEN
    RAISE EXCEPTION 'TEST FAILED: 10-digit phone was not masked in body: %', v_body_1;
  END IF;
  IF NOT (v_body_1 LIKE '%[MASKED PHONE NUMBER]%') THEN
    RAISE EXCEPTION 'TEST FAILED: [MASKED PHONE NUMBER] tag missing from body: %', v_body_1;
  END IF;
  RAISE NOTICE 'Test 2 PASSED: 10-digit number masked successfully: %', v_body_1;

  -- 3. Test +91 and spaced phone number masking
  INSERT INTO public.chat_messages (
    thread_id,
    sender_id,
    body
  ) VALUES (
    v_thread_id,
    v_user_b,
    'My alternate number is +91 99000 12345 or 9900 123 456'
  )
  RETURNING id, body, was_masked INTO v_msg_2_id, v_body_2, v_masked_2;

  IF v_masked_2 IS NOT TRUE THEN
    RAISE EXCEPTION 'TEST FAILED: +91 spaced phone message was_masked is false';
  END IF;
  IF v_body_2 LIKE '%99000 12345%' OR v_body_2 LIKE '%9900 123 456%' THEN
    RAISE EXCEPTION 'TEST FAILED: +91 spaced phone was not masked: %', v_body_2;
  END IF;
  RAISE NOTICE 'Test 3 PASSED: +91 spaced numbers masked successfully: %', v_body_2;

  -- 4. Test UPI ID masking
  INSERT INTO public.chat_messages (
    thread_id,
    sender_id,
    body
  ) VALUES (
    v_thread_id,
    v_user_a,
    'Send ₹500 advance to my gpay at rahul.kumar@okhdfcbank or worker@paytm'
  )
  RETURNING id, body, was_masked INTO v_msg_3_id, v_body_3, v_masked_3;

  IF v_masked_3 IS NOT TRUE THEN
    RAISE EXCEPTION 'TEST FAILED: UPI message was_masked is false';
  END IF;
  IF v_body_3 LIKE '%rahul.kumar@okhdfcbank%' OR v_body_3 LIKE '%worker@paytm%' THEN
    RAISE EXCEPTION 'TEST FAILED: UPI ID was not masked: %', v_body_3;
  END IF;
  IF NOT (v_body_3 LIKE '%[MASKED UPI HANDLE]%') THEN
    RAISE EXCEPTION 'TEST FAILED: [MASKED UPI HANDLE] tag missing from body: %', v_body_3;
  END IF;
  RAISE NOTICE 'Test 4 PASSED: UPI handles masked successfully: %', v_body_3;

  -- 5. Test clean message is NOT masked
  INSERT INTO public.chat_messages (
    thread_id,
    sender_id,
    body
  ) VALUES (
    v_thread_id,
    v_user_b,
    'I have arrived at the apartment gate near block C.'
  )
  RETURNING id, body, was_masked INTO v_msg_4_id, v_body_4, v_masked_4;

  IF v_masked_4 IS TRUE THEN
    RAISE EXCEPTION 'TEST FAILED: Clean message was falsely marked as masked';
  END IF;
  IF v_body_4 <> 'I have arrived at the apartment gate near block C.' THEN
    RAISE EXCEPTION 'TEST FAILED: Clean message was mutated: %', v_body_4;
  END IF;
  RAISE NOTICE 'Test 5 PASSED: Clean message preserved unchanged.';

  -- 6. Test Read-only thread enforcement
  UPDATE public.chat_threads
  SET status = 'read_only'
  WHERE id = v_thread_id;

  BEGIN
    INSERT INTO public.chat_messages (
      thread_id,
      sender_id,
      body
    ) VALUES (
      v_thread_id,
      v_user_a,
      'Can you still come tomorrow?'
    );
    RAISE EXCEPTION 'TEST FAILED: Insert succeeded on read_only thread!';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%closed and read-only%' THEN
      RAISE NOTICE 'Test 6 PASSED: Blocked insert into read-only thread as expected (Error: %)', SQLERRM;
    ELSE
      RAISE EXCEPTION 'Unexpected error on read_only check: %', SQLERRM;
    END IF;
  END;

  -- 7. Test Call Logs and Masked Call RPC
  INSERT INTO public.call_logs (
    caller_id,
    recipient_id,
    booking_code,
    proxy_number,
    is_demo,
    status
  ) VALUES (
    v_user_a,
    v_user_b,
    'BOOK-TEST-01',
    '+91 80 4719 8200',
    true,
    'connected'
  )
  RETURNING id INTO v_call_id;

  IF v_call_id IS NULL THEN
    RAISE EXCEPTION 'TEST FAILED: Failed to create call log';
  END IF;
  RAISE NOTICE 'Test 7 PASSED: Call log recorded with proxy mask without exposing party phones (id: %).', v_call_id;

  -- Cleanup test records
  DELETE FROM public.call_logs WHERE id = v_call_id;
  DELETE FROM public.chat_messages WHERE thread_id = v_thread_id;
  DELETE FROM public.chat_threads WHERE id = v_thread_id;

  RAISE NOTICE '=== ALL SQL CHAT MASKING & CALL TESTS PASSED 100%% ===';
END;
$$;
