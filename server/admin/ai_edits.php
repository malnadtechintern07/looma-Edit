<?php
$pageTitle = 'AI Edit Studio';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

// Helper for safe file uploads
function handleMediaUpload($fileKey, $allowedExts, $prefix = 'ai_media_') {
    if (!isset($_FILES[$fileKey]) || $_FILES[$fileKey]['error'] !== UPLOAD_ERR_OK) {
        return null;
    }
    $file = $_FILES[$fileKey];
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!in_array($ext, $allowedExts)) {
        return false;
    }
    $targetDir = MEDIA_UPLOAD_DIR;
    if (!is_dir($targetDir)) {
        @mkdir($targetDir, 0775, true);
    }
    $filename = $prefix . bin2hex(random_bytes(6)) . '_' . time() . '.' . $ext;
    $targetPath = $targetDir . '/' . $filename;
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        return '/uploads/media/' . $filename;
    }
    return false;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $action = $_POST['action'] ?? '';

        if ($action === 'toggle_active') {
            $id = trim($_POST['id'] ?? '');
            $preset = Database::fetchOne("SELECT id, is_active, title FROM ai_presets WHERE id = ?", [$id]);
            if ($preset) {
                $newVal = $preset['is_active'] ? 0 : 1;
                Database::query("UPDATE ai_presets SET is_active = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'ai_preset_toggled', "Toggled AI preset visibility: {$preset['title']} ({$id})");
                $success = "AI preset status updated successfully.";
            } else {
                $error = "Preset not found.";
            }
        } elseif ($action === 'save_ai_preset') {
            $id = trim($_POST['id'] ?? '');
            $type = in_array($_POST['type'] ?? '', ['photo', 'video']) ? $_POST['type'] : 'photo';
            $isNew = empty($id);

            if ($isNew) {
                $id = ($type === 'video' ? 'video_' : 'photo_') . bin2hex(random_bytes(6));
            }

            $title = trim($_POST['title'] ?? '');
            $category = trim($_POST['category'] ?? 'Trending');
            $prompt = trim($_POST['prompt'] ?? '');
            $negativePrompt = trim($_POST['negative_prompt'] ?? 'blurry, low quality, artifacts, distorted, watermark');
            $modelName = trim($_POST['model_name'] ?? ($type === 'video' ? 'OpenAI Sora' : 'Midjourney v6'));
            $style = trim($_POST['style'] ?? 'Cinematic');
            $cameraMovement = trim($_POST['camera_movement'] ?? 'Smooth Cinematic Dolly');
            $lighting = trim($_POST['lighting'] ?? 'Volumetric Atmospheric');
            $seed = trim($_POST['seed'] ?? '');
            $durationText = trim($_POST['duration_text'] ?? ($type === 'video' ? '5s' : 'Static'));
            $tags = trim($_POST['tags'] ?? '');
            $displayOrder = (int)($_POST['display_order'] ?? 0);
            $isActive = isset($_POST['is_active']) ? 1 : 0;

            // Media URL or Upload
            $referenceImageUrl = trim($_POST['reference_image_url'] ?? '');
            $previewVideoUrl = trim($_POST['preview_video_url'] ?? '');

            // Handle image upload if provided
            if (isset($_FILES['reference_image_file']) && $_FILES['reference_image_file']['error'] === UPLOAD_ERR_OK) {
                $uploadedImg = handleMediaUpload('reference_image_file', ['jpg', 'jpeg', 'png', 'webp'], 'ai_ref_');
                if ($uploadedImg === false) {
                    $error = 'Invalid image format. Allowed: JPG, PNG, WEBP.';
                } elseif ($uploadedImg) {
                    $referenceImageUrl = $uploadedImg;
                }
            }

            // Handle video upload if provided
            if (empty($error) && isset($_FILES['preview_video_file']) && $_FILES['preview_video_file']['error'] === UPLOAD_ERR_OK) {
                $uploadedVid = handleMediaUpload('preview_video_file', ['mp4', 'mov', 'webm'], 'ai_vid_');
                if ($uploadedVid === false) {
                    $error = 'Invalid video format. Allowed: MP4, MOV, WEBM.';
                } elseif ($uploadedVid) {
                    $previewVideoUrl = $uploadedVid;
                }
            }

            if (empty($title)) {
                $error = 'Preset title is required.';
            } elseif (empty($prompt)) {
                $error = 'AI generation prompt is required.';
            } elseif (empty($error)) {
                if ($isNew) {
                    Database::query(
                        "INSERT INTO ai_presets (id, type, title, category, prompt, negative_prompt, reference_image_url,
                                                 preview_video_url, model_name, style, camera_movement, lighting, seed,
                                                 duration_text, tags, is_active, display_order)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        [$id, $type, $title, $category, $prompt, $negativePrompt, $referenceImageUrl,
                         $previewVideoUrl, $modelName, $style, $cameraMovement, $lighting, $seed,
                         $durationText, $tags, $isActive, $displayOrder]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'ai_preset_created', "Created AI {$type} preset: {$title} ({$id})");
                    $success = "New AI {$type} prompt preset published successfully!";
                } else {
                    Database::query(
                        "UPDATE ai_presets
                         SET type = ?, title = ?, category = ?, prompt = ?, negative_prompt = ?,
                             reference_image_url = ?, preview_video_url = ?, model_name = ?, style = ?,
                             camera_movement = ?, lighting = ?, seed = ?, duration_text = ?, tags = ?,
                             is_active = ?, display_order = ?, updated_at = NOW()
                         WHERE id = ?",
                        [$type, $title, $category, $prompt, $negativePrompt, $referenceImageUrl,
                         $previewVideoUrl, $modelName, $style, $cameraMovement, $lighting, $seed,
                         $durationText, $tags, $isActive, $displayOrder, $id]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'ai_preset_updated', "Updated AI preset: {$id}");
                    $success = "AI preset updated successfully!";
                }
            }
        } elseif ($action === 'delete_ai_preset') {
            $id = trim($_POST['id'] ?? '');
            $preset = Database::fetchOne("SELECT title FROM ai_presets WHERE id = ?", [$id]);
            Database::query("DELETE FROM ai_presets WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'ai_preset_deleted', "Deleted AI preset: " . ($preset['title'] ?? $id));
            $success = "AI preset deleted permanently.";

        } elseif ($action === 'sync_bundled_presets') {
            // ── Sync all 95 bundled presets to database ──
            $syncFile = dirname(__DIR__) . '/sync_ai_presets.php';
            $seedFile = dirname(__DIR__) . '/database/seed_ai_presets.php';
            if (file_exists($syncFile)) {
                ob_start();
                $_GET['format'] = 'json';
                include $syncFile;
                ob_end_clean();
            } elseif (file_exists($seedFile)) {
                ob_start();
                include $seedFile;
                ob_end_clean();
            }
            $totalCount = (int)(Database::fetchOne("SELECT COUNT(*) as c FROM ai_presets")['c'] ?? 0);
            $photoCount = (int)(Database::fetchOne("SELECT COUNT(*) as c FROM ai_presets WHERE type = 'photo'")['c'] ?? 0);
            $videoCount = (int)(Database::fetchOne("SELECT COUNT(*) as c FROM ai_presets WHERE type = 'video'")['c'] ?? 0);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'ai_presets_synced', "Synced AI presets: {$totalCount} total ({$photoCount} photos, {$videoCount} videos).");
            $success = "✅ AI presets synced! Database now has {$totalCount} presets ({$photoCount} photos, {$videoCount} videos).";
        }
    }
}

