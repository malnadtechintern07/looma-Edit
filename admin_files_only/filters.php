<?php
$pageTitle = 'Filters & Color Presets';
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
            $f = Database::fetchOne("SELECT * FROM filters WHERE id = ?", [$id]);
            if ($f) {
                $newVal = $f['is_enabled'] ? 0 : 1;
                Database::query("UPDATE filters SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'filter_toggled', "Toggled filter {$f['filter_key']}");
                $success = "Filter status updated.";
            }
        } elseif ($action === 'save_filter') {
            $id = (int)($_POST['id'] ?? 0);
            $key = trim($_POST['filter_key'] ?? '');
            $name = trim($_POST['name'] ?? '');
            $subtitle = trim($_POST['subtitle'] ?? '');
            $cat = trim($_POST['category'] ?? 'Cinematic & Film');
            $isPro = isset($_POST['is_pro']) ? 1 : 0;
            $enabled = isset($_POST['is_enabled']) ? 1 : 0;
            $order = (int)($_POST['display_order'] ?? 1);

            if (empty($key) || empty($name)) {
                $error = 'Filter key and name are required.';
            } else {
                if ($id > 0) {
                    Database::query(
                        "UPDATE filters SET filter_key = ?, name = ?, subtitle = ?, category = ?, is_pro = ?, is_enabled = ?, display_order = ?, updated_at = NOW()
                         WHERE id = ?",
                        [$key, $name, $subtitle, $cat, $isPro, $enabled, $order, $id]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'filter_updated', "Updated filter {$key}");
                    $success = "Filter updated.";
                } else {
                    Database::query(
                        "INSERT INTO filters (filter_key, name, subtitle, category, is_pro, is_enabled, display_order)
                         VALUES (?, ?, ?, ?, ?, ?, ?)",
                        [$key, $name, $subtitle, $cat, $isPro, $enabled, $order]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'filter_created', "Created filter {$key}");
                    $success = "Filter published.";
                }
            }
        } elseif ($action === 'delete_filter') {
            $id = (int)($_POST['id'] ?? 0);
            Database::query("DELETE FROM filters WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'filter_deleted', "Deleted filter ID {$id}");
            $success = "Filter deleted.";
        }
    }
}

$filters = Database::fetchAll("SELECT * FROM filters ORDER BY display_order ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Color Filters & LUT Presets</h3>
        <p class="text-muted small mb-0">Manage 4x5 Color Grading matrices, cinematic teal & orange LUTs, and vintage Kodachrome presets.</p>
    </div>
    <button type="button" class="btn btn-primary rounded-pill px-3" onclick="openNewFilter()">
        <i class="bi bi-plus-lg me-1"></i> Add Filter
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
                    <th>Filter Name</th>
                    <th>Identifier</th>
                    <th>Category</th>
                    <th>Tier</th>
                    <th>Status</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($filters as $fl): ?>
                <tr>
                    <td>
                        <span class="badge bg-light text-dark border fw-bold"><?= (int)$fl['display_order'] ?></span>
                    </td>
                    <td>
                        <div class="fw-bold text-dark"><?= htmlspecialchars($fl['name']) ?></div>
                        <small class="text-muted"><?= htmlspecialchars($fl['subtitle'] ?? '') ?></small>
                    </td>
                    <td>
                        <code><?= htmlspecialchars($fl['filter_key']) ?></code>
                    </td>
                    <td>
                        <span class="badge badge-soft-info"><?= htmlspecialchars($fl['category']) ?></span>
                    </td>
                    <td>
                        <?php if ($fl['is_pro']): ?>
                            <span class="badge bg-warning text-dark fw-bold">PRO</span>
                        <?php else: ?>
                            <span class="badge bg-light text-muted border">Free</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <form method="POST" action="" class="d-inline">
                            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                            <input type="hidden" name="id" value="<?= (int)$fl['id'] ?>">
                            <input type="hidden" name="action" value="toggle_enabled">
                            <?php if ($fl['is_enabled']): ?>
                                <button type="submit" class="badge badge-soft-success border-0 px-2 py-1">Active</button>
                            <?php else: ?>
                                <button type="submit" class="badge badge-soft-danger border-0 px-2 py-1">Hidden</button>
                            <?php endif; ?>
                        </form>
                    </td>
                    <td class="text-end">
                        <div class="d-flex justify-content-end gap-1">
                            <button class="btn btn-sm btn-outline-primary py-1 px-2" onclick='editFilter(<?= json_encode($fl) ?>)'><i class="bi bi-pencil"></i></button>
                            <form method="POST" action="" onsubmit="return confirm('Delete this filter?');">
                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                <input type="hidden" name="id" value="<?= (int)$fl['id'] ?>">
                                <input type="hidden" name="action" value="delete_filter">
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

<!-- Modal Filter -->
<div class="modal fade" id="filterModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold" id="flModalTitle">Configure Filter</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_filter">
                    <input type="hidden" name="id" id="flId" value="0">

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Filter Key</label>
                            <input type="text" name="filter_key" id="flKey" class="form-control" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Name</label>
                            <input type="text" name="name" id="flName" class="form-control" required>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Subtitle</label>
                        <input type="text" name="subtitle" id="flSub" class="form-control">
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Category</label>
                            <select name="category" id="flCat" class="form-select">
                                <option value="Cinematic & Film">Cinematic & Film</option>
                                <option value="Vintage & Retro">Vintage & Retro</option>
                                <option value="Warm & Sun">Warm & Sun</option>
                                <option value="Cool & Frost">Cool & Frost</option>
                                <option value="B&W & Noir">B&W & Noir</option>
                                <option value="Artistic & Pop">Artistic & Pop</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Order</label>
                            <input type="number" name="display_order" id="flOrder" class="form-control" value="1">
                        </div>
                    </div>

                    <div class="d-flex gap-4 mt-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_pro" id="flPro" value="1">
                            <label class="form-check-label fw-semibold small" for="flPro">Requires PRO</label>
                        </div>
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_enabled" id="flEnabled" value="1" checked>
                            <label class="form-check-label fw-semibold small" for="flEnabled">Enabled in Editor</label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Filter</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function openNewFilter() {
    document.getElementById('flModalTitle').innerText = 'Add New Filter';
    document.getElementById('flId').value = '0';
    document.getElementById('flKey').value = '';
    document.getElementById('flKey').readOnly = false;
    document.getElementById('flName').value = '';
    document.getElementById('flSub').value = '';
    document.getElementById('flCat').value = 'Cinematic & Film';
    document.getElementById('flOrder').value = '1';
    document.getElementById('flPro').checked = false;
    document.getElementById('flEnabled').checked = true;
    new bootstrap.Modal(document.getElementById('filterModal')).show();
}

function editFilter(fl) {
    document.getElementById('flModalTitle').innerText = 'Edit Filter';
    document.getElementById('flId').value = fl.id;
    document.getElementById('flKey').value = fl.filter_key;
    document.getElementById('flKey').readOnly = true;
    document.getElementById('flName').value = fl.name;
    document.getElementById('flSub').value = fl.subtitle || '';
    document.getElementById('flCat').value = fl.category;
    document.getElementById('flOrder').value = fl.display_order;
    document.getElementById('flPro').checked = fl.is_pro == 1;
    document.getElementById('flEnabled').checked = fl.is_enabled == 1;
    new bootstrap.Modal(document.getElementById('filterModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
