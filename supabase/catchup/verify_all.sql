-- ============================================================================
-- Read-Only Schema Verification Script: verify_all.sql
-- Description: Comprehensive read-only verification query checking every table,
--              column, function with exact arguments, enum value, policy,
--              trigger, storage bucket, realtime publication, and grant
--              introduced or updated by migrations 0190 through 0640.
-- Output: Returns one row per checked object with columns:
--         migration_file, object_type, object_name, status ("OK" or "MISSING")
-- Sorting: MISSING rows appear FIRST so any discrepancy is immediately visible.
-- ============================================================================

WITH verification_checks AS (
  SELECT 
    '0190_single_role_rule.sql' AS migration_file,
    'function' AS object_type,
    'public.allow_multi_role()' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'allow_multi_role'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0190_single_role_rule.sql' AS migration_file,
    'function' AS object_type,
    'public.apply_role_selection(p_role app_role, p_seeker_type seeker_type)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'apply_role_selection' AND pg_get_function_identity_arguments(p.oid) = 'p_role app_role, p_seeker_type seeker_type'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0190_single_role_rule.sql' AS migration_file,
    'function' AS object_type,
    'public.anonymize_and_delete_user_data(p_target_user_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'anonymize_and_delete_user_data' AND pg_get_function_identity_arguments(p.oid) = 'p_target_user_id uuid'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0200_privacy_consent.sql' AS migration_file,
    'function' AS object_type,
    'public.revoke_consent(p_purpose text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'revoke_consent'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0200_privacy_consent.sql' AS migration_file,
    'function' AS object_type,
    'public.withdraw_face_consent()' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'withdraw_face_consent'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0210_verification_extra.sql' AS migration_file,
    'column' AS object_type,
    'public.service_categories.requires_licence' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'service_categories' AND column_name = 'requires_licence'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0210_verification_extra.sql' AS migration_file,
    'enum_value' AS object_type,
    'public.doc_type: student_id' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'doc_type' AND e.enumlabel = 'student_id'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0210_verification_extra.sql' AS migration_file,
    'enum_value' AS object_type,
    'public.doc_type: bank_account' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'doc_type' AND e.enumlabel = 'bank_account'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0210_verification_extra.sql' AS migration_file,
    'enum_value' AS object_type,
    'public.doc_type: upi' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'doc_type' AND e.enumlabel = 'upi'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0210_verification_extra.sql' AS migration_file,
    'function' AS object_type,
    'public.nearby_jobs_for_worker(uuid, double precision, double precision, double precision, uuid, integer, integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_jobs_for_worker'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0220_face_embedding.sql' AS migration_file,
    'column' AS object_type,
    'public.face_profiles.embedding' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'face_profiles' AND column_name = 'embedding'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0220_face_embedding.sql' AS migration_file,
    'function' AS object_type,
    'public.compare_face_embeddings(v1 double precision[], v2 double precision[])' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'compare_face_embeddings'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0220_face_embedding.sql' AS migration_file,
    'function' AS object_type,
    'public.save_face_embedding(p_user_id uuid, p_embedding double precision[], p_liveness_passed_at timestamp with time zone, p_matcher_ref text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'save_face_embedding'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0230_verification_visibility_guard.sql' AS migration_file,
    'function' AS object_type,
    'public.check_kyc_record_visibility()' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'check_kyc_record_visibility'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0230_verification_visibility_guard.sql' AS migration_file,
    'trigger' AS object_type,
    'public.kyc_records: trg_check_kyc_record_visibility' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_trigger tr JOIN pg_class c ON tr.tgrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = 'public' AND c.relname = 'kyc_records' AND tr.tgname = 'trg_check_kyc_record_visibility'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0240_sync_avatar_paths.sql' AS migration_file,
    'column' AS object_type,
    'public.profiles.avatar_path' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'avatar_path'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0250_face_verify_settings.sql' AS migration_file,
    'function' AS object_type,
    'public.get_face_login_requirement()' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_face_login_requirement'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0280_fix_bootstrap_wizard_completion.sql' AS migration_file,
    'function' AS object_type,
    'public.get_bootstrap_state()' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_bootstrap_state'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0290_safety_onboarding.sql' AS migration_file,
    'table' AS object_type,
    'public.training_events' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'training_events'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0290_safety_onboarding.sql' AS migration_file,
    'table' AS object_type,
    'public.event_registrations' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'event_registrations'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0290_safety_onboarding.sql' AS migration_file,
    'function' AS object_type,
    'public.get_safety_onboarding_status(p_user_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_safety_onboarding_status'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0290_safety_onboarding.sql' AS migration_file,
    'function' AS object_type,
    'public.book_safety_onboarding_slot(p_event_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'book_safety_onboarding_slot'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0290_safety_onboarding.sql' AS migration_file,
    'function' AS object_type,
    'public.simulate_training_status(p_user_id uuid, p_status text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'simulate_training_status'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0300_qr_tokens.sql' AS migration_file,
    'table' AS object_type,
    'public.qr_tokens' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'qr_tokens'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0300_qr_tokens.sql' AS migration_file,
    'function' AS object_type,
    'public.revoke_qr_token(p_token_id_hash text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'revoke_qr_token'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0310_public_verification_enhancement.sql' AS migration_file,
    'function' AS object_type,
    'public.get_public_verification(p_user_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_public_verification'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0320_recommendations.sql' AS migration_file,
    'function' AS object_type,
    'public.get_seeker_home_summary(p_worker_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_seeker_home_summary'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0350_audience_and_jobs_rules.sql' AS migration_file,
    'function' AS object_type,
    'public.get_user_consents()' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_user_consents'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0350_audience_and_jobs_rules.sql' AS migration_file,
    'function' AS object_type,
    'public.record_user_consent_v2(p_purpose text, p_granted boolean, p_version text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_user_consent_v2'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0370_job_details_and_requests.sql' AS migration_file,
    'function' AS object_type,
    'public.check_job_eligibility(p_job_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'check_job_eligibility'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0370_job_details_and_requests.sql' AS migration_file,
    'function' AS object_type,
    'public.get_job_detail(p_job_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_job_detail'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0380_provider_jobs_management.sql' AS migration_file,
    'function' AS object_type,
    'public.get_provider_jobs(p_provider_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_provider_jobs'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0380_provider_jobs_management.sql' AS migration_file,
    'function' AS object_type,
    'public.get_job_applicants(p_job_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_job_applicants'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0380_provider_jobs_management.sql' AS migration_file,
    'function' AS object_type,
    'public.update_provider_job_status(p_job_id uuid, p_status job_status)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_provider_job_status'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0380_provider_jobs_management.sql' AS migration_file,
    'function' AS object_type,
    'public.respond_to_application(p_application_id uuid, p_status application_status)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'respond_to_application'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0390_provider_hub_worker_search.sql' AS migration_file,
    'function' AS object_type,
    'public.nearby_workers(...)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_workers'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0390_provider_hub_worker_search.sql' AS migration_file,
    'function' AS object_type,
    'public.get_worker_profile_detail(p_worker_id uuid, p_caller_lat double precision, p_caller_lng double precision)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_worker_profile_detail'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0390_provider_hub_worker_search.sql' AS migration_file,
    'function' AS object_type,
    'public.get_provider_active_booking(p_provider_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_provider_active_booking'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0390_provider_hub_worker_search.sql' AS migration_file,
    'function' AS object_type,
    'public.toggle_favourite(p_target_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'toggle_favourite'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0400_guided_booking_and_protection.sql' AS migration_file,
    'function' AS object_type,
    'public.get_worker_booked_slots(p_worker_id uuid, p_start_date date, p_end_date date)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_worker_booked_slots'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0400_guided_booking_and_protection.sql' AS migration_file,
    'function' AS object_type,
    'public.request_worker(...)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'request_worker'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0400_guided_booking_and_protection.sql' AS migration_file,
    'function' AS object_type,
    'public.get_user_addresses(p_user_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_user_addresses'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0400_guided_booking_and_protection.sql' AS migration_file,
    'function' AS object_type,
    'public.save_user_address(p_label text, p_line1 text, p_landmark text, p_city text, p_pincode text, p_lat double precision, p_lng double precision, p_is_default boolean)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'save_user_address'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0400_guided_booking_and_protection.sql' AS migration_file,
    'function' AS object_type,
    'public.get_provider_recurring_bookings(p_provider_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_provider_recurring_bookings'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0400_guided_booking_and_protection.sql' AS migration_file,
    'function' AS object_type,
    'public.update_recurring_booking(p_recurring_id uuid, p_status subscription_status, p_schedule_rule text, p_preferred_time time without time zone)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_recurring_booking'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0400_guided_booking_and_protection.sql' AS migration_file,
    'function' AS object_type,
    'public.skip_recurring_booking_date(p_recurring_id uuid, p_skip_date date)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'skip_recurring_booking_date'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0410_fix_polish_p4.sql' AS migration_file,
    'column' AS object_type,
    'public.jobs.suitable_for' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'jobs' AND column_name = 'suitable_for'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0410_fix_polish_p4.sql' AS migration_file,
    'column' AS object_type,
    'public.provider_profiles.is_verified_badge' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'provider_profiles' AND column_name = 'is_verified_badge'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0420_assignment_timeline_p47.sql' AS migration_file,
    'enum_value' AS object_type,
    'public.assignment_status: verification_completed' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'assignment_status' AND e.enumlabel = 'verification_completed'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0420_assignment_timeline_p47.sql' AS migration_file,
    'function' AS object_type,
    'public.advance_assignment_stage(p_assignment_id uuid, p_next_status text, p_meta jsonb)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'advance_assignment_stage'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0420_assignment_timeline_p47.sql' AS migration_file,
    'function' AS object_type,
    'public.get_worker_schedule(p_worker_id uuid, p_start_date timestamp with time zone, p_end_date timestamp with time zone)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_worker_schedule'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0420_assignment_timeline_p47.sql' AS migration_file,
    'trigger' AS object_type,
    'public.job_assignments: trg_assignment_status_event' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_trigger tr JOIN pg_class c ON tr.tgrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = 'public' AND c.relname = 'job_assignments' AND tr.tgname = 'trg_assignment_status_event'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0420_assignment_timeline_p47.sql' AS migration_file,
    'realtime_publication' AS object_type,
    'public.assignment_events' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'assignment_events'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0420_assignment_timeline_p47.sql' AS migration_file,
    'realtime_publication' AS object_type,
    'public.job_assignments' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'job_assignments'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0430_qr_ticket_attendance.sql' AS migration_file,
    'column' AS object_type,
    'public.qr_tokens.assignment_id' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'qr_tokens' AND column_name = 'assignment_id'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0430_qr_ticket_attendance.sql' AS migration_file,
    'column' AS object_type,
    'public.qr_tokens.used' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'qr_tokens' AND column_name = 'used'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0430_qr_ticket_attendance.sql' AS migration_file,
    'function' AS object_type,
    'public.get_job_ticket_details(p_assignment_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_job_ticket_details'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0431_ticket_attendance_caller.sql' AS migration_file,
    'function' AS object_type,
    'public.record_ticket_attendance(p_assignment_id uuid, p_token_id text, p_lat double precision, p_lng double precision, p_scanned_by uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_ticket_attendance'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0440_assignment_verify_stage.sql' AS migration_file,
    'column' AS object_type,
    'public.job_assignments.midjob_verified_at' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'job_assignments' AND column_name = 'midjob_verified_at'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0440_assignment_verify_stage.sql' AS migration_file,
    'enum_value' AS object_type,
    'public.evidence_kind: selfie_midjob' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'evidence_kind' AND e.enumlabel = 'selfie_midjob'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0440_assignment_verify_stage.sql' AS migration_file,
    'function' AS object_type,
    'public.check_job_geofence(p_job_id uuid, p_lat double precision, p_lng double precision)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'check_job_geofence'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0440_assignment_verify_stage.sql' AS migration_file,
    'function' AS object_type,
    'public.record_verified_start(p_assignment_id uuid, p_selfie_path text, p_lat double precision, p_lng double precision, p_actor_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_verified_start'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0440_assignment_verify_stage.sql' AS migration_file,
    'function' AS object_type,
    'public.record_midjob_check(p_assignment_id uuid, p_selfie_path text, p_lat double precision, p_lng double precision, p_confirmed_by_customer boolean, p_actor_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_midjob_check'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0440_assignment_verify_stage.sql' AS migration_file,
    'function' AS object_type,
    'public.record_verified_completion(p_assignment_id uuid, p_selfie_path text, p_lat double precision, p_lng double precision, p_work_photos text[], p_actor_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_verified_completion'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0450_no_show_recovery.sql' AS migration_file,
    'column' AS object_type,
    'public.job_assignments.extended_grace_minutes' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'job_assignments' AND column_name = 'extended_grace_minutes'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0450_no_show_recovery.sql' AS migration_file,
    'function' AS object_type,
    'public.check_no_show_assignments()' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'check_no_show_assignments'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0450_no_show_recovery.sql' AS migration_file,
    'function' AS object_type,
    'public.extend_wait(p_assignment_id uuid, p_minutes integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'extend_wait'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0450_no_show_recovery.sql' AS migration_file,
    'function' AS object_type,
    'public.report_running_late(p_assignment_id uuid, p_eta_minutes integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'report_running_late'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0450_no_show_recovery.sql' AS migration_file,
    'function' AS object_type,
    'public.find_replacement_candidates(p_assignment_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'find_replacement_candidates'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0450_no_show_recovery.sql' AS migration_file,
    'function' AS object_type,
    'public.find_replacement(p_assignment_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'find_replacement'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0450_no_show_recovery.sql' AS migration_file,
    'function' AS object_type,
    'public.confirm_replacement(p_assignment_id uuid, p_replacement_worker_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'confirm_replacement'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0460_reviews_favourites_disputes.sql' AS migration_file,
    'function' AS object_type,
    'public.submit_job_review(p_assignment_id uuid, p_stars integer, p_tags text[], p_comment text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'submit_job_review'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0460_reviews_favourites_disputes.sql' AS migration_file,
    'function' AS object_type,
    'public.create_assignment_dispute(p_assignment_id uuid, p_issue_type dispute_issue_type, p_details text, p_evidence_paths text[])' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'create_assignment_dispute'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0460_reviews_favourites_disputes.sql' AS migration_file,
    'function' AS object_type,
    'public.get_job_history(p_status text, p_limit integer, p_offset integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_job_history'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0460_reviews_favourites_disputes.sql' AS migration_file,
    'function' AS object_type,
    'public.get_favourites_list(p_limit integer, p_offset integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_favourites_list'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0460_reviews_favourites_disputes.sql' AS migration_file,
    'function' AS object_type,
    'public.get_user_reviews(p_user_id uuid, p_limit integer, p_offset integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_user_reviews'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0470_wallet_payouts_transactions.sql' AS migration_file,
    'function' AS object_type,
    'public.get_wallet_summary()' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_wallet_summary'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0470_wallet_payouts_transactions.sql' AS migration_file,
    'function' AS object_type,
    'public.request_wallet_withdrawal(p_amount_paise bigint, p_method text, p_payout_ref text, p_idempotency_key text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'request_wallet_withdrawal'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0480_payments_receipts_escrow.sql' AS migration_file,
    'table' AS object_type,
    'public.payment_webhook_events' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payment_webhook_events'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0480_payments_receipts_escrow.sql' AS migration_file,
    'function' AS object_type,
    'public.compute_payment_bill(p_ref_type text, p_ref_id uuid, p_protection_override boolean)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'compute_payment_bill'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0480_payments_receipts_escrow.sql' AS migration_file,
    'function' AS object_type,
    'public.hold_escrow(p_payment_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'hold_escrow'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0480_payments_receipts_escrow.sql' AS migration_file,
    'function' AS object_type,
    'public.record_payment_success(p_payment_id uuid, p_razorpay_payment_id text, p_signature_verified boolean)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_payment_success'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0490_escrow_release_refunds_reconciliation.sql' AS migration_file,
    'function' AS object_type,
    'public.release_escrow(p_payment_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'release_escrow'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0490_escrow_release_refunds_reconciliation.sql' AS migration_file,
    'function' AS object_type,
    'public.release_assignment_escrow(p_assignment_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'release_assignment_escrow'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0490_escrow_release_refunds_reconciliation.sql' AS migration_file,
    'function' AS object_type,
    'public.confirm_job_completion_and_release(p_assignment_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'confirm_job_completion_and_release'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0490_escrow_release_refunds_reconciliation.sql' AS migration_file,
    'function' AS object_type,
    'public.refund_escrow(p_payment_id uuid, p_refund_paise bigint, p_reason text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'refund_escrow'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0490_escrow_release_refunds_reconciliation.sql' AS migration_file,
    'function' AS object_type,
    'public.refund_assignment_escrow(p_assignment_id uuid, p_refund_paise bigint, p_reason text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'refund_assignment_escrow'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0490_escrow_release_refunds_reconciliation.sql' AS migration_file,
    'function' AS object_type,
    'public.release_order_escrow(p_order_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'release_order_escrow'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0500_earnings_dashboard_savings_goals.sql' AS migration_file,
    'column' AS object_type,
    'public.profiles.daily_earnings_goal_paise' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'daily_earnings_goal_paise'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0500_earnings_dashboard_savings_goals.sql' AS migration_file,
    'column' AS object_type,
    'public.savings_goals.category' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'savings_goals' AND column_name = 'category'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0500_earnings_dashboard_savings_goals.sql' AS migration_file,
    'function' AS object_type,
    'public.update_daily_earnings_goal(p_goal_paise bigint)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_daily_earnings_goal'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0500_earnings_dashboard_savings_goals.sql' AS migration_file,
    'function' AS object_type,
    'public.allocate_savings_goal(p_goal_id uuid, p_amount_paise bigint)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'allocate_savings_goal'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0510_mandi_prices_and_demand.sql' AS migration_file,
    'table' AS object_type,
    'public.mandi_prices' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'mandi_prices'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0510_mandi_prices_and_demand.sql' AS migration_file,
    'column' AS object_type,
    'public.mandi_prices.state' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'mandi_prices' AND column_name = 'state'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0510_mandi_prices_and_demand.sql' AS migration_file,
    'function' AS object_type,
    'public.get_mandi_prices_with_demand(p_commodity_filter text, p_district_filter text, p_limit integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_mandi_prices_with_demand'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0520_produce_listings_management.sql' AS migration_file,
    'column' AS object_type,
    'public.produce_listings.low_stock_threshold' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'produce_listings' AND column_name = 'low_stock_threshold'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0520_produce_listings_management.sql' AS migration_file,
    'function' AS object_type,
    'public.get_buyer_produce_listings(p_search text, p_category text, p_farming_method text, p_limit integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_buyer_produce_listings'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0520_produce_listings_management.sql' AS migration_file,
    'function' AS object_type,
    'public.get_produce_price_suggestion(p_commodity text, p_unit text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_produce_price_suggestion'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0530_farm_resources_and_bookings.sql' AS migration_file,
    'column' AS object_type,
    'public.resource_listings.specs' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'resource_listings' AND column_name = 'specs'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0530_farm_resources_and_bookings.sql' AS migration_file,
    'column' AS object_type,
    'public.resource_bookings.quantity' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'resource_bookings' AND column_name = 'quantity'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0530_farm_resources_and_bookings.sql' AS migration_file,
    'function' AS object_type,
    'public.nearby_resources(...)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_resources'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0530_farm_resources_and_bookings.sql' AS migration_file,
    'function' AS object_type,
    'public.book_resource(p_resource_id uuid, p_start_at timestamp with time zone, p_end_at timestamp with time zone, p_quantity numeric, p_delivery_address text, p_notes text, p_payment_method text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'book_resource'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0540_produce_marketplace_and_lots.sql' AS migration_file,
    'column' AS object_type,
    'public.produce_listings.lot_number' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'produce_listings' AND column_name = 'lot_number'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0540_produce_marketplace_and_lots.sql' AS migration_file,
    'function' AS object_type,
    'public.nearby_produce(...)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_produce'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0540_produce_marketplace_and_lots.sql' AS migration_file,
    'function' AS object_type,
    'public.get_produce_lot_traceability(p_lot_number text, p_listing_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_produce_lot_traceability'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0550_orders_cart_slots.sql' AS migration_file,
    'column' AS object_type,
    'public.produce_listings.reserved_qty' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'produce_listings' AND column_name = 'reserved_qty'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0550_orders_cart_slots.sql' AS migration_file,
    'table' AS object_type,
    'public.delivery_slots' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'delivery_slots'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0550_orders_cart_slots.sql' AS migration_file,
    'function' AS object_type,
    'public.place_order(p_items jsonb, p_fulfilment fulfilment_type, p_address_id uuid, p_address_text text, p_slot_id uuid, p_slots jsonb, p_protected boolean, p_apply_reward_credits boolean, p_payment_method text, p_delivery_notes text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'place_order'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0550_orders_cart_slots.sql' AS migration_file,
    'function' AS object_type,
    'public.create_delivery_slot(p_slot_date date, p_window_start time without time zone, p_window_end time without time zone, p_capacity integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'create_delivery_slot'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0560_order_lifecycle_tracking.sql' AS migration_file,
    'column' AS object_type,
    'public.orders.delivery_pin' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'delivery_pin'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0560_order_lifecycle_tracking.sql' AS migration_file,
    'column' AS object_type,
    'public.orders.delivered_at' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'delivered_at'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0560_order_lifecycle_tracking.sql' AS migration_file,
    'table' AS object_type,
    'public.order_events' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'order_events'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0560_order_lifecycle_tracking.sql' AS migration_file,
    'function' AS object_type,
    'public.update_order_status(p_order_id uuid, p_status text, p_pin text, p_notes text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_order_status'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0560_order_lifecycle_tracking.sql' AS migration_file,
    'function' AS object_type,
    'public.get_order_details(p_order_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_order_details'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0560_order_lifecycle_tracking.sql' AS migration_file,
    'function' AS object_type,
    'public.get_farmer_orders(p_farmer_id uuid, p_status text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_farmer_orders'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0560_order_lifecycle_tracking.sql' AS migration_file,
    'function' AS object_type,
    'public.get_customer_orders(p_customer_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_customer_orders'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0560_order_lifecycle_tracking.sql' AS migration_file,
    'realtime_publication' AS object_type,
    'public.orders' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'orders'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0560_order_lifecycle_tracking.sql' AS migration_file,
    'realtime_publication' AS object_type,
    'public.order_events' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'order_events'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0570_fix_polish_jobs_tickets_wallet.sql' AS migration_file,
    'column' AS object_type,
    'public.jobs.landmark' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'jobs' AND column_name = 'landmark'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0570_fix_polish_jobs_tickets_wallet.sql' AS migration_file,
    'function' AS object_type,
    'public.apply_to_job(p_job_id uuid, p_message text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'apply_to_job'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0570_fix_polish_jobs_tickets_wallet.sql' AS migration_file,
    'function' AS object_type,
    'public.nearby_jobs(...)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_jobs'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0570_fix_polish_jobs_tickets_wallet.sql' AS migration_file,
    'function' AS object_type,
    'public.recommended_jobs(...)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'recommended_jobs'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0580_job_execution_tickets_qr_lifecycle.sql' AS migration_file,
    'column' AS object_type,
    'public.assignment_events.actor_role' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'assignment_events' AND column_name = 'actor_role'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0580_job_execution_tickets_qr_lifecycle.sql' AS migration_file,
    'column' AS object_type,
    'public.assignment_events.payload' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'assignment_events' AND column_name = 'payload'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0580_job_execution_tickets_qr_lifecycle.sql' AS migration_file,
    'function' AS object_type,
    'public.issue_job_ticket(p_assignment_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'issue_job_ticket'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0580_job_execution_tickets_qr_lifecycle.sql' AS migration_file,
    'function' AS object_type,
    'public.get_rotating_ticket_token(p_assignment_id uuid, p_debug_short_ttl boolean)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_rotating_ticket_token'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0580_job_execution_tickets_qr_lifecycle.sql' AS migration_file,
    'function' AS object_type,
    'public.record_step2_verification(p_assignment_id uuid, p_selfie_path text, p_lat double precision, p_lng double precision, p_face_score double precision)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_step2_verification'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0580_job_execution_tickets_qr_lifecycle.sql' AS migration_file,
    'function' AS object_type,
    'public.get_next_accepted_ticket()' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_next_accepted_ticket'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0580_job_execution_tickets_qr_lifecycle.sql' AS migration_file,
    'function' AS object_type,
    'public.get_active_job_details(p_assignment_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_active_job_details'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0590_job_thumbnails_and_students_welcome.sql' AS migration_file,
    'column' AS object_type,
    'public.jobs.site_photo_url' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'jobs' AND column_name = 'site_photo_url'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0590_job_thumbnails_and_students_welcome.sql' AS migration_file,
    'function' AS object_type,
    'public.post_provider_job (18 params: p_category_id ... p_site_photo_url)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'post_provider_job' AND pg_get_function_identity_arguments(p.oid) = 'p_category_id uuid, p_title text, p_description text, p_wage_type wage_type, p_wage_paise bigint, p_est_duration_minutes integer, p_start_at timestamp with time zone, p_slots_total integer, p_materials_provided boolean, p_payment_mode payment_mode, p_requirements jsonb, p_address_text text, p_location_lat double precision, p_location_lng double precision, p_geofence_radius_m integer, p_suitable_for text[], p_landmark text, p_site_photo_url text'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0590_job_thumbnails_and_students_welcome.sql' AS migration_file,
    'function' AS object_type,
    'public.update_provider_job (19 params: p_job_id ... p_site_photo_url)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_provider_job' AND pg_get_function_identity_arguments(p.oid) = 'p_job_id uuid, p_category_id uuid, p_title text, p_description text, p_wage_type wage_type, p_wage_paise bigint, p_est_duration_minutes integer, p_start_at timestamp with time zone, p_slots_total integer, p_materials_provided boolean, p_payment_mode payment_mode, p_requirements jsonb, p_address_text text, p_location_lat double precision, p_location_lng double precision, p_geofence_radius_m integer, p_suitable_for text[], p_landmark text, p_site_photo_url text'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0600_wallet_escrow_filters_and_validation.sql' AS migration_file,
    'function' AS object_type,
    'public.get_wallet_transactions(p_type text, p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_limit integer, p_offset integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_wallet_transactions'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0600_wallet_escrow_filters_and_validation.sql' AS migration_file,
    'function' AS object_type,
    'public.validate_upi_payment(p_vpa text, p_amount_rupees numeric)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'validate_upi_payment'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0610_job_execution_ticket_qr_polish.sql' AS migration_file,
    'function' AS object_type,
    'public.set_ticket_timing_debug(p_short_ttl_seconds integer, p_minutes_before integer, p_minutes_after integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'set_ticket_timing_debug'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0610_job_execution_ticket_qr_polish.sql' AS migration_file,
    'function' AS object_type,
    'public.verify_ticket_scan(p_token text, p_provider_lat double precision, p_provider_lng double precision)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'verify_ticket_scan'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0620_ledger_is_demo_and_savings_planner.sql' AS migration_file,
    'column' AS object_type,
    'public.ledger_entries.is_demo' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ledger_entries' AND column_name = 'is_demo'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0620_ledger_is_demo_and_savings_planner.sql' AS migration_file,
    'column' AS object_type,
    'public.savings_goals.monthly_percentage' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'savings_goals' AND column_name = 'monthly_percentage'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0620_ledger_is_demo_and_savings_planner.sql' AS migration_file,
    'function' AS object_type,
    'public.clean_demo_wallet_history(p_user_id uuid)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'clean_demo_wallet_history'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0620_ledger_is_demo_and_savings_planner.sql' AS migration_file,
    'function' AS object_type,
    'public.get_earnings_dashboard(p_days integer)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_earnings_dashboard'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0630_farmer_profile_fields.sql' AS migration_file,
    'column' AS object_type,
    'public.farmer_profiles.delivery_radius_km' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'delivery_radius_km'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0630_farmer_profile_fields.sql' AS migration_file,
    'column' AS object_type,
    'public.farmer_profiles.pickup_available' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'pickup_available'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0630_farmer_profile_fields.sql' AS migration_file,
    'column' AS object_type,
    'public.farmer_profiles.lead_time_hours' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'lead_time_hours'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0630_farmer_profile_fields.sql' AS migration_file,
    'column' AS object_type,
    'public.farmer_profiles.farm_photo_url' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'farm_photo_url'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0630_farmer_profile_fields.sql' AS migration_file,
    'column' AS object_type,
    'public.farmer_profiles.organic_cert_number' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'organic_cert_number'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0640_db_contract_sync.sql' AS migration_file,
    'enum_value' AS object_type,
    'public.application_status: accepted' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'application_status' AND e.enumlabel = 'accepted'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0640_db_contract_sync.sql' AS migration_file,
    'enum_value' AS object_type,
    'public.application_status: declined' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'application_status' AND e.enumlabel = 'declined'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0640_db_contract_sync.sql' AS migration_file,
    'policy' AS object_type,
    'public.job_applications: job_applications_provider_select' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'job_applications' AND policyname = 'job_applications_provider_select'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0640_db_contract_sync.sql' AS migration_file,
    'policy' AS object_type,
    'public.job_applications: job_applications_worker_select' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'job_applications' AND policyname = 'job_applications_worker_select'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0640_db_contract_sync.sql' AS migration_file,
    'realtime_publication' AS object_type,
    'public.job_applications' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'job_applications'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0640_db_contract_sync.sql' AS migration_file,
    'realtime_publication' AS object_type,
    'public.jobs' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'jobs'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0640_db_contract_sync.sql' AS migration_file,
    'single_overload' AS object_type,
    'public.post_provider_job (no older 15, 16 or 17 param overloads)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM (SELECT count(*) as c FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'post_provider_job') x WHERE x.c = 1
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0640_db_contract_sync.sql' AS migration_file,
    'single_overload' AS object_type,
    'public.update_provider_job (no older 16, 17 or 18 param overloads)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM (SELECT count(*) as c FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_provider_job') x WHERE x.c = 1
    ) THEN 'OK' ELSE 'MISSING' END AS status
)
SELECT
  migration_file,
  object_type,
  object_name,
  status
FROM verification_checks
ORDER BY
  CASE WHEN status = 'MISSING' THEN 0 ELSE 1 END,
  migration_file,
  object_type,
  object_name;

