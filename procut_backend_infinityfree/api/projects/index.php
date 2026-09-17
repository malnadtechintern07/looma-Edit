<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

$method = $_SERVER['REQUEST_METHOD'];

// Handle DELETE /api/projects/{id}
if ($method === 'DELETE') {
    require_once __DIR__ . '/delete.php';
    exit;
}

if ($method !== 'GET') {
    Response::error('Method not allowed. Use GET.', 405);
}

// User identification
$userId = trim($_GET['userId'] ?? $_GET['user_id'] ?? '');
$userEmail = strtolower(trim($_GET['userEmail'] ?? $_GET['user_email'] ?? ''));

// If token provided, authenticate via token
$tokenUser = Auth::authenticateApiUser();
if ($tokenUser) {
    $userId = $tokenUser['user_id'];
    $userEmail = $tokenUser['email'];
}

if (empty($userId) && empty($userEmail)) {
    Response::error('userId or userEmail parameter is required to access cloud projects.', 400);
}

// Strict user isolation query
if (!empty($userId)) {
    $rows = Database::fetchAll(
        "SELECT id, user_id, user_email, title, aspect_ratio, duration_ms, fps, thumbnail_url, project_json, created_at, updated_at
         FROM projects
         WHERE user_id = ? OR (user_email != '' AND LOWER(TRIM(user_email)) = ?)
         ORDER BY updated_at DESC",
        [$userId, $userEmail]
    );
} else {
    $rows = Database::fetchAll(
        "SELECT id, user_id, user_email, title, aspect_ratio, duration_ms, fps, thumbnail_url, project_json, created_at, updated_at
         FROM projects
         WHERE LOWER(TRIM(user_email)) = ?
         ORDER BY updated_at DESC",
        [$userEmail]
    );
}

$projects = [];
foreach ($rows as $r) {
    $decoded = json_decode($r['project_json'], true);
    if (is_array($decoded)) {
        // Ensure consistency with top-level fields
        $decoded['id'] = $r['id'];
        $decoded['userId'] = $r['user_id'];
        $decoded['userEmail'] = $r['user_email'];
        $decoded['title'] = $r['title'];
        $decoded['aspectRatio'] = $r['aspect_ratio'];
        $decoded['durationMs'] = (int)$r['duration_ms'];
        $decoded['fps'] = (int)$r['fps'];
        if (!empty($r['thumbnail_url'])) {
            $decoded['thumbnailUrl'] = $r['thumbnail_url'];
        }
        $decoded['createdAt'] = $r['created_at'];
        $decoded['updatedAt'] = $r['updated_at'];
        $decoded['syncStatus'] = 'synced';
        $projects[] = $decoded;
    }
}

Response::success([
    'count'    => count($projects),
    'projects' => $projects
]);
