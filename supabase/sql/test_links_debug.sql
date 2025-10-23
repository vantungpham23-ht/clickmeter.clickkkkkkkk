-- Test and create sample data for Links Management
-- Run this in Supabase SQL Editor

-- First, check if tables exist
SELECT 'links table exists' as status WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'links' AND table_schema = 'public');
SELECT 'clicks table exists' as status WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clicks' AND table_schema = 'public');

-- Check if view exists
SELECT 'links_with_counts view exists' as status WHERE EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'links_with_counts' AND table_schema = 'public');

-- Insert sample links if they don't exist
INSERT INTO public.links (slug, target_url, active) VALUES 
('test1', 'https://google.com', true),
('promo2024', 'https://shop.com/sale', true),
('docs', 'https://docs.example.com', false)
ON CONFLICT (slug) DO NOTHING;

-- Insert sample clicks for testing
INSERT INTO public.clicks (link_id, target_url, ip_address, user_agent, referrer) VALUES 
('test1', 'https://google.com', '192.168.1.1', 'Mozilla/5.0...', 'https://example.com'),
('test1', 'https://google.com', '192.168.1.2', 'Mozilla/5.0...', 'https://facebook.com'),
('promo2024', 'https://shop.com/sale', '192.168.1.3', 'Mozilla/5.0...', 'https://twitter.com')
ON CONFLICT DO NOTHING;

-- Verify the data
SELECT 'Links count:' as info, count(*) as count FROM public.links;
SELECT 'Clicks count:' as info, count(*) as count FROM public.clicks;

-- Test the view
SELECT 'View test:' as info, slug, target_url, active, total_clicks, last_click_at 
FROM public.links_with_counts 
ORDER BY updated_at DESC;
