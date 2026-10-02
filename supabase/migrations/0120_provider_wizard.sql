-- Migration: 0120_provider_wizard.sql
-- Description: Add wizard_step, categories_hiring, typical_crew_size, and delivery_preferences to provider_profiles table

ALTER TABLE public.provider_profiles
  ADD COLUMN IF NOT EXISTS wizard_step INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS categories_hiring TEXT[],
  ADD COLUMN IF NOT EXISTS typical_crew_size INT,
  ADD COLUMN IF NOT EXISTS delivery_preferences JSONB;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
