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

try {
    // 0. Auto-migrate / ensure projects table schema exists
    try {
        Database::query("
            CREATE TABLE IF NOT EXISTS projects (
                id VARCHAR(64) PRIMARY KEY,
                user_id VARCHAR(64) NOT NULL,
                user_email VARCHAR(255) NOT NULL,
                title VARCHAR(255) NOT NULL,
                aspect_ratio VARCHAR(32) DEFAULT 'ratio9_16',
                duration_ms INT DEFAULT 0,
                fps INT DEFAULT 30,
                thumbnail_url VARCHAR(500) NULL,
                project_json LONGTEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_proj_user_id (user_id),
                INDEX idx_proj_user_email (user_email)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");
    } catch (Throwable $e) {}

    try {
        Database::query("ALTER TABLE projects ADD COLUMN thumbnail_url VARCHAR(500) NULL AFTER fps");
    } catch (Throwable $e) {}

    // User identification
    $userId = trim($_GET['userId'] ?? $_GET['user_id'] ?? '');
    $userEmail = strtolower(trim($_GET['userEmail'] ?? $_GET['user_email'] ?? ''));

    // If token provided, authenticate via token
    $tokenUser = Auth::authenticateApiUser();
    if ($tokenUser) {
        $userId = $tokenUser['user_id'];
        $userEmail = strtolower($tokenUser['email']);
    }

    if (empty($userId) && empty($userEmail)) {
        Response::error('userId or userEmail parameter is required to access cloud projects.', 400);
    }

    // Resolve user ID / email from users table if possible
    if (!empty($userEmail)) {
        $u = Database::fetchOne("SELECT id FROM users WHERE LOWER(email) = ?", [$userEmail]);
        if ($u && !empty($u['id'])) {
            $dbUid = $u['id'];
            if (empty($userId)) {
                $userId = $dbUid;
            }
        }
    } elseif (!empty($userId)) {
        $u = Database::fetchOne("SELECT email FROM users WHERE id = ?", [$userId]);
        if ($u && !empty($u['email'])) {
            $userEmail = strtolower($u['email']);
        }
    }

    // Strict user isolation query matching email OR userId
    $query = "SELECT * FROM projects WHERE ";
    $params = [];

    if (!empty($userId) && !empty($userEmail)) {
        $query .= "(user_id = ? OR (user_email != '' AND LOWER(TRIM(user_email)) = ?))";
        $params = [$userId, $userEmail];
    } elseif (!empty($userEmail)) {
        $query .= "(user_email != '' AND LOWER(TRIM(user_email)) = ?)";
        $params = [$userEmail];
    } else {
        $query .= "user_id = ?";
        $params = [$userId];
    }

    $query .= " ORDER BY updated_at DESC";
    $rows = Database::fetchAll($query, $params);

    $projects = [];
    foreach ($rows as $r) {
        $decoded = json_decode($r['project_json'], true);
        if (!is_array($decoded)) {
            $decoded = [
                'id' => $r['id'],
                'title' => $r['title'] ?? 'Untitled Project',
                'aspectRatio' => $r['aspect_ratio'] ?? 'ratio9_16',
                'durationMs' => (int)($r['duration_ms'] ?? 0),
                'fps' => (int)($r['fps'] ?? 30),
                'tracks' => [],
            ];
        }

        // Ensure consistency with top-level fields
        $decoded['id'] = $r['id'];
        $decoded['userId'] = $r['user_id'] ?? $userId;
        $decoded['userEmail'] = !empty($r['user_email']) ? $r['user_email'] : $userEmail;
        $decoded['title'] = $r['title'] ?? $decoded['title'] ?? 'Untitled';
        $decoded['aspectRatio'] = $r['aspect_ratio'] ?? $decoded['aspectRatio'] ?? 'ratio9_16';
        $decoded['durationMs'] = (int)($r['duration_ms'] ?? $decoded['durationMs'] ?? 0);
        $decoded['fps'] = (int)($r['fps'] ?? $decoded['fps'] ?? 30);
        if (!empty($r['thumbnail_url'])) {
            $decoded['thumbnailUrl'] = $r['thumbnail_url'];
        }
        $decoded['createdAt'] = $r['created_at'] ?? $decoded['createdAt'] ?? date('Y-m-d H:i:s');
        $decoded['updatedAt'] = $r['updated_at'] ?? $decoded['updatedAt'] ?? date('Y-m-d H:i:s');
        $decoded['syncStatus'] = 'synced';
        $projects[] = $decoded;
    }

    Response::success([
        'count'    => count($projects),
        'projects' => $projects
    ]);
} catch (Throwable $e) {
    Response::error('Failed to retrieve cloud projects: ' . $e->getMessage(), 500);
}
