-- Migration: 0160_bootstrap_completion_fix.sql
-- Description: Fix get_bootstrap_state RPC to use strict per-role wizard completion logic based solely on each role's own is_wizard_complete flag.

-- 1. Ensure wizard_step and is_wizard_complete columns exist on role profile tables
ALTER TABLE public.worker_profiles
  ADD COLUMN IF NOT EXISTS wizard_step INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS is_wizard_complete BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.farmer_profiles
  ADD COLUMN IF NOT EXISTS wizard_step INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS is_wizard_complete BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.provider_profiles
  ADD COLUMN IF NOT EXISTS wizard_step INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS is_wizard_complete BOOLEAN NOT NULL DEFAULT false;

-- 2. Update get_bootstrap_state RPC with strict role-isolated wizard completion
CREATE OR REPLACE FUNCTION public.get_bootstrap_state()
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
    'user_id', v_user_id,
    'profile', jsonb_build_object(
      'id', p.id,
      'full_name', p.full_name,
      'phone', p.phone,
      'email', p.email,
      'avatar_path', p.avatar_path,
      'language', p.language,
      'gender', p.gender,
      'active_role', p.active_role,
      'onboarding_complete', p.onboarding_complete,
      'is_suspended', p.is_suspended,
      'created_at', p.created_at
    ),
    'roles', COALESCE(
      (SELECT jsonb_agg(ur.role) FROM public.user_roles ur WHERE ur.user_id = v_user_id),
      '[]'::jsonb
    ),
    'active_role', p.active_role,
    'onboarding_complete', p.onboarding_complete,
    'is_suspended', p.is_suspended,
    'wizard_completion', jsonb_build_object(
      'seeker', COALESCE((
        SELECT (wp.is_wizard_complete = true)
        FROM public.worker_profiles wp WHERE wp.user_id = v_user_id
      ), false),
      'farmer', COALESCE((
        SELECT (fp.is_wizard_complete = true)
        FROM public.farmer_profiles fp WHERE fp.user_id = v_user_id
      ), false),
      'provider', COALESCE((
        SELECT (pp.is_wizard_complete = true)
        FROM public.provider_profiles pp WHERE pp.user_id = v_user_id
      ), false)
    )
  ) INTO v_result
  FROM public.profiles p
  WHERE p.id = v_user_id;

  IF v_result IS NULL THEN
    -- Fallback if profile row is missing
    INSERT INTO public.profiles (id, active_role)
    VALUES (v_user_id, 'seeker'::public.app_role)
    ON CONFLICT (id) DO NOTHING;

    RETURN jsonb_build_object(
      'user_id', v_user_id,
      'profile', jsonb_build_object('id', v_user_id),
      'roles', '[]'::jsonb,
      'active_role', 'seeker',
      'onboarding_complete', false,
      'is_suspended', false,
      'wizard_completion', jsonb_build_object(
        'seeker', false,
        'provider', false,
        'farmer', false
      )
    );
  END IF;

  RETURN v_result;
END;
$$;

-- 3. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
