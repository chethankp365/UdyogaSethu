-- Migration: 0310_public_verification_enhancement.sql
-- Description: Enhances get_public_verification RPC to compute display_id (e.g. UDY2026xxxx),
--              level name from levels/xp_events, and training verification timestamp,
--              while strictly returning ONLY public non-PII fields.

CREATE OR REPLACE FUNCTION public.get_public_verification(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_name TEXT;
  v_initial TEXT;
  v_badge BOOLEAN := false;
  v_total_xp INT := 0;
  v_level INT := 1;
  v_level_name TEXT := 'Starter';
  v_kyc_date TIMESTAMPTZ;
  v_face_date TIMESTAMPTZ;
  v_training_date TIMESTAMPTZ;
  v_created_at TIMESTAMPTZ;
  v_year TEXT;
  v_hex_suffix TEXT;
  v_display_id TEXT;
BEGIN
  -- 1. Name initial
  SELECT full_name, created_at INTO v_name, v_created_at 
  FROM public.profiles 
  WHERE id = p_user_id;

  IF v_name IS NOT NULL AND LENGTH(TRIM(v_name)) > 0 THEN
    v_initial := UPPER(SUBSTRING(TRIM(v_name), 1, 1)) || '.';
  ELSE
    v_initial := 'U.';
  END IF;

  -- 2. Display ID: UDY + Year + Last 4 chars of user UUID
  v_year := TO_CHAR(COALESCE(v_created_at, NOW()), 'YYYY');
  v_hex_suffix := UPPER(RIGHT(REPLACE(p_user_id::text, '-', ''), 4));
  v_display_id := 'UDY' || v_year || v_hex_suffix;

  -- 3. Verified badge
  SELECT COALESCE(is_verified_badge, false) INTO v_badge 
  FROM public.worker_profiles 
  WHERE user_id = p_user_id;

  -- 4. Level & Level Name from XP
  SELECT COALESCE(SUM(points), 0) INTO v_total_xp 
  FROM public.xp_events 
  WHERE user_id = p_user_id;

  SELECT level_number, name INTO v_level, v_level_name
  FROM public.levels
  WHERE min_xp <= v_total_xp
  ORDER BY min_xp DESC
  LIMIT 1;

  IF v_level IS NULL THEN
    v_level := 1;
    v_level_name := 'Starter';
  END IF;

  -- 5. KYC verified date
  SELECT verified_at INTO v_kyc_date 
  FROM public.kyc_records 
  WHERE user_id = p_user_id AND status = 'verified' 
  ORDER BY verified_at DESC 
  LIMIT 1;

  -- 6. Face verified date
  SELECT liveness_passed_at INTO v_face_date 
  FROM public.face_profiles 
  WHERE user_id = p_user_id AND status = 'verified' 
  LIMIT 1;

  -- 7. 1-Day Training verified date
  SELECT er.updated_at INTO v_training_date
  FROM public.event_registrations er
  JOIN public.training_events te ON er.event_id = te.id
  WHERE er.user_id = p_user_id 
    AND te.kind = 'safety_onboarding' 
    AND er.status IN ('attended', 'approved')
  ORDER BY er.updated_at DESC
  LIMIT 1;

  -- Return ONLY public non-PII fields
  RETURN jsonb_build_object(
    'valid', true,
    'name_initial', v_initial,
    'display_id', v_display_id,
    'is_verified_badge', COALESCE(v_badge, false),
    'level', v_level,
    'level_name', v_level_name,
    'kyc_verified_at', v_kyc_date,
    'face_verified_at', v_face_date,
    'training_verified_at', v_training_date
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_public_verification(UUID) TO authenticated, anon;
