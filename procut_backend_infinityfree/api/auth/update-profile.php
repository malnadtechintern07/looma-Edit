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
$displayName = trim($payload['displayName'] ?? $payload['display_name'] ?? '');
$bio = trim($payload['bio'] ?? '');
$handle = trim($payload['handle'] ?? '');
$avatarUrl = trim($payload['avatarUrl'] ?? $payload['avatar_url'] ?? '');

if (empty($userId) && empty($email)) {
    Response::error('User ID or email is required', 400);
}

$user = !empty($userId) 
    ? Database::fetchOne("SELECT * FROM users WHERE id = ?", [$userId])
    : Database::fetchOne("SELECT * FROM users WHERE LOWER(email) = ?", [$email]);

if (!$user) {
    Response::error('User not found', 404);
}

$updates = [];
$params = [];

if (!empty($displayName)) {
    $updates[] = "display_name = ?";
    $params[] = $displayName;
}
if (!empty($bio)) {
    $updates[] = "bio = ?";
    $params[] = $bio;
}
if (!empty($handle)) {
    $updates[] = "handle = ?";
    $params[] = $handle;
}
if (!empty($avatarUrl)) {
    $updates[] = "avatar_url = ?";
    $params[] = $avatarUrl;
}

if (!empty($updates)) {
    $updates[] = "updated_at = NOW()";
    $params[] = $user['id'];
    Database::query("UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?", $params);
    Auth::logActivity('user', $user['id'], $displayName ?: $user['display_name'], 'profile_updated', 'Profile info updated');
}

$updatedUser = Database::fetchOne("SELECT * FROM users WHERE id = ?", [$user['id']]);

Response::success([
    'user' => [
        'id'          => $updatedUser['id'],
        'email'       => $updatedUser['email'],
        'displayName' => $updatedUser['display_name'],
        'isPro'       => (bool)$updatedUser['is_pro'],
        'avatarUrl'   => $updatedUser['avatar_url'],
        'bio'         => $updatedUser['bio'],
        'handle'      => $updatedUser['handle'],
        'lastLoginAt' => $updatedUser['last_login_at']
    ],
    'id'          => $updatedUser['id'],
    'email'       => $updatedUser['email'],
    'displayName' => $updatedUser['display_name'],
    'isPro'       => (bool)$updatedUser['is_pro']
], 'Profile updated successfully');
