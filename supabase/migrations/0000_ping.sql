-- Migration: 0000_ping.sql
-- Harmless ping function returning server time and version

CREATE OR REPLACE FUNCTION public.ping()
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT jsonb_build_object(
    'status', 'ok',
    'server_time', now(),
    'postgres_version', version()
  );
$$;

-- Grant permissions to anon and authenticated roles
GRANT EXECUTE ON FUNCTION public.ping() TO anon, authenticated;
