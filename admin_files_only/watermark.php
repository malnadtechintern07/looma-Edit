<?php
$pageTitle = 'Watermark & Export Settings';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $text = trim($_POST['watermark_text'] ?? 'PROCUT');
        $pos = trim($_POST['watermark_position'] ?? 'bottomRight');
        $enabledFree = isset($_POST['watermark_enabled_free']) ? '1' : '0';
        $defaultFps = trim($_POST['default_export_fps'] ?? '30');

        Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'watermark_text'", [$text]);
        Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'watermark_position'", [$pos]);
        Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'watermark_enabled_free'", [$enabledFree]);
        Database::query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'default_export_fps'", [$defaultFps]);

        Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'watermark_updated', 'Updated watermark and export rules');
        $success = 'Watermark and export settings saved successfully.';
    }
}

$settingsRows = Database::fetchAll("SELECT setting_key, setting_value FROM app_settings WHERE setting_group IN ('watermark', 'export')");
$settings = [];
foreach ($settingsRows as $row) {
    $settings[$row['setting_key']] = $row['setting_value'];
}

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Watermark & Video Export Engine</h3>
        <p class="text-muted small mb-0">Configure branding watermark rules, export resolution policies, and PRO export perks.</p>
    </div>
</div>

<?php if (!empty($error)): ?>
    <div class="alert alert-danger py-2 px-3 small mb-3"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if (!empty($success)): ?>
    <div class="alert alert-success py-2 px-3 small mb-3"><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<div class="row g-4">
    <div class="col-lg-7">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3">Branding & Watermark Rules</h5>
            <form method="POST" action="">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">

                <div class="mb-3">
                    <label class="form-label small fw-semibold">Watermark Display Text</label>
                    <input type="text" name="watermark_text" class="form-control" value="<?= htmlspecialchars($settings['watermark_text'] ?? 'PROCUT') ?>" required>
                    <small class="text-muted">Overlayed on exported videos for non-PRO subscribers.</small>
                </div>

                <div class="mb-3">
                    <label class="form-label small fw-semibold">Watermark Position</label>
                    <select name="watermark_position" class="form-select">
                        <option value="bottomRight" <?= ($settings['watermark_position'] ?? '') === 'bottomRight' ? 'selected' : '' ?>>Bottom Right Corner</option>
                        <option value="bottomLeft" <?= ($settings['watermark_position'] ?? '') === 'bottomLeft' ? 'selected' : '' ?>>Bottom Left Corner</option>
                        <option value="topRight" <?= ($settings['watermark_position'] ?? '') === 'topRight' ? 'selected' : '' ?>>Top Right Corner</option>
                        <option value="topLeft" <?= ($settings['watermark_position'] ?? '') === 'topLeft' ? 'selected' : '' ?>>Top Left Corner</option>
                    </select>
                </div>

                <div class="mb-4">
                    <label class="form-label small fw-semibold">Default Export Frame Rate</label>
                    <select name="default_export_fps" class="form-select">
                        <option value="24" <?= ($settings['default_export_fps'] ?? '') === '24' ? 'selected' : '' ?>>24 FPS (Cinematic standard)</option>
                        <option value="30" <?= ($settings['default_export_fps'] ?? '') === '30' ? 'selected' : '' ?>>30 FPS (Standard video)</option>
                        <option value="60" <?= ($settings['default_export_fps'] ?? '') === '60' ? 'selected' : '' ?>>60 FPS (Ultra smooth - PRO)</option>
                    </select>
                </div>

                <div class="p-3 bg-light rounded-3 mb-4 border">
                    <div class="form-check form-switch mb-0">
                        <input class="form-check-input" type="checkbox" name="watermark_enabled_free" id="wmSwitch" value="1" <?= ($settings['watermark_enabled_free'] ?? '1') === '1' ? 'checked' : '' ?>>
                        <label class="form-check-label fw-semibold small" for="wmSwitch">
                            Force Watermark on Free Accounts
                        </label>
                        <div class="small text-muted">When enabled, free creators cannot remove the watermark toggle during video export. Only PRO accounts can export clean videos.</div>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary px-4">Save Watermark Rules</button>
            </form>
        </div>
    </div>

    <!-- Live Preview -->
    <div class="col-lg-5">
        <div class="pro-card p-4">
            <h5 class="fw-bold mb-3">Mobile Export Preview</h5>
            <div class="rounded-4 bg-dark position-relative d-flex align-items-center justify-content-center overflow-hidden" style="height: 360px;">
                <div class="text-center text-secondary">
                    <i class="bi bi-play-circle fs-1 d-block mb-1"></i>
                    <small>Sample Video Canvas (9:16)</small>
                </div>

                <!-- Watermark Simulation -->
                <div class="position-absolute bottom-0 end-0 p-3">
                    <div class="badge bg-black bg-opacity-75 text-white border border-secondary px-3 py-2 rounded-pill d-flex align-items-center gap-1 shadow">
                        <i class="bi bi-film text-primary"></i>
                        <span class="fw-bold" style="letter-spacing: 0.5px;"><?= htmlspecialchars($settings['watermark_text'] ?? 'PROCUT') ?></span>
                    </div>
                </div>
            </div>
            <div class="text-center mt-2 small text-muted">Simulated rendering output with watermark badge overlay</div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
