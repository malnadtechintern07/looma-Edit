<?php
$pageTitle = 'Transitions Library';
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
            $tr = Database::fetchOne("SELECT * FROM transitions WHERE id = ?", [$id]);
            if ($tr) {
                $newVal = $tr['is_enabled'] ? 0 : 1;
                Database::query("UPDATE transitions SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'transition_toggled', "Toggled transition {$tr['transition_key']}");
                $success = "Transition status updated.";
            }
        } elseif ($action === 'save_transition') {
            $id = (int)($_POST['id'] ?? 0);
            $key = trim($_POST['transition_key'] ?? '');
            $label = trim($_POST['label'] ?? '');
            $desc = trim($_POST['description'] ?? '');
            $icon = trim($_POST['icon_name'] ?? 'transition');
            $isPro = isset($_POST['is_pro']) ? 1 : 0;
            $enabled = isset($_POST['is_enabled']) ? 1 : 0;
            $order = (int)($_POST['display_order'] ?? 1);

            if (empty($key) || empty($label)) {
                $error = 'Key and label are required.';
            } else {
                if ($id > 0) {
                    Database::query(
                        "UPDATE transitions SET transition_key = ?, label = ?, description = ?, icon_name = ?, is_pro = ?, is_enabled = ?, display_order = ?, updated_at = NOW()
                         WHERE id = ?",
                        [$key, $label, $desc, $icon, $isPro, $enabled, $order, $id]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'transition_updated', "Updated transition {$key}");
                    $success = "Transition updated.";
                } else {
                    Database::query(
                        "INSERT INTO transitions (transition_key, label, description, icon_name, is_pro, is_enabled, display_order)
                         VALUES (?, ?, ?, ?, ?, ?, ?)",
                        [$key, $label, $desc, $icon, $isPro, $enabled, $order]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'transition_created', "Created transition {$key}");
                    $success = "Transition published.";
                }
            }
        } elseif ($action === 'delete_transition') {
            $id = (int)($_POST['id'] ?? 0);
            Database::query("DELETE FROM transitions WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'transition_deleted', "Deleted transition ID {$id}");
            $success = "Transition deleted.";
        }
    }
}

$transitions = Database::fetchAll("SELECT * FROM transitions ORDER BY display_order ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Clip Transitions Library</h3>
        <p class="text-muted small mb-0">Manage cross-fades, whip slides, zoom cuts, glitch transitions, and PRO designations.</p>
    </div>
    <button type="button" class="btn btn-primary rounded-pill px-3" onclick="openNewTransition()">
        <i class="bi bi-plus-lg me-1"></i> Add Transition
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
                    <th>Transition Label</th>
                    <th>Identifier</th>
                    <th>Description</th>
                    <th>Tier</th>
                    <th>Status</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($transitions as $tr): ?>
                <tr>
                    <td>
                        <span class="badge bg-light text-dark border fw-bold"><?= (int)$tr['display_order'] ?></span>
                    </td>
                    <td>
                        <div class="fw-bold text-dark d-flex align-items-center gap-2">
                            <i class="bi bi-arrow-left-right text-primary"></i>
                            <?= htmlspecialchars($tr['label']) ?>
                        </div>
                    </td>
                    <td>
                        <code><?= htmlspecialchars($tr['transition_key']) ?></code>
                    </td>
                    <td>
                        <span class="small text-muted"><?= htmlspecialchars($tr['description'] ?? '') ?></span>
                    </td>
                    <td>
                        <?php if ($tr['is_pro']): ?>
                            <span class="badge bg-warning text-dark fw-bold">PRO</span>
                        <?php else: ?>
                            <span class="badge bg-light text-muted border">Free</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <form method="POST" action="" class="d-inline">
                            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                            <input type="hidden" name="id" value="<?= (int)$tr['id'] ?>">
                            <input type="hidden" name="action" value="toggle_enabled">
                            <?php if ($tr['is_enabled']): ?>
                                <button type="submit" class="badge badge-soft-success border-0 px-2 py-1">Active</button>
                            <?php else: ?>
                                <button type="submit" class="badge badge-soft-danger border-0 px-2 py-1">Hidden</button>
                            <?php endif; ?>
                        </form>
                    </td>
                    <td class="text-end">
                        <div class="d-flex justify-content-end gap-1">
                            <button class="btn btn-sm btn-outline-primary py-1 px-2" onclick='editTransition(<?= json_encode($tr) ?>)'><i class="bi bi-pencil"></i></button>
                            <form method="POST" action="" onsubmit="return confirm('Delete this transition?');">
                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                <input type="hidden" name="id" value="<?= (int)$tr['id'] ?>">
                                <input type="hidden" name="action" value="delete_transition">
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

<!-- Modal Transition -->
<div class="modal fade" id="transitionModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold" id="trModalTitle">Configure Transition</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_transition">
                    <input type="hidden" name="id" id="trId" value="0">

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Transition Key</label>
                            <input type="text" name="transition_key" id="trKey" class="form-control" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Label</label>
                            <input type="text" name="label" id="trLabel" class="form-control" required>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Description</label>
                        <input type="text" name="description" id="trDesc" class="form-control">
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Order</label>
                            <input type="number" name="display_order" id="trOrder" class="form-control" value="1">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Icon Identifier</label>
                            <input type="text" name="icon_name" id="trIcon" class="form-control" value="transition">
                        </div>
                    </div>

                    <div class="d-flex gap-4 mt-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_pro" id="trPro" value="1">
                            <label class="form-check-label fw-semibold small" for="trPro">Requires PRO</label>
                        </div>
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_enabled" id="trEnabled" value="1" checked>
                            <label class="form-check-label fw-semibold small" for="trEnabled">Active</label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Transition</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function openNewTransition() {
    document.getElementById('trModalTitle').innerText = 'Add New Transition';
    document.getElementById('trId').value = '0';
    document.getElementById('trKey').value = '';
    document.getElementById('trKey').readOnly = false;
    document.getElementById('trLabel').value = '';
    document.getElementById('trDesc').value = '';
    document.getElementById('trOrder').value = '1';
    document.getElementById('trPro').checked = false;
    document.getElementById('trEnabled').checked = true;
    new bootstrap.Modal(document.getElementById('transitionModal')).show();
}

function editTransition(tr) {
    document.getElementById('trModalTitle').innerText = 'Edit Transition';
    document.getElementById('trId').value = tr.id;
    document.getElementById('trKey').value = tr.transition_key;
    document.getElementById('trKey').readOnly = true;
    document.getElementById('trLabel').value = tr.label;
    document.getElementById('trDesc').value = tr.description || '';
    document.getElementById('trOrder').value = tr.display_order;
    document.getElementById('trPro').checked = tr.is_pro == 1;
    document.getElementById('trEnabled').checked = tr.is_enabled == 1;
    new bootstrap.Modal(document.getElementById('transitionModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
