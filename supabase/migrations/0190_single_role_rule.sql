-- Migration: 0190_single_role_rule.sql
-- Description: Enforces One Account = One Role policy centrally in SQL.
-- Switchable via public.allow_multi_role() function.
--
-- Prerequisite migrations: 0010_identity.sql and 0080_bootstrap.sql must be run before this migration.
-- Safe to run independently regardless of whether migration 0130 was previously applied.

-- 1. SQL Function: allow_multi_role
-- Returns false by default to enforce 1 Account = 1 Role.
-- Can be changed to return true to re-enable multi-role functionality.
CREATE OR REPLACE FUNCTION public.allow_multi_role()
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT false;
$$;

GRANT EXECUTE ON FUNCTION public.allow_multi_role() TO authenticated, anon;

-- 2. Function: apply_role_selection
-- Rejects adding a second role to an account if allow_multi_role() returns false.
-- Deterministic role lookup: ORDER BY is_primary DESC, role LIMIT 1.
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
  v_existing_role public.app_role;
  v_has_this_role BOOLEAN;
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

  -- Deterministic lookup of existing role
  SELECT role INTO v_existing_role
  FROM public.user_roles
  WHERE user_id = v_user_id
  ORDER BY is_primary DESC, role
  LIMIT 1;

  -- Enforce single-role restriction if allow_multi_role() is false
  IF NOT public.allow_multi_role() AND v_existing_role IS NOT NULL AND v_existing_role != p_role THEN
    RAISE EXCEPTION 'ROLE_CONFLICT: Account registered as %', v_existing_role
      USING ERRCODE = 'P0002', DETAIL = v_existing_role::text;
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
  ) INTO v_has_this_role;

  IF NOT v_has_this_role THEN
    v_is_primary := NOT v_has_any_role;
    INSERT INTO public.user_roles (user_id, role, is_primary)
    VALUES (v_user_id, p_role, v_is_primary);
  END IF;

  -- Create or update role profile row based on selected role
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

GRANT EXECUTE ON FUNCTION public.apply_role_selection(public.app_role, public.seeker_type) TO authenticated;

-- 3. RPC: anonymize_and_delete_user_data
-- Anonymizes review comments, deletes personal data rows, scrubs profiles row.
-- Financial records (wallets, ledger_entries, payments, disputes) are retained per Decision D11.
-- All table operations are guarded with to_regclass checks for standalone safety.
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

  -- Caller can delete themselves, or an admin can initiate
  IF v_caller_id != p_target_user_id THEN
    IF to_regprocedure('public.is_admin()') IS NOT NULL THEN
      IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
      END IF;
    ELSE
      RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
    END IF;
  END IF;

  -- 1. Anonymize ratings & reviews given or received (using exact column names: rater_id, target_id, comment)
  IF to_regclass('public.ratings_reviews') IS NOT NULL THEN
    UPDATE public.ratings_reviews
    SET comment = '[Account Deleted]'
    WHERE rater_id = p_target_user_id OR target_id = p_target_user_id;
  END IF;

  -- 2. Delete non-financial personal rows (guarded with to_regclass)
  IF to_regclass('public.consent_logs') IS NOT NULL THEN
    DELETE FROM public.consent_logs WHERE user_id = p_target_user_id;
  END IF;

  IF to_regclass('public.favourites') IS NOT NULL THEN
    DELETE FROM public.favourites WHERE user_id = p_target_user_id;
  END IF;

  IF to_regclass('public.emergency_contacts') IS NOT NULL THEN
    DELETE FROM public.emergency_contacts WHERE user_id = p_target_user_id;
  END IF;

  IF to_regclass('public.addresses') IS NOT NULL THEN
    DELETE FROM public.addresses WHERE user_id = p_target_user_id;
  END IF;

  IF to_regclass('public.kyc_records') IS NOT NULL THEN
    DELETE FROM public.kyc_records WHERE user_id = p_target_user_id;
  END IF;

  IF to_regclass('public.worker_skills') IS NOT NULL THEN
    DELETE FROM public.worker_skills WHERE user_id = p_target_user_id;
  END IF;

  IF to_regclass('public.worker_profiles') IS NOT NULL THEN
    DELETE FROM public.worker_profiles WHERE user_id = p_target_user_id;
  END IF;

  IF to_regclass('public.provider_profiles') IS NOT NULL THEN
    DELETE FROM public.provider_profiles WHERE user_id = p_target_user_id;
  END IF;

  IF to_regclass('public.farmer_profiles') IS NOT NULL THEN
    DELETE FROM public.farmer_profiles WHERE user_id = p_target_user_id;
  END IF;

  IF to_regclass('public.user_roles') IS NOT NULL THEN
    DELETE FROM public.user_roles WHERE user_id = p_target_user_id;
  END IF;

  -- Note: Financial records (wallets, ledger_entries, payments, disputes) are retained per Decision D11.

  -- 3. Scrub and delete profile row
  IF to_regclass('public.profiles') IS NOT NULL THEN
    UPDATE public.profiles
    SET full_name = 'Deleted User',
        phone = NULL,
        email = NULL,
        avatar_path = NULL,
        is_suspended = true
    WHERE id = p_target_user_id;

    DELETE FROM public.profiles WHERE id = p_target_user_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'deleted_user_id', p_target_user_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.anonymize_and_delete_user_data(UUID) TO authenticated;

-- 4. Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
