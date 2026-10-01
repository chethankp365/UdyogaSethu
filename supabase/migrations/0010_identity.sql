-- Migration: 0010_identity.sql
-- Description: Core identity, roles, user profiles, worker/provider/farmer profiles, skills, and addresses

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;

-- 2. Custom Enums
CREATE TYPE public.app_role AS ENUM ('seeker', 'provider', 'farmer', 'admin');
CREATE TYPE public.seeker_type AS ENUM ('informal', 'student', 'part_time');
CREATE TYPE public.provider_type AS ENUM ('household', 'employer');
CREATE TYPE public.lang_code AS ENUM ('en', 'kn', 'hi', 'te', 'ta', 'mr', 'bn', 'or');
CREATE TYPE public.availability_status AS ENUM ('available', 'busy', 'offline');
CREATE TYPE public.verification_status AS ENUM ('not_started', 'pending', 'verified', 'rejected', 'review_required');

-- 3. Updated_at Trigger Helper Function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Table: profiles
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT UNIQUE,
  email TEXT,
  avatar_path TEXT,
  language public.lang_code NOT NULL DEFAULT 'kn',
  simple_mode BOOLEAN NOT NULL DEFAULT false,
  low_data_mode BOOLEAN NOT NULL DEFAULT false,
  text_scale NUMERIC(3,2) NOT NULL DEFAULT 1.00,
  home_location extensions.geography(Point, 4326),
  home_address TEXT,
  city TEXT,
  state TEXT,
  pincode TEXT,
  active_role public.app_role NOT NULL DEFAULT 'seeker',
  onboarding_complete BOOLEAN NOT NULL DEFAULT false,
  is_suspended BOOLEAN NOT NULL DEFAULT false,
  last_active_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Table: user_roles
CREATE TABLE public.user_roles (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, role)
);

