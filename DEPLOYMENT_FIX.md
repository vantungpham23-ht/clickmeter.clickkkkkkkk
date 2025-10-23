# 🔧 Fix Cloudflare Pages Deployment Error

## ❌ **Lỗi gặp phải:**
```
Error: Cannot find cwd: /opt/buildhome/repo/root
Failed: build command exited with code: 1
```

## ✅ **Giải pháp đã áp dụng:**

### **1. Tạo cấu trúc project đúng:**
```
dashboardcl/
├── index.html              # Main dashboard file
├── public/                 # Build output directory
│   └── index.html         # Copied file for deployment
├── wrangler.toml          # Cloudflare configuration
├── build.sh               # Build script
├── package.json           # Project metadata
└── README.md              # Documentation
```

### **2. Cấu hình wrangler.toml:**
```toml
name = "clickmeter-dashboard"
compatibility_date = "2024-01-01"

[env.production]
name = "clickmeter-dashboard"

[[env.production.pages]]
pages_build_output_dir = "public"
```

### **3. Build script (build.sh):**
```bash
#!/bin/bash
echo "Building ClickMeter Dashboard..."
mkdir -p public
cp index.html public/
echo "Build complete! Files ready in public/ directory."
```

## 🚀 **Cách deploy lại:**

### **Method 1: Git Integration (Recommended)**
1. **Push code lên GitHub:**
   ```bash
   git add .
   git commit -m "Fix Cloudflare Pages deployment"
   git push origin main
   ```

2. **Cloudflare Pages Settings:**
   - **Build command**: `./build.sh`
   - **Build output directory**: `public`
   - **Root directory**: `/`

### **Method 2: Direct Upload**
1. **Chạy build script:**
   ```bash
   ./build.sh
   ```

2. **Upload thư mục `public/`** lên Cloudflare Pages

## 🔧 **Cloudflare Pages Build Settings:**

- **Framework preset**: None
- **Build command**: `./build.sh`
- **Build output directory**: `public`
- **Root directory**: `/`
- **Node.js version**: 18.x

## 📊 **Kiểm tra deployment:**

1. **Build logs** sẽ hiển thị:
   ```
   Building ClickMeter Dashboard...
   Build complete! Files ready in public/ directory.
   ```

2. **Deploy thành công** → Access dashboard tại URL được cung cấp

3. **Test functionality:**
   - Login với Supabase credentials
   - View dashboard data
   - Test real-time updates

## 🚨 **Nếu vẫn gặp lỗi:**

1. **Kiểm tra build command** trong Cloudflare Pages settings
2. **Đảm bảo build.sh có quyền execute** (`chmod +x build.sh`)
3. **Kiểm tra Node.js version** (recommend 18.x)
4. **Verify file structure** trong repository

## ✅ **Expected Result:**

- ✅ Build command runs successfully
- ✅ Files copied to `public/` directory
- ✅ Dashboard accessible via Cloudflare Pages URL
- ✅ All features working (auth, charts, real-time)

---

**🎯 Project đã được fix và sẵn sàng deploy lại!**
