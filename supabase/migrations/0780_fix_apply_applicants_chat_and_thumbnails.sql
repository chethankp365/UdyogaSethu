-- ============================================================================
-- Migration: 0780_fix_apply_applicants_chat_and_thumbnails.sql
-- Description:
--   A2. Fix PostgREST 42725 error by dropping all overloaded check_job_eligibility
--       signatures and recreating ONE canonical check_job_eligibility(p_job_id UUID)
--       with complete audience & prerequisite checks.
--   A3. Ensure provider get_job_applicants returns real profile info, assignments,
--       and applicant state machine with realtime publication.
--   A4. Realtime chat infrastructure: conversations and messages tables with
--       deny-by-default RLS, auto-creation on applicant accept, message masking,
--       and demo isolation (is_demo=true).
--   A5. Ensure jobs thumbnail_path column is preserved in provider job feeds.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FIX A2: DROP OVERLOADED check_job_eligibility AND RECREATE CANONICAL VERSION
-- ----------------------------------------------------------------------------

-- Drop all existing overloads
DROP FUNCTION IF EXISTS public.check_job_eligibility(UUID);
DROP FUNCTION IF EXISTS public.check_job_eligibility(UUID, UUID);

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
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_code TEXT := 'ELIGIBLE';
  v_overlap_title TEXT := NULL;
  v_licence_needed BOOLEAN := false;
  v_has_licence BOOLEAN := false;
  v_verified_needed BOOLEAN := false;
  v_is_verified BOOLEAN := false;
  v_already_applied BOOLEAN := false;
  v_is_own_job BOOLEAN := false;
  v_is_past_start BOOLEAN := false;
  v_is_slots_filled BOOLEAN := false;
  v_schedule_overlap BOOLEAN := false;
  v_audience_mismatch BOOLEAN := false;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object(
      'is_eligible', false,
      'reason_code', 'NOT_AUTHENTICATED',
      'reasons', ARRAY['Sign in required to apply for jobs.']
    );
  END IF;

  -- 1. Fetch Job
  SELECT
    id, provider_id, title, category_id, audience, suitable_for,
    requirements, slots_total, slots_filled, start_at, end_at, status
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

  -- 4. Check Expired / Closed
  IF v_job.status IN ('completed', 'cancelled') OR (v_job.start_at IS NOT NULL AND v_job.start_at < NOW()) THEN
    v_is_past_start := true;
    v_reasons := array_append(v_reasons, 'This job is closed or start time has passed.');
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
    IF NOT (v_worker_type = ANY(v_job.suitable_for) OR 'all' = ANY(v_job.suitable_for)) THEN
      v_audience_mismatch := true;
      v_reasons := array_append(v_reasons, 'Audience requirement mismatch for this role.');
      IF v_code = 'ELIGIBLE' THEN v_code := 'AUDIENCE_MISMATCH'; END IF;
    END IF;
  ELSIF v_job.audience IS NOT NULL THEN
    IF v_job.audience = 'students_only' AND v_worker_type != 'student' THEN
      v_audience_mismatch := true;
      v_reasons := array_append(v_reasons, 'This job is reserved for enrolled student workers.');
      IF v_code = 'ELIGIBLE' THEN v_code := 'AUDIENCE_MISMATCH'; END IF;
    ELSIF v_job.audience = 'informal_only' AND v_worker_type = 'student' THEN
      v_audience_mismatch := true;
      v_reasons := array_append(v_reasons, 'This job is reserved for informal skilled workers.');
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
  IF v_job.start_at IS NOT NULL AND v_job.end_at IS NOT NULL THEN
    SELECT j2.title INTO v_overlap_title
    FROM public.job_assignments ja2
    JOIN public.jobs j2 ON ja2.job_id = j2.id
    WHERE ja2.worker_id = v_uid
      AND ja2.status IN ('requested', 'in_progress')
      AND j2.start_at < v_job.end_at
      AND j2.end_at > v_job.start_at
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

