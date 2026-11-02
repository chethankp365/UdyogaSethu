-- ============================================================================
-- Migration 0826: Fix qr_tokens user_id column and get_rotating_ticket_token
-- ============================================================================

-- 1. Ensure user_id in qr_tokens is nullable so it never crashes if omitted
ALTER TABLE public.qr_tokens ALTER COLUMN user_id DROP NOT NULL;

-- 2. Update get_rotating_ticket_token() to supply user_id
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

  -- Defensive fallback: resolve via job_id
  IF v_resolved_id IS NULL THEN
    SELECT ja.id, ja.worker_id INTO v_resolved_id, v_worker_id
    FROM public.job_assignments ja
    WHERE ja.job_id = p_assignment_id AND ja.worker_id = v_uid
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
    user_id,
    token_id_hash,
    purpose,
    expires_at,
    created_at
  )
  VALUES (
    v_resolved_id,
    v_worker_id,
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
