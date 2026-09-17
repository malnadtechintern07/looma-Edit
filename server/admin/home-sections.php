<?php
$pageTitle = 'Home Screen Sections';
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
            $section = Database::fetchOne("SELECT * FROM home_sections WHERE id = ?", [$id]);
            if ($section) {
                $newEnabled = $section['is_enabled'] ? 0 : 1;
                Database::query("UPDATE home_sections SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newEnabled, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'home_section_toggled', "Toggled {$section['section_key']} to " . ($newEnabled ? 'Enabled' : 'Disabled'));
                $success = "Section status updated.";
            }
        } elseif ($action === 'update_section') {
            $id = (int)($_POST['id'] ?? 0);
            $title = trim($_POST['title'] ?? '');
            $subtitle = trim($_POST['subtitle'] ?? '');
            $order = (int)($_POST['display_order'] ?? 0);
            $isEnabled = isset($_POST['is_enabled']) ? 1 : 0;

            if (!empty($title)) {
                Database::query(
                    "UPDATE home_sections SET title = ?, subtitle = ?, display_order = ?, is_enabled = ?, updated_at = NOW() WHERE id = ?",
                    [$title, $subtitle, $order, $isEnabled, $id]
                );
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'home_section_updated', "Updated home section ID {$id}");
                $success = "Section updated successfully.";
            }
        }
    }
}

$sections = Database::fetchAll("SELECT * FROM home_sections ORDER BY display_order ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Home Screen Layout & Sections</h3>
        <p class="text-muted small mb-0">Control the ordering, titles, and visibility of components on ProCut's main mobile screen.</p>
    </div>
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
                    <th style="width: 80px;">Order</th>
                    <th>Section Name</th>
                    <th>Key Identifier</th>
                    <th>Subtitle / Description</th>
                    <th>Status</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($sections as $s): ?>
                <tr>
                    <td>
                        <span class="badge bg-light text-dark border px-3 py-2 fs-6 fw-bold"><?= (int)$s['display_order'] ?></span>
                    </td>
                    <td>
                        <div class="fw-bold text-dark"><?= htmlspecialchars($s['title']) ?></div>
                    </td>
                    <td>
                        <code><?= htmlspecialchars($s['section_key']) ?></code>
                    </td>
                    <td>
                        <span class="small text-muted"><?= htmlspecialchars($s['subtitle'] ?? '—') ?></span>
                    </td>
                    <td>
                        <form method="POST" action="" class="d-inline">
                            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                            <input type="hidden" name="id" value="<?= (int)$s['id'] ?>">
                            <input type="hidden" name="action" value="toggle_enabled">
                            <?php if ($s['is_enabled']): ?>
                                <button type="submit" class="badge badge-soft-success border-0 px-3 py-1 text-decoration-none">
                                    <i class="bi bi-check-circle-fill me-1"></i>Active
                                </button>
                            <?php else: ?>
                                <button type="submit" class="badge badge-soft-danger border-0 px-3 py-1 text-decoration-none">
                                    <i class="bi bi-x-circle-fill me-1"></i>Disabled
                                </button>
                            <?php endif; ?>
                        </form>
                    </td>
                    <td class="text-end">
                        <button type="button" class="btn btn-sm btn-outline-primary py-1 px-3 rounded-2" onclick='editSection(<?= json_encode($s) ?>)'>
                            <i class="bi bi-pencil me-1"></i>Edit
                        </button>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Edit Section Modal -->
<div class="modal fade" id="editModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold">Configure Home Section</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="update_section">
                    <input type="hidden" name="id" id="editId">

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Section Identifier</label>
                        <input type="text" id="editKey" class="form-control bg-light text-muted" readonly>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Display Title</label>
                        <input type="text" name="title" id="editTitle" class="form-control" required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Subtitle</label>
                        <input type="text" name="subtitle" id="editSubtitle" class="form-control">
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Display Order</label>
                        <input type="number" name="display_order" id="editOrder" class="form-control" min="1" max="99" required>
                    </div>

                    <div class="form-check form-switch mt-3">
                        <input class="form-check-input" type="checkbox" name="is_enabled" id="editEnabled" value="1">
                        <label class="form-check-label fw-semibold small" for="editEnabled">Visible on Mobile App Home Screen</label>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function editSection(s) {
    document.getElementById('editId').value = s.id;
    document.getElementById('editKey').value = s.section_key;
    document.getElementById('editTitle').value = s.title;
    document.getElementById('editSubtitle').value = s.subtitle || '';
    document.getElementById('editOrder').value = s.display_order;
    document.getElementById('editEnabled').checked = s.is_enabled == 1;
    new bootstrap.Modal(document.getElementById('editModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