// Metrics
$totalPresets = (int)(Database::fetchOne("SELECT COUNT(*) as c FROM ai_presets")['c'] ?? 0);
$totalPhotoPresets = (int)(Database::fetchOne("SELECT COUNT(*) as c FROM ai_presets WHERE type = 'photo'")['c'] ?? 0);
$totalVideoPresets = (int)(Database::fetchOne("SELECT COUNT(*) as c FROM ai_presets WHERE type = 'video'")['c'] ?? 0);
$totalActiveModels = (int)(Database::fetchOne("SELECT COUNT(DISTINCT model_name) as c FROM ai_presets")['c'] ?? 0);

// Filters & Querying
$filterType = trim($_GET['type'] ?? 'all');
$filterCategory = trim($_GET['category'] ?? 'all');
$searchQuery = trim($_GET['search'] ?? '');

$sql = "SELECT * FROM ai_presets WHERE 1=1";
$params = [];

if ($filterType === 'photo' || $filterType === 'video') {
    $sql .= " AND type = ?";
    $params[] = $filterType;
}

if ($filterCategory !== '' && $filterCategory !== 'all') {
    $sql .= " AND category = ?";
    $params[] = $filterCategory;
}

if ($searchQuery !== '') {
    $sql .= " AND (title LIKE ? OR prompt LIKE ? OR model_name LIKE ? OR category LIKE ?)";
    $term = "%{$searchQuery}%";
    $params[] = $term;
    $params[] = $term;
    $params[] = $term;
    $params[] = $term;
}

$sql .= " ORDER BY display_order ASC, created_at DESC";
$presets = Database::fetchAll($sql, $params);

