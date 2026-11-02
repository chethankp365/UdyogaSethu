-- Migration 0830: Robust face embedding registration and RLS permissions
-- 1. Grant SELECT, INSERT, UPDATE on face_profiles to authenticated and service_role
GRANT SELECT, INSERT, UPDATE ON public.face_profiles TO authenticated, service_role;

-- 2. Ensure RLS policies exist for authenticated users to insert/update their own face profile
ALTER TABLE public.face_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS face_profiles_insert ON public.face_profiles;
CREATE POLICY face_profiles_insert ON public.face_profiles
  FOR INSERT WITH CHECK (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS face_profiles_update ON public.face_profiles;
CREATE POLICY face_profiles_update ON public.face_profiles
  FOR UPDATE USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS face_profiles_select ON public.face_profiles;
CREATE POLICY face_profiles_select ON public.face_profiles
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

-- 3. Replace save_face_embedding with robust version that returns JSONB and handles foreign keys
DROP FUNCTION IF EXISTS public.save_face_embedding(UUID, DOUBLE PRECISION[], TIMESTAMPTZ, TEXT);

CREATE OR REPLACE FUNCTION public.save_face_embedding(
  p_user_id UUID,
  p_embedding DOUBLE PRECISION[],
  p_liveness_passed_at TIMESTAMPTZ DEFAULT NOW(),
  p_matcher_ref TEXT DEFAULT 'ondevice'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rec RECORD;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID is required' USING ERRCODE = 'P0001';
  END IF;

  -- Ensure profile exists in public.profiles to satisfy foreign key constraint
  INSERT INTO public.profiles (id, active_role)
  VALUES (p_user_id, 'seeker')
  ON CONFLICT (id) DO NOTHING;

  -- Upsert face profile record
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
    COALESCE(p_matcher_ref, 'ondevice'),
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
    embedding = COALESCE(EXCLUDED.embedding, face_profiles.embedding),
    updated_at = NOW()
  RETURNING id, user_id, status, matcher_ref, liveness_passed_at, updated_at INTO v_rec;

  -- Recompute verified badge for the user
  BEGIN
    PERFORM public.recompute_verification_badge(p_user_id);
  EXCEPTION WHEN OTHERS THEN
    -- Never block face saving if badge recalculation fails
    NULL;
  END;

  RETURN jsonb_build_object(
    'id', v_rec.id,
    'user_id', v_rec.user_id,
    'status', v_rec.status,
    'matcher_ref', v_rec.matcher_ref,
    'liveness_passed_at', v_rec.liveness_passed_at,
    'updated_at', v_rec.updated_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_face_embedding(UUID, DOUBLE PRECISION[], TIMESTAMPTZ, TEXT) TO authenticated, service_role, anon;
