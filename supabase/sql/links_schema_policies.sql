-- Table for short links
create table if not exists public.links (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,        -- e.g. "link1"
  target_url  text not null,               -- e.g. "https://example.com/page"
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists idx_links_slug on public.links (slug);
create index if not exists idx_links_active on public.links (active);

-- updated_at trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_links_updated_at on public.links;
create trigger trg_links_updated_at
before update on public.links
for each row execute function public.set_updated_at();

-- RLS
alter table public.links enable row level security;

-- Anyone (anon) may SELECT to let redirects work without login
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='links' and policyname='links_select_anon'
  ) then
    create policy "links_select_anon"
    on public.links for select
    to anon
    using (true);
  end if;
end$$;

-- Only authenticated users (dashboard) may INSERT/UPDATE/DELETE
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='links' and policyname='links_ins_auth'
  ) then
    create policy "links_ins_auth"
    on public.links for insert
    to authenticated
    with check (true);
  end if;
end$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='links' and policyname='links_upd_auth'
  ) then
    create policy "links_upd_auth"
    on public.links for update
    to authenticated
    using (true) with check (true);
  end if;
end$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='links' and policyname='links_del_auth'
  ) then
    create policy "links_del_auth"
    on public.links for delete
    to authenticated
    using (true);
  end if;
end$$;

-- (Optional) Basic URL/slug sanity via a domain check
-- Not enforced at DB-level to keep it simple; we'll validate in UI.
