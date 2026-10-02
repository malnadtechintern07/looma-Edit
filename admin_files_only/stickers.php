<?php
$pageTitle = 'Stickers & Clipart';
require_once __DIR__ . '/includes/auth_check.php';
require_once __DIR__ . '/../helpers/uploader.php';

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
            $s = Database::fetchOne("SELECT * FROM stickers WHERE id = ?", [$id]);
            if ($s) {
                $newVal = $s['is_enabled'] ? 0 : 1;
                Database::query("UPDATE stickers SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'sticker_toggled', "Toggled sticker ID {$id}");
                $success = "Sticker status updated.";
            }
        } elseif ($action === 'save_sticker') {
            $id = (int)($_POST['id'] ?? 0);
            $key = trim($_POST['sticker_key'] ?? '');
            $name = trim($_POST['name'] ?? '');
            $cat = trim($_POST['category'] ?? 'Vlog');
            $imgUrl = trim($_POST['image_url'] ?? '');
            $isPro = isset($_POST['is_pro']) ? 1 : 0;
            $enabled = isset($_POST['is_enabled']) ? 1 : 0;
            $order = (int)($_POST['display_order'] ?? 1);

            if (!empty($_FILES['sticker_image']['name'])) {
                $allowed = ['image/png', 'image/webp', 'image/jpeg', 'image/gif'];
                $upload = Uploader::uploadFile($_FILES['sticker_image'], STICKER_UPLOAD_DIR, $allowed, 10485760);
                if ($upload['success']) {
                    $imgUrl = $upload['web_url'];
                } else {
                    $error = $upload['error'];
                }
            }

            if (empty($error)) {
                if (empty($key) || empty($name) || empty($imgUrl)) {
                    $error = 'Key, name, and image are required.';
                } else {
                    if ($id > 0) {
                        Database::query(
                            "UPDATE stickers SET sticker_key = ?, name = ?, category = ?, image_url = ?, is_pro = ?, is_enabled = ?, display_order = ?, updated_at = NOW()
                             WHERE id = ?",
                            [$key, $name, $cat, $imgUrl, $isPro, $enabled, $order, $id]
                        );
                        Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'sticker_updated', "Updated sticker {$key}");
                        $success = "Sticker updated.";
                    } else {
                        Database::query(
                            "INSERT INTO stickers (sticker_key, name, category, image_url, is_pro, is_enabled, display_order)
                             VALUES (?, ?, ?, ?, ?, ?, ?)",
                            [$key, $name, $cat, $imgUrl, $isPro, $enabled, $order]
                        );
                        Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'sticker_created', "Created sticker {$key}");
                        $success = "Sticker added.";
                    }
                }
            }
        } elseif ($action === 'delete_sticker') {
            $id = (int)($_POST['id'] ?? 0);
            Database::query("DELETE FROM stickers WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'sticker_deleted', "Deleted sticker ID {$id}");
            $success = "Sticker deleted.";
        }
    }
}

