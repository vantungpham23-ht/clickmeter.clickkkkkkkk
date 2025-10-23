-- Table for durable daily aggregates
create table if not exists public.clicks_daily (
  date         date        not null,
  link_id      text        not null,
  total_clicks integer     not null,
  unique_ips   integer     not null default 0,
  primary key (date, link_id)
);

create index if not exists idx_clicks_daily_date on public.clicks_daily (date);

-- Enable RLS and add SELECT policies (anon + authenticated)
alter table public.clicks_daily enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'clicks_daily' and policyname = 'select clicks_daily anon'
  ) then
    create policy "select clicks_daily anon"
    on public.clicks_daily for select to anon using (true);
  end if;
end$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'clicks_daily' and policyname = 'select clicks_daily auth'
  ) then
    create policy "select clicks_daily auth"
    on public.clicks_daily for select to authenticated using (true);
  end if;
end$$;

-- Helpful indexes on clicks if not present
create index if not exists idx_clicks_ts on public.clicks (ts);
create index if not exists idx_clicks_link_ts on public.clicks (link_id, ts desc);
