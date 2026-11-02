-- Migration: 0790_chat_thumbnails_and_seed_cleanup.sql
-- Description:
-- 1. Updates get_provider_jobs to include thumbnail_path and site_photo_url.
-- 2. Fixes mask_realtime_message_content regex repetition bound <= 255.
-- 3. Hardens get_conversations() with LEFT JOIN public.public_profiles and demo-filtering.
-- 4. Adds get_or_create_conversation() RPC for idempotent client conversation lookup.
-- 5. Seeds demo conversations with is_demo = true strictly for demo_users.

-- ----------------------------------------------------------------------------
-- 1. UPDATE get_provider_jobs TO RETURN thumbnail_path AND site_photo_url
-- ----------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.get_provider_jobs(UUID);

CREATE OR REPLACE FUNCTION public.get_provider_jobs(
  p_provider_id UUID DEFAULT auth.uid()
)
RETURNS TABLE (
  id UUID,
  provider_id UUID,
  category_id UUID,
  category_name TEXT,
  category_icon TEXT,
  title TEXT,
  description TEXT,
  wage_type TEXT,
  wage_paise BIGINT,
  est_duration_minutes INT,
  start_at TIMESTAMPTZ,
  slots_total INT,
  slots_filled INT,
  materials_provided BOOLEAN,
  payment_mode TEXT,
  requirements JSONB,
  address_text TEXT,
  geofence_radius_m INT,
  status TEXT,
  created_at TIMESTAMPTZ,
  applicant_count BIGINT,
  hired_count BIGINT,
  site_photo_url TEXT,
  thumbnail_path TEXT
) AS $$
DECLARE
  v_uid UUID;
BEGIN
  v_uid := COALESCE(p_provider_id, auth.uid());
  RETURN QUERY
  SELECT
    j.id,
    j.provider_id,
    j.category_id,
    COALESCE(sc.names->>'en', sc.slug, 'General')::TEXT AS category_name,
    sc.icon::TEXT AS category_icon,
    j.title,
    j.description,
    j.wage_type::TEXT,
    j.wage_paise,
    j.est_duration_minutes,
    j.start_at,
    j.slots_total,
    j.slots_filled,
    j.materials_provided,
    j.payment_mode::TEXT,
    j.requirements,
    j.address_text,
    j.geofence_radius_m,
    j.status::TEXT,
    j.created_at,
    (SELECT COUNT(*) FROM public.job_applications ja WHERE ja.job_id = j.id) AS applicant_count,
    (SELECT COUNT(*) FROM public.job_assignments ass WHERE ass.job_id = j.id AND ass.status NOT IN ('cancelled', 'no_show')) AS hired_count,
    j.site_photo_url::TEXT,
    COALESCE(j.thumbnail_path, j.site_photo_url)::TEXT AS thumbnail_path
  FROM public.jobs j
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  WHERE j.provider_id = v_uid
  ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_provider_jobs(UUID) TO authenticated, anon;

-- ----------------------------------------------------------------------------
-- 2. FIX mask_realtime_message_content REGEX BOUNDS
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

  -- 3. Mask UPI handles (bounded to 100 chars, well below Postgres 255 regex limit)
  IF v_masked_body ~* '[a-zA-Z0-9._-]{2,100}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '[a-zA-Z0-9._-]{2,100}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})',
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

-- ----------------------------------------------------------------------------
-- 3. HARDEN get_conversations() WITH LEFT JOIN & DEMO ISOLATION
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
  v_is_demo_user BOOLEAN := false;
