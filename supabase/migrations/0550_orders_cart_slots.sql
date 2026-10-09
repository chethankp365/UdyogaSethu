-- Migration 0550: Orders, Cart, Delivery Slots & Atomic Checkout with Stock Reservation
-- Step P6.5: Guided order flow: Cart, Slot Manager, place_order with atomic concurrency locks, server-side pricing

-- 1. Produce Listings: Add reserved_qty column for concurrency safety
ALTER TABLE public.produce_listings
ADD COLUMN IF NOT EXISTS reserved_qty NUMERIC(10,2) NOT NULL DEFAULT 0.0 CHECK (reserved_qty >= 0);

-- Update trigger function to take reserved_qty into account
CREATE OR REPLACE FUNCTION public.sync_produce_listing_status()
RETURNS TRIGGER AS $$
DECLARE
  v_available NUMERIC;
BEGIN
  -- Preserve paused status if explicitly set
  IF NEW.status = 'paused' THEN
    RETURN NEW;
  END IF;

  v_available := NEW.stock_qty - COALESCE(NEW.reserved_qty, 0.0);

  IF NEW.stock_qty <= 0 OR v_available <= 0 THEN
    NEW.status := 'sold_out';
  ELSIF v_available <= COALESCE(NEW.low_stock_threshold, 5.0) THEN
    NEW.status := 'low_stock';
  ELSE
    NEW.status := 'active';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Delivery Slots: RLS Policies & Grants
ALTER TABLE public.delivery_slots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS delivery_slots_select ON public.delivery_slots;
CREATE POLICY delivery_slots_select ON public.delivery_slots
  FOR SELECT USING (true);

DROP POLICY IF EXISTS delivery_slots_farmer ON public.delivery_slots;
CREATE POLICY delivery_slots_farmer ON public.delivery_slots
  FOR ALL USING (farmer_id = auth.uid())
  WITH CHECK (farmer_id = auth.uid());

GRANT ALL ON public.delivery_slots TO authenticated;
GRANT SELECT ON public.delivery_slots TO anon;

-- 3. Orders: Add additional checkout columns
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS address_text TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_notes TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS discount_paise BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'upi';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS items JSONB;

-- 4. Calculate Order Discount function
CREATE OR REPLACE FUNCTION public.calculate_order_discount(
  p_customer_id UUID,
  p_subtotal_paise BIGINT,
  p_use_rewards BOOLEAN DEFAULT false
)
RETURNS BIGINT AS $$
DECLARE
  v_discount BIGINT := 0;
  v_available_rewards BIGINT := 0;
BEGIN
  IF NOT p_use_rewards OR p_subtotal_paise <= 0 THEN
    RETURN 0;
  END IF;

  -- Check user's wallet reward balance if exists
  SELECT COALESCE(reward_paise, 0) INTO v_available_rewards
  FROM public.wallet_balances
  WHERE user_id = p_customer_id;

  IF v_available_rewards > 0 THEN
    v_discount := LEAST(v_available_rewards, (p_subtotal_paise * 10) / 100);
  ELSE
    -- Demo reward credit discount: 5% of subtotal, capped at 5000 paise (₹50)
    v_discount := LEAST(5000::BIGINT, (p_subtotal_paise * 5) / 100);
  END IF;

  RETURN v_discount;
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION public.calculate_order_discount(UUID, BIGINT, BOOLEAN) TO authenticated, service_role, anon;

-- 5. Trigger: Stock & Slot reservation lifecycle on status updates
-- Replace older trigger from 0520
DROP TRIGGER IF EXISTS trg_order_accepted_decrement_stock ON public.orders;
DROP FUNCTION IF EXISTS public.trg_order_accepted_decrement_stock();

CREATE OR REPLACE FUNCTION public.trg_order_status_stock_and_slot_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_item RECORD;
  v_listing_id UUID;
  v_qty NUMERIC;
