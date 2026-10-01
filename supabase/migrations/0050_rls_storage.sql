-- Migration: 0050_rls_storage.sql
-- Description: Helper functions, public_profiles view, computed column guard triggers, RLS policies on all tables,
--              storage bucket creation, and storage RLS policies.

-- ============================================================================
-- 1. STABLE SECURITY DEFINER HELPER FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.has_role(p_role public.app_role)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = p_role
  ) OR EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND active_role = p_role
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = 'admin'::public.app_role
  ) OR EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND active_role = 'admin'::public.app_role
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_assignment_party(p_assignment_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.job_assignments ja
    JOIN public.jobs j ON ja.job_id = j.id
    WHERE ja.id = p_assignment_id
      AND (ja.worker_id = auth.uid() OR j.provider_id = auth.uid())
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_order_party(p_order_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id = p_order_id
      AND (o.customer_id = auth.uid() OR o.farmer_id = auth.uid())
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_thread_member(p_thread_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.chat_threads ct
    WHERE ct.id = p_thread_id
      AND (ct.participant_a = auth.uid() OR ct.participant_b = auth.uid())
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 2. PUBLIC PROFILE VIEW
-- ============================================================================

CREATE OR REPLACE VIEW public.public_profiles AS
SELECT
  p.id,
  p.full_name,
  p.avatar_path,
  p.active_role,
  p.city,
  p.state,
  p.pincode,
  p.language,
  COALESCE(wp.rating_avg, 0.00) AS rating_avg,
  COALESCE(wp.rating_count, 0) AS rating_count,
  COALESCE(wp.jobs_completed, 0) AS jobs_completed,
  COALESCE(wp.is_verified_badge, false) AS is_verified_badge
FROM public.profiles p
LEFT JOIN public.worker_profiles wp ON p.id = wp.user_id;

GRANT SELECT ON public.public_profiles TO authenticated, anon;

-- ============================================================================
-- 3. SERVER-COMPUTED COLUMN GUARD TRIGGERS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.guard_worker_profile_computed_columns()
RETURNS TRIGGER AS $$
BEGIN
  IF (auth.uid() IS NOT NULL AND COALESCE(current_setting('request.jwt.claim.role', true), '') <> 'service_role') THEN
    IF (NEW.rating_avg IS DISTINCT FROM OLD.rating_avg OR
        NEW.rating_count IS DISTINCT FROM OLD.rating_count OR
        NEW.jobs_completed IS DISTINCT FROM OLD.jobs_completed OR
        NEW.is_verified_badge IS DISTINCT FROM OLD.is_verified_badge) THEN
      RAISE EXCEPTION 'Server-computed fields (rating_avg, rating_count, jobs_completed, is_verified_badge) cannot be modified by clients.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_guard_worker_profile_computed
  BEFORE UPDATE ON public.worker_profiles
  FOR EACH ROW EXECUTE FUNCTION public.guard_worker_profile_computed_columns();

CREATE OR REPLACE FUNCTION public.guard_provider_profile_computed_columns()
RETURNS TRIGGER AS $$
BEGIN
  IF (auth.uid() IS NOT NULL AND COALESCE(current_setting('request.jwt.claim.role', true), '') <> 'service_role') THEN
    IF (NEW.rating_avg IS DISTINCT FROM OLD.rating_avg OR
        NEW.rating_count IS DISTINCT FROM OLD.rating_count) THEN
      RAISE EXCEPTION 'Server-computed fields (rating_avg, rating_count) cannot be modified by clients.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_guard_provider_profile_computed
  BEFORE UPDATE ON public.provider_profiles
  FOR EACH ROW EXECUTE FUNCTION public.guard_provider_profile_computed_columns();

CREATE OR REPLACE FUNCTION public.guard_farmer_profile_computed_columns()
RETURNS TRIGGER AS $$
BEGIN
  IF (auth.uid() IS NOT NULL AND COALESCE(current_setting('request.jwt.claim.role', true), '') <> 'service_role') THEN
    IF (NEW.rating_avg IS DISTINCT FROM OLD.rating_avg OR
        NEW.rating_count IS DISTINCT FROM OLD.rating_count) THEN
      RAISE EXCEPTION 'Server-computed fields (rating_avg, rating_count) cannot be modified by clients.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_guard_farmer_profile_computed
  BEFORE UPDATE ON public.farmer_profiles
  FOR EACH ROW EXECUTE FUNCTION public.guard_farmer_profile_computed_columns();

-- ============================================================================
-- 4. GRANT SCHEMA & TABLE PRIVILEGES TO authenticated AND anon
-- ============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Default grants for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon;

-- ============================================================================
-- 5. ROW LEVEL SECURITY POLICIES FOR TABLES
-- ============================================================================

-- PROFILES
CREATE POLICY profiles_select ON public.profiles FOR SELECT USING (id = auth.uid() OR public.is_admin());
CREATE POLICY profiles_insert ON public.profiles FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY profiles_update ON public.profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY profiles_delete ON public.profiles FOR DELETE USING (public.is_admin());

-- USER ROLES
CREATE POLICY user_roles_select ON public.user_roles FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY user_roles_insert ON public.user_roles FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY user_roles_update ON public.user_roles FOR UPDATE USING (public.is_admin());
CREATE POLICY user_roles_delete ON public.user_roles FOR DELETE USING (public.is_admin());

-- WORKER PROFILES
CREATE POLICY worker_profiles_select ON public.worker_profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY worker_profiles_insert ON public.worker_profiles FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY worker_profiles_update ON public.worker_profiles FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY worker_profiles_delete ON public.worker_profiles FOR DELETE USING (user_id = auth.uid() OR public.is_admin());

-- WORKER SKILLS
CREATE POLICY worker_skills_select ON public.worker_skills FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY worker_skills_insert ON public.worker_skills FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY worker_skills_update ON public.worker_skills FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY worker_skills_delete ON public.worker_skills FOR DELETE USING (user_id = auth.uid());

-- PROVIDER PROFILES
CREATE POLICY provider_profiles_select ON public.provider_profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY provider_profiles_insert ON public.provider_profiles FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY provider_profiles_update ON public.provider_profiles FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY provider_profiles_delete ON public.provider_profiles FOR DELETE USING (user_id = auth.uid() OR public.is_admin());

-- FARMER PROFILES
CREATE POLICY farmer_profiles_select ON public.farmer_profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY farmer_profiles_insert ON public.farmer_profiles FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY farmer_profiles_update ON public.farmer_profiles FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY farmer_profiles_delete ON public.farmer_profiles FOR DELETE USING (user_id = auth.uid() OR public.is_admin());

-- ADDRESSES
CREATE POLICY addresses_select ON public.addresses FOR SELECT USING (user_id = auth.uid());
CREATE POLICY addresses_insert ON public.addresses FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY addresses_update ON public.addresses FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY addresses_delete ON public.addresses FOR DELETE USING (user_id = auth.uid());

-- SERVICE CATEGORIES & SKILLS
CREATE POLICY service_categories_select ON public.service_categories FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY service_categories_insert ON public.service_categories FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY service_categories_update ON public.service_categories FOR UPDATE USING (public.is_admin());
CREATE POLICY service_categories_delete ON public.service_categories FOR DELETE USING (public.is_admin());

CREATE POLICY skills_select ON public.skills FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY skills_insert ON public.skills FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY skills_update ON public.skills FOR UPDATE USING (public.is_admin());
CREATE POLICY skills_delete ON public.skills FOR DELETE USING (public.is_admin());

-- JOBS
CREATE POLICY jobs_select ON public.jobs FOR SELECT USING (status IN ('open', 'filled', 'closed') OR provider_id = auth.uid() OR public.is_admin());
CREATE POLICY jobs_insert ON public.jobs FOR INSERT WITH CHECK (provider_id = auth.uid());
CREATE POLICY jobs_update ON public.jobs FOR UPDATE USING (provider_id = auth.uid());
CREATE POLICY jobs_delete ON public.jobs FOR DELETE USING (provider_id = auth.uid());

-- JOB APPLICATIONS
CREATE POLICY job_applications_select ON public.job_applications FOR SELECT USING (
  worker_id = auth.uid() OR EXISTS (SELECT 1 FROM public.jobs j WHERE j.id = job_id AND j.provider_id = auth.uid()) OR public.is_admin()
);
CREATE POLICY job_applications_insert ON public.job_applications FOR INSERT WITH CHECK (worker_id = auth.uid());
CREATE POLICY job_applications_update ON public.job_applications FOR UPDATE USING (
  worker_id = auth.uid() OR EXISTS (SELECT 1 FROM public.jobs j WHERE j.id = job_id AND j.provider_id = auth.uid())
);
CREATE POLICY job_applications_delete ON public.job_applications FOR DELETE USING (worker_id = auth.uid());

-- JOB ASSIGNMENTS
CREATE POLICY job_assignments_select ON public.job_assignments FOR SELECT USING (public.is_assignment_party(id) OR public.is_admin());
CREATE POLICY job_assignments_insert ON public.job_assignments FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.jobs j WHERE j.id = job_id AND j.provider_id = auth.uid())
);
CREATE POLICY job_assignments_update ON public.job_assignments FOR UPDATE USING (public.is_assignment_party(id) OR public.is_admin());

-- ASSIGNMENT EVENTS & ATTENDANCE LOGS
CREATE POLICY assignment_events_select ON public.assignment_events FOR SELECT USING (public.is_assignment_party(assignment_id) OR public.is_admin());
CREATE POLICY assignment_events_insert ON public.assignment_events FOR INSERT WITH CHECK (public.is_assignment_party(assignment_id));

CREATE POLICY attendance_logs_select ON public.attendance_logs FOR SELECT USING (public.is_assignment_party(assignment_id) OR public.is_admin());
CREATE POLICY attendance_logs_insert ON public.attendance_logs FOR INSERT WITH CHECK (public.is_assignment_party(assignment_id));

-- JOB EVIDENCE
CREATE POLICY job_evidence_select ON public.job_evidence FOR SELECT USING (public.is_assignment_party(assignment_id) OR public.is_admin());
CREATE POLICY job_evidence_insert ON public.job_evidence FOR INSERT WITH CHECK (uploader = auth.uid() AND public.is_assignment_party(assignment_id));
CREATE POLICY job_evidence_delete ON public.job_evidence FOR DELETE USING (uploader = auth.uid());

-- PRODUCE & RESOURCE LISTINGS
CREATE POLICY produce_listings_select ON public.produce_listings FOR SELECT USING (status = 'active' OR farmer_id = auth.uid() OR public.is_admin());
CREATE POLICY produce_listings_insert ON public.produce_listings FOR INSERT WITH CHECK (farmer_id = auth.uid());
CREATE POLICY produce_listings_update ON public.produce_listings FOR UPDATE USING (farmer_id = auth.uid());
CREATE POLICY produce_listings_delete ON public.produce_listings FOR DELETE USING (farmer_id = auth.uid());

CREATE POLICY resource_listings_select ON public.resource_listings FOR SELECT USING (active = true OR owner_id = auth.uid() OR public.is_admin());
CREATE POLICY resource_listings_insert ON public.resource_listings FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY resource_listings_update ON public.resource_listings FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY resource_listings_delete ON public.resource_listings FOR DELETE USING (owner_id = auth.uid());

-- CARTS & CART ITEMS
CREATE POLICY carts_select ON public.carts FOR SELECT USING (user_id = auth.uid());
CREATE POLICY carts_insert ON public.carts FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY carts_update ON public.carts FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY carts_delete ON public.carts FOR DELETE USING (user_id = auth.uid());

CREATE POLICY cart_items_select ON public.cart_items FOR SELECT USING (EXISTS (SELECT 1 FROM public.carts c WHERE c.id = cart_id AND c.user_id = auth.uid()));
CREATE POLICY cart_items_insert ON public.cart_items FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.carts c WHERE c.id = cart_id AND c.user_id = auth.uid()));
CREATE POLICY cart_items_update ON public.cart_items FOR UPDATE USING (EXISTS (SELECT 1 FROM public.carts c WHERE c.id = cart_id AND c.user_id = auth.uid()));
CREATE POLICY cart_items_delete ON public.cart_items FOR DELETE USING (EXISTS (SELECT 1 FROM public.carts c WHERE c.id = cart_id AND c.user_id = auth.uid()));

