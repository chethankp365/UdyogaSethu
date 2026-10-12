-- ============================================================================
-- Migration: 0690_jobs_thumbnail_path.sql
-- Description: Adds thumbnail_path column to jobs table and enhances
--              post_provider_job and update_provider_job to persist custom
--              uploaded or library thumbnail paths.
-- ============================================================================

-- 1. Add thumbnail_path to jobs table
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS thumbnail_path TEXT DEFAULT NULL;

-- 2. Backfill from site_photo_url if available
UPDATE public.jobs
SET thumbnail_path = site_photo_url
WHERE thumbnail_path IS NULL AND site_photo_url IS NOT NULL;

-- 3. Enhanced 19-param post_provider_job
CREATE OR REPLACE FUNCTION public.post_provider_job(
  p_category_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_wage_type public.wage_type,
  p_wage_paise BIGINT,
  p_est_duration_minutes INT,
  p_start_at TIMESTAMPTZ,
  p_slots_total INT,
  p_materials_provided BOOLEAN,
  p_payment_mode public.payment_mode,
  p_requirements JSONB,
  p_address_text TEXT,
  p_location_lat DOUBLE PRECISION,
  p_location_lng DOUBLE PRECISION,
  p_geofence_radius_m INT DEFAULT 150,
  p_suitable_for TEXT[] DEFAULT ARRAY['informal'],
  p_landmark TEXT DEFAULT NULL,
  p_site_photo_url TEXT DEFAULT NULL,
  p_thumbnail_path TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_provider_id UUID;
  v_job_id UUID;
  v_loc extensions.geography(Point, 4326) := NULL;
  v_suitable public.seeker_type[];
  v_effective_thumb TEXT;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_location_lat IS NOT NULL AND p_location_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_location_lng, p_location_lat), 4326)::extensions.geography;
  END IF;

  -- Convert suitable_for text array to seeker_type array
  IF p_suitable_for IS NOT NULL AND array_length(p_suitable_for, 1) > 0 THEN
    SELECT array_agg(u::public.seeker_type)
    INTO v_suitable
    FROM unnest(p_suitable_for) u;
  ELSE
    v_suitable := ARRAY['informal'::public.seeker_type];
  END IF;

  v_effective_thumb := COALESCE(p_thumbnail_path, p_site_photo_url);

  INSERT INTO public.jobs (
    provider_id,
    category_id,
    title,
    description,
    wage_type,
    wage_paise,
    est_duration_minutes,
    start_at,
    slots_total,
    slots_filled,
    materials_provided,
    payment_mode,
    requirements,
    location,
    address_text,
    landmark,
    site_photo_url,
    thumbnail_path,
    geofence_radius_m,
    suitable_for,
    is_demo,
    status
  ) VALUES (
    v_provider_id,
    p_category_id,
    TRIM(p_title),
    p_description,
    p_wage_type,
    p_wage_paise,
    COALESCE(p_est_duration_minutes, 480),
    p_start_at,
    GREATEST(COALESCE(p_slots_total, 1), 1),
    0,
    COALESCE(p_materials_provided, false),
    p_payment_mode,
    COALESCE(p_requirements, '{"verified_only": false, "licence_required": false, "students_ok": false}'::jsonb),
    v_loc,
    p_address_text,
    p_landmark,
    COALESCE(p_site_photo_url, v_effective_thumb),
    v_effective_thumb,
    COALESCE(p_geofence_radius_m, 150),
    v_suitable,
    false,
    'open'
  )
  RETURNING id INTO v_job_id;

  RETURN v_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.post_provider_job(UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], TEXT, TEXT, TEXT) TO authenticated;

