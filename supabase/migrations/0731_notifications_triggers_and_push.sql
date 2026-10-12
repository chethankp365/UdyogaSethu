-- Migration: 0731_notifications_triggers_and_push.sql
-- Description: Business event triggers to create in-app notifications and device token management (Step P7.4)

-- 1. Device tokens management RPCs
CREATE OR REPLACE FUNCTION public.register_device_token(
  p_token TEXT,
  p_platform TEXT DEFAULT 'android'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.device_tokens (user_id, token, platform, updated_at)
  VALUES (v_user_id, TRIM(p_token), LOWER(TRIM(p_platform)), NOW())
  ON CONFLICT (token)
  DO UPDATE SET
    user_id = EXCLUDED.user_id,
    platform = EXCLUDED.platform,
    updated_at = NOW();

  RETURN jsonb_build_object('ok', true, 'token', p_token);
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_device_token(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM public.device_tokens
  WHERE token = TRIM(p_token) AND user_id = v_user_id;

  RETURN jsonb_build_object('ok', true, 'removed_token', p_token);
END;
$$;

-- 2. Notification utility RPCs: mark read, mark all read, get unread count
CREATE OR REPLACE FUNCTION public.mark_notification_read(p_notification_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.notifications
  SET read_at = NOW()
  WHERE id = p_notification_id AND user_id = v_user_id;

  RETURN jsonb_build_object('ok', true, 'id', p_notification_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_updated_count INT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.notifications
  SET read_at = NOW()
  WHERE user_id = v_user_id AND read_at IS NULL;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  RETURN jsonb_build_object('ok', true, 'updated_count', v_updated_count);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_unread_notification_count()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_count INT;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN 0;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.notifications
  WHERE user_id = v_user_id AND read_at IS NULL;

  RETURN v_count;
END;
$$;

-- 3. Trigger: Job applications (new application notifies provider, response notifies worker)
CREATE OR REPLACE FUNCTION public.trg_notify_on_job_application()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_job RECORD;
  v_worker_name TEXT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Notify provider of new applicant
    SELECT provider_id, title INTO v_job FROM public.jobs WHERE id = NEW.job_id;
    SELECT full_name INTO v_worker_name FROM public.profiles WHERE id = NEW.worker_id;

    IF FOUND AND v_job.provider_id IS NOT NULL THEN
      INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
      VALUES (
        v_job.provider_id,
        'job_application',
        'notif_new_applicant_title',
        'notif_new_applicant_body',
        jsonb_build_object(
          'job_id', NEW.job_id,
          'job_title', COALESCE(v_job.title, 'Job'),
          'worker_name', COALESCE(v_worker_name, 'A worker'),
          'application_id', NEW.id
        )
      );
    END IF;
  ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    -- Notify worker of response
    SELECT title INTO v_job FROM public.jobs WHERE id = NEW.job_id;

    INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
    VALUES (
      NEW.worker_id,
      'application_update',
      'notif_application_status_title',
      'notif_application_status_body',
      jsonb_build_object(
        'job_id', NEW.job_id,
        'job_title', COALESCE(v_job.title, 'Job'),
        'status', NEW.status
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_job_applications_notify ON public.job_applications;
CREATE TRIGGER trg_job_applications_notify
  AFTER INSERT OR UPDATE OF status ON public.job_applications
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_notify_on_job_application();

-- 4. Trigger: Job assignment status changes
CREATE OR REPLACE FUNCTION public.trg_notify_on_assignment_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_job_title TEXT;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    SELECT title INTO v_job_title FROM public.jobs WHERE id = NEW.job_id;
    IF v_job_title IS NULL THEN v_job_title := 'Service Assignment'; END IF;

    -- Notify worker
    INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
    VALUES (
      NEW.worker_id,
      'assignment_status',
      'notif_assignment_status_title',
      'notif_assignment_status_body',
      jsonb_build_object(
        'assignment_id', NEW.id,
        'job_title', v_job_title,
        'booking_code', COALESCE(NEW.booking_code, 'BOOK'),
        'status', NEW.status
      )
    );

    -- Notify provider
    INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
    VALUES (
      NEW.provider_id,
      'assignment_status',
      'notif_assignment_status_title',
      'notif_assignment_status_body',
      jsonb_build_object(
        'assignment_id', NEW.id,
        'job_title', v_job_title,
        'booking_code', COALESCE(NEW.booking_code, 'BOOK'),
        'status', NEW.status
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_job_assignments_notify ON public.job_assignments;
CREATE TRIGGER trg_job_assignments_notify
  AFTER UPDATE OF status ON public.job_assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_notify_on_assignment_status();

-- 5. Trigger: Orders status updates
CREATE OR REPLACE FUNCTION public.trg_notify_on_order_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Notify farmer of new order
    INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
    VALUES (
      NEW.farmer_id,
      'order_update',
      'notif_new_order_title',
      'notif_new_order_body',
      jsonb_build_object(
        'order_id', NEW.id,
        'order_code', COALESCE(NEW.order_code, 'ORD'),
        'total_paise', NEW.total_paise
      )
    );
  ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    -- Notify customer of order progress
    INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
    VALUES (
      NEW.customer_id,
      'order_update',
      'notif_order_status_title',
      'notif_order_status_body',
      jsonb_build_object(
        'order_id', NEW.id,
        'order_code', COALESCE(NEW.order_code, 'ORD'),
        'status', NEW.status
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_orders_notify ON public.orders;
CREATE TRIGGER trg_orders_notify
  AFTER INSERT OR UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_notify_on_order_status();

-- 6. Trigger: Escrow & payments
CREATE OR REPLACE FUNCTION public.trg_notify_on_payment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.notifications (user_id, type, title_key, body_key, params)
    VALUES (
      NEW.user_id,
      'payment_update',
      'notif_payment_received_title',
      'notif_payment_received_body',
      jsonb_build_object(
        'payment_id', NEW.id,
        'amount_paise', NEW.amount_paise,
        'status', NEW.status
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payments_notify ON public.payments;
CREATE TRIGGER trg_payments_notify
  AFTER INSERT ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_notify_on_payment();

-- 7. Grant execute permissions on RPCs
GRANT EXECUTE ON FUNCTION public.register_device_token(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_device_token(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_notification_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_unread_notification_count() TO authenticated;
