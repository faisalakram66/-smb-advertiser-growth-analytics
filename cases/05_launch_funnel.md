# Case 5: Where do advertisers drop off before launching a campaign?

**SQL:** [`sql/05_launch_funnel.sql`](../sql/05_launch_funnel.sql)

## Business question
Advertisers create campaigns but don't always launch them. Which step loses the most campaigns, and why?

## How I framed it

| Step | Answer |
|---|---|
| **Grain** | One row per funnel step |
| **Everyone** | Every campaign attempt (472, Jan 15 to Mar 31, 2025) |
| **Yes** | Reached the step |
| **Traps** | The events table logs **several events per campaign**, so count `DISTINCT campaign_id`, not rows |

## The funnel

| Step | Campaigns | % of previous step | % of created |
|---|---|---|---|
| Created | 472 | | 100.0% |
| Setup started | 472 | 100.0% | 100.0% |
| **Submitted** | **400** | **84.7%** | 84.7% |
| Launched | 359 | 89.8% | 76.1% |

**The setup step is the leakiest:** 15.3% of campaigns are abandoned there. Another 10.2% of submitted campaigns hit an error before launch.

**Reconciles across tables:** 359 launches in the events table = 359 campaigns with a launch date. ✅

## Why campaigns stall

| Friction theme | Abandoned | Errored | Total lost |
|---|---|---|---|
| **Billing and payment** | 24 | 18 | **42** |
| Creative | 28 | 0 | 28 |
| Audience setup | 20 | 0 | 20 |
| Tracking (pixel) | 0 | 12 | 12 |
| Policy review | 0 | 11 | 11 |

Looked at one reason at a time, "creative missing" (28) is the top cause. **Grouped by theme, billing and payment is the biggest problem**: 42 of 113 lost campaigns (37%), split across abandoned setups and failed payments.

## Does campaign type matter?

| Campaign type | Campaigns | Launch rate |
|---|---|---|
| Sales | 132 | 75.0% |
| Messages | 112 | 75.9% |
| App promotion | 120 | 76.7% |
| Leads | 108 | 76.9% |

| Targeting | Campaigns | Launch rate | Median hours to launch |
|---|---|---|---|
| Advantage+ | 175 | 74.9% | 142 |
| Manual | 297 | 76.8% | 139 |

Launch rates sit within 2 points of each other across every type. **The friction is in the setup flow itself, not in any one campaign type.**

## What it means
Fixing billing and payment is the single biggest lever: recovering even half of those 42 campaigns would lift the launch rate by about 4.5 points. Creative and audience setup are the next priorities, and both are good fits for guided or AI-assisted setup.

## Caveats
- Differences between campaign and targeting types are small and within normal variation; I wouldn't act on them.
- Friction reasons are recorded only for abandoned and errored campaigns, so they explain losses, not slow launches.

## Next step
Partner with product on a billing flow test: saved payment methods, earlier payment validation, and a clear retry path, measured on launch rate with a holdout.
