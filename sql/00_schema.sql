-- SMB Advertiser Growth Analytics: schema (PostgreSQL 14+)
-- All data is synthetic practice data. advertiser_id joins every advertiser-level table.

DROP TABLE IF EXISTS help_center_engagement, marketing_touchpoints, channel_usage,
    advertiser_events, advertiser_campaigns, advertiser_experiment, experiments,
    product_health, product_adoption, monthly_performance, advertisers CASCADE;

-- One row per advertiser
CREATE TABLE advertisers (
    advertiser_id               INTEGER PRIMARY KEY,
    business_name               TEXT,
    signup_date                 DATE,
    signup_month                TEXT,
    first_touch_channel         TEXT,
    business_segment            TEXT,
    company_size                TEXT,
    monthly_budget              NUMERIC(12,2),
    region                      TEXT,
    country                     TEXT,
    account_tier                TEXT,
    sales_assisted              SMALLINT,
    industry                    TEXT,
    lifecycle_stage             TEXT,
    baseline_90d_value          NUMERIC(12,2),
    eligible_advantage_plus     SMALLINT,
    eligible_capi               SMALLINT,
    eligible_business_messaging SMALLINT
);

-- One row per advertiser per month (month = first day of month)
CREATE TABLE monthly_performance (
    advertiser_id       INTEGER REFERENCES advertisers,
    month               DATE,
    days_active         INTEGER,
    spend               NUMERIC(12,2),
    impressions         BIGINT,
    reach               BIGINT,
    clicks              INTEGER,
    landing_page_views  INTEGER,
    leads               INTEGER,
    conversions         INTEGER,
    revenue             NUMERIC(12,2),
    active_in_month     SMALLINT,
    sessions            INTEGER,
    new_customers       INTEGER,
    repeat_customers    INTEGER,
    video_views         BIGINT,
    messages_started    INTEGER,
    qualified_leads     INTEGER,
    purchases           INTEGER,
    refunds             INTEGER,
    PRIMARY KEY (advertiser_id, month)
);

-- One row per advertiser per product (only products the advertiser was eligible for)
CREATE TABLE product_adoption (
    advertiser_id        INTEGER REFERENCES advertisers,
    product_name         TEXT,
    eligible_date        DATE,
    adoption_date        DATE,
    adopted              SMALLINT,
    activation_completed SMALLINT,
    days_to_adopt        INTEGER,
    pre_30d_spend        NUMERIC(12,2),
    post_30d_spend       NUMERIC(12,2),
    pre_30d_revenue      NUMERIC(12,2),
    post_30d_revenue     NUMERIC(12,2),
    feature_usage_30d    INTEGER,
    retained_60d         SMALLINT,
    retained_90d         SMALLINT,
    education_exposed    SMALLINT,
    support_contacted    SMALLINT,
    PRIMARY KEY (advertiser_id, product_name)
);

-- One row per advertiser per monthly snapshot: tracking (Pixel / Conversions API) and click-to-WhatsApp health
CREATE TABLE product_health (
    advertiser_id                INTEGER REFERENCES advertisers,
    snapshot_date                TIMESTAMP,
    pixel_active                 SMALLINT,
    capi_active                  SMALLINT,
    emq_score                    NUMERIC(4,1),
    server_events_received       INTEGER,
    matched_server_events        INTEGER,
    duplicate_event_pairs        INTEGER,
    deduplicated_pairs           INTEGER,
    event_latency_minutes        NUMERIC(8,1),
    ctwa_conversations           INTEGER,
    ctwa_qualified_conversations INTEGER,
    ctwa_purchases               INTEGER,
    ctwa_block_or_report         INTEGER,
    ctwa_spend                   NUMERIC(12,2),
    currency                     TEXT,
    PRIMARY KEY (advertiser_id, snapshot_date)
);

