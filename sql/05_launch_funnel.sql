-- =====================================================================
-- Case 5: Where do advertisers drop off between creating and launching a campaign?
-- Question: Which funnel step loses the most campaigns, and why?
-- Tables:   advertiser_events (one row per setup event)
--           advertiser_campaigns (one row per campaign attempt)
-- =====================================================================

-- 5.1 Funnel: distinct campaigns reaching each step, with step-to-step conversion.
--     Count DISTINCT campaigns, not events: one campaign can log several events.
WITH steps AS (
    SELECT
        COUNT(DISTINCT campaign_id) FILTER (WHERE event_name = 'campaign_created')  AS created,
        COUNT(DISTINCT campaign_id) FILTER (WHERE event_name = 'setup_started')     AS setup_started,
        COUNT(DISTINCT campaign_id) FILTER (WHERE event_name = 'setup_submitted')   AS submitted,
        COUNT(DISTINCT campaign_id) FILTER (WHERE event_name = 'campaign_launched') AS launched
    FROM advertiser_events
)
SELECT 'created'       AS step, created       AS campaigns, NULL::numeric AS pct_of_previous, 100.0 AS pct_of_created FROM steps
UNION ALL
SELECT 'setup_started', setup_started, ROUND(100.0 * setup_started / created, 1),       ROUND(100.0 * setup_started / created, 1) FROM steps
UNION ALL
SELECT 'submitted',     submitted,     ROUND(100.0 * submitted / setup_started, 1),     ROUND(100.0 * submitted / created, 1)     FROM steps
UNION ALL
SELECT 'launched',      launched,      ROUND(100.0 * launched / submitted, 1),          ROUND(100.0 * launched / created, 1)      FROM steps;

-- 5.2 Why campaigns stall: friction reasons, grouped into themes
SELECT
    CASE
        WHEN friction_reason IN ('billing_friction', 'payment_failed') THEN 'Billing and payment'
        WHEN friction_reason IN ('creative_missing')                   THEN 'Creative'
        WHEN friction_reason IN ('audience_setup')                     THEN 'Audience setup'
        WHEN friction_reason IN ('pixel_missing')                      THEN 'Tracking (pixel)'
        WHEN friction_reason IN ('policy_review')                      THEN 'Policy review'
    END                                         AS friction_theme,
    COUNT(*) FILTER (WHERE event_name = 'setup_abandoned') AS abandoned,
    COUNT(*) FILTER (WHERE event_name = 'setup_error')     AS errored,
    COUNT(*)                                               AS total_lost
FROM advertiser_events
WHERE friction_reason IS NOT NULL
GROUP BY 1
ORDER BY total_lost DESC;

-- 5.3 Launch rate and median time to launch, by targeting type
--     A campaign counts as launched if launched_at is filled in.
SELECT
    targeting_type,
    COUNT(*)                                                         AS campaigns,
    ROUND(100.0 * COUNT(launched_at) / COUNT(*), 1)                  AS launch_rate_pct,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (
          ORDER BY EXTRACT(EPOCH FROM (launched_at - created_at)) / 3600.0)::numeric, 1)
                                                                     AS median_hours_to_launch
FROM advertiser_campaigns
GROUP BY targeting_type
ORDER BY launch_rate_pct;

-- 5.4 Launch rate by campaign type, lowest first
SELECT
    campaign_type,
    COUNT(*)                                          AS campaigns,
    ROUND(100.0 * COUNT(launched_at) / COUNT(*), 1)   AS launch_rate_pct,
    COUNT(*) FILTER (WHERE status = 'abandoned')      AS abandoned,
    COUNT(*) FILTER (WHERE status = 'failed')         AS failed
FROM advertiser_campaigns
GROUP BY campaign_type
ORDER BY launch_rate_pct;

-- 5.5 Reconcile the two tables: funnel launches vs campaigns with a launch date
SELECT
    (SELECT COUNT(DISTINCT campaign_id) FROM advertiser_events WHERE event_name = 'campaign_launched') AS launched_per_events,
    (SELECT COUNT(*) FROM advertiser_campaigns WHERE launched_at IS NOT NULL)                          AS launched_per_campaigns;