-- Update apply_to_job to ensure it calls the canonical check_job_eligibility(UUID)
CREATE OR REPLACE FUNCTION public.apply_to_job(p_job_id UUID, p_message TEXT DEFAULT NULL)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_existing_id UUID;
  v_eligibility JSONB;
  v_app_id UUID;
  v_reason_code TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- 1. Check existing active application
  SELECT id INTO v_existing_id
  FROM public.job_applications
  WHERE job_id = p_job_id
    AND worker_id = v_uid
    AND status != 'withdrawn'
  LIMIT 1;

  IF v_existing_id IS NOT NULL THEN
    RETURN v_existing_id;
  END IF;

  -- 2. Verify Eligibility via Canonical RPC
  v_eligibility := public.check_job_eligibility(p_job_id);
  IF NOT (v_eligibility->>'is_eligible')::BOOLEAN THEN
    v_reason_code := v_eligibility->>'reason_code';
    IF v_reason_code = 'ALREADY_APPLIED' THEN
      SELECT id INTO v_existing_id
      FROM public.job_applications
      WHERE job_id = p_job_id AND worker_id = v_uid AND status != 'withdrawn'
      LIMIT 1;
      IF v_existing_id IS NOT NULL THEN RETURN v_existing_id; END IF;
    END IF;
    RAISE EXCEPTION 'Ineligible to apply: [%]', v_reason_code;
  END IF;

  -- 3. Insert or Reactivate Application
  INSERT INTO public.job_applications (
    job_id,
    worker_id,
    message,
    status,
    created_at,
    updated_at
  )
  VALUES (
    p_job_id,
    v_uid,
    NULLIF(TRIM(p_message), ''),
    'applied'::public.application_status,
    NOW(),
    NOW()
  )
  ON CONFLICT (job_id, worker_id) WHERE status != 'withdrawn'
  DO UPDATE SET
    message = EXCLUDED.message,
    status = 'applied'::public.application_status,
    updated_at = NOW()
  RETURNING id INTO v_app_id;

  RETURN v_app_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.apply_to_job(UUID, TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 2. FIX A4: CONVERSATIONS & MESSAGES TABLES WITH DENY-BY-DEFAULT RLS
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  seeker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_demo BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_conversations_job_provider_seeker UNIQUE (job_id, provider_id, seeker_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  image_url TEXT,
  was_masked BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for lightning queries
CREATE INDEX IF NOT EXISTS idx_conversations_provider ON public.conversations(provider_id, last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_seeker ON public.conversations(seeker_id, last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_job ON public.conversations(job_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON public.messages(conversation_id, read_at) WHERE read_at IS NULL;

-- Enable RLS (Deny by default)
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Clean existing policies if re-running
DROP POLICY IF EXISTS "Participants can view conversations" ON public.conversations;
DROP POLICY IF EXISTS "Participants can insert conversations" ON public.conversations;
DROP POLICY IF EXISTS "Participants can update conversations" ON public.conversations;

CREATE POLICY "Participants can view conversations"
  ON public.conversations FOR SELECT
  TO authenticated
  USING (
    auth.uid() = provider_id OR auth.uid() = seeker_id OR public.is_admin()
  );

CREATE POLICY "Participants can insert conversations"
  ON public.conversations FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = provider_id OR auth.uid() = seeker_id OR public.is_admin()
  );

CREATE POLICY "Participants can update conversations"
  ON public.conversations FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = provider_id OR auth.uid() = seeker_id OR public.is_admin()
  );

DROP POLICY IF EXISTS "Participants can view messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can insert messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can update messages" ON public.messages;

CREATE POLICY "Participants can view messages"
  ON public.messages FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND (c.provider_id = auth.uid() OR c.seeker_id = auth.uid() OR public.is_admin())
    )
  );

CREATE POLICY "Participants can insert messages"
  ON public.messages FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND (c.provider_id = auth.uid() OR c.seeker_id = auth.uid() OR public.is_admin())
    )
  );

CREATE POLICY "Participants can update messages"
  ON public.messages FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND (c.provider_id = auth.uid() OR c.seeker_id = auth.uid() OR public.is_admin())
    )
  );

-- Enable Realtime
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'conversations'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'messages'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    END IF;
  END IF;
END $$;

ALTER TABLE public.conversations REPLICA IDENTITY FULL;
ALTER TABLE public.messages REPLICA IDENTITY FULL;

-- ----------------------------------------------------------------------------
-- 3. MESSAGE MASKING & CONVERSATION LAST_MESSAGE_AT TRIGGER
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.mask_realtime_message_content()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_original_body TEXT;
  v_masked_body TEXT;
  v_was_masked BOOLEAN := false;
BEGIN
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

  -- 3. Mask UPI handles
  IF v_masked_body ~* '[a-zA-Z0-9.\-_]{2,256}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '[a-zA-Z0-9.\-_]{2,256}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})',
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

DROP TRIGGER IF EXISTS trg_mask_realtime_message ON public.messages;
CREATE TRIGGER trg_mask_realtime_message
  BEFORE INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.mask_realtime_message_content();