-- 6. Table: service_categories
CREATE TABLE public.service_categories (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  names JSONB NOT NULL,
  icon TEXT,
  sort INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Table: skills
CREATE TABLE public.skills (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES public.service_categories(id) ON DELETE CASCADE,
  names JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Table: worker_profiles
CREATE TABLE public.worker_profiles (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  seeker_type public.seeker_type NOT NULL DEFAULT 'informal',
  headline TEXT,
  bio TEXT,
  experience_years NUMERIC(4,1) DEFAULT 0,
  hourly_rate_paise BIGINT,
  daily_rate_paise BIGINT,
  languages public.lang_code[] DEFAULT ARRAY['kn']::public.lang_code[],
  service_radius_km NUMERIC(5,2) DEFAULT 10.0,
  availability public.availability_status NOT NULL DEFAULT 'available',
  work_hours JSONB,
  -- Student fields
  college_name TEXT,
  course TEXT,
  reg_no_masked TEXT,
  -- Part-time preferences
  preferred_hours JSONB,
  -- Server-computed fields
  rating_avg NUMERIC(3,2) NOT NULL DEFAULT 0.00,
  rating_count INT NOT NULL DEFAULT 0,
  jobs_completed INT NOT NULL DEFAULT 0,
  is_verified_badge BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Table: worker_skills
CREATE TABLE public.worker_skills (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES public.skills(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, skill_id)
);

-- 10. Table: provider_profiles
CREATE TABLE public.provider_profiles (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  provider_type public.provider_type NOT NULL DEFAULT 'household',
  org_name TEXT,
  -- Server-computed fields
  rating_avg NUMERIC(3,2) NOT NULL DEFAULT 0.00,
  rating_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. Table: farmer_profiles
CREATE TABLE public.farmer_profiles (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  farm_name TEXT,
  farm_location extensions.geography(Point, 4326),
  cluster_village TEXT,
  acres NUMERIC(6,2),
  soil_type TEXT,
  soil_ph NUMERIC(3,1),
  primary_crops TEXT[],
  farming_method TEXT,
  apmc_registration TEXT,
  kcc_status TEXT,
  organic_cert_status public.verification_status NOT NULL DEFAULT 'not_started',
  organic_cert_path TEXT,
  delivery_options JSONB,
  -- Server-computed fields
  rating_avg NUMERIC(3,2) NOT NULL DEFAULT 0.00,
  rating_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. Table: addresses
CREATE TABLE public.addresses (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  label TEXT,
  line1 TEXT NOT NULL,
  landmark TEXT,
  city TEXT NOT NULL,
  pincode TEXT NOT NULL,
  location extensions.geography(Point, 4326),
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. Enable RLS on all tables (No policies created yet - done in P1.5)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farmer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;

-- 14. Indexes
CREATE INDEX idx_profiles_home_location ON public.profiles USING GIST (home_location);
CREATE INDEX idx_profiles_full_name_trgm ON public.profiles USING GIN (full_name extensions.gin_trgm_ops);
CREATE INDEX idx_user_roles_user_id ON public.user_roles (user_id);
CREATE INDEX idx_farmer_farm_location ON public.farmer_profiles USING GIST (farm_location);
CREATE INDEX idx_addresses_user_id ON public.addresses (user_id);
CREATE INDEX idx_addresses_location ON public.addresses USING GIST (location);

-- 15. Triggers for updated_at
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_service_categories_updated_at BEFORE UPDATE ON public.service_categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_skills_updated_at BEFORE UPDATE ON public.skills FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_worker_profiles_updated_at BEFORE UPDATE ON public.worker_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_provider_profiles_updated_at BEFORE UPDATE ON public.provider_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_farmer_profiles_updated_at BEFORE UPDATE ON public.farmer_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_addresses_updated_at BEFORE UPDATE ON public.addresses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 16. New User Trigger Function (auth.users -> public.profiles)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  meta_full_name TEXT;
BEGIN
  meta_full_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    NULL
  );

  INSERT INTO public.profiles (
    id,
    phone,
    email,
    full_name,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.phone,
    NEW.email,
    meta_full_name,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 17. Comments on Tables and Server-Computed Columns
COMMENT ON TABLE public.profiles IS 'Core identity profile linked 1:1 with auth.users.';
COMMENT ON TABLE public.user_roles IS 'Multi-role mapping table supporting seeker, provider, farmer, and admin roles per user.';
COMMENT ON TABLE public.service_categories IS 'Master service categories with multilingual JSONB names.';
COMMENT ON TABLE public.skills IS 'Granular skills linked to service categories with multilingual names.';
COMMENT ON TABLE public.worker_profiles IS 'Worker specific profile for informal, student, and part-time job seekers.';
COMMENT ON TABLE public.worker_skills IS 'Junction table linking workers to their selected skills.';
COMMENT ON TABLE public.provider_profiles IS 'Job provider/employer specific profile.';
COMMENT ON TABLE public.farmer_profiles IS 'Farmer specific agri-marketplace and farm profile.';
COMMENT ON TABLE public.addresses IS 'User saved physical addresses with PostGIS geographical points.';

-- Computed Column Comments
COMMENT ON COLUMN public.worker_profiles.rating_avg IS 'SERVER COMPUTED: Aggregated average rating (0.00-5.00) calculated from completed job reviews.';
COMMENT ON COLUMN public.worker_profiles.rating_count IS 'SERVER COMPUTED: Total count of completed job ratings received by this worker.';
COMMENT ON COLUMN public.worker_profiles.jobs_completed IS 'SERVER COMPUTED: Total number of verified jobs successfully completed.';
COMMENT ON COLUMN public.worker_profiles.is_verified_badge IS 'SERVER COMPUTED: Boolean flag true when worker completes face + KYC verification.';
COMMENT ON COLUMN public.provider_profiles.rating_avg IS 'SERVER COMPUTED: Aggregated average rating (0.00-5.00) calculated from worker reviews.';
COMMENT ON COLUMN public.provider_profiles.rating_count IS 'SERVER COMPUTED: Total count of ratings received by this employer.';
COMMENT ON COLUMN public.farmer_profiles.rating_avg IS 'SERVER COMPUTED: Aggregated average rating (0.00-5.00) calculated from agri-buyer reviews.';
COMMENT ON COLUMN public.farmer_profiles.rating_count IS 'SERVER COMPUTED: Total count of ratings received by this farmer.';
