-- Test data for Links Management
-- Run this in Supabase SQL Editor after running links_schema_policies.sql

-- Insert sample links for testing
INSERT INTO public.links (slug, target_url, active) VALUES 
('test1', 'https://google.com', true),
('promo2024', 'https://shop.com/sale?discount=50', true),
('docs', 'https://docs.example.com', false)
ON CONFLICT (slug) DO NOTHING;

-- Verify the data
SELECT slug, target_url, active, updated_at FROM public.links ORDER BY updated_at DESC;
