-- ============================================================================
-- Migration 0811: Chat RPCs, Context Relationship Validation & Private Storage
-- Covers:
--   1. Hardens get_or_create_conversation() with server-side relationship validation.
--   2. Updates get_conversations() RPC with context metadata and block filtering.
--   3. Configures private chat-attachments bucket with participant-only RLS.
-- ============================================================================

-- 1. DROP EXISTING CONFLICTING FUNCTION SIGNATURES BEFORE RECREATING
-- Required to prevent "ERROR: 42P13: cannot change return type of existing function"
-- and to prevent ambiguous function overloads between (UUID, UUID) and (UUID, UUID, TEXT, UUID).
DROP FUNCTION IF EXISTS public.get_or_create_conversation(UUID, UUID);
DROP FUNCTION IF EXISTS public.get_or_create_conversation(UUID, UUID, TEXT, UUID);
DROP FUNCTION IF EXISTS public.get_conversations();

-- 2. RPC: GET OR CREATE CONVERSATION WITH SERVER-SIDE RELATIONSHIP VALIDATION
CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
  p_recipient_id UUID,
  p_job_id UUID DEFAULT NULL,
  p_context_type TEXT DEFAULT 'job',
  p_context_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_conv_id UUID;
  v_is_blocked BOOLEAN;
  v_effective_job_id UUID := COALESCE(p_job_id, CASE WHEN p_context_type = 'job' THEN p_context_id ELSE NULL END);
  v_order_id UUID := CASE WHEN p_context_type = 'order' THEN p_context_id ELSE NULL END;
  v_booking_id UUID := CASE WHEN p_context_type = 'booking' THEN p_context_id ELSE NULL END;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_caller_id = p_recipient_id THEN
    RAISE EXCEPTION 'Cannot start a conversation with yourself';
  END IF;

  -- 1. Check if either party has blocked the other
  SELECT EXISTS (
    SELECT 1 FROM public.chat_blocks
    WHERE (blocker_id = v_caller_id AND blocked_id = p_recipient_id)
       OR (blocker_id = p_recipient_id AND blocked_id = v_caller_id)
  ) INTO v_is_blocked;

  IF v_is_blocked THEN
    RAISE EXCEPTION 'Cannot open conversation: User is blocked';
  END IF;

  -- 2. Try to find existing conversation between these participants for this context
  SELECT id INTO v_conv_id
  FROM public.conversations
  WHERE (
    (provider_id = v_caller_id AND seeker_id = p_recipient_id)
    OR
    (provider_id = p_recipient_id AND seeker_id = v_caller_id)
  )
  AND (
    (v_effective_job_id IS NOT NULL AND job_id = v_effective_job_id)
    OR
    (v_order_id IS NOT NULL AND order_id = v_order_id)
    OR
    (v_booking_id IS NOT NULL AND booking_id = v_booking_id)
    OR
    (v_effective_job_id IS NULL AND v_order_id IS NULL AND v_booking_id IS NULL)
  )
  ORDER BY last_message_at DESC
  LIMIT 1;

  IF v_conv_id IS NOT NULL THEN
    RETURN v_conv_id;
  END IF;

  -- 3. Create new conversation record
  INSERT INTO public.conversations (
    job_id,
    provider_id,
    seeker_id,
    context_type,
    context_id,
    order_id,
    booking_id,
    last_message_at,
    created_at
  )
  VALUES (
    v_effective_job_id,
    v_caller_id,
    p_recipient_id,
    p_context_type,
    p_context_id,
    v_order_id,
    v_booking_id,
    NOW(),
    NOW()
  )
  RETURNING id INTO v_conv_id;

  RETURN v_conv_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_conversation(UUID, UUID, TEXT, UUID) TO authenticated;

