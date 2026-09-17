<?php
/**
 * ProCut Templates API Endpoint
 * Handles /api/templates
 * Supports category filtering, search, and full project definition retrieval.
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

// Handle recording template download / usage from mobile app
if ($_SERVER['REQUEST_METHOD'] === 'POST' || ($_GET['action'] ?? '') === 'download' || ($_GET['action'] ?? '') === 'use') {
    $body = Response::getJsonBody();
    $tid = $body['id'] ?? $_POST['id'] ?? $_GET['id'] ?? null;
    if (!empty($tid)) {
        Database::query("UPDATE templates SET downloads_count = downloads_count + 1 WHERE id = ?", [$tid]);
        Auth::logActivity('system', 0, 'App User', 'template_used', "Template used or downloaded: $tid");
        $updated = Database::fetchOne("SELECT downloads_count FROM templates WHERE id = ?", [$tid]);
        Response::success([
            'id' => $tid,
            'downloads_count' => (int)($updated['downloads_count'] ?? 0)
        ], 'Template usage recorded');
    }
}

$category = $_GET['category'] ?? null;
$badge = $_GET['badge'] ?? null;
$search = $_GET['search'] ?? null;
$id = $_GET['id'] ?? null;

// Helper to normalize relative media paths to full URLs
function normalizeMediaUrl(?string $url): ?string {
    if (!$url) return null;
    if (str_starts_with($url, 'http://') || str_starts_with($url, 'https://') || str_starts_with($url, 'assets/')) {
        return $url;
    }
    return APP_BASE_URL . '/' . ltrim($url, '/');
}

// Single template by ID
if (!empty($id)) {
    $template = Database::fetchOne(
        "SELECT id, title, category, badge, description, prompt, author, aspect_ratio,
                duration_ms, clips_count, downloads_count, preview_gradient_start,
                preview_gradient_end, preview_video_url, preview_image_url, audio_title,
                audio_url, project_json, tags, is_pro, is_trending, is_new, is_popular
         FROM templates
         WHERE id = :id AND is_enabled = 1",
        [':id' => $id]
    );

    if (!$template) {
        Response::error('Template not found', 404);
    }

    $template['preview_video_url'] = normalizeMediaUrl($template['preview_video_url']);
    $template['preview_image_url'] = normalizeMediaUrl($template['preview_image_url']);
    $template['audio_url'] = normalizeMediaUrl($template['audio_url']);

    Response::success([
        'template' => $template
    ]);
}

// Build query for list of templates
$sql = "SELECT id, title, category, badge, description, prompt, author, aspect_ratio,
               duration_ms, clips_count, downloads_count, preview_gradient_start,
               preview_gradient_end, preview_video_url, preview_image_url, audio_title,
               audio_url, project_json, tags, is_pro, is_trending, is_new, is_popular
        FROM templates
        WHERE is_enabled = 1";
$params = [];

if (!empty($category) && strtolower($category) !== 'all') {
    $sql .= " AND (category = :category OR tags LIKE :category_tag)";
    $params[':category'] = $category;
    $params[':category_tag'] = '%' . $category . '%';
}

if (!empty($badge)) {
    $sql .= " AND badge = :badge";
    $params[':badge'] = $badge;
}

if (!empty($search)) {
    $sql .= " AND (title LIKE :search OR description LIKE :search OR tags LIKE :search OR category LIKE :search)";
    $params[':search'] = '%' . $search . '%';
}

$sql .= " ORDER BY display_order ASC, created_at DESC";

$templates = Database::fetchAll($sql, $params);

foreach ($templates as &$t) {
    $t['preview_video_url'] = normalizeMediaUrl($t['preview_video_url']);
    $t['preview_image_url'] = normalizeMediaUrl($t['preview_image_url']);
    $t['audio_url'] = normalizeMediaUrl($t['audio_url']);
}

Response::success([
    'total' => count($templates),
    'templates' => $templates
]);
