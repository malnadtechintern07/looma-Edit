<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';

Response::cors();

$settingsRows = Database::fetchAll("SELECT setting_key, setting_value, setting_group FROM app_settings");
$settings = [];
foreach ($settingsRows as $row) {
    $settings[$row['setting_key']] = $row['setting_value'];
}

// Helper: parse 0xFF... hex colour strings
function parseColour(string $hex, string $fallback): string {
    return !empty($hex) ? $hex : $fallback;
}

// Video / Photo editor tools from JSON
function parseToolsJson(?string $json, array $fallback = []): array {
    if (!$json) return $fallback;
    $decoded = json_decode($json, true);
    return is_array($decoded) ? $decoded : $fallback;
}

$videoToolsFallback = [
    ["key"=>"add_media","label"=>"Add Media","icon"=>"add_photo_alternate","enabled"=>true,"order"=>1],
    ["key"=>"split","label"=>"Split","icon"=>"splitscreen","enabled"=>true,"order"=>2],
    ["key"=>"reorder","label"=>"Reorder","icon"=>"reorder","enabled"=>true,"order"=>3],
    ["key"=>"speed","label"=>"Speed","icon"=>"speed","enabled"=>true,"order"=>4],
    ["key"=>"volume","label"=>"Volume","icon"=>"volume_up","enabled"=>true,"order"=>5],
    ["key"=>"animation","label"=>"Animation","icon"=>"animation","enabled"=>true,"order"=>6],
    ["key"=>"effects","label"=>"Effects","icon"=>"auto_fix_high","enabled"=>true,"order"=>7],
    ["key"=>"mask","label"=>"Mask","icon"=>"masks","enabled"=>true,"order"=>8],
    ["key"=>"chroma_key","label"=>"Chroma Key","icon"=>"colorize","enabled"=>true,"order"=>9],
    ["key"=>"filters","label"=>"Filters","icon"=>"filter_vintage","enabled"=>true,"order"=>10],
    ["key"=>"adjust","label"=>"Adjust","icon"=>"tune","enabled"=>true,"order"=>11],
    ["key"=>"overlay","label"=>"Overlay","icon"=>"layers","enabled"=>true,"order"=>12],
    ["key"=>"keyframe","label"=>"Keyframe","icon"=>"diamond_outlined","enabled"=>true,"order"=>13],
    ["key"=>"duplicate","label"=>"Duplicate","icon"=>"control_point_duplicate","enabled"=>true,"order"=>14],
    ["key"=>"replace","label"=>"Replace","icon"=>"swap_horiz","enabled"=>true,"order"=>15],
    ["key"=>"crop","label"=>"Crop/Frame","icon"=>"crop","enabled"=>true,"order"=>16],
    ["key"=>"text","label"=>"Text","icon"=>"title","enabled"=>true,"order"=>17],
    ["key"=>"stickers","label"=>"Stickers","icon"=>"emoji_emotions","enabled"=>true,"order"=>18],
    ["key"=>"voiceover","label"=>"Voiceover","icon"=>"mic","enabled"=>true,"order"=>19],
    ["key"=>"audio_mix","label"=>"Audio Mix","icon"=>"equalizer","enabled"=>true,"order"=>20],
    ["key"=>"transitions","label"=>"Transitions","icon"=>"transform","enabled"=>true,"order"=>21],
    ["key"=>"add_clip","label"=>"Add Clip","icon"=>"add_to_photos","enabled"=>true,"order"=>22],
    ["key"=>"captions","label"=>"Captions","icon"=>"subtitles","enabled"=>true,"order"=>23],
    ["key"=>"delete","label"=>"Delete","icon"=>"delete_outline","enabled"=>true,"order"=>24],
];
$photoToolsFallback = [
    ["key"=>"enhance","label"=>"Enhance","icon"=>"auto_awesome","enabled"=>true,"order"=>1],
    ["key"=>"remove_bg","label"=>"Remove BG","icon"=>"layers_clear","enabled"=>true,"order"=>2],
    ["key"=>"autocut","label"=>"AutoCut","icon"=>"content_cut","enabled"=>true,"order"=>3],
    ["key"=>"retouch","label"=>"Retouch","icon"=>"face_retouching_natural","enabled"=>true,"order"=>4],
    ["key"=>"crop","label"=>"Crop","icon"=>"crop","enabled"=>true,"order"=>5],
    ["key"=>"adjust","label"=>"Adjust","icon"=>"tune","enabled"=>true,"order"=>6],
    ["key"=>"filters","label"=>"Filters","icon"=>"filter_hdr","enabled"=>true,"order"=>7],
    ["key"=>"draw","label"=>"Draw","icon"=>"brush","enabled"=>true,"order"=>8],
    ["key"=>"text","label"=>"Text","icon"=>"text_fields","enabled"=>true,"order"=>9],
    ["key"=>"stickers","label"=>"Stickers","icon"=>"emoji_emotions","enabled"=>true,"order"=>10],
    ["key"=>"resize","label"=>"Resize","icon"=>"aspect_ratio","enabled"=>true,"order"=>11],
    ["key"=>"hsl","label"=>"HSL","icon"=>"colorize","enabled"=>true,"order"=>12],
    ["key"=>"curves","label"=>"Curves","icon"=>"show_chart","enabled"=>true,"order"=>13],
    ["key"=>"layout","label"=>"Layout","icon"=>"grid_goldenratio","enabled"=>true,"order"=>14],
    ["key"=>"collage","label"=>"Collage","icon"=>"dashboard","enabled"=>true,"order"=>15],
    ["key"=>"watermark","label"=>"Watermark","icon"=>"verified","enabled"=>true,"order"=>16],
    ["key"=>"import","label"=>"Import","icon"=>"add_a_photo","enabled"=>true,"order"=>17],
];

