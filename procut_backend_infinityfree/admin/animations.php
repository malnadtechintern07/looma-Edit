<?php
$pageTitle = 'Clip Animations';
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
            $an = Database::fetchOne("SELECT * FROM animations WHERE id = ?", [$id]);
            if ($an) {
                $newVal = $an['is_enabled'] ? 0 : 1;
                Database::query("UPDATE animations SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'animation_toggled', "Toggled animation {$an['animation_key']}");
                $success = "Animation status updated.";
            }
        } elseif ($action === 'save_animation') {
            $id = (int)($_POST['id'] ?? 0);
            $key = trim($_POST['animation_key'] ?? '');
            $label = trim($_POST['label'] ?? '');
            $category = trim($_POST['category'] ?? 'in');
            $isPro = isset($_POST['is_pro']) ? 1 : 0;
            $enabled = isset($_POST['is_enabled']) ? 1 : 0;
            $order = (int)($_POST['display_order'] ?? 1);

            if (empty($key) || empty($label)) {
                $error = 'Key and label are required.';
            } else {
                if ($id > 0) {
                    Database::query(
                        "UPDATE animations SET animation_key = ?, label = ?, category = ?, is_pro = ?, is_enabled = ?, display_order = ?, updated_at = NOW()
                         WHERE id = ?",
                        [$key, $label, $category, $isPro, $enabled, $order, $id]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'animation_updated', "Updated animation {$key}");
                    $success = "Animation updated.";
                } else {
                    Database::query(
                        "INSERT INTO animations (animation_key, label, category, is_pro, is_enabled, display_order)
                         VALUES (?, ?, ?, ?, ?, ?)",
                        [$key, $label, $category, $isPro, $enabled, $order]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'animation_created', "Created animation {$key}");
                    $success = "Animation published.";
                }
            }
        } elseif ($action === 'delete_animation') {
            $id = (int)($_POST['id'] ?? 0);
            Database::query("DELETE FROM animations WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'animation_deleted', "Deleted animation ID {$id}");
            $success = "Animation deleted.";
        }
    }
}

$animations = Database::fetchAll("SELECT * FROM animations ORDER BY display_order ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Clip Animations Library</h3>
        <p class="text-muted small mb-0">Configure In, Out, and Combo clip entrance/exit keyframe animations.</p>
    </div>
    <button type="button" class="btn btn-primary rounded-pill px-3" onclick="openNewAnimation()">
        <i class="bi bi-plus-lg me-1"></i> Add Animation
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
                    <th>Animation Label</th>
                    <th>Identifier</th>
                    <th>Category</th>
                    <th>Tier</th>
                    <th>Status</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($animations as $an): ?>
                <tr>
                    <td>
                        <span class="badge bg-light text-dark border fw-bold"><?= (int)$an['display_order'] ?></span>
                    </td>
                    <td>
                        <div class="fw-bold text-dark d-flex align-items-center gap-2">
                            <i class="bi bi-play-circle-fill text-primary"></i>
                            <?= htmlspecialchars($an['label']) ?>
                        </div>
                    </td>
                    <td>
                        <code><?= htmlspecialchars($an['animation_key']) ?></code>
                    </td>
                    <td>
                        <span class="badge bg-light text-secondary border text-uppercase"><?= htmlspecialchars($an['category']) ?></span>
                    </td>
                    <td>
                        <?php if ($an['is_pro']): ?>
                            <span class="badge bg-warning text-dark fw-bold">PRO</span>
                        <?php else: ?>
                            <span class="badge bg-light text-muted border">Free</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <form method="POST" action="" class="d-inline">
                            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                            <input type="hidden" name="id" value="<?= (int)$an['id'] ?>">
                            <input type="hidden" name="action" value="toggle_enabled">
                            <?php if ($an['is_enabled']): ?>
                                <button type="submit" class="badge badge-soft-success border-0 px-2 py-1">Active</button>
                            <?php else: ?>
                                <button type="submit" class="badge badge-soft-danger border-0 px-2 py-1">Hidden</button>
                            <?php endif; ?>
                        </form>
                    </td>
                    <td class="text-end">
                        <div class="d-flex justify-content-end gap-1">
                            <button class="btn btn-sm btn-outline-primary py-1 px-2" onclick='editAnimation(<?= json_encode($an) ?>)'><i class="bi bi-pencil"></i></button>
                            <form method="POST" action="" onsubmit="return confirm('Delete this animation?');">
                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                <input type="hidden" name="id" value="<?= (int)$an['id'] ?>">
                                <input type="hidden" name="action" value="delete_animation">
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

<!-- Modal Animation -->
<div class="modal fade" id="animModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold" id="anModalTitle">Configure Animation</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_animation">
                    <input type="hidden" name="id" id="anId" value="0">

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Animation Key</label>
                            <input type="text" name="animation_key" id="anKey" class="form-control" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Label</label>
                            <input type="text" name="label" id="anLabel" class="form-control" required>
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Category</label>
                            <select name="category" id="anCat" class="form-select">
                                <option value="in">In (Entrance)</option>
                                <option value="out">Out (Exit)</option>
                                <option value="combo">Combo</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Order</label>
                            <input type="number" name="display_order" id="anOrder" class="form-control" value="1">
                        </div>
                    </div>

                    <div class="d-flex gap-4 mt-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_pro" id="anPro" value="1">
                            <label class="form-check-label fw-semibold small" for="anPro">Requires PRO</label>
                        </div>
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_enabled" id="anEnabled" value="1" checked>
                            <label class="form-check-label fw-semibold small" for="anEnabled">Active</label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Animation</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function openNewAnimation() {
    document.getElementById('anModalTitle').innerText = 'Add New Animation';
    document.getElementById('anId').value = '0';
    document.getElementById('anKey').value = '';
    document.getElementById('anKey').readOnly = false;
    document.getElementById('anLabel').value = '';
    document.getElementById('anCat').value = 'in';
    document.getElementById('anOrder').value = '1';
    document.getElementById('anPro').checked = false;
    document.getElementById('anEnabled').checked = true;
    new bootstrap.Modal(document.getElementById('animModal')).show();
}

function editAnimation(an) {
    document.getElementById('anModalTitle').innerText = 'Edit Animation';
    document.getElementById('anId').value = an.id;
    document.getElementById('anKey').value = an.animation_key;
    document.getElementById('anKey').readOnly = true;
    document.getElementById('anLabel').value = an.label;
    document.getElementById('anCat').value = an.category;
    document.getElementById('anOrder').value = an.display_order;
    document.getElementById('anPro').checked = an.is_pro == 1;
    document.getElementById('anEnabled').checked = an.is_enabled == 1;
    new bootstrap.Modal(document.getElementById('animModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
