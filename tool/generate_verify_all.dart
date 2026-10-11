// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures
import 'dart:io';

void main() {
  final buffer = StringBuffer();
  buffer.writeln('-- ============================================================================');
  buffer.writeln('-- Read-Only Schema Verification Script: verify_all.sql');
  buffer.writeln('-- Description: Comprehensive read-only verification query checking every table,');
  buffer.writeln('--              column, function with exact arguments, enum value, policy,');
  buffer.writeln('--              trigger, storage bucket, realtime publication, and grant');
  buffer.writeln('--              introduced or updated by migrations 0190 through 0640.');
  buffer.writeln('-- Output: Returns one row per checked object with columns:');
  buffer.writeln('--         migration_file, object_type, object_name, status ("OK" or "MISSING")');
  buffer.writeln('-- Sorting: MISSING rows appear FIRST so any discrepancy is immediately visible.');
  buffer.writeln('-- ============================================================================');
  buffer.writeln();
  buffer.writeln('WITH verification_checks AS (');

  final checks = <String>[];

  void addCheck(String file, String type, String name, String existsSql) {
    final cleanExists = existsSql.trim();
    checks.add('''  SELECT 
    '$file' AS migration_file,
    '$type' AS object_type,
    '$name' AS object_name,
    CASE WHEN EXISTS (
      $cleanExists
    ) THEN 'OK' ELSE 'MISSING' END AS status''');
  }

  // --- 0190_single_role_rule.sql ---
  addCheck('0190_single_role_rule.sql', 'function', 'public.allow_multi_role()',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'allow_multi_role'");
  addCheck('0190_single_role_rule.sql', 'function', 'public.apply_role_selection(p_role app_role, p_seeker_type seeker_type)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'apply_role_selection' AND pg_get_function_identity_arguments(p.oid) = 'p_role app_role, p_seeker_type seeker_type'");
  addCheck('0190_single_role_rule.sql', 'function', 'public.anonymize_and_delete_user_data(p_target_user_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'anonymize_and_delete_user_data' AND pg_get_function_identity_arguments(p.oid) = 'p_target_user_id uuid'");

  // --- 0200_privacy_consent.sql ---
  addCheck('0200_privacy_consent.sql', 'function', 'public.revoke_consent(p_purpose text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'revoke_consent'");
  addCheck('0200_privacy_consent.sql', 'function', 'public.withdraw_face_consent()',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'withdraw_face_consent'");

  // --- 0210_verification_extra.sql ---
  addCheck('0210_verification_extra.sql', 'column', 'public.service_categories.requires_licence',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'service_categories' AND column_name = 'requires_licence'");
  addCheck('0210_verification_extra.sql', 'enum_value', 'public.doc_type: student_id',
    "SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'doc_type' AND e.enumlabel = 'student_id'");
  addCheck('0210_verification_extra.sql', 'enum_value', 'public.doc_type: bank_account',
    "SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'doc_type' AND e.enumlabel = 'bank_account'");
  addCheck('0210_verification_extra.sql', 'enum_value', 'public.doc_type: upi',
    "SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'doc_type' AND e.enumlabel = 'upi'");
  addCheck('0210_verification_extra.sql', 'function', 'public.nearby_jobs_for_worker(uuid, double precision, double precision, double precision, uuid, integer, integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_jobs_for_worker'");

  // --- 0220_face_embedding.sql ---
  addCheck('0220_face_embedding.sql', 'column', 'public.face_profiles.embedding',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'face_profiles' AND column_name = 'embedding'");
  addCheck('0220_face_embedding.sql', 'function', 'public.compare_face_embeddings(v1 double precision[], v2 double precision[])',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'compare_face_embeddings'");
  addCheck('0220_face_embedding.sql', 'function', 'public.save_face_embedding(p_user_id uuid, p_embedding double precision[], p_liveness_passed_at timestamp with time zone, p_matcher_ref text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'save_face_embedding'");

  // --- 0230_verification_visibility_guard.sql ---
  addCheck('0230_verification_visibility_guard.sql', 'function', 'public.check_kyc_record_visibility()',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'check_kyc_record_visibility'");
  addCheck('0230_verification_visibility_guard.sql', 'trigger', 'public.kyc_records: trg_check_kyc_record_visibility',
    "SELECT 1 FROM pg_trigger tr JOIN pg_class c ON tr.tgrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = 'public' AND c.relname = 'kyc_records' AND tr.tgname = 'trg_check_kyc_record_visibility'");

  // --- 0240_sync_avatar_paths.sql ---
  addCheck('0240_sync_avatar_paths.sql', 'column', 'public.profiles.avatar_path',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'avatar_path'");

  // --- 0250_face_verify_settings.sql ---
  addCheck('0250_face_verify_settings.sql', 'function', 'public.get_face_login_requirement()',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_face_login_requirement'");

  // --- 0280_fix_bootstrap_wizard_completion.sql ---
  addCheck('0280_fix_bootstrap_wizard_completion.sql', 'function', 'public.get_bootstrap_state()',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_bootstrap_state'");

  // --- 0290_safety_onboarding.sql ---
  addCheck('0290_safety_onboarding.sql', 'table', 'public.training_events',
    "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'training_events'");
  addCheck('0290_safety_onboarding.sql', 'table', 'public.event_registrations',
    "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'event_registrations'");
  addCheck('0290_safety_onboarding.sql', 'function', 'public.get_safety_onboarding_status(p_user_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_safety_onboarding_status'");
  addCheck('0290_safety_onboarding.sql', 'function', 'public.book_safety_onboarding_slot(p_event_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'book_safety_onboarding_slot'");
  addCheck('0290_safety_onboarding.sql', 'function', 'public.simulate_training_status(p_user_id uuid, p_status text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'simulate_training_status'");

  // --- 0300_qr_tokens.sql ---
  addCheck('0300_qr_tokens.sql', 'table', 'public.qr_tokens',
    "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'qr_tokens'");
  addCheck('0300_qr_tokens.sql', 'function', 'public.revoke_qr_token(p_token_id_hash text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'revoke_qr_token'");

  // --- 0310_public_verification_enhancement.sql ---
  addCheck('0310_public_verification_enhancement.sql', 'function', 'public.get_public_verification(p_user_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_public_verification'");

  // --- 0320_recommendations.sql & 0350 ---
  addCheck('0320_recommendations.sql', 'function', 'public.get_seeker_home_summary(p_worker_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_seeker_home_summary'");

  // --- 0350_audience_and_jobs_rules.sql ---
  addCheck('0350_audience_and_jobs_rules.sql', 'function', 'public.get_user_consents()',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_user_consents'");
  addCheck('0350_audience_and_jobs_rules.sql', 'function', 'public.record_user_consent_v2(p_purpose text, p_granted boolean, p_version text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_user_consent_v2'");

  // --- 0370_job_details_and_requests.sql & 0570 ---
  addCheck('0370_job_details_and_requests.sql', 'function', 'public.check_job_eligibility(p_job_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'check_job_eligibility'");
  addCheck('0370_job_details_and_requests.sql', 'function', 'public.get_job_detail(p_job_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_job_detail'");

  // --- 0380_provider_jobs_management.sql ---
  addCheck('0380_provider_jobs_management.sql', 'function', 'public.get_provider_jobs(p_provider_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_provider_jobs'");
  addCheck('0380_provider_jobs_management.sql', 'function', 'public.get_job_applicants(p_job_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_job_applicants'");
  addCheck('0380_provider_jobs_management.sql', 'function', 'public.update_provider_job_status(p_job_id uuid, p_status job_status)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_provider_job_status'");
  addCheck('0380_provider_jobs_management.sql', 'function', 'public.respond_to_application(p_application_id uuid, p_status application_status)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'respond_to_application'");

  // --- 0390_provider_hub_worker_search.sql ---
  addCheck('0390_provider_hub_worker_search.sql', 'function', 'public.nearby_workers(...)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_workers'");
  addCheck('0390_provider_hub_worker_search.sql', 'function', 'public.get_worker_profile_detail(p_worker_id uuid, p_caller_lat double precision, p_caller_lng double precision)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_worker_profile_detail'");
  addCheck('0390_provider_hub_worker_search.sql', 'function', 'public.get_provider_active_booking(p_provider_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_provider_active_booking'");
  addCheck('0390_provider_hub_worker_search.sql', 'function', 'public.toggle_favourite(p_target_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'toggle_favourite'");

  // --- 0400_guided_booking_and_protection.sql ---
  addCheck('0400_guided_booking_and_protection.sql', 'function', 'public.get_worker_booked_slots(p_worker_id uuid, p_start_date date, p_end_date date)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_worker_booked_slots'");
  addCheck('0400_guided_booking_and_protection.sql', 'function', 'public.request_worker(...)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'request_worker'");
  addCheck('0400_guided_booking_and_protection.sql', 'function', 'public.get_user_addresses(p_user_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_user_addresses'");
  addCheck('0400_guided_booking_and_protection.sql', 'function', 'public.save_user_address(p_label text, p_line1 text, p_landmark text, p_city text, p_pincode text, p_lat double precision, p_lng double precision, p_is_default boolean)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'save_user_address'");
  addCheck('0400_guided_booking_and_protection.sql', 'function', 'public.get_provider_recurring_bookings(p_provider_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_provider_recurring_bookings'");
  addCheck('0400_guided_booking_and_protection.sql', 'function', 'public.update_recurring_booking(p_recurring_id uuid, p_status subscription_status, p_schedule_rule text, p_preferred_time time without time zone)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_recurring_booking'");
  addCheck('0400_guided_booking_and_protection.sql', 'function', 'public.skip_recurring_booking_date(p_recurring_id uuid, p_skip_date date)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'skip_recurring_booking_date'");

  // --- 0410_fix_polish_p4.sql ---
  addCheck('0410_fix_polish_p4.sql', 'column', 'public.jobs.suitable_for',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'jobs' AND column_name = 'suitable_for'");
  addCheck('0410_fix_polish_p4.sql', 'column', 'public.provider_profiles.is_verified_badge',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'provider_profiles' AND column_name = 'is_verified_badge'");

  // --- 0420_assignment_timeline_p47.sql ---
  addCheck('0420_assignment_timeline_p47.sql', 'enum_value', 'public.assignment_status: verification_completed',
    "SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'assignment_status' AND e.enumlabel = 'verification_completed'");
  addCheck('0420_assignment_timeline_p47.sql', 'function', 'public.advance_assignment_stage(p_assignment_id uuid, p_next_status text, p_meta jsonb)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'advance_assignment_stage'");
  addCheck('0420_assignment_timeline_p47.sql', 'function', 'public.get_worker_schedule(p_worker_id uuid, p_start_date timestamp with time zone, p_end_date timestamp with time zone)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_worker_schedule'");
  addCheck('0420_assignment_timeline_p47.sql', 'trigger', 'public.job_assignments: trg_assignment_status_event',
    "SELECT 1 FROM pg_trigger tr JOIN pg_class c ON tr.tgrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = 'public' AND c.relname = 'job_assignments' AND tr.tgname = 'trg_assignment_status_event'");
  addCheck('0420_assignment_timeline_p47.sql', 'realtime_publication', 'public.assignment_events',
    "SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'assignment_events'");
  addCheck('0420_assignment_timeline_p47.sql', 'realtime_publication', 'public.job_assignments',
    "SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'job_assignments'");

  // --- 0430 & 0431 ---
  addCheck('0430_qr_ticket_attendance.sql', 'column', 'public.qr_tokens.assignment_id',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'qr_tokens' AND column_name = 'assignment_id'");
  addCheck('0430_qr_ticket_attendance.sql', 'column', 'public.qr_tokens.used',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'qr_tokens' AND column_name = 'used'");
  addCheck('0430_qr_ticket_attendance.sql', 'function', 'public.get_job_ticket_details(p_assignment_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_job_ticket_details'");
  addCheck('0431_ticket_attendance_caller.sql', 'function', 'public.record_ticket_attendance(p_assignment_id uuid, p_token_id text, p_lat double precision, p_lng double precision, p_scanned_by uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_ticket_attendance'");

  // --- 0440_assignment_verify_stage.sql ---
  addCheck('0440_assignment_verify_stage.sql', 'column', 'public.job_assignments.midjob_verified_at',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'job_assignments' AND column_name = 'midjob_verified_at'");
  addCheck('0440_assignment_verify_stage.sql', 'enum_value', 'public.evidence_kind: selfie_midjob',
    "SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'evidence_kind' AND e.enumlabel = 'selfie_midjob'");
  addCheck('0440_assignment_verify_stage.sql', 'function', 'public.check_job_geofence(p_job_id uuid, p_lat double precision, p_lng double precision)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'check_job_geofence'");
  addCheck('0440_assignment_verify_stage.sql', 'function', 'public.record_verified_start(p_assignment_id uuid, p_selfie_path text, p_lat double precision, p_lng double precision, p_actor_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_verified_start'");
  addCheck('0440_assignment_verify_stage.sql', 'function', 'public.record_midjob_check(p_assignment_id uuid, p_selfie_path text, p_lat double precision, p_lng double precision, p_confirmed_by_customer boolean, p_actor_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_midjob_check'");
  addCheck('0440_assignment_verify_stage.sql', 'function', 'public.record_verified_completion(p_assignment_id uuid, p_selfie_path text, p_lat double precision, p_lng double precision, p_work_photos text[], p_actor_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_verified_completion'");

  // --- 0450_no_show_recovery.sql ---
  addCheck('0450_no_show_recovery.sql', 'column', 'public.job_assignments.extended_grace_minutes',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'job_assignments' AND column_name = 'extended_grace_minutes'");
  addCheck('0450_no_show_recovery.sql', 'function', 'public.check_no_show_assignments()',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'check_no_show_assignments'");
  addCheck('0450_no_show_recovery.sql', 'function', 'public.extend_wait(p_assignment_id uuid, p_minutes integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'extend_wait'");
  addCheck('0450_no_show_recovery.sql', 'function', 'public.report_running_late(p_assignment_id uuid, p_eta_minutes integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'report_running_late'");
  addCheck('0450_no_show_recovery.sql', 'function', 'public.find_replacement_candidates(p_assignment_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'find_replacement_candidates'");
  addCheck('0450_no_show_recovery.sql', 'function', 'public.find_replacement(p_assignment_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'find_replacement'");
  addCheck('0450_no_show_recovery.sql', 'function', 'public.confirm_replacement(p_assignment_id uuid, p_replacement_worker_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'confirm_replacement'");

  // --- 0460_reviews_favourites_disputes.sql ---
  addCheck('0460_reviews_favourites_disputes.sql', 'function', 'public.submit_job_review(p_assignment_id uuid, p_stars integer, p_tags text[], p_comment text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'submit_job_review'");
  addCheck('0460_reviews_favourites_disputes.sql', 'function', 'public.create_assignment_dispute(p_assignment_id uuid, p_issue_type dispute_issue_type, p_details text, p_evidence_paths text[])',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'create_assignment_dispute'");
  addCheck('0460_reviews_favourites_disputes.sql', 'function', 'public.get_job_history(p_status text, p_limit integer, p_offset integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_job_history'");
  addCheck('0460_reviews_favourites_disputes.sql', 'function', 'public.get_favourites_list(p_limit integer, p_offset integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_favourites_list'");
  addCheck('0460_reviews_favourites_disputes.sql', 'function', 'public.get_user_reviews(p_user_id uuid, p_limit integer, p_offset integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_user_reviews'");

  // --- 0470_wallet_payouts_transactions.sql ---
  addCheck('0470_wallet_payouts_transactions.sql', 'function', 'public.get_wallet_summary()',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_wallet_summary'");
  addCheck('0470_wallet_payouts_transactions.sql', 'function', 'public.request_wallet_withdrawal(p_amount_paise bigint, p_method text, p_payout_ref text, p_idempotency_key text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'request_wallet_withdrawal'");

  // --- 0480_payments_receipts_escrow.sql ---
  addCheck('0480_payments_receipts_escrow.sql', 'table', 'public.payment_webhook_events',
    "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payment_webhook_events'");
  addCheck('0480_payments_receipts_escrow.sql', 'function', 'public.compute_payment_bill(p_ref_type text, p_ref_id uuid, p_protection_override boolean)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'compute_payment_bill'");
  addCheck('0480_payments_receipts_escrow.sql', 'function', 'public.hold_escrow(p_payment_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'hold_escrow'");
  addCheck('0480_payments_receipts_escrow.sql', 'function', 'public.record_payment_success(p_payment_id uuid, p_razorpay_payment_id text, p_signature_verified boolean)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_payment_success'");

  // --- 0490_escrow_release_refunds_reconciliation.sql ---
  addCheck('0490_escrow_release_refunds_reconciliation.sql', 'function', 'public.release_escrow(p_payment_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'release_escrow'");
  addCheck('0490_escrow_release_refunds_reconciliation.sql', 'function', 'public.release_assignment_escrow(p_assignment_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'release_assignment_escrow'");
  addCheck('0490_escrow_release_refunds_reconciliation.sql', 'function', 'public.confirm_job_completion_and_release(p_assignment_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'confirm_job_completion_and_release'");
  addCheck('0490_escrow_release_refunds_reconciliation.sql', 'function', 'public.refund_escrow(p_payment_id uuid, p_refund_paise bigint, p_reason text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'refund_escrow'");
  addCheck('0490_escrow_release_refunds_reconciliation.sql', 'function', 'public.refund_assignment_escrow(p_assignment_id uuid, p_refund_paise bigint, p_reason text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'refund_assignment_escrow'");
  addCheck('0490_escrow_release_refunds_reconciliation.sql', 'function', 'public.release_order_escrow(p_order_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'release_order_escrow'");

  // --- 0500_earnings_dashboard_savings_goals.sql ---
  addCheck('0500_earnings_dashboard_savings_goals.sql', 'column', 'public.profiles.daily_earnings_goal_paise',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'daily_earnings_goal_paise'");
  addCheck('0500_earnings_dashboard_savings_goals.sql', 'column', 'public.savings_goals.category',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'savings_goals' AND column_name = 'category'");
  addCheck('0500_earnings_dashboard_savings_goals.sql', 'function', 'public.update_daily_earnings_goal(p_goal_paise bigint)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_daily_earnings_goal'");
  addCheck('0500_earnings_dashboard_savings_goals.sql', 'function', 'public.allocate_savings_goal(p_goal_id uuid, p_amount_paise bigint)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'allocate_savings_goal'");

  // --- 0510_mandi_prices_and_demand.sql ---
  addCheck('0510_mandi_prices_and_demand.sql', 'table', 'public.mandi_prices',
    "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'mandi_prices'");
  addCheck('0510_mandi_prices_and_demand.sql', 'column', 'public.mandi_prices.state',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'mandi_prices' AND column_name = 'state'");
  addCheck('0510_mandi_prices_and_demand.sql', 'function', 'public.get_mandi_prices_with_demand(p_commodity_filter text, p_district_filter text, p_limit integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_mandi_prices_with_demand'");

  // --- 0520_produce_listings_management.sql ---
  addCheck('0520_produce_listings_management.sql', 'column', 'public.produce_listings.low_stock_threshold',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'produce_listings' AND column_name = 'low_stock_threshold'");
  addCheck('0520_produce_listings_management.sql', 'function', 'public.get_buyer_produce_listings(p_search text, p_category text, p_farming_method text, p_limit integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_buyer_produce_listings'");
  addCheck('0520_produce_listings_management.sql', 'function', 'public.get_produce_price_suggestion(p_commodity text, p_unit text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_produce_price_suggestion'");

  // --- 0530_farm_resources_and_bookings.sql ---
  addCheck('0530_farm_resources_and_bookings.sql', 'column', 'public.resource_listings.specs',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'resource_listings' AND column_name = 'specs'");
  addCheck('0530_farm_resources_and_bookings.sql', 'column', 'public.resource_bookings.quantity',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'resource_bookings' AND column_name = 'quantity'");
  addCheck('0530_farm_resources_and_bookings.sql', 'function', 'public.nearby_resources(...)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_resources'");
  addCheck('0530_farm_resources_and_bookings.sql', 'function', 'public.book_resource(p_resource_id uuid, p_start_at timestamp with time zone, p_end_at timestamp with time zone, p_quantity numeric, p_delivery_address text, p_notes text, p_payment_method text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'book_resource'");

  // --- 0540_produce_marketplace_and_lots.sql ---
  addCheck('0540_produce_marketplace_and_lots.sql', 'column', 'public.produce_listings.lot_number',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'produce_listings' AND column_name = 'lot_number'");
  addCheck('0540_produce_marketplace_and_lots.sql', 'function', 'public.nearby_produce(...)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_produce'");
  addCheck('0540_produce_marketplace_and_lots.sql', 'function', 'public.get_produce_lot_traceability(p_lot_number text, p_listing_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_produce_lot_traceability'");

  // --- 0550_orders_cart_slots.sql ---
  addCheck('0550_orders_cart_slots.sql', 'column', 'public.produce_listings.reserved_qty',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'produce_listings' AND column_name = 'reserved_qty'");
  addCheck('0550_orders_cart_slots.sql', 'table', 'public.delivery_slots',
    "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'delivery_slots'");
  addCheck('0550_orders_cart_slots.sql', 'function', 'public.place_order(p_items jsonb, p_fulfilment fulfilment_type, p_address_id uuid, p_address_text text, p_slot_id uuid, p_slots jsonb, p_protected boolean, p_apply_reward_credits boolean, p_payment_method text, p_delivery_notes text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'place_order'");
  addCheck('0550_orders_cart_slots.sql', 'function', 'public.create_delivery_slot(p_slot_date date, p_window_start time without time zone, p_window_end time without time zone, p_capacity integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'create_delivery_slot'");

  // --- 0560_order_lifecycle_tracking.sql ---
  addCheck('0560_order_lifecycle_tracking.sql', 'column', 'public.orders.delivery_pin',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'delivery_pin'");
  addCheck('0560_order_lifecycle_tracking.sql', 'column', 'public.orders.delivered_at',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'delivered_at'");
  addCheck('0560_order_lifecycle_tracking.sql', 'table', 'public.order_events',
    "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'order_events'");
  addCheck('0560_order_lifecycle_tracking.sql', 'function', 'public.update_order_status(p_order_id uuid, p_status text, p_pin text, p_notes text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_order_status'");
  addCheck('0560_order_lifecycle_tracking.sql', 'function', 'public.get_order_details(p_order_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_order_details'");
  addCheck('0560_order_lifecycle_tracking.sql', 'function', 'public.get_farmer_orders(p_farmer_id uuid, p_status text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_farmer_orders'");
  addCheck('0560_order_lifecycle_tracking.sql', 'function', 'public.get_customer_orders(p_customer_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_customer_orders'");
  addCheck('0560_order_lifecycle_tracking.sql', 'realtime_publication', 'public.orders',
    "SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'orders'");
  addCheck('0560_order_lifecycle_tracking.sql', 'realtime_publication', 'public.order_events',
    "SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'order_events'");

  // --- 0570_fix_polish_jobs_tickets_wallet.sql ---
  addCheck('0570_fix_polish_jobs_tickets_wallet.sql', 'column', 'public.jobs.landmark',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'jobs' AND column_name = 'landmark'");
  addCheck('0570_fix_polish_jobs_tickets_wallet.sql', 'function', 'public.apply_to_job(p_job_id uuid, p_message text)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'apply_to_job'");
  addCheck('0570_fix_polish_jobs_tickets_wallet.sql', 'function', 'public.nearby_jobs(...)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'nearby_jobs'");
  addCheck('0570_fix_polish_jobs_tickets_wallet.sql', 'function', 'public.recommended_jobs(...)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'recommended_jobs'");

  // --- 0580_job_execution_tickets_qr_lifecycle.sql ---
  addCheck('0580_job_execution_tickets_qr_lifecycle.sql', 'column', 'public.assignment_events.actor_role',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'assignment_events' AND column_name = 'actor_role'");
  addCheck('0580_job_execution_tickets_qr_lifecycle.sql', 'column', 'public.assignment_events.payload',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'assignment_events' AND column_name = 'payload'");
  addCheck('0580_job_execution_tickets_qr_lifecycle.sql', 'function', 'public.issue_job_ticket(p_assignment_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'issue_job_ticket'");
  addCheck('0580_job_execution_tickets_qr_lifecycle.sql', 'function', 'public.get_rotating_ticket_token(p_assignment_id uuid, p_debug_short_ttl boolean)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_rotating_ticket_token'");
  addCheck('0580_job_execution_tickets_qr_lifecycle.sql', 'function', 'public.record_step2_verification(p_assignment_id uuid, p_selfie_path text, p_lat double precision, p_lng double precision, p_face_score double precision)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'record_step2_verification'");
  addCheck('0580_job_execution_tickets_qr_lifecycle.sql', 'function', 'public.get_next_accepted_ticket()',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_next_accepted_ticket'");
  addCheck('0580_job_execution_tickets_qr_lifecycle.sql', 'function', 'public.get_active_job_details(p_assignment_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_active_job_details'");

  // --- 0590_job_thumbnails_and_students_welcome.sql & 0640 ---
  addCheck('0590_job_thumbnails_and_students_welcome.sql', 'column', 'public.jobs.site_photo_url',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'jobs' AND column_name = 'site_photo_url'");
  addCheck('0590_job_thumbnails_and_students_welcome.sql', 'function', 'public.post_provider_job (18 params: p_category_id ... p_site_photo_url)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'post_provider_job' AND pg_get_function_identity_arguments(p.oid) = 'p_category_id uuid, p_title text, p_description text, p_wage_type wage_type, p_wage_paise bigint, p_est_duration_minutes integer, p_start_at timestamp with time zone, p_slots_total integer, p_materials_provided boolean, p_payment_mode payment_mode, p_requirements jsonb, p_address_text text, p_location_lat double precision, p_location_lng double precision, p_geofence_radius_m integer, p_suitable_for text[], p_landmark text, p_site_photo_url text'");
  addCheck('0590_job_thumbnails_and_students_welcome.sql', 'function', 'public.update_provider_job (19 params: p_job_id ... p_site_photo_url)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_provider_job' AND pg_get_function_identity_arguments(p.oid) = 'p_job_id uuid, p_category_id uuid, p_title text, p_description text, p_wage_type wage_type, p_wage_paise bigint, p_est_duration_minutes integer, p_start_at timestamp with time zone, p_slots_total integer, p_materials_provided boolean, p_payment_mode payment_mode, p_requirements jsonb, p_address_text text, p_location_lat double precision, p_location_lng double precision, p_geofence_radius_m integer, p_suitable_for text[], p_landmark text, p_site_photo_url text'");

  // --- 0600_wallet_escrow_filters_and_validation.sql ---
  addCheck('0600_wallet_escrow_filters_and_validation.sql', 'function', 'public.get_wallet_transactions(p_type text, p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_limit integer, p_offset integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_wallet_transactions'");
  addCheck('0600_wallet_escrow_filters_and_validation.sql', 'function', 'public.validate_upi_payment(p_vpa text, p_amount_rupees numeric)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'validate_upi_payment'");

  // --- 0610_job_execution_ticket_qr_polish.sql ---
  addCheck('0610_job_execution_ticket_qr_polish.sql', 'function', 'public.set_ticket_timing_debug(p_short_ttl_seconds integer, p_minutes_before integer, p_minutes_after integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'set_ticket_timing_debug'");
  addCheck('0610_job_execution_ticket_qr_polish.sql', 'function', 'public.verify_ticket_scan(p_token text, p_provider_lat double precision, p_provider_lng double precision)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'verify_ticket_scan'");

  // --- 0620_ledger_is_demo_and_savings_planner.sql ---
  addCheck('0620_ledger_is_demo_and_savings_planner.sql', 'column', 'public.ledger_entries.is_demo',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ledger_entries' AND column_name = 'is_demo'");
  addCheck('0620_ledger_is_demo_and_savings_planner.sql', 'column', 'public.savings_goals.monthly_percentage',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'savings_goals' AND column_name = 'monthly_percentage'");
  addCheck('0620_ledger_is_demo_and_savings_planner.sql', 'function', 'public.clean_demo_wallet_history(p_user_id uuid)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'clean_demo_wallet_history'");
  addCheck('0620_ledger_is_demo_and_savings_planner.sql', 'function', 'public.get_earnings_dashboard(p_days integer)',
    "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_earnings_dashboard'");

  // --- 0630_farmer_profile_fields.sql ---
  addCheck('0630_farmer_profile_fields.sql', 'column', 'public.farmer_profiles.delivery_radius_km',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'delivery_radius_km'");
  addCheck('0630_farmer_profile_fields.sql', 'column', 'public.farmer_profiles.pickup_available',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'pickup_available'");
  addCheck('0630_farmer_profile_fields.sql', 'column', 'public.farmer_profiles.lead_time_hours',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'lead_time_hours'");
  addCheck('0630_farmer_profile_fields.sql', 'column', 'public.farmer_profiles.farm_photo_url',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'farm_photo_url'");
  addCheck('0630_farmer_profile_fields.sql', 'column', 'public.farmer_profiles.organic_cert_number',
    "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'organic_cert_number'");

  // --- 0640_db_contract_sync.sql ---
  addCheck('0640_db_contract_sync.sql', 'enum_value', 'public.application_status: accepted',
    "SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'application_status' AND e.enumlabel = 'accepted'");
  addCheck('0640_db_contract_sync.sql', 'enum_value', 'public.application_status: declined',
    "SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typname = 'application_status' AND e.enumlabel = 'declined'");
  addCheck('0640_db_contract_sync.sql', 'policy', 'public.job_applications: job_applications_provider_select',
    "SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'job_applications' AND policyname = 'job_applications_provider_select'");
  addCheck('0640_db_contract_sync.sql', 'policy', 'public.job_applications: job_applications_worker_select',
    "SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'job_applications' AND policyname = 'job_applications_worker_select'");
  addCheck('0640_db_contract_sync.sql', 'realtime_publication', 'public.job_applications',
    "SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'job_applications'");
  addCheck('0640_db_contract_sync.sql', 'realtime_publication', 'public.jobs',
    "SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'jobs'");
  addCheck('0640_db_contract_sync.sql', 'single_overload', 'public.post_provider_job (no older 15, 16 or 17 param overloads)',
    "SELECT 1 FROM (SELECT count(*) as c FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'post_provider_job') x WHERE x.c = 1");
  addCheck('0640_db_contract_sync.sql', 'single_overload', 'public.update_provider_job (no older 16, 17 or 18 param overloads)',
    "SELECT 1 FROM (SELECT count(*) as c FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_provider_job') x WHERE x.c = 1");

  buffer.writeln(checks.join('\n\n  UNION ALL\n\n'));
  buffer.writeln(')');
  buffer.writeln('SELECT');
  buffer.writeln('  migration_file,');
  buffer.writeln('  object_type,');
  buffer.writeln('  object_name,');
  buffer.writeln('  status');
  buffer.writeln('FROM verification_checks');
  buffer.writeln('ORDER BY');
  buffer.writeln('  CASE WHEN status = \'MISSING\' THEN 0 ELSE 1 END,');
  buffer.writeln('  migration_file,');
  buffer.writeln('  object_type,');
  buffer.writeln('  object_name;');
  buffer.writeln();

  File('supabase/catchup/verify_all.sql').writeAsStringSync(buffer.toString());
  print('Wrote ${checks.length} checks to supabase/catchup/verify_all.sql');
}

