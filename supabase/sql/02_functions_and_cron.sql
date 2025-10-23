-- 1) Rollup function: aggregate "yesterday" (Asia/Bangkok) into clicks_daily
create or replace function public.rollup_clicks_yesterday() returns void
language sql as $$
  insert into public.clicks_daily (date, link_id, total_clicks, unique_ips)
  select
    (ts at time zone 'Asia/Bangkok')::date as date,
    link_id,
    count(*) as total_clicks,
    count(distinct ip_address) as unique_ips
  from public.clicks
  where (ts at time zone 'Asia/Bangkok')::date = (now() at time zone 'Asia/Bangkok')::date - 1
  group by 1, 2
  on conflict (date, link_id) do update
    set total_clicks = excluded.total_clicks,
        unique_ips   = excluded.unique_ips;
$$;

-- 2) Prune function: keep newest N rows in public.clicks (global cap)
create or replace function public.prune_clicks_keep_latest(limit_count int)
returns void language sql as $$
  with to_delete as (
    select id
    from public.clicks
    order by ts desc
    offset limit_count
  )
  delete from public.clicks c
  using to_delete d
  where c.id = d.id;
$$;

-- 3) pg_cron schedules
create extension if not exists pg_cron;

-- 3.1 Rollup "yesterday" daily at 02:55 UTC
select cron.schedule(
  'rollup_yesterday',
  '55 2 * * *',
  $$ select public.rollup_clicks_yesterday() $$
);

-- 3.2 Prune to 20,000 newest rows at 03:00 UTC
select cron.schedule(
  'prune_clicks_20k_global',
  '0 3 * * *',
  $$ select public.prune_clicks_keep_latest(20000) $$
);

-- 3.3 Weekly maintenance
select cron.schedule(
  'vacuum_clicks_weekly',
  '0 4 * * 0',
  $$ vacuum analyze public.clicks $$
);
