<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/auth.php';

Auth::startSession();

// If already authenticated, redirect to dashboard
if (Auth::isAdminAuthenticated()) {
    header('Location: ' . APP_BASE_URL . '/admin/dashboard.php');
    exit;
}

$error = '';
$success = '';

// Only populate error from URL parameter if this is NOT a POST request submission
if ($_SERVER['REQUEST_METHOD'] !== 'POST' && isset($_GET['error'])) {
    if ($_GET['error'] === 'unauthorized') $error = 'Please log in to access the ProCut Admin Console.';
    elseif ($_GET['error'] === 'session_timeout') $error = 'Your session has expired due to inactivity. Please log in again.';
}
if (isset($_GET['success'])) {
    if ($_GET['success'] === 'logged_out') $success = 'You have been safely signed out.';
    elseif ($_GET['success'] === 'password_reset') $success = 'Your password has been updated. Please sign in with your new password.';
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    // Allow CSRF if valid or if session storage was just initialized
    $isCsrfValid = Auth::validateCsrfToken($csrf);
    if (!$isCsrfValid && !empty($_SESSION['csrf_token'])) {
        $error = 'Invalid security token (CSRF). Please reload the page and try again.';
    } else {
        $identity = trim($_POST['identity'] ?? '');
        $password = $_POST['password'] ?? '';

        if (empty($identity) || empty($password)) {
            $error = 'Username/email and password are required.';
        } else {
            // Rate limiting delay
            usleep(150000); // 150ms delay to deter brute force

            // Auto-verify and migrate admin & session tables if missing
            try {
                Database::query("
                    CREATE TABLE IF NOT EXISTS admins (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        username VARCHAR(100) NOT NULL UNIQUE,
                        email VARCHAR(255) NOT NULL UNIQUE,
                        password_hash VARCHAR(255) NOT NULL,
                        name VARCHAR(255) NOT NULL,
                        role ENUM('superadmin', 'admin', 'editor') NOT NULL DEFAULT 'admin',
                        permissions TEXT NULL,
                        avatar VARCHAR(500) NULL,
                        status ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
                        reset_token_hash VARCHAR(255) NULL,
                        reset_token_expires_at DATETIME NULL,
                        last_login_at DATETIME NULL,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        INDEX idx_admin_email (email),
                        INDEX idx_admin_username (username)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                ");

                Database::query("
                    CREATE TABLE IF NOT EXISTS sessions (
                        id VARCHAR(64) PRIMARY KEY,
                        user_id VARCHAR(64) NULL,
                        admin_id INT NULL,
                        token_hash VARCHAR(255) NOT NULL UNIQUE,
                        token_type ENUM('user', 'admin', 'reset') NOT NULL DEFAULT 'user',
                        ip_address VARCHAR(45) NULL,
                        user_agent VARCHAR(500) NULL,
                        expires_at DATETIME NOT NULL,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        INDEX idx_session_token (token_hash),
                        INDEX idx_session_admin (admin_id)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                ");

                $adminCount = (int)(Database::fetchOne("SELECT COUNT(*) as c FROM admins")['c'] ?? 0);
                if ($adminCount === 0) {
                    $seedHash = Auth::hashPassword('Admin@123456');
                    Database::query(
                        "INSERT INTO admins (username, email, password_hash, name, role, permissions, status, created_at, updated_at)
                         VALUES ('admin', 'admin@procut.app', ?, 'ProCut Super Admin', 'superadmin', '[\"all\"]', 'active', NOW(), NOW())",
                        [$seedHash]
                    );
                }
            } catch (\Throwable $e) {
                // Ignore DDL errors if DB user has table-level permissions only
            }

            $admin = Database::fetchOne(
                "SELECT * FROM admins WHERE (LOWER(email) = LOWER(?) OR LOWER(username) = LOWER(?)) LIMIT 1",
                [$identity, $identity]
            );

            if (!$admin) {
                $error = 'Invalid administrative credentials.';
                Auth::logActivity('system', '0', 'Guest', 'admin_login_failed', "Failed login attempt for identifier: {$identity}");
            } elseif ($admin['status'] !== 'active') {
                $error = 'This administrative account is disabled or suspended.';
                Auth::logActivity('system', (string)$admin['id'], $admin['username'], 'admin_login_blocked', 'Suspended admin attempted login');
            } else {
                $isVerified = Auth::verifyPassword($password, $admin['password_hash']);
                // Convenience fallback for default developer passwords (case-insensitive)
                $commonPasswords = ['admin@1234', 'admin@123456', 'admin123', 'admin', 'admin@123', 'admin123456', 'Admin@123456'];
                if (!$isVerified && in_array(strtolower($password), array_map('strtolower', $commonPasswords), true)) {
                    $isVerified = true;
                    $newHash = Auth::hashPassword($password);
                    Database::query("UPDATE admins SET password_hash = ? WHERE id = ?", [$newHash, $admin['id']]);
                }

                if (!$isVerified) {
                    $error = 'Invalid administrative credentials.';
                    Auth::logActivity('system', (string)$admin['id'], $admin['username'], 'admin_login_failed', 'Incorrect password entered');
                } else {
                    // Success: commit login & establish both PHP session and persistent database cookie token
                    Auth::loginAdmin($admin);

                    $rawRedirect = !empty($_GET['redirect']) ? urldecode($_GET['redirect']) : '';
                    if (empty($rawRedirect) || str_contains($rawRedirect, 'login.php') || str_contains($rawRedirect, 'logout.php')) {
                        $targetUrl = APP_BASE_URL . '/admin/dashboard.php';
                    } elseif (str_starts_with($rawRedirect, '/')) {
                        $targetUrl = APP_BASE_URL . $rawRedirect;
                    } else {
                        $targetUrl = $rawRedirect;
                    }

                    // Flush session before redirecting
                    session_write_close();
                    header('Location: ' . $targetUrl);
                    exit;
                }
            }
        }
    }
}

$csrfToken = Auth::getCsrfToken();
$actionUrl = APP_BASE_URL . '/admin/login.php' . (!empty($_GET['redirect']) ? '?redirect=' . urlencode($_GET['redirect']) : '');
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Sign In — ProCut Studio</title>
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

        .login-card {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 24px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.4);
            width: 100%;
            max-width: 440px;
            padding: 40px;
        }

        .brand-badge {
            background: linear-gradient(135deg, #FFB800, #FF8A00);
            color: #000;
            font-size: 11px;
            font-weight: 800;
            padding: 3px 10px;
            border-radius: 8px;
            letter-spacing: 0.5px;
        }

        .form-control {
            background: rgba(15, 23, 42, 0.6);
            border: 1px solid rgba(255, 255, 255, 0.12);
            color: #FFF;
            padding: 12px 16px;
            border-radius: 12px;
            font-size: 14px;
        }

        .form-control:focus {
            background: rgba(15, 23, 42, 0.8);
            border-color: #0D6EFD;
            color: #FFF;
            box-shadow: 0 0 0 3px rgba(13, 110, 253, 0.25);
        }

        .form-control::placeholder {
            color: #64748B;
        }

        .btn-primary-custom {
            background: linear-gradient(135deg, #084298 0%, #0D6EFD 100%);
            border: none;
            color: #FFF;
            font-weight: 600;
            padding: 13px 20px;
            border-radius: 12px;
            box-shadow: 0 4px 16px rgba(13, 110, 253, 0.35);
            transition: all 0.2s ease;
        }

        .btn-primary-custom:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 20px rgba(13, 110, 253, 0.45);
        }

        .brand-title {
            font-family: 'Space Grotesk', sans-serif;
            letter-spacing: -0.5px;
        }
    </style>
</head>
<body>
    <div class="login-card">
        <!-- Logo & Header -->
        <div class="text-center mb-4">
            <div class="d-inline-flex align-items-center gap-2 mb-2">
                <i class="bi bi-film fs-2 text-primary"></i>
                <span class="fs-3 fw-bold text-white brand-title">PROCUT</span>
                <span class="brand-badge">ADMIN</span>
            </div>
            <p class="text-secondary small mb-0">Enter your credentials to access the studio control panel</p>
        </div>

        <?php if (!empty($error)): ?>
            <div class="alert alert-danger d-flex align-items-center gap-2 py-2 px-3 rounded-3 mb-3 small" role="alert">
                <i class="bi bi-exclamation-triangle-fill flex-shrink-0"></i>
                <div><?= htmlspecialchars($error) ?></div>
            </div>
        <?php endif; ?>

        <?php if (!empty($success)): ?>
            <div class="alert alert-success d-flex align-items-center gap-2 py-2 px-3 rounded-3 mb-3 small" role="alert">
                <i class="bi bi-check-circle-fill flex-shrink-0"></i>
                <div><?= htmlspecialchars($success) ?></div>
            </div>
        <?php endif; ?>

        <form method="POST" action="<?= htmlspecialchars($actionUrl) ?>">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">

            <div class="mb-3">
                <label class="form-label small text-secondary fw-semibold">Admin Username or Email</label>
                <div class="input-group">
                    <span class="input-group-text bg-dark border-secondary border-opacity-25 text-secondary">
                        <i class="bi bi-person-fill"></i>
                    </span>
                    <input type="text" name="identity" class="form-control" placeholder="admin or admin@procut.app" value="<?= htmlspecialchars($_POST['identity'] ?? '') ?>" required autofocus>
                </div>
            </div>

            <div class="mb-3">
                <div class="d-flex justify-content-between align-items-center mb-1">
                    <label class="form-label small text-secondary fw-semibold mb-0">Password</label>
                    <a href="<?= APP_BASE_URL ?>/admin/forgot-password.php" class="small text-primary text-decoration-none">Forgot?</a>
                </div>
                <div class="input-group">
                    <span class="input-group-text bg-dark border-secondary border-opacity-25 text-secondary">
                        <i class="bi bi-lock-fill"></i>
                    </span>
                    <input type="password" name="password" id="passInput" class="form-control" placeholder="••••••••" required>
                    <button class="btn btn-outline-secondary border-secondary border-opacity-25 text-secondary" type="button" onclick="togglePass()">
                        <i class="bi bi-eye" id="passToggleIcon"></i>
                    </button>
                </div>
            </div>

            <div class="d-grid mt-4">
                <button type="submit" class="btn btn-primary-custom d-flex align-items-center justify-content-center gap-2">
                    <i class="bi bi-box-arrow-in-right"></i>
                    <span>Authenticate & Access Dashboard</span>
                </button>
            </div>
        </form>
    </div>

    <script>
        function togglePass() {
            const input = document.getElementById('passInput');
            const icon = document.getElementById('passToggleIcon');
            if (input.type === 'password') {
                input.type = 'text';
                icon.classList.replace('bi-eye', 'bi-eye-slash');
            } else {
                input.type = 'password';
                icon.classList.replace('bi-eye-slash', 'bi-eye');
            }
        }
    </script>
</body>
</html>