-- ORDERS & ORDER ITEMS
CREATE POLICY orders_select ON public.orders FOR SELECT USING (public.is_order_party(id) OR public.is_admin());
CREATE POLICY orders_insert ON public.orders FOR INSERT WITH CHECK (customer_id = auth.uid());
CREATE POLICY orders_update ON public.orders FOR UPDATE USING (public.is_order_party(id) OR public.is_admin());

CREATE POLICY order_items_select ON public.order_items FOR SELECT USING (public.is_order_party(order_id) OR public.is_admin());
CREATE POLICY order_items_insert ON public.order_items FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND o.customer_id = auth.uid()));

-- GROUP ORDERS & SUBSCRIPTIONS
CREATE POLICY group_orders_select ON public.group_orders FOR SELECT USING (organizer_id = auth.uid() OR public.is_admin());
CREATE POLICY group_orders_insert ON public.group_orders FOR INSERT WITH CHECK (organizer_id = auth.uid());
CREATE POLICY group_orders_update ON public.group_orders FOR UPDATE USING (organizer_id = auth.uid());

CREATE POLICY group_order_members_select ON public.group_order_members FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY group_order_members_insert ON public.group_order_members FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY subscriptions_select ON public.subscriptions FOR SELECT USING (customer_id = auth.uid() OR public.is_admin());
CREATE POLICY subscriptions_insert ON public.subscriptions FOR INSERT WITH CHECK (customer_id = auth.uid());
CREATE POLICY subscriptions_update ON public.subscriptions FOR UPDATE USING (customer_id = auth.uid());