// Parse navigation order
$navOrder = array_map('trim', explode(',', $settings['nav_tabs_order'] ?? 'home,projects,templates,me'));

// Default legal text if not configured in DB
$defaultPrivacy = "PROCut PRIVACY COMMITMENT\n\nYour media belongs to you. ProCut is engineered with a strict offline-first architecture: your source videos, voiceovers, photos, and project timelines are processed directly on your device and never uploaded to public clouds without your explicit direction.\n\n1. OFFLINE-FIRST PROCESSING & MEDIA STORAGE\nAll video trimming, timeline slicing, multi-track layering, filter rendering, and audio ducking take place strictly within your mobile device's native hardware. ProCut does not transmit your source video clips, photos, or voiceover recordings to our servers for processing.\n\n2. DEVICE PERMISSIONS & PURPOSE\n• Photos, Media & Storage: Required solely to import video clips into your editing timeline and export rendered MP4 videos into your camera roll (DCIM/Movies).\n• Microphone: Requested only when you intentionally record a custom voiceover track in the audio timeline.\n• Camera: Used only if you choose to record new footage directly inside the media picker.\n• Notifications: Used to notify you when background video rendering or cloud backup is completed.\nWe never access, index, or scan any files, photos, or audio recordings outside of what you explicitly select for your project.\n\n3. OPTIONAL CLOUD SYNC & ACCOUNT DATA\nIf you register for a ProCut Cloud account, we store your account email, securely hashed password, and project metadata. When you choose to back up a project, your project JSON draft is transmitted over TLS 1.3 encryption and stored in a private storage vault accessible only by your authenticated session.\n\n4. CACHE & TEMPORARY VIDEO FRAGMENTS\nDuring video playback, preview thumbnails and audio waveform caches are saved in your app temporary sandbox for stutter-free performance. You can purge this cache anytime in the app settings under \"Clear Temporary Cache\" without losing any saved project drafts.\n\n5. ZERO ADVERTISING & NO THIRD-PARTY DATA SELLING\nProCut contains no advertising tracking SDKs, no behavioral trackers, and no third-party data brokers. We never sell, rent, or monetize your creative media, exported clips, email addresses, or personal information under any circumstance.\n\n6. USER RIGHTS & COMPLETE DATA DELETION\nYou retain full ownership of your content. You have the right to export your data, clear all cloud backups, or delete your ProCut account and associated data entirely at any time. Deleting a cloud project immediately purges its files from our cloud storage servers.\n\n7. POLICY UPDATES & CONTACT\nWe may occasionally update this Privacy Policy to reflect app enhancements or legal requirements. Any modifications will be updated directly in this app.\nFor questions, data requests, or privacy inquiries, please contact our support team at support@procut.app.";

