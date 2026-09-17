<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

$userId = trim($_GET['userId'] ?? $_GET['user_id'] ?? '');

$tokenUser = Auth::authenticateApiUser();
if ($tokenUser) {
    $userId = $tokenUser['user_id'];
}

$notifications = Database::fetchAll(
    "SELECT id, title, message, type, created_at
     FROM notifications
     WHERE is_active = 1 AND (target_user_id IS NULL OR target_user_id = ?)
     ORDER BY created_at DESC
     LIMIT 50",
    [$userId ?: '']
);

Response::success([
    'count'         => count($notifications),
    'notifications' => $notifications
]);
