<?php
/**
 * ProCut Authentication, Token & Security Helper
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';

class Auth {
    // Password Hashing
    public static function hashPassword(string $password): string {
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    }

    public static function verifyPassword(string $password, string $expectedHash, string $salt = ''): bool {
        // 1. Try standard bcrypt password_verify
        if (password_verify($password, $expectedHash)) {
            return true;
        }

        // 2. Fallback to legacy SHA256 1000-round hash if salt exists
        if (!empty($salt)) {
            $calc = self::legacyHashPassword($password, $salt);
            if (hash_equals($calc, $expectedHash)) {
                return true;
            }
        }

        return false;
    }

    public static function legacyHashPassword(string $password, string $salt): string {
        $current = "{$password}::{$salt}";
        for ($i = 0; $i < 1000; $i++) {
            $current = hash('sha256', $current, true);
        }
        return rtrim(strtr(base64_encode($current), '+/', '-_'), '=');
    }

    public static function generateSalt(): string {
        return rtrim(strtr(base64_encode(random_bytes(16)), '+/', '-_'), '=');
    }

    // Admin Session Management
    public static function startSession(): void {
        if (session_status() === PHP_SESSION_NONE) {
            // Local Mac XAMPP temp dir support (only if running on macOS without open_basedir restrictions)
            if (PHP_OS_FAMILY === 'Darwin' && empty(ini_get('open_basedir'))) {
                $macXamppTemp = '/Applications/XAMPP/xamppfiles/temp';
                if (@is_dir($macXamppTemp) && @is_writable($macXamppTemp)) {
                    @session_save_path($macXamppTemp);
                }
            }

            if (PHP_VERSION_ID >= 70300) {
                @session_set_cookie_params([
                    'lifetime' => 86400 * 7,    // 7 days cookie lifetime
                    'path'     => '/',
                    'httponly' => true,
                    'secure'   => false,        // Allow HTTP for free hosting / dev
                    'samesite' => 'Lax'
                ]);
            } else {
                @session_set_cookie_params(86400 * 7, '/', '', false, true);
            }
            @session_start();
        }

        // Check for inactivity timeout (server-side, 30 minutes)
        if (isset($_SESSION[ADMIN_SESSION_KEY])) {
            if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity'] > SESSION_LIFETIME)) {
                $expiredAdmin = $_SESSION[ADMIN_SESSION_KEY];
                self::logoutAdmin();
                try {
                    self::logActivity('admin', (string)($expiredAdmin['id'] ?? 0), $expiredAdmin['name'] ?? 'Admin', 'admin_timeout', 'Admin session timed out');
                } catch (\Throwable $e) {}

                $script = basename($_SERVER['SCRIPT_NAME'] ?? '');
                if ($script !== 'login.php') {
                    header('Location: ' . APP_BASE_URL . '/admin/login.php?error=session_timeout');
                    exit;
                }
                return;
            }
            $_SESSION['last_activity'] = time();
        }
    }

    public static function loginAdmin(array $admin): void {
        if (session_status() === PHP_SESSION_NONE) {
            self::startSession();
        }
        if (function_exists('session_regenerate_id')) {
            @session_regenerate_id(false);
        }

        $_SESSION[ADMIN_SESSION_KEY] = [
            'id'           => $admin['id'],
            'username'     => $admin['username'],
            'email'        => $admin['email'],
            'name'         => $admin['name'],
            'role'         => $admin['role'],
            'avatar'       => $admin['avatar'] ?? null,
            'logged_in_at' => time()
        ];
        $_SESSION['last_activity'] = time();

        // Persistent database session token (guarantees session recovery if PHP file session is lost)
        try {
            $token = self::createToken('', (int)$admin['id'], 'admin');
            if (PHP_VERSION_ID >= 70300) {
                @setcookie('procut_admin_token', $token, [
                    'expires'  => time() + (86400 * 30),
                    'path'     => '/',
                    'httponly' => true,
                    'secure'   => false,
                    'samesite' => 'Lax'
                ]);
            } else {
                @setcookie('procut_admin_token', $token, time() + (86400 * 30), '/', '', false, true);
            }
        } catch (\Throwable $e) {}

        // Update admin last login in database
        try {
            Database::query("UPDATE admins SET last_login_at = NOW() WHERE id = ?", [$admin['id']]);
        } catch (\Throwable $e) {}

        // Log activity
        try {
            self::logActivity('admin', (string)$admin['id'], $admin['name'], 'admin_login', 'Admin logged in successfully');
        } catch (\Throwable $e) {}

        // Ensure session data is saved before any HTTP redirect occurs
        session_write_close();
    }

    public static function logoutAdmin(): void {
        if (session_status() === PHP_SESSION_NONE) {
            self::startSession();
        }
        if (isset($_SESSION[ADMIN_SESSION_KEY])) {
            $admin = $_SESSION[ADMIN_SESSION_KEY];
            try {
                self::logActivity('admin', (string)$admin['id'], $admin['name'], 'admin_logout', 'Admin logged out');
            } catch (\Throwable $e) {}
        }

        // Revoke persistent database token
        if (!empty($_COOKIE['procut_admin_token'])) {
            try {
                self::revokeToken($_COOKIE['procut_admin_token']);
            } catch (\Throwable $e) {}
            setcookie('procut_admin_token', '', time() - 86400, '/');
            unset($_COOKIE['procut_admin_token']);
        }

        $_SESSION = [];
        if (ini_get("session.use_cookies")) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000,
                $params["path"], $params["domain"],
                $params["secure"], $params["httponly"]
            );
        }
        if (session_status() === PHP_SESSION_ACTIVE) {
            @session_destroy();
        }
    }

    public static function getAdmin(): ?array {
        if (session_status() === PHP_SESSION_NONE) {
            self::startSession();
        }
        if (!empty($_SESSION[ADMIN_SESSION_KEY])) {
            return $_SESSION[ADMIN_SESSION_KEY];
        }

        // Persistent database token fallback (guarantees session recovery if PHP file session was lost)
        if (!empty($_COOKIE['procut_admin_token'])) {
            try {
                $tokenHash = hash('sha256', trim($_COOKIE['procut_admin_token']));
                $row = Database::fetchOne(
                    "SELECT s.*, a.id as admin_id, a.username, a.email, a.name, a.role, a.avatar, a.status
                     FROM sessions s
                     JOIN admins a ON s.admin_id = a.id
                     WHERE s.token_hash = ? AND s.expires_at > NOW() AND s.token_type = 'admin' AND a.status = 'active'
                     LIMIT 1",
                    [$tokenHash]
                );
                if ($row) {
                    $adminData = [
                        'id'           => $row['admin_id'],
                        'username'     => $row['username'],
                        'email'        => $row['email'],
                        'name'         => $row['name'],
                        'role'         => $row['role'],
                        'avatar'       => $row['avatar'] ?? null,
                        'logged_in_at' => time()
                    ];
                    $_SESSION[ADMIN_SESSION_KEY] = $adminData;
                    $_SESSION['last_activity'] = time();
                    return $adminData;
                }
            } catch (\Throwable $e) {}
        }

        return null;
    }

    public static function isAdminAuthenticated(): bool {
        return self::getAdmin() !== null;
    }

    public static function requireAdmin(): array {
        $admin = self::getAdmin();
        if (!$admin) {
            header('Location: ' . APP_BASE_URL . '/admin/login.php?error=unauthorized');
            exit;
        }
        return $admin;
    }

    public static function requireRole(string $role): void {
        $admin = self::requireAdmin();
        if ($admin['role'] !== 'superadmin' && $admin['role'] !== $role) {
            header('Location: ' . APP_BASE_URL . '/admin/dashboard.php?error=forbidden');
            exit;
        }
    }

    // CSRF Protection
    public static function getCsrfToken(): string {
        if (session_status() === PHP_SESSION_NONE) {
            self::startSession();
        }
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }

    public static function validateCsrfToken(?string $token): bool {
        if (session_status() === PHP_SESSION_NONE) {
            self::startSession();
        }
        if (empty($_SESSION['csrf_token']) || empty($token)) {
            return false;
        }
        return hash_equals($_SESSION['csrf_token'], $token);
    }

    // Token Management for Mobile App API
    public static function createToken(string $userId, ?int $adminId = null, string $type = 'user'): string {
        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);
        $expiresAt = date('Y-m-d H:i:s', time() + (TOKEN_LIFETIME_DAYS * 86400));
        $id = 'tok_' . bin2hex(random_bytes(16));

        Database::query(
            "INSERT INTO sessions (id, user_id, admin_id, token_hash, token_type, ip_address, user_agent, expires_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [
                $id,
                $userId ?: null,
                $adminId ?: null,
                $tokenHash,
                $type,
                self::getClientIp(),
                self::getUserAgent(),
                $expiresAt
            ]
        );

        return $token;
    }

    public static function authenticateApiUser(): ?array {
        $authHeader = '';
        if (function_exists('getallheaders')) {
            $headers = getallheaders();
            $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        }
        if (empty($authHeader)) {
            $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
        }
        $token = '';

        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = trim($matches[1]);
        } elseif (!empty($_REQUEST['token'])) {
            $token = trim($_REQUEST['token']);
        }

        if (empty($token)) {
            return null;
        }

        $tokenHash = hash('sha256', $token);
        $session = Database::fetchOne(
            "SELECT s.*, u.id as user_id, u.email, u.display_name, u.is_pro, u.status
             FROM sessions s
             JOIN users u ON s.user_id = u.id
             WHERE s.token_hash = ? AND s.expires_at > NOW() AND s.token_type = 'user'
             LIMIT 1",
            [$tokenHash]
        );

        if ($session && $session['status'] !== 'banned') {
            return $session;
        }

        return null;
    }

    public static function revokeToken(string $token): bool {
        $tokenHash = hash('sha256', $token);
        return Database::execute("DELETE FROM sessions WHERE token_hash = ?", [$tokenHash]);
    }

    // Activity Logging
    public static function logActivity(string $actorType, string $actorId, string $actorName, string $action, ?string $details = null): void {
        try {
            Database::query(
                "INSERT INTO activity_logs (actor_type, actor_id, actor_name, action, details, ip_address, user_agent)
                 VALUES (?, ?, ?, ?, ?, ?, ?)",
                [
                    $actorType,
                    $actorId,
                    $actorName,
                    $action,
                    $details,
                    self::getClientIp(),
                    self::getUserAgent()
                ]
            );
        } catch (Exception $e) {
            // Silently handle log errors to avoid blocking core operations
        }
    }

    public static function getClientIp(): string {
        return $_SERVER['HTTP_CF_CONNECTING_IP'] 
            ?? $_SERVER['HTTP_X_FORWARDED_FOR'] 
            ?? $_SERVER['REMOTE_ADDR'] 
            ?? '127.0.0.1';
    }

    public static function getUserAgent(): string {
        return substr($_SERVER['HTTP_USER_AGENT'] ?? 'Unknown', 0, 500);
    }
}
