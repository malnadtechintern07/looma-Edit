<?php
$pageTitle = 'Dynamic App Control Center';
require_once __DIR__ . '/includes/auth_check.php';

$error   = '';
$success = '';
$activeTab = $_GET['tab'] ?? 'branding';

$defaultPrivacyPolicy = "Privacy Policy\nLast updated 28 September 2026\n\nThis policy explains what personal data PusherHub collects, why, and what you can do about it. It covers the hosted PusherHub service at this website — the website, the dashboard, the REST API and the SDKs. It doesn't cover copies of PusherHub that other people host on their own servers.\n\nPusherHub is operated by Harsha (\"we\", \"us\"), who is responsible for your personal data under India's Digital Personal Data Protection Act, 2023.\n\nThe app does use third-party services that may collect information used to identify you.\nLink to the privacy policy of third-party service providers used by the app:\n• Google Play Services\n• AdMob\n• Google Analytics for Firebase\n• Firebase Crashlytics\n• Facebook\n• PusherHub\n\nTwo kinds of data\nYour account data is about you, as a PusherHub customer. We decide how it's used, and this policy explains how.\nYour app users' data is about the people who use the apps you connect to PusherHub. You decide what's collected and why; we store and process it only to deliver your notifications and messages, on your instructions. If you're one of those app users, the app's own privacy policy applies, and the app's developer is the right person to contact first.\n\nWhat we collect about you\nAccount details — your name, email address and password. Passwords are stored only as a secure hash; we can't see them.\nGoogle sign-in — if you sign in with Google, we receive your name, email address, Google account ID and profile picture. We don't get your Google password or access to anything else in your Google account.\nSign-in records — when you last signed in, and the IP address used to ask for a sign-in or password-reset code. The codes themselves are stored only as a hash and deleted once they expire.\nPayments — the plan you bought, the amount, the date and status, and the Razorpay order and payment IDs. Your card, UPI or bank details go straight to Razorpay; we never receive or store them.\nWhat you set up in PusherHub — your apps, the Firebase service account you connect, API keys, notifications, templates, segments, topics, in-app messages and webhook addresses. Firebase service accounts and API secret keys are stored encrypted.\nServer logs — like most websites, our servers record requests (IP address, time, page and browser) for security and troubleshooting.\n\nWhat PusherHub stores about your app users\nWhen your app registers a device with PusherHub, through our SDK or API, we store:\nthe device's Firebase messaging token, platform, brand and model, app version, language and timezone;\nwhether the user has allowed notifications, and when the device was last active;\na user ID, only if your app sends one;\nan approximate location — country, state and city — worked out from the device's IP address. The IP address itself isn't stored with the device;\nwhat happened to each notification and in-app message: delivered, opened, clicked, shown or dismissed.\n\nHow we use data\nTo run the Service: sign you in, send your notifications and messages, and show your analytics.\nTo apply your plan's limits and features, and to process your payments.\nTo email you sign-in codes, password-reset codes, and important messages about your account or the Service.\nTo keep PusherHub secure: block abuse, limit repeated sign-in attempts and investigate problems.\nTo meet our legal, tax and accounting obligations.\nWe don't sell personal data, we don't show ads, and we don't use your app users' data for any purpose of our own.\n\nCookies\nWe only use the cookies the site needs to work:\na session cookie that keeps you signed in;\na security token (XSRF-TOKEN) that protects forms against cross-site request forgery;\na \"remember me\" cookie, only if you tick that box when you sign in.\nWe don't use analytics or advertising cookies. Some pages load services from other companies, which may set their own cookies or see your IP address: fonts from Google Fonts on our public pages, Google Sign-In on the sign-in page, and Razorpay Checkout when you pay.\n\nWho we share data with\nWe share personal data only with the service providers that help us run PusherHub, and only what they need:\nGoogle (Firebase Cloud Messaging) — to deliver push notifications, through the Firebase project you connect;\nGoogle (Sign-In) — if you choose to sign in with Google;\nRazorpay — to process payments;\nour hosting provider, which runs the servers PusherHub is on, and our email provider, which delivers sign-in and reset codes.\nWe may also disclose data where the law requires it — for example, a valid order from a court or government authority — or where it's needed to protect the rights, property or safety of our users or the public. Some providers, such as Google, may process data outside India under their own privacy and security commitments.\n\nHow long we keep data\nAccount data — for as long as you have an account. When you ask us to delete your account, we delete your account data together with the apps, devices and messages in it.\nPayment records — for as long as Indian tax and accounting law requires, even after your account is deleted.\nSign-in and reset codes — deleted once they expire.\nApp users' devices — removed after they've been inactive for the period set for each app, or when you delete the app.\nDelivery and engagement records — kept while your account exists, so your analytics keep working.\nServer logs — kept only as long as they're needed for security and troubleshooting.\n\nHow we protect data\nPasswords and sign-in codes are hashed. Firebase service accounts and API secret keys are encrypted. Each customer can see only their own apps and data, and sign-in attempts are rate-limited. No system is perfectly secure, but if a breach affects your personal data, we'll tell you and the authorities as the law requires.\n\nYour rights\nUnder India's Digital Personal Data Protection Act, 2023, you can:\nask for a summary of the personal data we hold about you and how we use it;\nask us to correct, complete or update it;\nask us to delete it, unless the law requires us to keep it;\nwithdraw your consent — which may mean closing your account;\nnominate someone to exercise these rights for you if you die or can't act yourself;\nraise a grievance with us and, if you're not satisfied with our answer, complain to the Data Protection Board of India.\nYou can change your password at any time with Forgot password? on the sign-in page. For anything else, contact our Grievance Officer below.\n\nChildren\nPusherHub is a service for businesses and developers, and isn't meant for anyone under 18. If you believe a child has created an account, contact us and we'll delete it.\n\nChanges to this policy\nWhen we change this policy, we update the date at the top. If a change is significant, we'll tell you by email or in the dashboard before it takes effect.\n\nContact and Grievance Officer\nFor questions, requests or complaints about your personal data:\nGrievance Officer: Harsha\nEmail: harsha.malnadtech@gmail.com\nWe'll acknowledge your request and respond within the time limits set by Indian law.";

