-- Migration: 0270_face_login_gate.sql
-- Description: Ensures face_required_at_login default setting exists in admin_settings,
--              updates get_face_login_requirement() to safely parse jsonb, string, and number values,
--              and updates get_bootstrap_state() RPC to return face_required_at_login and has_enrolled_face flags.

-- 1. Ensure face_required_at_login seed exists in admin_settings without overwriting existing setting
INSERT INTO public.admin_settings (key, value)
VALUES ('face_required_at_login', 'false'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- 2. Update get_face_login_requirement() to read jsonb, string, or number values safely
CREATE OR REPLACE FUNCTION public.get_face_login_requirement()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller UUID;
  v_setting_val JSONB;
  v_setting_bool BOOLEAN := false;
  v_is_seeker BOOLEAN := false;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RETURN false;
  END IF;

  -- Read global setting face_required_at_login
  SELECT value INTO v_setting_val
  FROM public.admin_settings
  WHERE key = 'face_required_at_login';

  IF v_setting_val IS NOT NULL THEN
    IF jsonb_typeof(v_setting_val) = 'boolean' THEN
      v_setting_bool := v_setting_val::boolean;
    ELSIF jsonb_typeof(v_setting_val) = 'string' THEN
      v_setting_bool := (v_setting_val->>0 = 'true') 
                     OR (v_setting_val#>>'{}' = 'true') 
                     OR (LOWER(v_setting_val::text) LIKE '%true%');
    ELSIF jsonb_typeof(v_setting_val) = 'number' THEN
      v_setting_bool := (v_setting_val::text = '1');
    END IF;
  END IF;

  IF NOT v_setting_bool THEN
    RETURN false;
  END IF;

  -- Check if calling user has 'seeker' role (workers)
  v_is_seeker := public.has_role('seeker'::public.app_role);

  RETURN COALESCE(v_is_seeker, false);
END;
$$;

-- 3. Update get_bootstrap_state() to include face_required_at_login and has_enrolled_face
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
    'face_required_at_login', public.get_face_login_requirement(),
    'has_enrolled_face', EXISTS (
      SELECT 1 FROM public.face_profiles WHERE user_id = v_user_id AND status = 'verified'
    ),
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

GRANT EXECUTE ON FUNCTION public.get_face_login_requirement() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_bootstrap_state() TO authenticated;

NOTIFY pgrst, 'reload schema';
