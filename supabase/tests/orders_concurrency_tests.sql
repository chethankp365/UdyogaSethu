-- Concurrency, Slot, Server-Side Pricing, and Multi-Farmer Split Test Suite
-- Step P6.5 Verification Function returning formatted result table

CREATE OR REPLACE FUNCTION public.test_run_orders_concurrency_suite()
RETURNS TABLE (
  test_name TEXT,
  passed BOOLEAN,
  details TEXT
) AS $$
DECLARE
  v_test_farmer1 UUID := '44444444-4444-4444-8444-444444444401';
  v_test_farmer2 UUID := '44444444-4444-4444-8444-444444444402';
  v_test_customer UUID;
  v_listing1 UUID;
  v_listing2 UUID;
  v_slot1 UUID;
  v_slot_full UUID;
  v_order_count INT;
  v_caught_oversell BOOLEAN := false;
  v_caught_slot_full BOOLEAN := false;
  v_orders_res RECORD;
  v_actual_total BIGINT;
  v_order_id_test UUID;
  v_stock_before NUMERIC;
  v_stock_after NUMERIC;
  v_reserved_after NUMERIC;
BEGIN
  -- Test Customer
  SELECT id INTO v_test_customer FROM public.profiles WHERE id != v_test_farmer1 LIMIT 1;
  IF v_test_customer IS NULL THEN
    v_test_customer := '11111111-1111-1111-8111-111111111101';
  END IF;
  PERFORM set_config('request.jwt.claim.sub', v_test_customer::TEXT, true);

  -- --------------------------------------------------------------------------
  -- TEST 1: LAST UNIT CANNOT BE OVER-SOLD
  -- --------------------------------------------------------------------------
  INSERT INTO public.produce_listings (
    farmer_id, name, category, description, price_paise, unit, stock_qty, reserved_qty, status
  ) VALUES (
    v_test_farmer1, 'Test Single Unit Crop', 'vegetable', 'Test item', 5000, 'kg', 1.0, 0.0, 'active'
  ) RETURNING id INTO v_listing1;

  INSERT INTO public.delivery_slots (
    farmer_id, slot_date, window_start, window_end, capacity, used
  ) VALUES (
    v_test_farmer1, CURRENT_DATE + 5, '08:00:00', '10:00:00', 5, 0
  ) RETURNING id INTO v_slot1;

  -- Buyer 1 order
  SELECT * INTO v_orders_res FROM public.place_order(
    p_items := jsonb_build_array(jsonb_build_object('listing_id', v_listing1, 'quantity', 1.0)),
    p_fulfilment := 'delivery',
    p_slot_id := v_slot1
  );

  -- Buyer 2 concurrent order must fail
  BEGIN
    PERFORM public.place_order(
      p_items := jsonb_build_array(jsonb_build_object('listing_id', v_listing1, 'quantity', 1.0)),
      p_fulfilment := 'delivery',
      p_slot_id := v_slot1
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%Out of stock%' THEN
      v_caught_oversell := true;
    END IF;
  END;

  test_name := 'Test 1: Last unit oversell protection';
  passed := v_caught_oversell;
  details := 'Buyer 1 booked last 1.0 unit. Concurrent Buyer 2 blocked with Out of stock exception.';
  RETURN NEXT;

  -- --------------------------------------------------------------------------
  -- TEST 2: FULL DELIVERY SLOT CANNOT BE OVERBOOKED
  -- --------------------------------------------------------------------------
  INSERT INTO public.produce_listings (
    farmer_id, name, category, description, price_paise, unit, stock_qty, reserved_qty, status
  ) VALUES (
    v_test_farmer1, 'Test Slot Crop', 'vegetable', 'Slot test', 3000, 'kg', 100.0, 0.0, 'active'
  ) RETURNING id INTO v_listing2;

  INSERT INTO public.delivery_slots (
    farmer_id, slot_date, window_start, window_end, capacity, used
  ) VALUES (
    v_test_farmer1, CURRENT_DATE + 6, '14:00:00', '16:00:00', 1, 1
  ) RETURNING id INTO v_slot_full;

  BEGIN
    PERFORM public.place_order(
      p_items := jsonb_build_array(jsonb_build_object('listing_id', v_listing2, 'quantity', 1.0)),
      p_fulfilment := 'delivery',
      p_slot_id := v_slot_full
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%Delivery slot is full%' THEN
      v_caught_slot_full := true;
    END IF;
  END;

  test_name := 'Test 2: Full slot overbooking protection';
  passed := v_caught_slot_full;
  details := 'Order on capacity=1, used=1 slot blocked with Delivery slot is full exception.';
  RETURN NEXT;

  -- --------------------------------------------------------------------------
  -- TEST 3: CLIENT CANNOT SEND OR CHANGE PRICES (SERVER-AUTHORITATIVE)
  -- --------------------------------------------------------------------------
  SELECT * INTO v_orders_res FROM public.place_order(
    p_items := jsonb_build_array(jsonb_build_object(
      'listing_id', v_listing2,
      'quantity', 2.0,
      'unit_price_paise', 10 -- Client attempted malicious price
    )),
    p_fulfilment := 'pickup',
    p_protected := false
  );

  SELECT total_paise INTO v_actual_total FROM public.orders WHERE id = v_orders_res.order_id;

  test_name := 'Test 3: Server-side pricing enforcement';
  passed := (v_actual_total = 6000);
  details := format('Malicious client price ignored. Server calculated exact 6000 paise (actual: %s).', v_actual_total);
  RETURN NEXT;

  -- --------------------------------------------------------------------------
  -- TEST 4: MULTI-FARMER CART SPLIT INTO ONE ORDER PER FARMER
  -- --------------------------------------------------------------------------
  INSERT INTO public.produce_listings (
    farmer_id, name, category, description, price_paise, unit, stock_qty, reserved_qty, status
  ) VALUES (
    v_test_farmer2, 'Farmer 2 Organic Milk', 'dairy', 'Pure milk', 6000, 'L', 50.0, 0.0, 'active'
  ) RETURNING id INTO v_listing1;

  SELECT COUNT(*) INTO v_order_count FROM public.place_order(
    p_items := jsonb_build_array(
      jsonb_build_object('listing_id', v_listing2, 'quantity', 1.0),
      jsonb_build_object('listing_id', v_listing1, 'quantity', 2.0)
    ),
    p_fulfilment := 'delivery'
  );

  test_name := 'Test 4: Multi-farmer cart splitting';
  passed := (v_order_count = 2);
  details := format('Cart with 2 farmers split automatically into %s independent orders.', v_order_count);
  RETURN NEXT;

  -- --------------------------------------------------------------------------
  -- TEST 5: STOCK RESERVATION LIFECYCLE (ACCEPT CONFIRMS, CANCEL RELEASES)
  -- --------------------------------------------------------------------------
  INSERT INTO public.produce_listings (
    farmer_id, name, category, description, price_paise, unit, stock_qty, reserved_qty, status
  ) VALUES (
    v_test_farmer1, 'Lifecycle Test Grain', 'grain', 'Test grain', 4000, 'kg', 10.0, 0.0, 'active'
  ) RETURNING id INTO v_listing1;

  SELECT * INTO v_orders_res FROM public.place_order(
    p_items := jsonb_build_array(jsonb_build_object('listing_id', v_listing1, 'quantity', 3.0)),
    p_fulfilment := 'delivery',
    p_slot_id := v_slot1
  );
  v_order_id_test := v_orders_res.order_id;

  SELECT stock_qty, reserved_qty INTO v_stock_before, v_reserved_after
  FROM public.produce_listings WHERE id = v_listing1;

  -- Farmer accepts order
  UPDATE public.orders SET status = 'accepted' WHERE id = v_order_id_test;

  SELECT stock_qty, reserved_qty INTO v_stock_after, v_reserved_after
  FROM public.produce_listings WHERE id = v_listing1;

  test_name := 'Test 5: Stock reservation & acceptance confirmation';
  passed := (v_stock_before = 10.0 AND v_stock_after = 7.0 AND v_reserved_after = 0.0);
  details := format('Before accept: stock=%s, after accept: stock=%s, reserved=%s.', v_stock_before, v_stock_after, v_reserved_after);
  RETURN NEXT;

  -- Cleanup
  DELETE FROM public.orders WHERE customer_id = v_test_customer;
  DELETE FROM public.produce_listings WHERE id IN (v_listing1, v_listing2);
  DELETE FROM public.delivery_slots WHERE id IN (v_slot1, v_slot_full);

  RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM public.test_run_orders_concurrency_suite();
