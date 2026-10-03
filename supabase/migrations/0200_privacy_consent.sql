-- Migration: 0200_privacy_consent.sql
-- Description: RPCs for user consent management and face reference scrubbing under Phase 3.1.
-- Prerequisite migrations: 0010_identity.sql and 0030_money_trust.sql must be run before this migration.

-- 1. Function: revoke_consent
-- Revokes consent for a given purpose for the authenticated user in consent_logs.
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

  -- Record consent revocation in consent_logs
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

-- 2. Function: withdraw_face_consent
-- Revokes face verification consent and scrubs face reference and matcher records.
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

  -- 1. Record consent revocation in consent_logs
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

  -- 2. Scrub face profile vector reference if face_profiles table exists
  IF to_regclass('public.face_profiles') IS NOT NULL THEN
    DELETE FROM public.face_profiles WHERE user_id = v_user_id;
  END IF;

  -- 3. Scrub face verification attempts if verification_attempts table exists
  IF to_regclass('public.verification_attempts') IS NOT NULL THEN
    DELETE FROM public.verification_attempts 
    WHERE user_id = v_user_id AND verification_type = 'face';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Face verification consent withdrawn and matcher reference erased.',
    'user_id', v_user_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.withdraw_face_consent() TO authenticated;

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
