<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed. Use POST.', 405);
}

$data = Response::getJsonBody();
if (empty($data)) {
    $data = $_POST;
}

$email = strtolower(trim($data['email'] ?? ''));
$password = $data['password'] ?? '';
$displayName = trim($data['displayName'] ?? $data['display_name'] ?? $data['name'] ?? 'ProCut Creator');

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    Response::error('A valid email address is required.', 400);
}

if (strlen($password) < 6) {
    Response::error('Password must be at least 6 characters.', 400);
}

// Check if registration is allowed by app settings
$allowReg = Database::fetchOne("SELECT setting_value FROM app_settings WHERE setting_key = 'allow_user_registration'")['setting_value'] ?? '1';
if ($allowReg === '0') {
    Response::error('New user registration is currently disabled by administrator.', 403);
}

// Check for existing user
$existing = Database::fetchOne("SELECT * FROM users WHERE LOWER(TRIM(email)) = ?", [$email]);
if ($existing) {
    // If password matches existing, seamlessly log in
    if (Auth::verifyPassword($password, $existing['password_hash'] ?? '', $existing['salt'] ?? '')) {
        $token = Auth::createToken($existing['id']);
        Database::query("UPDATE users SET last_login_at = NOW() WHERE id = ?", [$existing['id']]);
        Auth::logActivity('user', $existing['id'], $existing['display_name'], 'user_login_via_register', 'User registered email matched existing account');

        Response::success([
            'token'       => $token,
            'user'        => [
                'id'          => $existing['id'],
                'email'       => $existing['email'],
                'displayName' => $existing['display_name'],
                'isPro'       => (bool)$existing['is_pro'],
                'avatarUrl'   => $existing['avatar_url'],
                'createdAt'   => $existing['created_at'],
                'lastLoginAt' => date('Y-m-d H:i:s')
            ],
            // Backwards compatibility keys for Flutter models
            'id'          => $existing['id'],
            'email'       => $existing['email'],
            'displayName' => $existing['display_name'],
            'isPro'       => (bool)$existing['is_pro'],
            'passwordHash'=> $existing['password_hash'],
            'salt'        => $existing['salt']
        ], 'Account logged in successfully', 200);
    } else {
        Response::error('An account with this email already exists. Please log in or reset your password.', 409);
    }
}

// Create new user
$userId = 'usr_' . substr(hash('sha256', $email . microtime()), 0, 16);
$pHash = Auth::hashPassword($password);
$salt = Auth::generateSalt();
$now = date('Y-m-d H:i:s');

Database::query(
    "INSERT INTO users (id, email, display_name, password_hash, salt, is_pro, created_at, updated_at, last_login_at)
     VALUES (?, ?, ?, ?, ?, 1, ?, ?, ?)",
    [$userId, $email, $displayName, $pHash, $salt, $now, $now, $now]
);

$token = Auth::createToken($userId);
Auth::logActivity('user', $userId, $displayName, 'user_registered', 'New user account registered');

Response::success([
    'token'       => $token,
    'user'        => [
        'id'          => $userId,
        'email'       => $email,
        'displayName' => $displayName,
        'isPro'       => true,
        'avatarUrl'   => null,
        'createdAt'   => $now,
        'lastLoginAt' => $now
    ],
    // Backwards compatibility keys
    'id'          => $userId,
    'email'       => $email,
    'displayName' => $displayName,
    'isPro'       => true,
    'passwordHash'=> $pHash,
    'salt'        => $salt
], 'Account created successfully', 201);
