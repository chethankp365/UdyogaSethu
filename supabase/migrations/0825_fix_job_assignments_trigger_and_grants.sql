-- ============================================================================
-- Migration 0825: Fix Job Assignments Trigger, Realtime Grants & Auto-Chat
-- Description:
--   1. Fixes trigger trg_auto_thread_assignment: queries j.provider_id (not j.employer_id)
--      and creates canonical record in public.conversations + initial welcome message.
--   2. Updates respond_to_application() to insert job_assignments with status 'accepted'
--      (instead of 'requested') and link the conversation.
--   3. Updates issue_job_ticket() and get_rotating_ticket_token() to defensively resolve
--      either assignment_id or application_id.
--   4. Grants table privileges (SELECT, INSERT, UPDATE, DELETE) on conversations, messages,
--      chat_blocks, chat_reports, job_assignments, qr_tokens to authenticated and anon.
--   5. Backfills any existing hired applications that missed assignment creation.
-- ============================================================================

-- 1. FIX TRIGGER trg_auto_thread_assignment ON public.job_assignments
DROP TRIGGER IF EXISTS trg_auto_thread_assignment ON public.job_assignments;

CREATE OR REPLACE FUNCTION public.auto_create_assignment_chat_thread()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_provider_id UUID;
  v_job_title TEXT;
  v_conv_id UUID;