$defaultTermsConditions = "TERMS & CONDITIONS\n\n1. ACCEPTANCE OF TERMS\nBy downloading, installing, or using ProCut (\"the App\"), you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the App.\n\n2. LICENSE & USAGE RIGHTS\nProCut grants you a personal, non-exclusive, non-transferable, revocable license to use the App for personal or commercial video editing and creation in accordance with these Terms.\n\n3. USER CONTENT & OWNERSHIP\nYou retain 100% intellectual property ownership of all videos, audio files, images, and projects created or edited within ProCut. You are solely responsible for ensuring you have the legal right to use any third-party copyrighted music, audio, or footage in your projects.\n\n4. SUBSCRIPTIONS & IN-APP PURCHASES\nProCut offers optional Pro features, including watermark removal, 4K 60FPS export, and premium AI tools. Subscriptions and one-time purchases are processed securely through Google Play Billing and are subject to Google Play store refund policies.\n\n5. PROHIBITED USES\nYou agree not to reverse engineer, decompile, or tamper with the App's binary code, circumvent DRM or licensing protections, or use the App to produce or distribute unlawful, harmful, or infringing content.\n\n6. DISCLAIMER OF WARRANTIES & LIMITATION OF LIABILITY\nProCut is provided on an \"as-is\" and \"as-available\" basis. While we strive for seamless multi-track performance, we are not liable for any lost data, corrupt project files, or hardware rendering failures. Always maintain backups of your vital media.\n\n7. TERMINATION & MODIFICATIONS\nWe reserve the right to modify these Terms at any time. Continued use of the App following updates constitutes your acceptance of the updated Terms.\n\n8. CONTACT US\nFor questions or support regarding these Terms, contact us at support@procut.app.";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $tab = $_POST['active_tab'] ?? 'branding';

        if ($tab === 'branding') {
            $fields = ['app_name','splash_message','splash_bg_color','splash_icon_url','announcement_title','announcement_message'];
            foreach ($fields as $k) {
                if (isset($_POST[$k])) {
                    Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [trim($_POST[$k]), $k]);
                }
            }
            $announcementEnabled = isset($_POST['announcement_enabled']) ? '1' : '0';
            Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'announcement_enabled'", [$announcementEnabled]);

        } elseif ($tab === 'theme') {
            $colorFields = ['theme_mode','primary_color','secondary_color','accent_color','background_color','surface_color','text_primary_color','text_secondary_color'];
            foreach ($colorFields as $k) {
                if (isset($_POST[$k])) {
                    Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [trim($_POST[$k]), $k]);
                }
            }

        } elseif ($tab === 'navigation') {
            $navFields = ['nav_home_title','nav_projects_title','nav_templates_title','nav_me_title','nav_tabs_order'];
            foreach ($navFields as $k) {
                if (isset($_POST[$k])) {
                    Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [trim($_POST[$k]), $k]);
                }
            }
            foreach (['nav_home_enabled','nav_projects_enabled','nav_templates_enabled','nav_me_enabled'] as $k) {
                Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [isset($_POST[$k]) ? '1' : '0', $k]);
            }
            // Home Layout
            $homeToggles = ['home_hero_header_enabled','home_banner_enabled','home_quick_tools_enabled','home_recent_projects_enabled','home_templates_preview_enabled','home_ratio_filter_enabled'];
            foreach ($homeToggles as $k) {
                Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [isset($_POST[$k]) ? '1' : '0', $k]);
            }

        } elseif ($tab === 'editor_tools') {
            if (!empty($_POST['video_editor_tools_json'])) {
                Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'video_editor_tools_json'", [trim($_POST['video_editor_tools_json'])]);
            }
            if (!empty($_POST['photo_editor_tools_json'])) {
                Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'photo_editor_tools_json'", [trim($_POST['photo_editor_tools_json'])]);
            }

        } elseif ($tab === 'watermark') {
            $wmFields = ['watermark_text','watermark_logo_url','watermark_position','watermark_size','default_export_fps'];
            foreach ($wmFields as $k) {
                if (isset($_POST[$k])) {
                    Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [trim($_POST[$k]), $k]);
                }
            }
            Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'watermark_enabled_free'", [isset($_POST['watermark_enabled_free']) ? '1' : '0']);
            if (isset($_POST['watermark_opacity'])) {
                Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'watermark_opacity'", [trim($_POST['watermark_opacity'])]);
            }
            if (isset($_POST['watermark_size'])) {
                Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'watermark_size'", [trim($_POST['watermark_size'])]);
            }

        } elseif ($tab === 'support') {
            $supportFields = ['support_email','support_phone','support_whatsapp','support_website','help_center_url','about_app_description','about_company_name','about_copyright_text'];
            foreach ($supportFields as $k) {
                if (isset($_POST[$k])) {
                    $val = trim($_POST[$k]);
                    Database::query(
                        "INSERT INTO app_settings (setting_key, setting_value, setting_group) 
                         VALUES (?, ?, 'support') 
                         ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)",
                        [$k, $val]
                    );
                }
            }
            // Long-text legal fields (upsert into app_settings)
            foreach (['privacy_policy_content','terms_conditions_content'] as $k) {
                if (isset($_POST[$k])) {
                    $val = $_POST[$k];
                    Database::query(
                        "INSERT INTO app_settings (setting_key, setting_value, setting_group) 
                         VALUES (?, ?, 'legal') 
                         ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)",
                        [$k, $val]
                    );
                }
            }

        } elseif ($tab === 'social') {
            $socialFields = ['social_instagram_url','social_youtube_url','social_twitter_url','social_tiktok_url','social_discord_url','rate_us_store_url','share_app_message','share_app_url'];
            foreach ($socialFields as $k) {
                if (isset($_POST[$k])) {
                    Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [trim($_POST[$k]), $k]);
                }
            }
            Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'rate_us_enabled'", [isset($_POST['rate_us_enabled']) ? '1' : '0']);
            Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'share_app_enabled'", [isset($_POST['share_app_enabled']) ? '1' : '0']);

        } elseif ($tab === 'versioning') {
            $versionFields = ['app_version','min_app_version','update_dialog_title','update_dialog_message','update_store_url','maintenance_title','maintenance_message','max_free_cloud_projects','max_pro_cloud_projects'];
            foreach ($versionFields as $k) {
                if (isset($_POST[$k])) {
                    Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [trim($_POST[$k]), $k]);
                }
            }
            Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'force_update_enabled'", [isset($_POST['force_update_enabled']) ? '1' : '0']);
            Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'maintenance_mode'", [isset($_POST['maintenance_mode']) ? '1' : '0']);
            Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'allow_user_registration'", [isset($_POST['allow_user_registration']) ? '1' : '0']);
        }

        Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'app_config_updated', "Updated [{$tab}] configuration from Dynamic Control Center");
        $success = 'Settings saved successfully.';
        $activeTab = $tab;
    }
}

// Fetch ALL settings
$settingsRows = Database::fetchAll("SELECT setting_key, setting_value FROM app_settings");
$s = [];
foreach ($settingsRows as $row) $s[$row['setting_key']] = $row['setting_value'];

// Auto-seed legal settings if empty in DB (fail-safe)
try {
    if (empty($s['privacy_policy_content'])) {
        Database::query(
            "INSERT INTO app_settings (setting_key, setting_value, setting_group, description) 
             VALUES ('privacy_policy_content', ?, 'legal', 'App Privacy Policy plain text content') 
             ON DUPLICATE KEY UPDATE setting_value = IF(setting_value = '' OR setting_value IS NULL, VALUES(setting_value), setting_value)",
            [$defaultPrivacyPolicy]
        );
        $s['privacy_policy_content'] = $defaultPrivacyPolicy;
    }
    if (empty($s['terms_conditions_content'])) {
        Database::query(
            "INSERT INTO app_settings (setting_key, setting_value, setting_group, description) 
             VALUES ('terms_conditions_content', ?, 'legal', 'App Terms & Conditions plain text content') 
             ON DUPLICATE KEY UPDATE setting_value = IF(setting_value = '' OR setting_value IS NULL, VALUES(setting_value), setting_value)",
            [$defaultTermsConditions]
        );
        $s['terms_conditions_content'] = $defaultTermsConditions;
    }
} catch (\Throwable $e) {
    if (empty($s['privacy_policy_content'])) $s['privacy_policy_content'] = $defaultPrivacyPolicy;
    if (empty($s['terms_conditions_content'])) $s['terms_conditions_content'] = $defaultTermsConditions;
}

