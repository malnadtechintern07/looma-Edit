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
$newPassword = $data['newPassword'] ?? $data['password'] ?? '';

if (empty($email) || empty($newPassword)) {
    Response::error('Email and new password are required.', 400);
}

if (strlen($newPassword) < 6) {
    Response::error('New password must be at least 6 characters.', 400);
}

$user = Database::fetchOne("SELECT * FROM users WHERE LOWER(email) = ?", [$email]);
if (!$user) {
    Response::error('No account found with this email address.', 404);
}

$newHash = Auth::hashPassword($newPassword);
$newSalt = Auth::generateSalt();

Database::query(
    "UPDATE users SET password_hash = ?, salt = ?, updated_at = NOW() WHERE id = ?",
    [$newHash, $newSalt, $user['id']]
);

// Invalidate existing sessions for security
Database::query("DELETE FROM sessions WHERE user_id = ?", [$user['id']]);

Auth::logActivity('user', $user['id'], $user['display_name'], 'password_reset', 'User reset account password');

Response::success([
    'message' => 'Password reset successfully. You can now log in with your new password.'
]);
