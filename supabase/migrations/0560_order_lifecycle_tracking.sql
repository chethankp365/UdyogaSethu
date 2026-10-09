-- Migration 0560: Order Lifecycle Tracking, Farmer Order Board & Escrow Settlement
-- Step P6.6: Order tracking, farmer order board, PIN confirmation, P5.3 escrow release/refund, reviews and disputes

-- 1. Ensure orders table has delivery_pin and pickup verification columns
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS delivery_pin TEXT DEFAULT LPAD(FLOOR(RANDOM() * 9000 + 1000)::TEXT, 4, '0');

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS pin_verified BOOLEAN NOT NULL DEFAULT false;

-- 2. Align order_events table columns
ALTER TABLE public.order_events ALTER COLUMN event_type DROP NOT NULL;
ALTER TABLE public.order_events ADD COLUMN IF NOT EXISTS status TEXT;
ALTER TABLE public.order_events ADD COLUMN IF NOT EXISTS note TEXT;

-- 3. Enhance place_order to create escrow payment and generate PIN
CREATE OR REPLACE FUNCTION public.place_order(
  p_items JSONB,
  p_fulfilment public.fulfilment_type DEFAULT 'delivery',
  p_address_id UUID DEFAULT NULL,
  p_address_text TEXT DEFAULT NULL,
  p_slot_id UUID DEFAULT NULL,
  p_slots JSONB DEFAULT NULL,
  p_protected BOOLEAN DEFAULT false,
  p_apply_reward_credits BOOLEAN DEFAULT false,
  p_payment_method TEXT DEFAULT 'upi',
  p_delivery_notes TEXT DEFAULT NULL
)
RETURNS TABLE (
  order_id UUID,
  order_code TEXT,
  farmer_id UUID,
  farmer_name TEXT,
  total_paise BIGINT,
  fee_paise BIGINT,
  discount_paise BIGINT,
  status public.order_status,
  items_count INT,
  slot_id UUID,
  fulfilment public.fulfilment_type,
  protected BOOLEAN
) AS $$
DECLARE
  v_customer_id UUID;
  v_farmer_record RECORD;
  v_item_req RECORD;
  v_listing_name TEXT;
  v_listing_unit TEXT;
  v_listing_price BIGINT;
  v_stock_qty NUMERIC;
  v_reserved_qty NUMERIC;
  v_listing_status public.produce_status;
  v_farmer_subtotal BIGINT;
  v_item_subtotal BIGINT;
  v_fee_paise BIGINT;
  v_discount_paise BIGINT;
  v_total_paise BIGINT;
  v_order_code TEXT;
  v_delivery_pin TEXT;
  v_cur_slot_id UUID;
  v_slot_capacity INT;
  v_slot_used INT;
  v_new_order_id UUID;
  v_new_payment_id UUID;
  v_items_json JSONB;
  v_item_count INT;
  v_single_item RECORD;