BEGIN
  -- Query provider_id (correct column name) and title from jobs
  SELECT j.provider_id, j.title
  INTO v_provider_id, v_job_title
  FROM public.jobs j
  WHERE j.id = NEW.job_id;

  IF v_provider_id IS NOT NULL AND NEW.worker_id IS NOT NULL THEN
    -- Create or update unified conversation
    INSERT INTO public.conversations (
      job_id,
      provider_id,
      seeker_id,
      context_type,
      context_id,
      booking_id,
      last_message_at,
      created_at
    )
    VALUES (
      NEW.job_id,
      v_provider_id,
      NEW.worker_id,
      'job',
      NEW.job_id,
      NEW.id,
      NOW(),
      NOW()
    )
    ON CONFLICT (job_id, provider_id, seeker_id)
    DO UPDATE SET
      booking_id = COALESCE(public.conversations.booking_id, EXCLUDED.booking_id),
      last_message_at = NOW()
    RETURNING id INTO v_conv_id;

    -- Insert Initial Platform Welcome Message if conversation has no messages
    IF v_conv_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.messages WHERE conversation_id = v_conv_id
    ) THEN
      INSERT INTO public.messages (
        conversation_id,
        sender_id,
        body,
        created_at
      )
      VALUES (
        v_conv_id,
        v_provider_id,
        'Congratulations! Application accepted for "' || COALESCE(v_job_title, 'this position') || '". You can coordinate work details and timings here.',
        NOW()
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_thread_assignment
  AFTER INSERT ON public.job_assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_assignment_chat_thread();


-- 2. HARDEN respond_to_application() RPC
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

    -- Check if an assignment already exists for this job and worker
    SELECT id INTO v_assignment_id
    FROM public.job_assignments
    WHERE job_id = v_job_id AND worker_id = v_worker_id
    LIMIT 1;

    IF v_assignment_id IS NULL THEN
      IF v_slots_filled >= v_slots_total THEN
        RAISE EXCEPTION 'All slots are already filled.';
      END IF;

      -- Create Assignment with status 'accepted'
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
        COALESCE(v_wage_paise, 60000),
        'accepted',
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
    ELSE
      -- Ensure status is at least 'accepted'
      UPDATE public.job_assignments
      SET status = CASE WHEN status = 'requested' THEN 'accepted'::public.assignment_status ELSE status END,
          updated_at = NOW()
      WHERE id = v_assignment_id;
    END IF;

    -- Automatically create or update Conversation
    INSERT INTO public.conversations (
      job_id,
      provider_id,
      seeker_id,
      context_type,
      context_id,
      booking_id,
      last_message_at,
      created_at
    )
    VALUES (
      v_job_id,
      v_provider_id,
      v_worker_id,
      'job',
      v_job_id,
      v_assignment_id,
      NOW(),
      NOW()
    )
    ON CONFLICT (job_id, provider_id, seeker_id)
    DO UPDATE SET
      booking_id = COALESCE(public.conversations.booking_id, EXCLUDED.booking_id),
      last_message_at = NOW()
    RETURNING id INTO v_conv_id;

    -- Insert Welcome Message if conversation has no messages
    IF v_conv_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.messages WHERE conversation_id = v_conv_id
    ) THEN
      INSERT INTO public.messages (
        conversation_id,
        sender_id,
        body,
        created_at
      )
      VALUES (
        v_conv_id,
        v_provider_id,
        'Congratulations! Application accepted for "' || COALESCE(v_job_title, 'this position') || '". You can coordinate work details and timings here.',
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

GRANT EXECUTE ON FUNCTION public.respond_to_application(UUID, TEXT) TO authenticated, anon;


-- 3. DEFENSIVE issue_job_ticket() (RESOLVES APPLICATION ID OR ASSIGNMENT ID)
CREATE OR REPLACE FUNCTION public.issue_job_ticket(p_assignment_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_rec RECORD;
  v_resolved_id UUID := p_assignment_id;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Check direct assignment match
  SELECT id INTO v_resolved_id
  FROM public.job_assignments
  WHERE id = p_assignment_id;

  -- Defensive fallback: resolve via application_id
  IF v_resolved_id IS NULL THEN
    SELECT ja.id INTO v_resolved_id
    FROM public.job_assignments ja
    JOIN public.job_applications app ON ja.job_id = app.job_id AND ja.worker_id = app.worker_id
    WHERE app.id = p_assignment_id
    ORDER BY ja.created_at DESC
    LIMIT 1;
  END IF;

  -- Defensive fallback: resolve via job_id
  IF v_resolved_id IS NULL THEN
    SELECT ja.id INTO v_resolved_id
    FROM public.job_assignments ja
    WHERE ja.job_id = p_assignment_id AND ja.worker_id = v_uid
    ORDER BY ja.created_at DESC
    LIMIT 1;
  END IF;

  IF v_resolved_id IS NULL THEN
    RAISE EXCEPTION 'Assignment not found.';
  END IF;

  SELECT
    ja.id AS assignment_id, ja.booking_code, ja.status::TEXT AS status, ja.job_id,
    ja.worker_id, ja.agreed_wage_paise, ja.started_at, ja.ended_at,
    j.title AS job_title, j.wage_type::TEXT AS wage_type, j.payment_mode::TEXT AS payment_mode,
    j.start_at, j.est_duration_minutes, j.address_text,
    extensions.ST_Y(j.location::extensions.geometry) AS lat,
    extensions.ST_X(j.location::extensions.geometry) AS lng,
    j.provider_id,
    COALESCE(sc.names->>'en', 'Work')::TEXT AS category_name,
    COALESCE(sc.icon, 'work')::TEXT AS category_icon,
    COALESCE(wp_prof.full_name, 'Worker')::TEXT AS worker_name,
    wp_prof.avatar_path::TEXT AS worker_avatar,
    COALESCE(wp.is_verified_badge, false) AS is_worker_verified,
    COALESCE(wp.seeker_type::TEXT, 'informal')::TEXT AS worker_seeker_type,
    COALESCE(prov_prof.full_name, 'Employer')::TEXT AS provider_name
  INTO v_rec
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  JOIN public.profiles wp_prof ON ja.worker_id = wp_prof.id
  LEFT JOIN public.worker_profiles wp ON ja.worker_id = wp.user_id
  JOIN public.profiles prov_prof ON j.provider_id = prov_prof.id
  WHERE ja.id = v_resolved_id;

  IF v_rec.assignment_id IS NULL THEN
    RAISE EXCEPTION 'Assignment not found.';
  END IF;

  IF v_rec.worker_id != v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only assigned worker can issue job ticket.';
  END IF;

  IF v_rec.status IN ('accepted', 'requested') THEN
    UPDATE public.job_assignments SET status = 'ticket_issued', updated_at = NOW() WHERE id = v_resolved_id;
    v_rec.status := 'ticket_issued';
  END IF;

  RETURN jsonb_build_object(
    'assignment_id', v_rec.assignment_id,
    'booking_code', v_rec.booking_code,
    'status', v_rec.status,
    'job_id', v_rec.job_id,
    'job_title', v_rec.job_title,
    'category_name', v_rec.category_name,
    'category_icon', v_rec.category_icon,
    'start_at', v_rec.start_at,
    'est_duration_minutes', v_rec.est_duration_minutes,
    'agreed_wage_paise', v_rec.agreed_wage_paise,
    'wage_type', v_rec.wage_type,
    'payment_mode', v_rec.payment_mode,
    'address_text', v_rec.address_text,
    'lat', v_rec.lat,
    'lng', v_rec.lng,
    'worker_id', v_rec.worker_id,
    'worker_name', v_rec.worker_name,
    'worker_avatar', v_rec.worker_avatar,
    'is_worker_verified', v_rec.is_worker_verified,
    'worker_seeker_type', v_rec.worker_seeker_type,
    'provider_id', v_rec.provider_id,
    'provider_name', v_rec.provider_name
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.issue_job_ticket(UUID) TO authenticated, anon;


-- 4. DEFENSIVE get_rotating_ticket_token() (RESOLVES APPLICATION ID OR ASSIGNMENT ID)
CREATE OR REPLACE FUNCTION public.get_rotating_ticket_token(
  p_assignment_id UUID,
  p_debug_short_ttl BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_resolved_id UUID := p_assignment_id;
  v_worker_id UUID;
  v_token TEXT;
  v_hash TEXT;
  v_ttl INT := 120;
  v_expires TIMESTAMPTZ;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Check direct assignment match
  SELECT id, worker_id INTO v_resolved_id, v_worker_id
  FROM public.job_assignments
  WHERE id = p_assignment_id;

  -- Defensive fallback: resolve via application_id
  IF v_resolved_id IS NULL THEN
    SELECT ja.id, ja.worker_id INTO v_resolved_id, v_worker_id
    FROM public.job_assignments ja
    JOIN public.job_applications app ON ja.job_id = app.job_id AND ja.worker_id = app.worker_id
    WHERE app.id = p_assignment_id
    ORDER BY ja.created_at DESC
    LIMIT 1;
  END IF;

  IF v_resolved_id IS NULL THEN
    RAISE EXCEPTION 'Assignment not found.';
  END IF;

  IF v_worker_id != v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only assigned worker can get ticket QR.';
  END IF;

  IF p_debug_short_ttl THEN
    v_ttl := 15;
  END IF;

  v_expires := NOW() + (v_ttl || ' seconds')::INTERVAL;
  v_token := 'TKT-' || UPPER(SUBSTRING(encode(extensions.gen_random_bytes(16), 'hex') FROM 1 FOR 24));
  v_hash := encode(extensions.digest(v_token, 'sha256'), 'hex');

  INSERT INTO public.qr_tokens (
    assignment_id,
    token_id_hash,
    purpose,
    expires_at,
    created_at
  )
  VALUES (
    v_resolved_id,
    v_hash,
    'ticket',
    v_expires,
    NOW()
  );

  RETURN jsonb_build_object(
    'qr_token', v_token,
    'assignment_id', v_resolved_id,
    'expires_in_seconds', v_ttl,
    'expires_at', v_expires,
    'mode', 'rotating',
    'created_at', NOW()
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_rotating_ticket_token(UUID, BOOLEAN) TO authenticated, anon;


-- 5. BACKFILL EXISTING HIRED APPLICATIONS MISSING ASSIGNMENTS
DO $$
DECLARE
  r RECORD;
  v_new_asg_id UUID;
  v_c_id UUID;
BEGIN
  FOR r IN (
    SELECT ja.id AS app_id, ja.job_id, ja.worker_id, j.provider_id, j.wage_paise, j.title
    FROM public.job_applications ja
    JOIN public.jobs j ON ja.job_id = j.id
    LEFT JOIN public.job_assignments asg ON asg.job_id = ja.job_id AND asg.worker_id = ja.worker_id
    WHERE ja.status = 'hired' AND asg.id IS NULL
  ) LOOP
    -- Insert missing assignment
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
      r.job_id,
      r.worker_id,
      'BOOK-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::text, 1, 6)),
      COALESCE(r.wage_paise, 60000),
      'accepted',
      NOW(),
      NOW()
    )
    RETURNING id INTO v_new_asg_id;

    -- Ensure conversation exists
    INSERT INTO public.conversations (
      job_id,
      provider_id,
      seeker_id,
      context_type,
      context_id,
      booking_id,
      last_message_at,
      created_at
    )
    VALUES (
      r.job_id,
      r.provider_id,
      r.worker_id,
      'job',
      r.job_id,
      v_new_asg_id,
      NOW(),
      NOW()
    )
    ON CONFLICT (job_id, provider_id, seeker_id)
    DO UPDATE SET
      booking_id = COALESCE(public.conversations.booking_id, EXCLUDED.booking_id),
      last_message_at = NOW()
    RETURNING id INTO v_c_id;

    -- Ensure welcome message exists
    IF v_c_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.messages WHERE conversation_id = v_c_id
    ) THEN
      INSERT INTO public.messages (
        conversation_id,
        sender_id,
        body,
        created_at
      )
      VALUES (
        v_c_id,
        r.provider_id,
        'Congratulations! Application accepted for "' || COALESCE(r.title, 'this position') || '". You can coordinate work details and timings here.',
        NOW()
      );
    END IF;
  END LOOP;
END $$;


-- 6. GRANT ALL REQUIRED PRIVILEGES ON CHAT & EXECUTION TABLES
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.conversations TO authenticated, anon, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.messages TO authenticated, anon, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.chat_blocks TO authenticated, anon, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.chat_reports TO authenticated, anon, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.job_assignments TO authenticated, anon, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.assignment_events TO authenticated, anon, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.qr_tokens TO authenticated, anon, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.attendance_logs TO authenticated, anon, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;

-- 7. ENSURE REALTIME SUBSCRIPTION FOR CHAT & ASSIGNMENTS
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

    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'job_assignments'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.job_assignments;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'assignment_events'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.assignment_events;
    END IF;
  END IF;
END $$;
