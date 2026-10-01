-- SQL Script: reset_demo.sql
-- Safely resets all demo users and content created by seed_demo.ts

DO $$
BEGIN
  -- 1. Create demo_users tracking table if missing
  CREATE TABLE IF NOT EXISTS public.demo_users (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    phone TEXT UNIQUE,
    role TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );

  -- 2. Delete demo assignment events
  DELETE FROM public.assignment_events
  WHERE assignment_id IN (
    SELECT id FROM public.job_assignments
    WHERE worker_id IN (SELECT user_id FROM public.demo_users)
       OR job_id IN (SELECT id FROM public.jobs WHERE provider_id IN (SELECT user_id FROM public.demo_users))
  );

  -- 3. Delete ratings and reviews involving demo users
  DELETE FROM public.ratings_reviews
  WHERE rater_id IN (SELECT user_id FROM public.demo_users)
     OR target_id IN (SELECT user_id FROM public.demo_users);

  -- 4. Delete payments involving demo users
  DELETE FROM public.payments
  WHERE payer_id IN (SELECT user_id FROM public.demo_users)
     OR payee_id IN (SELECT user_id FROM public.demo_users);

  -- 5. Delete job assignments
  DELETE FROM public.job_assignments
  WHERE worker_id IN (SELECT user_id FROM public.demo_users)
     OR job_id IN (SELECT id FROM public.jobs WHERE provider_id IN (SELECT user_id FROM public.demo_users));

  -- 6. Delete job applications
  DELETE FROM public.job_applications
  WHERE worker_id IN (SELECT user_id FROM public.demo_users)
     OR job_id IN (SELECT id FROM public.jobs WHERE provider_id IN (SELECT user_id FROM public.demo_users));

  -- 7. Delete jobs posted by demo providers
  DELETE FROM public.jobs
  WHERE provider_id IN (SELECT user_id FROM public.demo_users);

  -- 8. Delete produce listings & resource listings
  DELETE FROM public.produce_listings WHERE farmer_id IN (SELECT user_id FROM public.demo_users);
  DELETE FROM public.resource_listings WHERE owner_id IN (SELECT user_id FROM public.demo_users);

  -- 9. Delete community posts
  DELETE FROM public.community_posts WHERE author_id IN (SELECT user_id FROM public.demo_users);

  -- 10. Disable ledger mutation trigger temporarily for clean demo teardown
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_prevent_ledger_mutation') THEN
    ALTER TABLE public.ledger_entries DISABLE TRIGGER trg_prevent_ledger_mutation;
  END IF;

  DELETE FROM public.ledger_entries
  WHERE wallet_id IN (SELECT id FROM public.wallets WHERE user_id IN (SELECT user_id FROM public.demo_users));

  DELETE FROM public.wallets
  WHERE user_id IN (SELECT user_id FROM public.demo_users);

  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_prevent_ledger_mutation') THEN
    ALTER TABLE public.ledger_entries ENABLE TRIGGER trg_prevent_ledger_mutation;
  END IF;

  -- 11. Delete role-specific profiles, verification records & roles
  DELETE FROM public.worker_profiles WHERE user_id IN (SELECT user_id FROM public.demo_users);
  DELETE FROM public.provider_profiles WHERE user_id IN (SELECT user_id FROM public.demo_users);
  DELETE FROM public.farmer_profiles WHERE user_id IN (SELECT user_id FROM public.demo_users);
  DELETE FROM public.user_roles WHERE user_id IN (SELECT user_id FROM public.demo_users);
  DELETE FROM public.kyc_records WHERE user_id IN (SELECT user_id FROM public.demo_users);
  DELETE FROM public.face_profiles WHERE user_id IN (SELECT user_id FROM public.demo_users);

  -- 12. Delete profiles and auth users
  DELETE FROM public.profiles WHERE id IN (SELECT user_id FROM public.demo_users);
  DELETE FROM auth.users WHERE id IN (SELECT user_id FROM public.demo_users);

  -- 13. Delete seed content
  DELETE FROM public.mandi_prices WHERE market IN ('Kolar Mandi', 'Yashwantpur Mandi', 'Binny Mill Mandi', 'Chintamani Mandi');
  DELETE FROM public.wage_benchmarks WHERE area IN ('Bengaluru Urban', 'Bengaluru Rural', 'Kolar');
  DELETE FROM public.reward_items WHERE names->>'en' IN ('UdyogaSethu Safety T-Shirt', 'Branded Cap', 'Stainless Steel Water Bottle', 'Heavy Duty Tool Bag', 'UdyogaSethu Lanyard', 'Sticker Pack');
  DELETE FROM public.training_events WHERE venue LIKE '%Bengaluru%';
  DELETE FROM public.learning_modules WHERE slug LIKE 'demo-%';
  DELETE FROM public.ad_banners WHERE title LIKE '%PM-KMY%';
  DELETE FROM public.badges WHERE slug IN (
    'safety_first', 'punctual_worker', 'top_rated', 'ekyc_verified', 'face_verified',
    'super_farmer', 'group_buyer', 'early_bird', 'zero_cancellation', 'community_champion',
    'skill_master', 'green_thumb'
  );
  DELETE FROM public.levels WHERE name IN ('Starter', 'Reliable', 'Trusted Pro', 'Community Hero');

  -- 14. Clear demo_users tracking table
  TRUNCATE TABLE public.demo_users;

  RAISE NOTICE 'Demo data reset completed cleanly!';
END $$;

SELECT 'DEMO DATA RESET SUCCESSFULLY' AS status;
