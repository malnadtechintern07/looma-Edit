<?php
$pageTitle = 'Features & Creation Tools';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

// Handle actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $action = $_POST['action'] ?? '';
        
        if ($action === 'toggle_enabled') {
            $id = (int)($_POST['id'] ?? 0);
            $f = Database::fetchOne("SELECT * FROM features WHERE id = ?", [$id]);
            if ($f) {
                $newVal = $f['is_enabled'] ? 0 : 1;
                Database::query("UPDATE features SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'feature_toggled', "Toggled feature {$f['feature_key']} to " . ($newVal ? 'Enabled' : 'Disabled'));
                $success = "Feature status updated.";
            }
        } elseif ($action === 'toggle_pro') {
            $id = (int)($_POST['id'] ?? 0);
            $f = Database::fetchOne("SELECT * FROM features WHERE id = ?", [$id]);
            if ($f) {
                $newPro = $f['is_pro_only'] ? 0 : 1;
                $badge = $newPro ? 'PRO' : null;
                Database::query("UPDATE features SET is_pro_only = ?, badge_text = ?, updated_at = NOW() WHERE id = ?", [$newPro, $badge, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'feature_pro_toggled', "Toggled PRO on feature {$f['feature_key']}");
                $success = "Feature PRO requirement updated.";
            }
        } elseif ($action === 'save_feature') {
            $id = (int)($_POST['id'] ?? 0);
            $key = trim($_POST['feature_key'] ?? '');
            $title = trim($_POST['title'] ?? '');
            $subtitle = trim($_POST['subtitle'] ?? '');
            $icon = trim($_POST['icon_name'] ?? 'star');
            $category = trim($_POST['category'] ?? 'quick_tool');
            $order = (int)($_POST['display_order'] ?? 1);
            $isPro = isset($_POST['is_pro_only']) ? 1 : 0;
            $badge = trim($_POST['badge_text'] ?? ($isPro ? 'PRO' : ''));
            $route = trim($_POST['action_route'] ?? '');
            $enabled = isset($_POST['is_enabled']) ? 1 : 0;

            if (empty($key) || empty($title)) {
                $error = 'Feature key and title are required.';
            } else {
                if ($id > 0) {
                    Database::query(
                        "UPDATE features SET feature_key = ?, title = ?, subtitle = ?, icon_name = ?, category = ?,
                                display_order = ?, is_enabled = ?, is_pro_only = ?, badge_text = ?, action_route = ?, updated_at = NOW()
                         WHERE id = ?",
                        [$key, $title, $subtitle, $icon, $category, $order, $enabled, $isPro, $badge, $route, $id]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'feature_updated', "Updated feature {$key}");
                    $success = "Feature updated successfully.";
                } else {
                    Database::query(
                        "INSERT INTO features (feature_key, title, subtitle, icon_name, category, display_order, is_enabled, is_pro_only, badge_text, action_route)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        [$key, $title, $subtitle, $icon, $category, $order, $enabled, $isPro, $badge, $route]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'feature_created', "Created new feature {$key}");
                    $success = "Feature created successfully.";
                }
            }
        } elseif ($action === 'delete_feature') {
            $id = (int)($_POST['id'] ?? 0);
            Database::query("DELETE FROM features WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'feature_deleted', "Deleted feature ID {$id}");
            $success = "Feature deleted.";
        }
    }
}

$features = Database::fetchAll("SELECT * FROM features ORDER BY display_order ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Features & Creation Tools</h3>
        <p class="text-muted small mb-0">Manage quick tools grid, AutoCut, Retouch, AI background removal, and PRO feature gates.</p>
    </div>
    <button type="button" class="btn btn-primary rounded-pill px-3" onclick="openNewModal()">
        <i class="bi bi-plus-lg me-1"></i> Add Tool / Feature
    </button>
</div>

<?php if (!empty($error)): ?>
    <div class="alert alert-danger py-2 px-3 small mb-3"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if (!empty($success)): ?>
    <div class="alert alert-success py-2 px-3 small mb-3"><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<div class="pro-card p-4">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead>
                <tr>
                    <th style="width: 70px;">Order</th>
                    <th>Tool Title</th>
                    <th>Identifier</th>
                    <th>Category</th>
                    <th>Tier / Badge</th>
                    <th>Status</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($features as $f): ?>
                <tr>
                    <td>
                        <span class="badge bg-light text-dark border px-2 py-1 fs-6 fw-bold"><?= (int)$f['display_order'] ?></span>
                    </td>
                    <td>
                        <div class="fw-bold text-dark d-flex align-items-center gap-2">
                            <i class="bi bi-gear-wide text-primary"></i>
                            <?= htmlspecialchars($f['title']) ?>
                        </div>
                        <small class="text-muted"><?= htmlspecialchars($f['subtitle'] ?? '') ?></small>
                    </td>
                    <td>
                        <code><?= htmlspecialchars($f['feature_key']) ?></code>
                    </td>
                    <td>
                        <span class="badge bg-light text-secondary border text-capitalize"><?= htmlspecialchars($f['category'] ?? 'quick_tool') ?></span>
                    </td>
                    <td>
                        <form method="POST" action="" class="d-inline">
                            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                            <input type="hidden" name="id" value="<?= (int)$f['id'] ?>">
                            <input type="hidden" name="action" value="toggle_pro">
                            <?php if ($f['is_pro_only']): ?>
                                <button type="submit" class="badge bg-warning text-dark border-0 px-2 py-1 fw-bold">
                                    <i class="bi bi-star-fill me-1"></i>PRO ONLY
                                </button>
                            <?php else: ?>
                                <button type="submit" class="badge bg-light text-muted border-0 px-2 py-1">
                                    Free
                                </button>
                            <?php endif; ?>
                        </form>
                    </td>
                    <td>
                        <form method="POST" action="" class="d-inline">
                            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                            <input type="hidden" name="id" value="<?= (int)$f['id'] ?>">
                            <input type="hidden" name="action" value="toggle_enabled">
                            <?php if ($f['is_enabled']): ?>
                                <button type="submit" class="badge badge-soft-success border-0 px-3 py-1">
                                    <i class="bi bi-check-circle-fill me-1"></i>Active
                                </button>
                            <?php else: ?>
                                <button type="submit" class="badge badge-soft-danger border-0 px-3 py-1">
                                    <i class="bi bi-x-circle-fill me-1"></i>Hidden
                                </button>
                            <?php endif; ?>
                        </form>
                    </td>
                    <td class="text-end">
                        <div class="d-flex justify-content-end gap-1">
                            <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 rounded-2" onclick='editFeature(<?= json_encode($f) ?>)'>
                                <i class="bi bi-pencil"></i>
                            </button>
                            <form method="POST" action="" onsubmit="return confirm('Delete this tool from the application?');">
                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                <input type="hidden" name="id" value="<?= (int)$f['id'] ?>">
                                <input type="hidden" name="action" value="delete_feature">
                                <button type="submit" class="btn btn-sm btn-outline-danger py-1 px-2 rounded-2">
                                    <i class="bi bi-trash3"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Create / Edit Feature -->
<div class="modal fade" id="featureModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold" id="featureModalTitle">Edit Feature</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_feature">
                    <input type="hidden" name="id" id="fId" value="0">

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Identifier Key</label>
                            <input type="text" name="feature_key" id="fKey" class="form-control" placeholder="e.g. smart_cut" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Title</label>
                            <input type="text" name="title" id="fTitle" class="form-control" placeholder="e.g. Smart Cut" required>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Subtitle</label>
                        <input type="text" name="subtitle" id="fSubtitle" class="form-control" placeholder="Brief feature caption">
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Order</label>
                            <input type="number" name="display_order" id="fOrder" class="form-control" value="1" min="1" max="99" required>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Category</label>
                            <select name="category" id="fCategory" class="form-select">
                                <option value="quick_tool">Quick Tool</option>
                                <option value="hero_card">Hero Card</option>
                                <option value="ai_suite">AI Suite</option>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Badge Text</label>
                            <input type="text" name="badge_text" id="fBadge" class="form-control" placeholder="e.g. PRO / HOT">
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Action Route</label>
                        <input type="text" name="action_route" id="fRoute" class="form-control" placeholder="e.g. /editor or /autocut">
                    </div>

                    <div class="d-flex gap-4 mt-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_enabled" id="fEnabled" value="1" checked>
                            <label class="form-check-label fw-semibold small" for="fEnabled">Enabled</label>
                        </div>
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_pro_only" id="fProOnly" value="1">
                            <label class="form-check-label fw-semibold small" for="fProOnly">Requires PRO</label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Feature</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function openNewModal() {
    document.getElementById('featureModalTitle').innerText = 'Add New Tool / Feature';
    document.getElementById('fId').value = '0';
    document.getElementById('fKey').value = '';
    document.getElementById('fKey').readOnly = false;
    document.getElementById('fTitle').value = '';
    document.getElementById('fSubtitle').value = '';
    document.getElementById('fOrder').value = '10';
    document.getElementById('fBadge').value = '';
    document.getElementById('fRoute').value = '';
    document.getElementById('fEnabled').checked = true;
    document.getElementById('fProOnly').checked = false;
    new bootstrap.Modal(document.getElementById('featureModal')).show();
}

function editFeature(f) {
    document.getElementById('featureModalTitle').innerText = 'Edit Feature';
    document.getElementById('fId').value = f.id;
    document.getElementById('fKey').value = f.feature_key;
    document.getElementById('fKey').readOnly = true;
    document.getElementById('fTitle').value = f.title;
    document.getElementById('fSubtitle').value = f.subtitle || '';
    document.getElementById('fOrder').value = f.display_order;
    document.getElementById('fCategory').value = f.category || 'quick_tool';
    document.getElementById('fBadge').value = f.badge_text || '';
    document.getElementById('fRoute').value = f.action_route || '';
    document.getElementById('fEnabled').checked = f.is_enabled == 1;
    document.getElementById('fProOnly').checked = f.is_pro_only == 1;
    new bootstrap.Modal(document.getElementById('featureModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
