-- ============================================================================
-- Migration: 0720_chat_masking_threads_and_calls.sql
-- Step P7.1 & P7.2: Protected Inbox, Realtime Chat Masking, Masked Voice Proxy
-- ============================================================================

-- 1. ENHANCE CHAT_THREADS TABLE
ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS subject TEXT,
  ADD COLUMN IF NOT EXISTS booking_code TEXT,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'read_only', 'archived')),
  ADD COLUMN IF NOT EXISTS read_only_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS category_tag TEXT DEFAULT 'general' CHECK (category_tag IN ('general', 'worker', 'customer', 'farmer'));

CREATE INDEX IF NOT EXISTS idx_chat_threads_status_last_msg
  ON public.chat_threads (status, last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_threads_booking_code
  ON public.chat_threads (booking_code);

-- 2. SERVER-SIDE MESSAGE MASKING FUNCTION & TRIGGER
CREATE OR REPLACE FUNCTION public.mask_chat_message_content()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_thread_status TEXT;
  v_original_body TEXT;
  v_masked_body TEXT;
  v_was_masked BOOLEAN := false;
BEGIN
  -- Check thread status: if read_only, block message
  SELECT status INTO v_thread_status
  FROM public.chat_threads
  WHERE id = NEW.thread_id;

  IF v_thread_status = 'read_only' THEN
    RAISE EXCEPTION 'This chat thread is closed and read-only.';
  END IF;

  v_original_body := NEW.body;
  v_masked_body := v_original_body;

  -- A. Mask Indian phone numbers:
  -- 1) Standard +91 or 91 or 0 prefix followed by 10 digits (with optional spaces, dashes, or dots)
  IF v_masked_body ~* '(?:\+91|91|0)[\s\-\.]?[6-9](?:[\s\-\.]?[0-9]){9}' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '(?:\+91|91|0)[\s\-\.]?[6-9](?:[\s\-\.]?[0-9]){9}',
      '[MASKED PHONE NUMBER]',
      'g'
    );
    v_was_masked := true;
  END IF;

  -- 2) 10-digit mobile starting with 6-9 (including spaced digits like "98765 43210" or "9876 543 210")
  IF v_masked_body ~* '\m[6-9](?:[\s\-\.]?[0-9]){9}\M' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '\m[6-9](?:[\s\-\.]?[0-9]){9}\M',
      '[MASKED PHONE NUMBER]',
      'g'
    );
    v_was_masked := true;
  END IF;

  -- B. Mask UPI IDs (e.g. name@okhdfcbank, 9876543210@ybl, user.name@paytm, etc.)
  IF v_masked_body ~* '[a-zA-Z0-9.\-_]{2,256}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '[a-zA-Z0-9.\-_]{2,256}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})',
      '[MASKED UPI HANDLE]',
      'gi'
    );
    v_was_masked := true;
  END IF;

  -- C. Mask off-platform solicitations with phone keywords
  IF v_masked_body ~* '(?:call|contact|whatsapp|gpay|paytm|phonepe|transfer)[\s\w]*?(?:on|at|to)?[\s:]*[6-9][0-9]{9}' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '(?:call|contact|whatsapp|gpay|paytm|phonepe|transfer)[\s\w]*?(?:on|at|to)?[\s:]*[6-9][0-9]{9}',
      '[OFF-PLATFORM CONTACT MASKED]',
      'gi'
    );
    v_was_masked := true;
  END IF;

  IF v_was_masked THEN
    NEW.body := v_masked_body || E'\n\n[🔒 Notice: Contact details and direct payment handles are automatically masked by UdyogaSethu for your security. Please keep all communications and payments protected within the platform escrow.]';
    NEW.was_masked := true;
  END IF;

  -- Update thread's last_message_at
  UPDATE public.chat_threads
  SET last_message_at = NOW()
  WHERE id = NEW.thread_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mask_chat_message ON public.chat_messages;
CREATE TRIGGER trg_mask_chat_message
  BEFORE INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.mask_chat_message_content();