// Parse video/photo tools
$videoTools = json_decode($s['video_editor_tools_json'] ?? '[]', true) ?: [];
$photoTools = json_decode($s['photo_editor_tools_json'] ?? '[]', true) ?: [];
usort($videoTools, fn($a,$b) => ($a['order']??99) - ($b['order']??99));
usort($photoTools, fn($a,$b) => ($a['order']??99) - ($b['order']??99));

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';

function sv($s, $key, $default = '') {
    return htmlspecialchars($s[$key] ?? $default);
}
function checked_if($s, $key, $expected = '1') {
    return ($s[$key] ?? '0') === $expected ? 'checked' : '';
}
?>

<style>
.dac-tab-btn { cursor:pointer; border:2px solid transparent; border-radius:12px; padding:10px 18px; background:var(--bs-white); transition:all .2s; font-weight:600; font-size:13px; display:flex; align-items:center; gap:8px; }
.dac-tab-btn:hover { border-color:#0D6EFD22; background:#f0f5ff; }
.dac-tab-btn.active { border-color:#0D6EFD; background:linear-gradient(135deg,#0D6EFD11,#00C2CB11); color:#0D6EFD; }
.dac-panel { display:none; }
.dac-panel.active { display:block; }
.colour-row { display:flex; align-items:center; gap:12px; }
.colour-row input[type=color] { width:44px; height:36px; border-radius:8px; border:1px solid #dee2e6; padding:2px; cursor:pointer; }
.colour-row input[type=text] { font-family:monospace; font-size:13px; }
.tool-row { display:flex; align-items:center; justify-content:space-between; padding:8px 12px; background:#f8f9fe; border-radius:10px; border:1px solid #ecf0f1; margin-bottom:6px; }
.tool-row .form-check-input { width:1.4em; height:1.4em; }
.tool-row .order-badge { font-size:11px; color:#6b7280; background:#e5e7eb; border-radius:6px; padding:2px 7px; font-weight:700; }
.live-preview { background:linear-gradient(135deg, var(--prev-primary,#084298), var(--prev-secondary,#0D6EFD)); border-radius:18px; padding:20px; color:#fff; font-family:Inter,sans-serif; min-height:140px; }
.announcement-box { border-left:4px solid #FFB800; background:#FFFBEB; border-radius:0 12px 12px 0; padding:12px 16px; }
</style>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font"><i class="bi bi-sliders me-2 text-primary"></i>Dynamic App Control Center</h3>
        <p class="text-muted small mb-0">Control every visible and configurable element of the ProCut app without rebuilding the APK.</p>
    </div>
    <div>
        <a href="<?= APP_BASE_URL ?>/api/app/config" target="_blank" class="btn btn-outline-primary btn-sm">
            <i class="bi bi-link-45deg me-1"></i>Live Config API
        </a>
    </div>
</div>

<?php if (!empty($error)): ?>
    <div class="alert alert-danger py-2 px-3 small mb-3"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if (!empty($success)): ?>
    <div class="alert alert-success py-2 px-3 small mb-3"><i class="bi bi-check-circle-fill me-2"></i><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<!-- Tab Navigation -->
<div class="d-flex flex-wrap gap-2 mb-4" id="dacTabs">
    <?php
    $tabs = [
        'branding'     => ['icon'=>'bi-palette2',        'label'=>'Branding'],
        'theme'        => ['icon'=>'bi-droplet-fill',    'label'=>'Colors & Theme'],
        'navigation'   => ['icon'=>'bi-layout-sidebar',  'label'=>'Navigation & Home'],
        'editor_tools' => ['icon'=>'bi-tools',           'label'=>'Editor Tools'],
        'watermark'    => ['icon'=>'bi-shield-check',    'label'=>'Watermark'],
        'support'      => ['icon'=>'bi-headset',         'label'=>'Support & Legal'],
        'social'       => ['icon'=>'bi-share-fill',      'label'=>'Social & Growth'],
        'versioning'   => ['icon'=>'bi-rocket-takeoff',  'label'=>'Versioning & Maintenance'],
    ];
    foreach ($tabs as $tid => $t): ?>
        <button class="dac-tab-btn <?= $activeTab === $tid ? 'active' : '' ?>" onclick="switchTab('<?= $tid ?>')">
            <i class="bi <?= $t['icon'] ?>"></i><?= $t['label'] ?>
        </button>
    <?php endforeach; ?>
</div>

<!-- ===================== BRANDING ===================== -->
<div class="dac-panel <?= $activeTab === 'branding' ? 'active' : '' ?>" id="panel-branding">
<form method="POST"><input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>"><input type="hidden" name="active_tab" value="branding">
<div class="row g-4">
    <div class="col-lg-7">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-app me-2"></i>App Identity</h5>
            <div class="mb-3">
                <label class="form-label small fw-semibold">App Name <span class="text-danger">*</span></label>
                <input type="text" name="app_name" class="form-control" value="<?= sv($s,'app_name','ProCut') ?>" required>
                <small class="text-muted">Displayed in header badge and splash screen.</small>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">App Logo URL</label>
                <input type="url" name="app_logo_url" class="form-control" value="<?= sv($s,'app_logo_url') ?>" placeholder="https://...">
                <small class="text-muted">If set, replaces the default icon in the app header. Leave blank to use default.</small>
            </div>
        </div>
        <div class="pro-card p-4 mt-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-phone me-2"></i>Splash Screen</h5>
            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label small fw-semibold">Splash Message</label>
                    <input type="text" name="splash_message" class="form-control" value="<?= sv($s,'splash_message','Welcome to ProCut') ?>">
                </div>
                <div class="col-md-6">
                    <label class="form-label small fw-semibold">Splash BG Color (hex 0xFFxxxxxx)</label>
                    <input type="text" name="splash_bg_color" class="form-control font-monospace" value="<?= sv($s,'splash_bg_color','0xFF084298') ?>">
                </div>
            </div>
        </div>
        <div class="pro-card p-4 mt-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-megaphone me-2"></i>Announcement Banner</h5>
            <div class="p-3 bg-light rounded-3 border mb-3">
                <div class="form-check form-switch mb-0">
                    <input class="form-check-input" type="checkbox" name="announcement_enabled" id="annSwitch" value="1" <?= checked_if($s,'announcement_enabled') ?>>
                    <label class="form-check-label fw-semibold small" for="annSwitch">Show Announcement Banner to App Users</label>
                    <div class="small text-muted">Displays a dismissible alert on the Home screen.</div>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Announcement Title</label>
                <input type="text" name="announcement_title" class="form-control" value="<?= sv($s,'announcement_title') ?>" placeholder="e.g. New Feature Released!">
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Announcement Message</label>
                <textarea name="announcement_message" class="form-control" rows="2" placeholder="Your announcement text..."><?= sv($s,'announcement_message') ?></textarea>
            </div>
            <?php if (!empty($s['announcement_enabled']) && $s['announcement_enabled'] === '1'): ?>
            <div class="announcement-box">
                <strong><?= sv($s,'announcement_title') ?></strong>
                <p class="mb-0 small mt-1"><?= sv($s,'announcement_message') ?></p>
            </div>
            <?php endif; ?>
        </div>
    </div>
    <div class="col-lg-5">
        <div class="pro-card p-4 text-center" style="background:linear-gradient(135deg,#084298,#0D6EFD,#0284C7); color:#fff; border-radius:20px;">
            <p class="small mb-2 text-white-50">Live Preview</p>
            <img src="<?= defined('APP_BASE_URL') ? APP_BASE_URL : '' ?>/assets/icon/app_icon.png" width="56" height="56" style="border-radius:14px; margin-bottom:10px; box-shadow: 0 4px 16px rgba(0,0,0,0.25);" onerror="this.src='assets/icon/app_icon.png'">
            <h4 class="fw-black mb-0" id="prev_app_name"><?= sv($s,'app_name','ProCut') ?></h4>
            <small class="text-white-50" id="prev_splash_msg"><?= sv($s,'splash_message','Welcome to ProCut') ?></small>
            <?php if (!empty($s['announcement_enabled']) && $s['announcement_enabled'] === '1'): ?>
            <div class="mt-3 p-2 rounded-2" style="background:rgba(255,184,0,.25); border:1px solid #FFB800; font-size:12px;">
                📣 <?= sv($s,'announcement_title') ?>: <?= htmlspecialchars(mb_strimwidth($s['announcement_message']??'', 0, 60, '...')) ?>
            </div>
            <?php endif; ?>
        </div>
    </div>
</div>
<div class="d-flex justify-content-end mt-4"><button type="submit" class="btn btn-primary px-5 py-2 fw-semibold">Save Branding</button></div>
</form></div>

<!-- ===================== THEME & COLORS ===================== -->
<div class="dac-panel <?= $activeTab === 'theme' ? 'active' : '' ?>" id="panel-theme">
<form method="POST"><input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>"><input type="hidden" name="active_tab" value="theme">
<div class="row g-4">
    <div class="col-lg-7">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-droplet-fill me-2"></i>Color Palette</h5>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Theme Mode</label>
                <select name="theme_mode" class="form-select">
                    <?php foreach (['light'=>'Light','dark'=>'Dark','custom'=>'Custom'] as $v => $l): ?>
                        <option value="<?= $v ?>" <?= ($s['theme_mode'] ?? 'light') === $v ? 'selected' : '' ?>><?= $l ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <?php
            $colourFields = [
                'primary_color'       => ['Primary Color (Brand)',         '0xFF0D6EFD', '#0D6EFD'],
                'secondary_color'     => ['Secondary Color (Cyan)',        '0xFF00C2CB', '#00C2CB'],
                'accent_color'        => ['Accent Color (Amber / Gold)',   '0xFFFFB800', '#FFB800'],
                'background_color'    => ['Background Color',              '0xFFF8F9FE', '#F8F9FE'],
                'surface_color'       => ['Surface / Card Color',          '0xFFFFFFFF', '#FFFFFF'],
                'text_primary_color'  => ['Text Primary Color',            '0xFF111827', '#111827'],
                'text_secondary_color'=> ['Text Secondary Color',          '0xFF6B7280', '#6B7280'],
            ];
            foreach ($colourFields as $key => [$label, $def, $css]): ?>
                <div class="mb-3">
                    <label class="form-label small fw-semibold"><?= $label ?></label>
                    <div class="colour-row">
                        <?php
                        $hexVal = $s[$key] ?? $def;
                        $cssHex = '#' . substr($hexVal, 4, 6);
                        ?>
                        <input type="color" value="<?= $cssHex ?>" oninput="syncHex(this,'<?= $key ?>')">
                        <input type="text" name="<?= $key ?>" id="<?= $key ?>" class="form-control font-monospace" value="<?= htmlspecialchars($hexVal) ?>" placeholder="<?= $def ?>" oninput="syncPicker(this,'<?= $key ?>')">
                    </div>
                    <small class="text-muted">Format: 0xFFRRGGBB (e.g. <?= $def ?>)</small>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
    <div class="col-lg-5">
        <div class="pro-card p-3">
            <p class="small fw-semibold mb-2"><i class="bi bi-phone me-1"></i>Live App Preview</p>
            <div id="themePreviewBox" style="border-radius:18px; overflow:hidden; border:6px solid #e5e7eb;">
                <div id="prevHeader" style="background:<?= '#'.substr($s['primary_color']??'0xFF0D6EFD',4,6) ?>; padding:16px; color:#fff;">
                    <div style="font-weight:900; font-size:14px;"><?= sv($s,'app_name','ProCut') ?></div>
                    <div style="font-size:11px; opacity:.7;">Video create · Get started ›</div>
                </div>
                <div id="prevBody" style="background:<?= '#'.substr($s['background_color']??'0xFFF8F9FE',4,6) ?>; padding:14px;">
                    <div id="prevCard" style="background:#fff; border-radius:12px; border:1px solid #e5e7eb; padding:10px; margin-bottom:8px;">
                        <div style="height:10px; border-radius:5px; background:<?= '#'.substr($s['primary_color']??'0xFF0D6EFD',4,6) ?>; width:60%; margin-bottom:6px;"></div>
                        <div style="height:8px; border-radius:4px; background:#e5e7eb; width:80%;"></div>
                    </div>
                    <div style="display:flex; gap:8px;">
                        <?php for ($i=0;$i<3;$i++): ?>
                        <div style="flex:1; background:#fff; border-radius:10px; border:1px solid #e5e7eb; height:56px; display:flex; align-items:center; justify-content:center;">
                            <div style="width:20px; height:20px; border-radius:50%; background:<?= '#'.substr($s['primary_color']??'0xFF0D6EFD',4,6) ?>"></div>
                        </div>
                        <?php endfor; ?>
                    </div>
                </div>
                <div id="prevNav" style="background:#fff; border-top:1px solid #e5e7eb; display:flex; justify-content:space-around; padding:8px 0;">
                    <?php foreach(['Home','Projects','Templates','Me'] as $n): ?>
                    <div style="font-size:10px; font-weight:700; color:<?= '#'.substr($s['primary_color']??'0xFF0D6EFD',4,6) ?>;"><?= $n ?></div>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>
    </div>
</div>
<div class="d-flex justify-content-end mt-4"><button type="submit" class="btn btn-primary px-5 py-2 fw-semibold">Save Colors & Theme</button></div>
</form></div>

<!-- ===================== NAVIGATION & HOME LAYOUT ===================== -->
<div class="dac-panel <?= $activeTab === 'navigation' ? 'active' : '' ?>" id="panel-navigation">
<form method="POST"><input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>"><input type="hidden" name="active_tab" value="navigation">
<div class="row g-4">
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-layout-sidebar me-2"></i>Bottom Navigation Tabs</h5>
            <p class="text-muted small mb-3">Control which tabs appear and what they're called. The app's bottom navigation bar reflects these settings.</p>
            <?php
            $navTabs = [
                ['key'=>'home',      'icon'=>'bi-house-fill',      'iconCode'=>'home_filled'],
                ['key'=>'projects',  'icon'=>'bi-folder-fill',     'iconCode'=>'folder_open'],
                ['key'=>'templates', 'icon'=>'bi-collection-play', 'iconCode'=>'auto_awesome'],
                ['key'=>'me',        'icon'=>'bi-person-fill',     'iconCode'=>'person'],
            ];
            foreach ($navTabs as $nt): $k = $nt['key']; ?>
            <div class="pro-card p-3 mb-3 border">
                <div class="d-flex align-items-center gap-3">
                    <div class="d-flex align-items-center justify-content-center" style="width:40px; height:40px; background:#f0f5ff; border-radius:10px;">
                        <i class="bi <?= $nt['icon'] ?> text-primary"></i>
                    </div>
                    <div class="flex-grow-1">
                        <input type="text" name="nav_<?= $k ?>_title" class="form-control form-control-sm mb-1" value="<?= sv($s,"nav_{$k}_title", ucfirst($k)) ?>" placeholder="Tab Label">
                    </div>
                    <div class="form-check form-switch ms-auto">
                        <input class="form-check-input" type="checkbox" name="nav_<?= $k ?>_enabled" value="1" <?= checked_if($s,"nav_{$k}_enabled") ?>>
                        <label class="form-check-label small">Visible</label>
                    </div>
                </div>
            </div>
            <?php endforeach; ?>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Tab Order (comma-separated)</label>
                <input type="text" name="nav_tabs_order" class="form-control font-monospace" value="<?= sv($s,'nav_tabs_order','home,projects,templates,me') ?>">
                <small class="text-muted">Example: home,projects,templates,me</small>
            </div>
        </div>
    </div>
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-layout-text-window-reverse me-2"></i>Home Screen Sections</h5>
            <p class="text-muted small mb-3">Toggle which sections appear on the main Home dashboard.</p>
            <?php
            $homeToggles = [
                'home_hero_header_enabled'       => ['Hero Header (Gradient Banner)', 'bi-image-fill'],
                'home_banner_enabled'            => ['Cloud Sync / CTA Banner',      'bi-megaphone-fill'],
                'home_quick_tools_enabled'       => ['Quick Creation Tools Grid',    'bi-grid-3x3-gap-fill'],
                'home_recent_projects_enabled'   => ['Recent Projects List',         'bi-clock-history'],
                'home_templates_preview_enabled' => ['Trending Templates Preview',   'bi-collection-play-fill'],
                'home_ratio_filter_enabled'      => ['Aspect Ratio Filter Chips',    'bi-aspect-ratio-fill'],
            ];
            foreach ($homeToggles as $hk => [$hlabel, $hicon]): ?>
            <div class="d-flex align-items-center justify-content-between py-2 border-bottom">
                <div class="d-flex align-items-center gap-2">
                    <i class="bi <?= $hicon ?> text-primary"></i>
                    <span class="small fw-semibold"><?= $hlabel ?></span>
                </div>
                <div class="form-check form-switch mb-0">
                    <input class="form-check-input" type="checkbox" name="<?= $hk ?>" value="1" <?= checked_if($s, $hk) ?>>
                </div>
            </div>
            <?php endforeach; ?>
        </div>
    </div>
</div>
<div class="d-flex justify-content-end mt-4"><button type="submit" class="btn btn-primary px-5 py-2 fw-semibold">Save Navigation & Layout</button></div>
</form></div>

<!-- ===================== EDITOR TOOLS ===================== -->
<div class="dac-panel <?= $activeTab === 'editor_tools' ? 'active' : '' ?>" id="panel-editor_tools">
<form method="POST"><input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>"><input type="hidden" name="active_tab" value="editor_tools">
<div class="alert alert-info small py-2 px-3 mb-4"><i class="bi bi-info-circle me-1"></i>Toggle tools visible in the Video and Photo editor action bars. Disabled tools are hidden from creators. Edit JSON directly to reorder.</div>
<div class="row g-4">
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-film me-2"></i>Video Editor Toolbar</h5>
            <div id="videoToolsList">
            <?php foreach ($videoTools as $i => $tool): ?>
                <div class="tool-row">
                    <div class="d-flex align-items-center gap-2">
                        <span class="order-badge"><?= $tool['order'] ?? ($i+1) ?></span>
                        <span class="small fw-semibold"><?= htmlspecialchars($tool['label'] ?? $tool['key']) ?></span>
                    </div>
                    <div class="form-check form-switch mb-0">
                        <input class="form-check-input video-tool-toggle" type="checkbox" data-key="<?= htmlspecialchars($tool['key']) ?>" <?= ($tool['enabled'] ?? true) ? 'checked' : '' ?>>
                    </div>
                </div>
            <?php endforeach; ?>
            </div>
            <div class="mt-3">
                <label class="form-label small fw-semibold mt-2">Raw JSON Configuration</label>
                <textarea name="video_editor_tools_json" id="videoToolsJson" class="form-control font-monospace" rows="6" style="font-size:11px;"><?= htmlspecialchars($s['video_editor_tools_json'] ?? '[]') ?></textarea>
                <small class="text-muted">Advanced: edit JSON directly for full control over order and labels.</small>
            </div>
        </div>
    </div>
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-image me-2"></i>Photo Editor Toolbar</h5>
            <div id="photoToolsList">
            <?php foreach ($photoTools as $i => $tool): ?>
                <div class="tool-row">
                    <div class="d-flex align-items-center gap-2">
                        <span class="order-badge"><?= $tool['order'] ?? ($i+1) ?></span>
                        <span class="small fw-semibold"><?= htmlspecialchars($tool['label'] ?? $tool['key']) ?></span>
                    </div>
                    <div class="form-check form-switch mb-0">
                        <input class="form-check-input photo-tool-toggle" type="checkbox" data-key="<?= htmlspecialchars($tool['key']) ?>" <?= ($tool['enabled'] ?? true) ? 'checked' : '' ?>>
                    </div>
                </div>
            <?php endforeach; ?>
            </div>
            <div class="mt-3">
                <label class="form-label small fw-semibold mt-2">Raw JSON Configuration</label>
                <textarea name="photo_editor_tools_json" id="photoToolsJson" class="form-control font-monospace" rows="6" style="font-size:11px;"><?= htmlspecialchars($s['photo_editor_tools_json'] ?? '[]') ?></textarea>
            </div>
        </div>
    </div>
</div>
<div class="d-flex justify-content-end mt-4"><button type="submit" class="btn btn-primary px-5 py-2 fw-semibold">Save Editor Tool Settings</button></div>
</form></div>

<!-- ===================== WATERMARK ===================== -->
<div class="dac-panel <?= $activeTab === 'watermark' ? 'active' : '' ?>" id="panel-watermark">
<form method="POST"><input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>"><input type="hidden" name="active_tab" value="watermark">
<div class="row g-4">
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-shield-check me-2"></i>Watermark Engine</h5>
            <div class="p-3 bg-light rounded-3 border mb-3">
                <div class="form-check form-switch mb-0">
                    <input class="form-check-input" type="checkbox" name="watermark_enabled_free" id="wmSwitch" value="1" <?= checked_if($s,'watermark_enabled_free') ?>>
                    <label class="form-check-label fw-semibold small" for="wmSwitch">Force Watermark on Free Accounts</label>
                    <div class="small text-muted">When ON, free users cannot remove the watermark during export. PRO accounts can export without watermark.</div>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Watermark Text</label>
                <input type="text" name="watermark_text" class="form-control" value="<?= sv($s,'watermark_text','PROCUT') ?>">
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Watermark Position</label>
                <select name="watermark_position" class="form-select">
                    <?php foreach(['bottomRight'=>'Bottom Right','bottomLeft'=>'Bottom Left','topRight'=>'Top Right','topLeft'=>'Top Left','center'=>'Center'] as $v=>$l): ?>
                        <option value="<?= $v ?>" <?= ($s['watermark_position']??'bottomRight')===$v?'selected':'' ?>><?= $l ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Watermark Opacity: <span id="opVal"><?= $s['watermark_opacity']??'0.8' ?></span></label>
                <input type="range" name="watermark_opacity" class="form-range" min="0.1" max="1" step="0.05"
                    value="<?= $s['watermark_opacity']??'0.8' ?>" oninput="document.getElementById('opVal').textContent=this.value">
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Watermark Size: <span id="szVal"><?= $s['watermark_size']??'0.8' ?></span></label>
                <input type="range" name="watermark_size" class="form-range" min="0.3" max="2.0" step="0.05"
                    value="<?= $s['watermark_size']??'0.8' ?>" oninput="document.getElementById('szVal').textContent=this.value">
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Default Export FPS</label>
                <select name="default_export_fps" class="form-select">
                    <?php foreach(['24'=>'24 FPS','30'=>'30 FPS','60'=>'60 FPS (PRO)'] as $v=>$l): ?>
                        <option value="<?= $v ?>" <?= ($s['default_export_fps']??'30')===$v?'selected':'' ?>><?= $l ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
    </div>
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3">Live Preview</h5>
            <div style="background:#111; border-radius:16px; aspect-ratio:9/16; position:relative; overflow:hidden; max-height:320px;">
                <div style="position:absolute; inset:0; background:linear-gradient(135deg,#1a1a2e,#16213e); display:flex; align-items:center; justify-content:center;">
                    <span style="color:#fff; font-size:12px; opacity:.3;">Video Content</span>
                </div>
                <?php $wPos = $s['watermark_position']??'bottomRight'; ?>
                <div style="position:absolute; <?= str_contains($wPos,'bottom')?'bottom:12px':'top:12px' ?>; <?= str_contains($wPos,'Right')?'right:12px':'left:12px' ?>; <?= $wPos==='center'?'left:50%;top:50%;transform:translate(-50%,-50%)':'' ?>; opacity:<?= $s['watermark_opacity']??'0.8' ?>;">
                    <span style="color:#fff; font-size:9px; font-weight:800; letter-spacing:1px; text-shadow:0 1px 3px rgba(0,0,0,.8);">✦ <?= htmlspecialchars($s['watermark_text']??'PROCUT') ?></span>
                </div>
            </div>
            <p class="text-muted small text-center mt-2">Watermark appears on exported video at configured position & opacity.</p>
        </div>
    </div>
</div>
<div class="d-flex justify-content-end mt-4"><button type="submit" class="btn btn-primary px-5 py-2 fw-semibold">Save Watermark Settings</button></div>
</form></div>

<!-- ===================== SUPPORT & LEGAL ===================== -->
<div class="dac-panel <?= $activeTab === 'support' ? 'active' : '' ?>" id="panel-support">
<form method="POST"><input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>"><input type="hidden" name="active_tab" value="support">
<div class="row g-4">
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-headset me-2"></i>Support & Contact Info</h5>
            <?php foreach([
                'support_email'   => ['Email Address',       'support@procut.app', 'email'],
                'support_phone'   => ['Phone Number',        '+1 555 000 0000',    'tel'],
                'support_whatsapp'=> ['WhatsApp Number',     '+1 555 000 0000',    'tel'],
                'support_website' => ['Website URL',         'https://procut.app', 'url'],
                'help_center_url' => ['Help Center URL',     'https://help.procut.app', 'url'],
            ] as $fk => [$fl, $fph, $ft]): ?>
            <div class="mb-3">
                <label class="form-label small fw-semibold"><?= $fl ?></label>
                <input type="<?= $ft ?>" name="<?= $fk ?>" class="form-control" value="<?= sv($s,$fk) ?>" placeholder="<?= $fph ?>">
            </div>
            <?php endforeach; ?>
        </div>
        <div class="pro-card p-4 mt-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-info-circle me-2"></i>About App</h5>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Company / Studio Name</label>
                <input type="text" name="about_company_name" class="form-control" value="<?= sv($s,'about_company_name','ProCut Studio') ?>">
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">App Description (shown in About dialog)</label>
                <textarea name="about_app_description" class="form-control" rows="3"><?= sv($s,'about_app_description') ?></textarea>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Copyright Text</label>
                <input type="text" name="about_copyright_text" class="form-control" value="<?= sv($s,'about_copyright_text','© 2025 ProCut Studio.') ?>">
            </div>
        </div>
    </div>
    <div class="col-lg-6">
        <!-- ── Privacy Policy ── -->
        <div class="pro-card p-4">
            <div class="d-flex align-items-center justify-content-between mb-1">
                <h5 class="fw-bold mb-0"><i class="bi bi-shield-lock me-2 text-primary"></i>Privacy Policy</h5>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="btn btn-sm btn-outline-primary" onclick="loadDefaultPrivacyPolicy()" style="font-size:12px; padding:3px 10px;">
                        <i class="bi bi-magic me-1"></i>Insert Standard ProCut Policy
                    </button>
                    <span class="badge bg-success-subtle text-success border border-success-subtle" style="font-size:11px;">
                        <i class="bi bi-phone me-1"></i>Live in App
                    </span>
                </div>
            </div>
            <p class="text-muted small mb-3">
                This text appears inside the app when users view the <strong>Privacy Policy</strong>.
            </p>

            <div class="position-relative">
                <textarea
                    name="privacy_policy_content"
                    id="privacyPolicyTextarea"
                    class="form-control font-monospace"
                    rows="16"
                    placeholder="Enter Privacy Policy text..."
                    oninput="updateLegalCounter('privacyPolicyTextarea','privacyPolicyCounter','privacyPolicyPreview')"
                ><?= htmlspecialchars($s['privacy_policy_content']??'') ?></textarea>
            </div>
            <div class="d-flex justify-content-between align-items-center mt-1 mb-3">
                <small class="text-muted">Plain text</small>
                <small id="privacyPolicyCounter" class="text-muted font-monospace">0 chars</small>
            </div>

            <!-- Live preview -->
            <div class="border rounded-3 p-3 bg-light" style="min-height:80px;">
                <p class="small text-muted fw-semibold mb-2"><i class="bi bi-eye me-1"></i>App Preview</p>
                <div id="privacyPolicyPreview" class="small text-dark" style="line-height:1.7; white-space:pre-wrap; word-break:break-word;">
                    <?= htmlspecialchars($s['privacy_policy_content']??'') ?: '<span class="text-muted fst-italic">Start typing above to see a preview…</span>' ?>
                </div>
            </div>
        </div>

        <!-- ── Terms & Conditions ── -->
        <div class="pro-card p-4 mt-4">
            <div class="d-flex align-items-center justify-content-between mb-1">
                <h5 class="fw-bold mb-0"><i class="bi bi-file-text me-2 text-primary"></i>Terms & Conditions</h5>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="btn btn-sm btn-outline-primary" onclick="loadDefaultTermsConditions()" style="font-size:12px; padding:3px 10px;">
                        <i class="bi bi-magic me-1"></i>Insert Standard Terms
                    </button>
                    <span class="badge bg-success-subtle text-success border border-success-subtle" style="font-size:11px;">
                        <i class="bi bi-phone me-1"></i>Live in App
                    </span>
                </div>
            </div>
            <p class="text-muted small mb-3">Displayed inside the app when users view <strong>Terms & Conditions</strong>.</p>
            <textarea
                name="terms_conditions_content"
                id="termsTextarea"
                class="form-control font-monospace"
                rows="12"
                placeholder="Write or paste your full Terms & Conditions here."
                oninput="updateLegalCounter('termsTextarea','termsCounter','termsPreview')"
            ><?= htmlspecialchars($s['terms_conditions_content']??'') ?></textarea>
            <div class="d-flex justify-content-between align-items-center mt-1 mb-3">
                <small class="text-muted">Plain text</small>
                <small id="termsCounter" class="text-muted font-monospace">0 chars</small>
            </div>
            <div class="border rounded-3 p-3 bg-light" style="min-height:60px;">
                <p class="small text-muted fw-semibold mb-2"><i class="bi bi-eye me-1"></i>App Preview</p>
                <div id="termsPreview" class="small text-dark" style="line-height:1.7; white-space:pre-wrap; word-break:break-word;">
                    <?= htmlspecialchars($s['terms_conditions_content']??'') ?: '<span class="text-muted fst-italic">Start typing above to see a preview…</span>' ?>
                </div>
            </div>
        </div>
    </div>

    <script>
    const defaultPrivacyPolicyText = <?= json_encode($defaultPrivacyPolicy) ?>;
    const defaultTermsConditionsText = <?= json_encode($defaultTermsConditions) ?>;

    function loadDefaultPrivacyPolicy() {
        const ta = document.getElementById('privacyPolicyTextarea');
        if (!ta) return;
        ta.value = defaultPrivacyPolicyText;
        updateLegalCounter('privacyPolicyTextarea','privacyPolicyCounter','privacyPolicyPreview');
    }

    function loadDefaultTermsConditions() {
        const ta = document.getElementById('termsTextarea');
        if (!ta) return;
        ta.value = defaultTermsConditionsText;
        updateLegalCounter('termsTextarea','termsCounter','termsPreview');
    }

    function updateLegalCounter(textareaId, counterId, previewId) {
        const ta = document.getElementById(textareaId);
        const counter = document.getElementById(counterId);
        const preview = document.getElementById(previewId);
        if (!ta || !counter || !preview) return;
        const len = ta.value.length;
        counter.textContent = len.toLocaleString() + ' chars';
        counter.className = 'font-monospace small ' + (len > 4000 ? 'text-danger fw-bold' : 'text-muted');
        preview.innerHTML = ta.value.trim()
            ? ta.value.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
            : '<span class="text-muted fst-italic">Start typing above to see a preview…</span>';
    }
    // Init counters on page load
    document.addEventListener('DOMContentLoaded', function() {
        ['privacyPolicyTextarea','termsTextarea'].forEach(function(id) {
            const ta = document.getElementById(id);
            if (!ta) return;
            const map = {
                'privacyPolicyTextarea': ['privacyPolicyCounter','privacyPolicyPreview'],
                'termsTextarea':         ['termsCounter','termsPreview']
            };
            updateLegalCounter(id, map[id][0], map[id][1]);
        });
    });
    </script>
</div>
<div class="d-flex justify-content-end mt-4"><button type="submit" class="btn btn-primary px-5 py-2 fw-semibold">Save Support & Legal</button></div>
</form></div>

<!-- ===================== SOCIAL & GROWTH ===================== -->
<div class="dac-panel <?= $activeTab === 'social' ? 'active' : '' ?>" id="panel-social">
<form method="POST"><input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>"><input type="hidden" name="active_tab" value="social">
<div class="row g-4">
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-share-fill me-2"></i>Social Media Links</h5>
            <?php foreach([
                'social_instagram_url' => ['bi-instagram','Instagram URL'],
                'social_youtube_url'   => ['bi-youtube','YouTube URL'],
                'social_twitter_url'   => ['bi-twitter-x','X (Twitter) URL'],
                'social_tiktok_url'    => ['bi-tiktok','TikTok URL'],
                'social_discord_url'   => ['bi-discord','Discord Server URL'],
            ] as $sk => [$sicon, $slabel]): ?>
            <div class="mb-3">
                <label class="form-label small fw-semibold"><i class="bi <?= $sicon ?> me-1"></i><?= $slabel ?></label>
                <input type="url" name="<?= $sk ?>" class="form-control" value="<?= sv($s,$sk) ?>" placeholder="https://...">
            </div>
            <?php endforeach; ?>
        </div>
    </div>
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-star-fill me-2 text-warning"></i>Rate Us</h5>
            <div class="p-3 bg-light rounded-3 border mb-3">
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" name="rate_us_enabled" id="ruSwitch" value="1" <?= checked_if($s,'rate_us_enabled') ?>>
                    <label class="form-check-label fw-semibold small" for="ruSwitch">Enable Rate Us Prompt</label>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Store URL (Google Play / App Store)</label>
                <input type="url" name="rate_us_store_url" class="form-control" value="<?= sv($s,'rate_us_store_url','https://play.google.com/store') ?>">
            </div>
        </div>
        <div class="pro-card p-4 mt-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-share me-2"></i>Share App</h5>
            <div class="p-3 bg-light rounded-3 border mb-3">
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" name="share_app_enabled" id="saSwitch" value="1" <?= checked_if($s,'share_app_enabled') ?>>
                    <label class="form-check-label fw-semibold small" for="saSwitch">Enable Share App Feature</label>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Share Message</label>
                <textarea name="share_app_message" class="form-control" rows="2"><?= sv($s,'share_app_message','Check out ProCut! Download now: https://procut.app') ?></textarea>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">App Download URL</label>
                <input type="url" name="share_app_url" class="form-control" value="<?= sv($s,'share_app_url','https://procut.app') ?>">
            </div>
        </div>
    </div>
</div>
<div class="d-flex justify-content-end mt-4"><button type="submit" class="btn btn-primary px-5 py-2 fw-semibold">Save Social & Growth</button></div>
</form></div>

<!-- ===================== VERSIONING & MAINTENANCE ===================== -->
<div class="dac-panel <?= $activeTab === 'versioning' ? 'active' : '' ?>" id="panel-versioning">
<form method="POST"><input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>"><input type="hidden" name="active_tab" value="versioning">
<div class="row g-4">
    <div class="col-lg-6">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-rocket-takeoff me-2"></i>App Versioning & Updates</h5>
            <div class="row g-2 mb-3">
                <div class="col-md-6">
                    <label class="form-label small fw-semibold">Current Live Version</label>
                    <input type="text" name="app_version" class="form-control" value="<?= sv($s,'app_version','1.0.0') ?>">
                    <small class="text-muted">Latest production release (e.g. 2.4.0)</small>
                </div>
                <div class="col-md-6">
                    <label class="form-label small fw-semibold">Minimum Supported Version</label>
                    <input type="text" name="min_app_version" class="form-control" value="<?= sv($s,'min_app_version','1.0.0') ?>">
                    <small class="text-muted">Users below this must update</small>
                </div>
            </div>
            <div class="p-3 bg-light rounded-3 border mb-3">
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" name="force_update_enabled" id="fuSwitch" value="1" <?= checked_if($s,'force_update_enabled') ?>>
                    <label class="form-check-label fw-semibold small" for="fuSwitch">Enforce Mandatory Update</label>
                    <div class="small text-muted">Blocks app usage until user updates if version &lt; minimum supported version.</div>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Update Dialog Title</label>
                <input type="text" name="update_dialog_title" class="form-control" value="<?= sv($s,'update_dialog_title','Update Available') ?>">
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Update Dialog Message</label>
                <textarea name="update_dialog_message" class="form-control" rows="2"><?= sv($s,'update_dialog_message','A new version of ProCut is available. Please update to continue.') ?></textarea>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Store Update URL</label>
                <input type="url" name="update_store_url" class="form-control" value="<?= sv($s,'update_store_url','https://play.google.com/store') ?>">
            </div>
            <div class="p-3 bg-light rounded-3 border">
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" name="allow_user_registration" id="regSwitch" value="1" <?= checked_if($s,'allow_user_registration') ?>>
                    <label class="form-check-label fw-semibold small" for="regSwitch">Allow New User Registrations</label>
                    <div class="small text-muted">When disabled, only existing users can log in from the app.</div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-lg-6">
        <div class="pro-card p-4 border-danger" style="border:2px solid #EF4444 !important;">
            <h5 class="fw-bold mb-3 text-danger"><i class="bi bi-tools me-2"></i>Maintenance Mode</h5>
            <div class="p-3 rounded-3 mb-3" style="background:#fef2f2; border:1px solid #fca5a5;">
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" name="maintenance_mode" id="maintSwitch" value="1" <?= checked_if($s,'maintenance_mode') ?>>
                    <label class="form-check-label fw-semibold small text-danger" for="maintSwitch">🔴 Maintenance Mode Active</label>
                    <div class="small text-muted">Shows a maintenance banner to ALL users on the Home screen. Editing remains functional.</div>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Maintenance Title</label>
                <input type="text" name="maintenance_title" class="form-control" value="<?= sv($s,'maintenance_title','Scheduled Maintenance') ?>">
            </div>
            <div class="mb-3">
                <label class="form-label small fw-semibold">Maintenance Message (shown to users)</label>
                <textarea name="maintenance_message" class="form-control" rows="2"><?= sv($s,'maintenance_message','ProCut Cloud is currently undergoing scheduled maintenance. Offline editing remains fully functional.') ?></textarea>
            </div>
        </div>
        <div class="pro-card p-4 mt-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-cloud me-2"></i>Cloud Storage Quotas</h5>
            <div class="row g-2">
                <div class="col-md-6">
                    <label class="form-label small fw-semibold">Free Tier Max Projects</label>
                    <input type="number" name="max_free_cloud_projects" class="form-control" value="<?= sv($s,'max_free_cloud_projects','10') ?>" min="1" max="100">
                </div>
                <div class="col-md-6">
                    <label class="form-label small fw-semibold">PRO Tier Max Projects</label>
                    <input type="number" name="max_pro_cloud_projects" class="form-control" value="<?= sv($s,'max_pro_cloud_projects','100') ?>" min="10" max="1000">
                </div>
            </div>
        </div>
    </div>
</div>
<div class="d-flex justify-content-end mt-4"><button type="submit" class="btn btn-primary px-5 py-2 fw-semibold">Save Versioning & Maintenance</button></div>
</form></div>

<script>
function switchTab(tabId) {
    document.querySelectorAll('.dac-tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.dac-panel').forEach(p => p.classList.remove('active'));
    document.getElementById('panel-' + tabId).classList.add('active');
    event.currentTarget.classList.add('active');
    history.replaceState(null,'', '?tab=' + tabId);
}

// Branding live preview
const appNameInput = document.querySelector('[name="app_name"]');
const splashMsgInput = document.querySelector('[name="splash_message"]');
if (appNameInput) appNameInput.addEventListener('input', e => {
    const el = document.getElementById('prev_app_name');
    if (el) el.textContent = e.target.value;
});
if (splashMsgInput) splashMsgInput.addEventListener('input', e => {
    const el = document.getElementById('prev_splash_msg');
    if (el) el.textContent = e.target.value;
});

// Colour picker sync
function syncHex(picker, key) {
    const hex = picker.value; // #RRGGBB
    const dart = '0xFF' + hex.replace('#','').toUpperCase();
    const field = document.getElementById(key);
    if (field) field.value = dart;
    updateThemePreview(key, hex);
}
function syncPicker(input, key) {
    const val = input.value; // 0xFFRRGGBB or #RRGGBB
    let css;
    if (val.startsWith('0x') && val.length >= 10) css = '#' + val.slice(4, 10);
    else css = val;
    const picker = input.previousElementSibling;
    if (picker && picker.type === 'color') picker.value = css;
    updateThemePreview(key, css);
}
function updateThemePreview(key, css) {
    const h = document.getElementById('prevHeader');
    const b = document.getElementById('prevBody');
    if (key === 'primary_color' && h) h.style.background = css;
    if (key === 'background_color' && b) b.style.background = css;
}

// Editor tool toggles → update JSON textarea
function bindToolToggles(listId, textareaId, cls) {
    const list = document.getElementById(listId);
    const ta   = document.getElementById(textareaId);
    if (!list || !ta) return;
    list.querySelectorAll('.' + cls).forEach(cb => {
        cb.addEventListener('change', () => {
            try {
                const tools = JSON.parse(ta.value);
                const key = cb.dataset.key;
                const t = tools.find(x => x.key === key);
                if (t) t.enabled = cb.checked;
                ta.value = JSON.stringify(tools, null, 2);
            } catch(e) {}
        });
    });
}
bindToolToggles('videoToolsList','videoToolsJson','video-tool-toggle');
bindToolToggles('photoToolsList','photoToolsJson','photo-tool-toggle');
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
