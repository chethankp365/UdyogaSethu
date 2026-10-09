-- ============================================================================
-- Migration 0511: Mandi Sync Daily Schedule via pg_cron & pg_net
-- Step: P6.1 (Daily Automated Mandi Sync)
-- NOTE: Per AGENTS.md rule, this migration file is authored for manual review.
-- Do NOT apply or run supabase db push automatically.
-- ============================================================================

-- REQUIRED EXTENSIONS TO ENABLE IN SUPABASE DASHBOARD:
-- 1. pg_cron (Settings -> Database -> Extensions -> pg_cron)
-- 2. pg_net (Settings -> Database -> Extensions -> pg_net)

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 1. Helper function to trigger internal mandi-sync edge function with service key authentication
-- Endpoint is protected and requires Bearer token; this function runs with SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.trigger_mandi_sync()
RETURNS VOID AS $$
DECLARE
  v_supabase_url TEXT;
  v_service_key TEXT;
  v_request_id BIGINT;
BEGIN
  -- Read internal project configuration from vault or settings
  SELECT decrypted_secret INTO v_service_key 
  FROM vault.decrypted_secrets 
  WHERE name = 'service_role_key' 
  LIMIT 1;

  -- Fallback to environment variable if configured
  IF v_service_key IS NULL THEN
    v_service_key := current_setting('app.settings.service_role_key', true);
  END IF;

  -- Supabase Project URL
  v_supabase_url := current_setting('app.settings.supabase_url', true);
  IF v_supabase_url IS NULL OR v_supabase_url = '' THEN
    v_supabase_url := 'https://mmzbpeqkfomnywuzoqii.supabase.co';
  END IF;

  -- Secure internal POST using pg_net (private network / auth header)
  IF v_service_key IS NOT NULL AND v_service_key <> '' THEN
    SELECT net.http_post(
      url := v_supabase_url || '/functions/v1/mandi-sync',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || v_service_key
      ),
      body := jsonb_build_object('action', 'scheduled_sync', 'state', 'Karnataka')
    ) INTO v_request_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- Revoke execute from public/anon/authenticated to prevent unauthorized execution
REVOKE ALL ON FUNCTION public.trigger_mandi_sync() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_mandi_sync() TO service_role, postgres;

-- 2. Schedule cron job:
-- Runs daily at 06:00 AM IST (00:30 UTC)
-- '30 0 * * *'
DO $$
BEGIN
  -- Unschedule existing job if previously registered
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'daily_mandi_sync') THEN
    PERFORM cron.unschedule('daily_mandi_sync');
  END IF;

  PERFORM cron.schedule(
    'daily_mandi_sync',
    '30 0 * * *',
    'SELECT public.trigger_mandi_sync();'
  );
END $$;
