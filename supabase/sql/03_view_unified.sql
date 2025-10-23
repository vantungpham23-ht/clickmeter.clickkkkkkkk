-- Unified view:
--   include all historical days from clicks_daily
--   plus raw clicks for dates not yet rolled up (to avoid double counting)
create or replace view public.clicks_daily_unified as
select date, link_id, total_clicks, unique_ips
from public.clicks_daily
union all
select
  (c.ts at time zone 'Asia/Bangkok')::date as date,
  c.link_id,
  count(*) as total_clicks,
  count(distinct c.ip_address) as unique_ips
from public.clicks c
where (c.ts at time zone 'Asia/Bangkok')::date not in (select d.date from public.clicks_daily d)
group by 1, 2;
