-- Migration: 0280_fix_bootstrap_wizard_completion.sql
-- Description: Fix get_bootstrap_state RPC to read seeker wizard completion from worker_profiles.is_wizard_complete
--              instead of non-existent wp.skills column, restoring startup stability.

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
    'face_required_at_login', public.get_face_login_requirement(),
    'has_enrolled_face', EXISTS (
      SELECT 1 FROM public.face_profiles WHERE user_id = v_user_id AND status = 'verified'
    ),
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
      'face_required_at_login', false,
      'has_enrolled_face', false,
      'wizard_completion', jsonb_build_object('seeker', false, 'provider', false, 'farmer', false)
    );
  END IF;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_bootstrap_state() TO authenticated;

NOTIFY pgrst, 'reload schema';
