-- ============================================================================
-- Migration: 0654_earnings_and_farmer.sql
-- Description: Earnings analytics, job history, and farmer profile sync
--              written strictly against real inventory columns.
-- ============================================================================

-- 1. DROP ALL EXISTING OVERLOADS BY NAME
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
      AND p.proname IN ('get_earnings_dashboard', 'get_job_history')
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
  END LOOP;
END $$;

-- 2. ENSURE FARMER PROFILES COLUMNS AND BACKFILL (ZERO DATA LOSS)
ALTER TABLE public.farmer_profiles
  ADD COLUMN IF NOT EXISTS delivery_radius_km NUMERIC(5,1) DEFAULT 25.0,
  ADD COLUMN IF NOT EXISTS pickup_available BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS lead_time_hours INT DEFAULT 24,
  ADD COLUMN IF NOT EXISTS farm_photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS organic_cert_number TEXT DEFAULT NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'farmer_profiles' AND column_name = 'delivery_options'
  ) THEN
    UPDATE public.farmer_profiles
    SET 
      delivery_radius_km = COALESCE(
        delivery_radius_km,
        NULLIF(delivery_options->>'delivery_radius_km', '')::NUMERIC,
        25.0
      ),
      pickup_available = COALESCE(
        pickup_available,
        (delivery_options->>'pickup_available')::BOOLEAN,
        true
      )
    WHERE delivery_options IS NOT NULL AND delivery_radius_km IS NULL;
  END IF;
END $$;

