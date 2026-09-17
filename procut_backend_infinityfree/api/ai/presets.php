<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';

Response::cors();

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'GET') {
    Response::error("Method {$method} not allowed", 405);
}

$type = trim($_GET['type'] ?? '');
$category = trim($_GET['category'] ?? '');
$search = trim($_GET['search'] ?? '');

$sql = "SELECT id, type, title, category, prompt, negative_prompt, reference_image_url,
               preview_video_url, model_name, style, camera_movement, lighting, seed,
               duration_text, tags, display_order, created_at
        FROM ai_presets
        WHERE is_active = 1";
$params = [];

if ($type === 'photo' || $type === 'video') {
    $sql .= " AND type = ?";
    $params[] = $type;
}

if ($category !== '' && $category !== 'all') {
    $sql .= " AND category = ?";
    $params[] = $category;
}

if ($search !== '') {
    $sql .= " AND (title LIKE ? OR prompt LIKE ? OR model_name LIKE ? OR category LIKE ?)";
    $term = "%{$search}%";
    $params[] = $term;
    $params[] = $term;
    $params[] = $term;
    $params[] = $term;
}

$sql .= " ORDER BY display_order ASC, created_at DESC";

$presets = Database::fetchAll($sql, $params);

// Normalize URLs to full URLs if needed
$baseUrl = APP_BASE_URL;
$formatted = array_map(function ($item) use ($baseUrl) {
    if (!empty($item['reference_image_url']) && str_starts_with($item['reference_image_url'], '/')) {
        $item['reference_image_url'] = $baseUrl . $item['reference_image_url'];
    }
    if (!empty($item['preview_video_url']) && str_starts_with($item['preview_video_url'], '/')) {
        $item['preview_video_url'] = $baseUrl . $item['preview_video_url'];
    }
    return $item;
}, $presets);

$photoCount = count(array_filter($presets, fn($p) => $p['type'] === 'photo'));
$videoCount = count(array_filter($presets, fn($p) => $p['type'] === 'video'));

Response::success([
    'presets'     => $formatted,
    'total'       => count($formatted),
    'photo_count' => $photoCount,
    'video_count' => $videoCount,
    'timestamp'   => date('c')
]);
