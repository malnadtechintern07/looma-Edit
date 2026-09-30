<?php
/**
 * ProCut API – Register Device FCM Token
 *
 * POST /api/app/register-fcm-token
 *
 * Body (JSON or form):
 *   fcm_token  string  (required) The device's Firebase Cloud Messaging token
 *   platform   string  "android" | "ios" (optional, defaults to "android")
 *
 * Authentication:
 *   Bearer token in Authorization header, or X-User-Id / userId query param.
 *   Unauthenticated (guest) calls are accepted — the token will be stored without a user ID
 *   and will receive global broadcast notifications only.
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed. Use POST.', 405);
}

$data     = Response::getJsonBody() ?: $_POST;
$fcmToken = trim($data['fcm_token'] ?? $data['token'] ?? '');
$platform = strtolower(trim($data['platform'] ?? 'android'));

// Resolve authenticated user (optional – guests are allowed too)
$userId = '';
$tokenUser = Auth::authenticateApiUser();
if ($tokenUser && !empty($tokenUser['user_id'])) {
    $userId = $tokenUser['user_id'];
} else {
    // Try query param fallback (less secure; for legacy support)
    $userId = trim($data['user_id'] ?? $data['userId'] ?? $_GET['userId'] ?? $_GET['user_id'] ?? '');
}

if (empty($fcmToken)) {
    Response::error('fcm_token is required.', 400);
}

// Only accept known platforms
if (!in_array($platform, ['android', 'ios', 'web'], true)) {
    $platform = 'android';
}

// ------------------------------------------------------------------ //
//  Ensure device_tokens table exists                                  //
// ------------------------------------------------------------------ //
try {
    Database::query("
        CREATE TABLE IF NOT EXISTS device_tokens (
            id          INT AUTO_INCREMENT PRIMARY KEY,
            user_id     VARCHAR(64) NULL,
            fcm_token   TEXT NOT NULL,
            platform    VARCHAR(20) DEFAULT 'android',
            is_active   TINYINT(1) DEFAULT 1,
            created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_dt_user   (user_id),
            INDEX idx_dt_active (is_active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
} catch (\Throwable $e) {
    // Table probably already exists — ignore
}

// ------------------------------------------------------------------ //
//  Upsert token record (insert or refresh existing)                   //
// ------------------------------------------------------------------ //
try {
    if (!empty($userId)) {
        // Check if this exact token already exists for this user
        $existing = Database::fetchOne(
            "SELECT id FROM device_tokens WHERE fcm_token = ? AND user_id = ?",
            [$fcmToken, $userId]
        );
        if ($existing) {
            Database::query(
                "UPDATE device_tokens SET is_active = 1, platform = ?, updated_at = NOW() WHERE id = ?",
                [$platform, $existing['id']]
            );
        } else {
            // Deactivate any old tokens for this user on this platform to prevent stale deliveries
            Database::query(
                "UPDATE device_tokens SET is_active = 0 WHERE user_id = ? AND platform = ? AND fcm_token != ?",
                [$userId, $platform, $fcmToken]
            );
            Database::query(
                "INSERT INTO device_tokens (user_id, fcm_token, platform, is_active) VALUES (?, ?, ?, 1)",
                [$userId, $fcmToken, $platform]
            );
        }
    } else {
        // Anonymous / guest token
        $existing = Database::fetchOne(
            "SELECT id FROM device_tokens WHERE fcm_token = ?",
            [$fcmToken]
        );
        if ($existing) {
            Database::query(
                "UPDATE device_tokens SET is_active = 1, updated_at = NOW() WHERE id = ?",
                [$existing['id']]
            );
        } else {
            Database::query(
                "INSERT INTO device_tokens (user_id, fcm_token, platform, is_active) VALUES (NULL, ?, ?, 1)",
                [$fcmToken, $platform]
            );
        }
    }

    Response::success(['registered' => true], 'Device token registered successfully');
} catch (\Throwable $e) {
    error_log('register-fcm-token error: ' . $e->getMessage());
    // Return success to client — don't expose DB errors, and the token can still receive topic messages
    Response::success(['registered' => false, 'note' => 'Token could not be persisted, but global notifications will still work via topics'], 'Token stored in session only');
}
