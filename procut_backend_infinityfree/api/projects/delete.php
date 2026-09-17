<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

$pid = trim($_GET['id'] ?? $_GET['projectId'] ?? '');
if (empty($pid)) {
    // Attempt parsing from path
    $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    if (preg_match('#/api/projects/([^/?]+)#', $uri, $m)) {
        $pid = trim($m[1]);
    }
}

if (empty($pid)) {
    Response::error('Project ID is required.', 400);
}

$userId = trim($_GET['userId'] ?? $_GET['user_id'] ?? '');
$userEmail = strtolower(trim($_GET['userEmail'] ?? $_GET['user_email'] ?? ''));

// If token provided, authenticate via token
$tokenUser = Auth::authenticateApiUser();
if ($tokenUser) {
    $userId = $tokenUser['user_id'];
    $userEmail = $tokenUser['email'];
}

$existing = Database::fetchOne("SELECT user_id, user_email, title FROM projects WHERE id = ?", [$pid]);
if (!$existing) {
    Response::success(['deleted' => $pid], 'Project already deleted or not found');
}

// Check ownership if user details provided
if (!empty($userId) && $existing['user_id'] !== $userId) {
    Response::error('Unauthorized: You can only delete your own projects.', 403);
}
if (!empty($userEmail) && strtolower($existing['user_email']) !== $userEmail) {
    Response::error('Unauthorized: You can only delete your own projects.', 403);
}

// Delete project files on disk if any
$files = Database::fetchAll("SELECT file_path FROM project_files WHERE project_id = ?", [$pid]);
foreach ($files as $f) {
    if (file_exists($f['file_path'])) {
        @unlink($f['file_path']);
    }
}

Database::query("DELETE FROM projects WHERE id = ?", [$pid]);
Auth::logActivity('user', $existing['user_id'], $existing['user_email'], 'project_deleted', "Deleted project: {$existing['title']} ({$pid})");

Response::success([
    'deleted'   => $pid,
    'projectId' => $pid
], 'Project deleted successfully');
