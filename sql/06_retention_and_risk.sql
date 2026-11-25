-- =====================================================================
-- Case 6: Are advertisers sticking around, and can we spot who is about to leave?
-- Questions: (a) What does monthly retention look like by signup cohort?
--            (b) Who stopped spending, and did our lifecycle label see it coming?
-- Tables:    advertisers, monthly_performance (one row per advertiser per month)
-- =====================================================================

-- 6.1 Cohort retention: % of each signup cohort active 1, 2, 3 months after signup.
--     Trap: a month that is not in the data yet is NOT 0% retention. It is unknown.
--     The CASE returns NULL when the month falls after the last month of data.
WITH cohorts AS (
    SELECT advertiser_id, TO_DATE(signup_month, 'YYYY-MM') AS cohort_month
    FROM advertisers
),
bounds AS (
    SELECT MAX(month) AS last_month FROM monthly_performance
),
retention AS (
    SELECT
        c.cohort_month,
        k.months_after,
        COUNT(DISTINCT c.advertiser_id)                                    AS cohort_size,
        COUNT(DISTINCT m.advertiser_id)                                    AS active
    FROM cohorts c
    CROSS JOIN (VALUES (1), (2), (3)) AS k(months_after)
    LEFT JOIN monthly_performance m
           ON m.advertiser_id   = c.advertiser_id
          AND m.month           = c.cohort_month + make_interval(months => k.months_after)
          AND m.active_in_month = 1
    GROUP BY c.cohort_month, k.months_after
)
SELECT
    r.cohort_month,
    MAX(r.cohort_size) AS cohort_size,
    MAX(CASE WHEN r.months_after = 1 AND r.cohort_month + INTERVAL '1 month' <= b.last_month
             THEN ROUND(100.0 * r.active / r.cohort_size, 1) END) AS month_1_pct,
    MAX(CASE WHEN r.months_after = 2 AND r.cohort_month + INTERVAL '2 months' <= b.last_month
             THEN ROUND(100.0 * r.active / r.cohort_size, 1) END) AS month_2_pct,
    MAX(CASE WHEN r.months_after = 3 AND r.cohort_month + INTERVAL '3 months' <= b.last_month
             THEN ROUND(100.0 * r.active / r.cohort_size, 1) END) AS month_3_pct
FROM retention r
CROSS JOIN bounds b
GROUP BY r.cohort_month
ORDER BY r.cohort_month;

-- 6.2 Who went dark? Advertisers whose spend fell 50% or more vs their own previous month.
--     LAG runs on the full history first; the month filter is applied afterwards,
--     otherwise the first month in the window has no previous month to compare to.
WITH with_prev AS (
    SELECT
        advertiser_id,
        month,
        spend,
        LAG(spend) OVER (PARTITION BY advertiser_id ORDER BY month) AS prev_spend
    FROM monthly_performance
)
SELECT
    month,
    COUNT(*) FILTER (WHERE prev_spend > 0)                              AS spending_last_month,
    COUNT(*) FILTER (WHERE prev_spend > 0 AND spend <= 0.5 * prev_spend) AS dropped_50pct_plus,
    COUNT(*) FILTER (WHERE prev_spend > 0 AND spend = 0)                AS went_to_zero,
    ROUND(100.0 * COUNT(*) FILTER (WHERE prev_spend > 0 AND spend <= 0.5 * prev_spend)
          / NULLIF(COUNT(*) FILTER (WHERE prev_spend > 0), 0), 1)       AS drop_rate_pct
FROM with_prev
WHERE month >= '2024-09-01'
GROUP BY month
ORDER BY month;

-- 6.3 Did the CRM lifecycle label predict December drop-offs?
WITH with_prev AS (
    SELECT advertiser_id, month, spend,
           LAG(spend) OVER (PARTITION BY advertiser_id ORDER BY month) AS prev_spend
    FROM monthly_performance
)
SELECT
    a.lifecycle_stage,
    COUNT(*)                                                     AS spending_in_nov,
    COUNT(*) FILTER (WHERE w.spend <= 0.5 * w.prev_spend)        AS dropped_in_dec,
    ROUND(100.0 * COUNT(*) FILTER (WHERE w.spend <= 0.5 * w.prev_spend) / COUNT(*), 1) AS drop_rate_pct
FROM with_prev w
JOIN advertisers a USING (advertiser_id)
WHERE w.month = '2024-12-01'
  AND w.prev_spend > 0
GROUP BY a.lifecycle_stage
ORDER BY dropped_in_dec DESC;

-- 6.4 Do advertisers come back? Months with zero spend followed by spend again
WITH flagged AS (
    SELECT advertiser_id, month, spend,
           LAG(spend)  OVER (PARTITION BY advertiser_id ORDER BY month) AS prev_spend,
           LEAD(spend) OVER (PARTITION BY advertiser_id ORDER BY month) AS next_spend
    FROM monthly_performance
)
SELECT
    COUNT(*) FILTER (WHERE spend = 0 AND prev_spend > 0)                     AS went_dark,
    COUNT(*) FILTER (WHERE spend = 0 AND prev_spend > 0 AND next_spend > 0)  AS came_back_next_month,
    COUNT(*) FILTER (WHERE spend = 0 AND prev_spend > 0 AND next_spend IS NULL) AS too_recent_to_tell
FROM flagged;
