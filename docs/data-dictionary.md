# Data dictionary

All data is **synthetic**, created for practice. `advertiser_id` joins every advertiser-level table. Money is in USD.

| Table | One row per | Rows | Key columns |
|---|---|---|---|
| `advertisers` | advertiser | 120 | `business_segment`, `company_size`, `account_tier`, `lifecycle_stage`, `signup_month`, eligibility flags (`eligible_advantage_plus`, `eligible_capi`, `eligible_business_messaging`) |
| `monthly_performance` | advertiser × month (Jun to Dec 2024) | 595 | `spend`, `revenue`, `clicks`, `conversions`, `leads`, `active_in_month` |
| `product_adoption` | advertiser × product | 441 | `product_name`, `adopted`, `days_to_adopt`, `retained_60d`, `retained_90d`, pre/post 30-day spend and revenue |
| `product_health` | advertiser × monthly snapshot | 720 | `pixel_active`, `capi_active`, `emq_score`, click-to-WhatsApp conversations and purchases |
| `experiments` | advertiser × experiment (3 tests) | 120 | `experiment_name`, `variant`, `exposed`, `adopted_product`, `incremental_revenue_30d`, `guardrail_opt_out` |
| `advertiser_experiment` | advertiser in test EDU_120 | 120 | `variant`, `baseline_eligible`, `baseline_adopter`, `adopted_14d`, `opt_out_14d`, `complaint_14d`, pre/post spend |
| `advertiser_campaigns` | campaign attempt | 472 | `campaign_type`, `targeting_type`, `created_at`, `launched_at`, `status`, `spend` |
| `advertiser_events` | campaign setup event | 2,175 | `event_name`, `funnel_step`, `friction_reason` |
| `channel_usage` | advertiser × channel (Nov 2024) | 407 | `channel_name`, `spend`, `conversions`, `revenue` |
| `marketing_touchpoints` | marketing touch | 823 | `channel`, `touch_type`, `cost`, `converted_to_adoption` |
| `help_center_engagement` | Help Center interaction | 169 | `interaction_type`, `content_topic`, `dwell_seconds`, `entry_channel` |

## Things to know before querying
- **Not every eligible advertiser has a `product_adoption` row.** A missing row means the advertiser never engaged with the product.
- **`monthly_performance` starts at each advertiser's signup month**, so early months have fewer advertisers.
- **Data ends in December 2024** for monthly tables and **March 2025** for campaigns. Anchor time windows to the data, not to today.
- **Experiment populations differ:** `experiments` holds three small tests; `advertiser_experiment` holds one randomized 60/60 test.
- **`incremental_revenue_30d` is positive even for control advertisers**, so treat that column's definition with care (see Case 3).