-- WALLETS, LEDGER & PAYOUTS
CREATE POLICY wallets_select ON public.wallets FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY ledger_entries_select ON public.ledger_entries FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.wallets w WHERE w.id = wallet_id AND w.user_id = auth.uid()) OR public.is_admin()
);

CREATE POLICY payments_select ON public.payments FOR SELECT USING (payer_id = auth.uid() OR payee_id = auth.uid() OR public.is_admin());
CREATE POLICY payments_insert ON public.payments FOR INSERT WITH CHECK (payer_id = auth.uid());

CREATE POLICY payouts_select ON public.payouts FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY payouts_insert ON public.payouts FOR INSERT WITH CHECK (user_id = auth.uid());

-- KYC, FACE & VERIFICATION
CREATE POLICY kyc_records_select ON public.kyc_records FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY face_profiles_select ON public.face_profiles FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY verification_attempts_select ON public.verification_attempts FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY fraud_flags_select ON public.fraud_flags FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

-- RATINGS & REVIEWS
CREATE POLICY ratings_reviews_select ON public.ratings_reviews FOR SELECT USING (hidden = false OR rater_id = auth.uid() OR target_id = auth.uid() OR public.is_admin());
CREATE POLICY ratings_reviews_insert ON public.ratings_reviews FOR INSERT WITH CHECK (rater_id = auth.uid());
CREATE POLICY ratings_reviews_update ON public.ratings_reviews FOR UPDATE USING (rater_id = auth.uid());
CREATE POLICY ratings_reviews_delete ON public.ratings_reviews FOR DELETE USING (rater_id = auth.uid() OR public.is_admin());

