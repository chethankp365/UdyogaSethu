-- Migration: 0280_qr_tokens.sql
-- Description: Creates qr_tokens table for server-side token hashes & revocation,
--              seeds qr_expiry_seconds in admin_settings, and updates get_public_verification RPC.

-- 1. Table: qr_tokens
CREATE TABLE IF NOT EXISTS public.qr_tokens (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  token_id_hash TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  purpose TEXT NOT NULL DEFAULT 'profile',
  expires_at TIMESTAMPTZ NOT NULL,
  revoked BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on qr_tokens
ALTER TABLE public.qr_tokens ENABLE ROW LEVEL SECURITY;

-- Indexes for fast token lookup & revocation
CREATE INDEX IF NOT EXISTS idx_qr_tokens_hash ON public.qr_tokens (token_id_hash);
CREATE INDEX IF NOT EXISTS idx_qr_tokens_user ON public.qr_tokens (user_id);

-- RLS Policies
DROP POLICY IF EXISTS qr_tokens_select ON public.qr_tokens;
CREATE POLICY qr_tokens_select ON public.qr_tokens 
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS qr_tokens_insert ON public.qr_tokens;
CREATE POLICY qr_tokens_insert ON public.qr_tokens 
  FOR INSERT WITH CHECK (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS qr_tokens_update ON public.qr_tokens;
CREATE POLICY qr_tokens_update ON public.qr_tokens 
  FOR UPDATE USING (user_id = auth.uid() OR public.is_admin());

-- 2. Seed qr_expiry_seconds setting in admin_settings
INSERT INTO public.admin_settings (setting_key, setting_value, description)
VALUES ('qr_expiry_seconds', '300'::jsonb, 'Default lifetime in seconds for profile QR code verification tokens (5 mins).')
ON CONFLICT (setting_key) DO UPDATE 
SET setting_value = EXCLUDED.setting_value, updated_at = NOW();

-- 3. RPC: get_public_verification (Returns ONLY public fields: initial, badge, level, dates)
CREATE OR REPLACE FUNCTION public.get_public_verification(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_name TEXT;
  v_initial TEXT;
  v_badge BOOLEAN := false;
  v_level INT := 1;
  v_kyc_date TIMESTAMPTZ;
  v_face_date TIMESTAMPTZ;
BEGIN
  -- Get user name initial
  SELECT full_name INTO v_name FROM public.profiles WHERE id = p_user_id;
  IF v_name IS NOT NULL AND LENGTH(v_name) > 0 THEN
    v_initial := UPPER(SUBSTRING(v_name, 1, 1)) || '.';
  ELSE
    v_initial := 'U.';
  END IF;

  -- Get verified badge status from worker_profiles
  SELECT COALESCE(is_verified_badge, false) INTO v_badge 
  FROM public.worker_profiles 
  WHERE user_id = p_user_id;

  -- Get KYC verified date
  SELECT verified_at INTO v_kyc_date 
  FROM public.kyc_records 
  WHERE user_id = p_user_id AND status = 'verified' 
  ORDER BY verified_at DESC 
  LIMIT 1;

  -- Get Face liveness date
  SELECT liveness_passed_at INTO v_face_date 
  FROM public.face_profiles 
  WHERE user_id = p_user_id AND status = 'verified' 
  LIMIT 1;

  RETURN jsonb_build_object(
    'name_initial', v_initial,
    'is_verified_badge', COALESCE(v_badge, false),
    'level', v_level,
    'kyc_verified_at', v_kyc_date,
    'face_verified_at', v_face_date
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 4. RPC: revoke_qr_token
CREATE OR REPLACE FUNCTION public.revoke_qr_token(p_token_id_hash TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.qr_tokens
  SET revoked = true
  WHERE token_id_hash = p_token_id_hash;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.get_public_verification(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.revoke_qr_token(TEXT) TO authenticated;
