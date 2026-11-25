# Case 1: Where is Advantage+ adoption weakest?

**SQL:** [`sql/01_adoption_gap.sql`](../sql/01_adoption_gap.sql)

## Business question
The product team wants to grow adoption of Advantage+ Shopping campaigns. Among advertisers who are **eligible**, what share have adopted it, and where is the gap biggest?

## How I framed it

| Step | Answer |
|---|---|
| **Grain** | One row per company size |
| **Everyone (denominator)** | Advertisers with `eligible_advantage_plus = 1` |
| **Yes (numerator)** | Those with an Advantage+ Shopping record where `adopted = 1` |
| **Where** | Eligibility in `advertisers`, adoption in `product_adoption`, joined on `advertiser_id` |
| **Traps** | Some eligible advertisers have **no record at all**: they are non-adopters and must stay in the denominator |

## Check the data first
| Eligible | Have a record | **No record at all** | Adopted | Record, not adopted |
|---|---|---|---|---|
| 101 | 65 | **36** | 33 | 32 |

More than a third of eligible advertisers never appear in the adoption table. That decides how the query has to be written.

## The mistake this case is built around
Putting the product filter in `WHERE` instead of the join's `ON` clause:

```sql
LEFT JOIN product_adoption p ON p.advertiser_id = a.advertiser_id
WHERE a.eligible_advantage_plus = 1
  AND p.product_name = 'Advantage+ Shopping'   -- removes the 36 advertisers with no record
```

| Version | Adoption rate |
|---|---|
| Filter in `WHERE` (wrong) | **50.8%** |
| Filter in `ON` (correct) | **32.7%** |

The wrong version quietly turns the LEFT JOIN into an INNER JOIN, drops every advertiser who never engaged, and overstates adoption by 18 points.

## Results

| Company size | Eligible | Adopted | Adoption % | Never engaged | Engaged, not adopted |
|---|---|---|---|---|---|
| Large | 19 | 5 | **26.3%** | 6 | 8 |
| Small | 29 | 8 | 27.6% | **15** | 6 |
| Micro | 21 | 7 | 33.3% | 9 | 5 |
| Medium | 32 | 13 | 40.6% | 6 | **13** |
| **Total** | **101** | **33** | **32.7%** | 36 | 32 |

## What it means
- **Large advertisers adopt least**, at 26%. They are also where most of the spend sits (see [Case 4](04_opportunity_sizing.md)).
- **The gap isn't one problem.** Small advertisers mostly *never engaged* (15 of 21 non-adopters): that's an **awareness** problem. Medium advertisers mostly *engaged and stopped* (13 of 19): that's an **activation** problem. They need different programs.

## Caveats
- **Data quality flag:** 11 advertisers marked *not eligible* have Advantage+ records, and 4 of them adopted. Either the eligibility flag is out of date or the definition changed. I'd confirm the eligibility rule with the product team before using it for targeting.
- Groups are small (19 to 32 advertisers), so differences of a few points are directional.

## Next step
Design two separate journeys: discovery for advertisers who never engaged, and setup help for those who engaged but didn't adopt. Test each against a holdout (see [Case 2](02_experiment_readout.md)).
