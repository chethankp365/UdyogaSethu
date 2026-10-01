-- Migration: 0070_record_consent.sql
-- Description: Function to record terms & privacy policy consent for authenticated user upon initial sign in

CREATE OR REPLACE FUNCTION public.record_user_consent(
  p_granted BOOLEAN DEFAULT true,
  p_version TEXT DEFAULT '1.0'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to log consent';
  END IF;

  INSERT INTO public.consent_logs (user_id, purpose, granted, version)
  VALUES (v_user_id, 'terms'::public.consent_purpose, p_granted, p_version);
END;
$$;

GRANT EXECUTE ON FUNCTION public.record_user_consent(BOOLEAN, TEXT) TO authenticated;
