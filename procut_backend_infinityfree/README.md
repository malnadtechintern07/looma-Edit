# ProCut Admin Panel & Backend Dynamic Control Center
**Complete Self-Hosted PHP & MySQL Backend with Full Dynamic Content Management**

This package contains the complete, production-ready backend and admin dashboard for **ProCut** (Video & Photo Editor Mobile App). Every aspect of the mobile application—from home banners, AI prompts, video templates, filters, effects, editor tools, watermark, and theme colors to push notifications, user cloud projects, and legal policies—is dynamically controllable via this admin panel in real time.

---

## 🚀 Quick Deployment Guide

### 1. Database Setup
1. Open your database manager (such as **phpMyAdmin**, **MySQL Workbench**, or the command line).
2. Create a new MySQL database (e.g. `procut_db` or your hosting DB name).
3. Import `schema.sql`:
   ```bash
   mysql -u root -p procut_db < schema.sql
   ```
   *(In phpMyAdmin, simply click the **Import** tab and choose `schema.sql`)*.
4. *(Optional)* To populate all 100+ creative AI video and photo presets, import `database/seed_ai_presets.sql` or click **"Sync AI Presets"** inside the Admin Panel under **AI Edit Studio**.

---

### 2. Configure Database Credentials
Edit `config/config.php` (or `config.json`):
```php
// Localhost / Development:
define('DB_HOST', '127.0.0.1');
define('DB_PORT', '3306');
define('DB_NAME', 'procut_db');
define('DB_USER', 'root');
define('DB_PASS', '');

// Production / InfinityFree / cPanel:
define('DB_HOST', 'your_sql_host.com');
define('DB_NAME', 'your_database_name');
define('DB_USER', 'your_database_user');
define('DB_PASS', 'your_database_password');
```
*Tip: The backend automatically detects localhost vs remote hosting (like InfinityFree / cPanel / VPS) and applies the corresponding credentials.*

---

### 3. Default Super Admin Login
Open your web browser and navigate to:
```
https://your-domain.com/admin/login.php
```
- **Username / Email**: `admin` or `admin@procut.app`
- **Default Password**: `Admin@123456`
*(You can change your password immediately after logging in from Account & Session → Change Password)*.

---

### 4. Running Locally (No XAMPP required)
You can start a local development server in seconds:
```bash
# Using PHP built-in server:
php -S 0.0.0.0:5050 router.php

# OR using the included Python server:
python3 server.py
```
Then visit `http://localhost:5050/admin` in your browser.

---

## 🎛️ Complete Dynamic Control Features

Every screen, asset, layout, and setting in the ProCut mobile app is driven dynamically by this admin panel:

### 1. 🎨 Theme Colors & Visual Branding (`admin/settings.php`)
- **Theme Mode**: Light Mode, Dark Mode, or Auto System.
- **Brand Colors**: Configure Primary Color, Secondary Color, Accent Color, Background Color, Surface Color, and Text Colors with live color pickers.
- **Branding Assets**: Update App Name, Splash Screen Title, Splash Background Color, Logo URL, and Top Bar Announcement Banner.

### 2. 📱 Dynamic Navigation & Home Screen Feed (`admin/home-sections.php` & `admin/settings.php`)
- **Navigation Tabs**: Rename tabs (Home, Projects, Templates, Me), re-order tabs, and show/hide individual tabs.
- **Home Feed Modules**: Toggle Hero Header, Promo Banners, Quick Creation Tools, Recent Projects, Template Preview Carousel, and Aspect Ratio Quick Filters.
- **Section Ordering**: Arrange home sections in any display sequence.

### 3. 🛠️ Video & Photo Editor Tools Ordering (`admin/settings.php` → Editor Tools)
- **Video Editor Toolbar**: Re-order or toggle all 24 tools: Add Media, Split, Reorder, Speed, Volume, Animation, Effects, Mask, Chroma Key, Filters, Adjust, Overlay, Keyframe, Duplicate, Replace, Crop, Text, Stickers, Voiceover, Audio Mix, Transitions, Captions, Delete.
- **Photo Editor Toolbar**: Re-order or toggle all 17 photo tools: Enhance, Remove BG, AutoCut, Retouch, Crop, Adjust, Filters, Draw, Text, Stickers, Resize, HSL, Curves, Layout, Collage, Watermark, Import.

