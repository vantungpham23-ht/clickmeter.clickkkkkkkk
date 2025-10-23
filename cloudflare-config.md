# Cloudflare Pages Configuration

## Build Settings
- **Build command**: (leave empty - no build required)
- **Build output directory**: `/` (root directory)
- **Root directory**: `/` (root directory)

## Environment Variables
No environment variables needed - all configuration is in the HTML file.

## Custom Headers
Add these headers for better security and performance:

```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  Cache-Control: public, max-age=31536000, immutable
```

## Domain Settings
- Enable HTTPS
- Set up custom domain (optional)
- Configure redirects if needed

## Deployment Notes
- Single HTML file deployment
- No build process required
- Static hosting only
- CDN optimized
