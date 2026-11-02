-- Migration 0430: Fix save_face_embedding RPC authorization
-- Allows service_role from Edge Functions (face-enroll) while keeping strict caller check for authenticated users

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
  v_role TEXT;
  v_result public.face_profiles;
BEGIN
  v_caller := auth.uid();
  
  -- Check role from auth helper or request headers safely
  BEGIN
    v_role := auth.role();
  EXCEPTION WHEN OTHERS THEN
    v_role := NULL;
  END;

  IF v_role IS NULL THEN
    BEGIN
      v_role := current_setting('request.jwt.claim.role', true);
    EXCEPTION WHEN OTHERS THEN
      v_role := NULL;
    END;
  END IF;

  -- Allow service_role or the matching authenticated user or admin
  IF (v_caller IS NULL AND v_role <> 'service_role') OR
     (v_caller IS NOT NULL AND v_caller <> p_user_id AND NOT public.is_admin()) THEN
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

  -- Recompute verification badge for user
  PERFORM public.recompute_verification_badge(p_user_id);

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_face_embedding(UUID, DOUBLE PRECISION[], TIMESTAMPTZ, TEXT) TO authenticated, service_role;
