-- ============================================================================
-- Migration 0520: Produce Listings Management, Price Suggestion & Buyer Feed
-- Step: P6.2 (Farmer Profile, Listings & Inventory Management)
-- NOTE: Per AGENTS.md rule, this migration file is authored for manual review.
-- Do NOT apply or run supabase db push automatically.
-- ============================================================================

-- 1. Ensure produce_listings table has low_stock_threshold column
ALTER TABLE public.produce_listings
  ADD COLUMN IF NOT EXISTS low_stock_threshold NUMERIC(10,2) NOT NULL DEFAULT 10.00;

-- 2. Trigger Function: Automatically manage listing status based on stock quantity
-- Invariant:
-- - stock_qty <= 0 -> 'sold_out'
-- - stock_qty <= low_stock_threshold AND status != 'paused' -> 'low_stock'
-- - stock_qty > low_stock_threshold AND status IN ('sold_out', 'low_stock') -> 'active'
-- - If status is manually set to 'paused', it remains 'paused' unless farmer activates it.
CREATE OR REPLACE FUNCTION public.sync_produce_listing_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.stock_qty <= 0 THEN
    NEW.status := 'sold_out';
  ELSIF NEW.status <> 'paused' THEN
    IF NEW.stock_qty <= COALESCE(NEW.low_stock_threshold, 10.00) THEN
      NEW.status := 'low_stock';
    ELSIF NEW.status IN ('sold_out', 'low_stock') THEN
      NEW.status := 'active';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_produce_listing_status ON public.produce_listings;
CREATE TRIGGER trg_sync_produce_listing_status
  BEFORE INSERT OR UPDATE OF stock_qty, status, low_stock_threshold
  ON public.produce_listings
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_produce_listing_status();

-- 3. SQL Procedure to decrement produce stock atomically
CREATE OR REPLACE FUNCTION public.decrement_listing_stock(
  p_listing_id UUID,
  p_quantity NUMERIC
)
RETURNS TABLE (
  success BOOLEAN,
  remaining_stock NUMERIC,
  new_status public.produce_status,
  error_message TEXT
) AS $$
DECLARE
  v_current_stock NUMERIC;
  v_new_stock NUMERIC;
  v_status public.produce_status;
BEGIN
  SELECT stock_qty, status INTO v_current_stock, v_status
  FROM public.produce_listings
  WHERE id = p_listing_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 0.0::NUMERIC, 'paused'::public.produce_status, 'Listing not found'::TEXT;
    RETURN;
  END IF;

  IF v_current_stock < p_quantity THEN
    RETURN QUERY SELECT false, v_current_stock, v_status, 'Insufficient stock available'::TEXT;
    RETURN;
  END IF;

  UPDATE public.produce_listings
  SET stock_qty = stock_qty - p_quantity
  WHERE id = p_listing_id
  RETURNING stock_qty, status INTO v_new_stock, v_status;

  RETURN QUERY SELECT true, v_new_stock, v_status, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.decrement_listing_stock(UUID, NUMERIC) TO authenticated, service_role;

-- 4. Trigger on orders: When an order is accepted, decrement produce stock
CREATE OR REPLACE FUNCTION public.trg_order_accepted_decrement_stock()
RETURNS TRIGGER AS $$
DECLARE
  v_item JSONB;
  v_listing_id UUID;
  v_qty NUMERIC;
BEGIN
  -- Only execute when status transitions to 'accepted' or 'confirmed'
  IF (NEW.status IN ('accepted', 'confirmed')) AND (OLD.status IS NULL OR OLD.status NOT IN ('accepted', 'confirmed')) THEN
    IF NEW.items IS NOT NULL AND jsonb_typeof(NEW.items) = 'array' THEN
      FOR v_item IN SELECT * FROM jsonb_array_elements(NEW.items)
      LOOP
        v_listing_id := (v_item->>'listing_id')::UUID;
        v_qty := COALESCE((v_item->>'quantity')::NUMERIC, (v_item->>'quantity_kg')::NUMERIC, 0.0);
        
        IF v_listing_id IS NOT NULL AND v_qty > 0 THEN
          PERFORM public.decrement_listing_stock(v_listing_id, v_qty);
        END IF;
      END LOOP;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_order_accepted_decrement_stock ON public.orders;
