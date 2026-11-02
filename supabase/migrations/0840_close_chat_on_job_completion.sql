-- ============================================================================
-- Migration 0840: Close Chat and Calling on Job Completion
-- ============================================================================
-- Ensures that when a job assignment is completed/cancelled, or a job is closed/cancelled:
-- 1. Associated conversations are marked 'read_only'.
-- 2. New messages are rejected by trigger with a clear notice.
-- 3. Masked phone calls are rejected once the job has ended.
-- 4. Active inbox queries default to hiding ended/completed chats, while allowing
--    users to inspect historical closed chats in read-only mode if directly accessed.
-- ============================================================================

-- 1. ADD STATUS & READ_ONLY_AT COLUMNS TO CONVERSATIONS
ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS read_only_at TIMESTAMPTZ;

-- Add check constraint for conversation status if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_conversations_status'
  ) THEN
    ALTER TABLE public.conversations
      ADD CONSTRAINT chk_conversations_status
      CHECK (status IN ('active', 'completed', 'read_only', 'archived', 'cancelled'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_conversations_status
  ON public.conversations (status, last_message_at DESC);

-- 2. AUTOMATIC CHAT CLOSURE TRIGGER ON JOB ASSIGNMENTS
CREATE OR REPLACE FUNCTION public.handle_assignment_chat_lifecycle()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- When job assignment is completed or cancelled, close the chat
  IF NEW.status::TEXT IN ('completed', 'cancelled') AND (OLD.status IS NULL OR OLD.status::TEXT NOT IN ('completed', 'cancelled')) THEN
    -- A. Update public.conversations
    UPDATE public.conversations
    SET status = 'read_only',
        read_only_at = NOW()
    WHERE (booking_id = NEW.id OR (job_id = NEW.job_id AND seeker_id = NEW.worker_id))
      AND status = 'active';

    -- B. Update public.chat_threads
    UPDATE public.chat_threads
    SET status = 'read_only',
        read_only_at = NOW()
    WHERE context_type = 'assignment'
      AND context_id = NEW.id
      AND status = 'active';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_assignment_chat_lifecycle ON public.job_assignments;
CREATE TRIGGER trg_assignment_chat_lifecycle
  AFTER UPDATE OF status ON public.job_assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_assignment_chat_lifecycle();

-- 3. AUTOMATIC CHAT CLOSURE TRIGGER ON JOBS (job_status enum: 'draft', 'open', 'filled', 'closed', 'cancelled')
CREATE OR REPLACE FUNCTION public.handle_job_chat_lifecycle()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status::TEXT IN ('closed', 'cancelled') AND (OLD.status IS NULL OR OLD.status::TEXT NOT IN ('closed', 'cancelled')) THEN
    UPDATE public.conversations
    SET status = 'read_only',
        read_only_at = NOW()
    WHERE job_id = NEW.id
      AND status = 'active';

    UPDATE public.chat_threads
    SET status = 'read_only',
        read_only_at = NOW()
    WHERE context_type = 'job'
      AND context_id = NEW.id
      AND status = 'active';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_job_chat_lifecycle ON public.jobs;
CREATE TRIGGER trg_job_chat_lifecycle
  AFTER UPDATE OF status ON public.jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_job_chat_lifecycle();

-- 4. BACKFILL EXISTING COMPLETED ASSIGNMENTS & CLOSED JOBS
UPDATE public.conversations c
SET status = 'read_only',
    read_only_at = NOW()
FROM public.job_assignments a
WHERE (c.booking_id = a.id OR (c.job_id = a.job_id AND c.seeker_id = a.worker_id))
  AND a.status::TEXT IN ('completed', 'cancelled')
  AND c.status = 'active';

UPDATE public.conversations c
SET status = 'read_only',
    read_only_at = NOW()
FROM public.jobs j
WHERE c.job_id = j.id
  AND j.status::TEXT IN ('closed', 'cancelled')
  AND c.status = 'active';

-- 5. REJECT MESSAGES FOR CLOSED / READ-ONLY CONVERSATIONS
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

-- 6. REJECT MASKED CALLS FOR ENDED JOBS
CREATE OR REPLACE FUNCTION public.initiate_masked_call(
  p_recipient_id UUID,
  p_booking_code TEXT DEFAULT NULL,
  p_assignment_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_caller_name TEXT;
  v_recipient_name TEXT;
  v_proxy_number TEXT := '+91 80 4719 8200';
  v_call_id UUID;
  v_booking_code TEXT := p_booking_code;
  v_assign_status TEXT;
  v_conv_status TEXT;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_recipient_id IS NULL OR p_recipient_id = v_caller_id THEN
    RAISE EXCEPTION 'Invalid recipient ID';
  END IF;

  -- Strict Guard: Check if the associated assignment is completed or cancelled
  IF p_assignment_id IS NOT NULL THEN
    SELECT status::TEXT INTO v_assign_status
    FROM public.job_assignments
    WHERE id = p_assignment_id;

    IF v_assign_status IN ('completed', 'cancelled') THEN
      RAISE EXCEPTION 'Voice calling is no longer available. This job has ended.';
    END IF;
  END IF;

  -- Also check if conversation between caller & recipient is read_only
  SELECT status INTO v_conv_status
  FROM public.conversations
  WHERE (provider_id = v_caller_id AND seeker_id = p_recipient_id)
     OR (provider_id = p_recipient_id AND seeker_id = v_caller_id)
  ORDER BY last_message_at DESC
  LIMIT 1;

  IF v_conv_status IN ('read_only', 'completed', 'cancelled') THEN
    RAISE EXCEPTION 'Voice calling is no longer available. This job has ended.';
  END IF;

  SELECT full_name INTO v_caller_name FROM public.profiles WHERE id = v_caller_id;
  SELECT full_name INTO v_recipient_name FROM public.profiles WHERE id = p_recipient_id;

  IF v_booking_code IS NULL AND p_assignment_id IS NOT NULL THEN
    v_booking_code := 'BOOK-' || UPPER(SUBSTRING(p_assignment_id::TEXT FROM 1 FOR 6));
  END IF;

  INSERT INTO public.call_logs (
    caller_id,
    recipient_id,
    booking_code,
    assignment_id,
    provider,
    status,
    proxy_number,
    is_demo,
    created_at
  ) VALUES (
    v_caller_id,
    p_recipient_id,
    COALESCE(v_booking_code, 'CALL-' || UPPER(SUBSTRING(extensions.gen_random_uuid()::TEXT FROM 1 FOR 6))),
    p_assignment_id,
    'mock',
    'connected',
    v_proxy_number,
    true,
    NOW()
  )
  RETURNING id INTO v_call_id;

  RETURN jsonb_build_object(
    'success', true,
    'call_id', v_call_id,
    'caller_id', v_caller_id,
    'caller_name', COALESCE(v_caller_name, 'Verified User'),
    'recipient_id', p_recipient_id,
    'recipient_name', COALESCE(v_recipient_name, 'Service Contact'),
    'proxy_number', v_proxy_number,
    'status', 'connected',
    'booking_code', COALESCE(v_booking_code, 'ACTIVE-SESSION'),
    'is_demo', true
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.initiate_masked_call(UUID, TEXT, UUID) TO authenticated;

-- 7. ENHANCED GET_CONVERSATIONS RPC RETURNING STATUS & SUPPORTING FILTERING
CREATE OR REPLACE FUNCTION public.get_conversations(p_filter TEXT DEFAULT 'all')
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
  is_demo BOOLEAN,
  status TEXT
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
    c.is_demo,
    COALESCE(c.status, 'active')::TEXT AS status
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
    AND (
      p_filter = 'all'
      OR (p_filter = 'active' AND COALESCE(c.status, 'active') = 'active')
      OR (p_filter = 'completed' AND COALESCE(c.status, 'active') IN ('read_only', 'completed', 'cancelled'))
    )
  ORDER BY c.last_message_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversations(TEXT) TO authenticated;
