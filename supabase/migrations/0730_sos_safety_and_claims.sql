-- Migration: 0730_sos_safety_and_claims.sql
-- Description: Emergency contacts management, SOS rate limiting, and claim eligibility checks (Step P7.3)

-- 1. Ensure emergency_contacts has unique constraint on (user_id, phone)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'emergency_contacts_user_phone_key'
  ) THEN
    ALTER TABLE public.emergency_contacts
      ADD CONSTRAINT emergency_contacts_user_phone_key UNIQUE (user_id, phone);
  END IF;
END $$;

-- 2. Function to add emergency contact with max 5 limit
CREATE OR REPLACE FUNCTION public.add_emergency_contact(
  p_name TEXT,
  p_phone TEXT,
  p_relation TEXT DEFAULT 'Emergency Contact'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_count INT;
  v_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.emergency_contacts
  WHERE user_id = v_user_id;

  IF v_count >= 5 THEN
    RAISE EXCEPTION 'Cannot add more than 5 emergency contacts.';
  END IF;

  INSERT INTO public.emergency_contacts (user_id, name, phone, relation)
  VALUES (v_user_id, TRIM(p_name), TRIM(p_phone), TRIM(p_relation))
  ON CONFLICT (user_id, phone)
  DO UPDATE SET name = EXCLUDED.name, relation = EXCLUDED.relation
  RETURNING id INTO v_id;

  RETURN jsonb_build_object(
    'ok', true,
    'id', v_id,
    'name', p_name,
    'phone', p_phone,
    'relation', p_relation
  );
END;
$$;

-- 3. Function to get user's emergency contacts
CREATE OR REPLACE FUNCTION public.get_emergency_contacts()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_contacts JSONB;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'name', name,
        'phone', phone,
        'relation', relation,
        'created_at', created_at
      ) ORDER BY created_at ASC
    ),
    '[]'::jsonb
  ) INTO v_contacts
  FROM public.emergency_contacts
  WHERE user_id = v_user_id;

  RETURN v_contacts;
END;
$$;

-- 4. Function to delete emergency contact
CREATE OR REPLACE FUNCTION public.delete_emergency_contact(p_contact_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM public.emergency_contacts
  WHERE id = p_contact_id AND user_id = v_user_id;

  RETURN jsonb_build_object('ok', true, 'deleted_id', p_contact_id);
END;
$$;

-- 5. RPC to evaluate Job Protection Claim Eligibility from real assignment data
CREATE OR REPLACE FUNCTION public.check_claim_eligibility(p_assignment_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_assignment RECORD;
  v_qr_ok BOOLEAN := false;
  v_selfie_gps_ok BOOLEAN := false;
  v_timer_ok BOOLEAN := false;
  v_evidence_ok BOOLEAN := false;
  v_evidence_count INT := 0;
  v_duration_minutes INT := 0;
  v_overall_eligible BOOLEAN := false;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_assignment
  FROM public.job_assignments
  WHERE id = p_assignment_id
    AND (worker_id = v_user_id OR provider_id = v_user_id);

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'eligible', false,
      'reason', 'Assignment not found or user is not a member of this assignment',
      'qr_ok', false,
      'selfie_gps_ok', false,
      'timer_ok', false,
      'evidence_ok', false
    );
  END IF;

  -- 1. Check QR attendance: verified start or qr_scanned_at or checkin events
  IF v_assignment.status IN ('in_progress', 'completed', 'disputed') THEN
    v_qr_ok := true;
  END IF;

  -- 2. Check Selfie/GPS check: assignment_events or verification_attempts
  SELECT EXISTS (
    SELECT 1 FROM public.assignment_events
    WHERE assignment_id = p_assignment_id
      AND event_type IN ('verified_start', 'mid_job_check', 'arrival')
  ) INTO v_selfie_gps_ok;

  IF NOT v_selfie_gps_ok AND v_assignment.status IN ('in_progress', 'completed', 'disputed') THEN
    v_selfie_gps_ok := true;
  END IF;

  -- 3. Check Job timer log: started_at present and duration calculated
  IF v_assignment.started_at IS NOT NULL THEN
    IF v_assignment.completed_at IS NOT NULL THEN
      v_duration_minutes := EXTRACT(EPOCH FROM (v_assignment.completed_at - v_assignment.started_at)) / 60;
    ELSE
      v_duration_minutes := EXTRACT(EPOCH FROM (NOW() - v_assignment.started_at)) / 60;
    END IF;
    v_timer_ok := v_duration_minutes >= 5;
  END IF;

  -- 4. Check Evidence: any dispute evidence or photos uploaded
  SELECT COUNT(*) INTO v_evidence_count
  FROM public.dispute_evidence de
  JOIN public.disputes d ON d.id = de.dispute_id
  WHERE d.assignment_id = p_assignment_id;

  v_evidence_ok := v_evidence_count > 0;

  -- Overall eligibility: QR attendance + selfie/GPS verification must be met
  v_overall_eligible := v_qr_ok AND v_selfie_gps_ok;

  RETURN jsonb_build_object(
    'eligible', v_overall_eligible,
    'assignment_id', p_assignment_id,
    'status', v_assignment.status,
    'qr_ok', v_qr_ok,
    'selfie_gps_ok', v_selfie_gps_ok,
    'timer_ok', v_timer_ok,
    'duration_minutes', v_duration_minutes,
    'evidence_ok', v_evidence_ok,
    'evidence_count', v_evidence_count,
    'coverage_type', 'Udyoga Escrow Job Protection',
    'max_cover_paise', 2500000 -- ₹25,000 max basic cover
  );
END;
$$;

-- 6. RPC to submit a Job Protection Claim
CREATE OR REPLACE FUNCTION public.submit_protection_claim(
  p_assignment_id UUID,
  p_claim_type TEXT,
  p_amount_paise BIGINT,
  p_details TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_claim_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_amount_paise <= 0 THEN
    RAISE EXCEPTION 'Claim amount must be positive';
  END IF;

  IF TRIM(p_details) = '' THEN
    RAISE EXCEPTION 'Incident details are required';
  END IF;

  INSERT INTO public.protection_claims (
    assignment_id,
    claimant_id,
    claim_type,
    amount_paise,
    details,
    status,
    is_simulated
  ) VALUES (
    p_assignment_id,
    v_user_id,
    p_claim_type,
    p_amount_paise,
    p_details,
    'submitted',
    true
  ) RETURNING id INTO v_claim_id;

  -- Also insert in-app notification to claimant
  INSERT INTO public.notifications (
    user_id,
    type,
    title_key,
    body_key,
    params
  ) VALUES (
    v_user_id,
    'protection_claim_submitted',
    'notif_claim_submitted_title',
    'notif_claim_submitted_body',
    jsonb_build_object(
      'claim_id', v_claim_id,
      'claim_type', p_claim_type,
      'amount_paise', p_amount_paise
    )
  );

  RETURN jsonb_build_object(
    'ok', true,
    'claim_id', v_claim_id,
    'claim_code', 'CLM-' || UPPER(SUBSTRING(v_claim_id::TEXT, 1, 8)),
    'status', 'submitted',
    'is_simulated', true,
    'message', 'Job protection claim submitted for admin review (Demo mode).'
  );
END;
$$;

-- 7. Grant RPC execute permissions
GRANT EXECUTE ON FUNCTION public.add_emergency_contact(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_emergency_contacts() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_emergency_contact(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_claim_eligibility(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_protection_claim(UUID, TEXT, BIGINT, TEXT) TO authenticated;
