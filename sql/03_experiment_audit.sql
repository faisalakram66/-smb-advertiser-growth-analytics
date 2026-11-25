-- =====================================================================
-- Case 3: Can we trust these three experiments?
-- Question: Before anyone reads the lift, are the tests valid?
-- Table:    experiments (one row per advertiser per experiment)
--           advertisers (for balance checks)
-- =====================================================================

-- 3.1 Headline numbers, exactly as a dashboard would show them
SELECT
    experiment_name,
    variant,
    COUNT(*)                                     AS advertisers,
    ROUND(100.0 * AVG(adopted_product), 1)       AS adoption_pct,
    ROUND(AVG(incremental_revenue_30d), 0)       AS avg_incremental_revenue,
    ROUND(100.0 * AVG(guardrail_opt_out), 1)     AS opt_out_pct
FROM experiments
GROUP BY experiment_name, variant
ORDER BY experiment_name, variant;

-- 3.2 Sample ratio mismatch (SRM): designed as 50/50
--     chi-square, 1 degree of freedom: above 3.84 fails at 5%, above 6.63 fails at 1%
SELECT
    experiment_name,
    COUNT(*) FILTER (WHERE variant = 'Treatment')                AS treatment,
    COUNT(*) FILTER (WHERE variant = 'Control')                  AS control,
    ROUND(100.0 * COUNT(*) FILTER (WHERE variant = 'Treatment') / COUNT(*), 1) AS treatment_share_pct,
    ROUND(
        2 * POWER(COUNT(*) FILTER (WHERE variant = 'Treatment') - COUNT(*) / 2.0, 2)
          / (COUNT(*) / 2.0), 2)                                 AS srm_chi_square
FROM experiments
GROUP BY experiment_name
ORDER BY srm_chi_square DESC;

-- 3.3 Where did the imbalance come from? Assignment windows by arm
SELECT
    experiment_name,
    variant,
    MIN(assignment_date) AS first_assigned,
    MAX(assignment_date) AS last_assigned
FROM experiments
GROUP BY experiment_name, variant
ORDER BY experiment_name, variant;

-- 3.4 Covariate balance: account tier mix by arm for the CAPI Onboarding Test
SELECT
    a.account_tier,
    COUNT(*) FILTER (WHERE e.variant = 'Treatment') AS treatment,
    COUNT(*) FILTER (WHERE e.variant = 'Control')   AS control
FROM experiments e
JOIN advertisers a USING (advertiser_id)
WHERE e.experiment_name = 'CAPI Onboarding Test'
GROUP BY a.account_tier
ORDER BY a.account_tier;

-- 3.5 The per-protocol trap: comparing only EXPOSED treatment advertisers.
--     Intent-to-treat keeps everyone assigned; dropping non-exposed advertisers
--     changes who is being compared.
SELECT
    experiment_name,
    ROUND(100.0 * AVG(adopted_product) FILTER (WHERE variant = 'Treatment'), 1)                  AS itt_treatment_pct,
    ROUND(100.0 * AVG(adopted_product) FILTER (WHERE variant = 'Treatment' AND exposed = 1), 1)  AS exposed_only_pct,
    ROUND(100.0 * AVG(adopted_product) FILTER (WHERE variant = 'Control'), 1)                    AS control_pct,
    COUNT(*) FILTER (WHERE variant = 'Treatment' AND exposed = 0)                                AS treated_not_exposed
FROM experiments
GROUP BY experiment_name
ORDER BY experiment_name;
