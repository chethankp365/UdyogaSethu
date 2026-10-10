-- ============================================================================
-- Migration: 0620_ledger_is_demo_and_savings_planner.sql
-- Dependencies:
--   - 0030_money_trust.sql (ledger_entries table & prevent_ledger_entry_mutation)
--   - 0040_engagement_admin.sql (savings_goals table)
--   - 0500_earnings_dashboard_savings_goals.sql (savings_goals enhancements & get_earnings_dashboard)
-- Description:
--   1. Adds is_demo flag to public.ledger_entries to separate demo seeds from real records.
--   2. Updates trigger & provides service-role cleanup function for demo ledger entries.
--   3. Adds monthly percentage and projected balance fields to savings_goals.
--   4. Enhances get_earnings_dashboard to provide 6-month average, best month,
--      trend versus last month, and category breakdown.
-- ============================================================================

-- 1. ADD is_demo COLUMN TO ledger_entries
ALTER TABLE public.ledger_entries
  ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_ledger_entries_is_demo
  ON public.ledger_entries (wallet_id, is_demo);

COMMENT ON COLUMN public.ledger_entries.is_demo IS
  'Flag indicating demo/seed ledger records. Must be excluded from admin totals and platform financial reports.';

-- 2. ENHANCE PREVENT MUTATION TRIGGER TO ALLOW SERVICE ROLE CLEANUP OF DEMO ENTRIES
CREATE OR REPLACE FUNCTION public.prevent_ledger_entry_mutation()
RETURNS TRIGGER AS $$
BEGIN
  -- Allow service_role to delete demo-flagged entries during test cleanup
  IF (TG_OP = 'DELETE' AND OLD.is_demo = true) THEN
    RETURN OLD;
  END IF;

  RAISE EXCEPTION 'Ledger entries are append-only. Updates and deletes are prohibited for audit safety.';
END;
$$ LANGUAGE plpgsql;

-- 3. SECURITY DEFINER FUNCTION FOR CLEANING DEMO WALLET HISTORY (Restricted to service_role)
CREATE OR REPLACE FUNCTION public.clean_demo_wallet_history(p_user_id UUID)
RETURNS INT AS $$
DECLARE
  v_wallet_id UUID;
  v_deleted_count INT := 0;
BEGIN
  SELECT id INTO v_wallet_id FROM public.wallets WHERE user_id = p_user_id;
  IF v_wallet_id IS NULL THEN
    RETURN 0;
  END IF;

  DELETE FROM public.ledger_entries
  WHERE wallet_id = v_wallet_id
    AND is_demo = true;

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.clean_demo_wallet_history(UUID) FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.clean_demo_wallet_history(UUID) TO service_role;

-- 4. ENHANCE savings_goals FOR MONTHLY PERCENTAGE AND PROJECTED SAVINGS (Prompt D5)
ALTER TABLE public.savings_goals
  ADD COLUMN IF NOT EXISTS monthly_percentage NUMERIC DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS target_type TEXT NOT NULL DEFAULT 'target_amount',
  ADD COLUMN IF NOT EXISTS monthly_saving_needed_paise BIGINT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS projected_balance_paise BIGINT NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'savings_goals_target_type_check'
  ) THEN
    ALTER TABLE public.savings_goals
      ADD CONSTRAINT savings_goals_target_type_check CHECK (
        target_type IN ('target_amount', 'monthly_percentage')
      );
  END IF;
END $$;

