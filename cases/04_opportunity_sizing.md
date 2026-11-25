# Case 4: How big is the opportunity?

**SQL:** [`sql/04_opportunity_sizing.sql`](../sql/04_opportunity_sizing.sql)

## Business question
If we roll the education email from [Case 2](02_experiment_readout.md) out to every eligible advertiser who hasn't adopted Advantage+, how many new adopters should we expect, and where is the value concentrated?

## How I framed it

| Step | Answer |
|---|---|
| **Grain** | One row per company size, plus a total |
| **Everyone** | Eligible advertisers with **no Advantage+ record, or a record with `adopted = 0`** (from [Case 1](01_adoption_gap.md)) |
| **Value** | Average monthly spend over the last 3 months of data |
| **Lift** | From Case 2: **9.6 points** (low end of the 95% CI) and **29.4 points** (point estimate) |
| **Traps** | "Last 3 months" must be anchored to the data (it ends Dec 2024), not to today. The monthly table has many rows per advertiser, so spend is averaged **per advertiser first**, then joined |

## Results

| Company size | Non-adopters | Monthly spend in scope | Avg monthly spend | New adopters (low) | New adopters (mid) |
|---|---|---|---|---|---|
| Large | 14 | $276,404 | $19,743 | 1.3 | 4.1 |
| Medium | 19 | $179,256 | $9,435 | 1.8 | 5.6 |
| Small | 21 | $110,122 | $5,244 | 2.0 | 6.2 |
| Micro | 14 | $28,841 | $2,060 | 1.3 | 4.1 |
| **Total** | **68** | **$594,624** | **$8,744** | **6.5** | **20.0** |

**Reconciles with Case 1:** 68 = 36 never engaged + 32 engaged but not adopted. ✅

## Concentration
The top 10 non-adopters by spend are **all Large advertisers** and hold **36.6%** of in-scope spend. The single biggest spends about $30,000 a month.

## What it means
- **Scale vs. value.** Small advertisers are the largest group (21), but **14 Large advertisers hold 46% of the spend**. And from Case 1, Large advertisers have the *lowest* adoption rate.
- **Two plays, not one:**
  - **Large:** a targeted, possibly sales-assisted program for a short list of high-spend advertisers
  - **Small and Medium:** the scaled email program, which is cheap per adopter
- **Planning number:** about **6 to 20 new adopters** from this pool, using the experiment's confidence range.

## Caveats
- **The lift may not transfer.** It was measured on one experiment's population. Large advertisers may respond differently to a self-serve email than smaller ones, so I'd validate the lift for Large advertisers before counting on it.
- **Spend isn't incremental revenue.** "Spend in scope" shows how much business sits with these advertisers, not what adoption would add. Measuring incremental spend needs its own holdout.
- Advertisers with no spend in the last 3 months are counted as $0 (`COALESCE`), not dropped.

## Next step
Run the email program for Small and Medium advertisers with a 10% holdout, and pilot a sales-assisted version with the top Large non-adopters, measuring 30-day retained adoption and spend change against a matched holdout.
