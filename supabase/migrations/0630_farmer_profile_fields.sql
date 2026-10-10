-- ============================================================================
-- Migration: 0630_farmer_profile_fields.sql
-- Dependencies:
--   - 0010_identity.sql (farmer_profiles table)
-- Description:
--   Adds typed columns to farmer_profiles for delivery radius, pickup options,
--   lead time, farm photos, and self-declared certificate tracking (Prompt F1, F2).
-- ============================================================================

ALTER TABLE public.farmer_profiles
  ADD COLUMN IF NOT EXISTS delivery_radius_km NUMERIC(5,1) DEFAULT 25.0,
  ADD COLUMN IF NOT EXISTS pickup_available BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS lead_time_hours INT DEFAULT 24,
  ADD COLUMN IF NOT EXISTS farm_photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS organic_cert_number TEXT DEFAULT NULL;

COMMENT ON COLUMN public.farmer_profiles.delivery_radius_km IS
  'Farmer direct delivery radius in kilometers for marketplace orders.';
COMMENT ON COLUMN public.farmer_profiles.pickup_available IS
  'True if buyers can pick up produce directly from farm gate.';
COMMENT ON COLUMN public.farmer_profiles.lead_time_hours IS
  'Harvest and packing lead time in hours before dispatch.';
COMMENT ON COLUMN public.farmer_profiles.organic_cert_number IS
  'Optional self-declared organic certificate number; verified status tracked separately by admin.';
