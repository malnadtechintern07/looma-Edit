<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed. Use POST.', 405);
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

    $payload = Response::getJsonBody();
    if (empty($payload)) {
        $payload = $_POST;
    }

    $project = $payload['project'] ?? $payload;
    if (!is_array($project) || empty($project['id'])) {
        Response::error('Valid project payload with id is required.', 400);
    }

    $pid = trim($project['id']);
    $uid = trim($payload['userId'] ?? $project['userId'] ?? $project['user_id'] ?? '');
    $uemail = strtolower(trim($payload['userEmail'] ?? $project['userEmail'] ?? $project['user_email'] ?? ''));

    // If token provided, authenticate via token
    $tokenUser = Auth::authenticateApiUser();
    if ($tokenUser) {
        $uid = $tokenUser['user_id'];
        $uemail = strtolower($tokenUser['email']);
    }

    if (empty($uid) && empty($uemail)) {
        Response::error('userId or userEmail is required to link cloud project.', 400);
    }

    // Resolve user from DB if only one of ID/Email is passed, or ensure ID matches email in DB
    if (!empty($uemail)) {
        $u = Database::fetchOne("SELECT id, email FROM users WHERE LOWER(email) = ?", [$uemail]);
        if ($u) {
            $uid = $u['id'];
        } else if (!empty($uid)) {
            // User registered offline: ensure user stub exists in users table so foreign keys don't fail
            try {
                $userExists = Database::fetchOne("SELECT id FROM users WHERE id = ?", [$uid]);
                if (!$userExists) {
                    $now = date('Y-m-d H:i:s');
                    Database::query(
                        "INSERT INTO users (id, email, display_name, password_hash, salt, is_pro, created_at, updated_at, last_login_at)
                         VALUES (?, ?, ?, '', '', 1, ?, ?, ?)",
                        [$uid, $uemail, 'ProCut Creator', $now, $now, $now]
                    );
                }
            } catch (Throwable $e) {}
        }
    } elseif (!empty($uid)) {
        $u = Database::fetchOne("SELECT email FROM users WHERE id = ?", [$uid]);
        if ($u && !empty($u['email'])) {
            $uemail = strtolower($u['email']);
        }
    }

    // Verify ownership if project already exists (Prevent overwriting another user's project)
    $existing = Database::fetchOne("SELECT user_id, user_email FROM projects WHERE id = ?", [$pid]);
    if ($existing) {
        $ownerUid = $existing['user_id'] ?? '';
        $ownerEmail = strtolower($existing['user_email'] ?? '');
        $isOwner = (!empty($uid) && $ownerUid === $uid) ||
                   (!empty($uemail) && !empty($ownerEmail) && $ownerEmail === $uemail);
        if (!$isOwner) {
            Response::error('Unauthorized: You do not have permission to modify this project.', 403);
        }
    }

    $title = trim($project['title'] ?? 'Untitled Project');
    $aspectRatio = $project['aspectRatio'] ?? 'ratio9_16';
    $durationMs = (int)($project['durationMs'] ?? 0);
    $fps = (int)($project['fps'] ?? 30);
    $thumbUrl = $project['thumbnailUrl'] ?? $project['thumbnail_url'] ?? null;
    $now = date('Y-m-d H:i:s');
    $createdAt = $project['createdAt'] ?? $now;

    // Ensure embedded project JSON has correct owner details
    $project['userId'] = $uid;
    $project['userEmail'] = $uemail;
    $project['updatedAt'] = $now;
    $jsonStr = json_encode($project, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

    // Defensive insert: check if thumbnail_url column is present in table
    try {
        Database::query(
            "INSERT INTO projects (id, user_id, user_email, title, aspect_ratio, duration_ms, fps, thumbnail_url, project_json, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                user_id = VALUES(user_id),
                user_email = VALUES(user_email),
                title = VALUES(title),
                aspect_ratio = VALUES(aspect_ratio),
                duration_ms = VALUES(duration_ms),
                fps = VALUES(fps),
                thumbnail_url = IF(VALUES(thumbnail_url) IS NOT NULL, VALUES(thumbnail_url), thumbnail_url),
                project_json = VALUES(project_json),
                updated_at = VALUES(updated_at)",
            [$pid, $uid, $uemail, $title, $aspectRatio, $durationMs, $fps, $thumbUrl, $jsonStr, $createdAt, $now]
        );
    } catch (Throwable $e) {
        // Fallback without thumbnail_url column if older schema
        Database::query(
            "INSERT INTO projects (id, user_id, user_email, title, aspect_ratio, duration_ms, fps, project_json, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                user_id = VALUES(user_id),
                user_email = VALUES(user_email),
                title = VALUES(title),
                aspect_ratio = VALUES(aspect_ratio),
                duration_ms = VALUES(duration_ms),
                fps = VALUES(fps),
                project_json = VALUES(project_json),
                updated_at = VALUES(updated_at)",
            [$pid, $uid, $uemail, $title, $aspectRatio, $durationMs, $fps, $jsonStr, $createdAt, $now]
        );
    }

    try {
        Auth::logActivity('user', $uid, $uemail, 'project_synced', "Backed up project: {$title} ({$pid})");
    } catch (Throwable $e) {}

    Response::success([
        'projectId' => $pid,
        'savedAt'   => $now,
        'syncStatus'=> 'synced'
    ], 'Project backed up successfully');

} catch (Throwable $e) {
    Response::error('Failed to backup project: ' . $e->getMessage(), 500);
}