-- FAVOURITES
CREATE POLICY favourites_select ON public.favourites FOR SELECT USING (user_id = auth.uid());
CREATE POLICY favourites_insert ON public.favourites FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY favourites_delete ON public.favourites FOR DELETE USING (user_id = auth.uid());

-- DISPUTES & EVIDENCE
CREATE POLICY disputes_select ON public.disputes FOR SELECT USING (raised_by = auth.uid() OR against = auth.uid() OR public.is_admin());
CREATE POLICY disputes_insert ON public.disputes FOR INSERT WITH CHECK (raised_by = auth.uid());
CREATE POLICY disputes_update ON public.disputes FOR UPDATE USING (public.is_admin());

CREATE POLICY dispute_evidence_select ON public.dispute_evidence FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.disputes d WHERE d.id = dispute_id AND (d.raised_by = auth.uid() OR d.against = auth.uid())) OR public.is_admin()
);
CREATE POLICY dispute_evidence_insert ON public.dispute_evidence FOR INSERT WITH CHECK (uploader = auth.uid());

-- EMERGENCY CONTACTS & SAFETY
CREATE POLICY emergency_contacts_select ON public.emergency_contacts FOR SELECT USING (user_id = auth.uid());
CREATE POLICY emergency_contacts_insert ON public.emergency_contacts FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY emergency_contacts_update ON public.emergency_contacts FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY emergency_contacts_delete ON public.emergency_contacts FOR DELETE USING (user_id = auth.uid());

CREATE POLICY sos_incidents_select ON public.sos_incidents FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY sos_incidents_insert ON public.sos_incidents FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY protection_claims_select ON public.protection_claims FOR SELECT USING (claimant_id = auth.uid() OR public.is_admin());
CREATE POLICY protection_claims_insert ON public.protection_claims FOR INSERT WITH CHECK (claimant_id = auth.uid());