// Categories list for filter dropdown
$distinctCategories = Database::fetchAll("SELECT DISTINCT category FROM ai_presets ORDER BY category ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<!-- Header & Quick Actions -->
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <div class="d-flex align-items-center gap-2 mb-1">
            <h3 class="fw-bold mb-0 brand-font">AI Edit Studio</h3>
            <span class="badge bg-gradient text-white px-2 py-1" style="background: linear-gradient(135deg, #7928CA, #FF0080); font-size: 11px;">
                <i class="bi bi-stars me-1"></i>PRO GENERATIVE
            </span>
        </div>
        <p class="text-muted small mb-0">Control AI Photo & Video prompt presets, reference images, playable video previews, negative prompts, and AI model parameters.</p>
    </div>
    <div class="d-flex gap-2 flex-wrap">
        <button type="button" class="btn btn-outline-dark rounded-pill px-3" onclick="openNewPreset('photo')">
            <i class="bi bi-image me-1 text-primary"></i> Add Photo Prompt
        </button>
        <button type="button" class="btn btn-primary rounded-pill px-3 shadow-sm" onclick="openNewPreset('video')">
            <i class="bi bi-camera-reels-fill me-1"></i> Add Video Prompt
        </button>
        <form method="POST" action="" style="display:inline;" onsubmit="return confirm('Sync all 108 AI photo and video presets into the database? This is safe to run multiple times.');">
            <input type="hidden" name="csrf_token" value="<?= Auth::generateCsrfToken() ?>">
            <input type="hidden" name="action" value="sync_bundled_presets">
            <button type="submit" class="btn rounded-pill px-3 shadow-sm" style="background:linear-gradient(135deg,#7928CA,#FF0080);color:#fff;border:none;">
                <i class="bi bi-cloud-download-fill me-1"></i> Sync All Presets (108)
            </button>
        </form>
    </div>
</div>

<?php if (!empty($error)): ?>
    <div class="alert alert-danger py-2 px-3 small mb-3 rounded-3 shadow-sm d-flex align-items-center gap-2">
        <i class="bi bi-exclamation-triangle-fill"></i>
        <span><?= htmlspecialchars($error) ?></span>
    </div>
<?php endif; ?>

<?php if (!empty($success)): ?>
    <div class="alert alert-success py-2 px-3 small mb-3 rounded-3 shadow-sm d-flex align-items-center gap-2">
        <i class="bi bi-check-circle-fill"></i>
        <span><?= htmlspecialchars($success) ?></span>
    </div>
<?php endif; ?>

<!-- 4 Key Stat Cards -->
<div class="row g-3 mb-4">
    <div class="col-xl-3 col-sm-6">
        <div class="pro-card p-3 p-xl-4 h-100">
            <div class="d-flex align-items-center justify-content-between mb-2">
                <span class="small fw-bold text-muted text-uppercase">Total AI Presets</span>
                <div class="metric-icon-box" style="background: rgba(121, 40, 202, 0.12); color: #7928CA;">
                    <i class="bi bi-robot"></i>
                </div>
            </div>
            <h2 class="fw-bold mb-1"><?= number_format($totalPresets) ?></h2>
            <span class="badge badge-soft-primary">Active Library</span>
        </div>
    </div>
    <div class="col-xl-3 col-sm-6">
        <div class="pro-card p-3 p-xl-4 h-100">
            <div class="d-flex align-items-center justify-content-between mb-2">
                <span class="small fw-bold text-muted text-uppercase">AI Photo Edits</span>
                <div class="metric-icon-box" style="background: rgba(13, 110, 253, 0.12); color: #0D6EFD;">
                    <i class="bi bi-camera-fill"></i>
                </div>
            </div>
            <h2 class="fw-bold mb-1"><?= number_format($totalPhotoPresets) ?></h2>
            <span class="badge badge-soft-info">Midjourney • Flux.1 • SDXL</span>
        </div>
    </div>
    <div class="col-xl-3 col-sm-6">
        <div class="pro-card p-3 p-xl-4 h-100">
            <div class="d-flex align-items-center justify-content-between mb-2">
                <span class="small fw-bold text-muted text-uppercase">AI Video Edits</span>
                <div class="metric-icon-box" style="background: rgba(255, 0, 128, 0.12); color: #FF0080;">
                    <i class="bi bi-film"></i>
                </div>
            </div>
            <h2 class="fw-bold mb-1"><?= number_format($totalVideoPresets) ?></h2>
            <span class="badge badge-soft-warning">Sora • Runway • Kling • Luma</span>
        </div>
    </div>
    <div class="col-xl-3 col-sm-6">
        <div class="pro-card p-3 p-xl-4 h-100">
            <div class="d-flex align-items-center justify-content-between mb-2">
                <span class="small fw-bold text-muted text-uppercase">Supported Models</span>
                <div class="metric-icon-box" style="background: rgba(16, 185, 129, 0.12); color: #10B981;">
                    <i class="bi bi-cpu-fill"></i>
                </div>
            </div>
            <h2 class="fw-bold mb-1"><?= number_format($totalActiveModels) ?></h2>
            <span class="badge badge-soft-success">Multi-Model Studio</span>
        </div>
    </div>
</div>

<!-- Filters Bar -->
<div class="pro-card p-3 mb-4">
    <form method="GET" action="" class="row g-2 align-items-center">
        <!-- Type Segmented Tabs -->
        <div class="col-lg-4 col-md-5">
            <div class="btn-group w-100" role="group">
                <a href="?type=all&category=<?= urlencode($filterCategory) ?>&search=<?= urlencode($searchQuery) ?>"
                   class="btn btn-sm <?= $filterType === 'all' ? 'btn-dark' : 'btn-outline-secondary' ?>">
                    All (<?= $totalPresets ?>)
                </a>
                <a href="?type=photo&category=<?= urlencode($filterCategory) ?>&search=<?= urlencode($searchQuery) ?>"
                   class="btn btn-sm <?= $filterType === 'photo' ? 'btn-primary' : 'btn-outline-secondary' ?>">
                    📸 Photo (<?= $totalPhotoPresets ?>)
                </a>
                <a href="?type=video&category=<?= urlencode($filterCategory) ?>&search=<?= urlencode($searchQuery) ?>"
                   class="btn btn-sm <?= $filterType === 'video' ? 'btn-danger' : 'btn-outline-secondary' ?>">
                    🎬 Video (<?= $totalVideoPresets ?>)
                </a>
            </div>
        </div>

        <!-- Category Dropdown -->
        <div class="col-lg-3 col-md-3">
            <select name="category" class="form-select form-select-sm" onchange="this.form.submit()">
                <option value="all" <?= $filterCategory === 'all' ? 'selected' : '' ?>>All Categories</option>
                <?php foreach ($distinctCategories as $c): ?>
                    <option value="<?= htmlspecialchars($c['category']) ?>" <?= $filterCategory === $c['category'] ? 'selected' : '' ?>>
                        <?= htmlspecialchars($c['category']) ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </div>

        <!-- Search Bar -->
        <div class="col-lg-5 col-md-4">
            <div class="input-group input-group-sm">
                <input type="hidden" name="type" value="<?= htmlspecialchars($filterType) ?>">
                <input type="text" name="search" class="form-control" placeholder="Search title, prompt, or model..." value="<?= htmlspecialchars($searchQuery) ?>">
                <button class="btn btn-primary" type="submit"><i class="bi bi-search"></i></button>
                <?php if (!empty($searchQuery) || $filterCategory !== 'all' || $filterType !== 'all'): ?>
                    <a href="ai_edits.php" class="btn btn-outline-secondary"><i class="bi bi-x-lg"></i></a>
                <?php endif; ?>
            </div>
        </div>
    </form>
</div>

<!-- AI Presets List Table / Cards -->
<div class="pro-card p-0 overflow-hidden mb-4">
    <div class="p-3 border-bottom d-flex justify-content-between align-items-center bg-light">
        <div class="fw-bold small text-uppercase text-secondary">
            Showing <?= count($presets) ?> AI Prompts & Presets
        </div>
        <div class="small text-muted">
            <i class="bi bi-info-circle me-1"></i>Click prompt to copy • Click video to preview in real-time
        </div>
    </div>

    <?php if (empty($presets)): ?>
        <div class="p-5 text-center text-muted">
            <i class="bi bi-robot fs-1 d-block mb-2 text-secondary"></i>
            <h5 class="fw-bold text-dark">No AI Presets Found</h5>
            <p class="small mb-3">No prompts match your filter criteria. Add your first AI prompt preset now.</p>
            <button class="btn btn-sm btn-primary rounded-pill px-3" onclick="openNewPreset('photo')">
                <i class="bi bi-plus-lg me-1"></i> Add AI Prompt
            </button>
        </div>
    <?php else: ?>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead>
                    <tr>
                        <th style="width: 220px;">Media Preview</th>
                        <th>Preset & Model</th>
                        <th style="width: 38%;">Generation Prompt</th>
                        <th>Style & Params</th>
                        <th class="text-center" style="width: 90px;">Status</th>
                        <th class="text-end" style="width: 110px;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($presets as $p): ?>
                        <tr>
                            <!-- Media Preview Column -->
                            <td>
                                <?php if ($p['type'] === 'video'): ?>
                                    <div class="position-relative rounded-3 overflow-hidden bg-black shadow-sm" style="width: 190px; height: 115px;">
                                        <?php if (!empty($p['preview_video_url'])): ?>
                                            <video src="<?= htmlspecialchars($p['preview_video_url']) ?>"
                                                   controls
                                                   preload="metadata"
                                                   playsinline
                                                   poster="<?= htmlspecialchars($p['reference_image_url'] ?: '') ?>"
                                                   style="width: 100%; height: 100%; object-fit: cover; border-radius: 6px;">
                                            </video>
                                        <?php else: ?>
                                            <div class="w-100 h-100 d-flex flex-column align-items-center justify-content-center text-secondary">
                                                <i class="bi bi-camera-reels fs-3 mb-1"></i>
                                                <span style="font-size: 10px;">No video URL</span>
                                            </div>
                                        <?php endif; ?>
                                        <span class="badge bg-danger position-absolute top-0 start-0 m-1 px-1 py-0" style="font-size: 9px; pointer-events: none;">
                                            <i class="bi bi-film me-1"></i>VIDEO
                                        </span>
                                    </div>
                                <?php else: ?>
                                    <div class="position-relative rounded-3 overflow-hidden bg-dark shadow-sm cursor-pointer"
                                         style="width: 140px; height: 115px;"
                                         onclick="showPhotoZoom('<?= htmlspecialchars($p['reference_image_url'] ?: '') ?>', '<?= htmlspecialchars(addslashes($p['title'])) ?>')">
                                        <?php if (!empty($p['reference_image_url'])): ?>
                                            <img src="<?= htmlspecialchars($p['reference_image_url']) ?>"
                                                 alt="<?= htmlspecialchars($p['title']) ?>"
                                                 style="width: 100%; height: 100%; object-fit: cover; transition: transform 0.2s;"
                                                 class="hover-zoom"
                                                 onerror="this.src='/media/templates/tmpl-golden-hour.jpg'">
                                        <?php else: ?>
                                            <div class="w-100 h-100 d-flex flex-column align-items-center justify-content-center text-secondary">
                                                <i class="bi bi-image fs-3 mb-1"></i>
                                                <span style="font-size: 10px;">No image URL</span>
                                            </div>
                                        <?php endif; ?>
                                        <span class="badge bg-primary position-absolute top-0 start-0 m-1 px-1 py-0" style="font-size: 9px;">
                                            <i class="bi bi-image me-1"></i>PHOTO
                                        </span>
                                        <div class="position-absolute bottom-0 end-0 m-1">
                                            <span class="badge bg-black bg-opacity-75" style="font-size: 9px;"><i class="bi bi-arrows-fullscreen"></i></span>
                                        </div>
                                    </div>
                                <?php endif; ?>
                            </td>

                            <!-- Preset Info Column -->
                            <td>
                                <div class="d-flex align-items-center gap-2 mb-1">
                                    <strong class="text-dark fs-6"><?= htmlspecialchars($p['title']) ?></strong>
                                </div>
                                <div class="d-flex flex-wrap gap-1 mb-2">
                                    <span class="badge badge-soft-info" style="font-size: 11px;"><?= htmlspecialchars($p['category']) ?></span>
                                    <span class="badge badge-soft-primary" style="font-size: 11px;">
                                        <i class="bi bi-cpu me-1"></i><?= htmlspecialchars($p['model_name'] ?: 'AI Model') ?>
                                    </span>
                                </div>
                                <div class="text-muted small" style="font-size: 11.5px;">
                                    <i class="bi bi-sort-numeric-down me-1"></i>Order: <strong><?= (int)$p['display_order'] ?></strong>
                                    <span class="mx-1">•</span>
                                    <span>ID: <code><?= htmlspecialchars($p['id']) ?></code></span>
                                </div>
                            </td>

                            <!-- Prompt Column -->
                            <td>
                                <div class="position-relative p-2 rounded-3 bg-light border" style="font-size: 12px; line-height: 1.4; max-height: 95px; overflow-y: auto;">
                                    <div class="text-dark font-monospace mb-1"><?= htmlspecialchars($p['prompt']) ?></div>
                                    <?php if (!empty($p['negative_prompt'])): ?>
                                        <div class="text-danger small border-top pt-1 mt-1" style="font-size: 10.5px;">
                                            <strong>Neg:</strong> <?= htmlspecialchars($p['negative_prompt']) ?>
                                        </div>
                                    <?php endif; ?>
                                </div>
                                <div class="mt-1 d-flex justify-content-end">
                                    <button type="button" class="btn btn-link btn-sm text-decoration-none p-0 text-primary small" style="font-size: 11px;" onclick="copyToClipboard(<?= json_encode($p['prompt']) ?>, this)">
                                        <i class="bi bi-clipboard me-1"></i>Copy Prompt
                                    </button>
                                </div>
                            </td>

                            <!-- Style & Parameters Column -->
                            <td>
                                <div class="small" style="font-size: 11.5px; line-height: 1.4;">
                                    <div><strong>Style:</strong> <?= htmlspecialchars($p['style'] ?: 'Cinematic') ?></div>
                                    <?php if ($p['type'] === 'video'): ?>
                                        <div class="text-secondary"><strong>Camera:</strong> <?= htmlspecialchars($p['camera_movement'] ?: 'Dolly') ?></div>
                                        <div class="text-secondary"><strong>Duration:</strong> <?= htmlspecialchars($p['duration_text'] ?: '5s') ?></div>
                                    <?php else: ?>
                                        <div class="text-secondary"><strong>Lighting:</strong> <?= htmlspecialchars($p['lighting'] ?: 'Studio') ?></div>
                                    <?php endif; ?>
                                    <?php if (!empty($p['seed'])): ?>
                                        <div class="text-muted"><strong>Seed:</strong> <code><?= htmlspecialchars($p['seed']) ?></code></div>
                                    <?php endif; ?>
                                </div>
                            </td>

                            <!-- Status Toggle Column -->
                            <td class="text-center">
                                <form method="POST" action="" class="d-inline">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                    <input type="hidden" name="id" value="<?= htmlspecialchars($p['id']) ?>">
                                    <input type="hidden" name="action" value="toggle_active">
                                    <?php if ($p['is_active']): ?>
                                        <button type="submit" class="badge badge-soft-success border-0 px-2 py-1" title="Click to hide from mobile app">
                                            <i class="bi bi-check-circle me-1"></i>Active
                                        </button>
                                    <?php else: ?>
                                        <button type="submit" class="badge badge-soft-danger border-0 px-2 py-1" title="Click to publish to mobile app">
                                            <i class="bi bi-eye-slash me-1"></i>Hidden
                                        </button>
                                    <?php endif; ?>
                                </form>
                            </td>

                            <!-- Actions Column -->
                            <td class="text-end">
                                <div class="d-flex justify-content-end gap-1">
                                    <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2" title="Edit Prompt" onclick='editPreset(<?= json_encode($p) ?>)'>
                                        <i class="bi bi-pencil-square"></i>
                                    </button>
                                    <form method="POST" action="" onsubmit="return confirm('Are you sure you want to delete AI preset: <?= htmlspecialchars(addslashes($p['title'])) ?>?');" class="d-inline">
                                        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                        <input type="hidden" name="id" value="<?= htmlspecialchars($p['id']) ?>">
                                        <input type="hidden" name="action" value="delete_ai_preset">
                                        <button type="submit" class="btn btn-sm btn-outline-danger py-1 px-2" title="Delete">
                                            <i class="bi bi-trash3"></i>
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</div>

<!-- Add / Edit AI Preset Modal -->
<div class="modal fade" id="presetModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow-lg overflow-hidden">
            <div class="modal-header bg-light border-bottom py-3">
                <div class="d-flex align-items-center gap-2">
                    <div class="rounded-circle p-2 bg-primary bg-opacity-10 text-primary" id="modalIcon">
                        <i class="bi bi-robot fs-5"></i>
                    </div>
                    <div>
                        <h5 class="modal-title fw-bold mb-0" id="presetModalTitle">Create AI Prompt Preset</h5>
                        <small class="text-muted" id="presetModalSubtitle">Configure generation prompt, preview assets, and AI engine parameters</small>
                    </div>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>

            <form method="POST" action="" enctype="multipart/form-data" id="presetForm">
                <div class="modal-body p-4">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_ai_preset">
                    <input type="hidden" name="id" id="presetId" value="">

                    <!-- Type Selector Tabs -->
                    <div class="mb-3">
                        <label class="form-label small fw-bold text-uppercase text-secondary">AI Preset Type</label>
                        <div class="row g-2">
                            <div class="col-6">
                                <label class="card p-2 text-center border cursor-pointer h-100 preset-type-option" id="typeOptionPhoto">
                                    <input type="radio" name="type" value="photo" id="typePhoto" class="d-none" onchange="onTypeChanged('photo')">
                                    <div class="d-flex align-items-center justify-content-center gap-2">
                                        <i class="bi bi-image fs-5 text-primary"></i>
                                        <div class="text-start">
                                            <strong class="d-block small">AI Photo Edit</strong>
                                            <span class="text-muted" style="font-size: 11px;">Midjourney, Flux, SDXL</span>
                                        </div>
                                    </div>
                                </label>
                            </div>
                            <div class="col-6">
                                <label class="card p-2 text-center border cursor-pointer h-100 preset-type-option" id="typeOptionVideo">
                                    <input type="radio" name="type" value="video" id="typeVideo" class="d-none" onchange="onTypeChanged('video')">
                                    <div class="d-flex align-items-center justify-content-center gap-2">
                                        <i class="bi bi-camera-reels-fill fs-5 text-danger"></i>
                                        <div class="text-start">
                                            <strong class="d-block small">AI Video Edit</strong>
                                            <span class="text-muted" style="font-size: 11px;">Sora, Runway Gen-3, Kling</span>
                                        </div>
                                    </div>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="row g-3 mb-3">
                        <div class="col-md-7">
                            <label class="form-label small fw-semibold">Preset Title <span class="text-danger">*</span></label>
                            <input type="text" name="title" id="presetTitle" class="form-control" placeholder="e.g. Cyberpunk Neon Tokyo 2088" required>
                        </div>
                        <div class="col-md-5">
                            <label class="form-label small fw-semibold">Category <span class="text-danger">*</span></label>
                            <input type="text" name="category" id="presetCategory" class="form-control" list="categorySuggestions" placeholder="e.g. Trending, 80s, Popular" required>
                            <datalist id="categorySuggestions">
                                <option value="Trending">
                                <option value="New">
                                <option value="80s">
                                <option value="Popular">
                                <option value="Cyberpunk">
                                <option value="Anime">
                                <option value="3D Render">
                                <option value="Cinematic">
                                <option value="Nature & Travel">
                                <option value="Sci-Fi & Cyberpunk">
                            </datalist>
                        </div>
                    </div>

                    <div class="row g-3 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">AI Model Engine</label>
                            <input type="text" name="model_name" id="presetModel" class="form-control" list="modelSuggestions" placeholder="e.g. OpenAI Sora, Runway Gen-3, Midjourney v6">
                            <datalist id="modelSuggestions">
                                <option value="OpenAI Sora">
                                <option value="Runway Gen-3 Alpha">
                                <option value="Kling AI 1.5">
                                <option value="Luma Dream Machine">
                                <option value="Pika 2.0 Pro">
                                <option value="Midjourney v6">
                                <option value="Flux.1 Pro">
                                <option value="Stable Diffusion XL">
                                <option value="NijiJourney v6">
                            </datalist>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Visual Style</label>
                            <input type="text" name="style" id="presetStyle" class="form-control" placeholder="e.g. Cinematic Photorealism, 80s Synthwave">
                        </div>
                    </div>

                    <!-- Prompt & Negative Prompt -->
                    <div class="mb-3">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                            <label class="form-label small fw-semibold mb-0">Master Generation Prompt <span class="text-danger">*</span></label>
                            <span class="text-muted small" style="font-size: 11px;">Complete text prompt executed by the AI engine</span>
                        </div>
                        <textarea name="prompt" id="presetPrompt" class="form-control font-monospace" rows="4" placeholder="Detailed visual prompt describing subject, composition, environment, camera, and lighting..." required></textarea>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold mb-1">Negative Prompt</label>
                        <input type="text" name="negative_prompt" id="presetNegativePrompt" class="form-control font-monospace small" value="blurry, low quality, artifacts, distorted, flickering, watermark, deformed">
                    </div>

                    <!-- Media Inputs: Image & Video with Live Previews -->
                    <div class="card p-3 bg-light border-0 rounded-3 mb-3">
                        <h6 class="fw-bold small mb-2 text-uppercase text-secondary">
                            <i class="bi bi-collection-play me-1"></i>Reference Photo & Playable Video Assets
                        </h6>

                        <!-- Reference Photo Section -->
                        <div class="row g-3 align-items-center mb-3">
                            <div class="col-md-8">
                                <label class="form-label small fw-semibold">Photo Reference URL / Server Path</label>
                                <input type="text" name="reference_image_url" id="presetImgUrl" class="form-control form-control-sm" placeholder="/media/templates/filename.jpg" oninput="updateModalImagePreview(this.value)">
                                <div class="mt-2">
                                    <label class="form-label small text-muted mb-1">Or Upload New Image File (.jpg, .png, .webp):</label>
                                    <input type="file" name="reference_image_file" class="form-control form-control-sm" accept="image/*" onchange="previewUploadedImage(this)">
                                </div>
                            </div>
                            <div class="col-md-4 text-center">
                                <div class="border rounded-3 bg-white p-1 shadow-sm d-inline-block" style="width: 130px; height: 100px;">
                                    <img id="modalImgPreview" src="" alt="Preview" class="w-100 h-100 rounded-2" style="object-fit: cover; display: none;">
                                    <div id="modalImgPlaceholder" class="w-100 h-100 d-flex flex-column align-items-center justify-content-center text-muted small">
                                        <i class="bi bi-image fs-4"></i>
                                        <span style="font-size: 10px;">Photo Preview</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Video Preview Section -->
                        <div class="row g-3 align-items-center" id="videoSectionRow">
                            <div class="col-md-8">
                                <label class="form-label small fw-semibold">Playable Video Preview URL / Server Path</label>
                                <input type="text" name="preview_video_url" id="presetVideoUrl" class="form-control form-control-sm" placeholder="/media/templates/urban_skate.mp4" oninput="updateModalVideoPreview(this.value)">
                                <div class="mt-2">
                                    <label class="form-label small text-muted mb-1">Or Upload New Video File (.mp4, .mov, .webm):</label>
                                    <input type="file" name="preview_video_file" class="form-control form-control-sm" accept="video/*" onchange="previewUploadedVideo(this)">
                                </div>
                            </div>
                            <div class="col-md-4 text-center">
                                <div class="border rounded-3 bg-black p-1 shadow-sm d-inline-block" style="width: 140px; height: 100px;">
                                    <video id="modalVideoPreview" controls playsinline class="w-100 h-100 rounded-2" style="object-fit: cover; display: none;"></video>
                                    <div id="modalVideoPlaceholder" class="w-100 h-100 d-flex flex-column align-items-center justify-content-center text-secondary small">
                                        <i class="bi bi-camera-reels fs-4"></i>
                                        <span style="font-size: 10px;">Video Player</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Parameters: Camera, Lighting, Duration, Seed -->
                    <div class="row g-2 mb-3">
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Camera Movement</label>
                            <input type="text" name="camera_movement" id="presetCamera" class="form-control form-control-sm" placeholder="e.g. Smooth Gimbal Dolly, FPV Dive">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Lighting Condition</label>
                            <input type="text" name="lighting" id="presetLighting" class="form-control form-control-sm" placeholder="e.g. Golden Hour, Volumetric Fog">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Duration Text</label>
                            <input type="text" name="duration_text" id="presetDuration" class="form-control form-control-sm" value="5s" placeholder="5s, 10s, Static">
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Generation Seed (Optional)</label>
                            <input type="text" name="seed" id="presetSeed" class="form-control form-control-sm" placeholder="e.g. 8492019">
                        </div>
                        <div class="col-md-5">
                            <label class="form-label small fw-semibold">Tags (comma-separated)</label>
                            <input type="text" name="tags" id="presetTags" class="form-control form-control-sm" placeholder="Trending, Viral, 4K, 8K">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label small fw-semibold">Display Order</label>
                            <input type="number" name="display_order" id="presetOrder" class="form-control form-control-sm" value="0">
                        </div>
                    </div>

                    <div class="d-flex align-items-center mt-2">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="is_active" id="presetActive" value="1" checked>
                            <label class="form-check-label fw-semibold small" for="presetActive">
                                Active & Visible in ProCut Mobile App Feed
                            </label>
                        </div>
                    </div>
                </div>

                <div class="modal-footer bg-light border-top py-2 px-4">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-3" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary rounded-pill px-4 shadow-sm" id="btnSubmitPreset">
                        <i class="bi bi-cloud-check-fill me-1"></i> Save AI Preset
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Photo Zoom Modal -->
<div class="modal fade" id="zoomModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content bg-transparent border-0 text-center">
            <div class="position-relative d-inline-block mx-auto">
                <img id="zoomModalImg" src="" alt="Full Preview" class="img-fluid rounded-4 shadow-lg" style="max-height: 80vh; object-fit: contain;">
                <button type="button" class="btn btn-light position-absolute top-0 end-0 m-3 rounded-circle shadow" data-bs-dismiss="modal" style="width: 40px; height: 40px;">
                    <i class="bi bi-x-lg"></i>
                </button>
                <div class="mt-2 text-white fw-bold shadow-sm" id="zoomModalTitle"></div>
            </div>
        </div>
    </div>
</div>

<style>
.cursor-pointer { cursor: pointer; }
.hover-zoom:hover { transform: scale(1.05); }
.preset-type-option.active-type {
    border-color: #0D6EFD !important;
    background-color: rgba(13, 110, 253, 0.08) !important;
}
</style>

<script>
let currentModalType = 'photo';

function onTypeChanged(type) {
    currentModalType = type;
    const photoOpt = document.getElementById('typeOptionPhoto');
    const videoOpt = document.getElementById('typeOptionVideo');

    if (type === 'video') {
        document.getElementById('typeVideo').checked = true;
        videoOpt.classList.add('active-type');
        photoOpt.classList.remove('active-type');
        document.getElementById('modalIcon').className = 'rounded-circle p-2 bg-danger bg-opacity-10 text-danger';
        document.getElementById('modalIcon').innerHTML = '<i class="bi bi-film fs-5"></i>';
        if (!document.getElementById('presetModel').value || document.getElementById('presetModel').value.includes('Midjourney')) {
            document.getElementById('presetModel').value = 'OpenAI Sora';
        }
        if (!document.getElementById('presetDuration').value || document.getElementById('presetDuration').value === 'Static') {
            document.getElementById('presetDuration').value = '5s';
        }
    } else {
        document.getElementById('typePhoto').checked = true;
        photoOpt.classList.add('active-type');
        videoOpt.classList.remove('active-type');
        document.getElementById('modalIcon').className = 'rounded-circle p-2 bg-primary bg-opacity-10 text-primary';
        document.getElementById('modalIcon').innerHTML = '<i class="bi bi-image fs-5"></i>';
        if (!document.getElementById('presetModel').value || document.getElementById('presetModel').value.includes('Sora')) {
            document.getElementById('presetModel').value = 'Midjourney v6';
        }
        document.getElementById('presetDuration').value = 'Static';
    }
}

function updateModalImagePreview(url) {
    const img = document.getElementById('modalImgPreview');
    const placeholder = document.getElementById('modalImgPlaceholder');
    if (url && url.trim() !== '') {
        img.src = url;
        img.style.display = 'block';
        placeholder.style.display = 'none';
    } else {
        img.style.display = 'none';
        placeholder.style.display = 'flex';
    }
}

function previewUploadedImage(input) {
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
            updateModalImagePreview(e.target.result);
        };
        reader.readAsDataURL(input.files[0]);
    }
}

