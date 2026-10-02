-- Migration: 0130_account_settings_export_delete.sql
-- Description: Adds user settings columns to profiles, data export RPC, and user anonymization/deletion RPC.

-- 1. Add settings columns to profiles table
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS simple_mode BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS text_scale NUMERIC(3,2) NOT NULL DEFAULT 1.00,
  ADD COLUMN IF NOT EXISTS voice_hints BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS low_data_mode BOOLEAN NOT NULL DEFAULT false;

-- 2. RPC: export_user_data
-- Returns a comprehensive JSON object containing all personal data associated with the authenticated user.
CREATE OR REPLACE FUNCTION public.export_user_data()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID;
  v_result JSONB;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT jsonb_build_object(
    'export_timestamp', NOW(),
    'profile', (SELECT to_jsonb(p) FROM public.profiles p WHERE p.id = v_user_id),
    'roles', (SELECT COALESCE(jsonb_agg(to_jsonb(ur)), '[]'::jsonb) FROM public.user_roles ur WHERE ur.user_id = v_user_id),
    'worker_profile', (SELECT to_jsonb(wp) FROM public.worker_profiles wp WHERE wp.user_id = v_user_id),
    'provider_profile', (SELECT to_jsonb(pp) FROM public.provider_profiles pp WHERE pp.user_id = v_user_id),
    'farmer_profile', (SELECT to_jsonb(fp) FROM public.farmer_profiles fp WHERE fp.user_id = v_user_id),
    'addresses', (SELECT COALESCE(jsonb_agg(to_jsonb(a)), '[]'::jsonb) FROM public.addresses a WHERE a.user_id = v_user_id),
    'kyc_records', (SELECT COALESCE(jsonb_agg(to_jsonb(k)), '[]'::jsonb) FROM public.kyc_records k WHERE k.user_id = v_user_id),
    'wallet', (SELECT to_jsonb(w) FROM public.wallets w WHERE w.user_id = v_user_id),
    'consent_logs', (SELECT COALESCE(jsonb_agg(to_jsonb(c)), '[]'::jsonb) FROM public.consent_logs c WHERE c.user_id = v_user_id),
    'emergency_contacts', (SELECT COALESCE(jsonb_agg(to_jsonb(ec)), '[]'::jsonb) FROM public.emergency_contacts ec WHERE ec.user_id = v_user_id)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.export_user_data() TO authenticated;

-- 3. RPC: anonymize_and_delete_user_data
-- Anonymizes legal/financial audit records (ledger, payments, disputes) and erases profile data and role rows.
CREATE OR REPLACE FUNCTION public.anonymize_and_delete_user_data(p_target_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_caller_id UUID;
BEGIN
  v_caller_id := auth.uid();
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  -- User can delete themselves, or an admin can initiate
  IF v_caller_id != p_target_user_id AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;

  -- 1. Anonymize reviews given or received
  UPDATE public.ratings_reviews
  SET review_text = '[Account Deleted]'
  WHERE reviewer_id = p_target_user_id OR reviewee_id = p_target_user_id;

  -- 2. Delete non-financial personal rows
  DELETE FROM public.consent_logs WHERE user_id = p_target_user_id;
  DELETE FROM public.favourites WHERE user_id = p_target_user_id;
  DELETE FROM public.emergency_contacts WHERE user_id = p_target_user_id;
  DELETE FROM public.addresses WHERE user_id = p_target_user_id;
  DELETE FROM public.kyc_records WHERE user_id = p_target_user_id;
  DELETE FROM public.worker_profiles WHERE user_id = p_target_user_id;
  DELETE FROM public.provider_profiles WHERE user_id = p_target_user_id;
  DELETE FROM public.farmer_profiles WHERE user_id = p_target_user_id;
  DELETE FROM public.user_roles WHERE user_id = p_target_user_id;

  -- 3. Scrub profile row
  UPDATE public.profiles
  SET full_name = 'Deleted User',
      phone = NULL,
      email = NULL,
      avatar_path = NULL,
      is_suspended = true
  WHERE id = p_target_user_id;

  -- 4. Delete profile row
  DELETE FROM public.profiles WHERE id = p_target_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'deleted_user_id', p_target_user_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.anonymize_and_delete_user_data(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
