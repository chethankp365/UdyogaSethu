-- supabase/dev/sample_jobs.sql
-- Seed script for realistic [TEST] jobs in Bengaluru.
-- 12 student-style jobs across 6 student categories and 8 trade jobs for informal workers.
-- DO NOT RUN AUTOMATICALLY (Developer execution only).

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.provider_profiles) THEN
    RAISE WARNING 'NO PROVIDER ACCOUNT EXISTS! Please ensure at least one provider account is created before running this script.';
  END IF;
END $$;

-- 1. Insert [TEST] Jobs using Parameters CTE
WITH params AS (
  SELECT 
    12.9352::DOUBLE PRECISION AS base_lat,
    77.6101::DOUBLE PRECISION AS base_lng,
    (SELECT user_id FROM public.provider_profiles LIMIT 1) AS provider_id
),
inserted_jobs AS (
  INSERT INTO public.jobs (
    id, provider_id, category_id, title, description,
    wage_type, wage_paise, est_duration_minutes, start_at,
    slots_total, slots_filled, payment_mode, materials_provided,
    requirements, location, address_text, status
  )
  SELECT
    j.id,
    p.provider_id,
    sc.id AS category_id,
    j.title,
    j.description,
    j.wage_type::public.wage_type,
    j.wage_paise,
    j.est_duration_minutes,
    NOW() + j.start_offset,
    j.slots_total,
    0,
    'escrow'::public.payment_mode,
    true,
    j.requirements,
    extensions.ST_SetSRID(extensions.ST_MakePoint(p.base_lng + j.lng_offset, p.base_lat + j.lat_offset), 4326)::extensions.geography,
    j.address_text,
    'open'::public.job_status
  FROM params p
  CROSS JOIN (
    VALUES
      -- 12 STUDENT & PART-TIME JOBS (6 categories x 2)
      -- Category: content-writing
      ('77777777-7777-4777-8777-777777770001'::UUID, 'content-writing', '[TEST] Campus Newsletter & Social Media Writer', 'Write articles and event recaps for student newsletter. Flexible remote writing.', 'hourly', 35000, 180, INTERVAL '3 hours', 2, '{"students_ok": true, "part_time_ok": true}'::jsonb, 0.005, 0.002, 'Koramangala 4th Block, Bengaluru'),
      ('77777777-7777-4777-8777-777777770002'::UUID, 'content-writing', '[TEST] English Proofreader & Transcript Editor', 'Review blog drafts and audio transcripts. Work from cafe or campus library.', 'hourly', 40000, 240, INTERVAL '1 day', 2, '{"students_ok": true, "part_time_ok": true}'::jsonb, -0.003, 0.006, 'Sony Signal, Koramangala, Bengaluru'),

      -- Category: design-data-work
      ('77777777-7777-4777-8777-777777770003'::UUID, 'design-data-work', '[TEST] Poster Designer & Presentation Creator', 'Design event flyers and clean pitch presentations. Laptop provided or bring own.', 'hourly', 50000, 180, INTERVAL '4 hours', 1, '{"students_ok": true, "part_time_ok": true}'::jsonb, 0.008, -0.004, 'HSR Layout Sector 1, Bengaluru'),
      ('77777777-7777-4777-8777-777777770004'::UUID, 'design-data-work', '[TEST] Excel Catalog & Data Entry Assistant', 'Format inventory sheets and digital product catalogs for local boutique.', 'hourly', 38000, 240, INTERVAL '5 hours', 2, '{"students_ok": true, "part_time_ok": true}'::jsonb, -0.006, -0.002, 'BTM Layout 2nd Stage, Bengaluru'),

      -- Category: tutoring-academics
      ('77777777-7777-4777-8777-777777770005'::UUID, 'tutoring-academics', '[TEST] High School Physics & Math Evening Tutor', 'Teach grade 9-10 science concepts to small batch of 3 students.', 'hourly', 55000, 120, INTERVAL '2 hours', 1, '{"students_ok": true, "part_time_ok": true}'::jsonb, 0.002, 0.008, 'Jayanagar 4th Block, Bengaluru'),
      ('77777777-7777-4777-8777-777777770006'::UUID, 'tutoring-academics', '[TEST] Primary School Homework Help & Reading Assistant', 'Assist 4th graders with homework and reading practice.', 'hourly', 42000, 150, INTERVAL '6 hours', 2, '{"students_ok": true, "part_time_ok": true}'::jsonb, -0.004, 0.009, 'Indiranagar 100ft Road, Bengaluru'),

      -- Category: campus-brand-promotion
      ('77777777-7777-4777-8777-777777770007'::UUID, 'campus-brand-promotion', '[TEST] Youth College Fest Brand Ambassador', 'Distribute merchandise and guide attendees at technology conference booth.', 'daily', 90000, 360, INTERVAL '1 day', 4, '{"students_ok": true, "part_time_ok": true}'::jsonb, 0.010, 0.001, 'Koramangala Indoor Stadium, Bengaluru'),
      ('77777777-7777-4777-8777-777777770008'::UUID, 'campus-brand-promotion', '[TEST] Mall Weekend Product Sampling Promoter', 'Explain organic snack samples to shoppers and hand out trial coupons.', 'hourly', 45000, 240, INTERVAL '2 days', 3, '{"students_ok": true, "part_time_ok": true}'::jsonb, -0.002, -0.008, 'Forum Mall, Koramangala, Bengaluru'),

      -- Category: retail-food-service
      ('77777777-7777-4777-8777-777777770009'::UUID, 'retail-food-service', '[TEST] Evening Coffee Barista & Cashier', 'Prepare espresso beverages and manage billing counter during peak rush.', 'hourly', 40000, 240, INTERVAL '3 hours', 2, '{"students_ok": true, "part_time_ok": true}'::jsonb, 0.003, -0.005, 'Third Wave Coffee • Koramangala 5th Block'),
      ('77777777-7777-4777-8777-777777770010'::UUID, 'retail-food-service', '[TEST] Book Cafe Weekend Floor Assistant', 'Stack bookshelf displays, welcome visitors, and assist beverage service.', 'hourly', 38000, 300, INTERVAL '1 day', 2, '{"students_ok": true, "part_time_ok": true}'::jsonb, -0.007, 0.004, 'Atta Galatta • Indiranagar, Bengaluru'),

      -- Category: delivery-gig-work
      ('77777777-7777-4777-8777-777777770011'::UUID, 'delivery-gig-work', '[TEST] Evening Local Parcel & Document Rider', 'Deliver documents and lightweight packets between Koramangala and HSR.', 'hourly', 46000, 180, INTERVAL '2 hours', 3, '{"students_ok": true, "part_time_ok": true}'::jsonb, 0.006, -0.002, 'Silk Board Junction Hub, Bengaluru'),
      ('77777777-7777-4777-8777-777777770012'::UUID, 'delivery-gig-work', '[TEST] Campus Food Delivery Courier', 'Deliver lunch orders from campus canteen to department blocks. Bicycle friendly.', 'hourly', 42000, 180, INTERVAL '4 hours', 4, '{"students_ok": true, "part_time_ok": true}'::jsonb, -0.001, 0.007, 'St Johns Campus, Bengaluru'),

      -- 8 TRADE JOBS FOR INFORMAL WORKERS
      ('77777777-7777-4777-8777-777777770013'::UUID, 'electrician', '[TEST] Commercial Electrician - Breaker Wiring', 'Single-phase to three-phase panel wiring and conduit laying at new bakery.', 'daily', 88000, 480, INTERVAL '1 hour', 2, '{}'::jsonb, 0.004, 0.001, 'Koramangala 6th Block, Bengaluru'),
      ('77777777-7777-4777-8777-777777770014'::UUID, 'plumber', '[TEST] Master Plumber - Bathroom Fitting', 'Fixing overhead tank pipeline and installing sanitary wash fixtures.', 'daily', 85000, 480, INTERVAL '2 hours', 1, '{}'::jsonb, -0.005, -0.003, 'Tavarekere Main Road, Bengaluru'),
      ('77777777-7777-4777-8777-777777770015'::UUID, 'carpenter', '[TEST] Carpenter - Plywood Wardrobe Assembly', 'Edge banding, drawer channel fitting, and wardrobe door hinge alignment.', 'daily', 92000, 480, INTERVAL '3 hours', 2, '{}'::jsonb, 0.009, 0.003, 'HSR Layout Sector 4, Bengaluru'),
      ('77777777-7777-4777-8777-777777770016'::UUID, 'mason', '[TEST] Mason & Tile Layer - Granite Flooring', 'Granite slab leveling, cement base laying, and epoxy joint filling.', 'daily', 95000, 480, INTERVAL '1 day', 3, '{}'::jsonb, -0.008, 0.002, 'Wilson Garden, Bengaluru'),
      ('77777777-7777-4777-8777-777777770017'::UUID, 'painting', '[TEST] Wall Painter - Emulsion Two-Coat Finish', 'Wall putty sanding, primer coating, and premium acrylic emulsion roll.', 'daily', 82000, 480, INTERVAL '4 hours', 2, '{}'::jsonb, 0.001, -0.007, 'BTM 1st Stage, Bengaluru'),
      ('77777777-7777-4777-8777-777777770018'::UUID, 'construction', '[TEST] Construction Helper - Concrete Mixing', 'Assisting RCC roof casting crew, sand shifting, and water curing.', 'daily', 72000, 480, INTERVAL '2 hours', 5, '{}'::jsonb, -0.003, -0.005, 'Ejipura Main Road, Bengaluru'),
      ('77777777-7777-4777-8777-777777770019'::UUID, 'cleaner', '[TEST] Deep Cleaning Worker - Post-Tenancy Scrub', 'Machine floor scrubbing, kitchen tile degreasing, and balcony wash.', 'daily', 68000, 420, INTERVAL '3 hours', 2, '{}'::jsonb, 0.005, 0.005, 'Indiranagar 12th Main, Bengaluru'),
      ('77777777-7777-4777-8777-777777770020'::UUID, 'loader', '[TEST] Warehouse Loading Partner - Carton Logistics', 'Unloading FMCG corrugated cartons from 14ft container truck.', 'daily', 75000, 480, INTERVAL '1 hour', 4, '{}'::jsonb, 0.012, -0.001, 'Domlur Intermediate Ring Road, Bengaluru')
  ) AS j(id, cat_slug, title, description, wage_type, wage_paise, est_duration_minutes, start_offset, slots_total, requirements, lng_offset, lat_offset, address_text)
  JOIN public.service_categories sc ON sc.slug = j.cat_slug
  WHERE p.provider_id IS NOT NULL
  ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    wage_paise = EXCLUDED.wage_paise,
    status = 'open'
)
SELECT 'Inserted/Updated test jobs successfully' AS status;

-- 2. Insert Sample ad_banners row for skill-training scheme
INSERT INTO public.ad_banners (
  id,
  title,
  body,
  cta_label,
  target_role,
  sponsor_name,
  why_text,
  active
)
VALUES (
  '88888888-8888-4888-8888-888888880001',
  '[TEST] PMKVY 4.0 Free Skill Certification Scheme',
  'Government-certified short courses in EV maintenance, digital cataloguing, and advanced plumbing with stipend.',
  'Explore Courses',
  'seeker',
  'National Skill Development Corporation (NSDC)',
  'You are seeing this sponsored skill initiative because you are registered as a verified worker on UdyogaSethu. Free government schemes are shown to all member categories.',
  true
)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  body = EXCLUDED.body,
  active = true;

-- 3. Verification Query: Count open jobs per category and audience
SELECT 
  sc.slug AS category_slug,
  sc.audience,
  COUNT(j.id) AS open_jobs_count
FROM public.service_categories sc
LEFT JOIN public.jobs j ON j.category_id = sc.id AND j.status = 'open'
GROUP BY sc.slug, sc.audience
ORDER BY sc.audience, sc.slug;