CREATE TRIGGER trg_order_accepted_decrement_stock
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_order_accepted_decrement_stock();

-- 5. RPC: Get Buyer Produce Listings (Active & In Stock only)
-- INVARIANT: Set stock to zero or pause -> buyer search no longer returns it!
CREATE OR REPLACE FUNCTION public.get_buyer_produce_listings(
  p_search TEXT DEFAULT NULL,
  p_category TEXT DEFAULT NULL,
  p_farming_method TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  farmer_id UUID,
  farmer_name TEXT,
  farm_name TEXT,
  cluster_village TEXT,
  farmer_avatar_path TEXT,
  is_verified_farmer BOOLEAN,
  name TEXT,
  category public.produce_category,
  description TEXT,
  price_paise BIGINT,
  unit TEXT,
  stock_qty NUMERIC,
  status public.produce_status,
  harvest_at TIMESTAMPTZ,
  quality_notes TEXT,
  farming_method TEXT,
  images TEXT[],
  delivery_available BOOLEAN,
  pickup_available BOOLEAN,
  availability_mode public.availability_mode,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pl.id,
    pl.farmer_id,
    COALESCE(p.full_name, 'Verified Farmer') AS farmer_name,
    COALESCE(fp.farm_name, 'Greenfield Organic Farm') AS farm_name,
    COALESCE(fp.cluster_village, 'Mandya Cluster') AS cluster_village,
    p.avatar_path AS farmer_avatar_path,
    (fp.user_id IS NOT NULL) AS is_verified_farmer,
    pl.name,
    pl.category,
    pl.description,
    pl.price_paise,
    pl.unit,
    pl.stock_qty,
    pl.status,
    pl.harvest_at,
    pl.quality_notes,
    pl.farming_method,
    pl.images,
    pl.delivery_available,
    pl.pickup_available,
    pl.availability_mode,
    pl.created_at,
    pl.updated_at
  FROM public.produce_listings pl
  JOIN public.profiles p ON p.id = pl.farmer_id
  LEFT JOIN public.farmer_profiles fp ON fp.user_id = pl.farmer_id
  WHERE pl.status IN ('active', 'low_stock')
    AND pl.stock_qty > 0
    AND (p_search IS NULL OR pl.name ILIKE '%' || p_search || '%' OR pl.description ILIKE '%' || p_search || '%')
    AND (p_category IS NULL OR pl.category::TEXT = p_category)
    AND (p_farming_method IS NULL OR pl.farming_method ILIKE '%' || p_farming_method || '%')
  ORDER BY pl.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_buyer_produce_listings(TEXT, TEXT, TEXT, INT) TO authenticated, anon;

-- 6. RPC: Price Suggestion Band Generator
-- Analyzes recent mandi prices from APMC and recent completed orders
CREATE OR REPLACE FUNCTION public.get_produce_price_suggestion(
  p_commodity TEXT,
  p_unit TEXT DEFAULT 'kg'
)
RETURNS TABLE (
  commodity TEXT,
  mandi_modal_price NUMERIC,
  mandi_market TEXT,
  mandi_arrival_date DATE,
  suggested_min_paise BIGINT,
  suggested_max_paise BIGINT,
  suggested_modal_paise BIGINT,
  explanation TEXT
) AS $$
DECLARE
  v_mandi_price NUMERIC := 0;
  v_market TEXT := 'Karnataka APMC Average';
  v_date DATE := CURRENT_DATE;
  v_unit_factor NUMERIC := 1.0; -- Default 1 for kg
  v_modal_paise BIGINT;
BEGIN
  -- Unit factor adjustment (if quintal, mandi modal price is already per quintal; if kg, divide by 100)
  IF LOWER(p_unit) = 'qtl' OR LOWER(p_unit) = 'quintal' THEN
    v_unit_factor := 100.0;
  ELSE
    v_unit_factor := 1.0;
  END IF;

  -- Look up latest mandi price for commodity
  SELECT modal_price, market, arrival_date
  INTO v_mandi_price, v_market, v_date
  FROM public.mandi_prices
  WHERE commodity ILIKE '%' || p_commodity || '%'
  ORDER BY arrival_date DESC
  LIMIT 1;

  IF v_mandi_price IS NULL OR v_mandi_price = 0 THEN
    -- Fallback default benchmark
    v_mandi_price := 2500.0;
    v_market := 'Karnataka Benchmark';
  END IF;

  -- Base price in paise per unit
  -- v_mandi_price is in rupees per quintal (100 kg)
  -- Price per kg in rupees = v_mandi_price / 100.0
  -- Price per unit in paise = (v_mandi_price / 100.0 * v_unit_factor) * 100 = v_mandi_price * v_unit_factor
  v_modal_paise := (v_mandi_price * v_unit_factor)::BIGINT;

  RETURN QUERY SELECT
    p_commodity,
    ROUND(v_mandi_price / 100.0, 2), -- ₹/kg benchmark
    v_market,
    v_date,
    ROUND(v_modal_paise * 0.90)::BIGINT, -- -10%
    ROUND(v_modal_paise * 1.15)::BIGINT, -- +15%
    v_modal_paise,
    format('Based on %s APMC rate of ₹%s/kg on %s. Direct farm sales typically command +5%% to +15%% for farm-freshness.',
      v_market,
      ROUND(v_mandi_price / 100.0, 0),
      to_char(v_date, 'DD Mon YYYY')
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_produce_price_suggestion(TEXT, TEXT) TO authenticated, anon;

-- 7. Storage Bucket for Produce Images
INSERT INTO storage.buckets (id, name, public)
VALUES ('produce-images', 'produce-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage policies: Public read, authenticated farmer write
DROP POLICY IF EXISTS produce_images_select ON storage.objects;
CREATE POLICY produce_images_select ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'produce-images');

DROP POLICY IF EXISTS produce_images_insert ON storage.objects;
CREATE POLICY produce_images_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'produce-images');

DROP POLICY IF EXISTS produce_images_update ON storage.objects;
CREATE POLICY produce_images_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'produce-images' AND auth.uid() = owner);