-- 3. get_earnings_dashboard (ONE version, real columns, real ledger entries)
CREATE OR REPLACE FUNCTION public.get_earnings_dashboard(p_days INT DEFAULT 14)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID; v_wallet_id UUID; v_goal BIGINT; v_rating NUMERIC;
  v_today_paise BIGINT := 0; v_week_paise BIGINT := 0; v_month_paise BIGINT := 0;
  v_last_month_paise BIGINT := 0; v_total_paise BIGINT := 0;
  v_jobs_count INT := 0; v_orders_count INT := 0;
  v_daily_trends JSONB := '[]'::JSONB;
  v_monthly_trends JSONB := '[]'::JSONB;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_uid;
  SELECT daily_earnings_goal_paise INTO v_goal FROM public.profiles WHERE id = v_uid;
  SELECT rating_avg INTO v_rating FROM public.worker_profiles WHERE user_id = v_uid;

  v_goal := COALESCE(v_goal, 150000);

  IF v_wallet_id IS NOT NULL THEN
    -- Real ledger sums
    SELECT
      COALESCE(SUM(CASE WHEN created_at >= CURRENT_DATE THEN amount_paise ELSE 0 END), 0),
      COALESCE(SUM(CASE WHEN created_at >= date_trunc('week', CURRENT_DATE) THEN amount_paise ELSE 0 END), 0),
      COALESCE(SUM(CASE WHEN created_at >= date_trunc('month', CURRENT_DATE) THEN amount_paise ELSE 0 END), 0),
      COALESCE(SUM(CASE WHEN created_at >= (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month') 
                          AND created_at < date_trunc('month', CURRENT_DATE) THEN amount_paise ELSE 0 END), 0),
      COALESCE(SUM(amount_paise), 0)
    INTO v_today_paise, v_week_paise, v_month_paise, v_last_month_paise, v_total_paise
    FROM public.ledger_entries
    WHERE wallet_id = v_wallet_id AND direction = 'credit';

    -- Daily trends for the requested period
    SELECT COALESCE(jsonb_agg(d_row), '[]'::JSONB) INTO v_daily_trends
    FROM (
      SELECT
        to_char(day_series, 'YYYY-MM-DD') AS date,
        COALESCE(SUM(le.amount_paise), 0) AS earnings_paise,
        0.0 AS hours,
        COUNT(le.id)::INT AS jobs_count
      FROM generate_series(CURRENT_DATE - (p_days || ' days')::INTERVAL, CURRENT_DATE, '1 day'::INTERVAL) day_series
      LEFT JOIN public.ledger_entries le ON le.wallet_id = v_wallet_id 
        AND le.direction = 'credit' 
        AND date_trunc('day', le.created_at) = day_series
      GROUP BY day_series ORDER BY day_series ASC
    ) d_row;

    -- Monthly trends (last 6 months)
    SELECT COALESCE(jsonb_agg(m_row), '[]'::JSONB) INTO v_monthly_trends
    FROM (
      SELECT
        to_char(m_series, 'YYYY-MM') AS month,
        COALESCE(SUM(le.amount_paise), 0) AS earnings_paise,
        COUNT(le.id)::INT AS jobs_count
      FROM generate_series(date_trunc('month', CURRENT_DATE) - INTERVAL '5 months', date_trunc('month', CURRENT_DATE), '1 month'::INTERVAL) m_series
      LEFT JOIN public.ledger_entries le ON le.wallet_id = v_wallet_id 
        AND le.direction = 'credit' 
        AND date_trunc('month', le.created_at) = m_series
      GROUP BY m_series ORDER BY m_series ASC
    ) m_row;
  END IF;

  -- Completed assignments count from job_assignments
  SELECT COUNT(*)::INT INTO v_jobs_count
  FROM public.job_assignments
  WHERE worker_id = v_uid AND status IN ('completed', 'payment_released');

  -- Completed orders count for farmers
  SELECT COUNT(*)::INT INTO v_orders_count
  FROM public.orders
  WHERE farmer_id = v_uid AND status = 'delivered';

  RETURN jsonb_build_object(
    'today_earnings_paise', v_today_paise,
    'this_week_earnings_paise', v_week_paise,
    'this_month_earnings_paise', v_month_paise,
    'last_month_earnings_paise', v_last_month_paise,
    'total_earnings_paise', v_total_paise,
    'completed_jobs_count', v_jobs_count,
    'completed_orders_count', v_orders_count,
    'average_rating', v_rating,
    'daily_goal_paise', v_goal,
    'daily_trends', v_daily_trends,
    'monthly_trends', v_monthly_trends,
    'monthly_average_paise', CASE WHEN v_month_paise > 0 THEN v_month_paise ELSE 0 END,
    'recent_avg_daily_earnings_paise', CASE WHEN p_days > 0 THEN v_total_paise / p_days ELSE 0 END
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 4. get_job_history (ONE version, real columns: started_at, ended_at, real profiles)
CREATE OR REPLACE FUNCTION public.get_job_history(
  p_status TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
)
RETURNS TABLE (
  assignment_id UUID, job_id UUID, title TEXT, description TEXT,
  wage_paise BIGINT, agreed_wage_paise BIGINT, status TEXT,
  start_time TIMESTAMPTZ, completed_at TIMESTAMPTZ, created_at TIMESTAMPTZ,
  category_slug TEXT, category_name TEXT, area TEXT,
  counterparty_id UUID, counterparty_name TEXT, counterparty_avatar TEXT,
  counterparty_role TEXT, counterparty_verified BOOLEAN, is_favourite BOOLEAN,
  can_review BOOLEAN, can_dispute BOOLEAN, can_rebook BOOLEAN
) AS $$
DECLARE
  v_uid UUID;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN RETURN; END IF;

  RETURN QUERY
  SELECT
    ja.id AS assignment_id,
    j.id AS job_id,
    j.title,
    j.description,
    j.wage_paise,
    ja.agreed_wage_paise,
    ja.status::TEXT AS status,
    ja.started_at AS start_time,
    ja.ended_at AS completed_at,
    ja.created_at,
    COALESCE(sc.slug, 'general')::TEXT AS category_slug,
    COALESCE(sc.names->>'en', 'General')::TEXT AS category_name,
    COALESCE(j.address_text, 'Bengaluru')::TEXT AS area,
    CASE WHEN v_uid = ja.worker_id THEN j.provider_id ELSE ja.worker_id END AS counterparty_id,
    CASE WHEN v_uid = ja.worker_id THEN COALESCE(pp.full_name, 'Employer') ELSE COALESCE(wp.full_name, 'Worker') END::TEXT AS counterparty_name,
    CASE WHEN v_uid = ja.worker_id THEN pp.avatar_path ELSE wp.avatar_path END::TEXT AS counterparty_avatar,
    CASE WHEN v_uid = ja.worker_id THEN 'provider' ELSE 'worker' END::TEXT AS counterparty_role,
    false AS counterparty_verified,
    false AS is_favourite,
    (ja.status IN ('completed', 'payment_released')) AS can_review,
    (ja.status IN ('completed', 'in_progress_verified', 'arrived')) AS can_dispute,
    (ja.status IN ('completed', 'payment_released')) AS can_rebook
  FROM public.job_assignments ja
  JOIN public.jobs j ON ja.job_id = j.id
  LEFT JOIN public.service_categories sc ON j.category_id = sc.id
  JOIN public.profiles wp ON ja.worker_id = wp.id
  JOIN public.profiles pp ON j.provider_id = pp.id
  WHERE (ja.worker_id = v_uid OR j.provider_id = v_uid)
    AND (p_status IS NULL OR ja.status::TEXT = p_status)
  ORDER BY ja.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions;

-- 5. PERMISSIONS & GRANTS
GRANT EXECUTE ON FUNCTION public.get_earnings_dashboard(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_job_history(TEXT, INT, INT) TO authenticated;

-- Verification query
SELECT proname, pg_get_function_identity_arguments(oid) AS args
FROM pg_proc WHERE pronamespace = 'public'::regnamespace
  AND proname IN ('get_earnings_dashboard', 'get_job_history');

NOTIFY pgrst, 'reload schema';
