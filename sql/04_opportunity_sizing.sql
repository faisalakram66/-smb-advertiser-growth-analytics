-- =====================================================================
-- Case 4: How big is the opportunity if we roll the education email
--         out to every eligible advertiser who has not adopted Advantage+?
-- Builds on: Case 1 (who the non-adopters are) and Case 2 (measured lift)
-- Tables:    advertisers, product_adoption, monthly_performance
-- =====================================================================

-- 4.1 Anchor "recent" to the data, not to today's date.
--     The data ends in Dec 2024; CURRENT_DATE - 3 months would return nothing.
SELECT MIN(month) AS first_month, MAX(month) AS last_month
FROM monthly_performance;

-- 4.2 Sizing by company size, with three lift scenarios from Case 2:
--       low  =  9.6 pts (lower bound of the 95% CI)
--       mid  = 29.4 pts (point estimate)
--     Spend is shrunk to ONE row per advertiser first, so the monthly table
--     cannot multiply rows (fan-out) when joined.
WITH last_3_months AS (
    SELECT advertiser_id,
           AVG(spend) AS avg_monthly_spend
    FROM monthly_performance
    WHERE month > (SELECT MAX(month) FROM monthly_performance) - INTERVAL '3 months'
    GROUP BY advertiser_id
),
non_adopters AS (
    SELECT a.advertiser_id, a.company_size
    FROM advertisers a
    LEFT JOIN product_adoption p
           ON p.advertiser_id = a.advertiser_id
          AND p.product_name  = 'Advantage+ Shopping'
    WHERE a.eligible_advantage_plus = 1
      AND (p.advertiser_id IS NULL OR p.adopted = 0)       -- no record OR not adopted
)
SELECT
    n.company_size,
    COUNT(*)                                             AS non_adopters,
    ROUND(SUM(COALESCE(s.avg_monthly_spend, 0)), 0)      AS monthly_spend_in_scope,
    ROUND(AVG(COALESCE(s.avg_monthly_spend, 0)), 0)      AS avg_monthly_spend,
    ROUND(COUNT(*) * 0.096, 1)                           AS new_adopters_low,
    ROUND(COUNT(*) * 0.294, 1)                           AS new_adopters_mid
FROM non_adopters n
LEFT JOIN last_3_months s USING (advertiser_id)
GROUP BY ROLLUP (n.company_size)
ORDER BY monthly_spend_in_scope DESC;

-- 4.3 Concentration: how much of the in-scope spend sits with the top 10 non-adopters?
--     Window function: running share of spend, highest spenders first.
WITH last_3_months AS (
    SELECT advertiser_id, AVG(spend) AS avg_monthly_spend
    FROM monthly_performance
    WHERE month > (SELECT MAX(month) FROM monthly_performance) - INTERVAL '3 months'
    GROUP BY advertiser_id
),
non_adopters AS (
    SELECT a.advertiser_id, a.company_size, COALESCE(s.avg_monthly_spend, 0) AS avg_monthly_spend
    FROM advertisers a
    LEFT JOIN product_adoption p
           ON p.advertiser_id = a.advertiser_id
          AND p.product_name  = 'Advantage+ Shopping'
    LEFT JOIN last_3_months s ON s.advertiser_id = a.advertiser_id
    WHERE a.eligible_advantage_plus = 1
      AND (p.advertiser_id IS NULL OR p.adopted = 0)
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY avg_monthly_spend DESC)              AS spend_rank,
           SUM(avg_monthly_spend) OVER (ORDER BY avg_monthly_spend DESC
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             / SUM(avg_monthly_spend) OVER ()                               AS running_share
    FROM non_adopters
)
SELECT spend_rank, advertiser_id, company_size,
       ROUND(avg_monthly_spend, 0)    AS avg_monthly_spend,
       ROUND(100 * running_share, 1)  AS cumulative_share_pct
FROM ranked
WHERE spend_rank <= 10
ORDER BY spend_rank;
