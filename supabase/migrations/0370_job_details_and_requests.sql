-- Migration: 0370_job_details_and_requests.sql
-- Description: RPCs for Job Detail, Pre-Application Eligibility Checks, and Debug Seeding for Overlapping Requests.

-- ============================================================================
-- 1. RPC: check_job_eligibility
-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_job_eligibility(
  p_job_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_worker_id UUID;
  v_seeker_type TEXT := 'informal';
  v_has_dl BOOLEAN := false;
  v_is_verified BOOLEAN := false;
  v_job RECORD;
  v_licence_needed BOOLEAN := false;
  v_verified_needed BOOLEAN := false;
  v_student_gated BOOLEAN := false;
  v_schedule_overlap BOOLEAN := false;
  v_overlap_job_title TEXT := NULL;
  v_already_applied BOOLEAN := false;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_is_eligible BOOLEAN := true;
  v_job_end TIMESTAMPTZ;
  v_effective_audience TEXT[];
BEGIN
  v_worker_id := auth.uid();
  IF v_worker_id IS NULL THEN
    RETURN jsonb_build_object(
      'is_eligible', false,
      'reasons', ARRAY['Authentication required.']::TEXT[]
    );
  END IF;

  -- 1. Fetch worker profile details
  SELECT COALESCE(wp.seeker_type, sp.seeker_type::text, 'informal'),
         COALESCE(wp.has_driving_licence, sp.has_driving_licence, false),
         COALESCE(p.is_verified_badge, false)
  INTO v_seeker_type, v_has_dl, v_is_verified
  FROM public.profiles p
  LEFT JOIN public.worker_profiles wp ON wp.user_id = p.id
  LEFT JOIN public.seeker_profiles sp ON sp.user_id = p.id
  WHERE p.id = v_worker_id;

  -- 2. Fetch job details
  SELECT j.*, sc.audience, sc.name AS category_name, sc.slug AS category_slug
  INTO v_job
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  IF v_job.id IS NULL THEN
    RETURN jsonb_build_object('is_eligible', false, 'reasons', ARRAY['Job not found.']::TEXT[]);
  END IF;

  -- 3. Check if already applied
  SELECT EXISTS (
    SELECT 1 FROM public.job_applications
    WHERE job_id = p_job_id AND worker_id = v_worker_id
  ) INTO v_already_applied;

  -- 4. Driving licence check
  IF (v_job.requirements->>'licence_required')::BOOLEAN = true OR
     v_job.category_slug IN ('driver', 'delivery', 'delivery-gig-work') THEN
    v_licence_needed := true;
    IF NOT v_has_dl THEN
      v_is_eligible := false;
      v_reasons := array_append(v_reasons, 'Driving Licence required for this job.');
    END IF;
  END IF;

  -- 5. Verified worker check
  IF (v_job.requirements->>'verified_only')::BOOLEAN = true THEN
    v_verified_needed := true;
    IF NOT v_is_verified THEN
      v_is_eligible := false;
      v_reasons := array_append(v_reasons, 'UdyogaSethu Verified badge required.');
    END IF;
  END IF;

  -- 6. Audience check (D-AUDIENCE)
  v_effective_audience := COALESCE(v_job.audience, ARRAY['informal']::TEXT[]);
  IF v_seeker_type IN ('student', 'part_time') THEN
    IF NOT (v_effective_audience && ARRAY['student', 'part_time']::TEXT[]) THEN
      v_student_gated := true;
      v_is_eligible := false;
      v_reasons := array_append(v_reasons, 'Reserved exclusively for informal workers.');
    END IF;
  ELSE
    IF NOT (v_effective_audience @> ARRAY['informal']::TEXT[]) THEN
      v_student_gated := true;
      v_is_eligible := false;
      v_reasons := array_append(v_reasons, 'Reserved exclusively for students or part-time workers.');
    END IF;
  END IF;

  -- 7. Schedule overlap check with existing accepted/active assignments
  v_job_end := v_job.start_at + (COALESCE(v_job.est_duration_minutes, 480) || ' minutes')::INTERVAL;
  SELECT j2.title INTO v_overlap_job_title
  FROM public.job_assignments ja2
  JOIN public.jobs j2 ON ja2.job_id = j2.id
  WHERE ja2.worker_id = v_worker_id
    AND ja2.status IN ('accepted', 'ticket_issued', 'arrived', 'in_progress_verified')
    AND j2.start_at < v_job_end
    AND (j2.start_at + (COALESCE(j2.est_duration_minutes, 480) || ' minutes')::INTERVAL) > v_job.start_at
  LIMIT 1;

  IF v_overlap_job_title IS NOT NULL THEN
    v_schedule_overlap := true;
    v_is_eligible := false;
    v_reasons := array_append(v_reasons, 'Schedule overlap with "' || v_overlap_job_title || '".');
  END IF;

  RETURN jsonb_build_object(
    'is_eligible', v_is_eligible,
    'licence_needed', v_licence_needed,
    'has_licence', v_has_dl,
    'verified_needed', v_verified_needed,
    'is_verified', v_is_verified,
    'student_gated', v_student_gated,
    'schedule_overlap', v_schedule_overlap,
    'overlap_job_title', v_overlap_job_title,
    'already_applied', v_already_applied,
    'reasons', v_reasons
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.check_job_eligibility(UUID) TO authenticated;

-- ============================================================================
-- 2. RPC: get_job_detail
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_job_detail(
  p_job_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_res JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', j.id,
    'provider_id', j.provider_id,
    'provider_name', COALESCE(p.full_name, 'Verified Employer'),
    'provider_avatar', p.avatar_url,
    'provider_verified', COALESCE(p.is_verified_badge, true),
    'provider_rating', COALESCE(pp.rating, 4.8),
    'provider_reviews_count', COALESCE(pp.review_count, 127),
    'background_verified', true,
    'title', j.title,
    'description', COALESCE(j.description, 'Reliable, verified work opportunity through UdyogaSethu.'),
    'category_id', j.category_id,
    'category_name', COALESCE(sc.name, 'General Work'),
    'category_slug', COALESCE(sc.slug, 'general'),
    'category_icon', COALESCE(sc.icon, 'handyman'),
    'wage_paise', j.wage_paise,
    'wage_type', j.wage_type,
    'est_duration_minutes', COALESCE(j.est_duration_minutes, 480),
    'start_at', j.start_at,
    'slots_total', j.slots_total,
    'slots_filled', j.slots_filled,
    'materials_provided', j.materials_provided,
    'payment_mode', j.payment_mode,
    'requirements', j.requirements,
    'address_text', COALESCE(j.address_text, 'Koramangala, Bengaluru, Karnataka'),
    'distance_km', 2.0,
    'walking_minutes', 12,
    'status', j.status
  )
  INTO v_res
  FROM public.jobs j
  LEFT JOIN public.profiles p ON p.id = j.provider_id
  LEFT JOIN public.provider_profiles pp ON pp.user_id = j.provider_id
  LEFT JOIN public.service_categories sc ON sc.id = j.category_id
  WHERE j.id = p_job_id;

  RETURN v_res;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_job_detail(UUID) TO authenticated;

-- ============================================================================
-- 3. Debug Helper RPC: debug_seed_overlapping_requests
-- Creates 2 direct-booking requests with overlapping times for test worker
-- ============================================================================
CREATE OR REPLACE FUNCTION public.debug_seed_overlapping_requests(
  p_worker_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_target_worker_id UUID;
  v_provider_1_id UUID;
  v_provider_2_id UUID;
  v_cat_id UUID;
  v_job_1_id UUID;
  v_job_2_id UUID;
  v_assign_1_id UUID;
  v_assign_2_id UUID;
  v_now TIMESTAMPTZ := NOW();
  v_start_1 TIMESTAMPTZ;
  v_start_2 TIMESTAMPTZ;
  v_code_1 TEXT;
  v_code_2 TEXT;
BEGIN
  v_target_worker_id := COALESCE(p_worker_id, auth.uid());
  IF v_target_worker_id IS NULL THEN
    RAISE EXCEPTION 'Worker ID required.';
  END IF;

  -- 1. Find demo providers or fallback to any profile
  SELECT id INTO v_provider_1_id FROM public.profiles WHERE phone = '+919900000101' LIMIT 1;
  IF v_provider_1_id IS NULL THEN
    SELECT id INTO v_provider_1_id FROM public.profiles WHERE id != v_target_worker_id LIMIT 1;
  END IF;
  IF v_provider_1_id IS NULL THEN
    v_provider_1_id := v_target_worker_id;
  END IF;

  SELECT id INTO v_provider_2_id FROM public.profiles WHERE phone = '+919900000102' LIMIT 1;
  IF v_provider_2_id IS NULL THEN
    SELECT id INTO v_provider_2_id FROM public.profiles WHERE id NOT IN (v_target_worker_id, v_provider_1_id) LIMIT 1;
  END IF;
  IF v_provider_2_id IS NULL THEN
    v_provider_2_id := v_provider_1_id;
  END IF;

  -- 2. Pick any active category
  SELECT id INTO v_cat_id FROM public.service_categories LIMIT 1;

  -- 3. Overlapping time frames:
  -- Job 1: Tomorrow at 10:00 AM (duration 240 mins -> 10:00 AM to 2:00 PM)
  -- Job 2: Tomorrow at 1:00 PM (duration 240 mins -> 1:00 PM to 5:00 PM)
  -- Overlap window: 1:00 PM to 2:00 PM!
  v_start_1 := date_trunc('day', v_now + INTERVAL '1 day') + INTERVAL '10 hours';
  v_start_2 := date_trunc('day', v_now + INTERVAL '1 day') + INTERVAL '13 hours';

  -- Job 1: Construction Site Assistant at Sharma Builders
  INSERT INTO public.jobs (
    provider_id, category_id, title, description, wage_type, wage_paise,
    est_duration_minutes, start_at, slots_total, slots_filled,
    materials_provided, payment_mode, address_text, source, status
  ) VALUES (
    v_provider_1_id, v_cat_id, 'Construction Site Assistant (Slot A)',
    'Assisting senior bricklayer and loading cement blocks. Shift 10:00 AM to 2:00 PM.',
    'daily', 75000, 240, v_start_1, 1, 1,
    true, 'escrow', 'Sharma Site #4, Koramangala 5th Block', 'direct_booking', 'filled'
  ) RETURNING id INTO v_job_1_id;

  v_code_1 := 'REQ-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6));
  INSERT INTO public.job_assignments (
    job_id, worker_id, booking_code, agreed_wage_paise, status, created_at
  ) VALUES (
    v_job_1_id, v_target_worker_id, v_code_1, 75000, 'requested', NOW()
  ) RETURNING id INTO v_assign_1_id;

  -- Job 2: Emergency Wiring Support at Sai Electricals (Overlapping!)
  INSERT INTO public.jobs (
    provider_id, category_id, title, description, wage_type, wage_paise,
    est_duration_minutes, start_at, slots_total, slots_filled,
    materials_provided, payment_mode, address_text, source, status
  ) VALUES (
    v_provider_2_id, v_cat_id, 'Emergency Wiring Support (Slot B)',
    'Conduit fitting and wire pulling helper needed. Shift 1:00 PM to 5:00 PM (Overlaps Slot A).',
    'daily', 88000, 240, v_start_2, 1, 1,
    true, 'escrow', 'Sai Complex, HSR Layout Sector 2', 'direct_booking', 'filled'
  ) RETURNING id INTO v_job_2_id;

  v_code_2 := 'REQ-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6));
  INSERT INTO public.job_assignments (
    job_id, worker_id, booking_code, agreed_wage_paise, status, created_at
  ) VALUES (
    v_job_2_id, v_target_worker_id, v_code_2, 88000, 'requested', NOW()
  ) RETURNING id INTO v_assign_2_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Created 2 overlapping invitations for worker.',
    'job_1', jsonb_build_object('id', v_job_1_id, 'assignment_id', v_assign_1_id, 'title', 'Construction Site Assistant (Slot A)', 'start_at', v_start_1),
    'job_2', jsonb_build_object('id', v_job_2_id, 'assignment_id', v_assign_2_id, 'title', 'Emergency Wiring Support (Slot B)', 'start_at', v_start_2)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.debug_seed_overlapping_requests(UUID) TO authenticated;
