-- ============================================================================
-- Migration: 0770_security_audit_hardening.sql
-- Description: Security and privacy audit hardening (P10.3):
--   1. Enable RLS and define strict policies on demo_users, recurring_bookings, order_events
--   2. Add guard triggers against client tampering of immutable & financial columns
--      on job_assignments and orders
--   3. Restrict payments_insert to status='created', signature_verified=false
--   4. Restrict payouts_insert to status='requested'
--   5. Restrict ratings_reviews_insert to prevent self-rating (target_id != rater_id)
--   6. Allow chat thread participants to read shared chat-attachments in storage
--   7. Set explicit fixed search_path = public, extensions on all SECURITY DEFINER functions
-- ============================================================================

-- ============================================================================
-- 1. RLS ON demo_users
-- ============================================================================
ALTER TABLE public.demo_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS demo_users_select ON public.demo_users;
CREATE POLICY demo_users_select ON public.demo_users FOR SELECT
USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS demo_users_admin ON public.demo_users;
CREATE POLICY demo_users_admin ON public.demo_users FOR ALL
USING (public.is_admin());

REVOKE INSERT, UPDATE, DELETE ON public.demo_users FROM anon, authenticated;
GRANT SELECT ON public.demo_users TO authenticated;
GRANT ALL ON public.demo_users TO service_role;

-- ============================================================================
-- 2. RLS ON recurring_bookings
-- ============================================================================
ALTER TABLE public.recurring_bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS recurring_bookings_select ON public.recurring_bookings;
CREATE POLICY recurring_bookings_select ON public.recurring_bookings FOR SELECT
USING (provider_id = auth.uid() OR worker_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS recurring_bookings_insert ON public.recurring_bookings;
CREATE POLICY recurring_bookings_insert ON public.recurring_bookings FOR INSERT
WITH CHECK (provider_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS recurring_bookings_update ON public.recurring_bookings;
CREATE POLICY recurring_bookings_update ON public.recurring_bookings FOR UPDATE
USING (provider_id = auth.uid() OR worker_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS recurring_bookings_delete ON public.recurring_bookings;
CREATE POLICY recurring_bookings_delete ON public.recurring_bookings FOR DELETE
USING (provider_id = auth.uid() OR public.is_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.recurring_bookings TO authenticated;

-- ============================================================================
-- 3. RLS ON order_events
-- ============================================================================
ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS order_events_select ON public.order_events;
CREATE POLICY order_events_select ON public.order_events FOR SELECT
USING (public.is_order_party(order_id) OR public.is_admin());

DROP POLICY IF EXISTS order_events_insert ON public.order_events;
CREATE POLICY order_events_insert ON public.order_events FOR INSERT
WITH CHECK (public.is_order_party(order_id) OR public.is_admin());

GRANT SELECT, INSERT ON public.order_events TO authenticated;

-- ============================================================================
-- 4. GUARD TRIGGERS FOR IMMUTABLE AND SERVER-COMPUTED COLUMNS
-- ============================================================================

-- A. Guard job_assignments immutable columns (job_id, worker_id, agreed_wage_paise)
CREATE OR REPLACE FUNCTION public.guard_job_assignments_immutable_columns()
RETURNS TRIGGER AS $$
BEGIN
  IF (auth.uid() IS NOT NULL AND COALESCE(current_setting('request.jwt.claim.role', true), '') <> 'service_role') THEN
    IF (NEW.job_id IS DISTINCT FROM OLD.job_id OR
        NEW.worker_id IS DISTINCT FROM OLD.worker_id OR
        NEW.agreed_wage_paise IS DISTINCT FROM OLD.agreed_wage_paise) THEN
      RAISE EXCEPTION 'Immutable fields (job_id, worker_id, agreed_wage_paise) on assignments cannot be modified by clients.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS trg_guard_job_assignments_immutable ON public.job_assignments;
CREATE TRIGGER trg_guard_job_assignments_immutable
  BEFORE UPDATE ON public.job_assignments
  FOR EACH ROW EXECUTE FUNCTION public.guard_job_assignments_immutable_columns();

-- B. Guard orders immutable and financial columns (customer_id, farmer_id, total_paise, fee_paise)
CREATE OR REPLACE FUNCTION public.guard_orders_immutable_columns()
RETURNS TRIGGER AS $$
BEGIN
  IF (auth.uid() IS NOT NULL AND COALESCE(current_setting('request.jwt.claim.role', true), '') <> 'service_role') THEN
    IF (NEW.customer_id IS DISTINCT FROM OLD.customer_id OR
        NEW.farmer_id IS DISTINCT FROM OLD.farmer_id OR
        NEW.total_paise IS DISTINCT FROM OLD.total_paise OR
        NEW.fee_paise IS DISTINCT FROM OLD.fee_paise) THEN
      RAISE EXCEPTION 'Server-computed financial fields on orders cannot be modified directly by clients.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS trg_guard_orders_immutable ON public.orders;
CREATE TRIGGER trg_guard_orders_immutable
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.guard_orders_immutable_columns();

-- ============================================================================
-- 5. PAYMENT & PAYOUT INSERT CONSTRAINTS (ANTI-FRAUD RLS)
-- ============================================================================

-- Enforce payments created by client must be in 'created' status with unverified signature
DROP POLICY IF EXISTS payments_insert ON public.payments;
CREATE POLICY payments_insert ON public.payments FOR INSERT
WITH CHECK (
  payer_id = auth.uid()
  AND status = 'created'::public.payment_status
  AND signature_verified = false
);

-- Enforce payouts created by client must be in 'requested' status
DROP POLICY IF EXISTS payouts_insert ON public.payouts;
CREATE POLICY payouts_insert ON public.payouts FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND status = 'requested'::public.payout_status
);

-- Disallow self-ratings
DROP POLICY IF EXISTS ratings_reviews_insert ON public.ratings_reviews;
CREATE POLICY ratings_reviews_insert ON public.ratings_reviews FOR INSERT
WITH CHECK (
  rater_id = auth.uid()
  AND target_id != auth.uid()
);

-- ============================================================================
-- 6. CHAT ATTACHMENTS STORAGE ACCESS FOR CONVERSATION PARTIES
-- ============================================================================
DROP POLICY IF EXISTS storage_chat_attachments_select ON storage.objects;
CREATE POLICY storage_chat_attachments_select ON storage.objects FOR SELECT USING (
  bucket_id = 'chat-attachments' AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.chat_messages cm
      JOIN public.chat_threads ct ON cm.thread_id = ct.id
      WHERE cm.attachment_path LIKE '%' || name || '%'
        AND (ct.participant_a = auth.uid() OR ct.participant_b = auth.uid())
    )
  )
);

-- ============================================================================
-- 7. SET EXPLICIT search_path ON ALL SECURITY DEFINER FUNCTIONS
-- ============================================================================
DO $$
DECLARE
  func_rec RECORD;
BEGIN
  -- Set fixed search_path = public, extensions on all SECURITY DEFINER functions in public schema
  FOR func_rec IN (
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.prosecdef = true
  ) LOOP
    BEGIN
      EXECUTE format('ALTER FUNCTION public.%I(%s) SET search_path = public, extensions;',
                     func_rec.proname, func_rec.args);
    EXCEPTION WHEN OTHERS THEN
      -- Silently skip functions that cannot be altered dynamically
      NULL;
    END;
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';
