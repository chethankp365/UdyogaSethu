-- ============================================================================
-- Migration 0500: Earnings Dashboard, SQL Aggregates & Savings Goal Planner
-- Features: #54 (Earnings & Performance Dashboard), #83 (Savings Goal Planner)
-- ============================================================================

-- 1. Add daily_earnings_goal_paise column to profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS daily_earnings_goal_paise BIGINT NOT NULL DEFAULT 150000;

-- 2. Enhance savings_goals (Virtual goal tracker - does not lock money)
-- Table savings_goals was created in migration 0040. We add category, is_completed, updated_at.
ALTER TABLE public.savings_goals
  ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'custom',
  ADD COLUMN IF NOT EXISTS is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'savings_goals_category_check'
  ) THEN
    ALTER TABLE public.savings_goals
      ADD CONSTRAINT savings_goals_category_check CHECK (
        category IN (
          'school_fees',
          'equipment',
          'scooter',
          'seeds',
          'emergency_fund',
          'home_improvement',
          'custom'
        )
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_savings_goals_user ON public.savings_goals (user_id, is_completed);
CREATE INDEX IF NOT EXISTS idx_savings_goals_created ON public.savings_goals (created_at DESC);

ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS savings_goals_select ON public.savings_goals;
CREATE POLICY savings_goals_select ON public.savings_goals
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS savings_goals_insert ON public.savings_goals;
CREATE POLICY savings_goals_insert ON public.savings_goals
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS savings_goals_update ON public.savings_goals;
CREATE POLICY savings_goals_update ON public.savings_goals
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS savings_goals_delete ON public.savings_goals;
CREATE POLICY savings_goals_delete ON public.savings_goals
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- 3. SQL View / RPC: get_earnings_dashboard
-- Sourced strictly from ledger_entries; no client-side summing of long histories.
CREATE OR REPLACE FUNCTION public.get_earnings_dashboard(
  p_days INT DEFAULT 14
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_wallet_id UUID;
  v_today_paise BIGINT := 0;
  v_week_paise BIGINT := 0;
  v_month_paise BIGINT := 0;
  v_total_paise BIGINT := 0;
  v_completed_jobs INT := 0;
  v_completed_orders INT := 0;
  v_rating NUMERIC := 5.0;
  v_daily_goal_paise BIGINT := 150000;
  v_daily_trends JSONB := '[]'::jsonb;
  v_monthly_trends JSONB := '[]'::jsonb;
  v_best_day JSONB := NULL;
  v_recent_avg_daily BIGINT := 0;
  v_7d_total BIGINT := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = v_uid;

  -- 1. Daily goal from profiles
  SELECT COALESCE(daily_earnings_goal_paise, 150000)
  INTO v_daily_goal_paise
  FROM public.profiles
  WHERE id = v_uid;

  -- 2. Average rating across worker and farmer profiles
  SELECT COALESCE(
    (SELECT rating_avg FROM public.worker_profiles WHERE user_id = v_uid),
    (SELECT rating_avg FROM public.farmer_profiles WHERE user_id = v_uid),
    5.0
  ) INTO v_rating;

  -- 3. Completed jobs count
  SELECT COUNT(*)
  INTO v_completed_jobs
  FROM public.job_assignments
  WHERE worker_id = v_uid
    AND status IN ('completed', 'payment_released');

  -- 4. Completed orders count (Phase 6 / marketplace produce)
  BEGIN
    SELECT COUNT(*)
    INTO v_completed_orders
    FROM public.orders
    WHERE seller_id = v_uid
      AND status = 'delivered';
  EXCEPTION WHEN undefined_table THEN
    v_completed_orders := 0;
  END;

  -- 5. Wallet ledger-backed aggregates
  IF v_wallet_id IS NOT NULL THEN
    -- Today's earnings
    SELECT COALESCE(SUM(l.amount_paise), 0)
    INTO v_today_paise
    FROM public.ledger_entries l
    WHERE l.wallet_id = v_wallet_id
      AND l.direction = 'credit'
      AND l.bucket = 'available'
      AND l.created_at >= date_trunc('day', NOW());

    -- This week's earnings (starting Monday)
    SELECT COALESCE(SUM(l.amount_paise), 0)
    INTO v_week_paise
    FROM public.ledger_entries l
    WHERE l.wallet_id = v_wallet_id
      AND l.direction = 'credit'
      AND l.bucket = 'available'
      AND l.created_at >= date_trunc('week', NOW());

    -- This month's earnings
    SELECT COALESCE(SUM(l.amount_paise), 0)
    INTO v_month_paise
    FROM public.ledger_entries l
    WHERE l.wallet_id = v_wallet_id
      AND l.direction = 'credit'
      AND l.bucket = 'available'
      AND l.created_at >= date_trunc('month', NOW());

    -- Total earnings: matches wallet transactions list totals exactly
    SELECT COALESCE(SUM(l.amount_paise), 0)
    INTO v_total_paise
    FROM public.ledger_entries l
    WHERE l.wallet_id = v_wallet_id
      AND l.direction = 'credit'
      AND l.bucket = 'available';

    -- 6. Daily trend series for the past p_days
    SELECT COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'date', d.dt::text,
          'earnings_paise', COALESCE(e.total_paise, 0),
          'jobs_count', COALESCE(e.job_count, 0)
        ) ORDER BY d.dt ASC
      ),
      '[]'::jsonb
    )
    INTO v_daily_trends
    FROM generate_series(
      (CURRENT_DATE - (GREATEST(7, p_days) - 1)),
      CURRENT_DATE,
      interval '1 day'
    ) AS d(dt)
    LEFT JOIN (
      SELECT
        date_trunc('day', l.created_at)::date AS dt,
        SUM(l.amount_paise) AS total_paise,
        COUNT(*) AS job_count
      FROM public.ledger_entries l
      WHERE l.wallet_id = v_wallet_id
        AND l.direction = 'credit'
        AND l.bucket = 'available'
      GROUP BY 1
    ) e ON d.dt::date = e.dt;

    -- 7. Monthly trend series for past 6 months
    SELECT COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'month', to_char(m.mth, 'YYYY-MM'),
          'month_label', to_char(m.mth, 'Mon YYYY'),
          'earnings_paise', COALESCE(me.total_paise, 0)
        ) ORDER BY m.mth ASC
      ),
      '[]'::jsonb
    )
    INTO v_monthly_trends
    FROM generate_series(
      date_trunc('month', NOW() - interval '5 months'),
      date_trunc('month', NOW()),
      interval '1 month'
    ) AS m(mth)
    LEFT JOIN (
      SELECT
        date_trunc('month', l.created_at)::date AS mth,
        SUM(l.amount_paise) AS total_paise
      FROM public.ledger_entries l
      WHERE l.wallet_id = v_wallet_id
        AND l.direction = 'credit'
        AND l.bucket = 'available'
      GROUP BY 1
    ) me ON m.mth::date = me.mth;

    -- 8. Best day insight
    SELECT jsonb_build_object(
      'date', dt::text,
      'earnings_paise', total_paise
    )
    INTO v_best_day
    FROM (
      SELECT
        date_trunc('day', l.created_at)::date AS dt,
        SUM(l.amount_paise) AS total_paise
      FROM public.ledger_entries l
      WHERE l.wallet_id = v_wallet_id
        AND l.direction = 'credit'
        AND l.bucket = 'available'
      GROUP BY 1
      ORDER BY 2 DESC, 1 DESC
      LIMIT 1
    ) best;

    -- 9. Recent 7-day average daily earnings for goal planner suggestions
    SELECT COALESCE(SUM(l.amount_paise), 0)
    INTO v_7d_total
    FROM public.ledger_entries l
    WHERE l.wallet_id = v_wallet_id
      AND l.direction = 'credit'
      AND l.bucket = 'available'
      AND l.created_at >= (NOW() - interval '7 days');

    v_recent_avg_daily := v_7d_total / 7;
  END IF;

  RETURN jsonb_build_object(
    'today_earnings_paise', v_today_paise,
    'this_week_earnings_paise', v_week_paise,
    'this_month_earnings_paise', v_month_paise,
    'total_earnings_paise', v_total_paise,
    'completed_jobs_count', v_completed_jobs,
    'completed_orders_count', v_completed_orders,
    'average_rating', v_rating,
    'daily_goal_paise', v_daily_goal_paise,
    'best_day', v_best_day,
    'daily_trends', v_daily_trends,
    'monthly_trends', v_monthly_trends,
    'recent_avg_daily_earnings_paise', v_recent_avg_daily
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_earnings_dashboard(INT) TO authenticated;

-- 4. RPC: update_daily_earnings_goal
CREATE OR REPLACE FUNCTION public.update_daily_earnings_goal(
  p_goal_paise BIGINT
)
RETURNS BIGINT AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;
  IF p_goal_paise <= 0 THEN
    RAISE EXCEPTION 'Daily goal must be greater than zero.';
  END IF;

  UPDATE public.profiles
  SET daily_earnings_goal_paise = p_goal_paise,
      updated_at = NOW()
  WHERE id = v_uid;

  RETURN p_goal_paise;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.update_daily_earnings_goal(BIGINT) TO authenticated;

-- 5. RPC: allocate_savings_goal
CREATE OR REPLACE FUNCTION public.allocate_savings_goal(
  p_goal_id UUID,
  p_amount_paise BIGINT
)
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_goal public.savings_goals%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT * INTO v_goal
  FROM public.savings_goals
  WHERE id = p_goal_id AND user_id = v_uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Savings goal not found.';
  END IF;

  UPDATE public.savings_goals
  SET saved_paise = GREATEST(0, saved_paise + p_amount_paise),
      is_completed = (GREATEST(0, saved_paise + p_amount_paise) >= target_paise),
      updated_at = NOW()
  WHERE id = p_goal_id
  RETURNING * INTO v_goal;

  RETURN to_jsonb(v_goal);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.allocate_savings_goal(UUID, BIGINT) TO authenticated;
