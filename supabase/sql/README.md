# Supabase rollup & prune (20,000) + unified view

## Apply order
1) Run 01_schema_clicks_daily.sql in Supabase SQL Editor.
2) Run 02_functions_and_cron.sql.
3) Run 03_view_unified.sql.

## What happens
- Nightly rollup of yesterday into clicks_daily (Asia/Bangkok).
- Keep only newest 20,000 rows in clicks.
- Unified view merges historical daily totals with current raw without double counting.

## Dashboard usage
To render "lifetime total":
- Archived total: sum(total_clicks) from clicks_daily.
- Current total: count(*) from clicks (the rows still kept).
- Lifetime = Archived + Current.

Example queries (client-side):
- Archived: `select sum(total_clicks) as s from clicks_daily;`
- Current:  `select count(*) as c from clicks;`

## Notes
- If you change the cap (e.g., 50,000), modify the cron call: `prune_clicks_keep_latest(50000)`.
- Keep SELECT policies on `clicks` and `clicks_daily` for your dashboard role (anon/auth).
- VACUUM weekly helps reclaim storage.