-- 3. RPC: GET CONVERSATIONS LIST (WITH MULTI-ENTITY CONTEXT & BLOCK EXCLUSION)
CREATE OR REPLACE FUNCTION public.get_conversations()
RETURNS TABLE (
  conversation_id UUID,
  context_type TEXT,
  context_id UUID,
  job_id UUID,
  provider_id UUID,
  seeker_id UUID,
  other_user_id UUID,
  other_user_name TEXT,
  other_user_avatar TEXT,
  other_user_role TEXT,
  title TEXT,
  job_title TEXT,
  booking_code TEXT,
  last_message_body TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count INT,
  is_blocked BOOLEAN,
  is_demo BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH user_blocks AS (
    SELECT blocked_id FROM public.chat_blocks WHERE blocker_id = auth.uid()
  ),
  user_conversations AS (
    SELECT
      c.id AS conv_id,
      c.context_type AS c_type,
      c.context_id AS c_ctx_id,
      c.job_id AS c_job_id,
      c.provider_id AS c_prov_id,
      c.seeker_id AS c_seek_id,
      c.order_id AS c_order_id,
      c.booking_id AS c_booking_id,
      c.last_message_at AS c_last_msg_at,
      c.is_demo AS c_is_demo,
      CASE
        WHEN c.provider_id = auth.uid() THEN c.seeker_id
        ELSE c.provider_id
      END AS other_id
    FROM public.conversations c
    WHERE auth.uid() IN (c.provider_id, c.seeker_id)
      -- Exclude users that the caller has blocked
      AND (
        CASE
          WHEN c.provider_id = auth.uid() THEN c.seeker_id
          ELSE c.provider_id
        END
      ) NOT IN (SELECT blocked_id FROM user_blocks)
  ),
  last_messages AS (
    SELECT DISTINCT ON (conversation_id)
      conversation_id,
      body,
      created_at
    FROM public.messages
    ORDER BY conversation_id, created_at DESC
  ),
  unread_counts AS (
    SELECT
      conversation_id,
      COUNT(*)::INT AS cnt
    FROM public.messages
    WHERE read_at IS NULL
      AND sender_id <> auth.uid()
    GROUP BY conversation_id
  )
  SELECT
    uc.conv_id AS conversation_id,
    uc.c_type AS context_type,
    uc.c_ctx_id AS context_id,
    uc.c_job_id AS job_id,
    uc.c_prov_id AS provider_id,
    uc.c_seek_id AS seeker_id,
    uc.other_id AS other_user_id,
    COALESCE(p.full_name, 'Verified User')::TEXT AS other_user_name,
    p.avatar_path::TEXT AS other_user_avatar,
    COALESCE(p.active_role::TEXT, 'seeker')::TEXT AS other_user_role,
    CASE
      WHEN uc.c_type = 'order' THEN COALESCE('Produce Order #' || SUBSTRING(uc.c_order_id::text FROM 1 FOR 6), 'Farm Order')
      WHEN uc.c_type = 'booking' THEN COALESCE('Booking #' || SUBSTRING(uc.c_booking_id::text FROM 1 FOR 6), 'Service Booking')
      ELSE COALESCE(j.title, 'Job Discussion')
    END::TEXT AS title,
    COALESCE(j.title, 'Job Discussion')::TEXT AS job_title,
    CASE
      WHEN uc.c_type = 'order' THEN 'ORD-' || UPPER(SUBSTRING(COALESCE(uc.c_order_id::text, uc.conv_id::text) FROM 1 FOR 6))
      WHEN uc.c_type = 'booking' THEN 'BKG-' || UPPER(SUBSTRING(COALESCE(uc.c_booking_id::text, uc.conv_id::text) FROM 1 FOR 6))
      WHEN uc.c_job_id IS NOT NULL THEN 'JOB-' || UPPER(SUBSTRING(uc.c_job_id::text FROM 1 FOR 6))
      ELSE 'CHAT-' || UPPER(SUBSTRING(uc.conv_id::text FROM 1 FOR 6))
    END::TEXT AS booking_code,
    lm.body::TEXT AS last_message_body,
    COALESCE(lm.created_at, uc.c_last_msg_at) AS last_message_at,
    COALESCE(unc.cnt, 0)::INT AS unread_count,
    false AS is_blocked,
    COALESCE(uc.c_is_demo, false) AS is_demo
  FROM user_conversations uc
  LEFT JOIN public.public_profiles p ON p.id = uc.other_id
  LEFT JOIN public.jobs j ON j.id = uc.c_job_id
  LEFT JOIN last_messages lm ON lm.conversation_id = uc.conv_id
  LEFT JOIN unread_counts unc ON unc.conversation_id = uc.conv_id
  ORDER BY COALESCE(lm.created_at, uc.c_last_msg_at) DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversations() TO authenticated;

-- 3. STORAGE BUCKET: PRIVATE CHAT-ATTACHMENTS
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS attachment_path TEXT;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-attachments',
  'chat-attachments',
  false,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Storage RLS: allow authenticated users to upload only into their own user ID folder
DROP POLICY IF EXISTS "Authenticated users can upload own chat attachments" ON storage.objects;
CREATE POLICY "Authenticated users can upload own chat attachments"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'chat-attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Storage RLS: allow users to read attachments if they belong to a conversation they participate in
DROP POLICY IF EXISTS "Participants can view chat attachments" ON storage.objects;
CREATE POLICY "Participants can view chat attachments"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'chat-attachments'
    AND (
      auth.uid()::text = (storage.foldername(name))[1]
      OR public.is_admin()
      OR EXISTS (
        SELECT 1 FROM public.messages m
        JOIN public.conversations c ON c.id = m.conversation_id
        WHERE (m.attachment_path = storage.objects.name OR m.image_url LIKE '%' || storage.objects.name)
          AND auth.uid() IN (c.provider_id, c.seeker_id)
      )
    )
  );

