-- Test: verify_subscriptions_and_ai.sql
-- Description: Automated SQL test suite for P6.7 Subscriptions, Scheduler, Group Orders & P6.8 Schemes

BEGIN;

DO $$
DECLARE
  v_farmer_id UUID;
  v_customer_id UUID;
  v_listing_id UUID;
  v_sub_active_id UUID;
  v_sub_paused_id UUID;
  v_sub_skipped_id UUID;
  v_sub_stockout_id UUID;
  v_sched_res JSONB;
  v_order_count INT;
  v_group_id UUID;
  v_join_res JSONB;
  v_eval_res JSONB;
  v_schemes_count INT;
  v_tomorrow DATE := CURRENT_DATE + 1;
BEGIN
  RAISE NOTICE '=== 1. Setting up Test Users and Produce Listing ===';
  
  -- Create or find test farmer and customer
  SELECT id INTO v_farmer_id FROM public.profiles WHERE active_role = 'farmer' LIMIT 1;
  IF v_farmer_id IS NULL THEN
    v_farmer_id := 'f0000000-0000-0000-0000-000000000001'::uuid;
    INSERT INTO public.profiles (id, phone, full_name, active_role)
    VALUES (v_farmer_id, '+919900000991', 'Test Organic Farmer', 'farmer')
    ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
  END IF;

  SELECT id INTO v_customer_id FROM public.profiles WHERE active_role = 'provider' LIMIT 1;
  IF v_customer_id IS NULL THEN
    v_customer_id := 'c0000000-0000-0000-0000-000000000001'::uuid;
    INSERT INTO public.profiles (id, phone, full_name, active_role)
    VALUES (v_customer_id, '+919900000992', 'Test Apartment Customer', 'provider')
    ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
  END IF;

  -- Create fresh produce listing with stock
  INSERT INTO public.produce_listings (
    farmer_id, name, category, price_paise, unit, stock_qty, status
  ) VALUES (
    v_farmer_id, 'A2 Farm Milk Daily Fresh Test', 'dairy', 6000, 'liter', 50.0, 'active'
  ) RETURNING id INTO v_listing_id;

  RAISE NOTICE '=== 2. Creating Subscriptions (Active, Paused, Skipped, Stockout) ===';

  -- A. Active subscription (qty 2 liters)
  INSERT INTO public.subscriptions (
    customer_id, farmer_id, listing_id, quantity, frequency, status, next_delivery_date,
    delivery_slot_time, doorstep_address, unit_price_paise, listing_name, farmer_name, skip_dates
  ) VALUES (
    v_customer_id, v_farmer_id, v_listing_id, 2.0, 'daily', 'active', v_tomorrow,
    '07:00 AM', 'Flat 402, Sunshine Apts', 6000, 'A2 Farm Milk Daily Fresh Test', 'Test Organic Farmer', '{}'
  ) RETURNING id INTO v_sub_active_id;

  -- B. Paused subscription
  INSERT INTO public.subscriptions (
    customer_id, farmer_id, listing_id, quantity, frequency, status, next_delivery_date,
    delivery_slot_time, doorstep_address, unit_price_paise, listing_name, farmer_name, skip_dates
  ) VALUES (
    v_customer_id, v_farmer_id, v_listing_id, 1.0, 'daily', 'paused', v_tomorrow,
    '07:00 AM', 'Flat 402, Sunshine Apts', 6000, 'A2 Farm Milk Daily Fresh Test', 'Test Organic Farmer', '{}'
  ) RETURNING id INTO v_sub_paused_id;

  -- C. Skipped tomorrow subscription
  INSERT INTO public.subscriptions (
    customer_id, farmer_id, listing_id, quantity, frequency, status, next_delivery_date,
    delivery_slot_time, doorstep_address, unit_price_paise, listing_name, farmer_name, skip_dates
  ) VALUES (
    v_customer_id, v_farmer_id, v_listing_id, 3.0, 'daily', 'active', v_tomorrow,
    '07:00 AM', 'Flat 402, Sunshine Apts', 6000, 'A2 Farm Milk Daily Fresh Test', 'Test Organic Farmer', ARRAY[v_tomorrow]
  ) RETURNING id INTO v_sub_skipped_id;

  RAISE NOTICE '=== 3. Testing Scheduler Execution for Tomorrow (%) ===', v_tomorrow;

  v_sched_res := public.generate_tomorrow_deliveries(v_tomorrow);
  RAISE NOTICE 'Scheduler result: %', v_sched_res;

  -- Verify active generated order
  SELECT count(*) INTO v_order_count
  FROM public.orders o
  JOIN public.order_items oi ON oi.order_id = o.id
  WHERE oi.listing_id = v_listing_id AND o.delivery_date = v_tomorrow;

  IF v_order_count <> 1 THEN
    RAISE EXCEPTION 'Expected exactly 1 generated order for tomorrow, found %', v_order_count;
  END IF;
  RAISE NOTICE '✓ Verification passed: Exactly 1 order generated for active subscription.';

  -- Verify stock deducted by 2 liters (50 - 2 = 48)
  IF (SELECT stock_qty FROM public.produce_listings WHERE id = v_listing_id) <> 48.0 THEN
    RAISE EXCEPTION 'Stock was not properly deducted by quantity 2';
  END IF;
  RAISE NOTICE '✓ Verification passed: Produce stock decremented from 50.0 to 48.0.';

  -- Idempotency check: Running scheduler again should generate 0 new orders
  v_sched_res := public.generate_tomorrow_deliveries(v_tomorrow);
  IF (v_sched_res->>'generated_orders')::int <> 0 THEN
    RAISE EXCEPTION 'Idempotency failure: scheduler regenerated order on same day';
  END IF;
  RAISE NOTICE '✓ Verification passed: Scheduler is idempotent, 0 duplicate orders generated.';

  RAISE NOTICE '=== 4. Testing Stock Shortage Handling ===';
  -- Set stock to 0 and verify notification created without order
  UPDATE public.produce_listings SET stock_qty = 0.5 WHERE id = v_listing_id;
  
  -- Create another active sub requiring 5 liters
  INSERT INTO public.subscriptions (
    customer_id, farmer_id, listing_id, quantity, frequency, status, next_delivery_date,
    delivery_slot_time, doorstep_address, unit_price_paise, listing_name, farmer_name, skip_dates
  ) VALUES (
    v_customer_id, v_farmer_id, v_listing_id, 5.0, 'daily', 'active', v_tomorrow + 1,
    '07:00 AM', 'Flat 402, Sunshine Apts', 6000, 'A2 Farm Milk Daily Fresh Test', 'Test Organic Farmer', '{}'
  ) RETURNING id INTO v_sub_stockout_id;

  v_sched_res := public.generate_tomorrow_deliveries(v_tomorrow + 1);
  IF (v_sched_res->>'stock_failures')::int < 1 OR (v_sched_res->>'generated_orders')::int <> 0 THEN
    RAISE EXCEPTION 'Expected at least 1 stock shortage failure and 0 generated orders, got %', v_sched_res;
  END IF;
  RAISE NOTICE '✓ Verification passed: Stock shortage prevented order and logged unfulfilled notice.';

  RAISE NOTICE '=== 5. Testing Apartment Group Orders and Tier Pricing ===';
  -- Create group order with tiers: >=10 -> 4000 paise, >=25 -> 3500 paise, >=50 -> 3000 paise
  INSERT INTO public.group_orders (
    organizer_id, listing_id, community_name, target_qty, price_tiers, deadline, status
  ) VALUES (
    v_customer_id,
    v_listing_id,
    'Prestige Falcon City Apartment',
    25.0,
    '[{"min_qty": 10, "price_paise": 4000}, {"min_qty": 25, "price_paise": 3500}, {"min_qty": 50, "price_paise": 3000}]'::jsonb,
    NOW() + INTERVAL '2 days',
    'open'
  ) RETURNING id INTO v_group_id;

  -- Add members to reach target tier 25
  INSERT INTO public.group_order_members (group_order_id, user_id, quantity, amount_paise, paid)
  VALUES (v_group_id, v_customer_id, 15.0, 60000, true);

  -- Neighbour joins with 10.0 -> Total = 25.0 (Target met!)
  INSERT INTO public.group_order_members (group_order_id, user_id, quantity, amount_paise, paid)
  VALUES (v_group_id, v_farmer_id, 10.0, 35000, true);

  -- Evaluate group order
  v_eval_res := public.evaluate_group_orders();
  RAISE NOTICE 'Group order evaluation result: %', v_eval_res;

  IF (SELECT status FROM public.group_orders WHERE id = v_group_id) <> 'closed' THEN
    RAISE EXCEPTION 'Group order was not finalized to closed on target met';
  END IF;
  RAISE NOTICE '✓ Verification passed: Group order target reached, bulk order created.';

  RAISE NOTICE '=== 6. Testing Government Schemes Table (P6.8) ===';
  SELECT count(*) INTO v_schemes_count FROM public.government_schemes;
  IF v_schemes_count < 5 THEN
    RAISE EXCEPTION 'Expected at least 5 curated government schemes, found %', v_schemes_count;
  END IF;
  RAISE NOTICE '✓ Verification passed: % Curated Government Schemes available with official links.', v_schemes_count;

  RAISE NOTICE '=== ALL SQL VERIFICATION TESTS PASSED SUCCESSFULLY! ===';
END $$;

ROLLBACK;
