-- Migration: 0240_sync_avatar_paths.sql
-- Description: Ensures public.profiles.avatar_path remains the single source of truth for all user profile photos.
-- Role Tables Audit:
--   - worker_profiles: No avatar column.
--   - farmer_profiles: No avatar column (organic_cert_path stores documents).
--   - provider_profiles: No avatar column.

-- 1. Safety check to ensure avatar_path column exists on public.profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_path TEXT;

-- 2. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
