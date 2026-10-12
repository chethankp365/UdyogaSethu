-- ============================================================================
-- Migration: 0721_fix_chat_masking_regex.sql
-- Fix PostgreSQL regex repetition count and character class in mask_chat_message_content
-- ============================================================================

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
  -- Using [-a-zA-Z0-9._]{2,100} to respect max 255 repetition limit in PostgreSQL POSIX regex
  IF v_masked_body ~* '[-a-zA-Z0-9._]{2,100}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})' THEN
    v_masked_body := regexp_replace(
      v_masked_body,
      '[-a-zA-Z0-9._]{2,100}@(okhdfcbank|okaxis|oksbi|okicici|paytm|ybl|ibl|axl|upi|sbi|hdfc|icici|kotak|barodampay|pnb|allbank|cnrb|postbank|[a-zA-Z]{2,30})',
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
