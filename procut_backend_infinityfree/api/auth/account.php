<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

$email = strtolower(trim($_GET['email'] ?? ''));
$userId = trim($_GET['id'] ?? $_GET['userId'] ?? '');

if (empty($email) && empty($userId)) {
    Response::error('Email or user ID parameter is required.', 400);
}

if (!empty($email)) {
    $user = Database::fetchOne("SELECT * FROM users WHERE LOWER(email) = ?", [$email]);
} else {
    $user = Database::fetchOne("SELECT * FROM users WHERE id = ?", [$userId]);
}

if (!$user) {
    Response::error('User not found', 404);
}

Response::json(200, [
    'id'          => $user['id'],
    'email'       => $user['email'],
    'displayName' => $user['display_name'],
    'isPro'       => (bool)$user['is_pro'],
    'avatarUrl'   => $user['avatar_url'],
    'bio'         => $user['bio'],
    'handle'      => $user['handle'],
    'passwordHash'=> $user['password_hash'],
    'salt'        => $user['salt'],
    'createdAt'   => $user['created_at'],
    'lastLoginAt' => $user['last_login_at']
]);