### 4. 🤖 AI Edit Studio & Prompt Presets (`admin/ai_edits.php`)
- **Prompt Presets**: Create, edit, and delete photo and video AI prompt presets.
- **Parameters**: Control prompt text, negative prompt, reference image URL, preview video URL, model name, art style, camera movement, lighting, seed, duration, and tags.
- **One-Click Sync**: Pre-loaded with 100+ creative prompts for Cyberpunk, Anime, Cinematic, 3D Render, Fantasy, and Vintage.

### 5. 🎬 Video Templates Studio (`admin/templates.php`)
- Create multi-track video templates with full project JSON draft support.
- Manage aspect ratios (16:9, 9:16, 1:1, 4:5, 21:9), clip count, duration, tags, audio tracks, and preview videos.
- Categorize by Trending, Popular, New, Vlog, Travel, Reels, TikTok, Gaming.

### 6. 🌈 Filters, Video Effects & Transitions
- **Filters & LUTs (`admin/filters.php`)**: Add custom 5x4 RGBA color matrices, categories, and Pro-only flags.
- **Video Effects (`admin/effects.php`)**: Manage glitch, VHS, cinema, sparkle, blur, and light leak effects.
- **Transitions (`admin/transitions.php`)**: Control cut, zoom, wipe, and dissolve transitions.
- **Clip Animations (`admin/animations.php`)**: Configure keyframe entrance/exit animations.

### 7. 🎵 Music & Audio Library (`admin/music.php`)
- Upload royalty-free MP3/WAV tracks directly through the admin panel.
- Set artist, duration, categories (Vlog, Beats, Ambient, Cinematic, Upbeat), and Pro badges.

### 8. ✨ Stickers & Clipart Manager (`admin/stickers.php`)
- Upload PNG/SVG stickers, emojis, animated clipart, and aesthetic overlays.
- Filter by categories with instant visual thumbnail grids.

### 9. 📢 Push Notifications & Firebase FCM (`admin/notifications.php`)
- Integrated with **Firebase Cloud Messaging (FCM) v1 HTTP API**.
- Compose and broadcast notifications to all app users or specific topics.
- History log with delivery status, timestamps, and real-time synchronization to the in-app Notification Center.

### 10. 🏷️ Watermark Engine & Export Configuration (`admin/watermark.php`)
- Visual preview for watermark placement: Bottom-Right, Bottom-Left, Top-Right, Top-Left.
- Custom watermark text, logo upload, opacity slider (10%–100%), and scale factor.
- Enforce watermark on Free tier while unlocking clean export for PRO subscribers.
- Configure default video export frame rate (24, 30, 60 FPS) and resolution (720p, 1080p, 4K).

### 11. 📜 Privacy Policy & Terms of Service (`admin/privacy-policy.php`)
- Pre-seeded with India's **Digital Personal Data Protection Act (DPDP Act), 2023** compliance policy.
- Configure Grievance Officer details (Officer name, email address).
- Interactive Live Preview mirroring the mobile app layout with word count and character count metrics.

### 12. 💬 Support, About Us & Social Growth (`admin/settings.php`)
- **Direct Support**: Support email, phone, WhatsApp direct chat link, and website URL.
- **About Info**: App description, company name, copyright statement, and version string.
- **Social Links**: Instagram, YouTube, Twitter/X, TikTok, and Discord channels.
- **App Growth**: In-app "Rate Us" dialog toggle, custom store review URL, "Share App" message and link.

### 13. 🛡️ Maintenance Mode & Force Update (`admin/settings.php`)
- **Maintenance Mode**: Toggle scheduled maintenance instantly without app store redeployment. Shows custom alert banner in the app while keeping offline editing functional.
- **Force Update**: Specify minimum required version (`min_app_version`) and latest version (`app_version`) with store redirect link and custom update prompt.

### 14. 👥 Users & Cloud Project Backups (`admin/users.php` & `admin/projects.php`)
- Search, filter, inspect, and manage registered mobile users.
- Toggle PRO subscription status with one click.
- Inspect and monitor cloud-backed project timeline drafts and storage usage.

### 15. 🔐 Staff Management & Audit Logs (`admin/admins.php` & `admin/activity-logs.php`)
- Role-based permissions (`superadmin`, `admin`, `editor`).
- Detailed audit log tracking every login, setting change, asset upload, and update.

---

