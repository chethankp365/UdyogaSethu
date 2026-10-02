-- Migration: 0110_profiles_gender.sql
-- Description: Add private gender column to profiles table with check constraint for worker search filter

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say'));

-- Notify PostgREST schema cache to reload immediately
NOTIFY pgrst, 'reload schema';
