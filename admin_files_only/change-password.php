<?php
$pageTitle = 'Change Password';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token (CSRF).';
    } else {
        $currentPass = $_POST['current_password'] ?? '';
        $newPass = $_POST['new_password'] ?? '';
        $confirmPass = $_POST['confirm_password'] ?? '';

        if (empty($currentPass) || empty($newPass)) {
            $error = 'All password fields are required.';
        } elseif ($newPass !== $confirmPass) {
            $error = 'New password and confirmation do not match.';
        } elseif (strlen($newPass) < 8) {
            $error = 'New password must be at least 8 characters long.';
        } else {
            $admin = Database::fetchOne("SELECT password_hash FROM admins WHERE id = ?", [$currentAdmin['id']]);
            if (!$admin || !Auth::verifyPassword($currentPass, $admin['password_hash'])) {
                $error = 'Your current password was entered incorrectly.';
            } else {
                $newHash = Auth::hashPassword($newPass);
                Database::query("UPDATE admins SET password_hash = ?, updated_at = NOW() WHERE id = ?", [$newHash, $currentAdmin['id']]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'password_changed', 'Admin changed account password');
                $success = 'Password successfully updated!';
            }
        }
    }
}

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="row justify-content-center">
    <div class="col-lg-6 col-md-8">
        <div class="pro-card p-4">
            <div class="d-flex align-items-center gap-3 mb-4 pb-3 border-bottom">
                <div class="metric-icon-box bg-primary bg-opacity-10 text-primary">
                    <i class="bi bi-key-fill"></i>
                </div>
                <div>
                    <h5 class="mb-0 fw-bold">Change Administrative Password</h5>
                    <small class="text-muted">Ensure your account uses a strong, secure passphrase</small>
                </div>
            </div>

            <?php if (!empty($error)): ?>
                <div class="alert alert-danger py-2 px-3 small mb-3"><?= htmlspecialchars($error) ?></div>
            <?php endif; ?>
            <?php if (!empty($success)): ?>
                <div class="alert alert-success py-2 px-3 small mb-3"><?= htmlspecialchars($success) ?></div>
            <?php endif; ?>

            <form method="POST" action="">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">

                <div class="mb-3">
                    <label class="form-label small fw-semibold">Current Password</label>
                    <input type="password" name="current_password" class="form-control" required>
                </div>

                <div class="mb-3">
                    <label class="form-label small fw-semibold">New Password (min 8 chars)</label>
                    <input type="password" name="new_password" class="form-control" required minlength="8">
                </div>

                <div class="mb-4">
                    <label class="form-label small fw-semibold">Confirm New Password</label>
                    <input type="password" name="confirm_password" class="form-control" required minlength="8">
                </div>

                <div class="d-flex gap-2 justify-content-end">
                    <a href="<?= APP_BASE_URL ?>/admin/dashboard.php" class="btn btn-outline-secondary px-4">Cancel</a>
                    <button type="submit" class="btn btn-primary px-4">Update Password</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
