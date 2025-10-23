create index if not exists idx_clicks_link_id on public.clicks(link_id);
create index if not exists idx_clicks_ts on public.clicks(ts);

create or replace view public.links_with_counts as
select
l.slug,
l.target_url,
l.active,
l.updated_at,
coalesce(x.total_clicks, 0)::bigint as total_clicks,
x.last_click_at
from public.links l
left join (
select link_id, count(*) as total_clicks, max(ts) as last_click_at
from public.clicks
group by link_id
) x on x.link_id = l.slug;

alter table public.links  enable row level security;
alter table public.clicks enable row level security;

do $$
begin
if not exists (select 1 from pg_policies where schemaname='public' and tablename='links' and policyname='links_select_anon') then
create policy "links_select_anon" on public.links  for select to anon using (true);
end if;
if not exists (select 1 from pg_policies where schemaname='public' and tablename='clicks' and policyname='clicks_select_anon') then
create policy "clicks_select_anon" on public.clicks for select to anon using (true);
end if;
end$$;

NOTIFY pgrst, 'reload schema';
