-- Migration: 0230_verification_visibility_guard.sql
-- Description: Server-side validation guards enforcing role and seeker-type constraints for KYC verification records.
-- Relies on tables: public.kyc_records (0030), public.worker_profiles (0010), public.user_roles (0010)

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
  -- Check driving_licence document type (Restricted to seekers)
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

  -- Check college_id document type (Restricted to student seekers)
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

NOTIFY pgrst, 'reload schema';
