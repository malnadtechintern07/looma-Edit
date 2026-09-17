<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed. Use POST.', 405);
}

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
    $uemail = $tokenUser['email'];
}

if (empty($uid) && empty($uemail)) {
    Response::error('userId or userEmail is required to link cloud project.', 400);
}

// Resolve user from DB if only one of ID/Email is passed
if (empty($uid) && !empty($uemail)) {
    $u = Database::fetchOne("SELECT id FROM users WHERE LOWER(email) = ?", [$uemail]);
    if ($u) $uid = $u['id'];
} elseif (!empty($uid) && empty($uemail)) {
    $u = Database::fetchOne("SELECT email FROM users WHERE id = ?", [$uid]);
    if ($u) $uemail = $u['email'];
}

// Verify ownership if project already exists (Prevent overwriting another user's project)
$existing = Database::fetchOne("SELECT user_id, user_email FROM projects WHERE id = ?", [$pid]);
if ($existing) {
    if ($existing['user_id'] !== $uid && strtolower($existing['user_email']) !== $uemail) {
        Response::error('Unauthorized: You do not have permission to modify this project.', 403);
    }
}

$title = trim($project['title'] ?? 'Untitled Project');
$aspectRatio = $project['aspectRatio'] ?? 'ratio9_16';
$durationMs = (int)($project['durationMs'] ?? 0);
$fps = (int)($project['fps'] ?? 30);
$thumbUrl = $project['thumbnailUrl'] ?? null;
$now = date('Y-m-d H:i:s');
$createdAt = $project['createdAt'] ?? $now;

// Ensure embedded project JSON has correct owner details
$project['userId'] = $uid;
$project['userEmail'] = $uemail;
$project['updatedAt'] = $now;
$jsonStr = json_encode($project, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

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

Auth::logActivity('user', $uid, $uemail, 'project_synced', "Backed up project: {$title} ({$pid})");

Response::success([
    'projectId' => $pid,
    'savedAt'   => $now,
    'syncStatus'=> 'synced'
], 'Project backed up successfully');
