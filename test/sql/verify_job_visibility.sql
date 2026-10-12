-- Verification test script for Migration 0700: Unified Job Visibility
DO $$
DECLARE
  v_prov_id UUID := '73f5e70f-b68c-4f48-ba9f-4b9cabe10970'; -- Sophia Nancy
  v_student_id UUID := '22222222-2222-4222-8222-222222222204'; -- Ananya Rao (student)
  v_informal_id UUID := '22222222-2222-4222-8222-222222222201'; -- Ramesh Kumar (informal)
  v_parttime_id UUID := '22222222-2222-4222-8222-222222222206'; -- Syed Imran (part_time)
  
  v_job_student UUID;
  v_job_informal UUID;
  v_job_parttime UUID;
  v_job_combo UUID;
  v_job_no_aud UUID;
  v_job_filled UUID;
  
  v_vis_student_to_student BOOLEAN;
  v_vis_student_to_informal BOOLEAN;
  v_vis_informal_to_informal BOOLEAN;
  v_vis_informal_to_student BOOLEAN;
  v_vis_parttime_to_parttime BOOLEAN;
  v_vis_parttime_to_student BOOLEAN;
  v_vis_combo_to_all BOOLEAN;
  v_vis_no_aud_to_all BOOLEAN;
  v_vis_filled_to_student BOOLEAN;
  
  v_eligibility JSONB;
  v_rec_count INT;