$defaultTerms = "TERMS & CONDITIONS\n\n1. ACCEPTANCE OF TERMS\nBy downloading, installing, or using ProCut (\"the App\"), you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the App.\n\n2. LICENSE & USAGE RIGHTS\nProCut grants you a personal, non-exclusive, non-transferable, revocable license to use the App for personal or commercial video editing and creation in accordance with these Terms.\n\n3. USER CONTENT & OWNERSHIP\nYou retain 100% intellectual property ownership of all videos, audio files, images, and projects created or edited within ProCut. You are solely responsible for ensuring you have the legal right to use any third-party copyrighted music, audio, or footage in your projects.\n\n4. SUBSCRIPTIONS & IN-APP PURCHASES\nProCut offers optional Pro features, including watermark removal, 4K 60FPS export, and premium AI tools. Subscriptions and one-time purchases are processed securely through Google Play Billing and are subject to Google Play store refund policies.\n\n5. PROHIBITED USES\nYou agree not to reverse engineer, decompile, or tamper with the App's binary code, circumvent DRM or licensing protections, or use the App to produce or distribute unlawful, harmful, or infringing content.\n\n6. DISCLAIMER OF WARRANTIES & LIMITATION OF LIABILITY\nProCut is provided on an \"as-is\" and \"as-available\" basis. While we strive for seamless multi-track performance, we are not liable for any lost data, corrupt project files, or hardware rendering failures. Always maintain backups of your vital media.\n\n7. TERMINATION & MODIFICATIONS\nWe reserve the right to modify these Terms at any time. Continued use of the App following updates constitutes your acceptance of the updated Terms.\n\n8. CONTACT US\nFor questions or support regarding these Terms, contact us at support@procut.app.";

