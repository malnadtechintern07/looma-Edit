<?php
$pageTitle = 'Video Effects';
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
            $e = Database::fetchOne("SELECT * FROM effects WHERE id = ?", [$id]);
            if ($e) {
                $newVal = $e['is_enabled'] ? 0 : 1;
                Database::query("UPDATE effects SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'effect_toggled', "Toggled effect {$e['effect_key']}");
                $success = "Effect status updated.";
            }
        } elseif ($action === 'save_effect') {
            $id = (int)($_POST['id'] ?? 0);
            $key = trim($_POST['effect_key'] ?? '');
            $label = trim($_POST['label'] ?? '');
            $category = trim($_POST['category'] ?? 'Trending');
            $desc = trim($_POST['description'] ?? '');
            $icon = trim($_POST['icon_name'] ?? 'magic');
            $color1 = trim($_POST['color1'] ?? '0xFF2C2F38');
            $color2 = trim($_POST['color2'] ?? '0xFF1E2028');
            $isPro = isset($_POST['is_pro']) ? 1 : 0;
            $enabled = isset($_POST['is_enabled']) ? 1 : 0;
            $order = (int)($_POST['display_order'] ?? 1);

            if (empty($key) || empty($label)) {
                $error = 'Key and label are required.';
            } else {
                if ($id > 0) {
                    Database::query(
                        "UPDATE effects SET effect_key = ?, label = ?, category = ?, description = ?, icon_name = ?,
                                color1 = ?, color2 = ?, is_pro = ?, is_enabled = ?, display_order = ?, updated_at = NOW()
                         WHERE id = ?",
                        [$key, $label, $category, $desc, $icon, $color1, $color2, $isPro, $enabled, $order, $id]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'effect_updated', "Updated effect {$key}");
                    $success = "Effect updated.";
                } else {
                    Database::query(
                        "INSERT INTO effects (effect_key, label, category, description, icon_name, color1, color2, is_pro, is_enabled, display_order)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        [$key, $label, $category, $desc, $icon, $color1, $color2, $isPro, $enabled, $order]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'effect_created', "Created effect {$key}");
                    $success = "Effect published.";
                }
            }
        } elseif ($action === 'delete_effect') {
            $id = (int)($_POST['id'] ?? 0);
            Database::query("DELETE FROM effects WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'effect_deleted', "Deleted effect ID {$id}");
            $success = "Effect deleted.";
        }
    }
}