-- 5. ENHANCED get_earnings_dashboard RPC (Prompt D5)
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
  v_last_month_paise BIGINT := 0;
  v_total_paise BIGINT := 0;
  v_completed_jobs INT := 0;
  v_completed_orders INT := 0;
  v_rating NUMERIC := 5.0;
  v_daily_goal_paise BIGINT := 150000;
  v_daily_trends JSONB := '[]'::jsonb;
  v_monthly_trends JSONB := '[]'::jsonb;
  v_best_day JSONB := NULL;
  v_best_month JSONB := NULL;
  v_category_split JSONB := '[]'::jsonb;
  v_monthly_average_paise BIGINT := 0;
  v_trend_vs_last_month_pct NUMERIC := 0.0;
  v_recent_avg_daily BIGINT := 0;
  v_7d_total BIGINT := 0;
  v_6m_sum BIGINT := 0;
  v_6m_count INT := 0;
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

  -- 2. Average rating
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

  -- 4. Completed orders count
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

    -- This week's earnings
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

    -- Last month's earnings (for trend calculation)
    SELECT COALESCE(SUM(l.amount_paise), 0)
    INTO v_last_month_paise
    FROM public.ledger_entries l
    WHERE l.wallet_id = v_wallet_id
      AND l.direction = 'credit'
      AND l.bucket = 'available'
      AND l.created_at >= date_trunc('month', NOW() - interval '1 month')
      AND l.created_at < date_trunc('month', NOW());

    IF v_last_month_paise > 0 THEN
      v_trend_vs_last_month_pct := ROUND(((v_month_paise - v_last_month_paise)::NUMERIC / v_last_month_paise::NUMERIC) * 100.0, 1);
    ELSE
      v_trend_vs_last_month_pct := CASE WHEN v_month_paise > 0 THEN 100.0 ELSE 0.0 END;
    END IF;

    -- Total earnings
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

    -- 7. Monthly trend series for past 6 months (D5)
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

    -- 8. 6-Month Average & Best Month (D5)
    SELECT
      COALESCE(SUM(me.total_paise), 0),
      COUNT(me.total_paise)
    INTO v_6m_sum, v_6m_count
    FROM (
      SELECT SUM(l.amount_paise) AS total_paise
      FROM public.ledger_entries l
      WHERE l.wallet_id = v_wallet_id
        AND l.direction = 'credit'
        AND l.bucket = 'available'
        AND l.created_at >= date_trunc('month', NOW() - interval '5 months')
      GROUP BY date_trunc('month', l.created_at)
    ) me;

    v_monthly_average_paise := CASE WHEN v_6m_count > 0 THEN v_6m_sum / 6 ELSE 0 END;

    -- Best Month
    SELECT jsonb_build_object(
      'month', to_char(mth, 'YYYY-MM'),
      'month_label', to_char(mth, 'Mon YYYY'),
      'earnings_paise', total_paise
    )
    INTO v_best_month
    FROM (
      SELECT
        date_trunc('month', l.created_at)::date AS mth,
        SUM(l.amount_paise) AS total_paise
      FROM public.ledger_entries l
      WHERE l.wallet_id = v_wallet_id
        AND l.direction = 'credit'
        AND l.bucket = 'available'
      GROUP BY 1
      ORDER BY 2 DESC, 1 DESC
      LIMIT 1
    ) bm;

    -- Best Day
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

    -- 9. Category Split (D5)
    SELECT COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'category', cat.category_name,
          'earnings_paise', cat.total_paise,
          'percentage', CASE WHEN v_total_paise > 0 THEN ROUND((cat.total_paise::NUMERIC / v_total_paise::NUMERIC) * 100.0, 1) ELSE 0 END
        ) ORDER BY cat.total_paise DESC
      ),
      '[]'::jsonb
    )
    INTO v_category_split
    FROM (
      SELECT
        CASE
          WHEN l.ref_type IN ('order', 'produce_order') OR l.note ILIKE '%Produce%' THEN 'Farm Produce'
          WHEN l.ref_type = 'job_assignment' OR l.note ILIKE '%Wage%' THEN 'Daily Wages'
          WHEN l.bucket = 'reward' OR l.note ILIKE '%Reward%' THEN 'Rewards'
          WHEN l.ref_type = 'refund' OR l.note ILIKE '%Refund%' THEN 'Refunds'
          ELSE 'Other Tasks'
        END AS category_name,
        SUM(l.amount_paise) AS total_paise
      FROM public.ledger_entries l
      WHERE l.wallet_id = v_wallet_id
        AND l.direction = 'credit'
        AND l.bucket = 'available'
      GROUP BY 1
    ) cat;

    -- 10. Recent 7-day average daily earnings
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
    'last_month_earnings_paise', v_last_month_paise,
    'total_earnings_paise', v_total_paise,
    'completed_jobs_count', v_completed_jobs,
    'completed_orders_count', v_completed_orders,
    'average_rating', v_rating,
    'daily_goal_paise', v_daily_goal_paise,
    'best_day', v_best_day,
    'best_month', v_best_month,
    'daily_trends', v_daily_trends,
    'monthly_trends', v_monthly_trends,
    'monthly_average_paise', v_monthly_average_paise,
    'trend_vs_last_month_pct', v_trend_vs_last_month_pct,
    'category_split', v_category_split,
    'recent_avg_daily_earnings_paise', v_recent_avg_daily
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_earnings_dashboard(INT) TO authenticated;