## 📡 REST API Endpoints for Mobile App

The mobile application communicates with these high-performance endpoints:

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/app/config.php` | `GET` | Fetches ALL dynamic branding, theme colors, navigation, home layout, editor tools, watermark, support, legal, social, and maintenance settings |
| `/api/app/content.php` | `GET` | Fetches active features, templates, AI presets, effects, filters, transitions, animations, music, stickers, and banners |
| `/api/app/notifications.php` | `GET` | Returns notifications feed for in-app notification center |
| `/api/app/register-fcm-token.php` | `POST` | Registers device FCM token for push notification delivery |
| `/api/app/support-ticket.php` | `POST` | Submits user support tickets with system diagnostics |
| `/api/auth/register.php` | `POST` | Mobile user registration |
| `/api/auth/login.php` | `POST` | Mobile user sign-in |
| `/api/projects/backup.php` | `POST` | Cloud timeline project backup |
| `/api/projects/index.php` | `GET` | Lists user's backed-up projects |
| `/api/health.php` | `GET` | Server & database connection health check |

---

## 📂 Directory Structure

```
├── admin/                     # Admin Dashboard Frontend & Controllers
│   ├── includes/              # Shared Sidebar, Header, Navbar, Footer
│   ├── dashboard.php          # Analytics & Overview
│   ├── users.php              # User Management & Pro Toggles
│   ├── projects.php           # User Cloud Backups
│   ├── home-sections.php      # Home Screen Module Reordering
│   ├── features.php           # Quick Creation Tools Manager
│   ├── banners.php            # Promotional Banners & CTAs
│   ├── notifications.php      # Push Notifications & FCM Broadcaster
│   ├── ai_edits.php           # AI Prompt Presets Studio
│   ├── templates.php          # Video Templates Manager
│   ├── effects.php            # Video Effects Manager
│   ├── filters.php            # Filters & LUTs Color Matrices
│   ├── transitions.php        # Video Transitions Manager
│   ├── animations.php         # Clip Animations Manager
│   ├── music.php              # Music & Audio Library (Uploads)
│   ├── stickers.php           # Stickers & Clipart Manager (Uploads)
│   ├── watermark.php          # Watermark Engine & Export Configuration
│   ├── privacy-policy.php     # Legal Policies & DPDP Act Live Editor
│   ├── settings.php           # Dynamic Control Center (Branding, Theme, Navigation, Tools, Updates)
│   ├── admins.php             # Staff & Role-Based Permissions
│   ├── activity-logs.php      # Audit Trail & System Logs
│   ├── login.php / logout.php # Administrative Authentication
│   └── change-password.php    # Password Reset & Security
├── api/                       # High-Performance JSON REST APIs
│   ├── app/                   # App Configuration, Content & Notifications
│   ├── auth/                  # User Auth & Profile APIs
│   ├── projects/              # Cloud Sync & Backup APIs
│   └── templates/             # Template Assets APIs
├── config/                    # Configuration Files
│   ├── config.php             # Database credentials & App Constants
│   ├── database.php           # Robust PDO Connection Manager
│   └── firebase-service-account.json  # FCM Private Key (Optional)
├── database/                  # Database Seed Scripts
│   ├── seed_ai_presets.sql    # 100+ Creative AI Prompt Presets
│   ├── seed_ai_presets.php    # Seeding script
│   └── seed_25_templates.php  # 25 Initial Video Templates
├── helpers/                   # Utility Classes (Auth, Response, FCM, Sanitizer)
├── uploads/                   # Uploaded media (music, stickers, thumbnails, banners)
├── .htaccess                  # Apache rewrite rules & security headers
├── router.php                 # PHP built-in server router
├── schema.sql                 # Complete MySQL schema & initial seed data
└── server.py                  # Standalone Python local server
```

---

## 🔒 Security Best Practices Built-In
- **PDO Prepared Statements** across all database interactions to prevent SQL injection.
- **CSRF Token Validation** on all admin forms and POST actions.
- **Session Expiry & Hijacking Protection** with user-agent and IP binding.
- **Bcrypt / Argon2 Password Hashing** for all administrative and user credentials.
- **Strict File Upload Validation** (MIME type checking and extension whitelisting for images and audio).
- **Graceful Error Handling** with suppressed stack traces in production.

---
© 2026 ProCut Studio. All rights reserved.
