-- Run this once in Supabase SQL Editor if listing is empty due to RLS.
alter table public.links enable row level security;

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

-- IMPORTANT: refresh REST schema cache
NOTIFY pgrst, 'reload schema';
