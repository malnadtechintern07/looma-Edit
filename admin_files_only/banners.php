<?php
$pageTitle = 'Banners & Promotions';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $action = $_POST['action'] ?? '';
        
        if ($action === 'toggle_enabled') {
            $id = (int)($_POST['id'] ?? 0);
            $b = Database::fetchOne("SELECT * FROM banners WHERE id = ?", [$id]);
            if ($b) {
                $newVal = $b['is_enabled'] ? 0 : 1;
                Database::query("UPDATE banners SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'banner_toggled', "Toggled banner ID {$id}");
                $success = "Banner status updated.";
            }
        } elseif ($action === 'save_banner') {
            $id = (int)($_POST['id'] ?? 0);
            $title = trim($_POST['title'] ?? '');
            $subtitle = trim($_POST['subtitle'] ?? '');
            $badge = trim($_POST['badge_text'] ?? '');
            $btnText = trim($_POST['button_text'] ?? '');
            $route = trim($_POST['action_route'] ?? '');
            $gradStart = trim($_POST['gradient_start'] ?? '0xFF084298');
            $gradEnd = trim($_POST['gradient_end'] ?? '0xFF0D6EFD');
            $placement = trim($_POST['placement'] ?? 'home_top');
            $order = (int)($_POST['display_order'] ?? 1);
            $enabled = isset($_POST['is_enabled']) ? 1 : 0;

            if (empty($title)) {
                $error = 'Banner title is required.';
            } else {
                if ($id > 0) {
                    Database::query(
                        "UPDATE banners SET title = ?, subtitle = ?, badge_text = ?, button_text = ?, action_route = ?,
                                gradient_start = ?, gradient_end = ?, placement = ?, display_order = ?, is_enabled = ?, updated_at = NOW()
                         WHERE id = ?",
                        [$title, $subtitle, $badge, $btnText, $route, $gradStart, $gradEnd, $placement, $order, $enabled, $id]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'banner_updated', "Updated banner ID {$id}");
                    $success = "Banner updated.";
                } else {
                    Database::query(
                        "INSERT INTO banners (title, subtitle, badge_text, button_text, action_route, gradient_start, gradient_end, placement, display_order, is_enabled)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        [$title, $subtitle, $badge, $btnText, $route, $gradStart, $gradEnd, $placement, $order, $enabled]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'banner_created', "Created new banner: {$title}");
                    $success = "Banner created.";
                }
            }
        } elseif ($action === 'delete_banner') {
            $id = (int)($_POST['id'] ?? 0);
            Database::query("DELETE FROM banners WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'banner_deleted', "Deleted banner ID {$id}");
            $success = "Banner deleted.";
        }
    }
}

$banners = Database::fetchAll("SELECT * FROM banners ORDER BY display_order ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Banners & Promotional Callouts</h3>
        <p class="text-muted small mb-0">Manage announcements, Cloud Sync promos, and upgrade cards on mobile screens.</p>
    </div>
    <button type="button" class="btn btn-primary rounded-pill px-3" onclick="openNewBanner()">
        <i class="bi bi-plus-lg me-1"></i> New Banner
    </button>
</div>

<?php if (!empty($error)): ?>
    <div class="alert alert-danger py-2 px-3 small mb-3"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if (!empty($success)): ?>
    <div class="alert alert-success py-2 px-3 small mb-3"><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<div class="row g-3">
    <?php foreach ($banners as $b): ?>
    <div class="col-md-6">
        <div class="pro-card p-4 h-100 d-flex flex-column">
            <!-- Simulated Banner Preview -->
            <div class="p-3 rounded-4 mb-3 text-white" style="background: linear-gradient(135deg, <?= str_replace('0xFF', '#', $b['gradient_start']) ?>, <?= str_replace('0xFF', '#', $b['gradient_end']) ?>);">
                <div class="d-flex justify-content-between align-items-start mb-2">
                    <span class="badge bg-white text-dark fw-bold"><?= htmlspecialchars($b['badge_text'] ?: 'ANNOUNCEMENT') ?></span>
                    <span class="badge bg-black bg-opacity-25 small"><?= htmlspecialchars($b['placement']) ?></span>
                </div>
                <h5 class="fw-bold mb-1 text-white"><?= htmlspecialchars($b['title']) ?></h5>
                <p class="small text-white text-opacity-75 mb-3"><?= htmlspecialchars($b['subtitle']) ?></p>
                <?php if (!empty($b['button_text'])): ?>
                    <button class="btn btn-sm btn-light fw-bold px-3 rounded-pill"><?= htmlspecialchars($b['button_text']) ?></button>
                <?php endif; ?>
            </div>

            <div class="d-flex justify-content-between align-items-center mt-auto pt-2 border-top">
                <div>
                    <form method="POST" action="" class="d-inline">
                        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                        <input type="hidden" name="id" value="<?= (int)$b['id'] ?>">
                        <input type="hidden" name="action" value="toggle_enabled">
                        <?php if ($b['is_enabled']): ?>
                            <button type="submit" class="badge badge-soft-success border-0 px-3 py-1">Active</button>
                        <?php else: ?>
                            <button type="submit" class="badge badge-soft-danger border-0 px-3 py-1">Hidden</button>
                        <?php endif; ?>
                    </form>
                    <span class="small text-muted ms-2">Order: <?= (int)$b['display_order'] ?></span>
                </div>
                <div class="d-flex gap-1">
                    <button class="btn btn-sm btn-outline-primary" onclick='editBanner(<?= json_encode($b) ?>)'><i class="bi bi-pencil"></i></button>
                    <form method="POST" action="" onsubmit="return confirm('Delete this banner?');">
                        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                        <input type="hidden" name="id" value="<?= (int)$b['id'] ?>">
                        <input type="hidden" name="action" value="delete_banner">
                        <button type="submit" class="btn btn-sm btn-outline-danger"><i class="bi bi-trash3"></i></button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <?php endforeach; ?>
</div>

<!-- Banner Modal -->
<div class="modal fade" id="bannerModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold" id="bModalTitle">Configure Banner</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_banner">
                    <input type="hidden" name="id" id="bId" value="0">

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Banner Headline</label>
                        <input type="text" name="title" id="bTitle" class="form-control" placeholder="e.g. Cloud Backup & Sync" required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Subtext</label>
                        <textarea name="subtitle" id="bSubtitle" class="form-control" rows="2" placeholder="Sign in or register to secure timelines..."></textarea>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Badge Pill</label>
                            <input type="text" name="badge_text" id="bBadge" class="form-control" placeholder="SYNC / PRO">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Button Label</label>
                            <input type="text" name="button_text" id="bBtn" class="form-control" placeholder="Sign In / Register">
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Action Route</label>
                            <input type="text" name="action_route" id="bRoute" class="form-control" placeholder="/auth or /pro">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Placement</label>
                            <select name="placement" id="bPlacement" class="form-select">
                                <option value="home_top">Home Top</option>
                                <option value="export_screen">Export Screen</option>
                                <option value="profile_tab">Profile Tab</option>
                            </select>
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Gradient Start (Hex / ARGB)</label>
                            <input type="text" name="gradient_start" id="bGradStart" class="form-control" placeholder="0xFF084298">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Gradient End (Hex / ARGB)</label>
                            <input type="text" name="gradient_end" id="bGradEnd" class="form-control" placeholder="0xFF0D6EFD">
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Order</label>
                            <input type="number" name="display_order" id="bOrder" class="form-control" value="1" min="1" max="99">
                        </div>
                        <div class="col-md-6 d-flex align-items-center mt-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" name="is_enabled" id="bEnabled" value="1" checked>
                                <label class="form-check-label fw-semibold small" for="bEnabled">Active Banner</label>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Banner</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function openNewBanner() {
    document.getElementById('bModalTitle').innerText = 'Create Promotional Banner';
    document.getElementById('bId').value = '0';
    document.getElementById('bTitle').value = '';
    document.getElementById('bSubtitle').value = '';
    document.getElementById('bBadge').value = 'PRO';
    document.getElementById('bBtn').value = 'Learn More';
    document.getElementById('bRoute').value = '/auth';
    document.getElementById('bPlacement').value = 'home_top';
    document.getElementById('bGradStart').value = '0xFF084298';
    document.getElementById('bGradEnd').value = '0xFF0D6EFD';
    document.getElementById('bOrder').value = '1';
    document.getElementById('bEnabled').checked = true;
    new bootstrap.Modal(document.getElementById('bannerModal')).show();
}

function editBanner(b) {
    document.getElementById('bModalTitle').innerText = 'Edit Banner';
    document.getElementById('bId').value = b.id;
    document.getElementById('bTitle').value = b.title;
    document.getElementById('bSubtitle').value = b.subtitle || '';
    document.getElementById('bBadge').value = b.badge_text || '';
    document.getElementById('bBtn').value = b.button_text || '';
    document.getElementById('bRoute').value = b.action_route || '';
    document.getElementById('bPlacement').value = b.placement || 'home_top';
    document.getElementById('bGradStart').value = b.gradient_start || '0xFF084298';
    document.getElementById('bGradEnd').value = b.gradient_end || '0xFF0D6EFD';
    document.getElementById('bOrder').value = b.display_order;
    document.getElementById('bEnabled').checked = b.is_enabled == 1;
    new bootstrap.Modal(document.getElementById('bannerModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
