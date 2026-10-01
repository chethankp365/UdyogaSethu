-- SQL Test Suite: functions_tests.sql
-- Tests job state machine transitions, double-booking rejection, escrow operations,
-- idempotency, refund path, and ledger immutability invariants.

DO $$
DECLARE
  v_provider UUID := gen_random_uuid();
  v_worker   UUID := gen_random_uuid();
  v_job1     UUID;
  v_job2     UUID;
  v_assign1  UUID;
  v_assign2  UUID;
  v_payment1 UUID;
  v_payment2 UUID;
  v_payer_wallet UUID;
  v_payee_wallet UUID;
  v_err_caught BOOLEAN := false;
  v_balance_before BIGINT;
  v_balance_after BIGINT;
  v_suffix TEXT := SUBSTRING(gen_random_uuid()::text, 1, 8);
BEGIN
  -- Setup test auth users and profiles using postgres admin context
  INSERT INTO auth.users (id, email, instance_id, aud, role) VALUES
    (v_provider, 'provider_fn_' || v_suffix || '@test.com', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_worker,   'worker_fn_'   || v_suffix || '@test.com', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.profiles (id, full_name, email, active_role) VALUES
    (v_provider, 'Provider Fn', 'provider_fn_' || v_suffix || '@test.com', 'provider'),
    (v_worker,   'Worker Fn',   'worker_fn_'   || v_suffix || '@test.com', 'seeker')
  ON CONFLICT (id) DO UPDATE SET active_role = EXCLUDED.active_role;

  INSERT INTO public.worker_profiles (user_id, availability) VALUES (v_worker, 'available')
  ON CONFLICT (user_id) DO NOTHING;

  -- Setup Wallets for provider and worker
  INSERT INTO public.wallets (user_id) VALUES (v_provider)
  ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
  RETURNING id INTO v_payer_wallet;

  INSERT INTO public.wallets (user_id) VALUES (v_worker)
  ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
  RETURNING id INTO v_payee_wallet;

  -- =========================================================================
  -- TEST 1: LEGAL AND ILLEGAL STATE MACHINE TRANSITIONS
  -- =========================================================================
  INSERT INTO public.jobs (provider_id, title, wage_type, wage_paise, start_at, est_duration_minutes, slots_total, slots_filled, status)
  VALUES (v_provider, 'Test Job 1', 'daily', 100000, NOW() + INTERVAL '1 day', 480, 1, 1, 'filled')
  RETURNING id INTO v_job1;

  INSERT INTO public.job_assignments (job_id, worker_id, booking_code, agreed_wage_paise, status)
  VALUES (v_job1, v_worker, 'BOOK-' || v_suffix || '-1', 100000, 'requested')
  RETURNING id INTO v_assign1;

  -- Illegal transition test: requested -> completed directly MUST FAIL
  v_err_caught := false;
  BEGIN
    PERFORM public.assignment_transition(v_assign1, 'completed', v_provider);
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST 1 FAILED: Illegal state transition (requested -> completed) did not throw an error!';
  END IF;

  -- Legal transition test: requested -> accepted
  PERFORM public.assignment_transition(v_assign1, 'accepted', v_worker);

  -- =========================================================================
  -- TEST 2: DOUBLE-BOOKING REJECTION IN accept_assignment
  -- =========================================================================
  -- Create a second overlapping job at the exact same start time
  INSERT INTO public.jobs (provider_id, title, wage_type, wage_paise, start_at, est_duration_minutes, slots_total, slots_filled, status)
  VALUES (v_provider, 'Overlapping Job 2', 'daily', 100000, NOW() + INTERVAL '1 day', 480, 1, 1, 'filled')
  RETURNING id INTO v_job2;

  INSERT INTO public.job_assignments (job_id, worker_id, booking_code, agreed_wage_paise, status)
  VALUES (v_job2, v_worker, 'BOOK-' || v_suffix || '-2', 100000, 'requested')
  RETURNING id INTO v_assign2;

  -- Impersonate worker using set_config
  PERFORM set_config('request.jwt.claim.sub', v_worker::text, false);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', false);

  v_err_caught := false;
  BEGIN
    PERFORM public.accept_assignment(v_assign2);
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  -- Impersonate provider for payment & escrow operations
  PERFORM set_config('request.jwt.claim.sub', v_provider::text, false);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', false);

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST 2 FAILED: accept_assignment allowed double-booking for overlapping job slots!';
  END IF;

  -- =========================================================================
  -- TEST 3: ESCROW HOLD, RELEASE AND IDEMPOTENCY
  -- =========================================================================
  -- 1. Fund provider wallet available bucket with 200,000 paise (Rs 2,000)
  PERFORM public.wallet_credit(v_provider, 200000, 'available', 'test_seed', gen_random_uuid(), 'seed-provider-' || v_suffix);

  -- Create Payment record
  INSERT INTO public.payments (payer_id, payee_id, ref_type, ref_id, amount_paise, receipt_no, status)
  VALUES (v_provider, v_worker, 'assignment', v_assign1, 100000, 'REC-' || v_suffix || '-1', 'created')
  RETURNING id INTO v_payment1;

  -- Hold Escrow
  PERFORM public.hold_escrow(v_payment1);

  -- Verify payer escrow balance is 100,000 paise
  SELECT escrow_paise INTO v_balance_before FROM public.wallet_balances WHERE user_id = v_provider;
  IF v_balance_before < 100000 THEN
    RAISE EXCEPTION 'TEST 3 FAILED: Escrow hold failed to populate escrow bucket! Balance: %', v_balance_before;
  END IF;

  -- Release Escrow (Platform fee 5% = 5,000 paise, Payee receives 95,000 paise)
  PERFORM public.release_escrow(v_payment1);

  SELECT available_paise INTO v_balance_after FROM public.wallet_balances WHERE user_id = v_worker;
  IF v_balance_after != 95000 THEN
    RAISE EXCEPTION 'TEST 3 FAILED: Payee available balance incorrect after release! Expected 95000, got: %', v_balance_after;
  END IF;

  -- Idempotency Test: Calling release_escrow AGAIN with same payment_id must do nothing extra
  PERFORM public.release_escrow(v_payment1);

  SELECT available_paise INTO v_balance_after FROM public.wallet_balances WHERE user_id = v_worker;
  IF v_balance_after != 95000 THEN
    RAISE EXCEPTION 'TEST 3 FAILED: Duplicate release_escrow altered balance! Expected 95000, got: %', v_balance_after;
  END IF;

  -- =========================================================================
  -- TEST 4: REFUND PATH
  -- =========================================================================
  -- Create another payment, hold escrow, and refund
  INSERT INTO public.payments (payer_id, payee_id, ref_type, ref_id, amount_paise, receipt_no, status)
  VALUES (v_provider, v_worker, 'assignment', v_assign2, 50000, 'REC-' || v_suffix || '-2', 'created')
  RETURNING id INTO v_payment2;

  PERFORM public.hold_escrow(v_payment2);

  -- Balance before refund
  SELECT available_paise INTO v_balance_before FROM public.wallet_balances WHERE user_id = v_provider;

  PERFORM public.refund_escrow(v_payment2, 50000);

  -- Balance after refund should have +50000 returned to available
  SELECT available_paise INTO v_balance_after FROM public.wallet_balances WHERE user_id = v_provider;
  IF v_balance_after != v_balance_before + 50000 THEN
    RAISE EXCEPTION 'TEST 4 FAILED: Refund did not return funds to available bucket! Before: %, After: %', v_balance_before, v_balance_after;
  END IF;

  -- Idempotency Test: Calling refund_escrow AGAIN with same payment_id must do nothing extra
  PERFORM public.refund_escrow(v_payment2, 50000);

  SELECT available_paise INTO v_balance_after FROM public.wallet_balances WHERE user_id = v_provider;
  IF v_balance_after != v_balance_before + 50000 THEN
    RAISE EXCEPTION 'TEST 4 FAILED: Duplicate refund_escrow altered balance!';
  END IF;

  -- =========================================================================
  -- TEST 5: LEDGER IMMUTABILITY INVARIANT
  -- =========================================================================
  v_err_caught := false;
  BEGIN
    UPDATE public.ledger_entries SET note = 'tampered' WHERE wallet_id = v_payer_wallet;
  EXCEPTION WHEN OTHERS THEN
    v_err_caught := true;
  END;

  IF NOT v_err_caught THEN
    RAISE EXCEPTION 'TEST 5 FAILED: Trigger failed to block UPDATE on ledger_entries!';
  END IF;

  RAISE NOTICE 'ALL FUNCTION & ESCROW TESTS PASSED CLEANLY!';
END $$;

SELECT 'PASSED ALL FUNCTION & ESCROW SECURITY TESTS CLEANLY' AS test_result;
