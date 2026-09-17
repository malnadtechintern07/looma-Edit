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

if (empty($email) || empty($password)) {
    Response::error('Email and password are required.', 400);
}

$user = Database::fetchOne("SELECT * FROM users WHERE LOWER(TRIM(email)) = ?", [$email]);
if (!$user) {
    Response::error('No account found with this email. Please create an account first.', 404);
}

if (($user['status'] ?? 'active') === 'banned') {
    Response::error('This account has been suspended by an administrator. Please contact support.', 403);
}

if (!Auth::verifyPassword($password, $user['password_hash'] ?? '', $user['salt'] ?? '')) {
    Response::error('Incorrect password. Please try again or tap Forgot password to reset.', 401);
}

// Seamlessly upgrade legacy sha256 hashes to bcrypt
if (!str_starts_with($user['password_hash'] ?? '', '$2y$') && !str_starts_with($user['password_hash'] ?? '', '$2a$')) {
    $newHash = Auth::hashPassword($password);
    Database::query("UPDATE users SET password_hash = ?, salt = '' WHERE id = ?", [$newHash, $user['id']]);
    $user['password_hash'] = $newHash;
    $user['salt'] = '';
}

// Issue session token
$token = Auth::createToken($user['id']);
Database::query("UPDATE users SET last_login_at = NOW() WHERE id = ?", [$user['id']]);
Auth::logActivity('user', $user['id'], $user['display_name'], 'user_login', 'User logged in successfully');

Response::success([
    'token'       => $token,
    'user'        => [
        'id'          => $user['id'],
        'email'       => $user['email'],
        'displayName' => $user['display_name'],
        'isPro'       => (bool)$user['is_pro'],
        'avatarUrl'   => $user['avatar_url'],
        'bio'         => $user['bio'],
        'handle'      => $user['handle'],
        'createdAt'   => $user['created_at'],
        'lastLoginAt' => date('Y-m-d H:i:s')
    ],
    // Backwards compatibility keys
    'id'          => $user['id'],
    'email'       => $user['email'],
    'displayName' => $user['display_name'],
    'isPro'       => (bool)$user['is_pro'],
    'passwordHash'=> $user['password_hash'],
    'salt'        => $user['salt']
], 'Login successful', 200);
