<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';

Response::cors();

$baseUrl = APP_BASE_URL;

// Fetch enabled, ordered configurable assets
$features = Database::fetchAll(
    "SELECT id, feature_key, title, title AS name, subtitle, icon_name, category, display_order, 
            is_pro_only, is_pro_only AS is_pro, is_enabled, badge_text, action_route
     FROM features
     WHERE is_enabled = 1
     ORDER BY display_order ASC"
);

$templates = Database::fetchAll(
    "SELECT id, title, category, badge, description, prompt, author, aspect_ratio, duration_ms, clips_count, downloads_count,
            preview_gradient_start, preview_gradient_end, preview_video_url, preview_image_url, audio_title, audio_url,
            project_json, tags, is_pro, is_trending, is_new, is_popular
     FROM templates
     WHERE is_enabled = 1
     ORDER BY display_order ASC"
);
$templates = array_map(function ($t) use ($baseUrl) {
    if (!empty($t['preview_video_url']) && str_starts_with($t['preview_video_url'], '/')) {
        $t['preview_video_url'] = $baseUrl . $t['preview_video_url'];
    }
    if (!empty($t['preview_image_url']) && str_starts_with($t['preview_image_url'], '/')) {
        $t['preview_image_url'] = $baseUrl . $t['preview_image_url'];
    }
    if (!empty($t['audio_url']) && str_starts_with($t['audio_url'], '/')) {
        $t['audio_url'] = $baseUrl . $t['audio_url'];
    }
    return $t;
}, $templates);

$effects = Database::fetchAll(
    "SELECT id, effect_key, label, category, description, icon_name, color1, color2, is_pro
     FROM effects
     WHERE is_enabled = 1
     ORDER BY display_order ASC"
);

$filters = Database::fetchAll(
    "SELECT id, filter_key, name, subtitle, category, color_matrix_json, is_pro
     FROM filters
     WHERE is_enabled = 1
     ORDER BY display_order ASC"
);

$transitions = Database::fetchAll(
    "SELECT id, transition_key, label, description, icon_name, is_pro
     FROM transitions
     WHERE is_enabled = 1
     ORDER BY display_order ASC"
);

$animations = Database::fetchAll(
    "SELECT id, animation_key, label, category, is_pro
     FROM animations
     WHERE is_enabled = 1
     ORDER BY display_order ASC"
);

$music = Database::fetchAll(
    "SELECT id, title, artist, category, duration_ms, audio_url, is_pro
     FROM music
     WHERE is_enabled = 1
     ORDER BY display_order ASC"
);
$music = array_map(function ($m) use ($baseUrl) {
    if (!empty($m['audio_url']) && str_starts_with($m['audio_url'], '/')) {
        $m['audio_url'] = $baseUrl . $m['audio_url'];
    }
    return $m;
}, $music);

$stickers = Database::fetchAll(
    "SELECT id, sticker_key, name, category, image_url, is_pro
     FROM stickers
     WHERE is_enabled = 1
     ORDER BY display_order ASC"
);
$stickers = array_map(function ($s) use ($baseUrl) {
    if (!empty($s['image_url']) && str_starts_with($s['image_url'], '/')) {
        $s['image_url'] = $baseUrl . $s['image_url'];
    }
    return $s;
}, $stickers);

$banners = Database::fetchAll(
    "SELECT id, title, subtitle, badge_text, button_text, action_route, image_url, gradient_start, gradient_end, placement
     FROM banners
     WHERE is_enabled = 1
     ORDER BY display_order ASC"
);
$banners = array_map(function ($b) use ($baseUrl) {
    if (!empty($b['image_url']) && str_starts_with($b['image_url'], '/')) {
        $b['image_url'] = $baseUrl . $b['image_url'];
    }
    return $b;
}, $banners);

$ai_presets = Database::fetchAll(
    "SELECT id, type, title, category, prompt, negative_prompt, reference_image_url, preview_video_url,
            model_name, style, camera_movement, lighting, seed, duration_text, tags
     FROM ai_presets
     WHERE is_active = 1
     ORDER BY display_order ASC, created_at DESC"
);
$ai_presets = array_map(function ($p) use ($baseUrl) {
    if (!empty($p['reference_image_url']) && str_starts_with($p['reference_image_url'], '/')) {
        $p['reference_image_url'] = $baseUrl . $p['reference_image_url'];
    }
    if (!empty($p['preview_video_url']) && str_starts_with($p['preview_video_url'], '/')) {
        $p['preview_video_url'] = $baseUrl . $p['preview_video_url'];
    }
    return $p;
}, $ai_presets);

Response::success([
    'features'    => $features,
    'templates'   => $templates,
    'ai_presets'  => $ai_presets,
    'effects'     => $effects,
    'filters'     => $filters,
    'transitions' => $transitions,
    'animations'  => $animations,
    'music'       => $music,
    'stickers'    => $stickers,
    'banners'     => $banners,
    'timestamp'   => date('c')
]);
