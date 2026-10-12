-- ============================================================================
-- SQL Test Suite: security_audit_tests.sql
-- Step P10.3: Regression Tests for Security & Authorization Audit
-- ============================================================================

DO $$
DECLARE
  v_user_a UUID := '11111111-1111-1111-1111-111111111111';
  v_user_b UUID := '22222222-2222-2222-2222-222222222222';
  v_admin  UUID := '99999999-9999-9999-9999-999999999999';
  v_job_id UUID;
  v_assignment_id UUID;
  v_order_id UUID;
  v_count INT;
  v_err_caught BOOLEAN;
BEGIN
  -- 0. Set up initial test fixtures using superuser / postgres role
  PERFORM set_config('role', 'postgres', true);

  -- Users
  INSERT INTO auth.users (id, email, aud, role) VALUES
    (v_user_a, 'sec_user_a@test.com', 'authenticated', 'authenticated'),
    (v_user_b, 'sec_user_b@test.com', 'authenticated', 'authenticated'),
    (v_admin,  'sec_admin@test.com',  'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  -- Profiles
  INSERT INTO public.profiles (id, full_name, email, active_role) VALUES
    (v_user_a, 'Sec User A', 'sec_user_a@test.com', 'seeker'),
    (v_user_b, 'Sec User B', 'sec_user_b@test.com', 'provider'),
    (v_admin,  'Sec Admin',  'sec_admin@test.com',  'admin')
  ON CONFLICT (id) DO NOTHING;

  -- Roles
  INSERT INTO public.user_roles (user_id, role, is_primary) VALUES
    (v_user_a, 'seeker', true),
    (v_user_b, 'provider', true),
    (v_admin,  'admin', true)
  ON CONFLICT (user_id, role) DO NOTHING;

  -- Test Job posted by User B
  INSERT INTO public.jobs (id, provider_id, title, category_id, agreed_wage_paise, status)
  VALUES (gen_random_uuid(), v_user_b, 'Security Audit Job', (SELECT id FROM public.service_categories LIMIT 1), 50000, 'open')
  RETURNING id INTO v_job_id;

  -- Test Assignment for User A
  INSERT INTO public.job_assignments (id, job_id, worker_id, agreed_wage_paise, status)
  VALUES (gen_random_uuid(), v_job_id, v_user_a, 50000, 'accepted')
  RETURNING id INTO v_assignment_id;

  -- Test Order by User A from User B
  INSERT INTO public.orders (id, order_code, customer_id, farmer_id, total_paise, fee_paise, status)
  VALUES (gen_random_uuid(), 'SEC-ORD-001', v_user_a, v_user_b, 10000, 500, 'pending')
  RETURNING id INTO v_order_id;

  -- Test Emergency contact for User B
  INSERT INTO public.emergency_contacts (user_id, name, phone, relationship)
  VALUES (v_user_b, 'B Contact', '+919900000999', 'Family')
  ON CONFLICT DO NOTHING;

  -- Test Wallet for User B
  INSERT INTO public.wallets (user_id) VALUES (v_user_b)
  ON CONFLICT (user_id) DO NOTHING;

  -- =========================================================================
  -- TEST 1: ANON ROLE CANNOT ACCESS RESTRICTED TABLES
  -- =========================================================================
  PERFORM set_config('role', 'anon', true);
  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('request.jwt.claim.role', 'anon', true);

  -- Anon reading demo_users
  SELECT COUNT(*) INTO v_count FROM public.demo_users;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 1 FAILED: Anon was able to read demo_users table!';
  END IF;

  -- Anon reading emergency_contacts
  SELECT COUNT(*) INTO v_count FROM public.emergency_contacts;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 1 FAILED: Anon was able to read emergency_contacts!';
  END IF;

  -- =========================================================================
  -- TEST 2: USER A CANNOT READ USER B'S PRIVATE DATA
  -- =========================================================================
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  -- User A reading User B's emergency contacts
  SELECT COUNT(*) INTO v_count FROM public.emergency_contacts WHERE user_id = v_user_b;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 2 FAILED: User A read User B emergency contacts!';
  END IF;

  -- User A reading User B's wallet
  SELECT COUNT(*) INTO v_count FROM public.wallets WHERE user_id = v_user_b;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'TEST 2 FAILED: User A read User B wallet!';
  END IF;

  -- =========================================================================
  -- TEST 3: CLIENT CANNOT MODIFY IMMUTABLE FIELDS ON JOB ASSIGNMENTS
  -- =========================================================================
  v_err_caught := false;
  BEGIN
    UPDATE public.job_assignments
    SET agreed_wage_paise = 9999999
    WHERE id = v_assignment_id;
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST 3 FAILED: Client was able to modify assignment agreed_wage_paise directly!';
  END IF;

  -- =========================================================================
  -- TEST 4: CLIENT CANNOT TAMPER WITH ORDER TOTAL PAISE
  -- =========================================================================
  v_err_caught := false;
  BEGIN
    UPDATE public.orders
    SET total_paise = 0
    WHERE id = v_order_id;
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST 4 FAILED: Client was able to modify order total_paise directly!';
  END IF;

  -- =========================================================================
  -- TEST 5: CLIENT CANNOT INSERT PRE-RELEASED / VERIFIED PAYMENT DIRECTLY
  -- =========================================================================
  v_err_caught := false;
  BEGIN
    INSERT INTO public.payments (
      payer_id, payee_id, ref_type, ref_id, amount_paise, receipt_no, status, signature_verified
    ) VALUES (
      v_user_a, v_user_b, 'assignment', v_assignment_id, 50000, 'SEC-REC-FAKE-01', 'released', true
    );
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST 5 FAILED: Client was able to inject pre-released payment!';
  END IF;

  -- =========================================================================
  -- TEST 6: CLIENT CANNOT INSERT PROCESSED PAYOUT DIRECTLY
  -- =========================================================================
  v_err_caught := false;
  BEGIN
    INSERT INTO public.payouts (
      user_id, amount_paise, status
    ) VALUES (
      v_user_a, 50000, 'processed'
    );
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST 6 FAILED: Client was able to inject processed payout!';
  END IF;

  -- =========================================================================
  -- TEST 7: CLIENT CANNOT SELF-RATE
  -- =========================================================================
  v_err_caught := false;
  BEGIN
    INSERT INTO public.ratings_reviews (
      rater_id, target_id, rating, review_text
    ) VALUES (
      v_user_a, v_user_a, 5, 'Self praise review'
    );
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST 7 FAILED: Client was able to submit self-rating!';
  END IF;

  -- Cleanup test records
  PERFORM set_config('role', 'postgres', true);
  DELETE FROM public.job_assignments WHERE id = v_assignment_id;
  DELETE FROM public.jobs WHERE id = v_job_id;
  DELETE FROM public.orders WHERE id = v_order_id;
  DELETE FROM public.emergency_contacts WHERE user_id = v_user_b;

  RAISE NOTICE 'SUCCESS: All 7 security audit regression tests passed cleanly!';
END $$;