-- 3. GET OR CREATE CHAT THREAD RPC
CREATE OR REPLACE FUNCTION public.get_or_create_chat_thread(
  p_context_type TEXT,
  p_context_id UUID,
  p_recipient_id UUID,
  p_subject TEXT DEFAULT NULL,
  p_booking_code TEXT DEFAULT NULL,
  p_category_tag TEXT DEFAULT 'general'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_participant_a UUID;
  v_participant_b UUID;
  v_thread_id UUID;
  v_subject TEXT := p_subject;
  v_booking_code TEXT := p_booking_code;
  v_category_tag TEXT := p_category_tag;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_recipient_id IS NULL OR p_recipient_id = v_caller_id THEN
    RAISE EXCEPTION 'Invalid recipient ID';
  END IF;

  -- Sort participant IDs deterministically to satisfy UNIQUE constraint
  IF v_caller_id < p_recipient_id THEN
    v_participant_a := v_caller_id;
    v_participant_b := p_recipient_id;
  ELSE
    v_participant_a := p_recipient_id;
    v_participant_b := v_caller_id;
  END IF;

  -- Check existing thread
  SELECT id INTO v_thread_id
  FROM public.chat_threads
  WHERE participant_a = v_participant_a
    AND participant_b = v_participant_b
    AND context_type = p_context_type
    AND context_id = p_context_id;

  IF v_thread_id IS NOT NULL THEN
    -- Update subject / booking code if missing
    IF v_subject IS NOT NULL OR v_booking_code IS NOT NULL THEN
      UPDATE public.chat_threads
      SET subject = COALESCE(subject, v_subject),
          booking_code = COALESCE(booking_code, v_booking_code),
          category_tag = COALESCE(category_tag, v_category_tag)
      WHERE id = v_thread_id;
    END IF;
    RETURN v_thread_id;
  END IF;

  -- If subject is missing, try inferring from assignment, order, or job
  IF v_subject IS NULL THEN
    IF p_context_type = 'assignment' THEN
      SELECT j.title, 'BOOK-' || UPPER(SUBSTRING(a.id::TEXT FROM 1 FOR 6))
      INTO v_subject, v_booking_code
      FROM public.job_assignments a
      JOIN public.jobs j ON j.id = a.job_id
      WHERE a.id = p_context_id;
      v_category_tag := 'worker';
    ELSIF p_context_type = 'order' THEN
      SELECT 'Order ' || o.order_code, o.order_code
      INTO v_subject, v_booking_code
      FROM public.orders o
      WHERE o.id = p_context_id;
      v_category_tag := 'farmer';
    ELSIF p_context_type = 'job' THEN
      SELECT j.title, 'JOB-' || UPPER(SUBSTRING(j.id::TEXT FROM 1 FOR 6))
      INTO v_subject, v_booking_code
      FROM public.jobs j
      WHERE j.id = p_context_id;
      v_category_tag := 'worker';
    END IF;
  END IF;

  -- Create new thread
  INSERT INTO public.chat_threads (
    context_type,
    context_id,
    participant_a,
    participant_b,
    subject,
    booking_code,
    category_tag,
    status,
    last_message_at
  ) VALUES (
    p_context_type,
    p_context_id,
    v_participant_a,
    v_participant_b,
    COALESCE(v_subject, 'Direct Inquiry'),
    COALESCE(v_booking_code, 'COMM-' || UPPER(SUBSTRING(p_context_id::TEXT FROM 1 FOR 6))),
    COALESCE(v_category_tag, 'general'),
    'active',
    NOW()
  )
  RETURNING id INTO v_thread_id;

  RETURN v_thread_id;
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.get_or_create_chat_thread(TEXT, UUID, UUID, TEXT, TEXT, TEXT) TO authenticated;

-- 4. AUTO-THREAD CREATION TRIGGERS FOR ASSIGNMENTS AND ORDERS
CREATE OR REPLACE FUNCTION public.auto_create_assignment_chat_thread()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_employer_id UUID;
  v_job_title TEXT;
  v_code TEXT;
  v_pa UUID;
  v_pb UUID;
BEGIN
  -- Get employer and title from job
  SELECT j.employer_id, j.title
  INTO v_employer_id, v_job_title
  FROM public.jobs j
  WHERE j.id = NEW.job_id;

  IF v_employer_id IS NOT NULL AND NEW.worker_id IS NOT NULL THEN
    v_code := 'BOOK-' || UPPER(SUBSTRING(NEW.id::TEXT FROM 1 FOR 6));
    IF NEW.worker_id < v_employer_id THEN
      v_pa := NEW.worker_id;
      v_pb := v_employer_id;
    ELSE
      v_pa := v_employer_id;
      v_pb := NEW.worker_id;
    END IF;

    INSERT INTO public.chat_threads (
      context_type,
      context_id,
      participant_a,
      participant_b,
      subject,
      booking_code,
      category_tag,
      status,
      last_message_at
    ) VALUES (
      'assignment',
      NEW.id,
      v_pa,
      v_pb,
      COALESCE(v_job_title, 'Service Assignment'),
      v_code,
      'worker',
      'active',
      NOW()
    )
    ON CONFLICT (participant_a, participant_b, context_type, context_id)
    DO UPDATE SET booking_code = EXCLUDED.booking_code;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_thread_assignment ON public.job_assignments;
CREATE TRIGGER trg_auto_thread_assignment
  AFTER INSERT ON public.job_assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_assignment_chat_thread();

-- 5. THREAD READ-ONLY TRIGGER ON ASSIGNMENT COMPLETION / CANCELLATION
CREATE OR REPLACE FUNCTION public.set_assignment_thread_read_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status IN ('completed', 'cancelled') AND OLD.status NOT IN ('completed', 'cancelled') THEN
    UPDATE public.chat_threads
    SET status = 'read_only',
        read_only_at = NOW()
    WHERE context_type = 'assignment'
      AND context_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_assignment_thread_close ON public.job_assignments;
CREATE TRIGGER trg_assignment_thread_close
  AFTER UPDATE OF status ON public.job_assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.set_assignment_thread_read_only();

-- 6. CALL LOGS TABLE (P7.2)
CREATE TABLE IF NOT EXISTS public.call_logs (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  caller_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  booking_code TEXT,
  assignment_id UUID REFERENCES public.job_assignments(id) ON DELETE SET NULL,
  provider TEXT NOT NULL DEFAULT 'mock',
  status TEXT NOT NULL DEFAULT 'initiated' CHECK (status IN ('initiated', 'ringing', 'connected', 'completed', 'busy', 'failed', 'cancelled')),
  duration_seconds INT NOT NULL DEFAULT 0,
  proxy_number TEXT NOT NULL DEFAULT '+91 80 4719 8200',
  call_sid TEXT,
  is_demo BOOLEAN NOT NULL DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ
);

ALTER TABLE public.call_logs ENABLE ROW LEVEL SECURITY;

-- Call logs RLS: Only call participants or admin can view
CREATE POLICY call_logs_select ON public.call_logs
  FOR SELECT
  USING (caller_id = auth.uid() OR recipient_id = auth.uid() OR public.is_admin());

CREATE POLICY call_logs_insert ON public.call_logs
  FOR INSERT
  WITH CHECK (caller_id = auth.uid() OR public.is_admin());

CREATE POLICY call_logs_update ON public.call_logs
  FOR UPDATE
  USING (caller_id = auth.uid() OR public.is_admin());

-- 7. INITIATE MASKED CALL RPC (P7.2)
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
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_recipient_id IS NULL OR p_recipient_id = v_caller_id THEN
    RAISE EXCEPTION 'Invalid recipient ID';
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
    'call_id', v_call_id,
    'status', 'connected',
    'proxy_number', v_proxy_number,
    'is_demo', true,
    'caller_name', COALESCE(v_caller_name, 'Udyoga User'),
    'recipient_name', COALESCE(v_recipient_name, 'Verified Contact'),
    'booking_code', COALESCE(v_booking_code, 'DIRECT-CALL')
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.initiate_masked_call(UUID, TEXT, UUID) TO authenticated;

-- 8. END MASKED CALL RPC
CREATE OR REPLACE FUNCTION public.end_masked_call(
  p_call_id UUID,
  p_duration_seconds INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.call_logs
  SET status = 'completed',
      duration_seconds = GREATEST(p_duration_seconds, 0),
      ended_at = NOW()
  WHERE id = p_call_id
    AND (caller_id = auth.uid() OR public.is_admin());

  RETURN jsonb_build_object('ok', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.end_masked_call(UUID, INT) TO authenticated;
