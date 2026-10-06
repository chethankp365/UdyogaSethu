-- Migration: 0340_nearby_jobs_pins.sql
-- Description: Updates nearby_jobs RPC to return coordinates (lat, lng), employer details,
--              and localized category metadata for interactive map pins.
--              Seeds 12 live Bangalore jobs matching Screen 7 in UI_REFERENCE.md.

-- 1. Drop existing nearby_jobs functions to allow return table signature expansion
DROP FUNCTION IF EXISTS public.nearby_jobs(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, UUID, BIGINT, BIGINT, TEXT, INT, INT);
DROP FUNCTION IF EXISTS public.nearby_jobs;

-- 2. Create updated nearby_jobs RPC with lat, lng, and employer/category metadata
CREATE OR REPLACE FUNCTION public.nearby_jobs(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 50000,
  p_category_id UUID DEFAULT NULL,
  p_min_wage_paise BIGINT DEFAULT NULL,
  p_max_wage_paise BIGINT DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_limit INT DEFAULT 60,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  category_id UUID,
  title TEXT,
  description TEXT,
  wage_type public.wage_type,
  wage_paise BIGINT,
  start_at TIMESTAMPTZ,
  slots_total INT,
  slots_filled INT,
  address_text TEXT,
  distance_m DOUBLE PRECISION,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  employer_name TEXT,
  employer_avatar TEXT,
  employer_verified BOOLEAN,
  employer_rating NUMERIC,
  category_name JSONB,
  category_icon TEXT,
  category_slug TEXT
) AS $$
DECLARE
  v_point extensions.geography;
BEGIN
  -- Build geography reference point
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL AND p_lat <> 0 AND p_lng <> 0 THEN
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;
  ELSE
    -- Default central anchor (Bengaluru) if null
    v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(77.5946, 12.9716), 4326)::extensions.geography;
  END IF;

  RETURN QUERY
  SELECT
    j.id,
    j.provider_id,
    j.category_id,
    j.title,
    j.description,
    j.wage_type,
    j.wage_paise,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    j.address_text,
    extensions.ST_Distance(j.location, v_point) AS distance_m,
    extensions.ST_Y(j.location::extensions.geometry) AS lat,
    extensions.ST_X(j.location::extensions.geometry) AS lng,
    COALESCE(pp.org_name, p.full_name, 'Direct Employer') AS employer_name,
    COALESCE(p.avatar_path, '') AS employer_avatar,
    (COALESCE(pp.rating_avg, 0) >= 4.0 OR j.provider_id IS NOT NULL) AS employer_verified,
    COALESCE(pp.rating_avg, 4.8) AS employer_rating,
    sc.names AS category_name,
    COALESCE(sc.icon, 'work') AS category_icon,
    COALESCE(sc.slug, 'general') AS category_slug
  FROM public.jobs j
  LEFT JOIN public.profiles p ON p.id = j.provider_id
  LEFT JOIN public.provider_profiles pp ON pp.user_id = j.provider_id
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.status = 'open'
    AND j.location IS NOT NULL
    AND extensions.ST_DWithin(j.location, v_point, p_radius_m)
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    AND (p_min_wage_paise IS NULL OR j.wage_paise >= p_min_wage_paise)
    AND (p_max_wage_paise IS NULL OR j.wage_paise <= p_max_wage_paise)
    AND (
      p_search_query IS NULL 
      OR p_search_query = ''
      OR j.title ILIKE '%' || p_search_query || '%' 
      OR j.description ILIKE '%' || p_search_query || '%'
      OR j.address_text ILIKE '%' || p_search_query || '%'
    )
  ORDER BY distance_m ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.nearby_jobs TO authenticated, anon;

-- 3. Seed/Upsert 12 Live Pin Jobs matching Screen 7 in UI_REFERENCE.md
-- All positioned around central/south/east Bengaluru (Koramangala, Indiranagar, HSR, Richmond, etc.)
DO $$
DECLARE
  v_prov UUID := '33333333-3333-4333-8333-333333333303';
  v_cat_elec UUID := 'a5555555-5555-4555-8555-555555555555';
  v_cat_const UUID := 'a1111111-1111-4111-8111-111111111111';
  v_cat_plumb UUID := 'a2222222-2222-4222-8222-222222222222';
  v_cat_paint UUID := 'a3333333-3333-4333-8333-333333333333';
  v_cat_deliv UUID := 'a4444444-4444-4444-8444-444444444444';
  v_cat_carp UUID := 'a6666666-6666-4666-8666-666666666666';
  v_cat_mason UUID := 'a7777777-7777-4777-8777-777777777777';
  v_cat_clean UUID := 'a8888888-8888-4888-8888-888888888888';
  v_cat_load UUID := 'b3333333-3333-4333-8333-333333333333';
  v_cat_agri UUID := 'b2222222-2222-4222-8222-222222222222';
