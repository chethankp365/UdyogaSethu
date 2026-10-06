-- Migration: 0270_safety_onboarding.sql
-- Description: Safety Onboarding data-driven workflow, slot booking with capacity enforcement,
--              recompute_verification_badge with 4 ticks (eKYC, Face Liveness, 1-Day Training, Document Approval),
--              XP event logging, safety_first badge award, and debug status simulation.

-- 1. Function: recompute_verification_badge
CREATE OR REPLACE FUNCTION public.recompute_verification_badge(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_kyc_ok BOOLEAN := false;
  v_face_ok BOOLEAN := false;
  v_training_ok BOOLEAN := false;
  v_doc_ok BOOLEAN := false;
  v_badge BOOLEAN := false;
  v_old_badge BOOLEAN := false;
  v_badge_id UUID;
BEGIN
  -- Tick 1: Aadhaar eKYC Verified
  SELECT (status = 'verified') INTO v_kyc_ok
  FROM public.kyc_records 
  WHERE user_id = p_user_id AND doc_type IN ('aadhaar', 'ekyc')
  LIMIT 1;

  -- Tick 2: Face Liveness Setup
  SELECT (status = 'verified') INTO v_face_ok
  FROM public.face_profiles 
  WHERE user_id = p_user_id 
  LIMIT 1;

  -- Tick 3: 1-Day Training Attended (status is attended, document_review, or approved for safety_onboarding)
  SELECT EXISTS (
    SELECT 1 
    FROM public.event_registrations er
    JOIN public.training_events te ON er.event_id = te.id
    WHERE er.user_id = p_user_id 
      AND te.kind = 'safety_onboarding'
      AND er.status IN ('attended', 'document_review', 'approved')
  ) INTO v_training_ok;

  -- Tick 4: Document Approval (status is approved for safety_onboarding)
  SELECT EXISTS (
    SELECT 1 
    FROM public.event_registrations er
    JOIN public.training_events te ON er.event_id = te.id
    WHERE er.user_id = p_user_id 
      AND te.kind = 'safety_onboarding'
      AND er.status = 'approved'
  ) INTO v_doc_ok;

  -- Overall Verified Badge requires ALL 4 ticks
  v_badge := (
    COALESCE(v_kyc_ok, false) AND 
    COALESCE(v_face_ok, false) AND 
    COALESCE(v_training_ok, false) AND 
    COALESCE(v_doc_ok, false)
  );

  -- Check previous badge state
  SELECT COALESCE(is_verified_badge, false) INTO v_old_badge
  FROM public.worker_profiles
  WHERE user_id = p_user_id;

  -- Update worker profile
  UPDATE public.worker_profiles
  SET is_verified_badge = v_badge, updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Award XP & Badge when earned for the first time
  IF v_badge AND NOT v_old_badge THEN
    -- 1. Insert XP Event (100 XP)
    IF NOT EXISTS (
      SELECT 1 FROM public.xp_events 
      WHERE user_id = p_user_id AND kind = 'verified_badge_earned'
    ) THEN
      INSERT INTO public.xp_events (user_id, kind, points)
      VALUES (p_user_id, 'verified_badge_earned', 100);
    END IF;

    -- 2. Award safety_first badge if registered in badges table
    SELECT id INTO v_badge_id FROM public.badges WHERE slug = 'safety_first' LIMIT 1;
    IF v_badge_id IS NOT NULL THEN
      INSERT INTO public.user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge_id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END IF;

  RETURN v_badge;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Function: get_safety_onboarding_status
CREATE OR REPLACE FUNCTION public.get_safety_onboarding_status(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_kyc_ok BOOLEAN := false;
  v_face_ok BOOLEAN := false;
  v_training_ok BOOLEAN := false;
  v_doc_ok BOOLEAN := false;
  v_badge BOOLEAN := false;
  v_reg_record RECORD;
  v_event_record RECORD;
BEGIN
  -- Get 4 ticks
  SELECT (status = 'verified') INTO v_kyc_ok
  FROM public.kyc_records 
  WHERE user_id = p_user_id AND doc_type IN ('aadhaar', 'ekyc')
  LIMIT 1;

  SELECT (status = 'verified') INTO v_face_ok
  FROM public.face_profiles 
  WHERE user_id = p_user_id 
  LIMIT 1;

  SELECT er.id AS reg_id, er.event_id, er.status AS reg_status, er.created_at AS registered_at
  INTO v_reg_record
  FROM public.event_registrations er
  JOIN public.training_events te ON er.event_id = te.id
  WHERE er.user_id = p_user_id AND te.kind = 'safety_onboarding'
  ORDER BY er.created_at DESC
  LIMIT 1;

  IF v_reg_record.reg_status IN ('attended', 'document_review', 'approved') THEN
    v_training_ok := true;
  END IF;

  IF v_reg_record.reg_status = 'approved' THEN
    v_doc_ok := true;
  END IF;

  SELECT is_verified_badge INTO v_badge 
  FROM public.worker_profiles 
  WHERE user_id = p_user_id;

  -- Get latest safety onboarding event
  SELECT id, title, description, venue, starts_at, capacity, language
  INTO v_event_record
  FROM public.training_events
  WHERE kind = 'safety_onboarding'
  ORDER BY starts_at ASC
  LIMIT 1;

  RETURN jsonb_build_object(
    'is_verified_badge', COALESCE(v_badge, false),
    'kyc_ok', COALESCE(v_kyc_ok, false),
    'face_ok', COALESCE(v_face_ok, false),
    'training_ok', v_training_ok,
    'doc_ok', v_doc_ok,
    'registration_status', COALESCE(v_reg_record.reg_status::TEXT, 'not_booked'),
    'registered_at', v_reg_record.registered_at,
    'event', CASE WHEN v_event_record.id IS NOT NULL THEN jsonb_build_object(
      'id', v_event_record.id,
      'title', v_event_record.title,
      'description', v_event_record.description,
      'venue', v_event_record.venue,
      'starts_at', v_event_record.starts_at,
      'capacity', v_event_record.capacity,
      'language', v_event_record.language
    ) ELSE NULL END
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 3. Function: book_safety_onboarding_slot
CREATE OR REPLACE FUNCTION public.book_safety_onboarding_slot(p_event_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_capacity INT;
  v_current_count INT;
  v_event_kind public.training_event_kind;
  v_reg_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated user call';
  END IF;

  -- Verify event exists & capacity
  SELECT capacity, kind INTO v_capacity, v_event_kind
  FROM public.training_events
  WHERE id = p_event_id;

  IF v_capacity IS NULL THEN
    RAISE EXCEPTION 'Training event not found';
  END IF;

  -- Count existing registrations (excluding rejected)
  SELECT COUNT(*) INTO v_current_count
  FROM public.event_registrations
  WHERE event_id = p_event_id AND status != 'rejected' AND user_id != v_user_id;

  IF v_current_count >= v_capacity THEN
    RAISE EXCEPTION 'P0003: Training event capacity reached (% / % slots filled)', v_current_count, v_capacity;
  END IF;

  -- Upsert registration
  INSERT INTO public.event_registrations (event_id, user_id, status, updated_at)
  VALUES (p_event_id, v_user_id, 'registered', NOW())
  ON CONFLICT (event_id, user_id) 
  DO UPDATE SET status = 'registered', updated_at = NOW()
  RETURNING id INTO v_reg_id;

  -- Create system notification for P7.4 push notifications / reminders
  INSERT INTO public.notifications (user_id, title, body, kind)
  VALUES (
    v_user_id,
    'Safety Onboarding Slot Confirmed',
    'Your 1-day safety onboarding slot is confirmed. Please report on time with your ID.',
    'system'
  );

  -- Recompute verification badge status
  PERFORM public.recompute_verification_badge(v_user_id);

  RETURN public.get_safety_onboarding_status(v_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Function: simulate_training_status (Debug / Demo Mode only)
CREATE OR REPLACE FUNCTION public.simulate_training_status(p_user_id UUID, p_status TEXT)
RETURNS JSONB AS $$
DECLARE
  v_event_id UUID;
BEGIN
  -- Get or create safety onboarding event
  SELECT id INTO v_event_id
  FROM public.training_events
  WHERE kind = 'safety_onboarding'
  LIMIT 1;

  IF v_event_id IS NULL THEN
    INSERT INTO public.training_events (kind, title, description, venue, starts_at, capacity, language)
    VALUES (
      'safety_onboarding',
      'Worksite Safety & PPE Onboarding Day',
      'Hands-on training covering helmet usage, harness safety and emergency protocol.',
      NOW() + INTERVAL '5 days',
      'Koramangala Community Centre, Bengaluru',
      50,
      'en'
    )
    RETURNING id INTO v_event_id;
  END IF;

  IF p_status = 'not_booked' THEN
    DELETE FROM public.event_registrations
    WHERE event_id = v_event_id AND user_id = p_user_id;
  ELSE
    INSERT INTO public.event_registrations (event_id, user_id, status, updated_at)
    VALUES (v_event_id, p_user_id, p_status::public.event_registration_status, NOW())
    ON CONFLICT (event_id, user_id)
    DO UPDATE SET status = p_status::public.event_registration_status, updated_at = NOW();
  END IF;

  -- Recompute verification badge status
  PERFORM public.recompute_verification_badge(p_user_id);

  RETURN public.get_safety_onboarding_status(p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Grant execution permissions
GRANT EXECUTE ON FUNCTION public.recompute_verification_badge(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_safety_onboarding_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.book_safety_onboarding_slot(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.simulate_training_status(UUID, TEXT) TO authenticated;
