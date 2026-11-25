#!/usr/bin/env bash
# Create the tables and load the cleaned CSVs into PostgreSQL.
# Usage: bash scripts/load_postgres.sh <database_name>
# Run from the repository root. Uses your normal psql connection settings (PGHOST, PGUSER, ...).
set -euo pipefail

DB="${1:-smb_growth}"

psql -v ON_ERROR_STOP=1 -d "$DB" -f sql/00_schema.sql

# Load parents before children so foreign keys are satisfied
for table in advertisers monthly_performance product_adoption product_health experiments \
             advertiser_experiment advertiser_campaigns advertiser_events channel_usage \
             marketing_touchpoints help_center_engagement; do
    psql -v ON_ERROR_STOP=1 -d "$DB" -c "\copy $table FROM 'data/$table.csv' WITH (FORMAT csv, HEADER true)"
done

psql -d "$DB" -c "SELECT 'advertisers' AS table_name, COUNT(*) FROM advertisers
                  UNION ALL SELECT 'product_adoption', COUNT(*) FROM product_adoption
                  UNION ALL SELECT 'advertiser_experiment', COUNT(*) FROM advertiser_experiment
                  UNION ALL SELECT 'advertiser_events', COUNT(*) FROM advertiser_events;"