BEGIN
  IF v_uid IS NULL THEN
    RETURN;
  END IF;

  SELECT EXISTS (SELECT 1 FROM public.demo_users WHERE user_id = v_uid) INTO v_is_demo_user;

  RETURN QUERY
  SELECT
    c.id AS conversation_id,
    c.job_id,
    COALESCE(j.title, 'Job Discussion')::TEXT AS job_title,
    c.provider_id,
    c.seeker_id,
    CASE WHEN c.provider_id = v_uid THEN c.seeker_id ELSE c.provider_id END AS other_user_id,
    COALESCE(NULLIF(TRIM(p.full_name), ''), 'User')::TEXT AS other_user_name,
    p.avatar_path::TEXT AS other_user_avatar,
    'user'::TEXT AS other_user_role,
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
  LEFT JOIN public.public_profiles p ON p.id = CASE WHEN c.provider_id = v_uid THEN c.seeker_id ELSE c.provider_id END
  LEFT JOIN LATERAL (
    SELECT lm.body, lm.created_at
    FROM public.messages lm
    WHERE lm.conversation_id = c.id
    ORDER BY lm.created_at DESC
    LIMIT 1
  ) m ON true
  WHERE (c.provider_id = v_uid OR c.seeker_id = v_uid)
    AND (c.is_demo = false OR v_is_demo_user = true)
  ORDER BY c.last_message_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversations() TO authenticated;

-- ----------------------------------------------------------------------------
-- 4. RPC: get_or_create_conversation() FOR CLIENT LOOKUP
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
  p_recipient_id UUID,
  p_job_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_conv_id UUID;
  v_prov_id UUID;
  v_seek_id UUID;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  -- Check if conversation already exists between these users (with or without job_id)
  IF p_job_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE job_id = p_job_id
      AND ((provider_id = v_uid AND seeker_id = p_recipient_id)
           OR (provider_id = p_recipient_id AND seeker_id = v_uid))
    LIMIT 1;
  ELSE
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE (provider_id = v_uid AND seeker_id = p_recipient_id)
       OR (provider_id = p_recipient_id AND seeker_id = v_uid)
    ORDER BY last_message_at DESC
    LIMIT 1;
  END IF;

  IF v_conv_id IS NOT NULL THEN
    RETURN v_conv_id;
  END IF;

  -- Create conversation
  v_prov_id := v_uid;
  v_seek_id := p_recipient_id;

  INSERT INTO public.conversations (
    job_id,
    provider_id,
    seeker_id,
    last_message_at,
    created_at
  )
  VALUES (
    p_job_id,
    v_prov_id,
    v_seek_id,
    NOW(),
    NOW()
  )
  RETURNING id INTO v_conv_id;

  RETURN v_conv_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_conversation(UUID, UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 5. SEED SAMPLE CONVERSATIONS FOR DEMO USERS (FLAGGED is_demo = true)
-- ----------------------------------------------------------------------------

DO $$
DECLARE
  v_s1 UUID := '22222222-2222-4222-8222-222222222201'; -- Demo Seeker
  v_p3 UUID := '33333333-3333-4333-8333-333333333303'; -- Demo Provider
  v_job1 UUID;
  v_conv_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_s1)
     AND EXISTS (SELECT 1 FROM public.profiles WHERE id = v_p3) THEN

    SELECT id INTO v_job1 FROM public.jobs WHERE provider_id = v_p3 LIMIT 1;

    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE provider_id = v_p3 AND seeker_id = v_s1
    LIMIT 1;

    IF v_conv_id IS NULL THEN
      INSERT INTO public.conversations (
        job_id,
        provider_id,
        seeker_id,
        last_message_at,
        created_at,
        is_demo
      )
      VALUES (
        v_job1,
        v_p3,
        v_s1,
        NOW() - INTERVAL '30 minutes',
        NOW() - INTERVAL '2 hours',
        true
      )
      RETURNING id INTO v_conv_id;
    END IF;

    IF v_conv_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.messages WHERE conversation_id = v_conv_id) THEN
      INSERT INTO public.messages (conversation_id, sender_id, body, created_at, read_at)
      VALUES
        (v_conv_id, v_p3, 'Welcome! We confirmed your shift assignment for tomorrow morning.', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '45 minutes'),
        (v_conv_id, v_s1, 'Thank you! I will arrive at the site by 8:00 AM sharp with required tools.', NOW() - INTERVAL '40 minutes', NOW() - INTERVAL '35 minutes'),
        (v_conv_id, v_p3, 'Sounds good. Water and tea will be arranged at the location.', NOW() - INTERVAL '30 minutes', NULL);
    END IF;
  END IF;
END $$;