-- 4. 18-param backward compatibility overload
CREATE OR REPLACE FUNCTION public.post_provider_job(
  p_category_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_wage_type public.wage_type,
  p_wage_paise BIGINT,
  p_est_duration_minutes INT,
  p_start_at TIMESTAMPTZ,
  p_slots_total INT,
  p_materials_provided BOOLEAN,
  p_payment_mode public.payment_mode,
  p_requirements JSONB,
  p_address_text TEXT,
  p_location_lat DOUBLE PRECISION,
  p_location_lng DOUBLE PRECISION,
  p_geofence_radius_m INT DEFAULT 150,
  p_suitable_for TEXT[] DEFAULT ARRAY['informal'],
  p_landmark TEXT DEFAULT NULL,
  p_site_photo_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
BEGIN
  RETURN public.post_provider_job(
    p_category_id,
    p_title,
    p_description,
    p_wage_type,
    p_wage_paise,
    p_est_duration_minutes,
    p_start_at,
    p_slots_total,
    p_materials_provided,
    p_payment_mode,
    p_requirements,
    p_address_text,
    p_location_lat,
    p_location_lng,
    p_geofence_radius_m,
    p_suitable_for,
    p_landmark,
    p_site_photo_url,
    p_site_photo_url
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.post_provider_job(UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], TEXT, TEXT) TO authenticated;

-- 5. Enhanced 20-param update_provider_job
CREATE OR REPLACE FUNCTION public.update_provider_job(
  p_job_id UUID,
  p_category_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_wage_type public.wage_type,
  p_wage_paise BIGINT,
  p_est_duration_minutes INT,
  p_start_at TIMESTAMPTZ,
  p_slots_total INT,
  p_materials_provided BOOLEAN,
  p_payment_mode public.payment_mode,
  p_requirements JSONB,
  p_address_text TEXT,
  p_location_lat DOUBLE PRECISION,
  p_location_lng DOUBLE PRECISION,
  p_geofence_radius_m INT DEFAULT 150,
  p_suitable_for TEXT[] DEFAULT ARRAY['informal'],
  p_landmark TEXT DEFAULT NULL,
  p_site_photo_url TEXT DEFAULT NULL,
  p_thumbnail_path TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_provider_id UUID;
  v_loc extensions.geography(Point, 4326) := NULL;
  v_suitable public.seeker_type[];
  v_effective_thumb TEXT;
BEGIN
  v_provider_id := auth.uid();
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_location_lat IS NOT NULL AND p_location_lng IS NOT NULL THEN
    v_loc := extensions.ST_SetSRID(extensions.ST_MakePoint(p_location_lng, p_location_lat), 4326)::extensions.geography;
  END IF;

  IF p_suitable_for IS NOT NULL AND array_length(p_suitable_for, 1) > 0 THEN
    SELECT array_agg(u::public.seeker_type)
    INTO v_suitable
    FROM unnest(p_suitable_for) u;
  ELSE
    v_suitable := ARRAY['informal'::public.seeker_type];
  END IF;

  v_effective_thumb := COALESCE(p_thumbnail_path, p_site_photo_url);

  UPDATE public.jobs
  SET
    category_id = p_category_id,
    title = TRIM(p_title),
    description = p_description,
    wage_type = p_wage_type,
    wage_paise = p_wage_paise,
    est_duration_minutes = COALESCE(p_est_duration_minutes, 480),
    start_at = p_start_at,
    slots_total = GREATEST(COALESCE(p_slots_total, 1), 1),
    materials_provided = COALESCE(p_materials_provided, false),
    payment_mode = p_payment_mode,
    requirements = COALESCE(p_requirements, requirements),
    location = COALESCE(v_loc, location),
    address_text = p_address_text,
    landmark = p_landmark,
    site_photo_url = COALESCE(p_site_photo_url, v_effective_thumb),
    thumbnail_path = v_effective_thumb,
    geofence_radius_m = COALESCE(p_geofence_radius_m, 150),
    suitable_for = v_suitable,
    updated_at = NOW()
  WHERE id = p_job_id AND provider_id = v_provider_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.update_provider_job(UUID, UUID, TEXT, TEXT, public.wage_type, BIGINT, INT, TIMESTAMPTZ, INT, BOOLEAN, public.payment_mode, JSONB, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], TEXT, TEXT, TEXT) TO authenticated;