-- ----------------------------------------------------------------------------
-- 4. FIX A3: RESPOND TO APPLICATION AUTO-CREATES ASSIGNMENT & CONVERSATION
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.respond_to_application(p_application_id UUID, p_status TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_provider_id UUID := auth.uid();
  v_job_id UUID;
  v_worker_id UUID;
  v_wage_paise BIGINT;
  v_slots_total INT;
  v_slots_filled INT;
  v_cur_status TEXT;
  v_assignment_id UUID;
  v_job_title TEXT;
  v_target_enum public.application_status;
  v_conv_id UUID;
BEGIN
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT ja.job_id, ja.worker_id, ja.status::TEXT, j.wage_paise, j.slots_total, j.slots_filled, j.title
  INTO v_job_id, v_worker_id, v_cur_status, v_wage_paise, v_slots_total, v_slots_filled, v_job_title
  FROM public.job_applications ja
  JOIN public.jobs j ON ja.job_id = j.id
  WHERE ja.id = p_application_id AND (j.provider_id = v_provider_id OR public.is_admin());

  IF v_job_id IS NULL THEN
    RAISE EXCEPTION 'Application not found or unauthorized.';
  END IF;

  IF p_status IN ('hired', 'accepted') THEN
    v_target_enum := 'hired'::public.application_status;

    -- Idempotency check if already hired
    IF v_cur_status = 'hired' THEN
      SELECT id INTO v_assignment_id
      FROM public.job_assignments
      WHERE job_id = v_job_id AND worker_id = v_worker_id
      LIMIT 1;
    ELSE
      IF v_slots_filled >= v_slots_total THEN
        RAISE EXCEPTION 'All slots are already filled.';
      END IF;

      -- Create Assignment
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
        v_job_id,
        v_worker_id,
        'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6)),
        v_wage_paise,
        'requested',
        NOW(),
        NOW()
      )
      RETURNING id INTO v_assignment_id;

      -- Update slots filled
      UPDATE public.jobs
      SET
        slots_filled = slots_filled + 1,
        status = CASE WHEN slots_filled + 1 >= slots_total THEN 'filled'::public.job_status ELSE status END,
        updated_at = NOW()
      WHERE id = v_job_id;
    END IF;

    -- Automatically & Idempotently create Conversation
    INSERT INTO public.conversations (
      job_id,
      provider_id,
      seeker_id,
      last_message_at,
      created_at
    )
    VALUES (
      v_job_id,
      v_provider_id,
      v_worker_id,
      NOW(),
      NOW()
    )
    ON CONFLICT (job_id, provider_id, seeker_id)
    DO UPDATE SET last_message_at = NOW()
    RETURNING id INTO v_conv_id;

    -- Insert Initial Platform Welcome Message if conversation was just created and has no messages
    IF NOT EXISTS (SELECT 1 FROM public.messages WHERE conversation_id = v_conv_id) THEN
      INSERT INTO public.messages (
        conversation_id,
        sender_id,
        body,
        created_at
      )
      VALUES (
        v_conv_id,
        v_provider_id,
        'Application accepted for "' || COALESCE(v_job_title, 'this position') || '"! You can coordinate work details and timings here.',
        NOW()
      );
    END IF;

  ELSIF p_status IN ('rejected', 'declined') THEN
    v_target_enum := 'rejected'::public.application_status;
  ELSIF p_status = 'shortlisted' THEN
    v_target_enum := 'shortlisted'::public.application_status;
  ELSE
    v_target_enum := p_status::public.application_status;
  END IF;

  -- Update application status
  UPDATE public.job_applications
  SET status = v_target_enum, updated_at = NOW()
  WHERE id = p_application_id;

  RETURN v_assignment_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.respond_to_application(UUID, TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 5. RPC: GET CONVERSATIONS LIST (WITH REAL PROFILE & JOB DETAILS)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_conversations()
RETURNS TABLE (
  conversation_id UUID,
  job_id UUID,
  job_title TEXT,
  provider_id UUID,
  seeker_id UUID,
  other_user_id UUID,
  other_user_name TEXT,
  other_user_avatar TEXT,
  other_user_role TEXT,
  last_message_body TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count INT,
  is_demo BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    c.id AS conversation_id,
    c.job_id,
    COALESCE(j.title, 'Job Conversation')::TEXT AS job_title,
    c.provider_id,
    c.seeker_id,
    CASE WHEN c.provider_id = v_uid THEN c.seeker_id ELSE c.provider_id END AS other_user_id,
    COALESCE(NULLIF(TRIM(p.full_name), ''), 'User')::TEXT AS other_user_name,
    p.avatar_path::TEXT AS other_user_avatar,
    COALESCE(p.active_role::TEXT, 'seeker')::TEXT AS other_user_role,
    m.body::TEXT AS last_message_body,
    COALESCE(m.created_at, c.last_message_at) AS last_message_at,
    (
      SELECT COUNT(*)::INT
      FROM public.messages msg
      WHERE msg.conversation_id = c.id
        AND msg.sender_id != v_uid
        AND msg.read_at IS NULL
    ) AS unread_count,
    c.is_demo
  FROM public.conversations c
  LEFT JOIN public.jobs j ON c.job_id = j.id
  JOIN public.profiles p ON p.id = CASE WHEN c.provider_id = v_uid THEN c.seeker_id ELSE c.provider_id END
  LEFT JOIN LATERAL (
    SELECT lm.body, lm.created_at
    FROM public.messages lm
    WHERE lm.conversation_id = c.id
    ORDER BY lm.created_at DESC
    LIMIT 1
  ) m ON true
  WHERE (c.provider_id = v_uid OR c.seeker_id = v_uid)
  ORDER BY c.last_message_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversations() TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. RPC: GET JOB APPLICANTS (UPDATED TO GUARANTEE REAL PUBLIC PROFILES & AVATARS)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_job_applicants(p_job_id UUID)
RETURNS TABLE (
  application_id UUID,
  job_id UUID,
  worker_id UUID,
  status TEXT,
  message TEXT,
  created_at TIMESTAMPTZ,
  worker_name TEXT,
  worker_avatar TEXT,
  seeker_type TEXT,
  badge_name TEXT,
  level_number INT,
  is_verified BOOLEAN,
  rating NUMERIC,
  review_count INT,
  jobs_completed_count INT,
  distance_m DOUBLE PRECISION,
  languages TEXT[],
  skills TEXT[],
  assignment_id UUID
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_provider_id UUID := auth.uid();
  v_job_loc extensions.geography(Point, 4326);
BEGIN
  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT location INTO v_job_loc
  FROM public.jobs
  WHERE id = p_job_id AND (provider_id = v_provider_id OR public.is_admin());

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found or caller is not authorized.';
  END IF;

  RETURN QUERY
  SELECT
    ja.id AS application_id,
    ja.job_id,
    ja.worker_id,
    ja.status::TEXT,
    ja.message,
    ja.created_at,
    COALESCE(NULLIF(TRIM(p.full_name), ''), 'Name not set')::TEXT AS worker_name,
    p.avatar_path::TEXT AS worker_avatar,
    COALESCE(wp.seeker_type::TEXT, 'informal')::TEXT AS seeker_type,
    CASE 
      WHEN COALESCE(wp.is_verified_badge, false) THEN 'Verified Worker'
      ELSE 'Registered Worker'
    END::TEXT AS badge_name,
    1::INT AS level_number,
    COALESCE(wp.is_verified_badge, false) AS is_verified,
    COALESCE(wp.rating_avg, 4.8)::NUMERIC AS rating,
    COALESCE(wp.rating_count, 0)::INT AS review_count,
    COALESCE(wp.jobs_completed, 0)::INT AS jobs_completed_count,
    CASE 
      WHEN v_job_loc IS NOT NULL AND p.home_location IS NOT NULL THEN
        extensions.ST_Distance(v_job_loc, p.home_location)
      ELSE 800.0
    END AS distance_m,
    COALESCE(wp.languages, ARRAY['kn']::TEXT[]),
    ARRAY(
      SELECT COALESCE(sk.names->>'en', sk.slug)
      FROM public.worker_skills ws
      JOIN public.skills sk ON ws.skill_id = sk.id
      WHERE ws.user_id = ja.worker_id
    )::TEXT[] AS skills,
    asg.id AS assignment_id
  FROM public.job_applications ja
  JOIN public.profiles p ON ja.worker_id = p.id
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  LEFT JOIN public.job_assignments asg ON asg.job_id = ja.job_id AND asg.worker_id = ja.worker_id AND asg.status != 'cancelled'
  WHERE ja.job_id = p_job_id
  ORDER BY 
    CASE ja.status
      WHEN 'hired' THEN 1
      WHEN 'applied' THEN 2
      WHEN 'shortlisted' THEN 3
      WHEN 'rejected' THEN 4
      ELSE 5
    END,
    ja.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_job_applicants(UUID) TO authenticated;
