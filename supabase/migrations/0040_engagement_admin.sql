-- Migration: 0040_engagement_admin.sql
-- Description: Communication, gamification, rewards, community, learning, finance goals, mandi prices,
--              ad banners, admin settings with default seeds, admin logs, audit logging trigger, views,
--              and Realtime publication enablement for specified tables.

-- 1. Custom Enums
CREATE TYPE public.community_post_kind AS ENUM ('story', 'recognition', 'announcement');
CREATE TYPE public.training_event_kind AS ENUM ('safety_onboarding', 'workshop', 'camp', 'meetup');
CREATE TYPE public.event_registration_status AS ENUM ('registered', 'attended', 'document_review', 'approved', 'rejected');
CREATE TYPE public.reward_redemption_status AS ENUM ('requested', 'approved', 'shipped', 'delivered');
CREATE TYPE public.credential_source AS ENUM ('module', 'uploaded_certificate');

-- ============================================================================
-- COMMUNICATION TABLES
-- ============================================================================

-- 2. Table: notifications
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title_key TEXT NOT NULL,
  body_key TEXT NOT NULL,
  params JSONB,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Table: device_tokens
CREATE TABLE public.device_tokens (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Table: chat_threads
CREATE TABLE public.chat_threads (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  context_type TEXT NOT NULL,
  context_id UUID NOT NULL,
  participant_a UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  participant_b UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_chat_thread_participants UNIQUE (participant_a, participant_b, context_type, context_id)
);

-- 5. Table: chat_messages
CREATE TABLE public.chat_messages (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES public.chat_threads(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  attachment_path TEXT,
  was_masked BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- GAMIFICATION & REWARDS TABLES
-- ============================================================================

-- 6. Table: xp_events
CREATE TABLE public.xp_events (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,
  points INT NOT NULL CHECK (points > 0),
  ref_type TEXT,
  ref_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Table: levels
CREATE TABLE public.levels (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  level_number INT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  min_xp INT UNIQUE NOT NULL CHECK (min_xp >= 0),
  perks JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Table: badges
CREATE TABLE public.badges (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  names JSONB NOT NULL,
  criteria JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Table: user_badges
CREATE TABLE public.user_badges (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
  awarded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, badge_id)
);

-- 10. Table: streaks
CREATE TABLE public.streaks (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  kind TEXT NOT NULL DEFAULT 'daily_activity',
  current INT NOT NULL DEFAULT 0 CHECK (current >= 0),
  best INT NOT NULL DEFAULT 0 CHECK (best >= 0),
  last_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_user_streak_kind UNIQUE (user_id, kind)
);

-- 11. Table: referral_codes
CREATE TABLE public.referral_codes (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  code TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. Table: referrals
CREATE TABLE public.referrals (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  referrer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  referred_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending',
  reward_given BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. Table: reward_items
CREATE TABLE public.reward_items (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  names JSONB NOT NULL,
  points_cost INT NOT NULL CHECK (points_cost >= 0),
  min_level INT NOT NULL DEFAULT 1,
  required_badge_id UUID REFERENCES public.badges(id) ON DELETE SET NULL,
  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  image TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 14. Table: reward_redemptions
CREATE TABLE public.reward_redemptions (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.reward_items(id) ON DELETE CASCADE,
  points_spent INT NOT NULL CHECK (points_spent >= 0),
  status public.reward_redemption_status NOT NULL DEFAULT 'requested',
  shipping_address JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- COMMUNITY & LEARNING TABLES
-- ============================================================================

-- 15. Table: community_posts
CREATE TABLE public.community_posts (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  kind public.community_post_kind NOT NULL DEFAULT 'story',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  images TEXT[],
  published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 16. Table: training_events
CREATE TABLE public.training_events (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  kind public.training_event_kind NOT NULL DEFAULT 'workshop',
  title TEXT NOT NULL,
  description TEXT,
  starts_at TIMESTAMPTZ NOT NULL,
  venue TEXT NOT NULL,
  location extensions.geography(Point, 4326),
  capacity INT CHECK (capacity > 0),
  language TEXT NOT NULL DEFAULT 'en',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 17. Table: event_registrations
CREATE TABLE public.event_registrations (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.training_events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status public.event_registration_status NOT NULL DEFAULT 'registered',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_event_registration UNIQUE (event_id, user_id)
);

-- 18. Table: learning_modules
CREATE TABLE public.learning_modules (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  titles JSONB NOT NULL,
  category TEXT NOT NULL,
  content JSONB NOT NULL,
  quiz JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 19. Table: learning_progress
CREATE TABLE public.learning_progress (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  module_id UUID NOT NULL REFERENCES public.learning_modules(id) ON DELETE CASCADE,
  score INT CHECK (score >= 0 AND score <= 100),
  completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_user_learning_module UNIQUE (user_id, module_id)
);

-- 20. Table: credentials
CREATE TABLE public.credentials (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,
  source_type public.credential_source NOT NULL,
  module_id UUID REFERENCES public.learning_modules(id) ON DELETE SET NULL,
  certificate_path TEXT,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- FINANCE & FARM DATA TABLES
-- ============================================================================

-- 21. Table: savings_goals
CREATE TABLE public.savings_goals (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  target_paise BIGINT NOT NULL CHECK (target_paise > 0),
  saved_paise BIGINT NOT NULL DEFAULT 0 CHECK (saved_paise >= 0),
  deadline DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 22. Table: wage_benchmarks
CREATE TABLE public.wage_benchmarks (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  category_id UUID REFERENCES public.service_categories(id) ON DELETE CASCADE,
  area TEXT NOT NULL,
  min_paise BIGINT NOT NULL CHECK (min_paise >= 0),
  max_paise BIGINT NOT NULL CHECK (max_paise >= min_paise),
  unit TEXT NOT NULL DEFAULT 'daily',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 23. Table: mandi_prices
CREATE TABLE public.mandi_prices (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  crop TEXT NOT NULL,
  variety TEXT NOT NULL DEFAULT 'standard',
  market TEXT NOT NULL,
  state TEXT NOT NULL,
  min_paise BIGINT CHECK (min_paise >= 0),
  modal_paise BIGINT CHECK (modal_paise >= 0),
  max_paise BIGINT CHECK (max_paise >= 0),
  price_date DATE NOT NULL,
  source TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_mandi_crop_market_date UNIQUE (crop, market, price_date)
);

-- ============================================================================
-- CONTENT & ADMIN TABLES
-- ============================================================================

-- 24. Table: ad_banners
CREATE TABLE public.ad_banners (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT,
  cta_label TEXT,
  image TEXT,
  target_role public.app_role,
  sponsor_name TEXT,
  why_text TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 25. Table: admin_settings
CREATE TABLE public.admin_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed admin_settings with defaults
INSERT INTO public.admin_settings (key, value) VALUES
  ('face_required_at_login', 'false'::jsonb),
  ('default_geofence_m', '150'::jsonb),
  ('commission_bps', '500'::jsonb),
  ('midjob_check_value_paise', '200000'::jsonb),
  ('fair_wage_guidance', 'true'::jsonb),
  ('no_show_grace_minutes', '15'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 26. Table: admin_logs
CREATE TABLE public.admin_logs (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 27. Table: audit_log
CREATE TABLE public.audit_log (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  table_name TEXT NOT NULL,
  row_id UUID NOT NULL,
  changed_by UUID,
  diff JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 28. Generic Audit Logger Trigger Function
CREATE OR REPLACE FUNCTION public.generic_audit_logger()
RETURNS TRIGGER AS $$
DECLARE
  v_changed_by UUID;
  v_row_id UUID;
  v_diff JSONB;
BEGIN
  BEGIN
    v_changed_by := auth.uid();
  EXCEPTION WHEN OTHERS THEN
    v_changed_by := NULL;
  END;

  IF (TG_OP = 'DELETE') THEN
    v_row_id := OLD.id;
    v_diff := jsonb_build_object('action', 'DELETE', 'old', to_jsonb(OLD));
  ELSIF (TG_OP = 'UPDATE') THEN
    v_row_id := NEW.id;
    v_diff := jsonb_build_object('action', 'UPDATE', 'old', to_jsonb(OLD), 'new', to_jsonb(NEW));
  ELSIF (TG_OP = 'INSERT') THEN
    v_row_id := NEW.id;
    v_diff := jsonb_build_object('action', 'INSERT', 'new', to_jsonb(NEW));
  END IF;

  INSERT INTO public.audit_log (table_name, row_id, changed_by, diff)
  VALUES (TG_TABLE_NAME, v_row_id, v_changed_by, v_diff);

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach Audit Triggers to required sensitive tables
CREATE TRIGGER trg_audit_kyc_records
  AFTER INSERT OR UPDATE OR DELETE ON public.kyc_records
  FOR EACH ROW EXECUTE FUNCTION public.generic_audit_logger();

CREATE TRIGGER trg_audit_disputes
  AFTER INSERT OR UPDATE OR DELETE ON public.disputes
  FOR EACH ROW EXECUTE FUNCTION public.generic_audit_logger();

CREATE TRIGGER trg_audit_payments
  AFTER INSERT OR UPDATE OR DELETE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.generic_audit_logger();

CREATE TRIGGER trg_audit_job_assignments
  AFTER INSERT OR UPDATE OR DELETE ON public.job_assignments
  FOR EACH ROW EXECUTE FUNCTION public.generic_audit_logger();

-- For admin_settings (which uses text PRIMARY KEY 'key')
CREATE OR REPLACE FUNCTION public.admin_settings_audit_logger()
RETURNS TRIGGER AS $$
DECLARE
  v_changed_by UUID;
  v_diff JSONB;
BEGIN
  BEGIN
    v_changed_by := auth.uid();
  EXCEPTION WHEN OTHERS THEN
    v_changed_by := NULL;
  END;

  IF (TG_OP = 'UPDATE') THEN
    v_diff := jsonb_build_object('key', NEW.key, 'action', 'UPDATE', 'old', to_jsonb(OLD), 'new', to_jsonb(NEW));
  ELSIF (TG_OP = 'INSERT') THEN
    v_diff := jsonb_build_object('key', NEW.key, 'action', 'INSERT', 'new', to_jsonb(NEW));
  ELSIF (TG_OP = 'DELETE') THEN
    v_diff := jsonb_build_object('key', OLD.key, 'action', 'DELETE', 'old', to_jsonb(OLD));
  END IF;

  INSERT INTO public.audit_log (table_name, row_id, changed_by, diff)
  VALUES ('admin_settings', extensions.gen_random_uuid(), v_changed_by, v_diff);

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_audit_admin_settings
  AFTER INSERT OR UPDATE OR DELETE ON public.admin_settings
  FOR EACH ROW EXECUTE FUNCTION public.admin_settings_audit_logger();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- 29. View: locality_trust_index
CREATE OR REPLACE VIEW public.locality_trust_index AS
SELECT
  p.pincode,
  COUNT(DISTINCT p.id) AS total_users,
  COALESCE(AVG(rr.stars), 0.00) AS avg_rating,
  COALESCE(
    COUNT(DISTINCT CASE WHEN kr.status = 'verified' THEN p.id END)::FLOAT / NULLIF(COUNT(DISTINCT p.id), 0),
    0.00
  ) AS verification_rate,
  COALESCE(
    COUNT(DISTINCT d.id)::FLOAT / NULLIF(COUNT(DISTINCT ja.id), 0),
    0.00
  ) AS dispute_rate,
  COALESCE(
    COUNT(DISTINCT CASE WHEN ja.arrived_at IS NOT NULL AND ja.arrived_at <= j.start_at THEN ja.id END)::FLOAT / NULLIF(COUNT(DISTINCT ja.id), 0),
    0.00
  ) AS on_time_rate
FROM public.profiles p
LEFT JOIN public.ratings_reviews rr ON p.id = rr.target_id
LEFT JOIN public.kyc_records kr ON p.id = kr.user_id
LEFT JOIN public.job_assignments ja ON p.id = ja.worker_id
LEFT JOIN public.jobs j ON ja.job_id = j.id
LEFT JOIN public.disputes d ON ja.id = d.ref_id AND d.ref_type = 'assignment'
WHERE p.pincode IS NOT NULL
GROUP BY p.pincode;

-- 30. View: admin_kpis
CREATE OR REPLACE VIEW public.admin_kpis AS
SELECT
  (SELECT COUNT(*) FROM public.profiles) AS total_users,
  (SELECT COUNT(*) FROM public.profiles WHERE onboarding_complete = true) AS onboarded_users,
  (SELECT COUNT(*) FROM public.worker_profiles WHERE is_verified_badge = true) AS verified_workers,
  (SELECT COUNT(*) FROM public.jobs) AS total_jobs,
  (SELECT COUNT(*) FROM public.job_assignments WHERE status = 'completed') AS completed_assignments,
  (SELECT COALESCE(SUM(amount_paise), 0) FROM public.payments WHERE status = 'captured') AS total_payment_volume_paise,
  (SELECT COUNT(*) FROM public.disputes WHERE status = 'open' OR status = 'in_review') AS active_disputes,
  (SELECT COUNT(*) FROM public.sos_incidents WHERE status = 'active') AS active_sos_incidents;

-- ============================================================================
-- ENABLE RLS ON ALL NEW TABLES (No policies yet - P1.5)
-- ============================================================================

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wage_benchmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mandi_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_notifications_user ON public.notifications (user_id, read_at);
CREATE INDEX idx_device_tokens_user ON public.device_tokens (user_id);
CREATE INDEX idx_chat_threads_user_a ON public.chat_threads (participant_a);
CREATE INDEX idx_chat_threads_user_b ON public.chat_threads (participant_b);
CREATE INDEX idx_chat_messages_thread ON public.chat_messages (thread_id, created_at);
CREATE INDEX idx_xp_events_user ON public.xp_events (user_id);
CREATE INDEX idx_mandi_prices_crop_date ON public.mandi_prices (crop, price_date);
CREATE INDEX idx_training_events_date ON public.training_events (starts_at);
CREATE INDEX idx_audit_log_table_row ON public.audit_log (table_name, row_id);

-- ============================================================================
-- TRIGGERS FOR updated_at
-- ============================================================================

CREATE TRIGGER trg_device_tokens_updated_at BEFORE UPDATE ON public.device_tokens FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_streaks_updated_at BEFORE UPDATE ON public.streaks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_reward_redemptions_updated_at BEFORE UPDATE ON public.reward_redemptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_event_registrations_updated_at BEFORE UPDATE ON public.event_registrations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- ENABLE REALTIME PUBLICATION FOR SPECIFIED TABLES
-- ============================================================================

-- Realtime publication enabled for: chat_messages, notifications, job_assignments, orders, assignment_events
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE
      public.chat_messages,
      public.notifications,
      public.job_assignments,
      public.orders,
      public.assignment_events;
  END IF;
END $$;

-- ============================================================================
-- TABLE COMMENTS
-- ============================================================================

COMMENT ON TABLE public.notifications IS 'In-app user push notification log.';
COMMENT ON TABLE public.device_tokens IS 'FCM / APNs push notification device tokens.';
COMMENT ON TABLE public.chat_threads IS 'Secure 1-to-1 masked chat thread context.';
COMMENT ON TABLE public.chat_messages IS 'Realtime chat messages between workers and providers.';
COMMENT ON TABLE public.xp_events IS 'XP points log for worker and farmer gamification.';
COMMENT ON TABLE public.reward_items IS 'Redeemable rewards store catalog.';
COMMENT ON TABLE public.mandi_prices IS 'Daily APMC mandi prices for crops and agricultural produce.';
COMMENT ON TABLE public.admin_settings IS 'Global platform administration configuration key-value pairs.';
COMMENT ON TABLE public.audit_log IS 'Generic audit change log for sensitive tables.';
COMMENT ON VIEW public.locality_trust_index IS 'Trust & safety index aggregated by postal pincode.';
COMMENT ON VIEW public.admin_kpis IS 'High-level real-time platform performance KPIs.';