$stickers = Database::fetchAll("SELECT * FROM stickers ORDER BY display_order ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Stickers & Overlays Library</h3>
        <p class="text-muted small mb-0">Manage clipart, badges, PNG overlays, and interactive video stickers.</p>
    </div>
    <button type="button" class="btn btn-primary rounded-pill px-3" onclick="openNewSticker()">
        <i class="bi bi-plus-lg me-1"></i> Add Sticker
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
                    <th>Sticker Image</th>
                    <th>Name & Key</th>
                    <th>Category</th>
                    <th>Tier</th>
                    <th>Status</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($stickers as $st): ?>
                <tr>
                    <td>
                        <span class="badge bg-light text-dark border fw-bold"><?= (int)$st['display_order'] ?></span>
                    </td>
                    <td>
                        <div class="p-1 rounded bg-light border d-inline-block text-center" style="width: 44px; height: 44px;">
                            <img src="<?= htmlspecialchars($st['image_url']) ?>" alt="Sticker" style="max-width: 100%; max-height: 100%; object-fit: contain;" onerror="this.src='https://placehold.co/44?text=PNG'">
                        </div>
                    </td>
                    <td>
                        <div class="fw-bold text-dark"><?= htmlspecialchars($st['name']) ?></div>
                        <code><?= htmlspecialchars($st['sticker_key']) ?></code>
                    </td>
                    <td>
                        <span class="badge badge-soft-info"><?= htmlspecialchars($st['category']) ?></span>
                    </td>
                    <td>
                        <?php if ($st['is_pro']): ?>
                            <span class="badge bg-warning text-dark fw-bold">PRO</span>
                        <?php else: ?>
                            <span class="badge bg-light text-muted border">Free</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <form method="POST" action="" class="d-inline">
                            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                            <input type="hidden" name="id" value="<?= (int)$st['id'] ?>">
                            <input type="hidden" name="action" value="toggle_enabled">
                            <?php if ($st['is_enabled']): ?>
                                <button type="submit" class="badge badge-soft-success border-0 px-2 py-1">Active</button>
                            <?php else: ?>
                                <button type="submit" class="badge badge-soft-danger border-0 px-2 py-1">Hidden</button>
                            <?php endif; ?>
                        </form>
                    </td>
                    <td class="text-end">
                        <div class="d-flex justify-content-end gap-1">
                            <button class="btn btn-sm btn-outline-primary py-1 px-2" onclick='editSticker(<?= json_encode($st) ?>)'><i class="bi bi-pencil"></i></button>
                            <form method="POST" action="" onsubmit="return confirm('Delete this sticker?');">
                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                <input type="hidden" name="id" value="<?= (int)$st['id'] ?>">
                                <input type="hidden" name="action" value="delete_sticker">
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

<!-- Modal Sticker -->
<div class="modal fade" id="stickerModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold" id="stModalTitle">Configure Sticker</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="" enctype="multipart/form-data">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_sticker">
                    <input type="hidden" name="id" id="stId" value="0">

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Sticker Key</label>
                            <input type="text" name="sticker_key" id="stKey" class="form-control" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Name</label>
                            <input type="text" name="name" id="stName" class="form-control" required>
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Category</label>
                            <select name="category" id="stCat" class="form-select">
                                <option value="Reels">Reels</option>
                                <option value="Love">Love</option>
                                <option value="Celebration">Celebration</option>
                                <option value="Vlog">Vlog</option>
                                <option value="Social">Social</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Order</label>
                            <input type="number" name="display_order" id="stOrder" class="form-control" value="1">
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Upload Image (PNG/WebP)</label>
                        <input type="file" name="sticker_image" class="form-control" accept="image/*">
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Or Image Asset URL</label>
                        <input type="text" name="image_url" id="stImg" class="form-control" placeholder="assets/stickers/name.png">
                    </div>

                    <div class="d-flex gap-4 mt-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_pro" id="stPro" value="1">
                            <label class="form-check-label fw-semibold small" for="stPro">Requires PRO</label>
                        </div>
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_enabled" id="stEnabled" value="1" checked>
                            <label class="form-check-label fw-semibold small" for="stEnabled">Active</label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Sticker</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function openNewSticker() {
    document.getElementById('stModalTitle').innerText = 'Add New Sticker';
    document.getElementById('stId').value = '0';
    document.getElementById('stKey').value = '';
    document.getElementById('stKey').readOnly = false;
    document.getElementById('stName').value = '';
    document.getElementById('stCat').value = 'Vlog';
    document.getElementById('stImg').value = 'assets/stickers/sparkle.png';
    document.getElementById('stOrder').value = '1';
    document.getElementById('stPro').checked = false;
    document.getElementById('stEnabled').checked = true;
    new bootstrap.Modal(document.getElementById('stickerModal')).show();
}

function editSticker(st) {
    document.getElementById('stModalTitle').innerText = 'Edit Sticker';
    document.getElementById('stId').value = st.id;
    document.getElementById('stKey').value = st.sticker_key;
    document.getElementById('stKey').readOnly = true;
    document.getElementById('stName').value = st.name;
    document.getElementById('stCat').value = st.category;
    document.getElementById('stImg').value = st.image_url;
    document.getElementById('stOrder').value = st.display_order;
    document.getElementById('stPro').checked = st.is_pro == 1;
    document.getElementById('stEnabled').checked = st.is_enabled == 1;
    new bootstrap.Modal(document.getElementById('stickerModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
