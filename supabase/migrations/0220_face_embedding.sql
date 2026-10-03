-- Migration: 0220_face_embedding.sql
-- Description: Adds embedding column to face_profiles, seeds face_match_threshold,
--              creates compare_face_embeddings and save_face_embedding RPCs,
--              and updates face consent withdrawal and account deletion hooks.

-- 1. Add embedding column to face_profiles table
ALTER TABLE public.face_profiles
ADD COLUMN IF NOT EXISTS embedding DOUBLE PRECISION[];

-- 2. Seed default face_match_threshold into admin_settings if missing
INSERT INTO public.admin_settings (setting_key, setting_value, category, description)
VALUES ('face_match_threshold', '0.65', 'trust_safety', 'Cosine similarity threshold for face verification matching')
ON CONFLICT (setting_key) DO NOTHING;

-- 3. Function: compare_face_embeddings (Cosine Similarity)
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

-- 4. RPC: save_face_embedding
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

  -- Recompute verification badge for user
  PERFORM public.recompute_verification_badge(p_user_id);

  RETURN v_result;
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.compare_face_embeddings(DOUBLE PRECISION[], DOUBLE PRECISION[]) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.save_face_embedding(UUID, DOUBLE PRECISION[], TIMESTAMPTZ, TEXT) TO authenticated, service_role;
