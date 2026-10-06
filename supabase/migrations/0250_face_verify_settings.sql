-- Migration: 0250_face_verify_settings.sql
-- Description: Seeds face_match_threshold into admin_settings using correct schema (key, value),
--              enforces strict RLS table security on verification tables, restricts biometric embedding column SELECT,
--              creates SECURITY DEFINER RPC get_face_login_requirement, and grants necessary permissions.

-- DEPENDENCY AUDIT:
-- Tables:
--   - public.admin_settings (key, value, updated_by, updated_at) [0040_engagement_admin.sql - PRESENT]
--   - public.verification_attempts (id, user_id, context, assignment_id, liveness_ok, match_score, gps_ok, distance_m, result, created_at) [0030_money_trust.sql - PRESENT]
--   - public.fraud_flags (id, user_id, rule_key, severity, ref_type, ref_id, evidence, status, created_at) [0030_money_trust.sql - PRESENT]
--   - public.face_profiles (id, user_id, reference_path, matcher_ref, liveness_passed_at, status, embedding, created_at, updated_at) [0030_money_trust.sql & 0220_face_embedding.sql - PRESENT]
--   - public.kyc_records (id, user_id, doc_type, status, ...) [0030_money_trust.sql - PRESENT]
-- Enums:
--   - public.verification_context ('login', 'job_start', 'mid_job', 'completion') [0030_money_trust.sql - PRESENT]
--   - public.verification_attempt_result ('pass', 'fail', 'manual_review_required', 'error') [0030_money_trust.sql - PRESENT]
--   - public.fraud_severity ('low', 'medium', 'high', 'critical') [0030_money_trust.sql - PRESENT]
-- Functions:
--   - public.is_admin() [0050_rls_storage.sql - PRESENT]
--   - public.has_role(public.app_role) [0050_rls_storage.sql - PRESENT]

-- 1. Seed face_match_threshold default setting ('0.65'::jsonb) into admin_settings
INSERT INTO public.admin_settings (key, value)
VALUES ('face_match_threshold', '0.65'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- 2. Drop any client insert policy on verification_attempts to enforce server-side service_role logging only
DROP POLICY IF EXISTS verification_attempts_insert ON public.verification_attempts;

-- 3. Enable RLS on all admin and verification tables (safe to repeat)
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.face_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kyc_records ENABLE ROW LEVEL SECURITY;

-- 4. Recreate admin_settings_select policy to strictly restrict direct SELECT to admins only
DROP POLICY IF EXISTS admin_settings_select ON public.admin_settings;
CREATE POLICY admin_settings_select ON public.admin_settings FOR SELECT USING (public.is_admin());

-- 5. Restrict biometric embedding vector column from direct SELECT by authenticated/anon roles
REVOKE SELECT ON public.face_profiles FROM authenticated, anon;
GRANT SELECT (id, user_id, reference_path, matcher_ref, liveness_passed_at, consent_log_id, status, created_at, updated_at) ON public.face_profiles TO authenticated;
GRANT ALL ON public.face_profiles TO service_role;

-- 6. Create SECURITY DEFINER function get_face_login_requirement()
-- Returns true ONLY if:
--   (a) face_required_at_login is true in admin_settings AND
--   (b) calling user's active role is 'seeker' (workers).
-- Returns false for farmers, providers, and unauthenticated/anon callers.
-- Note: No per-user switch currently exists in profiles schema.
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
      v_setting_bool := (v_setting_val->>0) = 'true' OR (v_setting_val#>>'{}') = 'true';
    ELSIF jsonb_typeof(v_setting_val) = 'number' THEN
      v_setting_bool := (v_setting_val::text) = '1';
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

-- Grant execution ONLY to authenticated users and service_role
REVOKE ALL ON FUNCTION public.get_face_login_requirement() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_face_login_requirement() TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
