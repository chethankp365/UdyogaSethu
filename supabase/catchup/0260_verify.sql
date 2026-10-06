-- Read-Only Schema Verification Script: 0260_verify.sql
-- Description: Read-only verification query checking every table, column, function,
--              enum value, policy, and trigger introduced or modified by migrations 0200 to 0250.
-- Output: Returns one row per checked object with columns:
--         migration_file, object_type, object_name, status ('OK' or 'MISSING')
-- Sorting: MISSING rows appear FIRST so any schema discrepancy is immediately obvious.

WITH verification_checks AS (
  -- 0200_privacy_consent.sql
  SELECT 
    '0200_privacy_consent.sql' AS migration_file,
    'function' AS object_type,
    'public.revoke_consent(text)' AS object_name,
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname = 'public' AND p.proname = 'revoke_consent'
    ) THEN 'OK' ELSE 'MISSING' END AS status

  UNION ALL

  SELECT 
    '0200_privacy_consent.sql', 'function', 'public.withdraw_face_consent()',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname = 'public' AND p.proname = 'withdraw_face_consent'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  -- 0210_verification_extra.sql
  SELECT 
    '0210_verification_extra.sql', 'column', 'public.service_categories.requires_licence',
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'service_categories' AND column_name = 'requires_licence'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0210_verification_extra.sql', 'enum_value', 'public.doc_type: student_id',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid 
      WHERE n.nspname = 'public' AND t.typname = 'doc_type' AND e.enumlabel = 'student_id'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0210_verification_extra.sql', 'enum_value', 'public.doc_type: bank_account',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid 
      WHERE n.nspname = 'public' AND t.typname = 'doc_type' AND e.enumlabel = 'bank_account'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0210_verification_extra.sql', 'enum_value', 'public.doc_type: upi',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid JOIN pg_namespace n ON t.typnamespace = n.oid 
      WHERE n.nspname = 'public' AND t.typname = 'doc_type' AND e.enumlabel = 'upi'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0210_verification_extra.sql', 'function', 'public.nearby_jobs_for_worker(...)',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname = 'public' AND p.proname = 'nearby_jobs_for_worker'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  -- 0220_face_embedding.sql
  SELECT 
    '0220_face_embedding.sql', 'column', 'public.face_profiles.embedding',
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'face_profiles' AND column_name = 'embedding'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0220_face_embedding.sql', 'function', 'public.compare_face_embeddings(...)',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname = 'public' AND p.proname = 'compare_face_embeddings'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0220_face_embedding.sql', 'function', 'public.save_face_embedding(...)',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname = 'public' AND p.proname = 'save_face_embedding'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  -- 0230_verification_visibility_guard.sql
  SELECT 
    '0230_verification_visibility_guard.sql', 'function', 'public.check_kyc_record_visibility()',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname = 'public' AND p.proname = 'check_kyc_record_visibility'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0230_verification_visibility_guard.sql', 'trigger', 'public.kyc_records: trg_check_kyc_record_visibility',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_trigger tr JOIN pg_class c ON tr.tgrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid 
      WHERE n.nspname = 'public' AND c.relname = 'kyc_records' AND tr.tgname = 'trg_check_kyc_record_visibility'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  -- 0240_sync_avatar_paths.sql
  SELECT 
    '0240_sync_avatar_paths.sql', 'column', 'public.profiles.avatar_path',
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'avatar_path'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  -- 0250_face_verify_settings.sql
  SELECT 
    '0250_face_verify_settings.sql', 'setting_seed', 'admin_settings.key: face_match_threshold',
    CASE WHEN EXISTS (
      SELECT 1 FROM public.admin_settings WHERE key = 'face_match_threshold'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0250_face_verify_settings.sql', 'rls_enabled', 'public.admin_settings',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid 
      WHERE n.nspname = 'public' AND c.relname = 'admin_settings' AND c.relrowsecurity = true
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0250_face_verify_settings.sql', 'rls_enabled', 'public.verification_attempts',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid 
      WHERE n.nspname = 'public' AND c.relname = 'verification_attempts' AND c.relrowsecurity = true
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0250_face_verify_settings.sql', 'rls_enabled', 'public.fraud_flags',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid 
      WHERE n.nspname = 'public' AND c.relname = 'fraud_flags' AND c.relrowsecurity = true
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0250_face_verify_settings.sql', 'rls_enabled', 'public.face_profiles',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid 
      WHERE n.nspname = 'public' AND c.relname = 'face_profiles' AND c.relrowsecurity = true
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0250_face_verify_settings.sql', 'rls_enabled', 'public.kyc_records',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid 
      WHERE n.nspname = 'public' AND c.relname = 'kyc_records' AND c.relrowsecurity = true
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0250_face_verify_settings.sql', 'policy', 'public.admin_settings: admin_settings_select',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'admin_settings' AND policyname = 'admin_settings_select'
    ) THEN 'OK' ELSE 'MISSING' END

  UNION ALL

  SELECT 
    '0250_face_verify_settings.sql', 'function', 'public.get_face_login_requirement()',
    CASE WHEN EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
      WHERE n.nspname = 'public' AND p.proname = 'get_face_login_requirement'
    ) THEN 'OK' ELSE 'MISSING' END
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
