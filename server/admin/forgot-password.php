<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/auth.php';

Auth::startSession();

$error = '';
$success = '';
$step = 1;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    
    if ($action === 'request') {
        $email = strtolower(trim($_POST['email'] ?? ''));
        if (empty($email)) {
            $error = 'Admin email address is required.';
        } else {
            $admin = Database::fetchOne("SELECT * FROM admins WHERE LOWER(email) = ?", [$email]);
            if ($admin) {
                // Generate secure 6-digit recovery code
                $code = sprintf('%06d', random_int(100000, 999999));
                $codeHash = hash('sha256', $code);
                $expires = date('Y-m-d H:i:s', time() + 1800);

                Database::query(
                    "UPDATE admins SET reset_token_hash = ?, reset_token_expires_at = ? WHERE id = ?",
                    [$codeHash, $expires, $admin['id']]
                );

                Auth::logActivity('system', (string)$admin['id'], $admin['name'], 'admin_password_reset_requested', "Recovery code generated for {$email}");
                $_SESSION['reset_admin_id'] = $admin['id'];
                $_SESSION['reset_email'] = $email;
                $step = 2;
                $success = "Verification code generated! (For local/development safety, your code is: <strong>{$code}</strong>)";
            } else {
                $error = 'No administrative account found with this email address.';
            }
        }
    } elseif ($action === 'verify_reset') {
        $step = 2;
        $adminId = $_SESSION['reset_admin_id'] ?? null;
        $code = trim($_POST['code'] ?? '');
        $newPass = $_POST['new_password'] ?? '';
        $confirmPass = $_POST['confirm_password'] ?? '';

        if (!$adminId) {
            $error = 'Reset session expired. Please start over.';
            $step = 1;
        } elseif (empty($code) || empty($newPass)) {
            $error = 'Verification code and new password are required.';
        } elseif ($newPass !== $confirmPass) {
            $error = 'Passwords do not match.';
        } elseif (strlen($newPass) < 8) {
            $error = 'New password must be at least 8 characters long.';
        } else {
            $admin = Database::fetchOne("SELECT * FROM admins WHERE id = ?", [$adminId]);
            $codeHash = hash('sha256', $code);

            if (!$admin || !hash_equals($admin['reset_token_hash'] ?? '', $codeHash)) {
                $error = 'Invalid verification code.';
            } elseif (strtotime($admin['reset_token_expires_at']) < time()) {
                $error = 'Verification code has expired. Please request a new one.';
                $step = 1;
            } else {
                $newHash = Auth::hashPassword($newPass);
                Database::query(
                    "UPDATE admins SET password_hash = ?, reset_token_hash = NULL, reset_token_expires_at = NULL WHERE id = ?",
                    [$newHash, $adminId]
                );
                Auth::logActivity('admin', (string)$adminId, $admin['name'], 'admin_password_reset_completed', 'Password reset using verification code');
                unset($_SESSION['reset_admin_id'], $_SESSION['reset_email']);
                header('Location: ' . APP_BASE_URL . '/admin/login.php?success=password_reset');
                exit;
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Admin Password — ProCut</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Space+Grotesk:wght@600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background: linear-gradient(135deg, #0F172A 0%, #081B3A 50%, #061124 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            color: #E2E8F0;
        }
        .card-custom {
            background: rgba(30, 41, 59, 0.75);
            backdrop-filter: blur(16px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 24px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.4);
            width: 100%;
            max-width: 460px;
            padding: 36px;
        }
        .form-control {
            background: rgba(15, 23, 42, 0.6);
            border: 1px solid rgba(255, 255, 255, 0.12);
            color: #FFF;
            padding: 12px 16px;
            border-radius: 12px;
        }
        .form-control:focus {
            background: rgba(15, 23, 42, 0.8);
            border-color: #0D6EFD;
            color: #FFF;
        }
    </style>
</head>
<body>
    <div class="card-custom">
        <div class="text-center mb-4">
            <div class="d-inline-flex align-items-center gap-2 mb-2">
                <i class="bi bi-shield-lock-fill fs-2 text-primary"></i>
                <span class="fs-4 fw-bold text-white">Reset Admin Password</span>
            </div>
            <p class="text-secondary small">Verify identity and regain administrative access</p>
        </div>

        <?php if (!empty($error)): ?>
            <div class="alert alert-danger py-2 px-3 rounded-3 mb-3 small"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>
        <?php if (!empty($success)): ?>
            <div class="alert alert-success py-2 px-3 rounded-3 mb-3 small"><?= $success ?></div>
        <?php endif; ?>

        <?php if ($step === 1): ?>
            <form method="POST" action="">
                <input type="hidden" name="action" value="request">
                <div class="mb-3">
                    <label class="form-label small text-secondary fw-semibold">Registered Admin Email</label>
                    <input type="email" name="email" class="form-control" placeholder="admin@procut.app" required autofocus>
                </div>
                <div class="d-grid mt-4">
                    <button type="submit" class="btn btn-primary py-2 rounded-3 fw-semibold">Send Recovery Code</button>
                </div>
            </form>
        <?php else: ?>
            <form method="POST" action="">
                <input type="hidden" name="action" value="verify_reset">
                <div class="mb-3">
                    <label class="form-label small text-secondary fw-semibold">6-Digit Verification Code</label>
                    <input type="text" name="code" class="form-control text-center fs-5 fw-bold letter-spacing-2" maxlength="6" required autofocus>
                </div>
                <div class="mb-3">
                    <label class="form-label small text-secondary fw-semibold">New Password (min 8 chars)</label>
                    <input type="password" name="new_password" class="form-control" required minlength="8">
                </div>
                <div class="mb-4">
                    <label class="form-label small text-secondary fw-semibold">Confirm New Password</label>
                    <input type="password" name="confirm_password" class="form-control" required minlength="8">
                </div>
                <div class="d-grid">
                    <button type="submit" class="btn btn-success py-2 rounded-3 fw-semibold">Update Password & Login</button>
                </div>
            </form>
        <?php endif; ?>

        <div class="text-center mt-4">
            <a href="<?= APP_BASE_URL ?>/admin/login.php" class="small text-secondary text-decoration-none">
                <i class="bi bi-arrow-left me-1"></i> Back to Admin Sign In
            </a>
        </div>
    </div>
</body>
</html>