-- NOTIFICATIONS & DEVICES & CONSENT & SAVINGS
CREATE POLICY notifications_select ON public.notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY notifications_update ON public.notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY notifications_delete ON public.notifications FOR DELETE USING (user_id = auth.uid());

CREATE POLICY device_tokens_select ON public.device_tokens FOR SELECT USING (user_id = auth.uid());
CREATE POLICY device_tokens_insert ON public.device_tokens FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY device_tokens_update ON public.device_tokens FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY device_tokens_delete ON public.device_tokens FOR DELETE USING (user_id = auth.uid());

CREATE POLICY savings_goals_select ON public.savings_goals FOR SELECT USING (user_id = auth.uid());
CREATE POLICY savings_goals_insert ON public.savings_goals FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY savings_goals_update ON public.savings_goals FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY savings_goals_delete ON public.savings_goals FOR DELETE USING (user_id = auth.uid());

CREATE POLICY consent_logs_select ON public.consent_logs FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY consent_logs_insert ON public.consent_logs FOR INSERT WITH CHECK (user_id = auth.uid());

-- CHAT
CREATE POLICY chat_threads_select ON public.chat_threads FOR SELECT USING (participant_a = auth.uid() OR participant_b = auth.uid() OR public.is_admin());
CREATE POLICY chat_threads_insert ON public.chat_threads FOR INSERT WITH CHECK (participant_a = auth.uid() OR participant_b = auth.uid());

CREATE POLICY chat_messages_select ON public.chat_messages FOR SELECT USING (public.is_thread_member(thread_id) OR public.is_admin());
CREATE POLICY chat_messages_insert ON public.chat_messages FOR INSERT WITH CHECK (sender_id = auth.uid() AND public.is_thread_member(thread_id));
CREATE POLICY chat_messages_update ON public.chat_messages FOR UPDATE USING (public.is_thread_member(thread_id));

-- GAMIFICATION & REWARDS
CREATE POLICY xp_events_select ON public.xp_events FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY user_badges_select ON public.user_badges FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY streaks_select ON public.streaks FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY referral_codes_select ON public.referral_codes FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY referral_codes_insert ON public.referral_codes FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY referrals_select ON public.referrals FOR SELECT USING (referrer_id = auth.uid() OR referred_id = auth.uid() OR public.is_admin());

CREATE POLICY reward_redemptions_select ON public.reward_redemptions FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY reward_redemptions_insert ON public.reward_redemptions FOR INSERT WITH CHECK (user_id = auth.uid());

-- CATALOG & CONTENT (PUBLIC READ, ADMIN WRITE)
CREATE POLICY reward_items_select ON public.reward_items FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY reward_items_admin ON public.reward_items FOR ALL USING (public.is_admin());

CREATE POLICY badges_select ON public.badges FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY badges_admin ON public.badges FOR ALL USING (public.is_admin());

CREATE POLICY levels_select ON public.levels FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY levels_admin ON public.levels FOR ALL USING (public.is_admin());

CREATE POLICY learning_modules_select ON public.learning_modules FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY learning_modules_admin ON public.learning_modules FOR ALL USING (public.is_admin());

CREATE POLICY learning_progress_select ON public.learning_progress FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY learning_progress_insert ON public.learning_progress FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY learning_progress_update ON public.learning_progress FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY credentials_select ON public.credentials FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY training_events_select ON public.training_events FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY training_events_admin ON public.training_events FOR ALL USING (public.is_admin());

CREATE POLICY event_registrations_select ON public.event_registrations FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY event_registrations_insert ON public.event_registrations FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY community_posts_select ON public.community_posts FOR SELECT USING (published = true OR author_id = auth.uid() OR public.is_admin());
CREATE POLICY community_posts_insert ON public.community_posts FOR INSERT WITH CHECK (author_id = auth.uid());
CREATE POLICY community_posts_admin ON public.community_posts FOR ALL USING (public.is_admin());

CREATE POLICY wage_benchmarks_select ON public.wage_benchmarks FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY wage_benchmarks_admin ON public.wage_benchmarks FOR ALL USING (public.is_admin());

CREATE POLICY mandi_prices_select ON public.mandi_prices FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY mandi_prices_admin ON public.mandi_prices FOR ALL USING (public.is_admin());