-- One row per advertiser per experiment (three product-education experiments)
CREATE TABLE experiments (
    experiment_id           INTEGER,
    advertiser_id           INTEGER REFERENCES advertisers,
    experiment_name         TEXT,
    variant                 TEXT,
    assignment_date         DATE,
    eligible                SMALLINT,
    exposed                 SMALLINT,
    primary_outcome         SMALLINT,
    adopted_product         SMALLINT,
    incremental_revenue_30d NUMERIC(12,2),
    spend_30d               NUMERIC(12,2),
    retained_60d            SMALLINT,
    guardrail_opt_out       SMALLINT,
    segment                 TEXT,
    region                  TEXT
);

-- One row per advertiser in a single randomized email-education experiment (EDU_120)
CREATE TABLE advertiser_experiment (
    experiment_id        TEXT,
    advertiser_id        INTEGER REFERENCES advertisers,
    variant              TEXT,
    assignment_at        TIMESTAMP,
    baseline_eligible    SMALLINT,
    baseline_adopter     SMALLINT,
    email_delivered      SMALLINT,
    adopted_14d          SMALLINT,
    adopted_at           TIMESTAMP,
    pre_spend_30d        NUMERIC(12,2),
    post_spend_30d       NUMERIC(12,2),
    merchant_revenue_30d NUMERIC(12,2),
    intervention_cost    NUMERIC(8,2),
    opt_out_14d          SMALLINT,
    complaint_14d        SMALLINT,
    active_day_60        SMALLINT,
    active_day_90        SMALLINT,
    business_segment     TEXT,
    region               TEXT,
    observation_end      TIMESTAMP,
    PRIMARY KEY (experiment_id, advertiser_id)
);

-- One row per campaign attempt
CREATE TABLE advertiser_campaigns (
    advertiser_id      INTEGER REFERENCES advertisers,
    campaign_id        TEXT PRIMARY KEY,
    campaign_type      TEXT,
    targeting_type     TEXT,
    created_at         TIMESTAMP,
    launched_at        TIMESTAMP,
    stopped_at         TIMESTAMP,
    spend              NUMERIC(12,2),
    purchases          INTEGER,
    status             TEXT,
    attributed_revenue NUMERIC(12,2),
    observation_end    TIMESTAMP,
    currency           TEXT
);

-- One row per campaign setup event (the launch funnel)
CREATE TABLE advertiser_events (
    event_id        TEXT PRIMARY KEY,
    advertiser_id   INTEGER REFERENCES advertisers,
    campaign_id     TEXT REFERENCES advertiser_campaigns,
    event_at        TIMESTAMP,
    event_name      TEXT,
    funnel_step     SMALLINT,
    friction_reason TEXT,
    scenario_id     TEXT
);

-- One row per advertiser per channel (November 2024)
CREATE TABLE channel_usage (
    advertiser_id  INTEGER REFERENCES advertisers,
    month          DATE,
    channel_name   TEXT,
    spend          NUMERIC(12,2),
    impressions    BIGINT,
    clicks         INTEGER,
    conversions    INTEGER,
    revenue        NUMERIC(12,2),
    active_channel SMALLINT
);

-- One row per marketing touch sent to an advertiser
CREATE TABLE marketing_touchpoints (
    touch_id              INTEGER PRIMARY KEY,
    advertiser_id         INTEGER REFERENCES advertisers,
    touch_date            DATE,
    channel               TEXT,
    campaign_name         TEXT,
    touch_type            TEXT,
    impressions           INTEGER,
    clicks                INTEGER,
    email_open            SMALLINT,
    email_click           SMALLINT,
    webinar_attended      SMALLINT,
    in_product_view       SMALLINT,
    cta_click             SMALLINT,
    cost                  NUMERIC(12,2),
    converted_to_adoption SMALLINT,
    attributed_revenue    NUMERIC(12,2)
);

-- One row per Help Center interaction
CREATE TABLE help_center_engagement (
    engagement_id    TEXT PRIMARY KEY,
    advertiser_id    INTEGER REFERENCES advertisers,
    engaged_at       TIMESTAMP,
    interaction_type TEXT,
    content_topic    TEXT,
    dwell_seconds    INTEGER,
    liked            SMALLINT,
    commented        SMALLINT,
    entry_channel    TEXT
);
