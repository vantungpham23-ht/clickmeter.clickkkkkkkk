# ClickMeter Dashboard - Cloudflare Pages Deployment Guide

## 🚀 Quick Deploy to Cloudflare Pages

### Method 1: Direct Upload
1. Go to [Cloudflare Pages](https://pages.cloudflare.com/)
2. Click "Create a project"
3. Choose "Upload assets"
4. Upload the `index.html` file
5. Set project name: `clickmeter-dashboard`
6. Click "Deploy site"

### Method 2: Git Integration
1. Push this repository to GitHub/GitLab
2. Connect repository to Cloudflare Pages
3. Set build settings:
   - **Build command**: (leave empty)
   - **Build output directory**: `/`
   - **Root directory**: `/`
4. Deploy

## ⚙️ Configuration

### Build Settings
- **Framework preset**: None
- **Build command**: (empty)
- **Build output directory**: `/`
- **Root directory**: `/`

### Custom Headers (Optional)
Add these in Pages → Settings → Custom headers:
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Cache-Control: public, max-age=31536000
```

## 🔐 Supabase Setup Required

Before using the dashboard, ensure:

1. **Authentication Provider**:
   - Supabase Dashboard → Authentication → Providers
   - Enable **Email** provider

2. **Create User**:
   - Authentication → Users → Add user
   - Email: `admin@example.com`
   - Password: `your-secure-password`

3. **RLS Policies**:
   ```sql
   -- Allow SELECT on views for authenticated users
   CREATE POLICY "Allow authenticated users to read click_stats" ON public.click_stats
     FOR SELECT TO authenticated USING (true);
   
   CREATE POLICY "Allow authenticated users to read click_stats_daily" ON public.click_stats_daily
     FOR SELECT TO authenticated USING (true);
   
   -- Allow INSERT on clicks table for anonymous users (from redirect pages)
   CREATE POLICY "Allow anonymous users to insert clicks" ON public.clicks
     FOR INSERT TO anon WITH CHECK (true);
   ```

## 📊 Features

- ✅ **Authentication**: Supabase email/password login
- ✅ **Real-time**: Live updates when new clicks are inserted
- ✅ **Charts**: Chart.js line chart for daily trends
- ✅ **KPIs**: Total clicks, unique IPs, first/last click
- ✅ **Responsive**: Mobile-friendly design
- ✅ **Monochrome**: Clean black/white/grey theme

## 🌐 Access

After deployment, your dashboard will be available at:
- `https://clickmeter-dashboard.pages.dev` (or your custom domain)

## 🔧 Troubleshooting

- **Login fails**: Check Supabase Auth provider and user credentials
- **No data**: Verify RLS policies and Supabase views exist
- **Chart not loading**: Check browser console for errors
- **Realtime not working**: Ensure Supabase Realtime is enabled

## 📱 Mobile Support

The dashboard is fully responsive and works on:
- Mobile phones
- Tablets
- Desktop computers
- All modern browsers

## 🚀 Performance

- Single HTML file (no build process)
- CDN optimized resources
- Efficient real-time subscriptions
- Minimal bundle size
- Fast loading times
