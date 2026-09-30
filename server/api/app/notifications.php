<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

// Ensure notifications table exists
try {
    Database::query("
        CREATE TABLE IF NOT EXISTS notifications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            message TEXT NOT NULL,
            type VARCHAR(50) NOT NULL DEFAULT 'info',
            target_user_id VARCHAR(64) NULL,
            is_active TINYINT(1) DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_notif_target (target_user_id),
            INDEX idx_notif_active (is_active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
} catch (\Throwable $e) {}

$userId = trim($_GET['userId'] ?? $_GET['user_id'] ?? '');
if (empty($userId)) {
    $headers = function_exists('getallheaders') ? getallheaders() : [];
    $userId = trim($headers['X-User-Id'] ?? $headers['x-user-id'] ?? $_SERVER['HTTP_X_USER_ID'] ?? '');
}

$tokenUser = Auth::authenticateApiUser();
if ($tokenUser && !empty($tokenUser['user_id'])) {
    $userId = $tokenUser['user_id'];
}

// Robust SQL query:
// Returns all global broadcasts (target_user_id is NULL, empty string, 'all', 'global')
// PLUS any notification specifically targeted to this user ID!
if (!empty($userId)) {
    $notifications = Database::fetchAll(
        "SELECT id, title, message, type, target_user_id, created_at
         FROM notifications
         WHERE is_active = 1 AND (
             target_user_id IS NULL 
             OR target_user_id = '' 
             OR target_user_id = 'all' 
             OR target_user_id = 'global' 
             OR target_user_id = ?
         )
         ORDER BY created_at DESC
         LIMIT 50",
        [$userId]
    );
} else {
    $notifications = Database::fetchAll(
        "SELECT id, title, message, type, target_user_id, created_at
         FROM notifications
         WHERE is_active = 1 AND (
             target_user_id IS NULL 
             OR target_user_id = '' 
             OR target_user_id = 'all' 
             OR target_user_id = 'global'
         )
         ORDER BY created_at DESC
         LIMIT 50"
    );
}

Response::success([
    'count'         => count($notifications),
    'notifications' => $notifications
]);