Response::success([
    'appName'    => $settings['app_name'] ?? 'ProCut',
    'appVersion' => $settings['app_version'] ?? APP_VERSION,

    // Branding
    'branding' => [
        'appName'             => $settings['app_name'] ?? 'ProCut',
        'logoUrl'             => $settings['app_logo_url'] ?? '',
        'splashMessage'       => $settings['splash_message'] ?? 'Welcome to ProCut',
        'splashBgColor'       => $settings['splash_bg_color'] ?? '0xFF084298',
        'splashIconUrl'       => $settings['splash_icon_url'] ?? '',
        'announcementEnabled' => ($settings['announcement_enabled'] ?? '0') === '1',
        'announcementTitle'   => $settings['announcement_title'] ?? '',
        'announcementMessage' => $settings['announcement_message'] ?? '',
    ],

    // Theme & Colors
    'theme' => [
        'mode'            => $settings['theme_mode'] ?? 'light',
        'primaryColor'    => parseColour($settings['primary_color'] ?? '', '0xFF0D6EFD'),
        'secondaryColor'  => parseColour($settings['secondary_color'] ?? '', '0xFF00C2CB'),
        'accentColor'     => parseColour($settings['accent_color'] ?? '', '0xFFFFB800'),
        'backgroundColor' => parseColour($settings['background_color'] ?? '', '0xFFF8F9FE'),
        'surfaceColor'    => parseColour($settings['surface_color'] ?? '', '0xFFFFFFFF'),
        'textPrimaryColor'=> parseColour($settings['text_primary_color'] ?? '', '0xFF111827'),
        'textSecondaryColor'=> parseColour($settings['text_secondary_color'] ?? '', '0xFF6B7280'),
    ],

    // Navigation
    'navigation' => [
        'tabsOrder'        => $navOrder,
        'homeTitle'        => $settings['nav_home_title'] ?? 'Home',
        'homeEnabled'      => ($settings['nav_home_enabled'] ?? '1') === '1',
        'projectsTitle'    => $settings['nav_projects_title'] ?? 'Projects',
        'projectsEnabled'  => ($settings['nav_projects_enabled'] ?? '1') === '1',
        'templatesTitle'   => $settings['nav_templates_title'] ?? 'Templates',
        'templatesEnabled' => ($settings['nav_templates_enabled'] ?? '1') === '1',
        'meTitle'          => $settings['nav_me_title'] ?? 'Me',
        'meEnabled'        => ($settings['nav_me_enabled'] ?? '1') === '1',
    ],

    // Home Layout
    'homeLayout' => [
        'heroHeaderEnabled'       => ($settings['home_hero_header_enabled'] ?? '1') === '1',
        'bannerEnabled'           => ($settings['home_banner_enabled'] ?? '1') === '1',
        'quickToolsEnabled'       => ($settings['home_quick_tools_enabled'] ?? '1') === '1',
        'recentProjectsEnabled'   => ($settings['home_recent_projects_enabled'] ?? '1') === '1',
        'templatePreviewEnabled'  => ($settings['home_templates_preview_enabled'] ?? '1') === '1',
        'ratioFilterEnabled'      => ($settings['home_ratio_filter_enabled'] ?? '1') === '1',
    ],

    // Editor Tools
    'videoEditorTools' => parseToolsJson($settings['video_editor_tools_json'] ?? null, $videoToolsFallback),
    'photoEditorTools' => parseToolsJson($settings['photo_editor_tools_json'] ?? null, $photoToolsFallback),

    // Watermark
    'watermark' => [
        'enabledFree' => ($settings['watermark_enabled_free'] ?? '1') === '1',
        'text'        => $settings['watermark_text'] ?? 'PROCUT',
        'logoUrl'     => $settings['watermark_logo_url'] ?? '',
        'position'    => $settings['watermark_position'] ?? 'bottomRight',
        'size'        => (float)($settings['watermark_size'] ?? 0.8),
        'opacity'     => (float)($settings['watermark_opacity'] ?? 0.8),
    ],

    // Support & Contact
    'support' => [
        'email'          => $settings['support_email'] ?? 'support@procut.app',
        'phone'          => $settings['support_phone'] ?? '',
        'whatsapp'       => $settings['support_whatsapp'] ?? '',
        'website'        => $settings['support_website'] ?? 'https://procut.app',
        'helpCenterUrl'  => $settings['help_center_url'] ?? '',
    ],

    // Legal
    'legal' => [
        'privacyPolicyContent'     => !empty(trim($settings['privacy_policy_content'] ?? '')) ? $settings['privacy_policy_content'] : $defaultPrivacy,
        'termsConditionsContent'   => !empty(trim($settings['terms_conditions_content'] ?? '')) ? $settings['terms_conditions_content'] : $defaultTerms,
        'aboutDescription'         => $settings['about_app_description'] ?? 'Pro Mobile Video Editor.',
        'aboutCompanyName'         => $settings['about_company_name'] ?? 'ProCut Studio',
        'copyrightText'            => $settings['about_copyright_text'] ?? '© 2025 ProCut Studio.',
    ],

    // Social & Growth
    'social' => [
        'instagramUrl'  => $settings['social_instagram_url'] ?? '',
        'youtubeUrl'    => $settings['social_youtube_url'] ?? '',
        'twitterUrl'    => $settings['social_twitter_url'] ?? '',
        'tiktokUrl'     => $settings['social_tiktok_url'] ?? '',
        'discordUrl'    => $settings['social_discord_url'] ?? '',
        'rateUsEnabled' => ($settings['rate_us_enabled'] ?? '1') === '1',
        'rateUsStoreUrl'=> $settings['rate_us_store_url'] ?? 'https://play.google.com/store',
        'shareAppEnabled'   => ($settings['share_app_enabled'] ?? '1') === '1',
        'shareAppMessage'   => $settings['share_app_message'] ?? 'Check out ProCut!',
        'shareAppUrl'       => $settings['share_app_url'] ?? 'https://procut.app',
    ],

    // Versioning & Update
    'versioning' => [
        'appVersion'          => $settings['app_version'] ?? APP_VERSION,
        'minAppVersion'       => $settings['min_app_version'] ?? '1.0.0',
        'forceUpdate'         => ($settings['force_update_enabled'] ?? '0') === '1',
        'updateDialogTitle'   => $settings['update_dialog_title'] ?? 'Update Available',
        'updateDialogMessage' => $settings['update_dialog_message'] ?? 'Please update ProCut to the latest version.',
        'updateStoreUrl'      => $settings['update_store_url'] ?? 'https://play.google.com/store',
    ],

    // Maintenance
    'maintenance' => [
        'enabled'  => ($settings['maintenance_mode'] ?? '0') === '1',
        'title'    => $settings['maintenance_title'] ?? 'Scheduled Maintenance',
        'message'  => $settings['maintenance_message'] ?? 'ProCut Cloud is temporarily undergoing scheduled maintenance.',
    ],

    // Storage & System Defaults
    'storage' => [
        'maxFreeProjects' => (int)($settings['max_free_cloud_projects'] ?? 10),
        'maxProProjects'  => (int)($settings['max_pro_cloud_projects'] ?? 100),
    ],
    'export' => [
        'defaultFps'        => (int)($settings['default_export_fps'] ?? 30),
        'defaultResolution' => $settings['default_export_resolution'] ?? '1080p',
        'autoSaveGallery'   => ($settings['auto_save_gallery_default'] ?? '1') === '1',
    ],
    'allowUserRegistration' => ($settings['allow_user_registration'] ?? '1') === '1',

    // Legacy compatibility fields (kept so existing code doesn't break)
    'minAppVersion'      => $settings['min_app_version'] ?? '1.0.0',
    'forceUpdate'        => ($settings['force_update_enabled'] ?? '0') === '1',
    'maintenanceMode'    => ($settings['maintenance_mode'] ?? '0') === '1',
    'maintenanceMessage' => $settings['maintenance_message'] ?? 'Service temporarily unavailable for maintenance.',
    'homeSections'       => Database::fetchAll(
        "SELECT section_key, title, subtitle, display_order, is_enabled
         FROM home_sections WHERE is_enabled = 1 ORDER BY display_order ASC"
    ),
    'settings'           => $settings,
]);
