-- SQL Script: seed_demo.sql
-- Idempotent SQL seed for UdyogaSethu demo data matching exact table schemas 100%

DO $$
DECLARE
  v_admin UUID := '11111111-1111-4111-8111-111111111111';
  v_s1    UUID := '22222222-2222-4222-8222-222222222201';
  v_s2    UUID := '22222222-2222-4222-8222-222222222202';
  v_s3    UUID := '22222222-2222-4222-8222-222222222203';
  v_s4    UUID := '22222222-2222-4222-8222-222222222204';
  v_s5    UUID := '22222222-2222-4222-8222-222222222205';
  v_s6    UUID := '22222222-2222-4222-8222-222222222206';
  v_s7    UUID := '22222222-2222-4222-8222-222222222207';
  v_p1    UUID := '33333333-3333-4333-8333-333333333301';
  v_p2    UUID := '33333333-3333-4333-8333-333333333302';
  v_p3    UUID := '33333333-3333-4333-8333-333333333303';
  v_f1    UUID := '44444444-4444-4444-8444-444444444401';
  v_f2    UUID := '44444444-4444-4444-8444-444444444402';
  v_f3    UUID := '44444444-4444-4444-8444-444444444403';
  v_f4    UUID := '44444444-4444-4444-8444-444444444404';

  v_c_const UUID := 'a1111111-1111-4111-8111-111111111111';
  v_c_plumb UUID := 'a2222222-2222-4222-8222-222222222222';
  v_c_paint UUID := 'a3333333-3333-4333-8333-333333333333';
  v_c_deliv UUID := 'a4444444-4444-4444-8444-444444444444';
  v_c_elec  UUID := 'a5555555-5555-4555-8555-555555555555';
  v_c_carp  UUID := 'a6666666-6666-4666-8666-666666666666';
  v_c_mas   UUID := 'a7777777-7777-4777-8777-777777777777';
  v_c_clean UUID := 'a8888888-8888-4888-8888-888888888888';
  v_c_driv  UUID := 'a9999999-9999-4999-8999-999999999999';
  v_c_dom   UUID := 'b1111111-1111-4111-8111-111111111111';
  v_c_agri  UUID := 'b2222222-2222-4222-8222-222222222222';
  v_c_load  UUID := 'b3333333-3333-4333-8333-333333333333';

  v_j1 UUID := '55555555-5555-4555-8555-555555555501';
  v_j2 UUID := '55555555-5555-4555-8555-555555555502';
  v_j3 UUID := '55555555-5555-4555-8555-555555555503';
  v_j4 UUID := '55555555-5555-4555-8555-555555555504';
  v_j5 UUID := '55555555-5555-4555-8555-555555555505';
  v_j6 UUID := '55555555-5555-4555-8555-555555555506';
  v_j7 UUID := '55555555-5555-4555-8555-555555555507';
  v_j8 UUID := '55555555-5555-4555-8555-555555555508';
  v_j9 UUID := '55555555-5555-4555-8555-555555555509';
  v_j10 UUID := '55555555-5555-4555-8555-555555555510';
  v_j11 UUID := '55555555-5555-4555-8555-555555555511';
  v_j12 UUID := '55555555-5555-4555-8555-555555555512';
  v_j13 UUID := '55555555-5555-4555-8555-555555555513';
  v_j14 UUID := '55555555-5555-4555-8555-555555555514';

  v_as1 UUID := '66666666-6666-4666-8666-666666666601';

  v_w_s1 UUID; v_w_p3 UUID;
  v_seed_demo_jobs BOOLEAN := true; -- Enabled for presentation demo listings
