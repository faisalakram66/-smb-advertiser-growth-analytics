-- =====================================================================
-- Case 2: Experiment readout for an Advantage+ education email (EDU_120)
-- Question: Did the email cause more eligible advertisers to adopt
--           Advantage+ within 14 days, and at what cost to guardrails?
-- Table:    advertiser_experiment (one row per advertiser, randomized 60/60)
-- =====================================================================

-- 2.1 Sanity checks before reading any result: group sizes and delivery
SELECT
    variant,
    COUNT(*)                     AS advertisers,
    SUM(email_delivered)         AS emails_delivered,
    SUM(baseline_eligible)       AS eligible_at_baseline,
    SUM(baseline_adopter)        AS already_adopted_at_baseline
FROM advertiser_experiment
GROUP BY variant
ORDER BY variant;

-- 2.2 Sample ratio check: a 60/60 design should land close to 50/50
--     chi-square with 1 degree of freedom; values above 3.84 fail at the 5% level
SELECT
    COUNT(*) FILTER (WHERE variant = 'treatment') AS treatment,
    COUNT(*) FILTER (WHERE variant = 'holdout')   AS holdout,
    ROUND(
        2 * POWER(COUNT(*) FILTER (WHERE variant = 'treatment') - COUNT(*) / 2.0, 2)
          / (COUNT(*) / 2.0), 2)                  AS srm_chi_square
FROM advertiser_experiment;

-- 2.3 Who belongs in the analysis?
--     Only advertisers who were eligible AND had not already adopted can adopt.
--     Including everyone dilutes the lift. This query shows both, side by side.
SELECT
    'all 120 advertisers (diluted)'                        AS population,
    ROUND(100.0 * AVG(adopted_14d) FILTER (WHERE variant = 'treatment'), 1) AS treatment_pct,
    ROUND(100.0 * AVG(adopted_14d) FILTER (WHERE variant = 'holdout'),   1) AS holdout_pct
FROM advertiser_experiment
UNION ALL
SELECT
    'eligible non-adopters (correct)',
    ROUND(100.0 * AVG(adopted_14d) FILTER (WHERE variant = 'treatment'), 1),
    ROUND(100.0 * AVG(adopted_14d) FILTER (WHERE variant = 'holdout'),   1)
FROM advertiser_experiment
WHERE baseline_eligible = 1
  AND baseline_adopter  = 0;

-- 2.4 Primary metric: 14-day adoption, with lift, z-test and 95% confidence interval
--     Intent-to-treat: compare everyone ASSIGNED, whether or not the email was opened.
WITH pop AS (
    SELECT variant, adopted_14d
    FROM advertiser_experiment
    WHERE baseline_eligible = 1
      AND baseline_adopter  = 0
),
arms AS (
    SELECT
        COUNT(*)         FILTER (WHERE variant = 'treatment')       AS n_t,
        SUM(adopted_14d) FILTER (WHERE variant = 'treatment')       AS x_t,
        COUNT(*)         FILTER (WHERE variant = 'holdout')         AS n_h,
        SUM(adopted_14d) FILTER (WHERE variant = 'holdout')         AS x_h
    FROM pop
),
rates AS (
    SELECT *,
        x_t::numeric / n_t                       AS p_t,
        x_h::numeric / n_h                       AS p_h,
        (x_t + x_h)::numeric / (n_t + n_h)       AS p_pool
    FROM arms
)
SELECT
    n_t, x_t, ROUND(100 * p_t, 1)                                   AS treatment_pct,
    n_h, x_h, ROUND(100 * p_h, 1)                                   AS holdout_pct,
    ROUND(100 * (p_t - p_h), 1)                                     AS lift_pts,
    ROUND(100 * (p_t - p_h) / NULLIF(p_h, 0), 0)                    AS relative_lift_pct,
    ROUND((p_t - p_h) / SQRT(p_pool * (1 - p_pool) * (1.0 / n_t + 1.0 / n_h)), 2) AS z_score,
    ROUND(100 * ((p_t - p_h) - 1.96 * SQRT(p_t * (1 - p_t) / n_t + p_h * (1 - p_h) / n_h)), 1) AS ci_low_pts,
    ROUND(100 * ((p_t - p_h) + 1.96 * SQRT(p_t * (1 - p_t) / n_t + p_h * (1 - p_h) / n_h)), 1) AS ci_high_pts
FROM rates;

-- 2.5 Guardrails and secondary outcomes (same analysis population)
--     Spend uses the CHANGE (post minus pre) because the arms started at different spend levels.
SELECT
    variant,
    COUNT(*)                                            AS advertisers,
    ROUND(100.0 * AVG(opt_out_14d), 1)                  AS opt_out_pct,
    ROUND(100.0 * AVG(complaint_14d), 1)                AS complaint_pct,
    ROUND(100.0 * AVG(active_day_60), 1)                AS active_day60_pct,
    ROUND(100.0 * AVG(active_day_90), 1)                AS active_day90_pct,
    ROUND(AVG(pre_spend_30d), 0)                        AS avg_pre_spend,
    ROUND(AVG(post_spend_30d - pre_spend_30d), 0)       AS avg_spend_change
FROM advertiser_experiment
WHERE baseline_eligible = 1
  AND baseline_adopter  = 0
GROUP BY variant
ORDER BY variant;

-- 2.6 Economics: what does one incremental adopter cost?
WITH pop AS (
    SELECT * FROM advertiser_experiment
    WHERE baseline_eligible = 1 AND baseline_adopter = 0
),
summary AS (
    SELECT
        AVG(adopted_14d)       FILTER (WHERE variant = 'treatment')
      - AVG(adopted_14d)       FILTER (WHERE variant = 'holdout')    AS lift,
        AVG(intervention_cost) FILTER (WHERE variant = 'treatment')  AS cost_per_email
    FROM pop
)
SELECT
    ROUND(1000 * lift, 0)                      AS incremental_adopters_per_1000_emails,
    ROUND(cost_per_email, 2)                   AS cost_per_email,
    ROUND(cost_per_email / NULLIF(lift, 0), 2) AS cost_per_incremental_adopter
FROM summary;
