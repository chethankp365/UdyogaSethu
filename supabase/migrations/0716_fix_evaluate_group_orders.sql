-- Migration: 0716_fix_evaluate_group_orders.sql
-- Description: Refresh evaluate_group_orders to use valid public.orders columns

CREATE OR REPLACE FUNCTION public.evaluate_group_orders()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_group RECORD;
  v_listing RECORD;
  v_current_total NUMERIC;
  v_effective_price_paise BIGINT;
  v_tier RECORD;
  v_member RECORD;
  v_order_id UUID;
  v_finalized_count INT := 0;
  v_cancelled_count INT := 0;
BEGIN
  FOR v_group IN
    SELECT * FROM public.group_orders
    WHERE status IN ('open', 'target_met')
  LOOP
    SELECT COALESCE(SUM(quantity), 0) INTO v_current_total
    FROM public.group_order_members
    WHERE group_order_id = v_group.id;

    -- Scenario 1: Target reached or deadline passed with target met
    IF v_current_total >= v_group.target_qty THEN
      SELECT * INTO v_listing
      FROM public.produce_listings
      WHERE id = v_group.listing_id;

      -- Determine final tier
      v_effective_price_paise := v_listing.price_paise;
      IF v_group.price_tiers IS NOT NULL AND jsonb_array_length(v_group.price_tiers) > 0 THEN
        FOR v_tier IN
          SELECT (elem->>'min_qty')::numeric AS min_qty, (elem->>'price_paise')::bigint AS price_paise
          FROM jsonb_array_elements(v_group.price_tiers) elem
          ORDER BY (elem->>'min_qty')::numeric DESC
        LOOP
          IF v_current_total >= v_tier.min_qty THEN
            v_effective_price_paise := v_tier.price_paise;
            EXIT;
          END IF;
        END LOOP;
      END IF;

      -- Mark group order closed
      UPDATE public.group_orders
      SET status = 'closed',
          updated_at = NOW()
      WHERE id = v_group.id;

      -- Create community bulk order with exact columns of public.orders
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
        address_text
      ) VALUES (
        'GRP-' || SUBSTRING(v_group.id::text, 1, 8),
        v_group.organizer_id,
        v_listing.farmer_id,
        (v_current_total * v_effective_price_paise)::bigint,
        0,
        0,
        'accepted',
        'delivery',
        true,
        v_group.community_name || ' (Community Bulk Delivery)'
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
        v_group.listing_id,
        v_listing.name,
        COALESCE(v_listing.unit, 'unit'),
        v_effective_price_paise,
        v_current_total,
        (v_current_total * v_effective_price_paise)::bigint
      );

      v_finalized_count := v_finalized_count + 1;

    -- Scenario 2: Deadline passed and target NOT met -> Cancel and Refund
    ELSIF v_group.deadline < NOW() AND v_current_total < v_group.target_qty THEN
      UPDATE public.group_orders
      SET status = 'cancelled',
          updated_at = NOW()
      WHERE id = v_group.id;

      -- Refund participants
      FOR v_member IN
        SELECT * FROM public.group_order_members
        WHERE group_order_id = v_group.id AND paid = true
      LOOP
        PERFORM public.wallet_credit(
          v_member.user_id,
          v_member.amount_paise,
          'refund',
          'Refund: Group order ' || v_group.community_name || ' target not met'
        );
      END LOOP;

      v_cancelled_count := v_cancelled_count + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'ok', true,
    'finalized_count', v_finalized_count,
    'cancelled_count', v_cancelled_count
  );
END;
$$;
