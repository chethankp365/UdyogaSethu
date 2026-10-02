-- Migration: 0080_bootstrap.sql
-- Description: RPC functions for role assignment, bootstrap state retrieval, and doc_type enum extension

-- 1. Extend doc_type enum to include background_check
ALTER TYPE public.doc_type ADD VALUE IF NOT EXISTS 'background_check';

-- 2. Function: apply_role_selection
-- Assigns a role to the caller, creates default role profile rows, sets active_role, and handles primary role flag.
CREATE OR REPLACE FUNCTION public.apply_role_selection(
  p_role public.app_role,
  p_seeker_type public.seeker_type DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID;
  v_has_role BOOLEAN;
  v_has_any_role BOOLEAN;
  v_is_primary BOOLEAN;
BEGIN
  -- Reject admin role self-assignment
  IF p_role = 'admin' THEN
    RAISE EXCEPTION 'Cannot self-assign admin role' USING ERRCODE = '42501';
  END IF;

  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  -- Ensure profiles row exists
  INSERT INTO public.profiles (id, active_role)
  VALUES (v_user_id, p_role)
  ON CONFLICT (id) DO NOTHING;

  -- Check if user already holds any role
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = v_user_id
  ) INTO v_has_any_role;

  -- Check if user already holds this specific role
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = v_user_id AND role = p_role
  ) INTO v_has_role;

  IF NOT v_has_role THEN
    v_is_primary := NOT v_has_any_role;
    INSERT INTO public.user_roles (user_id, role, is_primary)
    VALUES (v_user_id, p_role, v_is_primary);
  END IF;

  -- Create role profile row based on selected role
  IF p_role = 'seeker' THEN
    INSERT INTO public.worker_profiles (user_id, seeker_type)
    VALUES (v_user_id, COALESCE(p_seeker_type, 'informal'::public.seeker_type))
    ON CONFLICT (user_id) DO UPDATE
    SET seeker_type = COALESCE(EXCLUDED.seeker_type, worker_profiles.seeker_type);
  ELSIF p_role = 'provider' THEN
    INSERT INTO public.provider_profiles (user_id)
    VALUES (v_user_id)
    ON CONFLICT (user_id) DO NOTHING;
  ELSIF p_role = 'farmer' THEN
    INSERT INTO public.farmer_profiles (user_id)
    VALUES (v_user_id)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;

  -- Set active role in profiles table
  UPDATE public.profiles
  SET active_role = p_role,
      updated_at = NOW()
  WHERE id = v_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', v_user_id,
    'active_role', p_role,
    'seeker_type', p_seeker_type
  );
END;
$$;

-- 3. Function: get_bootstrap_state
-- Returns user profile, roles, active role, onboarding status, suspension status, and wizard completion in a single call.
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
        SELECT (wp.user_id IS NOT NULL AND wp.skills IS NOT NULL AND array_length(wp.skills, 1) > 0)
        FROM public.worker_profiles wp WHERE wp.user_id = v_user_id
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
      'wizard_completion', jsonb_build_object('seeker', false, 'provider', false, 'farmer', false)
    );
  END IF;

  RETURN v_result;
END;
$$;

-- 4. Permissions
GRANT EXECUTE ON FUNCTION public.apply_role_selection(public.app_role, public.seeker_type) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bootstrap_state() TO authenticated;