BEGIN
  -- Authenticate caller
  v_customer_id := auth.uid();
  IF v_customer_id IS NULL THEN
    v_customer_id := NULLIF(current_setting('request.jwt.claim.sub', true), '')::UUID;
  END IF;

  IF v_customer_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to place an order';
  END IF;

  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Order must contain at least one item';
  END IF;

  -- Process and group by each farmer in the cart
  FOR v_farmer_record IN
    SELECT DISTINCT pl.farmer_id, COALESCE(p.full_name, fp.farm_name, 'Cauvery Bio Farm') AS farmer_name
    FROM jsonb_to_recordset(p_items) AS x(listing_id UUID, quantity NUMERIC)
    JOIN public.produce_listings pl ON pl.id = x.listing_id
    LEFT JOIN public.profiles p ON p.id = pl.farmer_id
    LEFT JOIN public.farmer_profiles fp ON fp.user_id = pl.farmer_id
  LOOP
    v_farmer_subtotal := 0;
    v_items_json := '[]'::JSONB;
    v_item_count := 0;

    -- Determine slot for this farmer
    IF p_slots IS NOT NULL AND p_slots ? (v_farmer_record.farmer_id::TEXT) THEN
      v_cur_slot_id := (p_slots->>(v_farmer_record.farmer_id::TEXT))::UUID;
    ELSIF p_slot_id IS NOT NULL THEN
      v_cur_slot_id := p_slot_id;
    ELSE
      v_cur_slot_id := NULL;
    END IF;

    -- Row-level locking & stock verification for all items of this farmer
    FOR v_item_req IN
      SELECT x.listing_id, x.quantity
      FROM jsonb_to_recordset(p_items) AS x(listing_id UUID, quantity NUMERIC)
      JOIN public.produce_listings pl ON pl.id = x.listing_id
      WHERE pl.farmer_id = v_farmer_record.farmer_id
    LOOP
      IF v_item_req.quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
      END IF;

      -- LOCK LISTING ROW
      SELECT pl.name, pl.unit, pl.price_paise, pl.stock_qty, pl.reserved_qty, pl.status
      INTO v_listing_name, v_listing_unit, v_listing_price, v_stock_qty, v_reserved_qty, v_listing_status
      FROM public.produce_listings pl
      WHERE pl.id = v_item_req.listing_id
      FOR UPDATE;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'Produce item not found: %', v_item_req.listing_id;
      END IF;

      IF v_listing_status NOT IN ('active', 'low_stock') THEN
        RAISE EXCEPTION 'Produce item "%" is currently not available', v_listing_name;
      END IF;

      -- ATOMIC STOCK INVARIANT: Check available stock
      IF (v_stock_qty - v_reserved_qty) < v_item_req.quantity THEN
        RAISE EXCEPTION 'Out of stock: % (only % % available)', v_listing_name, GREATEST(0, (v_stock_qty - v_reserved_qty)), v_listing_unit;
      END IF;

      -- Reserve stock atomically
      UPDATE public.produce_listings
      SET reserved_qty = reserved_qty + v_item_req.quantity
      WHERE id = v_item_req.listing_id;

      -- Compute server-authoritative subtotal (client prices ignored!)
      v_item_subtotal := (v_listing_price * v_item_req.quantity)::BIGINT;
      v_farmer_subtotal := v_farmer_subtotal + v_item_subtotal;
      v_item_count := v_item_count + 1;

      v_items_json := v_items_json || jsonb_build_object(
        'listing_id', v_item_req.listing_id,
        'name', v_listing_name,
        'unit', v_listing_unit,
        'unit_price_paise', v_listing_price,
        'quantity', v_item_req.quantity,
        'subtotal_paise', v_item_subtotal
      );
    END LOOP;

    -- Slot capacity check with row-level locking
    IF v_cur_slot_id IS NOT NULL THEN
      SELECT capacity, used INTO v_slot_capacity, v_slot_used
      FROM public.delivery_slots
      WHERE id = v_cur_slot_id
      FOR UPDATE;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'Delivery slot not found: %', v_cur_slot_id;
      END IF;

      -- ATOMIC SLOT INVARIANT: Check slot capacity
      IF v_slot_used >= v_slot_capacity THEN
        RAISE EXCEPTION 'Delivery slot is full';
      END IF;

      -- Book slot atomically
      UPDATE public.delivery_slots
      SET used = used + 1
      WHERE id = v_cur_slot_id;
    END IF;

    -- Compute Fees, Discounts & Totals
    v_fee_paise := CASE WHEN p_protected THEN 500 ELSE 0 END;
    v_discount_paise := public.calculate_order_discount(v_customer_id, v_farmer_subtotal, p_apply_reward_credits);
    v_total_paise := GREATEST(0, v_farmer_subtotal + v_fee_paise - v_discount_paise);

    -- Generate unique human-readable order code & 4-digit PIN
    v_order_code := 'ORD-' || to_char(NOW(), 'YYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    v_delivery_pin := LPAD(FLOOR(RANDOM() * 9000 + 1000)::TEXT, 4, '0');

    -- Insert into public.orders
    INSERT INTO public.orders (
      order_code,
      customer_id,
      farmer_id,
      status,
      total_paise,
      fee_paise,
      discount_paise,
      fulfilment,
      address_id,
      address_text,
      slot_id,
      protected,
      payment_method,
      delivery_notes,
      delivery_pin,
      items
    ) VALUES (
      v_order_code,
      v_customer_id,
      v_farmer_record.farmer_id,
      'pending',
      v_total_paise,
      v_fee_paise,
      v_discount_paise,
      p_fulfilment,
      p_address_id,
      p_address_text,
      v_cur_slot_id,
      p_protected,
      p_payment_method,
      p_delivery_notes,
      v_delivery_pin,
      v_items_json
    ) RETURNING id INTO v_new_order_id;

    -- Create and hold escrow payment record
    INSERT INTO public.payments (
      payer_id,
      payee_id,
      amount_paise,
      platform_fee_paise,
      ref_type,
      ref_id,
      method,
      status
    ) VALUES (
      v_customer_id,
      v_farmer_record.farmer_id,
      v_total_paise,
      v_fee_paise,
      'order',
      v_new_order_id,
      COALESCE(p_payment_method, 'upi')::public.payment_method,
      'captured'
    ) RETURNING id INTO v_new_payment_id;

    UPDATE public.orders
    SET payment_id = v_new_payment_id
    WHERE id = v_new_order_id;

    -- Hold funds in escrow for order protection
    PERFORM public.hold_escrow(v_new_payment_id);

    -- Insert individual items into public.order_items
    FOR v_single_item IN SELECT * FROM jsonb_to_recordset(v_items_json) AS (
      listing_id UUID,
      name TEXT,
      unit TEXT,
      unit_price_paise BIGINT,
      quantity NUMERIC,
      subtotal_paise BIGINT
    ) LOOP
      INSERT INTO public.order_items (
        order_id,
        listing_id,
        name,
        unit,
        unit_price_paise,
        quantity,
        subtotal_paise
      ) VALUES (
        v_new_order_id,
        v_single_item.listing_id,
        v_single_item.name,
        v_single_item.unit,
        v_single_item.unit_price_paise,
        v_single_item.quantity,
        v_single_item.subtotal_paise
      );
    END LOOP;

    -- Log order_placed timeline event in order_events
    INSERT INTO public.order_events (order_id, event_type, status, actor_id, note, meta)
    VALUES (
      v_new_order_id,
      'pending',
      'pending',
      v_customer_id,
      'Order placed with escrow protection',
      jsonb_build_object(
        'total_paise', v_total_paise,
        'order_code', v_order_code,
        'items_count', v_item_count
      )
    );

    -- Assign return table values
    order_id := v_new_order_id;
    order_code := v_order_code;
    farmer_id := v_farmer_record.farmer_id;
    farmer_name := v_farmer_record.farmer_name;
    total_paise := v_total_paise;
    fee_paise := v_fee_paise;
    discount_paise := v_discount_paise;
    status := 'pending';
    items_count := v_item_count;
    slot_id := v_cur_slot_id;
    fulfilment := p_fulfilment;
    protected := p_protected;
    RETURN NEXT;
  END LOOP;

  -- Clear checked out items from cart
  DELETE FROM public.cart_items
  WHERE cart_id IN (SELECT id FROM public.carts WHERE user_id = v_customer_id)
    AND listing_id IN (
      SELECT (x->>'listing_id')::UUID FROM jsonb_array_elements(p_items) x
    );

  RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Update Order Status RPC with Escrow Settlement & Verification
CREATE OR REPLACE FUNCTION public.update_order_status(
  p_order_id UUID,
  p_status TEXT,
  p_pin TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order RECORD;
  v_new_status public.order_status;
  v_success BOOLEAN := true;
BEGIN
  IF v_uid IS NULL THEN
    v_uid := NULLIF(current_setting('request.jwt.claim.sub', true), '')::UUID;
  END IF;

  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Fetch order row with lock
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order % not found.', p_order_id;
  END IF;

  -- Verify authorization (must be farmer, customer, or admin)
  IF v_uid != v_order.farmer_id AND v_uid != v_order.customer_id AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized to update this order.';
  END IF;

  v_new_status := p_status::public.order_status;

  -- Authorization and Transition Rules
  IF v_new_status = 'accepted' THEN
    IF v_uid != v_order.farmer_id AND NOT public.is_admin() THEN
      RAISE EXCEPTION 'Only the farmer can accept an order.';
    END IF;
    IF v_order.status != 'pending' THEN
      RAISE EXCEPTION 'Only pending orders can be accepted (current: %).', v_order.status;
    END IF;

  ELSIF v_new_status = 'packed' THEN
    IF v_uid != v_order.farmer_id AND NOT public.is_admin() THEN
      RAISE EXCEPTION 'Only the farmer can mark an order as packed.';
    END IF;
    IF v_order.status != 'accepted' THEN
      RAISE EXCEPTION 'Only accepted orders can be packed (current: %).', v_order.status;
    END IF;

  ELSIF v_new_status = 'out_for_delivery' THEN
    IF v_uid != v_order.farmer_id AND NOT public.is_admin() THEN
      RAISE EXCEPTION 'Only the farmer can mark an order out for delivery.';
    END IF;
    IF v_order.status != 'packed' AND v_order.status != 'accepted' THEN
      RAISE EXCEPTION 'Order must be accepted or packed before delivery dispatch.';
    END IF;

  ELSIF v_new_status = 'delivered' THEN
    -- Either customer confirms directly, or farmer provides customer's PIN
    IF v_uid = v_order.customer_id THEN
      -- Customer confirms receipt
      NULL;
    ELSIF v_uid = v_order.farmer_id OR public.is_admin() THEN
      -- Farmer confirms delivery: check PIN if provided
      IF p_pin IS NOT NULL AND trim(p_pin) != '' THEN
        IF trim(p_pin) != v_order.delivery_pin THEN
          RAISE EXCEPTION 'Incorrect delivery/pickup PIN. Please check the customer code.';
        END IF;
      END IF;
    END IF;

    -- Update order to delivered and record timestamp
    UPDATE public.orders
    SET status = 'delivered',
        delivered_at = NOW(),
        pin_verified = (p_pin IS NOT NULL AND trim(p_pin) = v_order.delivery_pin),
        updated_at = NOW()
    WHERE id = p_order_id;

    -- RELEASE ESCROW FUNDS: Releases payment to farmer wallet (amount minus platform fee)
    IF v_order.payment_id IS NOT NULL THEN
      PERFORM public.release_escrow(v_order.payment_id);
    END IF;

  ELSIF v_new_status = 'cancelled' THEN
    IF v_order.status = 'delivered' THEN
      RAISE EXCEPTION 'Delivered orders cannot be cancelled. Please open a dispute instead.';
    END IF;

    -- REFUND ESCROW FUNDS: Full refund back to customer wallet
    IF v_order.payment_id IS NOT NULL THEN
      PERFORM public.refund_escrow(v_order.payment_id, NULL, COALESCE(p_notes, 'Order cancelled'));
    END IF;

    UPDATE public.orders
    SET status = 'cancelled',
        updated_at = NOW()
    WHERE id = p_order_id;

  ELSIF v_new_status = 'disputed' THEN
    UPDATE public.orders
    SET status = 'disputed',
        updated_at = NOW()
    WHERE id = p_order_id;

  ELSE
    -- Generic status update
    UPDATE public.orders
    SET status = v_new_status,
        updated_at = NOW()
    WHERE id = p_order_id;
  END IF;

  -- Ensure order row reflects new status
  UPDATE public.orders
  SET status = v_new_status,
      updated_at = NOW()
  WHERE id = p_order_id;

  -- Log timeline event
  INSERT INTO public.order_events (
    order_id,
    event_type,
    status,
    actor_id,
    note,
    meta,
    created_at
  ) VALUES (
    p_order_id,
    p_status,
    p_status,
    v_uid,
    COALESCE(p_notes, 'Status changed to ' || p_status),
    jsonb_build_object(
      'status', p_status,
      'actor_role', CASE WHEN v_uid = v_order.farmer_id THEN 'farmer' ELSE 'customer' END,
      'pin_verified', (p_pin IS NOT NULL AND trim(p_pin) = v_order.delivery_pin)
    ),
    NOW()
  );

  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'status', p_status,
    'pin_verified', (p_pin IS NOT NULL AND trim(p_pin) = v_order.delivery_pin)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.update_order_status(UUID, TEXT, TEXT, TEXT) TO authenticated, service_role;

-- 5. RPC: Get Full Order Details
CREATE OR REPLACE FUNCTION public.get_order_details(p_order_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order RECORD;
  v_farmer_name TEXT;
  v_customer_name TEXT;
  v_farmer_phone TEXT;
  v_customer_phone TEXT;
  v_slot RECORD;
  v_items JSONB;
BEGIN
  IF v_uid IS NULL THEN
    v_uid := NULLIF(current_setting('request.jwt.claim.sub', true), '')::UUID;
  END IF;

  SELECT o.*,
         p.status AS payment_status
  INTO v_order
  FROM public.orders o
  LEFT JOIN public.payments p ON p.id = o.payment_id
  WHERE o.id = p_order_id;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  -- Caller must be farmer, customer, or admin
  IF v_uid != v_order.farmer_id AND v_uid != v_order.customer_id AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized to view this order';
  END IF;

  -- Fetch farmer & customer names
  SELECT COALESCE(full_name, 'Cauvery Bio Farm'), phone
  INTO v_farmer_name, v_farmer_phone
  FROM public.profiles WHERE id = v_order.farmer_id;

  SELECT COALESCE(full_name, 'Direct Buyer'), phone
  INTO v_customer_name, v_customer_phone
  FROM public.profiles WHERE id = v_order.customer_id;

  -- Fetch delivery slot if present
  IF v_order.slot_id IS NOT NULL THEN
    SELECT slot_date, window_start, window_end, capacity, used
    INTO v_slot
    FROM public.delivery_slots WHERE id = v_order.slot_id;
  END IF;

  -- Fetch order items
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', oi.id,
      'listing_id', oi.listing_id,
      'name', oi.name,
      'unit', oi.unit,
      'unit_price_paise', oi.unit_price_paise,
      'quantity', oi.quantity,
      'subtotal_paise', oi.subtotal_paise
    )
  ) INTO v_items
  FROM public.order_items oi
  WHERE oi.order_id = p_order_id;

  RETURN jsonb_build_object(
    'order_id', v_order.id,
    'order_code', v_order.order_code,
    'customer_id', v_order.customer_id,
    'customer_name', v_customer_name,
    'customer_phone', v_customer_phone,
    'farmer_id', v_order.farmer_id,
    'farmer_name', v_farmer_name,
    'farmer_phone', v_farmer_phone,
    'status', v_order.status,
    'total_paise', v_order.total_paise,
    'fee_paise', v_order.fee_paise,
    'discount_paise', v_order.discount_paise,
    'fulfilment', v_order.fulfilment,
    'address_text', v_order.address_text,
    'delivery_notes', v_order.delivery_notes,
    'delivery_pin', v_order.delivery_pin,
    'protected', v_order.protected,
    'payment_method', v_order.payment_method,
    'payment_id', v_order.payment_id,
    'payment_status', v_order.payment_status,
    'created_at', v_order.created_at,
    'delivered_at', v_order.delivered_at,
    'slot', CASE WHEN v_slot.slot_date IS NOT NULL THEN
      jsonb_build_object(
        'slot_date', v_slot.slot_date,
        'window_start', v_slot.window_start,
        'window_end', v_slot.window_end
      ) ELSE NULL END,
    'items', COALESCE(v_items, '[]'::JSONB)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_order_details(UUID) TO authenticated, service_role;

-- 6. RPC: Get Farmer Orders Board
CREATE OR REPLACE FUNCTION public.get_farmer_orders(
  p_farmer_id UUID DEFAULT NULL,
  p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
  order_id UUID,
  order_code TEXT,
  customer_id UUID,
  customer_name TEXT,
  customer_phone TEXT,
  farmer_id UUID,
  status public.order_status,
  total_paise BIGINT,
  fee_paise BIGINT,
  discount_paise BIGINT,
  fulfilment public.fulfilment_type,
  address_text TEXT,
  delivery_notes TEXT,
  delivery_pin TEXT,
  protected BOOLEAN,
  payment_method TEXT,
  items_count INT,
  slot_date DATE,
  window_start TIME,
  window_end TIME,
  created_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  items JSONB
) AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_target_farmer UUID;
BEGIN
  IF v_uid IS NULL THEN
    v_uid := NULLIF(current_setting('request.jwt.claim.sub', true), '')::UUID;
  END IF;

  v_target_farmer := COALESCE(p_farmer_id, v_uid);

  RETURN QUERY
  SELECT
    o.id AS order_id,
    o.order_code,
    o.customer_id,
    COALESCE(p.full_name, 'Direct Buyer') AS customer_name,
    COALESCE(p.phone, '+91 91234 56789') AS customer_phone,
    o.farmer_id,
    o.status,
    o.total_paise,
    o.fee_paise,
    o.discount_paise,
    o.fulfilment,
    o.address_text,
    o.delivery_notes,
    o.delivery_pin,
    o.protected,
    o.payment_method,
    COALESCE(jsonb_array_length(o.items), 1)::INT AS items_count,
    ds.slot_date,
    ds.window_start,
    ds.window_end,
    o.created_at,
    o.delivered_at,
    COALESCE(o.items, '[]'::JSONB) AS items
  FROM public.orders o
  LEFT JOIN public.profiles p ON p.id = o.customer_id
  LEFT JOIN public.delivery_slots ds ON ds.id = o.slot_id
  WHERE o.farmer_id = v_target_farmer
    AND (p_status IS NULL OR o.status::TEXT = p_status)
  ORDER BY o.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_farmer_orders(UUID, TEXT) TO authenticated, service_role;

-- 7. RPC: Get Customer Orders
CREATE OR REPLACE FUNCTION public.get_customer_orders(
  p_customer_id UUID DEFAULT NULL
)
RETURNS TABLE (
  order_id UUID,
  order_code TEXT,
  farmer_id UUID,
  farmer_name TEXT,
  farmer_phone TEXT,
  status public.order_status,
  total_paise BIGINT,
  fee_paise BIGINT,
  discount_paise BIGINT,
  fulfilment public.fulfilment_type,
  address_text TEXT,
  delivery_notes TEXT,
  delivery_pin TEXT,
  protected BOOLEAN,
  payment_method TEXT,
  items_count INT,
  slot_date DATE,
  window_start TIME,
  window_end TIME,
  created_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  items JSONB
) AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_target_customer UUID;
BEGIN
  IF v_uid IS NULL THEN
    v_uid := NULLIF(current_setting('request.jwt.claim.sub', true), '')::UUID;
  END IF;

  v_target_customer := COALESCE(p_customer_id, v_uid);

  RETURN QUERY
  SELECT
    o.id AS order_id,
    o.order_code,
    o.farmer_id,
    COALESCE(fp.farm_name, p.full_name, 'Cauvery Bio Farm') AS farmer_name,
    COALESCE(p.phone, '+91 98450 77889') AS farmer_phone,
    o.status,
    o.total_paise,
    o.fee_paise,
    o.discount_paise,
    o.fulfilment,
    o.address_text,
    o.delivery_notes,
    o.delivery_pin,
    o.protected,
    o.payment_method,
    COALESCE(jsonb_array_length(o.items), 1)::INT AS items_count,
    ds.slot_date,
    ds.window_start,
    ds.window_end,
    o.created_at,
    o.delivered_at,
    COALESCE(o.items, '[]'::JSONB) AS items
  FROM public.orders o
  LEFT JOIN public.profiles p ON p.id = o.farmer_id
  LEFT JOIN public.farmer_profiles fp ON fp.user_id = o.farmer_id
  LEFT JOIN public.delivery_slots ds ON ds.id = o.slot_id
  WHERE o.customer_id = v_target_customer
  ORDER BY o.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_customer_orders(UUID) TO authenticated, service_role;

-- 8. Add Realtime publication on orders and order_events if not already added
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  EXCEPTION WHEN duplicate_object THEN
    -- already added
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.order_events;
  EXCEPTION WHEN duplicate_object THEN
    -- already added
  END;
END $$;
