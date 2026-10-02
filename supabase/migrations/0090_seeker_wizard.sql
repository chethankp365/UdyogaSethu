-- Migration: 0090_seeker_wizard.sql
-- Description: Additional fields for seeker wizard: gender, has_driving_licence, subjects_interests, working_days, wizard_step

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS gender TEXT;

ALTER TABLE public.worker_profiles
  ADD COLUMN IF NOT EXISTS has_driving_licence BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS subjects_interests TEXT[] DEFAULT '{}'::TEXT[],
  ADD COLUMN IF NOT EXISTS working_days TEXT[] DEFAULT '{}'::TEXT[],
  ADD COLUMN IF NOT EXISTS wizard_step INT NOT NULL DEFAULT 1;
