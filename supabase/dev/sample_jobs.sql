-- supabase/dev/sample_jobs.sql
-- Idempotent script for inserting realistic sample jobs in Bengaluru.
-- Features 10 Student / Part-time jobs and 8 Informal trade jobs.
-- Safe to re-run multiple times (ON CONFLICT DO UPDATE).

DO $$
DECLARE
  v_prov UUID := '33333333-3333-4333-8333-333333333303';

  -- Informal trade categories (audience = '{informal}')
  v_cat_elec UUID := 'a5555555-5555-4555-8555-555555555555';
  v_cat_const UUID := 'a1111111-1111-4111-8111-111111111111';
  v_cat_plumb UUID := 'a2222222-2222-4222-8222-222222222222';
  v_cat_paint UUID := 'a3333333-3333-4333-8333-333333333333';
  v_cat_carp UUID := 'a6666666-6666-4666-8666-666666666666';
  v_cat_mason UUID := 'a7777777-7777-4777-8777-777777777777';
  v_cat_clean UUID := 'a8888888-8888-4888-8888-888888888888';
  v_cat_load UUID := 'b3333333-3333-4333-8333-333333333333';

  -- Student / Part-time categories (audience = '{student,part_time}')
  v_cat_content UUID;
  v_cat_design UUID;
  v_cat_tutor UUID;
  v_cat_campus UUID;
  v_cat_retail UUID;
  v_cat_deliv UUID;
