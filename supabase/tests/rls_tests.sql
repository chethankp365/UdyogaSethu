-- SQL Test Suite: rls_tests.sql
-- Tests Row Level Security (RLS) enforcement and guard triggers.
-- Impersonates anon, User A, User B, and Admin to assert security bounds.

DO $$
DECLARE
  v_user_a UUID := '11111111-1111-1111-1111-111111111111';
  v_user_b UUID := '22222222-2222-2222-2222-222222222222';
  v_admin  UUID := '99999999-9999-9999-9999-999999999999';
  v_wallet_b UUID;
  v_thread_a_b UUID;
  v_count INT;
  v_err_caught BOOLEAN := false;
BEGIN
  -- Setup test data using direct postgres permissions
  INSERT INTO auth.users (id, email, instance_id, aud, role) VALUES
    (v_user_a, 'user_a@test.com', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_user_b, 'user_b@test.com', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_admin,  'admin@test.com',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.profiles (id, full_name, email, active_role) VALUES
    (v_user_a, 'User A', 'user_a@test.com', 'seeker'),
    (v_user_b, 'User B', 'user_b@test.com', 'provider'),
    (v_admin,  'Admin User', 'admin@test.com', 'admin')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_roles (user_id, role, is_primary) VALUES
    (v_user_a, 'seeker', true),
    (v_user_b, 'provider', true),
    (v_admin,  'admin', true)
  ON CONFLICT (user_id, role) DO NOTHING;

  -- Create worker profile for A
  INSERT INTO public.worker_profiles (user_id, rating_avg) VALUES (v_user_a, 4.50)
  ON CONFLICT (user_id) DO NOTHING;

  -- Create KYC record for B
  INSERT INTO public.kyc_records (user_id, doc_type, masked_id, status)
  VALUES (v_user_b, 'aadhaar', '1234', 'verified')
  ON CONFLICT DO NOTHING;

  -- Create Wallet for B
  INSERT INTO public.wallets (user_id) VALUES (v_user_b)
  ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
  RETURNING id INTO v_wallet_b;

  -- Create Chat Thread between A and B
  INSERT INTO public.chat_threads (id, context_type, context_id, participant_a, participant_b)
  VALUES (gen_random_uuid(), 'direct', gen_random_uuid(), v_user_a, v_user_b)
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_thread_a_b;

  IF v_thread_a_b IS NULL THEN
    SELECT id INTO v_thread_a_b FROM public.chat_threads
    WHERE participant_a = v_user_a AND participant_b = v_user_b LIMIT 1;
  END IF;

  INSERT INTO public.chat_messages (thread_id, sender_id, body)
  VALUES (v_thread_a_b, v_user_a, 'Hello from A to B')
  ON CONFLICT DO NOTHING;

  -- =========================================================================
  -- TEST 1: ANON ROLE READ RESTRICTIONS
  -- =========================================================================
  PERFORM set_config('role', 'anon', true);
  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('request.jwt.claim.role', 'anon', true);

  SELECT COUNT(*) INTO v_count FROM public.kyc_records;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 1 FAILED: Anon user was able to read kyc_records!';
  END IF;

  SELECT COUNT(*) INTO v_count FROM public.wallets;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 1 FAILED: Anon user was able to read wallets!';
  END IF;

  SELECT COUNT(*) INTO v_count FROM public.chat_messages;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 1 FAILED: Anon user was able to read chat_messages!';
  END IF;

  -- =========================================================================
  -- TEST 2: USER A CANNOT READ USER B's KYC OR WALLET
  -- =========================================================================
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  SELECT COUNT(*) INTO v_count FROM public.kyc_records WHERE user_id = v_user_b;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 2 FAILED: User A was able to read User B KYC record!';
  END IF;

  SELECT COUNT(*) INTO v_count FROM public.wallets WHERE user_id = v_user_b;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 2 FAILED: User A was able to read User B wallet!';
  END IF;

  -- =========================================================================
  -- TEST 3: USER A CANNOT UPDATE WORKER_PROFILES.RATING_AVG (COMPUTED GUARD)
  -- =========================================================================
  v_err_caught := false;
  BEGIN
    UPDATE public.worker_profiles SET rating_avg = 5.00 WHERE user_id = v_user_a;
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST 3 FAILED: User A was able to mutate rating_avg on worker_profiles!';
  END IF;

  -- =========================================================================
  -- TEST 4: NON-ADMIN CANNOT READ ADMIN SETTINGS
  -- =========================================================================
  SELECT COUNT(*) INTO v_count FROM public.admin_settings;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 4 FAILED: User A was able to read admin_settings!';
  END IF;

  -- =========================================================================
  -- TEST 5: ADMIN IMPERSONATION CAN READ ADMIN SETTINGS & KYC RECORDS
  -- =========================================================================
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claim.sub', v_admin::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  SELECT COUNT(*) INTO v_count FROM public.admin_settings;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'TEST 5 FAILED: Admin user could NOT read admin_settings!';
  END IF;

  SELECT COUNT(*) INTO v_count FROM public.kyc_records WHERE user_id = v_user_b;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'TEST 5 FAILED: Admin user could NOT read User B KYC record!';
  END IF;

  -- Clean up test records
  PERFORM set_config('role', 'postgres', true);
  DELETE FROM public.chat_messages WHERE thread_id = v_thread_a_b;
  DELETE FROM public.chat_threads WHERE id = v_thread_a_b;
  DELETE FROM public.wallets WHERE id = v_wallet_b;
  DELETE FROM public.kyc_records WHERE user_id = v_user_b;
  DELETE FROM public.worker_profiles WHERE user_id = v_user_a;
  DELETE FROM public.user_roles WHERE user_id IN (v_user_a, v_user_b, v_admin);
  DELETE FROM public.profiles WHERE id IN (v_user_a, v_user_b, v_admin);
  DELETE FROM auth.users WHERE id IN (v_user_a, v_user_b, v_admin);

  RAISE NOTICE 'ALL RLS SECURITY TESTS PASSED CLEANLY!';
END $$;
