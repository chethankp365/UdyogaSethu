-- ============================================================================
-- Migration 0510: Mandi Prices Schema, Demand Indicators & Karnataka APMC Seed
-- Step: P6.1 (Farmer Home & Live APMC Market Feed)
-- NOTE: Per AGENTS.md rule, this migration file is authored for manual review.
-- Do NOT apply or run supabase db push automatically.
-- ============================================================================

-- 1. Ensure public.mandi_prices table has the required schema columns:
-- Columns: id, state, district, market, commodity, variety, arrival_date, min_price, max_price, modal_price
CREATE TABLE IF NOT EXISTS public.mandi_prices (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  state TEXT NOT NULL DEFAULT 'Karnataka',
  district TEXT NOT NULL,
  market TEXT NOT NULL,
  commodity TEXT NOT NULL,
  variety TEXT NOT NULL DEFAULT 'Common',
  arrival_date DATE NOT NULL DEFAULT CURRENT_DATE,
  min_price NUMERIC(10, 2) NOT NULL CHECK (min_price >= 0),
  max_price NUMERIC(10, 2) NOT NULL CHECK (max_price >= min_price),
  modal_price NUMERIC(10, 2) NOT NULL CHECK (modal_price >= min_price AND modal_price <= max_price),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Backward compatibility columns in case table already exists from migration 0040:
ALTER TABLE public.mandi_prices
  ADD COLUMN IF NOT EXISTS state TEXT NOT NULL DEFAULT 'Karnataka',
  ADD COLUMN IF NOT EXISTS district TEXT,
  ADD COLUMN IF NOT EXISTS market TEXT,
  ADD COLUMN IF NOT EXISTS commodity TEXT,
  ADD COLUMN IF NOT EXISTS variety TEXT NOT NULL DEFAULT 'Common',
  ADD COLUMN IF NOT EXISTS arrival_date DATE NOT NULL DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS min_price NUMERIC(10, 2),
  ADD COLUMN IF NOT EXISTS max_price NUMERIC(10, 2),
  ADD COLUMN IF NOT EXISTS modal_price NUMERIC(10, 2),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Sync legacy crop / price_date columns if present
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'mandi_prices' AND column_name = 'crop'
  ) THEN
    UPDATE public.mandi_prices 
    SET commodity = crop 
    WHERE commodity IS NULL AND crop IS NOT NULL;
    
    ALTER TABLE public.mandi_prices ALTER COLUMN crop DROP NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'mandi_prices' AND column_name = 'price_date'
  ) THEN
    UPDATE public.mandi_prices 
    SET arrival_date = price_date 
    WHERE arrival_date IS NULL AND price_date IS NOT NULL;
    
    ALTER TABLE public.mandi_prices ALTER COLUMN price_date DROP NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'mandi_prices' AND column_name = 'modal_paise'
  ) THEN
    UPDATE public.mandi_prices 
    SET modal_price = modal_paise / 100.0 
    WHERE modal_price IS NULL AND modal_paise IS NOT NULL;
  END IF;
END $$;

-- Set default district for existing rows if null
UPDATE public.mandi_prices SET district = 'Bengaluru Urban' WHERE district IS NULL;
UPDATE public.mandi_prices SET commodity = 'Tomato' WHERE commodity IS NULL;
UPDATE public.mandi_prices SET min_price = 2000 WHERE min_price IS NULL;
UPDATE public.mandi_prices SET max_price = 3000 WHERE max_price IS NULL;
UPDATE public.mandi_prices SET modal_price = 2500 WHERE modal_price IS NULL;

-- Unique constraint for idempotent upserts by Edge function:
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_mandi_commodity_market_variety_date'
  ) THEN
    ALTER TABLE public.mandi_prices
      ADD CONSTRAINT uq_mandi_commodity_market_variety_date 
      UNIQUE (commodity, market, variety, arrival_date);
  END IF;
END $$;

-- Indexes for fast query and filtering
CREATE INDEX IF NOT EXISTS idx_mandi_prices_commodity_date 
  ON public.mandi_prices (commodity, arrival_date DESC);
CREATE INDEX IF NOT EXISTS idx_mandi_prices_market_date 
  ON public.mandi_prices (market, arrival_date DESC);
CREATE INDEX IF NOT EXISTS idx_mandi_prices_district 
  ON public.mandi_prices (district);

