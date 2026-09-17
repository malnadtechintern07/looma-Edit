<?php
$pageTitle = 'Admin Staff & Roles';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $action = $_POST['action'] ?? '';

        if ($action === 'create_admin') {
            Auth::requireRole('superadmin');
            $username = trim($_POST['username'] ?? '');
            $email = strtolower(trim($_POST['email'] ?? ''));
            $name = trim($_POST['name'] ?? '');
            $role = trim($_POST['role'] ?? 'admin');
            $password = $_POST['password'] ?? '';

            if (empty($username) || empty($email) || empty($password)) {
                $error = 'Username, email, and password are required.';
            } elseif (strlen($password) < 8) {
                $error = 'Password must be at least 8 characters long.';
            } else {
                $existing = Database::fetchOne("SELECT id FROM admins WHERE LOWER(email) = ? OR LOWER(username) = ?", [$email, $username]);
                if ($existing) {
                    $error = 'An admin with this username or email already exists.';
                } else {
                    $hash = Auth::hashPassword($password);
                    Database::query(
                        "INSERT INTO admins (username, email, password_hash, name, role, status)
                         VALUES (?, ?, ?, ?, ?, 'active')",
                        [$username, $email, $hash, $name, $role]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'admin_created', "Created admin staff member: {$username} ({$role})");
                    $success = "New administrator account created.";
                }
            }
        } elseif ($action === 'toggle_status') {
            Auth::requireRole('superadmin');
            $targetId = (int)($_POST['id'] ?? 0);
            if ($targetId === (int)$currentAdmin['id']) {
                $error = 'You cannot suspend your own administrative account.';
            } else {
                $adm = Database::fetchOne("SELECT * FROM admins WHERE id = ?", [$targetId]);
                if ($adm) {
                    $newStatus = ($adm['status'] === 'active') ? 'suspended' : 'active';
                    Database::query("UPDATE admins SET status = ?, updated_at = NOW() WHERE id = ?", [$newStatus, $targetId]);
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'admin_status_toggled', "Admin {$adm['username']} set to {$newStatus}");
                    $success = "Admin account status updated.";
                }
            }
        } elseif ($action === 'delete_admin') {
            Auth::requireRole('superadmin');
            $targetId = (int)($_POST['id'] ?? 0);
            if ($targetId === (int)$currentAdmin['id']) {
                $error = 'You cannot delete your own administrative account.';
            } else {
                Database::query("DELETE FROM admins WHERE id = ?", [$targetId]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'admin_deleted', "Deleted admin ID {$targetId}");
                $success = "Administrator removed.";
            }
        }
    }
}

$admins = Database::fetchAll("SELECT * FROM admins ORDER BY id ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Admin Staff & Permissions</h3>
        <p class="text-muted small mb-0">Manage authorized staff, assigned roles (Superadmin, Admin, Editor), and console credentials.</p>
    </div>
    <?php if ($currentAdmin['role'] === 'superadmin'): ?>
    <button type="button" class="btn btn-primary rounded-pill px-3" data-bs-toggle="modal" data-bs-target="#newAdminModal">
        <i class="bi bi-person-plus-fill me-1"></i> Add Admin
    </button>
    <?php endif; ?>
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
                    <th>Admin Name</th>
                    <th>Username & Email</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Last Active</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($admins as $adm): ?>
                <tr>
                    <td>
                        <div class="d-flex align-items-center gap-2">
                            <div class="rounded-circle bg-dark text-white d-flex align-items-center justify-content-center fw-bold" style="width: 38px; height: 38px;">
                                <?= strtoupper(substr($adm['name'] ?: 'A', 0, 1)) ?>
                            </div>
                            <div>
                                <div class="fw-bold text-dark"><?= htmlspecialchars($adm['name']) ?></div>
                                <?php if ($adm['id'] == $currentAdmin['id']): ?>
                                    <span class="badge badge-soft-primary" style="font-size: 10px;">Current User</span>
                                <?php endif; ?>
                            </div>
                        </div>
                    </td>
                    <td>
                        <div class="small fw-semibold"><?= htmlspecialchars($adm['username']) ?></div>
                        <div class="text-muted small"><?= htmlspecialchars($adm['email']) ?></div>
                    </td>
                    <td>
                        <?php if ($adm['role'] === 'superadmin'): ?>
                            <span class="badge bg-danger text-white fw-bold">Super Admin</span>
                        <?php elseif ($adm['role'] === 'admin'): ?>
                            <span class="badge bg-primary text-white">Admin</span>
                        <?php else: ?>
                            <span class="badge bg-secondary text-white">Editor</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <?php if ($adm['status'] === 'active'): ?>
                            <span class="badge badge-soft-success">Active</span>
                        <?php else: ?>
                            <span class="badge badge-soft-danger">Suspended</span>
                        <?php endif; ?>
                    </td>
                    <td class="small text-muted">
                        <?= $adm['last_login_at'] ? date('M d, Y H:i', strtotime($adm['last_login_at'])) : 'Never' ?>
                    </td>
                    <td class="text-end">
                        <?php if ($currentAdmin['role'] === 'superadmin' && $adm['id'] != $currentAdmin['id']): ?>
                            <div class="d-flex justify-content-end gap-1">
                                <form method="POST" action="" class="d-inline">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                    <input type="hidden" name="id" value="<?= (int)$adm['id'] ?>">
                                    <input type="hidden" name="action" value="toggle_status">
                                    <button type="submit" class="btn btn-sm btn-outline-warning py-1 px-2" title="Toggle Status">
                                        <i class="bi bi-slash-circle"></i>
                                    </button>
                                </form>
                                <form method="POST" action="" onsubmit="return confirm('Permanently remove this administrator?');" class="d-inline">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                    <input type="hidden" name="id" value="<?= (int)$adm['id'] ?>">
                                    <input type="hidden" name="action" value="delete_admin">
                                    <button type="submit" class="btn btn-sm btn-outline-danger py-1 px-2">
                                        <i class="bi bi-trash3"></i>
                                    </button>
                                </form>
                            </div>
                        <?php else: ?>
                            <span class="text-muted small">—</span>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Add Admin -->
<div class="modal fade" id="newAdminModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold">Add Administrative Staff</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="create_admin">

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Full Name</label>
                        <input type="text" name="name" class="form-control" placeholder="e.g. Alex Rivera" required>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Admin Username</label>
                            <input type="text" name="username" class="form-control" placeholder="alex" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Role</label>
                            <select name="role" class="form-select">
                                <option value="admin">Administrator</option>
                                <option value="editor">Content Editor</option>
                                <option value="superadmin">Super Administrator</option>
                            </select>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Email Address</label>
                        <input type="email" name="email" class="form-control" placeholder="alex@procut.app" required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Initial Password (min 8 chars)</label>
                        <input type="password" name="password" class="form-control" required minlength="8">
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Create Admin</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