CREATE POLICY ad_banners_select ON public.ad_banners FOR SELECT USING (active = true OR public.is_admin());
CREATE POLICY ad_banners_admin ON public.ad_banners FOR ALL USING (public.is_admin());

-- ADMIN TABLES
CREATE POLICY admin_settings_select ON public.admin_settings FOR SELECT USING (public.is_admin());
CREATE POLICY admin_settings_write ON public.admin_settings FOR ALL USING (public.is_admin());

CREATE POLICY admin_logs_select ON public.admin_logs FOR SELECT USING (public.is_admin());
CREATE POLICY admin_logs_write ON public.admin_logs FOR ALL USING (public.is_admin());

CREATE POLICY audit_log_select ON public.audit_log FOR SELECT USING (public.is_admin());
CREATE POLICY audit_log_write ON public.audit_log FOR ALL USING (public.is_admin());

-- ============================================================================
-- 6. STORAGE BUCKET CREATION & STORAGE RLS POLICIES
-- ============================================================================

-- Create Buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('produce-images', 'produce-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('listing-images', 'listing-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('community', 'community', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('kyc-docs', 'kyc-docs', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
  ('face-refs', 'face-refs', false, 5242880, ARRAY['image/jpeg', 'image/png']),
  ('job-evidence', 'job-evidence', false, 26214400, ARRAY['image/jpeg', 'image/png', 'video/mp4', 'audio/mpeg', 'audio/wav', 'audio/aac']),
  ('dispute-evidence', 'dispute-evidence', false, 26214400, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'audio/mpeg', 'audio/wav']),
  ('chat-attachments', 'chat-attachments', false, 15728640, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'audio/mpeg', 'audio/wav'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Storage buckets and policies created below

-- AVATARS POLICIES
CREATE POLICY storage_avatars_select ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY storage_avatars_owner_write ON storage.objects FOR ALL USING (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- PRODUCE IMAGES POLICIES
CREATE POLICY storage_produce_images_select ON storage.objects FOR SELECT USING (bucket_id = 'produce-images');
CREATE POLICY storage_produce_images_owner_write ON storage.objects FOR ALL USING (
  bucket_id = 'produce-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- LISTING IMAGES POLICIES (OWNER FOLDER ONLY - {user_id}/*)
CREATE POLICY storage_listing_images_select ON storage.objects FOR SELECT USING (bucket_id = 'listing-images');
CREATE POLICY storage_listing_images_owner_write ON storage.objects FOR ALL USING (
  bucket_id = 'listing-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- COMMUNITY POLICIES
CREATE POLICY storage_community_select ON storage.objects FOR SELECT USING (bucket_id = 'community');
CREATE POLICY storage_community_admin_write ON storage.objects FOR ALL USING (
  bucket_id = 'community' AND public.is_admin()
);

-- KYC DOCS POLICIES
CREATE POLICY storage_kyc_docs_select ON storage.objects FOR SELECT USING (
  bucket_id = 'kyc-docs' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.is_admin())
);
CREATE POLICY storage_kyc_docs_owner_write ON storage.objects FOR ALL USING (
  bucket_id = 'kyc-docs' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- FACE REFS POLICIES
CREATE POLICY storage_face_refs_select ON storage.objects FOR SELECT USING (
  bucket_id = 'face-refs' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.is_admin())
);
CREATE POLICY storage_face_refs_owner_write ON storage.objects FOR ALL USING (
  bucket_id = 'face-refs' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- JOB EVIDENCE POLICIES
CREATE POLICY storage_job_evidence_select ON storage.objects FOR SELECT USING (
  bucket_id = 'job-evidence' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.is_admin())
);
CREATE POLICY storage_job_evidence_owner_write ON storage.objects FOR ALL USING (
  bucket_id = 'job-evidence' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- DISPUTE EVIDENCE POLICIES
CREATE POLICY storage_dispute_evidence_select ON storage.objects FOR SELECT USING (
  bucket_id = 'dispute-evidence' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.is_admin())
);
CREATE POLICY storage_dispute_evidence_owner_write ON storage.objects FOR ALL USING (
  bucket_id = 'dispute-evidence' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- CHAT ATTACHMENTS POLICIES
CREATE POLICY storage_chat_attachments_select ON storage.objects FOR SELECT USING (
  bucket_id = 'chat-attachments' AND auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY storage_chat_attachments_owner_write ON storage.objects FOR ALL USING (
  bucket_id = 'chat-attachments' AND auth.uid()::text = (storage.foldername(name))[1]
);