$effects = Database::fetchAll("SELECT * FROM effects ORDER BY display_order ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Video Effects Library</h3>
        <p class="text-muted small mb-0">Manage visual overlay shaders, glitch animations, VHS filters, and PRO tier assignments.</p>
    </div>
    <button type="button" class="btn btn-primary rounded-pill px-3" onclick="openNewEffect()">
        <i class="bi bi-plus-lg me-1"></i> Add Effect
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
                    <th>Effect Label</th>
                    <th>Key</th>
                    <th>Category</th>
                    <th>Visual Palette</th>
                    <th>Tier</th>
                    <th>Status</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($effects as $e): ?>
                <tr>
                    <td>
                        <span class="badge bg-light text-dark border fw-bold"><?= (int)$e['display_order'] ?></span>
                    </td>
                    <td>
                        <div class="fw-bold text-dark"><?= htmlspecialchars($e['label']) ?></div>
                        <small class="text-muted"><?= htmlspecialchars($e['description']) ?></small>
                    </td>
                    <td>
                        <code><?= htmlspecialchars($e['effect_key']) ?></code>
                    </td>
                    <td>
                        <span class="badge badge-soft-primary"><?= htmlspecialchars($e['category']) ?></span>
                    </td>
                    <td>
                        <div class="d-flex gap-1 align-items-center">
                            <span class="rounded-circle d-inline-block border" style="width: 18px; height: 18px; background-color: <?= str_replace('0xFF', '#', $e['color1']) ?>;"></span>
                            <span class="rounded-circle d-inline-block border" style="width: 18px; height: 18px; background-color: <?= str_replace('0xFF', '#', $e['color2']) ?>;"></span>
                        </div>
                    </td>
                    <td>
                        <?php if ($e['is_pro']): ?>
                            <span class="badge bg-warning text-dark fw-bold">PRO</span>
                        <?php else: ?>
                            <span class="badge bg-light text-muted border">Free</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <form method="POST" action="" class="d-inline">
                            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                            <input type="hidden" name="id" value="<?= (int)$e['id'] ?>">
                            <input type="hidden" name="action" value="toggle_enabled">
                            <?php if ($e['is_enabled']): ?>
                                <button type="submit" class="badge badge-soft-success border-0 px-2 py-1">Active</button>
                            <?php else: ?>
                                <button type="submit" class="badge badge-soft-danger border-0 px-2 py-1">Hidden</button>
                            <?php endif; ?>
                        </form>
                    </td>
                    <td class="text-end">
                        <div class="d-flex justify-content-end gap-1">
                            <button class="btn btn-sm btn-outline-primary py-1 px-2" onclick='editEffect(<?= json_encode($e) ?>)'><i class="bi bi-pencil"></i></button>
                            <form method="POST" action="" onsubmit="return confirm('Delete this effect?');">
                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                <input type="hidden" name="id" value="<?= (int)$e['id'] ?>">
                                <input type="hidden" name="action" value="delete_effect">
                                <button type="submit" class="btn btn-sm btn-outline-danger py-1 px-2"><i class="bi bi-trash3"></i></button>
                            </form>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Effect -->
<div class="modal fade" id="effectModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold" id="efModalTitle">Configure Effect</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_effect">
                    <input type="hidden" name="id" id="efId" value="0">

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Effect Key</label>
                            <input type="text" name="effect_key" id="efKey" class="form-control" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Label</label>
                            <input type="text" name="label" id="efLabel" class="form-control" required>
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Category</label>
                            <select name="category" id="efCat" class="form-select">
                                <option value="Trending">Trending</option>
                                <option value="Glitch">Glitch</option>
                                <option value="Retro">Retro</option>
                                <option value="Light Effect">Light Effect</option>
                                <option value="Party">Party</option>
                                <option value="Distortion">Distortion</option>
                                <option value="Classic">Classic</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Order</label>
                            <input type="number" name="display_order" id="efOrder" class="form-control" value="1">
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Description</label>
                        <input type="text" name="description" id="efDesc" class="form-control">
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Color 1 (Hex/ARGB)</label>
                            <input type="text" name="color1" id="efCol1" class="form-control" value="0xFF084298">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Color 2 (Hex/ARGB)</label>
                            <input type="text" name="color2" id="efCol2" class="form-control" value="0xFF0D6EFD">
                        </div>
                    </div>

                    <div class="d-flex gap-4 mt-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_pro" id="efPro" value="1">
                            <label class="form-check-label fw-semibold small" for="efPro">Requires PRO</label>
                        </div>
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_enabled" id="efEnabled" value="1" checked>
                            <label class="form-check-label fw-semibold small" for="efEnabled">Enabled in Library</label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Effect</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function openNewEffect() {
    document.getElementById('efModalTitle').innerText = 'Add New Effect';
    document.getElementById('efId').value = '0';
    document.getElementById('efKey').value = '';
    document.getElementById('efKey').readOnly = false;
    document.getElementById('efLabel').value = '';
    document.getElementById('efCat').value = 'Trending';
    document.getElementById('efDesc').value = '';
    document.getElementById('efCol1').value = '0xFF2C2F38';
    document.getElementById('efCol2').value = '0xFF1E2028';
    document.getElementById('efOrder').value = '1';
    document.getElementById('efPro').checked = false;
    document.getElementById('efEnabled').checked = true;
    new bootstrap.Modal(document.getElementById('effectModal')).show();
}

function editEffect(e) {
    document.getElementById('efModalTitle').innerText = 'Edit Effect';
    document.getElementById('efId').value = e.id;
    document.getElementById('efKey').value = e.effect_key;
    document.getElementById('efKey').readOnly = true;
    document.getElementById('efLabel').value = e.label;
    document.getElementById('efCat').value = e.category;
    document.getElementById('efDesc').value = e.description || '';
    document.getElementById('efCol1').value = e.color1 || '0xFF2C2F38';
    document.getElementById('efCol2').value = e.color2 || '0xFF1E2028';
    document.getElementById('efOrder').value = e.display_order;
    document.getElementById('efPro').checked = e.is_pro == 1;
    document.getElementById('efEnabled').checked = e.is_enabled == 1;
    new bootstrap.Modal(document.getElementById('effectModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