DROP POLICY IF EXISTS produce_images_delete ON storage.objects;
CREATE POLICY produce_images_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'produce-images' AND auth.uid() = owner);

-- 8. Seed sample produce listings if farmer profiles exist
DO $$
DECLARE
  v_farmer_id UUID;
BEGIN
  SELECT user_id INTO v_farmer_id FROM public.farmer_profiles LIMIT 1;
  IF v_farmer_id IS NOT NULL THEN
    INSERT INTO public.produce_listings (
      farmer_id, name, category, description, price_paise, unit, stock_qty, low_stock_threshold,
      status, harvest_at, quality_notes, farming_method, delivery_available, pickup_available, availability_mode
    )
    VALUES
      (v_farmer_id, 'Organic Hybrid Tomatoes', 'vegetable', 'Vine-ripened, pesticide-free fresh farm tomatoes.', 2800, 'kg', 120.0, 15.0, 'active', NOW(), 'Grade A, firm and juicy', 'Organic (Karnataka Certified)', true, true, 'same_day'),
      (v_farmer_id, 'Fresh Sona Masuri Rice (Brown)', 'grain', 'Organically grown Sona Masuri unpolished rice, harvest 2026.', 6500, 'kg', 450.0, 50.0, 'active', NOW() - INTERVAL '10 days', 'Naturally aged, zero preservatives', 'Natural Farming', true, true, 'next_day'),
      (v_farmer_id, 'Nanjanagudu Rasabale Banana', 'fruit', 'GI-tagged heirloom sweet fragrance bananas from Mysuru.', 4500, 'bunch', 8.0, 10.0, 'low_stock', NOW(), 'Sweet and naturally ripened without carbide', 'Organic', true, true, 'same_day'),
      (v_farmer_id, 'Fresh Farm Baby Potatoes', 'vegetable', 'Tender red skin potatoes fresh from Hassan soil.', 2400, 'kg', 0.0, 10.0, 'sold_out', NOW() - INTERVAL '3 days', 'Graded medium size', 'Conventional', true, false, 'pre_order')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;