BEGIN
  -- Look up student category IDs dynamically by slug
  SELECT id INTO v_cat_content FROM public.service_categories WHERE slug = 'content-writing' LIMIT 1;
  SELECT id INTO v_cat_design FROM public.service_categories WHERE slug = 'design-data-work' LIMIT 1;
  SELECT id INTO v_cat_tutor FROM public.service_categories WHERE slug = 'tutoring-academics' LIMIT 1;
  SELECT id INTO v_cat_campus FROM public.service_categories WHERE slug = 'campus-brand-promotion' LIMIT 1;
  SELECT id INTO v_cat_retail FROM public.service_categories WHERE slug = 'retail-food-service' LIMIT 1;
  SELECT id INTO v_cat_deliv FROM public.service_categories WHERE slug = 'delivery-gig-work' LIMIT 1;

  -- Ensure fallback provider exists in profiles
  INSERT INTO public.profiles (id, phone, full_name, active_role, is_phone_verified)
  VALUES (v_prov, '+919988776655', 'UdyogaSethu Partner Network', 'provider', true)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.provider_profiles (user_id, org_name, provider_type, rating_avg)
  VALUES (v_prov, 'UdyogaSethu Verified Employers', 'company', 4.9)
  ON CONFLICT (user_id) DO NOTHING;

  -- =========================================================================
  -- 10 STUDENT & PART-TIME JOBS (Only visible to Student & Part-time seekers)
  -- =========================================================================

  -- S1: Weekend Campus Delivery Partner (Koramangala)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666601', v_prov, COALESCE(v_cat_deliv, v_cat_retail),
    'Weekend Campus Delivery Partner', 'Flexible evening food & packet delivery around Koramangala & Sony World signal.',
    'hourly', 45000, 4, 0, 'open', true, 'escrow',
    'Zippy Delivery Hub • Koramangala 5th Block',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6205, 12.9352), 4326)::extensions.geography,
    NOW() + INTERVAL '2 hours',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- S2: Math & Science Home Tutor (HSR Layout)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666602', v_prov, COALESCE(v_cat_tutor, v_cat_design),
    '10th Grade Math & Science Tutor', 'Evening tutoring session for 2 students. 2 hours per day.',
    'hourly', 50000, 2, 0, 'open', true, 'escrow',
    'Bright Minds Academy • HSR Layout Sector 2',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6480, 12.9110), 4326)::extensions.geography,
    NOW() + INTERVAL '3 hours',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- S3: Cafe Barista & Counter Assistant (Indiranagar)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666603', v_prov, COALESCE(v_cat_retail, v_cat_deliv),
    'Cafe Barista & Counter Assistant', 'Afternoon shift counter service, coffee brewing and cashier support.',
    'hourly', 40000, 2, 0, 'open', true, 'escrow',
    'Artisan Coffee House • 12th Main Indiranagar',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6410, 12.9719), 4326)::extensions.geography,
    NOW() + INTERVAL '4 hours',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- S4: Tech Fest Event Coordinator (MG Road)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666604', v_prov, COALESCE(v_cat_campus, v_cat_content),
    'Tech Fest Event Coordinator', 'Registration desk coordination and badge distribution for a 1-day summit.',
    'daily', 160000, 5, 0, 'open', true, 'escrow',
    'Bangalore Convention Centre • MG Road',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6090, 12.9750), 4326)::extensions.geography,
    NOW() + INTERVAL '1 day',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- S5: Retail Store Inventory Assistant (Commercial Street)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666605', v_prov, COALESCE(v_cat_retail, v_cat_deliv),
    'Retail Inventory & Stock Assistant', 'Barcode scanning, shelf restocking, and customer assistance.',
    'hourly', 42000, 3, 0, 'open', true, 'escrow',
    'FabStore • Commercial Street, Shivajinagar',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6105, 12.9818), 4326)::extensions.geography,
    NOW() + INTERVAL '5 hours',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- S6: Data Entry & Document Verifier (Electronic City)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666606', v_prov, COALESCE(v_cat_design, v_cat_content),
    'Data Entry & Document Verifier', 'Digitizing student records and catalog entries on Excel & web portal.',
    'hourly', 38000, 2, 0, 'open', true, 'escrow',
    'Tech Park One • Electronic City Phase 1',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6650, 12.8450), 4326)::extensions.geography,
    NOW() + INTERVAL '2 hours',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- S7: Social Media & Event Content Creator (Koramangala)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666607', v_prov, COALESCE(v_cat_content, v_cat_campus),
    'Campus Brand & Content Creator', 'Shooting 15-second clips and event stories on mobile during campus exhibitions.',
    'hourly', 45000, 2, 0, 'open', true, 'escrow',
    'Creative Spark • Koramangala 7th Block',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6140, 12.9360), 4326)::extensions.geography,
    NOW() + INTERVAL '6 hours',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- S8: Campus Brand Ambassador & Flyer Promoter (Brigade Road)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666608', v_prov, COALESCE(v_cat_campus, v_cat_retail),
    'Campus Brand Ambassador', 'Distributing youth discount coupons and app demos outside metro stations.',
    'hourly', 40000, 4, 0, 'open', true, 'escrow',
    'Rex Plaza • Brigade Road, Ashok Nagar',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6075, 12.9730), 4326)::extensions.geography,
    NOW() + INTERVAL '4 hours',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- S9: Evening Library Assistant (Jayanagar)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666609', v_prov, COALESCE(v_cat_design, v_cat_tutor),
    'Evening Library Assistant', 'Stacking books, scanning borrower cards and keeping reading hall orderly.',
    'hourly', 35000, 2, 0, 'open', true, 'escrow',
    'Central Public Library • Jayanagar 4th Block',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.5830, 12.9298), 4326)::extensions.geography,
    NOW() + INTERVAL '3 hours',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- S10: E-Commerce Dispatch Helper (BTM Layout)
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at, requirements
  ) VALUES (
    '66666666-6666-4666-8666-666666666610', v_prov, COALESCE(v_cat_deliv, v_cat_retail),
    'E-Commerce Dispatch Helper', 'Packing small electronics parcels and affixing shipping labels.',
    'hourly', 42000, 3, 0, 'open', true, 'escrow',
    'Express Logistics • BTM Layout 2nd Stage',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6101, 12.9165), 4326)::extensions.geography,
    NOW() + INTERVAL '1 hour',
    jsonb_build_object('students_ok', true, 'part_time_ok', true, 'flexible_shift', true)
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- =========================================================================
  -- 8 INFORMAL TRADE JOBS (Only visible to Informal seekers; NOT to students)
  -- =========================================================================

  -- T1: Electrician
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
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- T2: Construction Helper
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555502', v_prov, v_cat_const,
    'Construction Helper', 'Material carrying and mortar mixing for building renovation.',
    'daily', 70000, 5, 0, 'open', true, 'escrow',
    'Sharma Builders • Koramangala 4th Block',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6250, 12.9300), 4326)::extensions.geography,
    NOW() + INTERVAL '2 hours'
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- T3: Plumber
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555503', v_prov, v_cat_plumb,
    'Plumber', 'Pipeline joint fixing and sanitary fitting at residential apartment complex.',
    'daily', 85000, 2, 0, 'open', true, 'escrow',
    'QuickFix Plumbing • BTM Layout 1st Stage',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6050, 12.9200), 4326)::extensions.geography,
    NOW() + INTERVAL '3 hours'
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- T4: Wall Painter
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555504', v_prov, v_cat_paint,
    'Wall Painter', 'Interior emulsion painting and primer application for commercial flat.',
    'daily', 80000, 3, 0, 'open', true, 'escrow',
    'ColourCraft Studio • HSR Layout Sector 1',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6420, 12.9150), 4326)::extensions.geography,
    NOW() + INTERVAL '1 hour'
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- T5: Carpenter
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555505', v_prov, v_cat_carp,
    'Carpenter', 'Cabinet hinge fixing, shelf fitting and laminate edge trimming.',
    'daily', 90000, 2, 0, 'open', true, 'escrow',
    'WoodArt Carpentry • Jayanagar 7th Block',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.5780, 12.9240), 4326)::extensions.geography,
    NOW() + INTERVAL '2 hours'
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- T6: Mason / Tile Layer
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555506', v_prov, v_cat_mason,
    'Mason & Tile Layer', 'Floor tiling, levelling and cement grouting for office corridor.',
    'daily', 95000, 3, 0, 'open', true, 'escrow',
    'Apex Masonry • Richmond Town',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6010, 12.9620), 4326)::extensions.geography,
    NOW() + INTERVAL '4 hours'
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- T7: Warehouse Loader
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555507', v_prov, v_cat_load,
    'Warehouse Loader', 'Loading and unloading crates and carton boxes into delivery vans.',
    'daily', 75000, 4, 0, 'open', true, 'escrow',
    'Metro Logistics • Domlur Layout',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.6380, 12.9610), 4326)::extensions.geography,
    NOW() + INTERVAL '2 hours'
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

  -- T8: General Cleaner
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description, wage_type, wage_paise,
    slots_total, slots_filled, status, materials_provided, payment_mode,
    address_text, location, start_at
  ) VALUES (
    '55555555-5555-4555-8555-555555555508', v_prov, v_cat_clean,
    'Commercial Site Cleaner', 'Post-construction floor sweep, glass wipe down and debris clearance.',
    'daily', 65000, 3, 0, 'open', true, 'escrow',
    'CleanPro Services • Wilson Garden',
    extensions.ST_SetSRID(extensions.ST_MakePoint(77.5970, 12.9460), 4326)::extensions.geography,
    NOW() + INTERVAL '3 hours'
  ) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, status = 'open';

END $$;
