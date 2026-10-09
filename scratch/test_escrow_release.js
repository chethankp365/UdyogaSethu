const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function runDbQuery(sql) {
  const tmpFile = path.join(__dirname, 'temp_escrow_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5) + '.sql');
  fs.writeFileSync(tmpFile, sql, 'utf-8');
  try {
    const res = execSync(`npx supabase db query --linked -f "${tmpFile}"`, { encoding: 'utf-8' });
    try {
      return JSON.parse(res);
    } catch {
      return res;
    }
  } finally {
    if (fs.existsSync(tmpFile)) fs.unlinkSync(tmpFile);
  }
}

async function runTests() {
  console.log('=== Step P5.3 Escrow Release, Refunds & Dispute Freeze SQL Tests ===\n');

  const testSuiteSql = `
    DO $$
    DECLARE
      v_payer UUID;
      v_payee UUID;
      v_job_id UUID;
      v_asg1 UUID;
      v_p1 UUID;
      v_p2 UUID;
      v_p3 UUID;
      v_p4 UUID;
      v_p5 UUID;
      v_p_old UUID;
      v_p_new UUID;
      v_asg_old UUID;
      v_asg_new UUID;
      v_payer_wallet_id UUID;
      v_payee_wallet_id UUID;
      v_payer_avail BIGINT;
      v_payer_escrow BIGINT;
      v_payee_avail BIGINT;
      v_payee_before BIGINT;
      v_auto_res JSONB;
      v_dispute_caught BOOLEAN := false;
      v_gain BIGINT;
    BEGIN
      -- Setup test payer & payee profiles
      SELECT id INTO v_payer FROM public.profiles LIMIT 1;
      SELECT id INTO v_payee FROM public.profiles WHERE id <> v_payer LIMIT 1;

      IF v_payer IS NULL OR v_payee IS NULL THEN
        RAISE EXCEPTION 'Two distinct profiles required for test.';
      END IF;

      -- Ensure wallets exist
      INSERT INTO public.wallets (user_id) VALUES (v_payer), (v_payee) ON CONFLICT DO NOTHING;
      SELECT id INTO v_payer_wallet_id FROM public.wallets WHERE user_id = v_payer;
      SELECT id INTO v_payee_wallet_id FROM public.wallets WHERE user_id = v_payee;

      -- Give payer available funds
      PERFORM public.wallet_credit(
        v_payer, 1000000, 'available', 'payment', v_payer,
        'test-seed-' || gen_random_uuid(), 'Test seed credit'
      );

      -------------------------------------------------------------------------
      -- TEST 1: Hold Escrow, then Release Escrow (Net to worker minus 5% fee)
      -------------------------------------------------------------------------
      RAISE NOTICE '--- TEST 1: Hold then Release ---';
      INSERT INTO public.payments (
        payer_id, payee_id, ref_type, ref_id, amount_paise, platform_fee_paise,
        method, status, protected
      )
      VALUES (
        v_payer, v_payee, 'assignment', gen_random_uuid(), 70000, 0,
        'wallet', 'created', true
      )
      RETURNING id INTO v_p1;

      -- Hold escrow
      PERFORM public.hold_escrow(v_p1);

      SELECT available_paise, escrow_paise INTO v_payer_avail, v_payer_escrow
      FROM public.wallet_balances WHERE wallet_id = v_payer_wallet_id;
      RAISE NOTICE 'Payer Escrow after hold: % paise (Expected >= 70000)', v_payer_escrow;
      IF v_payer_escrow < 70000 THEN
        RAISE EXCEPTION 'Test 1 Failed: Escrow bucket not credited on hold.';
      END IF;

      SELECT available_paise INTO v_payee_before
      FROM public.wallet_balances WHERE wallet_id = v_payee_wallet_id;

      -- Release escrow
      PERFORM public.release_escrow(v_p1);

      SELECT available_paise INTO v_payee_avail
      FROM public.wallet_balances WHERE wallet_id = v_payee_wallet_id;

      -- 5% fee on 70,000 paise = 3,500 paise. Worker gain = 66,500 paise.
      v_gain := v_payee_avail - v_payee_before;
      RAISE NOTICE 'Worker gained: % paise (Expected 66500)', v_gain;
      IF v_gain <> 66500 THEN
        RAISE EXCEPTION 'Test 1 Failed: Worker received % paise instead of 66500.', v_gain;
      END IF;

      -------------------------------------------------------------------------
      -- TEST 2: Double Release Idempotency (same key / duplicate call)
      -------------------------------------------------------------------------
      RAISE NOTICE '--- TEST 2: Double Release Idempotency ---';
      PERFORM public.release_escrow(v_p1);

      SELECT available_paise INTO v_payee_avail
      FROM public.wallet_balances WHERE wallet_id = v_payee_wallet_id;
      IF (v_payee_avail - v_payee_before) <> 66500 THEN
        RAISE EXCEPTION 'Test 2 Failed: Double release double-credited worker!';
      END IF;
      RAISE NOTICE 'Test 2 PASSED: Idempotent repeat call did not double-credit.';

      -------------------------------------------------------------------------
      -- TEST 3: Partial Refund
      -------------------------------------------------------------------------
      RAISE NOTICE '--- TEST 3: Partial Refund ---';
      INSERT INTO public.payments (
        payer_id, payee_id, ref_type, ref_id, amount_paise, platform_fee_paise,
        method, status, protected
      )
      VALUES (
        v_payer, v_payee, 'assignment', gen_random_uuid(), 50000, 0,
        'wallet', 'created', true
      )
      RETURNING id INTO v_p2;

      PERFORM public.hold_escrow(v_p2);

      SELECT available_paise, escrow_paise INTO v_payer_avail, v_payer_escrow
      FROM public.wallet_balances WHERE wallet_id = v_payer_wallet_id;

      -- Refund partial ₹200 (20,000 paise)
      PERFORM public.refund_escrow(v_p2, 20000, 'Partial refund of cancellation');

      SELECT available_paise, escrow_paise INTO v_payer_avail, v_payer_escrow
      FROM public.wallet_balances WHERE wallet_id = v_payer_wallet_id;

      -- Check remaining amount in payment
      IF (SELECT amount_paise FROM public.payments WHERE id = v_p2) <> 30000 THEN
        RAISE EXCEPTION 'Test 3 Failed: Payment amount not reduced to 30000 after partial refund.';
      END IF;
      RAISE NOTICE 'Test 3 PASSED: Partial refund processed and 30000 paise retained in escrow.';

      -------------------------------------------------------------------------
      -- TEST 4: Release Blocked During Active Dispute
      -------------------------------------------------------------------------
      RAISE NOTICE '--- TEST 4: Dispute Freeze Invariant ---';
      INSERT INTO public.jobs (provider_id, title, description, wage_type, wage_paise, start_at)
      VALUES (v_payer, 'Dispute Test Job', 'Testing dispute freeze', 'daily', 60000, NOW() + INTERVAL '1 day')
      RETURNING id INTO v_job_id;

      INSERT INTO public.job_assignments (job_id, worker_id, booking_code, agreed_wage_paise, status, payment_eligible)
      VALUES (v_job_id, v_payee, 'BK-DISP-01', 60000, 'completed', true)
      RETURNING id INTO v_asg1;

      INSERT INTO public.payments (
        payer_id, payee_id, ref_type, ref_id, amount_paise, method, status, protected
      )
      VALUES (
        v_payer, v_payee, 'assignment', v_asg1, 60000, 'wallet', 'created', true
      )
      RETURNING id INTO v_p3;

      PERFORM public.hold_escrow(v_p3);

      -- Open dispute
      INSERT INTO public.disputes (
        ref_type, ref_id, raised_by, against, issue_type, details, status
      )
      VALUES (
        'job_assignment', v_asg1, v_payer, v_payee, 'poor_quality', 'Work incomplete', 'open'
      );

      BEGIN
        PERFORM public.release_escrow(v_p3);
      EXCEPTION WHEN OTHERS THEN
        v_dispute_caught := true;
        RAISE NOTICE 'Caught expected dispute freeze exception: %', SQLERRM;
      END;

      IF NOT v_dispute_caught THEN
        RAISE EXCEPTION 'Test 4 Failed: Release was NOT blocked despite active dispute!';
      END IF;
      RAISE NOTICE 'Test 4 PASSED: Active dispute strictly froze escrow release.';

      -------------------------------------------------------------------------
      -- TEST 5: Fee Rounding in Paise (Precision check on odd amounts)
      -------------------------------------------------------------------------
      RAISE NOTICE '--- TEST 5: Fee Rounding in Paise ---';
      -- Odd amount 73533 paise -> 5% fee = 73533 * 0.05 = 3676.65 -> rounded to 3677 paise
      -- Net = 73533 - 3677 = 69856 paise
      INSERT INTO public.payments (
        payer_id, payee_id, ref_type, ref_id, amount_paise, method, status, protected
      )
      VALUES (
        v_payer, v_payee, 'assignment', gen_random_uuid(), 73533, 'wallet', 'created', true
      )
      RETURNING id INTO v_p4;

      PERFORM public.hold_escrow(v_p4);

      SELECT available_paise INTO v_payee_before
      FROM public.wallet_balances WHERE wallet_id = v_payee_wallet_id;

      PERFORM public.release_escrow(v_p4);

      SELECT available_paise INTO v_payee_avail
      FROM public.wallet_balances WHERE wallet_id = v_payee_wallet_id;

      v_gain := v_payee_avail - v_payee_before;
      RAISE NOTICE 'Odd 73533 paise -> Net gained: % paise (Fee: %)', v_gain, 73533 - v_gain;
      IF v_gain <> 69856 THEN
        RAISE EXCEPTION 'Test 5 Failed: Expected 69856 paise, got %', v_gain;
      END IF;
      RAISE NOTICE 'Test 5 PASSED: Precise integer paise rounding verified.';

      -------------------------------------------------------------------------
      -- TEST 6: Auto-Release Timing & Filtering
      -------------------------------------------------------------------------
      RAISE NOTICE '--- TEST 6: Auto-Release Timing ---';
      -- Old completed assignment (ended 30 hours ago)
      INSERT INTO public.job_assignments (
        job_id, worker_id, booking_code, agreed_wage_paise, status, payment_eligible, ended_at
      )
      VALUES (
        v_job_id, v_payee, 'BK-OLD-30H', 45000, 'completed', true, NOW() - INTERVAL '30 hours'
      )
      RETURNING id INTO v_asg_old;

      INSERT INTO public.payments (
        payer_id, payee_id, ref_type, ref_id, amount_paise, method, status, protected
      )
      VALUES (
        v_payer, v_payee, 'assignment', v_asg_old, 45000, 'wallet', 'created', true
      )
      RETURNING id INTO v_p_old;

      PERFORM public.hold_escrow(v_p_old);

      -- Recent completed assignment (ended 30 minutes ago)
      INSERT INTO public.job_assignments (
        job_id, worker_id, booking_code, agreed_wage_paise, status, payment_eligible, ended_at
      )
      VALUES (
        v_job_id, v_payee, 'BK-NEW-30M', 35000, 'completed', true, NOW() - INTERVAL '30 minutes'
      )
      RETURNING id INTO v_asg_new;

      INSERT INTO public.payments (
        payer_id, payee_id, ref_type, ref_id, amount_paise, method, status, protected
      )
      VALUES (
        v_payer, v_payee, 'assignment', v_asg_new, 35000, 'wallet', 'created', true
      )
      RETURNING id INTO v_p_new;

      PERFORM public.hold_escrow(v_p_new);

      -- Run auto_release_escrow()
      v_auto_res := public.auto_release_escrow();
      RAISE NOTICE 'auto_release_escrow output: %', v_auto_res;

      IF (SELECT status FROM public.payments WHERE id = v_p_old) <> 'released' THEN
        RAISE EXCEPTION 'Test 6 Failed: Old payment (>24h) was NOT auto-released!';
      END IF;

      IF (SELECT status FROM public.payments WHERE id = v_p_new) <> 'held' THEN
        RAISE EXCEPTION 'Test 6 Failed: New payment (<24h) was prematurely auto-released!';
      END IF;

      RAISE NOTICE 'Test 6 PASSED: Old job auto-released while recent job remained held.';
      RAISE NOTICE '=== ALL 6 ESCROW & RECONCILIATION TESTS PASSED CLEANLY! ===';
    END $$;
  `;

  console.log('Executing test suite on remote database...');
  const res = runDbQuery(testSuiteSql);
  console.log(res);
  console.log('\n>>> SUCCESS: All 6 backend escrow release & refund tests PASSED!\n');
}

runTests().catch(err => {
  console.error('Test error:', err);
  process.exit(1);
});
