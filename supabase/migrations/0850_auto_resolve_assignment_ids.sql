-- ============================================================================
-- Migration 0850: Auto-Resolve Assignment IDs & Fix Message Regex & Provision Assignments
-- Purpose:
--   1. Fix PostgreSQL regex quantifier limit ({2,256} -> {2,100}) in mask_realtime_message_content.
--   2. Backfill missing job_assignments for hired/accepted applications.
--   3. Enhance get_active_job_details to resolve assignment_id, application_id,
--      or job_id, auto-provisioning the assignment if the application was hired.
-- ============================================================================

-- 1. FIX REGEX QUANTIFIER IN mask_realtime_message_content
CREATE OR REPLACE FUNCTION public.mask_realtime_message_content()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_conv_status TEXT;
  v_original_body TEXT;
  v_masked_body TEXT;
  v_was_masked BOOLEAN := false;
BEGIN
  -- Strict Check: Block new messages if conversation is completed / read-only / cancelled
  SELECT status INTO v_conv_status
  FROM public.conversations
  WHERE id = NEW.conversation_id;

  IF v_conv_status IN ('read_only', 'completed', 'cancelled', 'archived') THEN
    RAISE EXCEPTION 'This chat is no longer available. Messaging is disabled because the job has ended.';
  END IF;

  v_original_body := NEW.body;
  v_masked_body := v_original_body;

  -- 1. Mask Indian phone numbers: +91 / 91 / 0 prefix followed by 10 digits
  IF v_masked_body ~* '(?:\+91|91|0)[\s\-\.]?[6-9](?:[\s\-\.]?[0-9]){9}' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '(?:\+91|91|0)[\s\-\.]?[6-9](?:[\s\-\.]?[0-9]){9}',
      '[MASKED PHONE NUMBER]',
      'g'
    );
    v_was_masked := true;
  END IF;

  -- 2. 10-digit mobile starting with 6-9
  IF v_masked_body ~* '\m[6-9](?:[\s\-\.]?[0-9]){9}\M' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '\m[6-9](?:[\s\-\.]?[0-9]){9}\M',
      '[MASKED PHONE NUMBER]',
      'g'
    );
    v_was_masked := true;
  END IF;

  -- 3. Mask UPI handles (bounded to {2,100} to satisfy PostgreSQL 255 regex limit)
  IF v_masked_body ~* '[a-zA-Z0-9.\-_]{2,100}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '[a-zA-Z0-9.\-_]{2,100}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})',
      '[MASKED UPI HANDLE]',
      'gi'
    );
    v_was_masked := true;
  END IF;

  IF v_was_masked THEN
    NEW.body := v_masked_body || E'\n\n[🔒 Notice: Contact details and direct payment handles are automatically masked by UdyogaSethu for your security. Please keep all communications and payments protected within platform escrow.]';
    NEW.was_masked := true;
  END IF;

  -- Bump last_message_at on the conversation
  UPDATE public.conversations
  SET last_message_at = NOW()
  WHERE id = NEW.conversation_id;

  RETURN NEW;
END;
$$;

-- 2. BACKFILL ANY HIRED APPLICATIONS LACKING ASSIGNMENTS
INSERT INTO public.job_assignments (
  job_id,
  worker_id,
  booking_code,
  agreed_wage_paise,
  status,
  created_at,
  updated_at
)
SELECT
  ja.job_id,
  ja.worker_id,
  'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6)),
  COALESCE(j.wage_paise, 60000),
  CASE
    WHEN j.status::TEXT IN ('closed', 'completed') THEN 'completed'::public.assignment_status
    ELSE 'accepted'::public.assignment_status
  END,
  ja.created_at,
  NOW()
FROM public.job_applications ja
JOIN public.jobs j ON ja.job_id = j.id
LEFT JOIN public.job_assignments asg ON ja.job_id = asg.job_id AND ja.worker_id = asg.worker_id
WHERE ja.status::TEXT IN ('hired', 'accepted')
  AND asg.id IS NULL
ON CONFLICT DO NOTHING;

-- 3. ENHANCE get_active_job_details TO RESOLVE ANY ID AND AUTO-PROVISION
DROP FUNCTION IF EXISTS public.get_active_job_details(UUID);

