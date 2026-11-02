-- ============================================================================
-- Migration 0810: Unified Multi-Entity Chat, Reporting & Blocking
-- Covers:
--   1. Extends public.conversations to support job, booking, and produce order contexts.
--   2. Adds public.chat_blocks and public.chat_reports with deny-by-default RLS.
--   3. RPCs: block_user(), unblock_user(), and report_chat_user().
-- ============================================================================

-- 1. EXTEND CONVERSATIONS TABLE
ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS context_type TEXT NOT NULL DEFAULT 'job',
  ADD COLUMN IF NOT EXISTS context_id UUID,
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS booking_id UUID REFERENCES public.job_assignments(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS farmer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Ensure check constraint for context_type
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_conversations_context_type'
  ) THEN
    ALTER TABLE public.conversations
      ADD CONSTRAINT chk_conversations_context_type
      CHECK (context_type IN ('job', 'booking', 'order', 'general'));
  END IF;
END $$;

-- 2. CREATE CHAT_BLOCKS TABLE
CREATE TABLE IF NOT EXISTS public.chat_blocks (
  blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id)
);

ALTER TABLE public.chat_blocks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own blocks" ON public.chat_blocks;
DROP POLICY IF EXISTS "Users can block others" ON public.chat_blocks;
DROP POLICY IF EXISTS "Users can unblock others" ON public.chat_blocks;

CREATE POLICY "Users can view their own blocks"
  ON public.chat_blocks FOR SELECT
  TO authenticated
  USING (auth.uid() = blocker_id OR public.is_admin());

CREATE POLICY "Users can block others"
  ON public.chat_blocks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can unblock others"
  ON public.chat_blocks FOR DELETE
  TO authenticated
  USING (auth.uid() = blocker_id);

-- 3. CREATE CHAT_REPORTS TABLE
CREATE TABLE IF NOT EXISTS public.chat_reports (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reported_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed', 'action_taken')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.chat_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can submit reports" ON public.chat_reports;
DROP POLICY IF EXISTS "Users can view their submitted reports" ON public.chat_reports;

CREATE POLICY "Users can submit reports"
  ON public.chat_reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view their submitted reports"
  ON public.chat_reports FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_id OR public.is_admin());

-- 4. RPC: BLOCK & UNBLOCK USERS
CREATE OR REPLACE FUNCTION public.block_user(p_blocked_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_caller_id = p_blocked_id THEN
    RAISE EXCEPTION 'Cannot block yourself';
  END IF;

  INSERT INTO public.chat_blocks (blocker_id, blocked_id)
  VALUES (v_caller_id, p_blocked_id)
  ON CONFLICT (blocker_id, blocked_id) DO NOTHING;

  RETURN jsonb_build_object('success', true, 'blocked_id', p_blocked_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.block_user(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.unblock_user(p_blocked_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM public.chat_blocks
  WHERE blocker_id = v_caller_id AND blocked_id = p_blocked_id;

  RETURN jsonb_build_object('success', true, 'unblocked_id', p_blocked_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.unblock_user(UUID) TO authenticated;

-- 5. RPC: REPORT USER
CREATE OR REPLACE FUNCTION public.report_chat_user(
  p_reported_user_id UUID,
  p_conversation_id UUID,
  p_reason TEXT,
  p_details TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_report_id UUID;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.chat_reports (
    reporter_id,
    reported_user_id,
    conversation_id,
    reason,
    details
  )
  VALUES (
    v_caller_id,
    p_reported_user_id,
    p_conversation_id,
    p_reason,
    p_details
  )
  RETURNING id INTO v_report_id;

  RETURN jsonb_build_object('success', true, 'report_id', v_report_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.report_chat_user(UUID, UUID, TEXT, TEXT) TO authenticated;
