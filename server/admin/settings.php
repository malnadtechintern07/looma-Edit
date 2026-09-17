<?php
$pageTitle = 'Dynamic App Control Center';
require_once __DIR__ . '/includes/auth_check.php';

$error   = '';
$success = '';
$activeTab = $_GET['tab'] ?? 'branding';

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
                    Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [trim($_POST[$k]), $k]);
                }
            }
            // Long-text legal fields
            foreach (['privacy_policy_content','terms_conditions_content'] as $k) {
                if (isset($_POST[$k])) {
                    Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = ?", [$_POST[$k], $k]);
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
            <img src="assets/icon/app_icon.png" width="56" height="56" style="border-radius:14px; margin-bottom:10px;" onerror="this.style.display='none'">
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
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-shield-lock me-2"></i>Privacy Policy</h5>
            <textarea name="privacy_policy_content" class="form-control" rows="8" placeholder="Write or paste your full Privacy Policy here. Supports plain text."><?= htmlspecialchars($s['privacy_policy_content']??'') ?></textarea>
            <small class="text-muted">Displayed inside the app when users tap "Privacy Policy".</small>
        </div>
        <div class="pro-card p-4 mt-4">
            <h5 class="fw-bold mb-3"><i class="bi bi-file-text me-2"></i>Terms & Conditions</h5>
            <textarea name="terms_conditions_content" class="form-control" rows="8" placeholder="Write or paste your full Terms & Conditions here."><?= htmlspecialchars($s['terms_conditions_content']??'') ?></textarea>
        </div>
    </div>
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
