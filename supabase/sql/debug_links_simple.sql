-- Quick debug script for Links Management
-- Run this in Supabase SQL Editor

-- 1. Check if links table exists and has data
SELECT 'Step 1: Links table check' as step;
SELECT count(*) as links_count FROM public.links;

-- 2. Check if links_with_counts view exists
SELECT 'Step 2: View check' as step;
SELECT count(*) as view_count FROM public.links_with_counts;

-- 3. Check RLS policies
SELECT 'Step 3: RLS policies check' as step;
SELECT schemaname, tablename, policyname, roles 
FROM pg_policies 
WHERE tablename IN ('links', 'clicks') 
AND schemaname = 'public';

-- 4. Test direct query (bypass view)
SELECT 'Step 4: Direct links query' as step;
SELECT slug, target_url, active, updated_at 
FROM public.links 
ORDER BY updated_at DESC 
LIMIT 5;

-- 5. Test view query
SELECT 'Step 5: View query test' as step;
SELECT slug, target_url, active, total_clicks, last_click_at 
FROM public.links_with_counts 
ORDER BY updated_at DESC 
LIMIT 5;