-- Row Level Security
ALTER TABLE public.mandi_prices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS mandi_prices_select ON public.mandi_prices;
CREATE POLICY mandi_prices_select ON public.mandi_prices
  FOR SELECT TO authenticated, anon
  USING (true);

DROP POLICY IF EXISTS mandi_prices_service ON public.mandi_prices;
CREATE POLICY mandi_prices_service ON public.mandi_prices
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

-- 2. SQL Helper Function: get_mandi_prices_with_demand
-- Computes live price, price change vs previous day, and demand indicators (High Demand, Stable, Moderate, FRP Guaranteed, Oversupply)
CREATE OR REPLACE FUNCTION public.get_mandi_prices_with_demand(
  p_commodity_filter TEXT DEFAULT NULL,
  p_district_filter TEXT DEFAULT NULL,
  p_limit INT DEFAULT 40
)
RETURNS TABLE (
  id UUID,
  state TEXT,
  district TEXT,
  market TEXT,
  commodity TEXT,
  variety TEXT,
  arrival_date DATE,
  min_price NUMERIC,
  max_price NUMERIC,
  modal_price NUMERIC,
  price_per_kg NUMERIC,
  prev_modal_price NUMERIC,
  change_percent NUMERIC,
  demand_tag TEXT,
  trend_direction TEXT,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  WITH latest_prices AS (
    SELECT DISTINCT ON (m.commodity, m.market, m.variety)
      m.id,
      m.state,
      m.district,
      m.market,
      m.commodity,
      m.variety,
      m.arrival_date,
      m.min_price,
      m.max_price,
      m.modal_price,
      ROUND(m.modal_price / 100.0, 2) AS price_per_kg,
      m.updated_at
    FROM public.mandi_prices m
    WHERE (p_commodity_filter IS NULL OR m.commodity ILIKE '%' || p_commodity_filter || '%')
      AND (p_district_filter IS NULL OR m.district ILIKE '%' || p_district_filter || '%')
    ORDER BY m.commodity, m.market, m.variety, m.arrival_date DESC
  ),
  prices_with_prev AS (
    SELECT
      lp.*,
      (
        SELECT prev.modal_price
        FROM public.mandi_prices prev
        WHERE prev.commodity = lp.commodity
          AND prev.market = lp.market
          AND prev.variety = lp.variety
          AND prev.arrival_date < lp.arrival_date
        ORDER BY prev.arrival_date DESC
        LIMIT 1
      ) AS prev_price
    FROM latest_prices lp
  )
  SELECT
    p.id,
    p.state,
    p.district,
    p.market,
    p.commodity,
    p.variety,
    p.arrival_date,
    p.min_price,
    p.max_price,
    p.modal_price,
    p.price_per_kg,
    COALESCE(p.prev_price, p.modal_price) AS prev_modal_price,
    CASE
      WHEN p.prev_price IS NOT NULL AND p.prev_price > 0 THEN
        ROUND(((p.modal_price - p.prev_price) / p.prev_price) * 100.0, 1)
      ELSE 0.0
    END AS change_percent,
    CASE
      WHEN p.commodity ILIKE '%Sugarcane%' THEN 'FRP Guaranteed'
      WHEN p.commodity ILIKE '%Paddy%' OR p.commodity ILIKE '%Rice%' THEN 'MSP Protected'
      WHEN p.prev_price IS NOT NULL AND ((p.modal_price - p.prev_price) / p.prev_price) >= 0.08 THEN 'High Demand'
      WHEN p.prev_price IS NOT NULL AND ((p.modal_price - p.prev_price) / p.prev_price) <= -0.08 THEN 'Oversupply'
      WHEN p.prev_price IS NOT NULL AND ABS((p.modal_price - p.prev_price) / p.prev_price) <= 0.03 THEN 'Stable'
      ELSE 'Moderate'
    END AS demand_tag,
    CASE
      WHEN p.prev_price IS NOT NULL AND p.modal_price > p.prev_price THEN 'up'
      WHEN p.prev_price IS NOT NULL AND p.modal_price < p.prev_price THEN 'down'
      ELSE 'stable'
    END AS trend_direction,
    p.updated_at
  FROM prices_with_prev p
  ORDER BY p.arrival_date DESC, p.commodity ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_mandi_prices_with_demand(TEXT, TEXT, INT) TO authenticated, anon;

-- 3. Realistic Sample Data: ~40 Karnataka APMC Mandi Rows
-- Markets: Bengaluru (K.R. Market, Yeshwantpur, Binny Mill), Mysuru (Bandipalya), Mandya, Hubballi, Belagavi, Kolar
-- Commodities: Tomato, Onion, Potato, Rice/Paddy, Banana, Sugarcane, Chilli, Maize, Ragi, Ginger
-- Two days of data (CURRENT_DATE and CURRENT_DATE - 1) to enable change percentage calculation
INSERT INTO public.mandi_prices (state, district, market, commodity, variety, arrival_date, min_price, max_price, modal_price)
VALUES
  -- BENGALURU MARKETS (Today)
  ('Karnataka', 'Bengaluru Urban', 'K.R. Market (Bengaluru)', 'Tomato', 'Hybrid', CURRENT_DATE, 3000, 3600, 3400),
  ('Karnataka', 'Bengaluru Urban', 'K.R. Market (Bengaluru)', 'Tomato', 'Local Organic', CURRENT_DATE, 3200, 3800, 3500),
  ('Karnataka', 'Bengaluru Urban', 'Yeshwantpur APMC', 'Onion', 'Nasik Red', CURRENT_DATE, 3400, 4200, 3800),
  ('Karnataka', 'Bengaluru Urban', 'Yeshwantpur APMC', 'Potato', 'Jyoti', CURRENT_DATE, 2100, 2600, 2400),
  ('Karnataka', 'Bengaluru Urban', 'Yeshwantpur APMC', 'Rice', 'Sona Masoori Raw', CURRENT_DATE, 4800, 5600, 5200),
  ('Karnataka', 'Bengaluru Urban', 'Binny Mill', 'Banana', 'Robusta', CURRENT_DATE, 1800, 2400, 2200),
  ('Karnataka', 'Bengaluru Urban', 'Binny Mill', 'Banana', 'Elakki', CURRENT_DATE, 4500, 5800, 5200),
  ('Karnataka', 'Bengaluru Urban', 'K.R. Market (Bengaluru)', 'Green Chilli', 'G-4', CURRENT_DATE, 3500, 4800, 4200),
  ('Karnataka', 'Bengaluru Urban', 'Yeshwantpur APMC', 'Ginger', 'Fresh Green', CURRENT_DATE, 7000, 9500, 8500),

  -- BENGALURU MARKETS (Yesterday - for change trends)
  ('Karnataka', 'Bengaluru Urban', 'K.R. Market (Bengaluru)', 'Tomato', 'Hybrid', CURRENT_DATE - 1, 2800, 3400, 3035),
  ('Karnataka', 'Bengaluru Urban', 'K.R. Market (Bengaluru)', 'Tomato', 'Local Organic', CURRENT_DATE - 1, 3000, 3500, 3200),
  ('Karnataka', 'Bengaluru Urban', 'Yeshwantpur APMC', 'Onion', 'Nasik Red', CURRENT_DATE - 1, 3500, 4400, 3920),
  ('Karnataka', 'Bengaluru Urban', 'Yeshwantpur APMC', 'Potato', 'Jyoti', CURRENT_DATE - 1, 2100, 2500, 2350),
  ('Karnataka', 'Bengaluru Urban', 'Binny Mill', 'Banana', 'Robusta', CURRENT_DATE - 1, 1600, 2200, 1910),

  -- MANDYA APMC & CLUSTER
  ('Karnataka', 'Mandya', 'Mandya APMC Yard', 'Paddy', 'Sona Masoori', CURRENT_DATE, 2300, 2600, 2450),
  ('Karnataka', 'Mandya', 'Mandya APMC Yard', 'Paddy', 'Sona Masoori', CURRENT_DATE - 1, 2250, 2500, 2330),
  ('Karnataka', 'Mandya', 'Sugar Mill Co-op', 'Sugarcane', 'Co 86032', CURRENT_DATE, 3050, 3200, 3100),
  ('Karnataka', 'Mandya', 'Sugar Mill Co-op', 'Sugarcane', 'Co 86032', CURRENT_DATE - 1, 2900, 3050, 2980),
  ('Karnataka', 'Mandya', 'Mandya APMC Yard', 'Ragi', 'GPU-28', CURRENT_DATE, 3100, 3600, 3350),
  ('Karnataka', 'Mandya', 'Mandya APMC Yard', 'Tomato', 'Local', CURRENT_DATE, 2600, 3200, 2900),

  -- MYSURU MARKETS (Bandipalya APMC)
  ('Karnataka', 'Mysuru', 'Bandipalya APMC Yard', 'Tomato', 'Local Desi', CURRENT_DATE, 2800, 3400, 3100),
  ('Karnataka', 'Mysuru', 'Bandipalya APMC Yard', 'Tomato', 'Local Desi', CURRENT_DATE - 1, 2500, 3100, 2800),
  ('Karnataka', 'Mysuru', 'Bandipalya APMC Yard', 'Onion', 'Bellary', CURRENT_DATE, 3000, 3700, 3400),
  ('Karnataka', 'Mysuru', 'Bandipalya APMC Yard', 'Paddy', 'Jyothi Coarse', CURRENT_DATE, 2100, 2400, 2250),
  ('Karnataka', 'Mysuru', 'Bandipalya APMC Yard', 'Banana', 'Nanjangud Rasabale', CURRENT_DATE, 6000, 8000, 7200),
  ('Karnataka', 'Mysuru', 'Bandipalya APMC Yard', 'Maize', 'Yellow Hybrid', CURRENT_DATE, 2150, 2450, 2300),

  -- HUBBALLI MARKETS (Dharwad)
  ('Karnataka', 'Dharwad', 'Hubballi APMC Yard', 'Onion', 'Red Medium', CURRENT_DATE, 3200, 4000, 3650),
  ('Karnataka', 'Dharwad', 'Hubballi APMC Yard', 'Onion', 'Red Medium', CURRENT_DATE - 1, 3300, 4100, 3800),
  ('Karnataka', 'Dharwad', 'Hubballi APMC Yard', 'Chilli', 'Byadgi Kaddi', CURRENT_DATE, 38000, 48000, 43500),
  ('Karnataka', 'Dharwad', 'Hubballi APMC Yard', 'Chilli', 'Byadgi Dabbi', CURRENT_DATE, 32000, 42000, 37000),
  ('Karnataka', 'Dharwad', 'Hubballi APMC Yard', 'Maize', 'Hybrid', CURRENT_DATE, 2100, 2350, 2220),
  ('Karnataka', 'Dharwad', 'Hubballi APMC Yard', 'Cotton', 'DCH-32', CURRENT_DATE, 7200, 8100, 7650),

  -- BELAGAVI MARKETS
  ('Karnataka', 'Belagavi', 'Belagavi APMC Yard', 'Potato', 'Agria', CURRENT_DATE, 2000, 2500, 2250),
  ('Karnataka', 'Belagavi', 'Belagavi APMC Yard', 'Potato', 'Agria', CURRENT_DATE - 1, 2000, 2500, 2250),
  ('Karnataka', 'Belagavi', 'Belagavi APMC Yard', 'Soybean', 'JS-335', CURRENT_DATE, 4200, 4700, 4500),
  ('Karnataka', 'Belagavi', 'Belagavi APMC Yard', 'Onion', 'White', CURRENT_DATE, 2800, 3500, 3150),
  ('Karnataka', 'Belagavi', 'Belagavi APMC Yard', 'Sugarcane', 'Co 86032', CURRENT_DATE, 3100, 3300, 3200),

  -- KOLAR APMC
  ('Karnataka', 'Kolar', 'Kolar APMC Market', 'Tomato', 'Hybrid Grade 1', CURRENT_DATE, 3100, 3700, 3450),
  ('Karnataka', 'Kolar', 'Kolar APMC Market', 'Tomato', 'Hybrid Grade 1', CURRENT_DATE - 1, 2800, 3300, 3050),
  ('Karnataka', 'Kolar', 'Kolar APMC Market', 'Mango', 'Badami / Alphonso', CURRENT_DATE, 6500, 8500, 7500)
ON CONFLICT (commodity, market, variety, arrival_date)
DO UPDATE SET
  min_price = EXCLUDED.min_price,
  max_price = EXCLUDED.max_price,
  modal_price = EXCLUDED.modal_price,
  updated_at = NOW();
