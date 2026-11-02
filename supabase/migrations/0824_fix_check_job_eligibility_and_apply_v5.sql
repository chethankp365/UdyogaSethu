-- ============================================================================
-- Migration: 0824_fix_check_job_eligibility_and_apply_v5.sql
-- Description:
--   Fix check_job_eligibility(UUID):
--   - Correct active assignment_status values:
--     'requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified'
--     (enum assignment_status has 'in_progress_verified', not 'in_progress').
-- ============================================================================

DROP FUNCTION IF EXISTS public.check_job_eligibility(UUID);

CREATE OR REPLACE FUNCTION public.check_job_eligibility(p_job_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_job RECORD;
  v_wp RECORD;
  v_worker_type TEXT;
  v_suitable_texts TEXT[];
  v_already_applied BOOLEAN := false;
  v_is_own_job BOOLEAN := false;
  v_is_past_start BOOLEAN := false;
  v_is_slots_filled BOOLEAN := false;
  v_licence_needed BOOLEAN := false;
  v_has_licence BOOLEAN := false;
  v_verified_needed BOOLEAN := false;
  v_is_verified BOOLEAN := false;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_code TEXT := 'ELIGIBLE';
  v_overlap_title TEXT;
  v_schedule_overlap BOOLEAN := false;
  v_audience_mismatch BOOLEAN := false;
  v_job_end TIMESTAMPTZ;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object(
      'is_eligible', false,
      'reason_code', 'NOT_AUTHENTICATED',
      'reasons', ARRAY['Sign in required to apply for jobs.']
    );
  END IF;

  -- 1. Fetch Job with exact columns of public.jobs
  SELECT
    id, provider_id, title, category_id, suitable_for,
    requirements, slots_total, slots_filled, start_at, est_duration_minutes, status
  INTO v_job
  FROM public.jobs
  WHERE id = p_job_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'is_eligible', false,
      'reason_code', 'JOB_NOT_FOUND',
      'reasons', ARRAY['Job posting not found.']
    );
  END IF;

  -- 2. Fetch Worker Profile
  SELECT
    user_id, seeker_type, is_verified_badge, has_driving_licence
  INTO v_wp
  FROM public.worker_profiles
  WHERE user_id = v_uid;

  v_worker_type := COALESCE(v_wp.seeker_type::TEXT, 'informal');

  -- 3. Check Own Job
  IF v_job.provider_id = v_uid THEN
    v_is_own_job := true;
    v_reasons := array_append(v_reasons, 'You cannot apply to your own job posting.');
    v_code := 'OWN_JOB';
  END IF;

  -- 4. Check Expired / Closed (job_status enum: 'draft', 'open', 'filled', 'closed', 'cancelled')
  IF v_job.status::TEXT IN ('closed', 'cancelled') THEN
    v_is_past_start := true;
    v_reasons := array_append(v_reasons, 'This job is closed.');
    v_code := 'EXPIRED';
  END IF;

  -- 5. Check Slots Filled
  IF v_job.slots_filled >= v_job.slots_total THEN
    v_is_slots_filled := true;
    v_reasons := array_append(v_reasons, 'All slots for this job are filled.');
    v_code := 'SLOTS_FILLED';
  END IF;

  -- 6. Check Already Applied
  SELECT EXISTS(
    SELECT 1 FROM public.job_applications
    WHERE job_id = p_job_id AND worker_id = v_uid AND status != 'withdrawn'
  ) INTO v_already_applied;

  IF v_already_applied THEN
    v_reasons := array_append(v_reasons, 'You have already applied for this job.');
    v_code := 'ALREADY_APPLIED';
  END IF;

  -- 7. Audience Compatibility Check
  IF v_job.suitable_for IS NOT NULL AND array_length(v_job.suitable_for, 1) > 0 THEN
    v_suitable_texts := v_job.suitable_for::TEXT[];
    IF NOT (v_worker_type = ANY(v_suitable_texts) OR 'all' = ANY(v_suitable_texts)) THEN
      v_audience_mismatch := true;
      v_reasons := array_append(v_reasons, 'Audience requirement mismatch for this role.');
      IF v_code = 'ELIGIBLE' THEN v_code := 'AUDIENCE_MISMATCH'; END IF;
    END IF;
  END IF;

  -- 8. Driving Licence Requirement
  v_licence_needed := COALESCE((v_job.requirements->>'licence_required')::BOOLEAN, false);
  v_has_licence := COALESCE(v_wp.has_driving_licence, false);
  IF v_licence_needed AND NOT v_has_licence THEN
    v_reasons := array_append(v_reasons, 'A valid driving licence is required for this role.');
    IF v_code = 'ELIGIBLE' THEN v_code := 'LICENCE_REQUIRED'; END IF;
  END IF;

  -- 9. Verified Badge Requirement
  v_verified_needed := COALESCE((v_job.requirements->>'verified_required')::BOOLEAN, false);
  v_is_verified := COALESCE(v_wp.is_verified_badge, false);
  IF v_verified_needed AND NOT v_is_verified THEN
    v_reasons := array_append(v_reasons, 'A verified profile badge is required for this role.');
    IF v_code = 'ELIGIBLE' THEN v_code := 'VERIFIED_REQUIRED'; END IF;
  END IF;

  -- 10. Schedule Conflict Check (with active job assignments)
  IF v_job.start_at IS NOT NULL THEN
    v_job_end := v_job.start_at + (COALESCE(v_job.est_duration_minutes, 120) || ' minutes')::INTERVAL;

    SELECT j2.title INTO v_overlap_title
    FROM public.job_assignments ja2
    JOIN public.jobs j2 ON ja2.job_id = j2.id
    WHERE ja2.worker_id = v_uid
      AND ja2.status IN ('requested', 'accepted', 'ticket_issued', 'arrived', 'in_progress_verified')
      AND j2.start_at < v_job_end
      AND (j2.start_at + (COALESCE(j2.est_duration_minutes, 120) || ' minutes')::INTERVAL) > v_job.start_at
      AND j2.id != p_job_id
    LIMIT 1;

    IF v_overlap_title IS NOT NULL THEN
      v_schedule_overlap := true;
      v_reasons := array_append(v_reasons, 'Schedule conflict with active booking "' || v_overlap_title || '".');
      IF v_code = 'ELIGIBLE' THEN v_code := 'SCHEDULE_CLASH'; END IF;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'is_eligible', (array_length(v_reasons, 1) IS NULL OR array_length(v_reasons, 1) = 0),
    'reason_code', v_code,
    'reasons', v_reasons,
    'already_applied', v_already_applied,
    'is_own_job', v_is_own_job,
    'is_past_start', v_is_past_start,
    'is_slots_filled', v_is_slots_filled,
    'audience_mismatch', v_audience_mismatch,
    'student_gated', v_audience_mismatch,
    'licence_needed', v_licence_needed,
    'has_licence', v_has_licence,
    'verified_needed', v_verified_needed,
    'is_verified', v_is_verified,
    'schedule_overlap', v_schedule_overlap,
    'overlap_job_title', v_overlap_title
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_job_eligibility(UUID) TO authenticated, anon;
