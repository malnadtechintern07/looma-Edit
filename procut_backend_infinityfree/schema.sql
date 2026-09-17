-- ProCut Complete MySQL Database Schema
-- Run this script in MySQL Workbench, phpMyAdmin, or mysql CLI:
-- mysql -u root < schema.sql

CREATE DATABASE IF NOT EXISTS procut_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE procut_db;

-- 1. Admins Table
CREATE TABLE IF NOT EXISTS admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role ENUM('superadmin', 'admin', 'editor') NOT NULL DEFAULT 'admin',
    permissions TEXT NULL,
    avatar VARCHAR(500) NULL,
    status ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
    reset_token_hash VARCHAR(255) NULL,
    reset_token_expires_at DATETIME NULL,
    last_login_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_admin_email (email),
    INDEX idx_admin_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Users Table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255) DEFAULT '',
    is_pro TINYINT(1) DEFAULT 1,
    avatar_url VARCHAR(500) NULL,
    bio TEXT NULL,
    handle VARCHAR(100) NULL,
    status ENUM('active', 'banned', 'suspended') NOT NULL DEFAULT 'active',
    reset_token_hash VARCHAR(255) NULL,
    reset_token_expires_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_email (email),
    INDEX idx_user_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Sessions & Authentication Tokens Table
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NULL,
    admin_id INT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    token_type ENUM('user', 'admin', 'reset') NOT NULL DEFAULT 'user',
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(500) NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_session_token (token_hash),
    INDEX idx_session_user (user_id),
    INDEX idx_session_admin (admin_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Projects Table (Timelines & Cloud Backups)
CREATE TABLE IF NOT EXISTS projects (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    aspect_ratio VARCHAR(32) DEFAULT 'ratio9_16',
    duration_ms INT DEFAULT 0,
    fps INT DEFAULT 30,
    thumbnail_url VARCHAR(500) NULL,
    project_json LONGTEXT NOT NULL,
    is_cloud_synced TINYINT(1) DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_proj_user_id (user_id),
    INDEX idx_proj_user_email (user_email),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Project Files & Media Uploads
CREATE TABLE IF NOT EXISTS project_files (
    id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    file_type ENUM('video', 'audio', 'image', 'thumbnail') NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_pf_project (project_id),
    INDEX idx_pf_user (user_id),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Home Screen Sections
CREATE TABLE IF NOT EXISTS home_sections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    section_key VARCHAR(100) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255) NULL,
    display_order INT DEFAULT 0,
    is_enabled TINYINT(1) DEFAULT 1,
    meta_json LONGTEXT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hs_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Features & Quick Action Tools
CREATE TABLE IF NOT EXISTS features (
    id INT AUTO_INCREMENT PRIMARY KEY,
    feature_key VARCHAR(100) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255) NULL,
    icon_name VARCHAR(100) NOT NULL,
    category VARCHAR(100) DEFAULT 'quick_tool',
    display_order INT DEFAULT 0,
    is_enabled TINYINT(1) DEFAULT 1,
    is_pro_only TINYINT(1) DEFAULT 0,
    badge_text VARCHAR(50) NULL,
    action_route VARCHAR(255) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_features_order (display_order),
    INDEX idx_features_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Templates Table
CREATE TABLE IF NOT EXISTS templates (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    author VARCHAR(255) NOT NULL DEFAULT 'ProCut Originals',
    aspect_ratio VARCHAR(32) DEFAULT 'ratio9_16',
    duration_ms INT DEFAULT 10000,
    clips_count INT DEFAULT 6,
    downloads_count INT DEFAULT 0,
    preview_gradient_start VARCHAR(32) DEFAULT '0xFF7C3AED',
    preview_gradient_end VARCHAR(32) DEFAULT '0xFFEC4899',
    preview_video_url VARCHAR(500) NULL,
    audio_title VARCHAR(255) NULL,
    audio_url VARCHAR(500) NULL,
    tags VARCHAR(500) NULL,
    is_pro TINYINT(1) DEFAULT 0,
    is_enabled TINYINT(1) DEFAULT 1,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_templates_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Video Effects Table
CREATE TABLE IF NOT EXISTS effects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    effect_key VARCHAR(100) NOT NULL UNIQUE,
    label VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'Trending',
    description TEXT NULL,
    icon_name VARCHAR(100) NOT NULL,
    color1 VARCHAR(32) DEFAULT '0xFF2C2F38',
    color2 VARCHAR(32) DEFAULT '0xFF1E2028',
    is_pro TINYINT(1) DEFAULT 0,
    is_enabled TINYINT(1) DEFAULT 1,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_effects_order (display_order),
    INDEX idx_effects_cat (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Filters Table (LUTs and Color Matrices)
CREATE TABLE IF NOT EXISTS filters (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filter_key VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255) NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'Cinematic & Film',
    color_matrix_json TEXT NULL,
    is_pro TINYINT(1) DEFAULT 0,
    is_enabled TINYINT(1) DEFAULT 1,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_filters_order (display_order),
    INDEX idx_filters_cat (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Transitions Table
CREATE TABLE IF NOT EXISTS transitions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transition_key VARCHAR(100) NOT NULL UNIQUE,
    label VARCHAR(255) NOT NULL,
    description TEXT NULL,
    icon_name VARCHAR(100) DEFAULT 'transition',
    is_pro TINYINT(1) DEFAULT 0,
    is_enabled TINYINT(1) DEFAULT 1,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_transitions_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Clip Animations Table
CREATE TABLE IF NOT EXISTS animations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    animation_key VARCHAR(100) NOT NULL UNIQUE,
    label VARCHAR(255) NOT NULL,
    category VARCHAR(100) DEFAULT 'in',
    is_pro TINYINT(1) DEFAULT 0,
    is_enabled TINYINT(1) DEFAULT 1,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_animations_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. Music & Audio Library Table
CREATE TABLE IF NOT EXISTS music (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'Upbeat',
    duration_ms INT DEFAULT 60000,
    audio_url VARCHAR(500) NOT NULL,
    waveform_json TEXT NULL,
    is_pro TINYINT(1) DEFAULT 0,
    is_enabled TINYINT(1) DEFAULT 1,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_music_order (display_order),
    INDEX idx_music_cat (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. Stickers & Overlays Table
CREATE TABLE IF NOT EXISTS stickers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sticker_key VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'Vlog',
    image_url VARCHAR(500) NOT NULL,
    is_pro TINYINT(1) DEFAULT 0,
    is_enabled TINYINT(1) DEFAULT 1,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_stickers_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. Promotional & Announcement Banners Table
CREATE TABLE IF NOT EXISTS banners (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255) NULL,
    badge_text VARCHAR(50) NULL,
    button_text VARCHAR(100) NULL,
    action_route VARCHAR(255) NULL,
    image_url VARCHAR(500) NULL,
    gradient_start VARCHAR(32) DEFAULT '0xFF084298',
    gradient_end VARCHAR(32) DEFAULT '0xFF0D6EFD',
    placement VARCHAR(50) DEFAULT 'home_top',
    is_enabled TINYINT(1) DEFAULT 1,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_banners_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. In-App Notifications & Announcements Table
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('info', 'announcement', 'update', 'promotion') NOT NULL DEFAULT 'info',
    target_user_id VARCHAR(64) NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notif_target (target_user_id),
    INDEX idx_notif_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. App Settings & Version Information Table
CREATE TABLE IF NOT EXISTS app_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value LONGTEXT NOT NULL,
    setting_group VARCHAR(100) DEFAULT 'general',
    description VARCHAR(255) NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 18. Subscriptions Table
CREATE TABLE IF NOT EXISTS subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    plan_name VARCHAR(100) NOT NULL DEFAULT 'Pro Monthly',
    status ENUM('active', 'expired', 'cancelled', 'trial') NOT NULL DEFAULT 'active',
    starts_at DATETIME NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sub_user (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19. Activity Logs Table
CREATE TABLE IF NOT EXISTS activity_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    actor_type ENUM('admin', 'user', 'system') NOT NULL,
    actor_id VARCHAR(64) NOT NULL,
    actor_name VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    details TEXT NULL,
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(500) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_act_actor (actor_type, actor_id),
    INDEX idx_act_action (action),
    INDEX idx_act_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- SEED INITIAL DATA

-- 1. Default Super Admin (Username: admin, Email: admin@procut.app, Pass: Admin@123456)
INSERT INTO admins (id, username, email, password_hash, name, role, permissions, status)
VALUES (
    1,
    'admin',
    'admin@procut.app',
    '$2y$10$NKsnkk2/WWGn7xgOJmV1ReFs0/pW/8obAxenP3JHGNq2r7uJ2Zzdm',
    'ProCut Super Admin',
    'superadmin',
    '["all"]',
    'active'
) ON DUPLICATE KEY UPDATE
    password_hash = VALUES(password_hash),
    role = VALUES(role),
    status = VALUES(status);

-- 2. Home Sections
INSERT INTO home_sections (section_key, title, subtitle, display_order, is_enabled) VALUES
('hero_header', 'Sapphire Header', 'Video create & quick access header', 1, 1),
('cta_banner', 'Cloud Sync Banner', 'Registration and cloud sync CTA', 2, 1),
('quick_tools', 'Creation Tools Grid', 'AutoCut, Retouch, Photo Tools, etc.', 3, 1),
('recent_projects', 'Recent Projects', 'User timeline projects and drafts', 4, 1),
('templates_preview', 'Trending Templates', 'Hot viral templates feed preview', 5, 1)
ON DUPLICATE KEY UPDATE title = VALUES(title), is_enabled = VALUES(is_enabled);

-- 3. Features & Quick Tools
INSERT INTO features (feature_key, title, subtitle, icon_name, category, display_order, is_enabled, is_pro_only, badge_text, action_route) VALUES
('new_video', 'New video', 'Start from device video clips', 'add_circle', 'hero_card', 1, 1, 0, NULL, '/editor'),
('edit_photo', 'Edit photo', 'Collage & photo editor studio', 'image', 'hero_card', 2, 1, 0, NULL, '/photo-editor'),
('post_template', 'Post template', 'Trending viral templates', 'movie_creation_outlined', 'quick_tool', 3, 1, 0, 'Hot', '/templates'),
('autocut', 'AutoCut', 'AI beat-synced smart edits', 'video_library_outlined', 'quick_tool', 4, 1, 0, 'AI', '/autocut'),
('retouch', 'Retouch', 'Portrait face beautify & smooth', 'face_retouching_natural_outlined', 'quick_tool', 5, 1, 0, NULL, '/retouch'),
('photo_tools', 'Photo tools', 'Batch filters, cutout & frames', 'photo_filter_outlined', 'quick_tool', 6, 1, 0, NULL, '/photo-tools'),
('shoot_record', 'Shoot & record', 'Live camera & studio teleprompter', 'camera_alt_outlined', 'quick_tool', 7, 1, 0, NULL, '/camera'),
('auto_enhance', 'Auto enhance', 'HDR cinema dynamic range boost', 'auto_awesome_outlined', 'quick_tool', 8, 1, 1, 'PRO', '/enhance'),
('auto_captions', 'Auto captions', 'Speech-to-text subtitle generator', 'closed_caption_outlined', 'quick_tool', 9, 1, 1, 'PRO', '/captions'),
('remove_bg', 'Remove bg', 'Instant AI portrait background removal', 'person_pin_circle_outlined', 'quick_tool', 10, 1, 1, 'PRO', '/remove-bg'),
('cloud_space', 'Cloud Space', 'Encrypted cloud backup storage', 'cloud_outlined', 'quick_tool', 11, 1, 0, 'Sync', '/cloud')
ON DUPLICATE KEY UPDATE title = VALUES(title), display_order = VALUES(display_order);

-- 4. Initial Templates
INSERT INTO templates (id, title, description, author, aspect_ratio, duration_ms, clips_count, downloads_count, preview_gradient_start, preview_gradient_end, audio_title, audio_url, tags, is_pro, is_enabled, display_order) VALUES
('tmpl-viral-phonk', '🔥 Viral Phonk Drift Reel', 'Fast rhythmic cuts, heavy bass drop transitions, and neon subtitle styling.', 'ProCut Originals', 'ratio9_16', 10000, 6, 38400, '0xFF7C3AED', '0xFFEC4899', 'Phonk Bass Boosted (130 BPM)', 'assets/demo/phonk_beat.mp3', 'Trending, Phonk, Reels, TikTok, Viral', 0, 1, 1),
('tmpl-summer-tropical', '🌴 Summer Tropical Vlog', 'Warm film grain, upbeat tropical rhythm, and smooth cross-fade slide transitions.', 'Nordic Visuals', 'ratio9_16', 14000, 7, 29800, '0xFFF59E0B', '0xFF10B981', 'Sunset Tropical House Beats', 'assets/demo/tropical_beat.mp3', 'Vlog, Summer, Travel, Aesthetic', 0, 1, 2),
('tmpl-hype-reel', '⚡ Fast Cuts Cyberpunk Reel', 'High-energy glitch cuts with neon subtitle animations and beat drops.', 'Cyber Studio', 'ratio9_16', 9000, 6, 14200, '0xFF8B5CF6', '0xFF06B6D4', 'Neon Synthwave Drive', 'assets/demo/synthwave_beat.mp3', 'Cyberpunk, Glitch, Edits, FastCuts', 0, 1, 3),
('tmpl-vlog-minimal', '✨ Minimalist Day-in-the-Life', 'Aesthetic typography, subtle film texture, and relaxing lofi rhythm.', 'Minimal Co', 'ratio9_16', 15000, 5, 19800, '0xFFD97706', '0xFFB45309', 'Midnight LoFi Chillout', 'assets/demo/lofi_beat.mp3', 'Minimalist, DailyVlog, LoFi, Aesthetic', 0, 1, 4),
('tmpl-cinematic-youtube', '🎬 Cinematic Widescreen Intro', 'Epic letterbox 16:9 presentation with orchestral crescendo and bold title.', 'Studio Horizon', 'ratio16_9', 12000, 4, 22100, '0xFF1E3A8A', '0xFF065F46', 'Orchestral Cinematic Crescendo', 'assets/demo/cinematic_audio.mp3', 'YouTube, 16:9, Cinematic, Intro', 1, 1, 5)
ON DUPLICATE KEY UPDATE title = VALUES(title), is_enabled = VALUES(is_enabled);

-- 5. Video Effects
INSERT INTO effects (effect_key, label, category, description, icon_name, color1, color2, is_pro, is_enabled, display_order) VALUES
('explosion', 'Explosion', 'Trending', 'Fiery gold shockwave particle blast', 'local_fire_department', '0xFFFF9900', '0xFFFF3300', 0, 1, 1),
('videoCam', 'Video Cam', 'Trending', 'Vintage camcorder viewfinder with REC & crosshairs', 'videocam_outlined', '0xFF4A90E2', '0xFF1B2A47', 0, 1, 2),
('rollingFilm', 'Rolling Film', 'Trending', 'Vintage 35mm film sprockets with rolling scanlines', 'movie_filter', '0xFF434343', '0xFF000000', 0, 1, 3),
('phoneDrift', 'Phone Drift', 'Trending', 'Smooth floating handheld camera drift, inertia swing', 'screen_rotation', '0xFF5C258D', '0xFF4389A2', 0, 1, 4),
('lightningCloud', 'Lightning Cloud', 'Trending', 'Thunderstorm dark clouds with electric branching bolts', 'thunderstorm_outlined', '0xFF1A2980', '0xFF26D0CE', 1, 1, 5),
('crossSplit', 'Cross Split', 'Trending', '4-panel cross split screen with quad mirrors', 'grid_view_rounded', '0xFF11998E', '0xFF38EF7D', 0, 1, 6),
('flash', 'Flash', 'Trending', 'High-speed luminous white strobe pulse', 'flash_on', '0xFFFF007A', '0xFFFF5E36', 0, 1, 7),
('glitch', 'RGB Glitch', 'Glitch', 'Chromatic aberration slice and digital glitch', 'broken_image', '0xFF00F2FE', '0xFF4FACFE', 1, 1, 8),
('retroVhs', 'Retro VHS', 'Retro', '90s CRT scanlines with VHS tracking distortion', 'videocam', '0xFF654EA3', '0xFFEAAFC8', 0, 1, 9),
('neonGlow', 'Neon Glow', 'Light Effect', 'Cyberpunk edge luminescent neon shine', 'auto_awesome', '0xFFB92B27', '0xFF1565C0', 1, 1, 10)
ON DUPLICATE KEY UPDATE label = VALUES(label), is_enabled = VALUES(is_enabled);

-- 6. Filters
INSERT INTO filters (filter_key, name, subtitle, category, is_pro, is_enabled, display_order) VALUES
('cinematic', 'Cinematic', 'Teal & Orange Hollywood', 'Cinematic & Film', 0, 1, 1),
('vintage', 'Vintage', '70s Kodachrome Film', 'Vintage & Retro', 0, 1, 2),
('warm', 'Warm', 'Sunlit Golden Amber', 'Warm & Sun', 0, 1, 3),
('cool', 'Cool', 'Nordic Frost Breeze', 'Cool & Frost', 0, 1, 4),
('retro', 'Retro', '80s Analog VHS Tape', 'Vintage & Retro', 0, 1, 5),
('film', 'Film', '35mm Fuji Cinema Stock', 'Cinematic & Film', 1, 1, 6),
('moody', 'Moody', 'Low-Key Dark Contrast', 'Cinematic & Film', 1, 1, 7),
('noir', 'Noir B&W', 'Classic Monochromatic', 'B&W & Noir', 0, 1, 8),
('cyberpunk', 'Cyberpunk', 'Neon Magenta & Cyan', 'Artistic & Pop', 1, 1, 9)
ON DUPLICATE KEY UPDATE name = VALUES(name), is_enabled = VALUES(is_enabled);

-- 7. Transitions
INSERT INTO transitions (transition_key, label, description, icon_name, is_pro, is_enabled, display_order) VALUES
('crossFade', 'Cross Fade', 'Smooth blend dissolve between clips', 'gradient', 0, 1, 1),
('slideLeft', 'Slide Left', 'Next clip pushes from the right edge', 'arrow_back', 0, 1, 2),
('slideUp', 'Slide Up', 'Next clip pushes upward from bottom', 'arrow_upward', 0, 1, 3),
('wipeRight', 'Wipe Right', 'Linear wipe revealing next clip', 'swipe_right', 0, 1, 4),
('zoomIn', 'Zoom In', 'Dynamic action lens zoom push', 'zoom_in', 1, 1, 5),
('glitch', 'Glitch Cut', 'Digital chromatic aberration transition', 'broken_image', 1, 1, 6)
ON DUPLICATE KEY UPDATE label = VALUES(label), is_enabled = VALUES(is_enabled);

-- 8. Animations
INSERT INTO animations (animation_key, label, category, is_pro, is_enabled, display_order) VALUES
('fadeIn', 'Fade In', 'in', 0, 1, 1),
('zoomIn', 'Zoom In', 'in', 0, 1, 2),
('slideUp', 'Slide Up', 'in', 0, 1, 3),
('popIn', 'Pop In', 'in', 0, 1, 4),
('spinIn', 'Spin In', 'in', 1, 1, 5),
('glitchIn', 'Glitch Entrance', 'in', 1, 1, 6),
('bounce', 'Bounce', 'combo', 0, 1, 7)
ON DUPLICATE KEY UPDATE label = VALUES(label), is_enabled = VALUES(is_enabled);

-- 9. Music Tracks
INSERT INTO music (id, title, artist, category, duration_ms, audio_url, is_pro, is_enabled, display_order) VALUES
('mus-phonk-1', 'Phonk Bass Boosted', 'Drift Syndicate', 'Phonk', 120000, 'assets/demo/phonk_beat.mp3', 0, 1, 1),
('mus-tropical-1', 'Sunset Tropical House', 'Sol Waves', 'Vlog', 145000, 'assets/demo/tropical_beat.mp3', 0, 1, 2),
('mus-synth-1', 'Neon Synthwave Drive', 'Cyber Pulse', 'Electronic', 110000, 'assets/demo/synthwave_beat.mp3', 0, 1, 3),
('mus-lofi-1', 'Midnight LoFi Chillout', 'Coffee & Rain', 'Lo-Fi', 150000, 'assets/demo/lofi_beat.mp3', 0, 1, 4),
('mus-cinema-1', 'Orchestral Cinematic Epic', 'Hans Anthem', 'Cinematic', 180000, 'assets/demo/cinematic_audio.mp3', 1, 1, 5)
ON DUPLICATE KEY UPDATE title = VALUES(title), is_enabled = VALUES(is_enabled);

-- 10. Stickers
INSERT INTO stickers (sticker_key, name, category, image_url, is_pro, is_enabled, display_order) VALUES
('stk_fire', 'Fire Flame', 'Reels', 'assets/stickers/fire.png', 0, 1, 1),
('stk_heart', 'Glowing Heart', 'Love', 'assets/stickers/heart.png', 0, 1, 2),
('stk_star', 'Golden Star', 'Celebration', 'assets/stickers/star.png', 0, 1, 3),
('stk_sparkle', 'Sparkles Glow', 'Vlog', 'assets/stickers/sparkle.png', 0, 1, 4),
('stk_verified', 'Verified Badge', 'Social', 'assets/stickers/verified.png', 1, 1, 5)
ON DUPLICATE KEY UPDATE name = VALUES(name), is_enabled = VALUES(is_enabled);

-- 11. Banners
INSERT INTO banners (title, subtitle, badge_text, button_text, action_route, gradient_start, gradient_end, placement, is_enabled, display_order) VALUES
('Cloud Backup & Sync', 'Sign in or register to secure your timeline projects in the cloud.', 'SYNC', 'Sign In / Register Account', '/auth', '0xFF084298', '0xFF0D6EFD', 'home_top', 1, 1),
('Unlock ProCut PRO', 'Export in 4K 60FPS without watermark, unlock all AI tools and 50+ effects.', 'PRO', 'Upgrade to Pro', '/pro', '0xFF7C3AED', '0xFFEC4899', 'export_screen', 1, 2)
ON DUPLICATE KEY UPDATE title = VALUES(title), is_enabled = VALUES(is_enabled);

-- 12. App Settings
INSERT INTO app_settings (setting_key, setting_value, setting_group, description) VALUES
('app_name', 'ProCut', 'general', 'Official application name'),
('app_version', '1.0.0', 'version', 'Current production app version'),
('min_app_version', '1.0.0', 'version', 'Minimum supported app version for force update'),
('force_update_enabled', '0', 'version', 'Force users to update if below min_app_version'),
('maintenance_mode', '0', 'general', 'Temporarily disable cloud sync and API with maintenance alert'),
('maintenance_message', 'ProCut Cloud is currently undergoing scheduled maintenance. Offline editing remains fully functional.', 'general', 'Notice displayed during maintenance'),
('watermark_enabled_free', '1', 'watermark', 'Force watermark on video export for free users'),
('watermark_text', 'PROCUT', 'watermark', 'Watermark text displayed on exported videos'),
('watermark_position', 'bottomRight', 'watermark', 'Watermark position: bottomRight, bottomLeft, topRight, topLeft'),
('max_free_cloud_projects', '10', 'storage', 'Maximum cloud backup slots for free tier accounts'),
('max_pro_cloud_projects', '100', 'storage', 'Maximum cloud backup slots for PRO tier accounts'),
('default_export_fps', '30', 'export', 'Default video export frame rate'),
('allow_user_registration', '1', 'auth', 'Allow new user registration from app')
ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value);
