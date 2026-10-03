-- Migration: 0210_verification_extra.sql
-- Description: Adds requires_licence to service_categories, updates category requirements,
--              extends doc_type enum if needed, and adds nearby_jobs_for_worker RPC
--              with licence and verified_only gating.

-- 1. Add requires_licence column to service_categories
ALTER TABLE public.service_categories
ADD COLUMN IF NOT EXISTS requires_licence BOOLEAN NOT NULL DEFAULT false;

-- 2. Mark driver and delivery categories as requires_licence = true
UPDATE public.service_categories
SET requires_licence = true
WHERE slug IN ('driver', 'delivery', 'delivery-gig-work');

-- 3. Extend doc_type enum with student_id, bank_account, upi if missing
ALTER TYPE public.doc_type ADD VALUE IF NOT EXISTS 'student_id';
ALTER TYPE public.doc_type ADD VALUE IF NOT EXISTS 'bank_account';
ALTER TYPE public.doc_type ADD VALUE IF NOT EXISTS 'upi';

-- 4. Create or replace RPC function: nearby_jobs_for_worker
-- Filters out driver/delivery jobs requiring licence if worker is not DL-verified,
-- and filters out verified_only jobs if worker is not background-verified.
CREATE OR REPLACE FUNCTION public.nearby_jobs_for_worker(
  p_worker_id UUID,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 10000,
  p_category_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20,
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
  requires_licence_gated BOOLEAN,
  verified_only_gated BOOLEAN,
  is_eligible BOOLEAN,
  ineligibility_reason TEXT
) AS $$
DECLARE
  v_point extensions.geography;
  v_has_dl BOOLEAN := false;
  v_has_bgc BOOLEAN := false;
BEGIN
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  -- Check if worker has verified DL
  SELECT EXISTS (
    SELECT 1 FROM public.kyc_records
    WHERE user_id = p_worker_id
      AND doc_type IN ('driving_licence')
      AND status = 'verified'
  ) INTO v_has_dl;

  -- Check if worker has verified background check or verified badge
  SELECT EXISTS (
    SELECT 1 FROM public.kyc_records
    WHERE user_id = p_worker_id
      AND doc_type = 'background_check'
      AND status = 'verified'
  ) INTO v_has_bgc;

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
    COALESCE(sc.requires_licence, false) AS requires_licence_gated,
    COALESCE((j.requirements->>'verified_only')::boolean, false) AS verified_only_gated,
    CASE
      WHEN COALESCE(sc.requires_licence, false) AND NOT v_has_dl THEN false
      WHEN COALESCE((j.requirements->>'verified_only')::boolean, false) AND NOT v_has_bgc THEN false
      ELSE true
    END AS is_eligible,
    CASE
      WHEN COALESCE(sc.requires_licence, false) AND NOT v_has_dl THEN 'Requires Verified Driving Licence'
      WHEN COALESCE((j.requirements->>'verified_only')::boolean, false) AND NOT v_has_bgc THEN 'Requires Verified Background Check'
      ELSE NULL
    END AS ineligibility_reason
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  WHERE j.status = 'open'
    AND j.location IS NOT NULL
    AND extensions.ST_DWithin(j.location, v_point, p_radius_m)
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
  ORDER BY distance_m ASC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