CREATE OR REPLACE FUNCTION public.get_active_job_details(p_assignment_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_resolved_assignment_id UUID;
  v_result JSONB;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Attempt A: Direct match on job_assignments.id
  SELECT id INTO v_resolved_assignment_id
  FROM public.job_assignments
  WHERE id = p_assignment_id;

  -- Attempt B: Match on jobs.id (caller passed job_id)
  IF v_resolved_assignment_id IS NULL THEN
    SELECT ja.id INTO v_resolved_assignment_id
    FROM public.job_assignments ja
    JOIN public.jobs j ON ja.job_id = j.id
    WHERE ja.job_id = p_assignment_id
      AND (ja.worker_id = v_uid OR j.provider_id = v_uid OR public.is_admin())
    ORDER BY ja.created_at DESC
    LIMIT 1;
  END IF;

  -- Attempt C: Match on job_applications.id (caller passed application_id)
  IF v_resolved_assignment_id IS NULL THEN
    SELECT ja.id INTO v_resolved_assignment_id
    FROM public.job_assignments ja
    JOIN public.job_applications app ON ja.job_id = app.job_id AND ja.worker_id = app.worker_id
    WHERE app.id = p_assignment_id
    ORDER BY ja.created_at DESC
    LIMIT 1;

    -- If no assignment exists yet but application is hired/accepted, auto-create it
    IF v_resolved_assignment_id IS NULL THEN
      DECLARE
        v_app_job_id UUID;
        v_app_worker_id UUID;
        v_app_status TEXT;
        v_job_wage BIGINT;
        v_job_status TEXT;
      BEGIN
        SELECT ja.job_id, ja.worker_id, ja.status::TEXT, j.wage_paise, j.status::TEXT
        INTO v_app_job_id, v_app_worker_id, v_app_status, v_job_wage, v_job_status
        FROM public.job_applications ja
        JOIN public.jobs j ON ja.job_id = j.id
        WHERE ja.id = p_assignment_id;

        IF v_app_job_id IS NOT NULL AND v_app_status IN ('hired', 'accepted') THEN
          INSERT INTO public.job_assignments (
            job_id,
            worker_id,
            booking_code,
            agreed_wage_paise,
            status,
            created_at,
            updated_at
          )
          VALUES (
            v_app_job_id,
            v_app_worker_id,
            'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6)),
            COALESCE(v_job_wage, 60000),
            CASE
              WHEN v_job_status IN ('closed', 'completed') THEN 'completed'::public.assignment_status
              ELSE 'accepted'::public.assignment_status
            END,
            NOW(),
            NOW()
          )
          RETURNING id INTO v_resolved_assignment_id;
        END IF;
      END;
    END IF;
  END IF;

  IF v_resolved_assignment_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_build_object(
    'assignment_id', ja.id,
    'job_id', j.id,
    'booking_code', ja.booking_code,
    'status', ja.status::TEXT,
    'agreed_wage_paise', ja.agreed_wage_paise,
    'protection_selected', ja.protection_selected,
    'arrived_at', ja.arrived_at,
    'started_at', ja.started_at,
    'ended_at', ja.ended_at,
    'elapsed_seconds', CASE
      WHEN ja.started_at IS NOT NULL THEN
        GREATEST(0, EXTRACT(EPOCH FROM (COALESCE(ja.ended_at, NOW()) - ja.started_at))::INT)
      ELSE 0
    END,
    'midjob_verified_at', ja.midjob_verified_at,
    'payment_eligible', ja.payment_eligible,
    'extended_grace_minutes', COALESCE(ja.extended_grace_minutes, 0),
    'late_notified_at', ja.late_notified_at,
    'running_late_eta_minutes', ja.running_late_eta_minutes,
    'running_late_reported_at', ja.running_late_reported_at,
    'no_show_timer_paused', COALESCE(ja.no_show_timer_paused, false),
    'replaced_by', ja.replaced_by,
    'job_title', j.title,
    'job_description', j.description,
    'start_at', j.start_at,
    'est_duration_minutes', COALESCE(j.est_duration_minutes, 480),
    'address_text', j.address_text,
    'job_lat', CASE WHEN j.location IS NOT NULL THEN extensions.ST_Y(j.location::extensions.geometry) ELSE NULL END,
    'job_lng', CASE WHEN j.location IS NOT NULL THEN extensions.ST_X(j.location::extensions.geometry) ELSE NULL END,
    'category_name', COALESCE(sc.names->>'en', sc.slug, 'General Work'),
    'category_slug', COALESCE(sc.slug, 'general'),
    'category_icon', COALESCE(sc.icon, 'handyman'),
    'provider_id', pp.id,
    'provider_name', COALESCE(NULLIF(TRIM(pp.full_name), ''), 'Job Provider'),
    'provider_phone', CASE WHEN ja.status IN ('accepted', 'ticket_issued', 'arrived', 'in_progress_verified') THEN pp.phone ELSE NULL END,
    'provider_avatar', pp.avatar_path,
    'provider_verified', COALESCE(prp.is_verified_badge, true),
    'worker_id', wp_prof.id,
    'worker_name', COALESCE(NULLIF(TRIM(wp_prof.full_name), ''), 'Name not set'),
    'worker_phone', CASE WHEN ja.status IN ('accepted', 'ticket_issued', 'arrived', 'in_progress_verified') THEN wp_prof.phone ELSE NULL END,
    'worker_avatar', wp_prof.avatar_path,
    'worker_verified', COALESCE(wp.is_verified_badge, false),
    'worker_lat', CASE WHEN wp_prof.home_location IS NOT NULL THEN extensions.ST_Y(wp_prof.home_location::extensions.geometry) ELSE NULL END,
    'worker_lng', CASE WHEN wp_prof.home_location IS NOT NULL THEN extensions.ST_X(wp_prof.home_location::extensions.geometry) ELSE NULL END
  ) INTO v_result
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  LEFT JOIN public.profiles pp ON j.provider_id = pp.id
  LEFT JOIN public.provider_profiles prp ON j.provider_id = prp.user_id
  LEFT JOIN public.profiles wp_prof ON ja.worker_id = wp_prof.id
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  WHERE ja.id = v_resolved_assignment_id
    AND (ja.worker_id = v_uid OR j.provider_id = v_uid OR public.is_admin());

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

GRANT EXECUTE ON FUNCTION public.get_active_job_details(UUID) TO authenticated;
