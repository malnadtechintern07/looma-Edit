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
$defaultPrivacy = "Privacy Policy\nLast updated 28 September 2026\n\nThis policy explains what personal data PusherHub collects, why, and what you can do about it. It covers the hosted PusherHub service at this website — the website, the dashboard, the REST API and the SDKs. It doesn't cover copies of PusherHub that other people host on their own servers.\n\nPusherHub is operated by Harsha (\"we\", \"us\"), who is responsible for your personal data under India's Digital Personal Data Protection Act, 2023.\n\nThe app does use third-party services that may collect information used to identify you.\nLink to the privacy policy of third-party service providers used by the app:\n• Google Play Services\n• AdMob\n• Google Analytics for Firebase\n• Firebase Crashlytics\n• Facebook\n• PusherHub\n\nTwo kinds of data\nYour account data is about you, as a PusherHub customer. We decide how it's used, and this policy explains how.\nYour app users' data is about the people who use the apps you connect to PusherHub. You decide what's collected and why; we store and process it only to deliver your notifications and messages, on your instructions. If you're one of those app users, the app's own privacy policy applies, and the app's developer is the right person to contact first.\n\nWhat we collect about you\nAccount details — your name, email address and password. Passwords are stored only as a secure hash; we can't see them.\nGoogle sign-in — if you sign in with Google, we receive your name, email address, Google account ID and profile picture. We don't get your Google password or access to anything else in your Google account.\nSign-in records — when you last signed in, and the IP address used to ask for a sign-in or password-reset code. The codes themselves are stored only as a hash and deleted once they expire.\nPayments — the plan you bought, the amount, the date and status, and the Razorpay order and payment IDs. Your card, UPI or bank details go straight to Razorpay; we never receive or store them.\nWhat you set up in PusherHub — your apps, the Firebase service account you connect, API keys, notifications, templates, segments, topics, in-app messages and webhook addresses. Firebase service accounts and API secret keys are stored encrypted.\nServer logs — like most websites, our servers record requests (IP address, time, page and browser) for security and troubleshooting.\n\nWhat PusherHub stores about your app users\nWhen your app registers a device with PusherHub, through our SDK or API, we store:\nthe device's Firebase messaging token, platform, brand and model, app version, language and timezone;\nwhether the user has allowed notifications, and when the device was last active;\na user ID, only if your app sends one;\nan approximate location — country, state and city — worked out from the device's IP address. The IP address itself isn't stored with the device;\nwhat happened to each notification and in-app message: delivered, opened, clicked, shown or dismissed.\n\nHow we use data\nTo run the Service: sign you in, send your notifications and messages, and show your analytics.\nTo apply your plan's limits and features, and to process your payments.\nTo email you sign-in codes, password-reset codes, and important messages about your account or the Service.\nTo keep PusherHub secure: block abuse, limit repeated sign-in attempts and investigate problems.\nTo meet our legal, tax and accounting obligations.\nWe don't sell personal data, we don't show ads, and we don't use your app users' data for any purpose of our own.\n\nCookies\nWe only use the cookies the site needs to work:\na session cookie that keeps you signed in;\na security token (XSRF-TOKEN) that protects forms against cross-site request forgery;\na \"remember me\" cookie, only if you tick that box when you sign in.\nWe don't use analytics or advertising cookies. Some pages load services from other companies, which may set their own cookies or see your IP address: fonts from Google Fonts on our public pages, Google Sign-In on the sign-in page, and Razorpay Checkout when you pay.\n\nWho we share data with\nWe share personal data only with the service providers that help us run PusherHub, and only what they need:\nGoogle (Firebase Cloud Messaging) — to deliver push notifications, through the Firebase project you connect;\nGoogle (Sign-In) — if you choose to sign in with Google;\nRazorpay — to process payments;\nour hosting provider, which runs the servers PusherHub is on, and our email provider, which delivers sign-in and reset codes.\nWe may also disclose data where the law requires it — for example, a valid order from a court or government authority — or where it's needed to protect the rights, property or safety of our users or the public. Some providers, such as Google, may process data outside India under their own privacy and security commitments.\n\nHow long we keep data\nAccount data — for as long as you have an account. When you ask us to delete your account, we delete your account data together with the apps, devices and messages in it.\nPayment records — for as long as Indian tax and accounting law requires, even after your account is deleted.\nSign-in and reset codes — deleted once they expire.\nApp users' devices — removed after they've been inactive for the period set for each app, or when you delete the app.\nDelivery and engagement records — kept while your account exists, so your analytics keep working.\nServer logs — kept only as long as they're needed for security and troubleshooting.\n\nHow we protect data\nPasswords and sign-in codes are hashed. Firebase service accounts and API secret keys are encrypted. Each customer can see only their own apps and data, and sign-in attempts are rate-limited. No system is perfectly secure, but if a breach affects your personal data, we'll tell you and the authorities as the law requires.\n\nYour rights\nUnder India's Digital Personal Data Protection Act, 2023, you can:\nask for a summary of the personal data we hold about you and how we use it;\nask us to correct, complete or update it;\nask us to delete it, unless the law requires us to keep it;\nwithdraw your consent — which may mean closing your account;\nnominate someone to exercise these rights for you if you die or can't act yourself;\nraise a grievance with us and, if you're not satisfied with our answer, complain to the Data Protection Board of India.\nYou can change your password at any time with Forgot password? on the sign-in page. For anything else, contact our Grievance Officer below.\n\nChildren\nPusherHub is a service for businesses and developers, and isn't meant for anyone under 18. If you believe a child has created an account, contact us and we'll delete it.\n\nChanges to this policy\nWhen we change this policy, we update the date at the top. If a change is significant, we'll tell you by email or in the dashboard before it takes effect.\n\nContact and Grievance Officer\nFor questions, requests or complaints about your personal data:\nGrievance Officer: Harsha\nEmail: harsha.malnadtech@gmail.com\nWe'll acknowledge your request and respond within the time limits set by Indian law.";

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