function updateModalVideoPreview(url) {
    const vid = document.getElementById('modalVideoPreview');
    const placeholder = document.getElementById('modalVideoPlaceholder');
    if (url && url.trim() !== '') {
        vid.src = url;
        vid.style.display = 'block';
        placeholder.style.display = 'none';
        vid.load();
    } else {
        vid.style.display = 'none';
        placeholder.style.display = 'flex';
    }
}

function previewUploadedVideo(input) {
    if (input.files && input.files[0]) {
        const fileUrl = URL.createObjectURL(input.files[0]);
        updateModalVideoPreview(fileUrl);
    }
}

function openNewPreset(type) {
    document.getElementById('presetModalTitle').innerText = type === 'video' ? 'Create AI Video Prompt' : 'Create AI Photo Prompt';
    document.getElementById('presetModalSubtitle').innerText = 'Add a high-fidelity generation prompt to the ProCut mobile creative feed';
    document.getElementById('presetId').value = '';
    document.getElementById('presetTitle').value = '';
    document.getElementById('presetCategory').value = 'Trending';
    document.getElementById('presetPrompt').value = '';
    document.getElementById('presetNegativePrompt').value = 'blurry, low quality, artifacts, distorted, flickering, watermark, deformed';
    document.getElementById('presetModel').value = type === 'video' ? 'OpenAI Sora' : 'Midjourney v6';
    document.getElementById('presetStyle').value = 'Cinematic Photorealism';
    document.getElementById('presetCamera').value = type === 'video' ? 'Smooth Cinematic Dolly' : 'Static Portrait 85mm';
    document.getElementById('presetLighting').value = 'Volumetric Atmospheric';
    document.getElementById('presetSeed').value = Math.floor(1000000 + Math.random() * 9000000);
    document.getElementById('presetDuration').value = type === 'video' ? '5s' : 'Static';
    document.getElementById('presetTags').value = 'Trending, 4K, Masterpiece';
    document.getElementById('presetOrder').value = '0';
    document.getElementById('presetActive').checked = true;

    // Reset media
    document.getElementById('presetImgUrl').value = '';
    document.getElementById('presetVideoUrl').value = '';
    updateModalImagePreview('');
    updateModalVideoPreview('');

    onTypeChanged(type);
    new bootstrap.Modal(document.getElementById('presetModal')).show();
}

