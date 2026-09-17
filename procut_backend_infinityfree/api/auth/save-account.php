<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

$payload = Response::getJsonBody();
if (empty($payload)) {
    $payload = $_POST;
}

$userId = trim($payload['id'] ?? $payload['userId'] ?? '');
$email = strtolower(trim($payload['email'] ?? ''));
$name = trim($payload['displayName'] ?? $payload['display_name'] ?? $payload['name'] ?? 'ProCut Creator');
$hashVal = $payload['passwordHash'] ?? $payload['password_hash'] ?? '';
$saltVal = $payload['salt'] ?? '';

if (empty($email)) {
    Response::error('Email is required', 400);
}

$existing = Database::fetchOne("SELECT id FROM users WHERE LOWER(TRIM(email)) = ?", [$email]);
if ($existing) {
    $userId = $existing['id'];
} elseif (empty($userId)) {
    $userId = 'usr_' . substr(hash('sha256', $email . microtime()), 0, 16);
}

if (!empty($payload['password'])) {
    $hashVal = Auth::hashPassword($payload['password']);
    $saltVal = '';
} elseif (empty($hashVal) && !empty($payload['passwordHash'])) {
    $hashVal = $payload['passwordHash'];
}

$isPro = !empty($payload['isPro']) || !empty($payload['is_pro']) ? 1 : 0;
$now = date('Y-m-d H:i:s');

Database::query(
    "INSERT INTO users (id, email, display_name, password_hash, salt, is_pro, created_at, updated_at, last_login_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
        display_name = VALUES(display_name),
        password_hash = IF(VALUES(password_hash) != '', VALUES(password_hash), password_hash),
        salt = IF(VALUES(salt) != '', VALUES(salt), salt),
        is_pro = VALUES(is_pro),
        last_login_at = VALUES(last_login_at)",
    [$userId, $email, $name, $hashVal, $saltVal, $isPro, $now, $now, $now]
);

Response::success([
    'user' => [
        'id'          => $userId,
        'email'       => $email,
        'displayName' => $name,
        'isPro'       => (bool)$isPro
    ]
], 'User account persisted successfully');