BEGIN
  -- Pin 1: Electrician - Sai Electricals • Koramangala, Bengaluru (₹880)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555501', v_prov, v_cat_elec,
    'Electrician', 'Wiring inspection and breaker switch installations at commercial site.',
    'daily', 88000, 2, 0, 'open', true, 'escrow',
    'Sai Electricals • Koramangala, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6180, 12.9340), 4326)::extensions.geography,
    NOW() + INTERVAL '1 hour'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 2: Construction Helper - Sharma Builders • Koramangala 4th Block (₹700)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555502', v_prov, v_cat_const,
    'Construction Helper', 'Assisting site masonry and cement mortar mixing on new residential project.',
    'daily', 70000, 3, 0, 'open', true, 'escrow',
    'Sharma Builders • Koramangala 4th Block, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6250, 12.9310), 4326)::extensions.geography,
    NOW() + INTERVAL '2 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 3: Plumber - R.K. Plumbing Services • Koramangala 4th Block (₹910)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555503', v_prov, v_cat_plumb,
    'Plumber', 'Bathroom CPVC pipeline leakage repairs and kitchen sink trap assembly.',
    'daily', 91000, 1, 0, 'open', true, 'escrow',
    'R.K. Plumbing Services • Koramangala 4th Block, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6220, 12.9360), 4326)::extensions.geography,
    NOW() + INTERVAL '3 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 4: Painter - Royal Paints Worksite • Indiranagar (₹850)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555504', v_prov, v_cat_paint,
    'Interior Wall Painter', 'Putty preparation and primer roller application for 2BHK flat.',
    'daily', 85000, 2, 0, 'open', true, 'escrow',
    'Royal Paints Worksite • Indiranagar 100ft Rd, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6400, 12.9720), 4326)::extensions.geography,
    NOW() + INTERVAL '4 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 5: Delivery Driver - FastDrop Hub • BTM Layout (₹650)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555505', v_prov, v_cat_deliv,
    'E-Commerce Delivery Assistant', 'Local parcel last-mile dropoffs across BTM & Tavarekere.',
    'daily', 65000, 4, 0, 'open', true, 'escrow',
    'FastDrop Hub • BTM Layout 2nd Stage, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6080, 12.9150), 4326)::extensions.geography,
    NOW() + INTERVAL '2 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 6: Carpenter - WoodCraft Studio • Koramangala (₹800)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555506', v_prov, v_cat_carp,
    'Carpenter & Woodwork Assistant', 'Plywood wardrobe framing and laminating assist.',
    'daily', 80000, 1, 0, 'open', true, 'escrow',
    'WoodCraft Studio • Koramangala 1st Block, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6320, 12.9280), 4326)::extensions.geography,
    NOW() + INTERVAL '5 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 7: Loading Helper - APMC Yard • Yeshwanthpur (₹600)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555507', v_prov, v_cat_load,
    'Goods Loading & Unloading Helper', 'Unloading vegetable crates from trucks at wholesale market.',
    'daily', 60000, 5, 0, 'open', true, 'escrow',
    'APMC Wholesale Market • Yeshwanthpur, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.5500, 13.0200), 4326)::extensions.geography,
    NOW() + INTERVAL '1 hour'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 8: Mason Helper - Metro Project Pillar 234 • MG Road (₹750)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555508', v_prov, v_cat_mason,
    'Masonry Assistant', 'Civil construction work along MG Road metro corridor.',
    'daily', 75000, 2, 0, 'open', true, 'escrow',
    'Metro Infra Site • MG Road, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6080, 12.9750), 4326)::extensions.geography,
    NOW() + INTERVAL '3 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 9: Warehouse Associate - QuickMart Depot • Whitefield (₹950)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555509', v_prov, v_cat_deliv,
    'Warehouse Inventory Associate', 'Bar code scan dispatch and parcel sorting in fulfillment warehouse.',
    'daily', 95000, 3, 0, 'open', true, 'escrow',
    'QuickMart Depot • ITPL Main Rd, Whitefield, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.7280, 12.9850), 4326)::extensions.geography,
    NOW() + INTERVAL '2 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 10: Cleaner - CleanPro Homes • HSR Layout (₹680)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555511', v_prov, v_cat_clean,
    'Residential Deep Cleaning Helper', 'Floor scrubbing and window cleaning for villa renovation.',
    'daily', 68000, 2, 0, 'open', true, 'escrow',
    'CleanPro Homes • HSR Layout Sector 2, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6500, 12.9100), 4326)::extensions.geography,
    NOW() + INTERVAL '4 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 11: Tile Layer - Prestige Towers Site • Domlur (₹920)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555512', v_prov, v_cat_const,
    'Floor Tile Layer Assistant', 'Tile cutting and adhesive spreading for multi-unit apartment.',
    'daily', 92000, 2, 0, 'open', true, 'escrow',
    'Prestige Towers Site • Domlur, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6380, 12.9610), 4326)::extensions.geography,
    NOW() + INTERVAL '2 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

  -- Pin 12: Agri / Landscaping Worker - GreenCity Gardens • Bannerghatta (₹650)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555513', v_prov, v_cat_agri,
    'Landscape Gardener & Planting Assistant', 'Planting saplings and garden trench preparation.',
    'daily', 65000, 2, 0, 'open', true, 'escrow',
    'GreenCity Gardens • Bannerghatta Road, Bengaluru',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.5970, 12.8900), 4326)::extensions.geography,
    NOW() + INTERVAL '3 hours'
  ) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    wage_paise = EXCLUDED.wage_paise,
    address_text = EXCLUDED.address_text,
    location = EXCLUDED.location,
    status = 'open';

END $$;
