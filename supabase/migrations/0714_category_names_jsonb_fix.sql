-- Migration: 0714_category_names_jsonb_fix.sql
-- Description: Fix service_categories.names JSONB extraction in generate_tomorrow_deliveries

CREATE OR REPLACE FUNCTION public.generate_tomorrow_deliveries(
  p_target_date DATE DEFAULT (CURRENT_DATE + 1)
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sub RECORD;
  v_listing RECORD;
  v_day_of_week INT; -- 1 = Monday .. 7 = Sunday
  v_should_deliver BOOLEAN;
  v_order_id UUID;
  v_order_code TEXT;
  v_total_paise BIGINT;
  v_generated_orders INT := 0;
  v_skipped_orders INT := 0;
  v_stock_failures INT := 0;
  v_job_assignments_created INT := 0;
  v_rb RECORD;
  v_existing_order UUID;
  v_job_id UUID;
  v_should_service BOOLEAN;
BEGIN
  v_day_of_week := EXTRACT(ISODOW FROM p_target_date);

  -- 1. PROCESS PRODUCE SUBSCRIPTIONS
  FOR v_sub IN
    SELECT s.*
    FROM public.subscriptions s
    WHERE s.status = 'active'
  LOOP
    -- Check skip dates
    IF v_sub.skip_dates IS NOT NULL AND p_target_date = ANY(v_sub.skip_dates) THEN
      v_skipped_orders := v_skipped_orders + 1;
      CONTINUE;
    END IF;

    -- Check frequency fit
    v_should_deliver := false;
    IF v_sub.frequency = 'daily' THEN
      v_should_deliver := true;
    ELSIF v_sub.frequency = 'weekdays' THEN
      IF v_day_of_week BETWEEN 1 AND 5 THEN
        v_should_deliver := true;
      END IF;
    ELSIF v_sub.frequency = 'weekly' THEN
      -- Default weekly delivers on Monday (1) or whatever day next_delivery_date landed on
      IF v_day_of_week = EXTRACT(ISODOW FROM COALESCE(v_sub.next_delivery_date, p_target_date)) THEN
        v_should_deliver := true;
      END IF;
    ELSE
      v_should_deliver := true;
    END IF;

    IF NOT v_should_deliver THEN
      CONTINUE;
    END IF;

    -- Check idempotency: order already generated for this customer, listing, and delivery date?
    SELECT o.id INTO v_existing_order
    FROM public.orders o
    JOIN public.order_items oi ON oi.order_id = o.id
    WHERE o.customer_id = v_sub.customer_id
      AND oi.listing_id = v_sub.listing_id
      AND o.delivery_date = p_target_date
    LIMIT 1;

    IF v_existing_order IS NOT NULL THEN
      CONTINUE; -- Already generated today
    END IF;

    -- Check produce stock availability
    SELECT * INTO v_listing
    FROM public.produce_listings
    WHERE id = v_sub.listing_id;

    IF v_listing IS NULL OR v_listing.stock_qty < v_sub.quantity THEN
      -- Stock shortage! Do NOT generate order. Send notification.
      v_stock_failures := v_stock_failures + 1;

      INSERT INTO public.notifications (
        user_id,
        title,
        body,
        type,
        data
      ) VALUES (
        v_sub.customer_id,
        'Subscription delivery unavailable for tomorrow',
        'Your scheduled subscription for ' || COALESCE(v_sub.listing_name, 'Produce') || ' cannot be fulfilled tomorrow due to fresh harvest stock shortage.',
        'order_status',
        jsonb_build_object(
          'subscription_id', v_sub.id,
          'target_date', p_target_date,
          'reason', 'stock_shortage'
        )
      );

      CONTINUE;
    END IF;

    -- Deduct stock
    UPDATE public.produce_listings
    SET stock_qty = stock_qty - v_sub.quantity,
        updated_at = NOW()
    WHERE id = v_sub.listing_id;

    -- Generate order
    v_order_code := 'SUB-' || TO_CHAR(p_target_date, 'YYYYMMDD') || '-' || SUBSTRING(v_sub.id::text, 1, 6);
    v_total_paise := (v_sub.quantity * COALESCE(v_sub.unit_price_paise, v_listing.price_paise))::bigint;

    INSERT INTO public.orders (
      order_code,
      customer_id,
      farmer_id,
      total_paise,
      fee_paise,
      discount_paise,
      status,
      fulfilment,
      protected,
      delivery_date,
      address_text
    ) VALUES (
      v_order_code,
      v_sub.customer_id,
      v_sub.farmer_id,
      v_total_paise,
      0,
      0,
      'accepted',
      'delivery',
      true,
      p_target_date,
      COALESCE(v_sub.doorstep_address, 'Doorstep Delivery')
    ) RETURNING id INTO v_order_id;

    INSERT INTO public.order_items (
      order_id,
      listing_id,
      name,
      unit,
      unit_price_paise,
      quantity,
      subtotal_paise
    ) VALUES (
      v_order_id,
      v_sub.listing_id,
      COALESCE(v_sub.listing_name, v_listing.name),
      COALESCE(v_listing.unit, 'unit'),
      COALESCE(v_sub.unit_price_paise, v_listing.price_paise),
      v_sub.quantity,
      v_total_paise
    );

    -- Timeline event
    INSERT INTO public.order_events (
      order_id,
      event_type,
      status,
      note,
      actor_id
    ) VALUES (
      v_order_id,
      'order_placed',
      'accepted',
      'Automatically generated from active farm subscription ' || v_sub.delivery_slot_time,
      v_sub.farmer_id
    );

    v_generated_orders := v_generated_orders + 1;
  END LOOP;

  -- 2. PROCESS RECURRING SERVICE JOBS (P4.6)
  FOR v_rb IN
    SELECT rb.*, COALESCE(sc.names->>'en', 'Home Cleaning & Maintenance') AS category_title
    FROM public.recurring_bookings rb
    LEFT JOIN public.service_categories sc ON sc.id = rb.category_id
    WHERE rb.status = 'active'
  LOOP
    IF v_rb.skip_dates IS NOT NULL AND p_target_date = ANY(v_rb.skip_dates) THEN
      CONTINUE;
    END IF;

    -- Evaluate recurrence rule
    v_should_service := false;
    IF v_rb.schedule_rule = 'daily' THEN
      v_should_service := true;
    ELSIF v_rb.schedule_rule = 'weekdays' THEN
      IF v_day_of_week BETWEEN 1 AND 5 THEN
        v_should_service := true;
      END IF;
    ELSIF v_rb.schedule_rule = 'weekly' THEN
      IF v_day_of_week = EXTRACT(ISODOW FROM v_rb.created_at::date) THEN
        v_should_service := true;
      END IF;
    ELSE
      v_should_service := true;
    END IF;

    IF NOT v_should_service THEN
      CONTINUE;
    END IF;

    v_job_id := v_rb.job_id;

    IF v_job_id IS NULL THEN
      -- Create a direct job for this recurring booking
      INSERT INTO public.jobs (
        provider_id,
        category_id,
        title,
        description,
        wage_type,
        wage_paise,
        start_at,
        slots_total,
        slots_filled,
        source,
        status
      ) VALUES (
        v_rb.provider_id,
        v_rb.category_id,
        'Recurring Service: ' || v_rb.category_title,
        'Scheduled recurring service session',
        'daily',
        50000,
        (p_target_date || ' ' || COALESCE(v_rb.preferred_time::text, '09:00:00'))::timestamptz,
        1,
        1,
        'direct_booking',
        'assigned'
      ) RETURNING id INTO v_job_id;
    END IF;

    -- Check if assignment already exists for tomorrow
    IF NOT EXISTS (
      SELECT 1 FROM public.job_assignments
      WHERE job_id = v_job_id
        AND worker_id = v_rb.worker_id
        AND scheduled_start::date = p_target_date
    ) THEN
      INSERT INTO public.job_assignments (
        job_id,
        worker_id,
        status,
        scheduled_start,
        escrow_wage_paise,
        created_at
      ) VALUES (
        v_job_id,
        v_rb.worker_id,
        'requested',
        (p_target_date || ' ' || COALESCE(v_rb.preferred_time::text, '09:00:00'))::timestamptz,
        0,
        NOW()
      );
      v_job_assignments_created := v_job_assignments_created + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'ok', true,
    'target_date', p_target_date,
    'generated_orders', v_generated_orders,
    'skipped_orders', v_skipped_orders,
    'stock_failures', v_stock_failures,
    'job_assignments_created', v_job_assignments_created
  );
END;
$$;
