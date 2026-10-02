-- Migration: 0100_farmer_wizard.sql
-- Description: Add wizard_step to farmer_profiles table for resumable farmer onboarding

ALTER TABLE public.farmer_profiles
  ADD COLUMN IF NOT EXISTS wizard_step INT NOT NULL DEFAULT 1;
