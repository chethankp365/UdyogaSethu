-- Migration: 0732_fix_claim_eligibility_enum.sql
-- Description: Fix assignment_status enum values in check_claim_eligibility

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

  -- 1. Check QR attendance: verified start or ticket issued or completed
  IF v_assignment.status::TEXT IN ('in_progress_verified', 'completed', 'payment_released', 'disputed') THEN
    v_qr_ok := true;
  END IF;

  -- 2. Check Selfie/GPS check: assignment_events or verification_attempts
  SELECT EXISTS (
    SELECT 1 FROM public.assignment_events
    WHERE assignment_id = p_assignment_id
      AND event_type IN ('verified_start', 'mid_job_check', 'arrival')
  ) INTO v_selfie_gps_ok;

  IF NOT v_selfie_gps_ok AND v_assignment.status::TEXT IN ('in_progress_verified', 'completed', 'payment_released', 'disputed') THEN
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
    'status', v_assignment.status::TEXT,
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
