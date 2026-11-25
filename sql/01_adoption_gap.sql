-- =====================================================================
-- Case 1: Where is Advantage+ adoption weakest?
-- Question: Among advertisers ELIGIBLE for Advantage+, what share adopted
--           Advantage+ Shopping, by company size?
-- Tables:   advertisers (one row per advertiser)
--           product_adoption (one row per advertiser per product)
-- =====================================================================

-- 1.1 Check the data before writing the metric.
--     How many eligible advertisers actually have an Advantage+ Shopping record?
SELECT
    COUNT(*)                                           AS eligible_advertisers,
    COUNT(p.advertiser_id)                             AS have_a_record,
    COUNT(*) FILTER (WHERE p.advertiser_id IS NULL)    AS no_record_at_all,
    COUNT(*) FILTER (WHERE p.adopted = 1)              AS adopted,
    COUNT(*) FILTER (WHERE p.adopted = 0)              AS record_but_not_adopted
FROM advertisers a
LEFT JOIN product_adoption p
       ON p.advertiser_id = a.advertiser_id
      AND p.product_name  = 'Advantage+ Shopping'
WHERE a.eligible_advantage_plus = 1;

-- 1.2 The common mistake: product filter in WHERE.
--     Eligible advertisers with no record have NULL product_name, so WHERE removes them.
--     The LEFT JOIN silently becomes an INNER JOIN and the rate is inflated.
SELECT
    ROUND(100.0 * SUM(p.adopted) / COUNT(*), 1) AS adoption_pct_wrong
FROM advertisers a
LEFT JOIN product_adoption p
       ON p.advertiser_id = a.advertiser_id
WHERE a.eligible_advantage_plus = 1
  AND p.product_name = 'Advantage+ Shopping';   -- filter on the joined table: belongs in ON

-- 1.3 Correct version: product filter in ON keeps every eligible advertiser in the denominator.
--     Non-adopters are split into two groups because they need different programs.
SELECT
    a.company_size,
    COUNT(DISTINCT a.advertiser_id)                                              AS eligible,
    COUNT(DISTINCT a.advertiser_id) FILTER (WHERE p.adopted = 1)                 AS adopted,
    ROUND(100.0 * COUNT(DISTINCT a.advertiser_id) FILTER (WHERE p.adopted = 1)
          / NULLIF(COUNT(DISTINCT a.advertiser_id), 0), 1)                       AS adoption_pct,
    COUNT(DISTINCT a.advertiser_id) FILTER (WHERE p.advertiser_id IS NULL)       AS never_engaged,
    COUNT(DISTINCT a.advertiser_id) FILTER (WHERE p.adopted = 0)                 AS engaged_not_adopted
FROM advertisers a
LEFT JOIN product_adoption p
       ON p.advertiser_id = a.advertiser_id
      AND p.product_name  = 'Advantage+ Shopping'
WHERE a.eligible_advantage_plus = 1
GROUP BY a.company_size
ORDER BY adoption_pct;

-- 1.4 Total row, to reconcile with 1.1
SELECT
    COUNT(DISTINCT a.advertiser_id)                                              AS eligible,
    COUNT(DISTINCT a.advertiser_id) FILTER (WHERE p.adopted = 1)                 AS adopted,
    ROUND(100.0 * COUNT(DISTINCT a.advertiser_id) FILTER (WHERE p.adopted = 1)
          / NULLIF(COUNT(DISTINCT a.advertiser_id), 0), 1)                       AS adoption_pct
FROM advertisers a
LEFT JOIN product_adoption p
       ON p.advertiser_id = a.advertiser_id
      AND p.product_name  = 'Advantage+ Shopping'
WHERE a.eligible_advantage_plus = 1;

-- 1.5 Data-quality flag: adoption records for advertisers marked NOT eligible
SELECT
    COUNT(*)                         AS records_for_ineligible_advertisers,
    SUM(p.adopted)                   AS of_which_adopted
FROM product_adoption p
JOIN advertisers a USING (advertiser_id)
WHERE p.product_name = 'Advantage+ Shopping'
  AND a.eligible_advantage_plus = 0;
