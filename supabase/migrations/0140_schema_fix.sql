-- Migration: 0140_schema_fix.sql
-- Description: Fix get_bootstrap_state RPC worker_skills check, add gender constraint, and reload schema

-- 1. Ensure profiles.gender has proper check constraint
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS gender TEXT;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS chk_profiles_gender;

ALTER TABLE public.profiles
  ADD CONSTRAINT chk_profiles_gender
  CHECK (gender IS NULL OR gender IN ('male', 'female', 'other', 'prefer_not_to_say'));

-- 2. Update get_bootstrap_state RPC to check worker_skills table instead of wp.skills
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
      'seeker', (
        SELECT EXISTS (SELECT 1 FROM public.worker_skills ws WHERE ws.user_id = v_user_id)
        OR EXISTS (SELECT 1 FROM public.worker_profiles wp WHERE wp.user_id = v_user_id AND wp.wizard_step >= 7)
      ),
      'provider', (
        SELECT (pp.user_id IS NOT NULL)
        FROM public.provider_profiles pp WHERE pp.user_id = v_user_id
      ),
      'farmer', (
        SELECT (fp.user_id IS NOT NULL)
        FROM public.farmer_profiles fp WHERE fp.user_id = v_user_id
      )
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

-- 3. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
