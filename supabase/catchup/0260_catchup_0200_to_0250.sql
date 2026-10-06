-- Catch-Up Migration Script: 0260_catchup_0200_to_0250.sql
-- Description: Consolidated, 100% idempotent catch-up script bringing any live Supabase database
--              to the full schema, RPC, and security state specified by migrations 0200 through 0250 inclusive.
-- Safety Guarantee:
--   - Safe to execute repeatedly on live or existing databases.
--   - Non-destructive: Does NOT drop tables, drop columns, truncate data, or overwrite existing user settings.
--   - Idempotent: Uses IF NOT EXISTS, DROP POLICY/TRIGGER IF EXISTS before creation, ON CONFLICT DO NOTHING,
--     and explicit column-level grants in correct dependency order.

-- ============================================================================
-- 1. FROM 0200_privacy_consent.sql (Consent Management RPCs)
-- Rationale for repeat safety: CREATE OR REPLACE FUNCTION is idempotent.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.revoke_consent(
  p_purpose TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  IF to_regclass('public.consent_logs') IS NOT NULL THEN
    INSERT INTO public.consent_logs (
      user_id,
      consent_type,
      granted,
      granted_at,
      metadata
    ) VALUES (
      v_user_id,
      p_purpose,
      false,
      now(),
      jsonb_build_object('action', 'revoked_by_user', 'revoked_at', now())
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'purpose', p_purpose,
    'user_id', v_user_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.revoke_consent(TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.withdraw_face_consent()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  IF to_regclass('public.consent_logs') IS NOT NULL THEN
    INSERT INTO public.consent_logs (
      user_id,
      consent_type,
      granted,
      granted_at,
      metadata
    ) VALUES (
      v_user_id,
      'face',
      false,
      now(),
      jsonb_build_object('action', 'withdrawn_face_consent', 'withdrawn_at', now())
    );
  END IF;

  IF to_regclass('public.face_profiles') IS NOT NULL THEN
    DELETE FROM public.face_profiles WHERE user_id = v_user_id;
  END IF;

  IF to_regclass('public.verification_attempts') IS NOT NULL THEN
    DELETE FROM public.verification_attempts 
    WHERE user_id = v_user_id AND context = 'login';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Face verification consent withdrawn and matcher reference erased.',
    'user_id', v_user_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.withdraw_face_consent() TO authenticated;

-- ============================================================================
-- 2. FROM 0210_verification_extra.sql (Service Categories & Nearby Jobs RPC)
-- Rationale for repeat safety: ADD COLUMN IF NOT EXISTS, UPDATE is idempotent,
-- ADD VALUE IF NOT EXISTS for enums, CREATE OR REPLACE FUNCTION.
-- ============================================================================

ALTER TABLE public.service_categories
ADD COLUMN IF NOT EXISTS requires_licence BOOLEAN NOT NULL DEFAULT false;

UPDATE public.service_categories
SET requires_licence = true
WHERE slug IN ('driver', 'delivery', 'delivery-gig-work');

ALTER TYPE public.doc_type ADD VALUE IF NOT EXISTS 'student_id';
ALTER TYPE public.doc_type ADD VALUE IF NOT EXISTS 'bank_account';
ALTER TYPE public.doc_type ADD VALUE IF NOT EXISTS 'upi';

CREATE OR REPLACE FUNCTION public.nearby_jobs_for_worker(
  p_worker_id UUID,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 10000,
  p_category_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  category_id UUID,
  title TEXT,
  description TEXT,
  wage_type public.wage_type,
  wage_paise BIGINT,
  start_at TIMESTAMPTZ,
  slots_total INT,
  slots_filled INT,
  address_text TEXT,
  distance_m DOUBLE PRECISION,
  requires_licence_gated BOOLEAN,
  verified_only_gated BOOLEAN,
  is_eligible BOOLEAN,
  ineligibility_reason TEXT
) AS $$
DECLARE
  v_point extensions.geography;
  v_has_dl BOOLEAN := false;
  v_has_bgc BOOLEAN := false;
BEGIN
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(p_lng, p_lat), 4326)::extensions.geography;

  SELECT EXISTS (
    SELECT 1 FROM public.kyc_records
    WHERE user_id = p_worker_id
      AND doc_type IN ('driving_licence')
      AND status = 'verified'
  ) INTO v_has_dl;

  SELECT EXISTS (
    SELECT 1 FROM public.kyc_records
    WHERE user_id = p_worker_id
      AND doc_type = 'background_check'
      AND status = 'verified'
  ) INTO v_has_bgc;

  RETURN QUERY
  SELECT
    j.id,
    j.provider_id,
    j.category_id,
    j.title,
    j.description,
    j.wage_type,
    j.wage_paise,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    j.address_text,
    extensions.ST_Distance(j.location, v_point) AS distance_m,
    COALESCE(sc.requires_licence, false) AS requires_licence_gated,
    COALESCE((j.requirements->>'verified_only')::boolean, false) AS verified_only_gated,
    CASE
      WHEN COALESCE(sc.requires_licence, false) AND NOT v_has_dl THEN false
      WHEN COALESCE((j.requirements->>'verified_only')::boolean, false) AND NOT v_has_bgc THEN false
      ELSE true
    END AS is_eligible,
    CASE
      WHEN COALESCE(sc.requires_licence, false) AND NOT v_has_dl THEN 'Requires Verified Driving Licence'
      WHEN COALESCE((j.requirements->>'verified_only')::boolean, false) AND NOT v_has_bgc THEN 'Requires Verified Background Check'
      ELSE NULL
    END AS ineligibility_reason
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  WHERE j.status = 'open'
    AND j.location IS NOT NULL
    AND extensions.ST_DWithin(j.location, v_point, p_radius_m)
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
  ORDER BY distance_m ASC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 3. FROM 0220_face_embedding.sql (Face Vector Embedding & Matching RPCs)
-- Rationale for repeat safety: ADD COLUMN IF NOT EXISTS, CREATE OR REPLACE FUNCTION,
-- GRANT EXECUTE is safe to repeat.
-- ============================================================================

ALTER TABLE public.face_profiles
ADD COLUMN IF NOT EXISTS embedding DOUBLE PRECISION[];

CREATE OR REPLACE FUNCTION public.compare_face_embeddings(
  v1 DOUBLE PRECISION[],
  v2 DOUBLE PRECISION[]
)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
IMMUTABLE
STRICT
AS $$
DECLARE
  v_dot DOUBLE PRECISION := 0.0;
  v_norm1 DOUBLE PRECISION := 0.0;
  v_norm2 DOUBLE PRECISION := 0.0;
  v_len INTEGER;
  i INTEGER;
BEGIN
  IF v1 IS NULL OR v2 IS NULL THEN
    RETURN 0.0;
  END IF;

  v_len := array_length(v1, 1);
  IF v_len IS NULL OR v_len <> array_length(v2, 1) OR v_len = 0 THEN
    RETURN 0.0;
  END IF;

  FOR i IN 1..v_len LOOP
    v_dot := v_dot + (v1[i] * v2[i]);
    v_norm1 := v_norm1 + (v1[i] * v1[i]);
    v_norm2 := v_norm2 + (v2[i] * v2[i]);
  END LOOP;

  IF v_norm1 <= 0.0 OR v_norm2 <= 0.0 THEN
    RETURN 0.0;
  END IF;

  RETURN v_dot / (sqrt(v_norm1) * sqrt(v_norm2));
END;
$$;

CREATE OR REPLACE FUNCTION public.save_face_embedding(
  p_user_id UUID,
  p_embedding DOUBLE PRECISION[],
  p_liveness_passed_at TIMESTAMPTZ,
  p_matcher_ref TEXT DEFAULT 'ondevice'
)
RETURNS public.face_profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID;
  v_result public.face_profiles;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL OR (v_caller <> p_user_id AND NOT public.is_admin()) THEN
    RAISE EXCEPTION 'Unauthorized face embedding registration' USING ERRCODE = 'P0001';
  END IF;

  IF p_embedding IS NULL OR array_length(p_embedding, 1) < 64 THEN
    RAISE EXCEPTION 'Invalid face embedding vector dimension' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.face_profiles (
    user_id,
    reference_path,
    matcher_ref,
    liveness_passed_at,
    status,
    embedding,
    updated_at
  )
  VALUES (
    p_user_id,
    'face-refs/' || p_user_id || '/ref.jpg',
    p_matcher_ref,
    COALESCE(p_liveness_passed_at, NOW()),
    'verified',
    p_embedding,
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    reference_path = EXCLUDED.reference_path,
    matcher_ref = EXCLUDED.matcher_ref,
    liveness_passed_at = EXCLUDED.liveness_passed_at,
    status = 'verified',
    embedding = EXCLUDED.embedding,
    updated_at = NOW()
  RETURNING * INTO v_result;

  PERFORM public.recompute_verification_badge(p_user_id);

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.compare_face_embeddings(DOUBLE PRECISION[], DOUBLE PRECISION[]) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.save_face_embedding(UUID, DOUBLE PRECISION[], TIMESTAMPTZ, TEXT) TO authenticated, service_role;

-- ============================================================================
-- 4. FROM 0230_verification_visibility_guard.sql (Server-Side KYC Validation Trigger)
-- Rationale for repeat safety: CREATE OR REPLACE FUNCTION, DROP TRIGGER IF EXISTS.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_kyc_record_visibility()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
  v_seeker_type text;
BEGIN
  IF NEW.doc_type = 'driving_licence' THEN
    SELECT role INTO v_role
    FROM public.user_roles
    WHERE user_id = NEW.user_id AND role = 'seeker'
    LIMIT 1;

    IF v_role IS NULL THEN
      RAISE EXCEPTION 'Driving licence verification is restricted to job seekers only.'
        USING ERRCODE = 'P0003';
    END IF;
  END IF;

  IF NEW.doc_type = 'college_id' THEN
    SELECT seeker_type INTO v_seeker_type
    FROM public.worker_profiles
    WHERE user_id = NEW.user_id
    LIMIT 1;

    IF v_seeker_type IS NULL OR v_seeker_type <> 'student' THEN
      RAISE EXCEPTION 'Student verification is restricted to student job seekers only.'
        USING ERRCODE = 'P0004';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_kyc_record_visibility ON public.kyc_records;

CREATE TRIGGER trg_check_kyc_record_visibility
  BEFORE INSERT OR UPDATE ON public.kyc_records
  FOR EACH ROW
  EXECUTE FUNCTION public.check_kyc_record_visibility();

-- ============================================================================
-- 5. FROM 0240_sync_avatar_paths.sql (Avatar Path Column Guarantee)
-- Rationale for repeat safety: ADD COLUMN IF NOT EXISTS.
-- ============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_path TEXT;

-- ============================================================================
-- 6. FROM 0250_face_verify_settings.sql (Verification Security & Settings)
-- Rationale for repeat safety: ON CONFLICT DO NOTHING, DROP POLICY IF EXISTS,
-- ENABLE ROW LEVEL SECURITY is safe to repeat, REVOKE/GRANT is safe to repeat.
-- ============================================================================

INSERT INTO public.admin_settings (key, value)
VALUES ('face_match_threshold', '0.65'::jsonb)
ON CONFLICT (key) DO NOTHING;

DROP POLICY IF EXISTS verification_attempts_insert ON public.verification_attempts;

ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.face_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kyc_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_settings_select ON public.admin_settings;
CREATE POLICY admin_settings_select ON public.admin_settings FOR SELECT USING (public.is_admin());

REVOKE SELECT ON public.face_profiles FROM authenticated, anon;
GRANT SELECT (id, user_id, reference_path, matcher_ref, liveness_passed_at, consent_log_id, status, created_at, updated_at) ON public.face_profiles TO authenticated;
GRANT ALL ON public.face_profiles TO service_role;

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

  v_is_seeker := public.has_role('seeker'::public.app_role);

  RETURN COALESCE(v_is_seeker, false);
END;
$$;

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

REVOKE ALL ON FUNCTION public.get_face_login_requirement() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_face_login_requirement() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_bootstrap_state() TO authenticated;

NOTIFY pgrst, 'reload schema';