BEGIN
  -- 1. Order transitions from pending -> accepted
  -- CONFIRM RESERVATION: deduct stock_qty, reduce reserved_qty
  IF (NEW.status = 'accepted') AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN
    FOR v_item IN SELECT listing_id, quantity FROM public.order_items WHERE order_id = NEW.id
    LOOP
      v_listing_id := v_item.listing_id;
      v_qty := v_item.quantity;
      IF v_listing_id IS NOT NULL AND v_qty > 0 THEN
        UPDATE public.produce_listings
        SET stock_qty = GREATEST(0, stock_qty - v_qty),
            reserved_qty = GREATEST(0, reserved_qty - v_qty)
        WHERE id = v_listing_id;
      END IF;
    END LOOP;
  END IF;

  -- 2. Order transitions to cancelled from pending
  -- RELEASE RESERVATION: release reserved_qty, release delivery slot
  IF (NEW.status = 'cancelled') AND (OLD.status = 'pending') THEN
    FOR v_item IN SELECT listing_id, quantity FROM public.order_items WHERE order_id = NEW.id
    LOOP
      v_listing_id := v_item.listing_id;
      v_qty := v_item.quantity;
      IF v_listing_id IS NOT NULL AND v_qty > 0 THEN
        UPDATE public.produce_listings
        SET reserved_qty = GREATEST(0, reserved_qty - v_qty)
        WHERE id = v_listing_id;
      END IF;
    END LOOP;

    -- Release slot capacity
    IF NEW.slot_id IS NOT NULL THEN
      UPDATE public.delivery_slots
      SET used = GREATEST(0, used - 1)
      WHERE id = NEW.slot_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_order_status_stock_and_slot_sync ON public.orders;
CREATE TRIGGER trg_order_status_stock_and_slot_sync
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_order_status_stock_and_slot_sync();

-- 6. Atomic place_order procedure
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
  v_cur_slot_id UUID;
  v_slot_capacity INT;
  v_slot_used INT;
  v_new_order_id UUID;
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

    -- Generate unique human-readable order code
    v_order_code := 'ORD-' || to_char(NOW(), 'YYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));

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
      v_items_json
    ) RETURNING id INTO v_new_order_id;

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

    -- Log order_placed timeline event
    INSERT INTO public.order_events (order_id, event_type, actor_id, meta)
    VALUES (v_new_order_id, 'order_placed', v_customer_id, jsonb_build_object(
      'total_paise', v_total_paise,
      'order_code', v_order_code,
      'items_count', v_item_count
    ));

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

GRANT EXECUTE ON FUNCTION public.place_order(JSONB, public.fulfilment_type, UUID, TEXT, UUID, JSONB, BOOLEAN, BOOLEAN, TEXT, TEXT) TO authenticated, service_role;

-- 7. Farmer Delivery Slot Creation RPC
CREATE OR REPLACE FUNCTION public.create_delivery_slot(
  p_slot_date DATE,
  p_window_start TIME,
  p_window_end TIME,
  p_capacity INT DEFAULT 10
)
RETURNS UUID AS $$
DECLARE
  v_farmer_id UUID := auth.uid();
  v_new_id UUID;
BEGIN
  IF v_farmer_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_slot_date < CURRENT_DATE THEN
    RAISE EXCEPTION 'Slot date cannot be in the past';
  END IF;

  IF p_window_start >= p_window_end THEN
    RAISE EXCEPTION 'Window start must be before window end';
  END IF;

  IF p_capacity <= 0 THEN
    RAISE EXCEPTION 'Capacity must be greater than zero';
  END IF;

  INSERT INTO public.delivery_slots (
    farmer_id,
    slot_date,
    window_start,
    window_end,
    capacity,
    used
  ) VALUES (
    v_farmer_id,
    p_slot_date,
    p_window_start,
    p_window_end,
    p_capacity,
    0
  ) RETURNING id INTO v_new_id;

  RETURN v_new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_delivery_slot(DATE, TIME, TIME, INT) TO authenticated;

-- 8. Seed upcoming delivery slots for test farmers for CURRENT_DATE, CURRENT_DATE + 1, and CURRENT_DATE + 2
INSERT INTO public.delivery_slots (farmer_id, slot_date, window_start, window_end, capacity, used)
SELECT f.farmer_id, d.slot_date, w.w_start, w.w_end, 10, 0
FROM (
  VALUES
    ('44444444-4444-4444-8444-444444444401'::UUID),
    ('44444444-4444-4444-8444-444444444402'::UUID),
    ('44444444-4444-4444-8444-444444444403'::UUID)
) AS f(farmer_id)
CROSS JOIN (
  SELECT (CURRENT_DATE + s)::DATE AS slot_date FROM generate_series(0, 3) s
) AS d
CROSS JOIN (
  VALUES
    ('07:00:00'::TIME, '11:00:00'::TIME),
    ('16:00:00'::TIME, '19:00:00'::TIME)
) AS w(w_start, w_end)
ON CONFLICT DO NOTHING;
