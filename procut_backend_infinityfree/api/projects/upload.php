<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';
require_once __DIR__ . '/../../helpers/uploader.php';

Response::cors();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed. Use POST with multipart/form-data.', 405);
}

if (empty($_FILES['file'])) {
    Response::error('No file uploaded in "file" form field.', 400);
}

$projectId = trim($_POST['projectId'] ?? $_POST['project_id'] ?? '');
$userId = trim($_POST['userId'] ?? $_POST['user_id'] ?? '');
$type = trim($_POST['type'] ?? 'media'); // 'media', 'thumbnail'

if (empty($projectId) || empty($userId)) {
    Response::error('projectId and userId are required.', 400);
}

$allowedMimes = [
    'image/jpeg', 'image/png', 'image/webp', 'image/gif',
    'video/mp4', 'video/quicktime', 'video/webm',
    'audio/mpeg', 'audio/wav', 'audio/aac', 'audio/mp4'
];

$targetDir = ($type === 'thumbnail') ? THUMBNAIL_UPLOAD_DIR : MEDIA_UPLOAD_DIR;
$result = Uploader::uploadFile($_FILES['file'], $targetDir, $allowedMimes);

if (!$result['success']) {
    Response::error($result['error'], 400);
}

$fileId = 'pf_' . bin2hex(random_bytes(12));
$fileType = str_starts_with($result['mime_type'], 'video/') ? 'video' 
    : (str_starts_with($result['mime_type'], 'audio/') ? 'audio' 
    : ($type === 'thumbnail' ? 'thumbnail' : 'image'));

Database::query(
    "INSERT INTO project_files (id, project_id, user_id, file_type, file_path, original_name, file_size_bytes, mime_type)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
    [
        $fileId,
        $projectId,
        $userId,
        $fileType,
        $result['file_path'],
        $result['original_name'],
        $result['size_bytes'],
        $result['mime_type']
    ]
);

// If thumbnail, also update projects table
if ($type === 'thumbnail' || $fileType === 'thumbnail') {
    Database::query("UPDATE projects SET thumbnail_url = ? WHERE id = ?", [$result['web_url'], $projectId]);
}

Response::success([
    'fileId'   => $fileId,
    'url'      => $result['web_url'],
    'fileName' => $result['file_name'],
    'fileType' => $fileType,
    'size'     => $result['size_bytes']
], 'File uploaded and attached successfully');
