-- Complete setup script for Links Management
-- Run this in Supabase SQL Editor to ensure everything is set up correctly

-- 1. Create links table if not exists
CREATE TABLE IF NOT EXISTS public.links (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        text NOT NULL UNIQUE,
  target_url  text NOT NULL,
  active      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- 2. Create indexes
CREATE INDEX IF NOT EXISTS idx_links_slug ON public.links (slug);
CREATE INDEX IF NOT EXISTS idx_links_active ON public.links (active);

-- 3. Create updated_at trigger
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS set_links_updated_at ON public.links;
CREATE TRIGGER set_links_updated_at
  BEFORE UPDATE ON public.links
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 4. Enable RLS
ALTER TABLE public.links ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies
DO $$
BEGIN
  -- Policy for anonymous users to select links (for redirects)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname='public' AND tablename='links' AND policyname='links_select_anon'
  ) THEN
    CREATE POLICY "links_select_anon"
    ON public.links FOR SELECT
    TO anon
    USING (true);
  END IF;

  -- Policy for authenticated users to manage links
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname='public' AND tablename='links' AND policyname='links_all_auth'
  ) THEN
    CREATE POLICY "links_all_auth"
    ON public.links FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);
  END IF;
END $$;

-- 6. Create clicks table if not exists (for click tracking)
CREATE TABLE IF NOT EXISTS public.clicks (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  link_id     text NOT NULL,
  target_url  text NOT NULL,
  ip_address  text NOT NULL,
  user_agent  text,
  referrer    text,
  ts          timestamptz NOT NULL DEFAULT now()
);

-- 7. Create clicks indexes
CREATE INDEX IF NOT EXISTS idx_clicks_link_id ON public.clicks(link_id);
CREATE INDEX IF NOT EXISTS idx_clicks_ts ON public.clicks(ts);

-- 8. Enable RLS on clicks
ALTER TABLE public.clicks ENABLE ROW LEVEL SECURITY;

-- 9. Create clicks RLS policy
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname='public' AND tablename='clicks' AND policyname='clicks_select_anon'
  ) THEN
    CREATE POLICY "clicks_select_anon"
    ON public.clicks FOR SELECT
    TO anon
    USING (true);
  END IF;
END $$;

-- 10. Create links_with_counts view
CREATE OR REPLACE VIEW public.links_with_counts AS
SELECT
  l.slug,
  l.target_url,
  l.active,
  l.updated_at,
  COALESCE(x.total_clicks, 0)::bigint AS total_clicks,
  x.last_click_at
FROM public.links l
LEFT JOIN (
  SELECT link_id, count(*) AS total_clicks, max(ts) AS last_click_at
  FROM public.clicks
  GROUP BY link_id
) x ON x.link_id = l.slug;

-- 11. Insert sample data if table is empty
INSERT INTO public.links (slug, target_url, active) VALUES 
('test1', 'https://google.com', true),
('promo2024', 'https://shop.com/sale', true),
('docs', 'https://docs.example.com', false)
ON CONFLICT (slug) DO NOTHING;

-- 12. Insert sample clicks
INSERT INTO public.clicks (link_id, target_url, ip_address, user_agent, referrer) VALUES 
('test1', 'https://google.com', '192.168.1.1', 'Mozilla/5.0...', 'https://example.com'),
('test1', 'https://google.com', '192.168.1.2', 'Mozilla/5.0...', 'https://facebook.com'),
('promo2024', 'https://shop.com/sale', '192.168.1.3', 'Mozilla/5.0...', 'https://twitter.com')
ON CONFLICT DO NOTHING;

-- 13. Refresh PostgREST schema
NOTIFY pgrst, 'reload schema';

-- 14. Verify setup
SELECT 'Setup complete!' as status;
SELECT 'Links count:' as info, count(*) as count FROM public.links;
SELECT 'Clicks count:' as info, count(*) as count FROM public.clicks;
SELECT 'View test:' as info, slug, target_url, active, total_clicks, last_click_at 
FROM public.links_with_counts 
ORDER BY updated_at DESC;