function editPreset(p) {
    document.getElementById('presetModalTitle').innerText = 'Edit AI Preset: ' + p.title;
    document.getElementById('presetModalSubtitle').innerText = 'Modify prompt keywords, AI models, or replace preview assets';
    document.getElementById('presetId').value = p.id;
    document.getElementById('presetTitle').value = p.title || '';
    document.getElementById('presetCategory').value = p.category || 'Trending';
    document.getElementById('presetPrompt').value = p.prompt || '';
    document.getElementById('presetNegativePrompt').value = p.negative_prompt || '';
    document.getElementById('presetModel').value = p.model_name || '';
    document.getElementById('presetStyle').value = p.style || '';
    document.getElementById('presetCamera').value = p.camera_movement || '';
    document.getElementById('presetLighting').value = p.lighting || '';
    document.getElementById('presetSeed').value = p.seed || '';
    document.getElementById('presetDuration').value = p.duration_text || (p.type === 'video' ? '5s' : 'Static');
    document.getElementById('presetTags').value = p.tags || '';
    document.getElementById('presetOrder').value = p.display_order || 0;
    document.getElementById('presetActive').checked = (p.is_active == 1);

    document.getElementById('presetImgUrl').value = p.reference_image_url || '';
    document.getElementById('presetVideoUrl').value = p.preview_video_url || '';

    updateModalImagePreview(p.reference_image_url || '');
    updateModalVideoPreview(p.preview_video_url || '');

    onTypeChanged(p.type || 'photo');
    new bootstrap.Modal(document.getElementById('presetModal')).show();
}

function showPhotoZoom(url, title) {
    if (!url) return;
    document.getElementById('zoomModalImg').src = url;
    document.getElementById('zoomModalTitle').innerText = title || 'Reference Image Preview';
    new bootstrap.Modal(document.getElementById('zoomModal')).show();
}

function copyToClipboard(text, btn) {
    if (!text) return;
    navigator.clipboard.writeText(text).then(function() {
        const originalHtml = btn.innerHTML;
        btn.innerHTML = '<i class="bi bi-check2 me-1 text-success"></i><span class="text-success fw-bold">Copied!</span>';
        setTimeout(() => {
            btn.innerHTML = originalHtml;
        }, 2000);
    }).catch(function() {
        alert('Prompt copied: ' + text);
    });
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