BEGIN
  -- 1. Create tracking table demo_users
  CREATE TABLE IF NOT EXISTS public.demo_users (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    phone TEXT UNIQUE,
    role TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );

  -- 2. Seed Auth Users
  INSERT INTO auth.users (id, phone, phone_confirmed_at, email, instance_id, aud, role, encrypted_password) VALUES
    (v_admin, '+919900000001', NOW(), 'admin@udyogasethu.org', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_s1,    '+919900000101', NOW(), 'ramesh@test.com',      '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_s2,    '+919900000102', NOW(), 'sunita@test.com',      '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_s3,    '+919900000103', NOW(), 'manju@test.com',       '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_s4,    '+919900000104', NOW(), 'ananya@test.com',      '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_s5,    '+919900000105', NOW(), 'praveen@test.com',     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_s6,    '+919900000106', NOW(), 'syed@test.com',        '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_s7,    '+919900000107', NOW(), 'lakshmi@test.com',     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_p1,    '+919900000201', NOW(), 'anand@test.com',       '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_p2,    '+919900000202', NOW(), 'meera@test.com',       '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_p3,    '+919900000203', NOW(), 'suresh@test.com',      '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_f1,    '+919900000301', NOW(), 'gowda@test.com',       '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_f2,    '+919900000302', NOW(), 'venkatesh@test.com',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_f3,    '+919900000303', NOW(), 'ramakrishna@test.com', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf'))),
    (v_f4,    '+919900000304', NOW(), 'nagaraj@test.com',     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', extensions.crypt('Password123!', extensions.gen_salt('bf')))
  ON CONFLICT (id) DO UPDATE SET phone = EXCLUDED.phone;

  -- 3. Seed Profiles around Bengaluru
  INSERT INTO public.profiles (id, full_name, phone, email, active_role, onboarding_complete, home_location, home_address, city, state, pincode, language) VALUES
    (v_admin, 'UdyogaSethu System Admin', '+919900000001', 'admin@udyogasethu.org', 'admin', true, 'POINT(77.6245 12.9352)'::geography, '80 Feet Road, Koramangala', 'Bengaluru', 'Karnataka', '560095', 'en'),
    (v_s1,    'Ramesh Kumar',       '+919900000101', 'ramesh@test.com',      'seeker',   true, 'POINT(77.6245 12.9352)'::geography, 'Koramangala 4th Block', 'Bengaluru', 'Karnataka', '560034', 'kn'),
    (v_s2,    'Sunita Devi',        '+919900000102', 'sunita@test.com',      'seeker',   true, 'POINT(77.5938 12.9250)'::geography, 'Jayanagar 3rd Block', 'Bengaluru', 'Karnataka', '560011', 'hi'),
    (v_s3,    'Manjunath B',        '+919900000103', 'manju@test.com',       'seeker',   true, 'POINT(77.6446 12.9121)'::geography, 'HSR Layout Sector 2', 'Bengaluru', 'Karnataka', '560102', 'kn'),
    (v_s4,    'Ananya Rao',         '+919900000104', 'ananya@test.com',      'seeker',   true, 'POINT(77.6408 12.9784)'::geography, '100 Feet Road, Indiranagar', 'Bengaluru', 'Karnataka', '560038', 'en'),
    (v_s5,    'Praveen Teja',       '+919900000105', 'praveen@test.com',     'seeker',   true, 'POINT(77.6245 12.9352)'::geography, 'Koramangala 1st Block', 'Bengaluru', 'Karnataka', '560034', 'te'),
    (v_s6,    'Syed Imran',         '+919900000106', 'syed@test.com',        'seeker',   true, 'POINT(77.7127 13.2483)'::geography, 'Main Road, Devanahalli', 'Bengaluru Rural', 'Karnataka', '562110', 'en'),
    (v_s7,    'Lakshmi K',          '+919900000107', 'lakshmi@test.com',     'seeker',   true, 'POINT(77.5963 13.1007)'::geography, 'NES Office Circle, Yelahanka', 'Bengaluru', 'Karnataka', '560064', 'ta'),
    (v_p1,    'Dr. Anand Sharma',   '+919900000201', 'anand@test.com',       'provider', true, 'POINT(77.5938 12.9250)'::geography, 'Jayanagar 4th Block', 'Bengaluru', 'Karnataka', '560041', 'en'),
    (v_p2,    'Meera Reddy',        '+919900000202', 'meera@test.com',       'provider', true, 'POINT(77.6245 12.9352)'::geography, 'Koramangala 5th Block', 'Bengaluru', 'Karnataka', '560095', 'kn'),
    (v_p3,    'Suresh Sai',         '+919900000203', 'suresh@test.com',      'provider', true, 'POINT(77.6446 12.9121)'::geography, 'HSR Layout Sector 1', 'Bengaluru', 'Karnataka', '560102', 'en'),
    (v_f1,    'Gowda Farmer',       '+919900000301', 'gowda@test.com',       'farmer',   true, 'POINT(77.7127 13.2483)'::geography, 'Devanahalli Farm Sector', 'Bengaluru Rural', 'Karnataka', '562110', 'kn'),
    (v_f2,    'Venkatesh K',        '+919900000302', 'venkatesh@test.com',   'farmer',   true, 'POINT(77.5963 13.1007)'::geography, 'Yelahanka Dairy Circle', 'Bengaluru', 'Karnataka', '560064', 'kn'),
    (v_f3,    'Ramakrishnappa',     '+919900000303', 'ramakrishna@test.com', 'farmer',   true, 'POINT(77.7981 13.0722)'::geography, 'Hoskote Town Market', 'Bengaluru Rural', 'Karnataka', '562114', 'kn'),
    (v_f4,    'Nagaraj M',          '+919900000304', 'nagaraj@test.com',     'farmer',   true, 'POINT(77.5401 13.2927)'::geography, 'Doddaballapura Town', 'Bengaluru Rural', 'Karnataka', '561203', 'kn')
  ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, active_role = EXCLUDED.active_role;

  -- Record in demo_users tracking table
  INSERT INTO public.demo_users (user_id, phone, role) VALUES
    (v_admin, '+919900000001', 'admin'),
    (v_s1,    '+919900000101', 'seeker'),
    (v_s2,    '+919900000102', 'seeker'),
    (v_s3,    '+919900000103', 'seeker'),
    (v_s4,    '+919900000104', 'seeker'),
    (v_s5,    '+919900000105', 'seeker'),
    (v_s6,    '+919900000106', 'seeker'),
    (v_s7,    '+919900000107', 'seeker'),
    (v_p1,    '+919900000201', 'provider'),
    (v_p2,    '+919900000202', 'provider'),
    (v_p3,    '+919900000203', 'provider'),
    (v_f1,    '+919900000301', 'farmer'),
    (v_f2,    '+919900000302', 'farmer'),
    (v_f3,    '+919900000303', 'farmer'),
    (v_f4,    '+919900000304', 'farmer')
  ON CONFLICT (user_id) DO NOTHING;

  -- Seed User Roles
  INSERT INTO public.user_roles (user_id, role, is_primary) VALUES
    (v_admin, 'admin', true),
    (v_s1, 'seeker', true), (v_s2, 'seeker', true), (v_s3, 'seeker', true),
    (v_s4, 'seeker', true), (v_s5, 'seeker', true), (v_s6, 'seeker', true), (v_s7, 'seeker', true),
    (v_p1, 'provider', true), (v_p2, 'provider', true), (v_p3, 'provider', true),
    (v_f1, 'farmer', true), (v_f2, 'farmer', true), (v_f3, 'farmer', true), (v_f4, 'farmer', true)
  ON CONFLICT (user_id, role) DO NOTHING;

  -- Seed Worker Profiles
  INSERT INTO public.worker_profiles (user_id, seeker_type, headline, bio, experience_years, daily_rate_paise, availability, rating_avg, rating_count, jobs_completed, is_verified_badge) VALUES
    (v_s1, 'informal',  'Skilled Construction & Masonry Helper', '10+ years experience in masonry, concreting and site supervision.', 10, 120000, 'available', 4.9, 18, 18, true),
    (v_s2, 'informal',  'Experienced Domestic Help & House Cleaner', 'Punctual, thorough domestic helper trusted by Jayanagar families.', 6, 75000, 'available', 4.8, 12, 12, false),
    (v_s3, 'informal',  'General Helper & Material Loader', 'Reliable site loader and material assistant for HSR construction sites.', 3, 70000, 'available', 4.5, 5, 5, false),
    (v_s4, 'student',   'Part-Time Delivery & Event Assistant', 'Engineering student seeking weekend delivery and event support work.', 1, 60000, 'available', 4.7, 8, 8, false),
    (v_s5, 'student',   'Retail & Store Assistant', 'Degree student looking for part-time evening retail shifts in Koramangala.', 1, 55000, 'available', 4.6, 3, 3, false),
    (v_s6, 'part_time', 'Professional Commercial & Light Vehicle Driver', 'Licensed driver (LMV & Transport) available for airport & logistics runs.', 8, 90000, 'available', 4.9, 24, 24, true),
    (v_s7, 'part_time', 'Agri & Nursery Care Assistant', 'Part-time garden maintenance, plant nursery care and green house helper.', 4, 65000, 'available', 4.8, 14, 14, false)
  ON CONFLICT (user_id) DO UPDATE SET seeker_type = EXCLUDED.seeker_type, rating_avg = EXCLUDED.rating_avg;

  -- Seed KYC Records
  INSERT INTO public.kyc_records (user_id, doc_type, provider, status, masked_id, verified_at) VALUES
    (v_s1, 'aadhaar', 'digilocker', 'verified', 'XXXX-XXXX-9812', NOW() - INTERVAL '30 days'),
    (v_s2, 'aadhaar', 'digilocker', 'verified', 'XXXX-XXXX-4512', NOW() - INTERVAL '20 days'),
    (v_s4, 'aadhaar', 'digilocker', 'verified', 'XXXX-XXXX-3341', NOW() - INTERVAL '15 days'),
    (v_s6, 'aadhaar', 'digilocker', 'verified', 'XXXX-XXXX-7789', NOW() - INTERVAL '40 days'),
    (v_s6, 'driving_licence', 'transport_dept', 'verified', 'KA-04-DL-XXXXX', NOW() - INTERVAL '35 days'),
    (v_s7, 'aadhaar', 'digilocker', 'verified', 'XXXX-XXXX-1123', NOW() - INTERVAL '10 days')
  ON CONFLICT DO NOTHING;

  -- Seed Provider Profiles
  INSERT INTO public.provider_profiles (user_id, provider_type, org_name, rating_avg, rating_count) VALUES
    (v_p1, 'household', 'Sharma Residence', 4.9, 6),
    (v_p2, 'household', 'Reddy Villa', 4.8, 4),
    (v_p3, 'employer',  'Sai Electricals & Sharma Builders', 4.9, 15)
  ON CONFLICT (user_id) DO UPDATE SET org_name = EXCLUDED.org_name;

  -- Seed Farmer Profiles
  INSERT INTO public.farmer_profiles (user_id, acres, primary_crops, rating_avg, rating_count) VALUES
    (v_f1, 8.0, ARRAY['Tomatoes', 'Mangoes', 'Vegetables'], 4.9, 10),
    (v_f2, 5.0, ARRAY['Dairy Milk', 'Coconuts'], 4.8, 8),
    (v_f3, 12.0, ARRAY['Paddy', 'Sugarcane', 'Vegetables'], 4.7, 12),
    (v_f4, 6.0, ARRAY['Banana', 'Cardamom'], 4.9, 9)
  ON CONFLICT (user_id) DO UPDATE SET acres = EXCLUDED.acres;

  -- 4. Seed 12 Service Categories & Skills
  INSERT INTO public.service_categories (id, slug, icon, sort, names) VALUES
    (v_c_const, 'construction',  'construction', 1,  '{"en":"Construction", "kn":"ನಿರ್ಮಾಣ", "hi":"निर्माण", "te":"నిర్మాణం", "ta":"கட்டுமானம்"}'::jsonb),
    (v_c_plumb, 'plumbing',      'plumbing',     2,  '{"en":"Plumbing", "kn":"ಪ್ಲಂಬಿಂಗ್", "hi":"प्लंबिंग", "te":"ಪ್ಲಂಬಿಂಗ್", "ta":"பிளம்பிங்"}'::jsonb),
    (v_c_paint, 'painting',      'format_paint', 3,  '{"en":"Painting", "kn":"ಪೇಂಟಿಂಗ್", "hi":"पेंटिंग", "te":"പെയിന്റിംഗ്", "ta":"பெயிண்டிங்"}'::jsonb),
    (v_c_deliv, 'delivery',      'local_shipping',4, '{"en":"Delivery", "kn":"ಡೆಲಿವರಿ", "hi":"डिलीवरी", "te":"ಡೆಲಿವರೀ", "ta":"டெலிவரி"}'::jsonb),
    (v_c_elec,  'electrician',   'electrical_services', 5, '{"en":"Electrician", "kn":"ಎಲೆಕ್ಟ್ರಿಷಿಯನ್", "hi":"इलेक्ट्रिशियन", "te":"ఎలక్ట్రీషియన్", "ta":"மின்சார நிபுணர்"}'::jsonb),
    (v_c_carp,  'carpenter',     'carpenter',    6,  '{"en":"Carpenter", "kn":"ಕಾರ್ಪೆಂಟರ್", "hi":"कारपेंटर", "te":"కార్పెంటర్", "ta":"தச்சர்"}'::jsonb),
    (v_c_mas,   'mason',         'handyman',     7,  '{"en":"Mason", "kn":"ಮೇಸನ್", "hi":"राजमिस्त्री", "te":"మేసన్", "ta":"கொத்தனார்"}'::jsonb),
    (v_c_clean, 'cleaner',       'cleaning_services', 8, '{"en":"Cleaner", "kn":"ಕ್ಲೀನರ್", "hi":"सफाईवाला", "te":"ಕ್ಲೀನರ್", "ta":"துப்புரவாளர்"}'::jsonb),
    (v_c_driv,  'driver',        'directions_car', 9, '{"en":"Driver", "kn":"ಡ್ರೈವರ್", "hi":"ड्राइवर", "te":"డ్రైవర్", "ta":"ஓட்டுநர்"}'::jsonb),
    (v_c_dom,   'domestic_help', 'house',        10, '{"en":"Domestic Help", "kn":"ಮನೆ ಕೆಲಸ", "hi":"घरेलू सहायिका", "te":"ಇంటి పని", "ta":"வீட்டு உதவி"}'::jsonb),
    (v_c_agri,  'agri_labour',   'agriculture',  11, '{"en":"Agri Labour", "kn":"ಕೃಷಿ ಕಾರ್ಮಿಕ", "hi":"कृषि मजदूर", "te":"వ్యవసాయ ಕೂಲೀ", "ta":"விவசாய தொழிலாளி"}'::jsonb),
    (v_c_load,  'loader',        'inventory_2',  12, '{"en":"Loader", "kn":"ಲೋಡರ್", "hi":"लोडर", "te":"ಲೋಡರ್", "ta":"சுமை தூக்குಬವರ್"}'::jsonb)
  ON CONFLICT (id) DO UPDATE SET names = EXCLUDED.names;

  -- 5. Seed Open Jobs (Only created if v_seed_demo_jobs is explicitly true; flagged as is_demo = true)
  IF v_seed_demo_jobs THEN
    INSERT INTO public.jobs (id, provider_id, category_id, title, description, wage_type, wage_paise, est_duration_minutes, start_at, slots_total, slots_filled, materials_provided, payment_mode, location, address_text, suitable_for, is_demo, status) VALUES
      (v_j1,  v_p3, v_c_elec,  'Commercial Electrician Helper', 'Sai Electricals requires an experienced electrician for wiring installation at HSR commercial complex.', 'daily', 88000, 480, NOW() + INTERVAL '1 day', 2, 0, true, 'escrow', 'POINT(77.6446 12.9121)'::geography, 'Sai Electricals Shop 12, HSR Sector 1', ARRAY['informal']::public.seeker_type[], true, 'open'),
      (v_j2,  v_p3, v_c_const, 'Construction Site Helper & Mixer', 'Sharma Builders site helper needed for concrete mixing and material transport at Koramangala site.', 'daily', 70000, 480, NOW() + INTERVAL '1 day', 4, 1, true, 'escrow', 'POINT(77.6245 12.9352)'::geography, 'Sharma Builders Site #45, Koramangala 4th Block', ARRAY['informal', 'part_time']::public.seeker_type[], true, 'open'),
      (v_j3,  v_p1, v_c_plumb, 'Residential Plumbing & Pipe Repair', 'Dr. Anand Sharma residence needs leak repair and bathroom fixture installation.', 'daily', 90000, 360, NOW() + INTERVAL '2 days', 1, 0, false, 'escrow', 'POINT(77.5938 12.9250)'::geography, 'Residence #102, 4th Main, Jayanagar 4th Block', ARRAY['informal']::public.seeker_type[], true, 'open'),
      (v_j4,  v_p2, v_c_paint, 'Interior Wall Painting Assistant', 'Reddy Villa interior painting assistant needed for 2-day home refresh project.', 'daily', 80000, 480, NOW() + INTERVAL '3 days', 2, 0, true, 'escrow', 'POINT(77.6245 12.9352)'::geography, 'Reddy Villa #88, 5th Block, Koramangala', ARRAY['informal']::public.seeker_type[], true, 'open'),
      (v_j5,  v_p3, v_c_deliv, 'E-Commerce Parcel Delivery Executive', 'Express delivery assistant required for local parcel dispatch and package sorting in Koramangala.', 'daily', 70000, 480, NOW() + INTERVAL '1 day', 3, 1, true, 'upi', 'POINT(77.6245 12.9352)'::geography, 'Express Hub, 80 Feet Road, Koramangala', ARRAY['informal', 'student', 'part_time']::public.seeker_type[], true, 'open'),
      (v_j6,  v_p2, v_c_clean, 'Apartment Deep Cleaning Helper', 'CleanPro Services requires 2 cleaners for post-renovation 3BHK flat deep cleaning.', 'daily', 65000, 360, NOW() + INTERVAL '1 day', 2, 0, true, 'escrow', 'POINT(77.6408 12.9784)'::geography, 'Sobha Sunbeam, 100 Feet Road, Indiranagar', ARRAY['informal', 'part_time']::public.seeker_type[], true, 'open'),
      (v_j7,  v_p1, v_c_dom,   'Weekend Event Assistant Cook & Prep', 'Anand Catering needs assistant cook for family gathering. Vegetable chopping and food counter maintenance.', 'daily', 100000, 480, NOW() + INTERVAL '2 days', 2, 0, true, 'escrow', 'POINT(77.6280 12.9300)'::geography, 'Anand Party Hall, 12th Main, Koramangala 3rd Block', ARRAY['informal', 'part_time']::public.seeker_type[], true, 'open'),
      (v_j8,  v_f1, v_c_agri,  'Tomato Harvesting & Crate Sorting', 'Gowda Organic Farms requires farm workers for picking ripe tomatoes and packing into wooden crates.', 'daily', 65000, 420, NOW() + INTERVAL '1 day', 5, 1, true, 'escrow', 'POINT(77.7127 13.2483)'::geography, 'Gowda Farms Survey #42, Devanahalli Rural', ARRAY['informal']::public.seeker_type[], true, 'open'),
      (v_j9,  v_f3, v_c_agri,  'Drip Irrigation Pipeline Laying', 'Assistance required for unrolling drip tubes and connecting sub-main valve pipes across 4-acre field.', 'daily', 70000, 480, NOW() + INTERVAL '2 days', 3, 0, true, 'escrow', 'POINT(77.7981 13.0722)'::geography, 'Ramakrishnappa Agro Field, NH-75, Hoskote', ARRAY['informal']::public.seeker_type[], true, 'open'),
      (v_j10, v_p3, v_c_driv,  'Part-Time Pickup Van Driver (LMV)', 'Driver needed for morning goods transport (Tata Ace) between city wholesale mandi and local distribution.', 'daily', 85000, 360, NOW() + INTERVAL '1 day', 1, 0, true, 'escrow', 'POINT(77.5963 13.1007)'::geography, 'Major Unnikrishnan Road, Yelahanka', ARRAY['informal', 'part_time']::public.seeker_type[], true, 'open'),
      (v_j11, v_p1, v_c_dom,   'Supermarket Inventory & Billing Assistant', 'Supermarket shelf stocking, barcode scanning, and customer checkout assistance.', 'daily', 60000, 420, NOW() + INTERVAL '1 day', 2, 0, true, 'escrow', 'POINT(77.5938 12.9250)'::geography, 'Anand Supermart, 9th Main, Jayanagar 4th Block', ARRAY['student', 'part_time']::public.seeker_type[], true, 'open'),
      (v_j12, v_p3, v_c_load,  'Warehouse Goods Loading & Stacking', 'Daily wage loaders required for unloading FMCG shipment trucks and stacking cartons on pallets.', 'daily', 75000, 480, NOW() + INTERVAL '1 day', 6, 2, true, 'escrow', 'POINT(77.5650 12.9650)'::geography, 'Binny Mill Goods Shed, Binny Mill Road', ARRAY['informal']::public.seeker_type[], true, 'open'),
      (v_j13, v_p2, v_c_dom,   'Morning Housekeeping & Kitchen Helper', 'Morning 3-hour household assistance: floor mopping, kitchen vessel cleaning, and dusting.', 'daily', 40000, 180, NOW() + INTERVAL '1 day', 1, 0, true, 'escrow', 'POINT(77.6446 12.9121)'::geography, 'Apartment #204, 19th Main, HSR Layout Sector 2', ARRAY['informal', 'part_time']::public.seeker_type[], true, 'open'),
      (v_j14, v_p1, v_c_deliv, 'Evening Pharmacy Medicine Home Delivery', 'Local medicine delivery within 4km radius of clinic. Bicycle or two-wheeler required.', 'daily', 50000, 240, NOW() + INTERVAL '1 day', 2, 0, true, 'upi', 'POINT(77.5938 12.9250)'::geography, 'Sharma Medicos, 11th Main, Jayanagar 3rd Block', ARRAY['student', 'part_time']::public.seeker_type[], true, 'open')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, wage_paise = EXCLUDED.wage_paise, is_demo = true;
  END IF;

  -- 6. Seed Produce Listings (Prices in paise)
  INSERT INTO public.produce_listings (id, farmer_id, name, category, description, price_paise, unit, stock_qty, status, location) VALUES
    ('77777777-7777-4777-8777-777777777701', v_f1, 'Fresh Organic Tomatoes', 'vegetable', 'Farm-fresh organic red tomatoes.', 3400, 'kg', 500.0, 'active', 'POINT(77.7127 13.2483)'::geography),
    ('77777777-7777-4777-8777-777777777702', v_f2, 'Pure A2 Desi Cow Milk', 'dairy', 'Pure raw A2 cow milk from free-range cows.', 6000, 'litre', 150.0, 'active', 'POINT(77.5963 13.1007)'::geography),
    ('77777777-7777-4777-8777-777777777703', v_f1, 'Fresh Alphonso Mangoes', 'fruit', 'Naturally ripened Alphonso mangoes.', 12000, 'kg', 300.0, 'active', 'POINT(77.7127 13.2483)'::geography),
    ('77777777-7777-4777-8777-777777777704', v_f2, 'Fresh Tender Coconuts', 'fruit', 'Sweet electrolyte tender coconuts.', 4000, 'piece', 200.0, 'active', 'POINT(77.5963 13.1007)'::geography),
    ('77777777-7777-4777-8777-777777777705', v_f3, 'Weekly Organic Vegetable Basket', 'vegetable', 'Assorted organic seasonal vegetables.', 35000, 'box', 50.0, 'active', 'POINT(77.7981 13.0722)'::geography)
  ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, price_paise = EXCLUDED.price_paise;

  -- 7. Seed Resource Listings (Prices in paise)
  INSERT INTO public.resource_listings (id, owner_id, type, name, price_paise, unit, description, location, active) VALUES
    ('88888888-8888-4888-8888-888888888801', v_f3, 'tractor', 'Mahindra 575 Tractor with 9-Tyne Cultivator', 85000, 'hour', 'Tractor with cultivator for soil tilling.', 'POINT(77.7981 13.0722)'::geography, true),
    ('88888888-8888-4888-8888-888888888802', v_f3, 'harvester', 'Combine Paddy & Wheat Harvester', 140000, 'hour', 'Combine harvester for fast crop harvesting.', 'POINT(77.7981 13.0722)'::geography, true),
    ('88888888-8888-4888-8888-888888888803', v_f1, 'drone', 'Agricultural Spraying Drone Service', 45000, 'acre', 'Precision pesticide and fertilizer drone spraying.', 'POINT(77.7127 13.2483)'::geography, true),
    ('88888888-8888-4888-8888-888888888804', v_f1, 'fertilizer', 'Pure Organic Vermicompost Bag (50kg)', 45000, 'bag', 'High quality organic vermicompost.', 'POINT(77.7127 13.2483)'::geography, true)
  ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, price_paise = EXCLUDED.price_paise;

  -- 8. Seed Mandi Prices (Prices in paise)
  INSERT INTO public.mandi_prices (crop, variety, market, state, min_paise, modal_paise, max_paise, price_date) VALUES
    ('Tomato',    'Hybrid Local', 'Kolar Mandi',        'Karnataka', 3200, 3400, 3600, CURRENT_DATE),
    ('Onion',     'Medium Red',   'Yashwantpur Mandi', 'Karnataka', 2200, 2400, 2600, CURRENT_DATE),
    ('Paddy',     'Sona Masuri',  'Binny Mill Mandi',  'Karnataka', 2100, 2250, 2400, CURRENT_DATE),
    ('Sugarcane', 'High Yield',   'Chintamani Mandi',  'Karnataka', 3100, 3300, 3500, CURRENT_DATE),
    ('Banana',    'Robusta',      'Yashwantpur Mandi', 'Karnataka', 2800, 3100, 3400, CURRENT_DATE),
    ('Cardamom',  'Green Grade 1','Kolar Mandi',        'Karnataka', 180000, 200000, 220000, CURRENT_DATE)
  ON CONFLICT (crop, market, price_date) DO UPDATE SET modal_paise = EXCLUDED.modal_paise;

  -- 9. Seed Wage Benchmarks
  INSERT INTO public.wage_benchmarks (category_id, area, min_paise, max_paise, unit) VALUES
    (v_c_const, 'Bengaluru Urban', 65000, 90000, 'daily'),
    (v_c_elec,  'Bengaluru Urban', 80000, 120000, 'daily'),
    (v_c_plumb, 'Bengaluru Urban', 80000, 115000, 'daily'),
    (v_c_paint, 'Bengaluru Urban', 70000, 100000, 'daily'),
    (v_c_deliv, 'Bengaluru Urban', 55000, 80000, 'daily'),
    (v_c_agri,  'Bengaluru Rural', 55000, 75000, 'daily')
  ON CONFLICT DO NOTHING;

  -- 10. Seed Gamification Levels & Badges
  INSERT INTO public.levels (id, level_number, name, min_xp, perks) VALUES
    ('99999999-9999-4999-8999-999999999901', 1, 'Starter', 0, '{"cashback_pct": 1.0, "priority_matching": false}'::jsonb),
    ('99999999-9999-4999-8999-999999999902', 2, 'Reliable', 100, '{"cashback_pct": 2.0, "priority_matching": true}'::jsonb),
    ('99999999-9999-4999-8999-999999999903', 3, 'Trusted Pro', 300, '{"cashback_pct": 3.0, "priority_matching": true, "insurance_cover_paise": 10000000}'::jsonb),
    ('99999999-9999-4999-8999-999999999904', 4, 'Community Hero', 1000, '{"cashback_pct": 5.0, "priority_matching": true, "insurance_cover_paise": 25000000}'::jsonb)
  ON CONFLICT (id) DO UPDATE SET min_xp = EXCLUDED.min_xp;

  INSERT INTO public.badges (slug, names, criteria) VALUES
    ('safety_first',       '{"en":"Safety First", "kn":"ಸುರಕ್ಷತೆ ಪ್ರಥಮ"}'::jsonb, '{"training_completed": true}'::jsonb),
    ('punctual_worker',    '{"en":"Punctual Star", "kn":"ಸಮಯಪಾಲಕ"}'::jsonb, '{"on_time_ratio": 0.95}'::jsonb),
    ('top_rated',          '{"en":"Top Rated 5-Star", "kn":"ಅತ್ಯುತ್ತಮ ರೇಟಿಂಗ್"}'::jsonb, '{"min_rating": 4.8}'::jsonb),
    ('ekyc_verified',      '{"en":"Aadhaar Verified", "kn":"ಆಧಾರ್ ಪರಿಶೀಲಿಸಲಾಗಿದೆ"}'::jsonb, '{"kyc": true}'::jsonb),
    ('face_verified',      '{"en":"Face Verified Pro", "kn":"ಮುಖ ಪರಿಶೀಲಿಸಲಾಗಿದೆ"}'::jsonb, '{"liveness": true}'::jsonb),
    ('super_farmer',       '{"en":"Super Farmer", "kn":"ಸೂಪರ್ ರೈತ"}'::jsonb, '{"sales_count": 10}'::jsonb),
    ('group_buyer',        '{"en":"Group Order Leader", "kn":"ಗುಂಪು ಖರೀದಿ ನಾಯಕ"}'::jsonb, '{"group_orders": 3}'::jsonb),
    ('early_bird',         '{"en":"Early Bird Shift", "kn":"ಮುಂಜಾನೆಯ ಸೈನಿಕ"}'::jsonb, '{"morning_shifts": 5}'::jsonb),
    ('zero_cancellation',  '{"en":"Zero Cancellation", "kn":"ಶೂನ್ಯ ರದ್ಧತಿ"}'::jsonb, '{"cancel_rate": 0.0}'::jsonb),
    ('community_champion', '{"en":"Community Champion", "kn":"ಸಮುದಾಯ ಚಾಂಪಿಯನ್"}'::jsonb, '{"referrals": 5}'::jsonb),
    ('skill_master',       '{"en":"Certified Specialist", "kn":"ಪ್ರಮಾಣೀಕೃತ ತಜ್ಞ"}'::jsonb, '{"skills_verified": 3}'::jsonb),
    ('green_thumb',        '{"en":"Organic Organic Pro", "kn":"ಸಾವಯವ ತಜ್ಞ"}'::jsonb, '{"organic_certified": true}'::jsonb)
  ON CONFLICT (slug) DO UPDATE SET names = EXCLUDED.names;

  -- 11. Seed Reward Items
  INSERT INTO public.reward_items (names, points_cost, min_level, stock, active) VALUES
    ('{"en":"UdyogaSethu Safety T-Shirt", "kn":"ಸುರಕ್ಷತಾ ಟಿ-ಷರ್ಟ್"}'::jsonb, 500, 1, 100, true),
    ('{"en":"Branded Worker Cap", "kn":"ಉದ್ಯೋಗ ಸೇತು ಕ್ಯಾಪ್"}'::jsonb, 300, 1, 150, true),
    ('{"en":"Stainless Steel Water Bottle (1L)", "kn":"ಸ್ಟೀಲ್ ನೀರಿನ ಬಾಟಲಿ"}'::jsonb, 400, 2, 80, true),
    ('{"en":"Heavy Duty Tool Bag", "kn":"ಟೂಲ್ ಬ್ಯಾಗ್"}'::jsonb, 800, 3, 40, true),
    ('{"en":"UdyogaSethu Lanyard & ID Holder", "kn":"ಐಡಿ ಹೋಲ್ಡರ್"}'::jsonb, 150, 1, 200, true),
    ('{"en":"Safety Helmet & Reflective Sticker Pack", "kn":"ಸ್ಟಿಕರ್ ಪ್ಯಾಕ್"}'::jsonb, 100, 1, 300, true)
  ON CONFLICT DO NOTHING;

  -- 12. Seed Training Events
  INSERT INTO public.training_events (kind, title, description, starts_at, venue, capacity, language) VALUES
    ('safety_onboarding', 'Worksite Safety & PPE Onboarding Day', 'Hands-on training covering helmet usage, harness safety and emergency protocol.', NOW() + INTERVAL '5 days', 'Koramangala Community Centre, Bengaluru', 50, 'en'),
    ('workshop', 'Solar & Electrical Safety Workshop', 'Advanced training on residential solar inverter installation and safety groundings.', NOW() + INTERVAL '10 days', 'HSR Layout Skill Hub, Bengaluru', 30, 'en'),
    ('camp', 'Safe Handling of Agricultural Drones', 'Comprehensive training on pesticide spraying drone flight controls and battery safety.', NOW() + INTERVAL '12 days', 'Devanahalli Krishi Vigyan Kendra', 25, 'kn'),
    ('meetup', 'Digital Financial Literacy & UPI Security', 'Learn how to secure your UPI wallet, track daily earnings and start micro-savings.', NOW() + INTERVAL '15 days', 'Jayanagar Library Hall, Bengaluru', 100, 'kn')
  ON CONFLICT DO NOTHING;

  -- 13. Seed Learning Modules
  INSERT INTO public.learning_modules (slug, titles, category, content, quiz) VALUES
    ('demo-safety-guide', '{"en":"Basic Worksite Safety Guide", "kn":"ಮೂಲಭೂತ ಕೆಲಸದ ಸ್ಥಳದ ಸುರಕ್ಷತೆ"}'::jsonb, 'Safety', '{"video_url": "https://youtube.com/watch?v=demo_safety", "est_minutes": 10}'::jsonb, '{"questions": []}'::jsonb),
    ('demo-ekyc-guide', '{"en":"How to Get eKYC Verified Fast", "kn":"ಇ-ಕೆವೈಸಿ ಪರಿಶೀಲನೆ ಮಾರ್ಗದರ್ಶಿ"}'::jsonb, 'Trust', '{"url": "https://udyogasethu.org/guide/ekyc", "est_minutes": 5}'::jsonb, '{"questions": []}'::jsonb),
    ('demo-escrow-payouts', '{"en":"Understanding Escrow & Fast Payouts", "kn":"ಎಸ್ಕ್ರೋ ಪಾವತಿ ಮಾರ್ಗದರ್ಶಿ"}'::jsonb, 'Finance', '{"audio_url": "https://udyogasethu.org/guide/escrow.mp3", "est_minutes": 7}'::jsonb, '{"questions": []}'::jsonb),
    ('demo-drip-irrigation', '{"en":"Modern Drip Irrigation Essentials", "kn":"ಹನಿ ನೀರಾವರಿ ಮಾರ್ಗದರ್ಶಿ"}'::jsonb, 'Farming', '{"video_url": "https://youtube.com/watch?v=demo_drip", "est_minutes": 15}'::jsonb, '{"questions": []}'::jsonb),
    ('demo-customer-service', '{"en":"Customer Service Best Practices for Drivers", "kn":"ಚಾಲಕರ ಗ್ರಾಹಕ ಸೇವೆ"}'::jsonb, 'Skills', '{"quiz_url": "https://udyogasethu.org/quiz/driver", "est_minutes": 8}'::jsonb, '{"questions": []}'::jsonb),
    ('demo-rights-handbook', '{"en":"Emergency SOS & Worker Rights Handbook", "kn":"ಕಾರ್ಮಿಕರ ಹಕ್ಕುಗಳ ಕೈಪಿಡಿ"}'::jsonb, 'Rights', '{"url": "https://udyogasethu.org/guide/rights", "est_minutes": 10}'::jsonb, '{"questions": []}'::jsonb)
  ON CONFLICT (slug) DO UPDATE SET titles = EXCLUDED.titles;

  -- 14. Seed Sponsored Ad Banner
  INSERT INTO public.ad_banners (title, body, cta_label, image, target_role, sponsor_name, active) VALUES
    ('PM-KMY Farmer Pension & Machinery Subsidy 2026', 'Get up to 50% rental discount on agri drones and harvesters under PM-KMY scheme.', 'Apply Now', 'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=800', NULL, 'Ministry of Agriculture', true)
  ON CONFLICT DO NOTHING;

  -- 15. Seed Impact Stories
  INSERT INTO public.community_posts (author_id, kind, title, body, images, published) VALUES
    (v_s1, 'story', 'From Daily Wage Search to Guaranteed Escrow Jobs', 'Before UdyogaSethu, I spent 2 hours every morning waiting at labour chowks. Now, Ramesh receives direct bookings in Koramangala with verified daily wages deposited straight to escrow.', ARRAY['https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800'], true),
    (v_s2, 'story', 'Securing Domestic Work with Dignity & Safety', 'Sunita shares how eKYC verification helped her build trust with Jayanagar households, earning regular monthly income with built-in accident insurance.', ARRAY['https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800'], true)
  ON CONFLICT DO NOTHING;

  -- 16. Seed Completed Assignments, Reviews, Payments & Ledger Entries for realistic stats
  INSERT INTO public.jobs (id, provider_id, category_id, title, description, wage_type, wage_paise, est_duration_minutes, start_at, slots_total, slots_filled, status) VALUES
    ('55555555-5555-4555-8555-555555555510', v_p3, v_c_mas, 'Compound Wall Masonry Work', 'Completed wall repair at Sharma Builders site.', 'daily', 85000, 480, NOW() - INTERVAL '2 days', 1, 1, 'closed')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.job_assignments (id, job_id, worker_id, booking_code, agreed_wage_paise, status, started_at, ended_at, arrived_at, elapsed_seconds) VALUES
    (v_as1, '55555555-5555-4555-8555-555555555510', v_s1, 'BOOK-DEMO-001', 85000, 'payment_released', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '8 hours', NOW() - INTERVAL '2 days', 28800)
  ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status;

  INSERT INTO public.ratings_reviews (ref_type, ref_id, rater_id, target_id, stars, comment) VALUES
    ('assignment', v_as1, v_p3, v_s1, 5, 'Ramesh did an outstanding job on the wall masonry. Extremely punctual, neat alignment and very polite conduct!')
  ON CONFLICT (rater_id, ref_type, ref_id) DO NOTHING;

  -- Fund Ramesh and Suresh wallets with realistic ledger entries
  SELECT id INTO v_w_s1 FROM public.wallets WHERE user_id = v_s1;
  IF v_w_s1 IS NULL THEN INSERT INTO public.wallets (user_id) VALUES (v_s1) RETURNING id INTO v_w_s1; END IF;

  SELECT id INTO v_w_p3 FROM public.wallets WHERE user_id = v_p3;
  IF v_w_p3 IS NULL THEN INSERT INTO public.wallets (user_id) VALUES (v_p3) RETURNING id INTO v_w_p3; END IF;

  -- Ledger entries for completed earnings (idempotent keys)
  INSERT INTO public.ledger_entries (wallet_id, direction, amount_paise, bucket, ref_type, ref_id, idempotency_key, note) VALUES
    (v_w_s1, 'credit', 80750, 'available', 'assignment', v_as1, 'demo-seed-ledger-s1-credit', 'Payment released for completed job (5% fee deducted)'),
    (v_w_s1, 'credit', 50000, 'available', 'reward', NULL, 'demo-seed-ledger-s1-reward', 'Welcome Bonus Credited')
  ON CONFLICT (idempotency_key) DO NOTHING;

  RAISE NOTICE 'DEMO SEED COMPLETED SUCCESSFULLY!';
END $$;

SELECT 'DEMO SEED EXECUTED CLEANLY' AS status;