BEGIN
  -- 1. Insert test jobs with unique titles
  v_job_student := gen_random_uuid();
  v_job_informal := gen_random_uuid();
  v_job_parttime := gen_random_uuid();
  v_job_combo := gen_random_uuid();
  v_job_no_aud := gen_random_uuid();
  v_job_filled := gen_random_uuid();

  -- Student-only job
  INSERT INTO public.jobs (id, provider_id, title, status, wage_type, wage_paise, start_at, slots_total, slots_filled, suitable_for, location)
  VALUES (v_job_student, v_prov_id, '__TEST_STUDENT_ONLY__', 'open', 'daily', 80000, NOW() + INTERVAL '2 days', 1, 0, ARRAY['student'::public.seeker_type], extensions.ST_SetSRID(extensions.ST_MakePoint(77.6205, 12.9355), 4326)::geography);

  -- Informal-only job
  INSERT INTO public.jobs (id, provider_id, title, status, wage_type, wage_paise, start_at, slots_total, slots_filled, suitable_for, location)
  VALUES (v_job_informal, v_prov_id, '__TEST_INFORMAL_ONLY__', 'open', 'daily', 80000, NOW() + INTERVAL '2 days', 1, 0, ARRAY['informal'::public.seeker_type], extensions.ST_SetSRID(extensions.ST_MakePoint(77.6410, 12.9786), 4326)::geography);

  -- Part-time only job
  INSERT INTO public.jobs (id, provider_id, title, status, wage_type, wage_paise, start_at, slots_total, slots_filled, suitable_for, location)
  VALUES (v_job_parttime, v_prov_id, '__TEST_PARTTIME_ONLY__', 'open', 'daily', 80000, NOW() + INTERVAL '2 days', 1, 0, ARRAY['part_time'::public.seeker_type], extensions.ST_SetSRID(extensions.ST_MakePoint(77.6450, 12.9125), 4326)::geography);

  -- Combo job (student, informal, part_time)
  INSERT INTO public.jobs (id, provider_id, title, status, wage_type, wage_paise, start_at, slots_total, slots_filled, suitable_for, location)
  VALUES (v_job_combo, v_prov_id, '__TEST_COMBO_JOB__', 'open', 'daily', 80000, NOW() + INTERVAL '2 days', 3, 0, ARRAY['informal'::public.seeker_type, 'student'::public.seeker_type, 'part_time'::public.seeker_type], extensions.ST_SetSRID(extensions.ST_MakePoint(77.6205, 12.9355), 4326)::geography);

  -- Job without audience (empty array)
  INSERT INTO public.jobs (id, provider_id, title, status, wage_type, wage_paise, start_at, slots_total, slots_filled, suitable_for, location)
  VALUES (v_job_no_aud, v_prov_id, '__TEST_NO_AUDIENCE__', 'open', 'daily', 80000, NOW() + INTERVAL '2 days', 1, 0, '{}', extensions.ST_SetSRID(extensions.ST_MakePoint(77.6205, 12.9355), 4326)::geography);

  -- Filled job
  INSERT INTO public.jobs (id, provider_id, title, status, wage_type, wage_paise, start_at, slots_total, slots_filled, suitable_for, location)
  VALUES (v_job_filled, v_prov_id, '__TEST_FILLED_JOB__', 'open', 'daily', 80000, NOW() + INTERVAL '2 days', 1, 1, ARRAY['student'::public.seeker_type], extensions.ST_SetSRID(extensions.ST_MakePoint(77.6205, 12.9355), 4326)::geography);

  -- 2. Assert visibility matrix via public.job_visible_to
  v_vis_student_to_student := public.job_visible_to(v_student_id, v_job_student);
  v_vis_student_to_informal := public.job_visible_to(v_informal_id, v_job_student);
  
  v_vis_informal_to_informal := public.job_visible_to(v_informal_id, v_job_informal);
  v_vis_informal_to_student := public.job_visible_to(v_student_id, v_job_informal);
  
  v_vis_parttime_to_parttime := public.job_visible_to(v_parttime_id, v_job_parttime);
  v_vis_parttime_to_student := public.job_visible_to(v_student_id, v_job_parttime);

  v_vis_combo_to_all := public.job_visible_to(v_student_id, v_job_combo) 
                    AND public.job_visible_to(v_informal_id, v_job_combo) 
                    AND public.job_visible_to(v_parttime_id, v_job_combo);

  v_vis_no_aud_to_all := public.job_visible_to(v_student_id, v_job_no_aud) 
                      OR public.job_visible_to(v_informal_id, v_job_no_aud)
                      OR public.job_visible_to(v_parttime_id, v_job_no_aud);

  v_vis_filled_to_student := public.job_visible_to(v_student_id, v_job_filled);

  IF NOT v_vis_student_to_student THEN
    RAISE EXCEPTION 'ASSERTION FAILED: Student job should be visible to student worker!';
  END IF;

  IF v_vis_student_to_informal THEN
    RAISE EXCEPTION 'ASSERTION FAILED: Student job MUST NOT be visible to informal worker!';
  END IF;

  IF NOT v_vis_informal_to_informal THEN
    RAISE EXCEPTION 'ASSERTION FAILED: Informal job should be visible to informal worker!';
  END IF;

  IF v_vis_informal_to_student THEN
    RAISE EXCEPTION 'ASSERTION FAILED: Informal job MUST NOT be visible to student worker!';
  END IF;

  IF NOT v_vis_parttime_to_parttime THEN
    RAISE EXCEPTION 'ASSERTION FAILED: Part-time job should be visible to part-time worker!';
  END IF;

  IF v_vis_parttime_to_student THEN
    RAISE EXCEPTION 'ASSERTION FAILED: Part-time job MUST NOT be visible to student worker!';
  END IF;

  IF NOT v_vis_combo_to_all THEN
    RAISE EXCEPTION 'ASSERTION FAILED: Combo job should be visible to student, informal AND part-time!';
  END IF;

  IF v_vis_no_aud_to_all THEN
    RAISE EXCEPTION 'ASSERTION FAILED: Job without audience must be visible to NOBODY!';
  END IF;

  IF v_vis_filled_to_student THEN
    RAISE EXCEPTION 'ASSERTION FAILED: Filled job must not be visible!';
  END IF;

  -- 3. Check eligibility & apply rejection for wrong worker type
  v_eligibility := public.check_job_eligibility(v_job_student, v_informal_id);
  IF (v_eligibility->>'is_eligible')::BOOLEAN != false THEN
    RAISE EXCEPTION 'ASSERTION FAILED: check_job_eligibility must mark informal worker as ineligible for student job!';
  END IF;
  IF (v_eligibility->>'reason_code') != 'AUDIENCE_MISMATCH' THEN
    RAISE EXCEPTION 'ASSERTION FAILED: check_job_eligibility reason_code must be AUDIENCE_MISMATCH! Got: %', (v_eligibility->>'reason_code');
  END IF;

  -- 4. Test location fallback: Worker with NULL coordinates gets recommendations
  SELECT COUNT(*) INTO v_rec_count
  FROM public.recommended_jobs(v_student_id, NULL, NULL, 50000, 20);
  
  IF v_rec_count = 0 THEN
    RAISE EXCEPTION 'ASSERTION FAILED: recommended_jobs with NULL coordinates should return fallback jobs!';
  END IF;

  -- Clean up test jobs
  DELETE FROM public.jobs WHERE id IN (v_job_student, v_job_informal, v_job_parttime, v_job_combo, v_job_no_aud, v_job_filled);

  RAISE NOTICE 'SUCCESS: All SQL job visibility, audience isolation, application gating and location fallback tests PASSED!';
END;
$$;
