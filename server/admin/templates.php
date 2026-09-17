<?php
$pageTitle = 'Templates Studio';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

// Helper for safe video file uploads
function handleTemplateVideoUpload($fileKey) {
    if (!isset($_FILES[$fileKey]) || $_FILES[$fileKey]['error'] !== UPLOAD_ERR_OK) {
        return null;
    }
    $file = $_FILES[$fileKey];
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $allowedExts = ['mp4', 'mov', 'webm'];
    if (!in_array($ext, $allowedExts)) {
        return false;
    }
    $targetDir = MEDIA_UPLOAD_DIR;
    if (!is_dir($targetDir)) {
        @mkdir($targetDir, 0775, true);
    }
    $filename = 'tmpl_vid_' . bin2hex(random_bytes(6)) . '_' . time() . '.' . $ext;
    $targetPath = $targetDir . '/' . $filename;
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        return '/uploads/media/' . $filename;
    }
    return false;
}

// Helper for safe preview image uploads
function handleTemplateImageUpload($fileKey) {
    if (!isset($_FILES[$fileKey]) || $_FILES[$fileKey]['error'] !== UPLOAD_ERR_OK) {
        return null;
    }
    $file = $_FILES[$fileKey];
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $allowedExts = ['jpg', 'jpeg', 'png', 'webp'];
    if (!in_array($ext, $allowedExts)) {
        return false;
    }
    $targetDir = MEDIA_UPLOAD_DIR;
    if (!is_dir($targetDir)) {
        @mkdir($targetDir, 0775, true);
    }
    $filename = 'tmpl_img_' . bin2hex(random_bytes(6)) . '_' . time() . '.' . $ext;
    $targetPath = $targetDir . '/' . $filename;
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        return '/uploads/media/' . $filename;
    }
    return false;
}

// Standard 25 Categories
$categories = [
    'Birthday', 'Wedding', 'Travel', 'Love Story', 'Family', 'Friends',
    'Birthday Slideshow', 'Cinematic', 'Beat Sync', 'Reels', 'Festival',
    'Graduation', 'Before & After', '80s Retro', 'Trending', 'Photo Memories',
    'Fashion', 'Celebration', 'Business', 'Motivation', 'Nature', 'Food',
    'Fitness', 'Fast Transitions', 'Viral/Short Video'
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $action = $_POST['action'] ?? '';

        if ($action === 'toggle_enabled') {
            $id = trim($_POST['id'] ?? '');
            $t = Database::fetchOne("SELECT * FROM templates WHERE id = ?", [$id]);
            if ($t) {
                $newVal = $t['is_enabled'] ? 0 : 1;
                Database::query("UPDATE templates SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'template_toggled', "Toggled template {$id}");
                $success = "Template visibility updated.";
            }
        } elseif ($action === 'save_template') {
            $id = trim($_POST['id'] ?? '');
            $isNew = empty($id);
            if ($isNew) {
                $id = 'tmpl-' . bin2hex(random_bytes(6));
            }
            $title = trim($_POST['title'] ?? '');
            $category = trim($_POST['category'] ?? 'Trending');
            $badge = trim($_POST['badge'] ?? 'Trending');
            $description = trim($_POST['description'] ?? '');
            $prompt = trim($_POST['prompt'] ?? '');
            $author = trim($_POST['author'] ?? 'ProCut Originals');
            $aspectRatio = trim($_POST['aspect_ratio'] ?? 'ratio9_16');
            $durationMs = (int)($_POST['duration_ms'] ?? 10000);
            $clipsCount = (int)($_POST['clips_count'] ?? 4);
            $gradStart = trim($_POST['preview_gradient_start'] ?? '0xFF7C3AED');
            $gradEnd = trim($_POST['preview_gradient_end'] ?? '0xFFEC4899');
            $videoUrl = trim($_POST['preview_video_url'] ?? '');
            $imageUrl = trim($_POST['preview_image_url'] ?? '');
            $audioTitle = trim($_POST['audio_title'] ?? '');
            $audioUrl = trim($_POST['audio_url'] ?? '');
            $projectJson = trim($_POST['project_json'] ?? '');
            $tags = trim($_POST['tags'] ?? '');
            $isPro = isset($_POST['is_pro']) ? 1 : 0;
            $isTrending = isset($_POST['is_trending']) ? 1 : 0;
            $isNewFlag = isset($_POST['is_new']) ? 1 : 0;
            $isPopular = isset($_POST['is_popular']) ? 1 : 0;
            $enabled = isset($_POST['is_enabled']) ? 1 : 0;
            $order = (int)($_POST['display_order'] ?? 1);

            // Handle video upload if provided
            if (isset($_FILES['preview_video_file']) && $_FILES['preview_video_file']['error'] === UPLOAD_ERR_OK) {
                $uploaded = handleTemplateVideoUpload('preview_video_file');
                if ($uploaded === false) {
                    $error = 'Invalid video format. Allowed: MP4, MOV, WEBM.';
                } elseif ($uploaded) {
                    $videoUrl = $uploaded;
                }
            }

            // Handle image upload if provided
            if (isset($_FILES['preview_image_file']) && $_FILES['preview_image_file']['error'] === UPLOAD_ERR_OK) {
                $uploadedImg = handleTemplateImageUpload('preview_image_file');
                if ($uploadedImg === false) {
                    $error = 'Invalid image format. Allowed: JPG, PNG, WEBP.';
                } elseif ($uploadedImg) {
                    $imageUrl = $uploadedImg;
                }
            }

            // Fallback project JSON if empty
            if (empty($projectJson)) {
                $defaultClips = [];
                $clipDur = round($durationMs / max(1, $clipsCount));
                for ($i = 1; $i <= $clipsCount; $i++) {
                    $defaultClips[] = [
                        'id' => "clip_{$id}_{$i}",
                        'mediaPath' => 'assets/demo/urban_skate.mp4',
                        'name' => "Slot #{$i}",
                        'sourceDurationMs' => $clipDur,
                        'timelineStartMs' => ($i - 1) * $clipDur,
                        'timelineEndMs' => $i * $clipDur,
                        'trimStartMs' => 0,
                        'trimEndMs' => $clipDur,
                        'speed' => 1.0,
                        'volume' => 1.0,
                        'filterType' => 'vivid',
                        'transitionIn' => 'zoomIn',
                    ];
                }
                $projectJson = json_encode([
                    'id' => $id,
                    'title' => $title,
                    'aspectRatio' => $aspectRatio,
                    'fps' => 30,
                    'durationMs' => $durationMs,
                    'videoClips' => $defaultClips,
                    'audioClips' => [
                        [
                            'id' => "audio_{$id}",
                            'mediaPath' => $audioUrl ?: 'assets/demo/phonk_beat.wav',
                            'title' => $audioTitle ?: 'Soundtrack',
                            'timelineStartMs' => 0,
                            'timelineEndMs' => $durationMs,
                        ]
                    ],
                    'textOverlays' => [
                        [
                            'id' => "text_{$id}_1",
                            'text' => $title,
                            'fontFamily' => 'Inter',
                            'fontSize' => 26,
                            'colorHex' => 0xFFFFFFFF,
                            'timelineStartMs' => 0,
                            'timelineEndMs' => round($durationMs * 0.5),
                            'animationType' => 'scale',
                            'posX' => 0.5,
                            'posY' => 0.25,
                        ]
                    ],
                ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
            }

            if (empty($title)) {
                $error = 'Template title is required.';
            } elseif (empty($error)) {
                if ($isNew) {
                    Database::query(
                        "INSERT INTO templates (
                            id, title, category, badge, description, prompt, author, aspect_ratio, duration_ms, clips_count,
                            preview_gradient_start, preview_gradient_end, preview_video_url, preview_image_url, audio_title,
                            audio_url, project_json, tags, is_pro, is_trending, is_new, is_popular, is_enabled, display_order, created_at, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())",
                        [
                            $id, $title, $category, $badge, $description, $prompt, $author, $aspectRatio, $durationMs, $clipsCount,
                            $gradStart, $gradEnd, $videoUrl, $imageUrl, $audioTitle, $audioUrl, $projectJson, $tags,
                            $isPro, $isTrending, $isNewFlag, $isPopular, $enabled, $order
                        ]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'template_created', "Created template {$title} ({$id})");
                    $success = "New template published.";
                } else {
                    Database::query(
                        "UPDATE templates SET
                            title = ?, category = ?, badge = ?, description = ?, prompt = ?, author = ?, aspect_ratio = ?, duration_ms = ?, clips_count = ?,
                            preview_gradient_start = ?, preview_gradient_end = ?, preview_video_url = ?, preview_image_url = ?, audio_title = ?,
                            audio_url = ?, project_json = ?, tags = ?, is_pro = ?, is_trending = ?, is_new = ?, is_popular = ?, is_enabled = ?, display_order = ?, updated_at = NOW()
                         WHERE id = ?",
                        [
                            $title, $category, $badge, $description, $prompt, $author, $aspectRatio, $durationMs, $clipsCount,
                            $gradStart, $gradEnd, $videoUrl, $imageUrl, $audioTitle, $audioUrl, $projectJson, $tags,
                            $isPro, $isTrending, $isNewFlag, $isPopular, $enabled, $order, $id
                        ]
                    );
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'template_updated', "Updated template {$id}");
                    $success = "Template updated successfully.";
                }
            }
        } elseif ($action === 'delete_template') {
            $id = trim($_POST['id'] ?? '');
            Database::query("DELETE FROM templates WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'template_deleted', "Deleted template {$id}");
            $success = "Template deleted.";
        }
    }
}

// Category filter
$selectedCategory = $_GET['cat'] ?? 'All';
if ($selectedCategory !== 'All') {
    $templates = Database::fetchAll("SELECT * FROM templates WHERE category = ? ORDER BY display_order ASC, created_at DESC", [$selectedCategory]);
} else {
    $templates = Database::fetchAll("SELECT * FROM templates ORDER BY display_order ASC, created_at DESC");
}

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Templates Studio (25 Online Categories)</h3>
        <p class="text-muted small mb-0">Manage 25 editable video template categories, real video/image previews, project timelines, placeholders, transitions & audio definitions.</p>
    </div>
    <div class="d-flex gap-2">
        <a href="<?= APP_BASE_URL ?>/admin/ai_edits.php" class="btn btn-outline-dark rounded-pill px-3">
            <i class="bi bi-robot me-1 text-primary"></i> AI Edit Studio
        </a>
        <button type="button" class="btn btn-primary rounded-pill px-3 shadow-sm" onclick="openNewTemplate()">
            <i class="bi bi-plus-lg me-1"></i> Add Template
        </button>
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

<!-- Category Filter Pills -->
<div class="card p-3 border-0 rounded-4 shadow-sm mb-4 bg-light">
    <div class="d-flex align-items-center justify-content-between mb-2">
        <span class="small fw-bold text-secondary text-uppercase" style="font-size: 11px; letter-spacing: 0.5px;">
            <i class="bi bi-grid-fill me-1 text-primary"></i>Filter by Category (<?= count($templates) ?> templates found)
        </span>
        <span class="badge bg-primary rounded-pill px-2 py-1"><?= htmlspecialchars($selectedCategory) ?></span>
    </div>
    <div class="d-flex flex-wrap gap-1" style="max-height: 110px; overflow-y: auto;">
        <a href="templates.php?cat=All" class="btn btn-sm rounded-pill <?= $selectedCategory === 'All' ? 'btn-dark' : 'btn-outline-secondary' ?> py-1 px-3" style="font-size: 12px;">
            All (<?= Database::fetchOne("SELECT COUNT(*) as c FROM templates")['c'] ?? 0 ?>)
        </a>
        <?php foreach ($categories as $cat): ?>
            <?php 
                $count = Database::fetchOne("SELECT COUNT(*) as c FROM templates WHERE category = ?", [$cat])['c'] ?? 0;
            ?>
            <a href="templates.php?cat=<?= urlencode($cat) ?>" class="btn btn-sm rounded-pill <?= $selectedCategory === $cat ? 'btn-primary shadow-sm' : 'btn-outline-secondary' ?> py-1 px-2" style="font-size: 12px;">
                <?= htmlspecialchars($cat) ?> <span class="badge bg-white bg-opacity-25 ms-1"><?= $count ?></span>
            </a>
        <?php endforeach; ?>
    </div>
</div>

<div class="row g-3">
    <?php foreach ($templates as $t): ?>
    <div class="col-md-6 col-xl-4">
        <div class="pro-card p-3 h-100 d-flex flex-column">
            <!-- Preview Media Header -->
            <?php if (!empty($t['preview_video_url'])): ?>
                <div class="position-relative rounded-4 overflow-hidden mb-3 bg-black shadow-sm" style="height: 190px;">
                    <video src="<?= htmlspecialchars($t['preview_video_url']) ?>"
                           controls
                           preload="metadata"
                           playsinline
                           style="width: 100%; height: 100%; object-fit: cover;">
                    </video>
                    <span class="badge bg-black bg-opacity-75 position-absolute top-0 start-0 m-2 fw-semibold" style="pointer-events: none;">
                        <?= htmlspecialchars($t['aspect_ratio']) ?>
                    </span>
                    <div class="position-absolute top-0 end-0 m-2 d-flex gap-1" style="pointer-events: none;">
                        <?php if (!empty($t['badge'])): ?>
                            <span class="badge bg-info text-dark fw-bold"><?= htmlspecialchars($t['badge']) ?></span>
                        <?php endif; ?>
                        <?php if ($t['is_pro']): ?>
                            <span class="badge bg-warning text-dark fw-bold"><i class="bi bi-star-fill me-1"></i>PRO</span>
                        <?php endif; ?>
                    </div>
                </div>
            <?php elseif (!empty($t['preview_image_url'])): ?>
                <div class="position-relative rounded-4 overflow-hidden mb-3 bg-black shadow-sm" style="height: 190px;">
                    <img src="<?= htmlspecialchars($t['preview_image_url']) ?>" alt="Preview" style="width: 100%; height: 100%; object-fit: cover;">
                    <span class="badge bg-black bg-opacity-75 position-absolute top-0 start-0 m-2 fw-semibold"><?= htmlspecialchars($t['aspect_ratio']) ?></span>
                </div>
            <?php else: ?>
                <!-- Fallback Gradient Art -->
                <div class="rounded-4 p-3 text-white mb-3 position-relative overflow-hidden" style="height: 140px; background: linear-gradient(135deg, <?= str_replace('0xFF', '#', $t['preview_gradient_start']) ?>, <?= str_replace('0xFF', '#', $t['preview_gradient_end']) ?>);">
                    <div class="d-flex justify-content-between align-items-start">
                        <span class="badge bg-black bg-opacity-40 fw-semibold"><?= htmlspecialchars($t['aspect_ratio']) ?></span>
                        <?php if ($t['is_pro']): ?>
                            <span class="badge bg-warning text-dark fw-bold"><i class="bi bi-star-fill me-1"></i>PRO</span>
                        <?php endif; ?>
                    </div>
                    <div class="position-absolute bottom-0 start-0 p-3 w-100">
                        <h6 class="fw-bold mb-0 text-truncate text-white"><?= htmlspecialchars($t['title']) ?></h6>
                        <small class="text-white text-opacity-75" style="font-size: 11px;">By <?= htmlspecialchars($t['author']) ?></small>
                    </div>
                </div>
            <?php endif; ?>

            <div class="d-flex justify-content-between align-items-start mb-1">
                <div>
                    <span class="badge bg-primary bg-opacity-10 text-primary fw-semibold px-2 py-1 mb-1" style="font-size: 10.5px;">
                        <?= htmlspecialchars($t['category'] ?? 'Trending') ?>
                    </span>
                    <h6 class="fw-bold text-dark mb-0"><?= htmlspecialchars($t['title']) ?></h6>
                </div>
                <small class="text-muted text-nowrap" style="font-size: 11px;">#<?= (int)$t['display_order'] ?></small>
            </div>

            <p class="small text-muted mb-2" style="font-size: 12px; line-height: 1.35;"><?= htmlspecialchars($t['description']) ?></p>

            <!-- Video Editing Prompt Box -->
            <?php if (!empty($t['prompt'])): ?>
                <div class="mb-2 p-2 rounded-3 bg-light border" style="font-size: 11.5px; line-height: 1.35;">
                    <div class="d-flex justify-content-between align-items-center mb-1">
                        <span class="fw-bold text-primary" style="font-size: 10.5px;">
                            <i class="bi bi-stars me-1"></i>PROMPT
                        </span>
                        <button type="button" class="btn btn-link btn-sm text-decoration-none p-0 text-secondary" style="font-size: 11px;" onclick="copyTemplatePrompt(<?= json_encode($t['prompt']) ?>, this)">
                            <i class="bi bi-clipboard me-1"></i>Copy
                        </button>
                    </div>
                    <div class="text-dark font-monospace" style="display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">
                        <?= htmlspecialchars($t['prompt']) ?>
                    </div>
                </div>
            <?php endif; ?>

            <!-- Badges Bar -->
            <div class="d-flex flex-wrap gap-1 mb-2">
                <?php if ($t['is_trending']): ?>
                    <span class="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25" style="font-size: 10px;">🔥 Trending</span>
                <?php endif; ?>
                <?php if ($t['is_new']): ?>
                    <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25" style="font-size: 10px;">✨ New</span>
                <?php endif; ?>
                <?php if ($t['is_popular']): ?>
                    <span class="badge bg-warning bg-opacity-10 text-dark border border-warning border-opacity-25" style="font-size: 10px;">⭐ Popular</span>
                <?php endif; ?>
                <?php if (!empty($t['project_json'])): ?>
                    <span class="badge bg-dark bg-opacity-10 text-dark" style="font-size: 10px;"><i class="bi bi-file-earmark-code me-1"></i>Editable Project JSON</span>
                <?php endif; ?>
            </div>

            <div class="d-flex align-items-center gap-2 small text-secondary mt-auto mb-3" style="font-size: 11.5px;">
                <span><i class="bi bi-clock me-1"></i><?= round($t['duration_ms'] / 1000) ?>s</span>
                <span>•</span>
                <span><i class="bi bi-camera-reels me-1"></i><?= (int)$t['clips_count'] ?> clips</span>
                <span>•</span>
                <span class="text-truncate" style="max-width: 120px;"><i class="bi bi-music-note me-1"></i><?= htmlspecialchars($t['audio_title'] ?: 'Soundtrack') ?></span>
            </div>

            <div class="d-flex justify-content-between align-items-center pt-2 border-top">
                <form method="POST" action="" class="d-inline">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="id" value="<?= htmlspecialchars($t['id']) ?>">
                    <input type="hidden" name="action" value="toggle_enabled">
                    <?php if ($t['is_enabled']): ?>
                        <button type="submit" class="badge badge-soft-success border-0 px-2 py-1">Active</button>
                    <?php else: ?>
                        <button type="submit" class="badge badge-soft-danger border-0 px-2 py-1">Hidden</button>
                    <?php endif; ?>
                </form>

                <div class="d-flex gap-1">
                    <button class="btn btn-sm btn-outline-primary py-1 px-2" onclick='editTemplate(<?= json_encode($t) ?>)'><i class="bi bi-pencil"></i></button>
                    <form method="POST" action="" onsubmit="return confirm('Delete this template?');">
                        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                        <input type="hidden" name="id" value="<?= htmlspecialchars($t['id']) ?>">
                        <input type="hidden" name="action" value="delete_template">
                        <button type="submit" class="btn btn-sm btn-outline-danger py-1 px-2"><i class="bi bi-trash3"></i></button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <?php endforeach; ?>
</div>

<!-- Template Modal -->
<div class="modal fade" id="templateModal" tabindex="-1">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow-lg overflow-hidden">
            <div class="modal-header border-bottom bg-light py-3">
                <h5 class="modal-title fw-bold" id="tModalTitle">Template Details</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="" enctype="multipart/form-data">
                <div class="modal-body p-4" style="max-height: 75vh; overflow-y: auto;">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_template">
                    <input type="hidden" name="id" id="tId" value="">

                    <div class="row g-2 mb-3">
                        <div class="col-md-7">
                            <label class="form-label small fw-semibold">Template Title <span class="text-danger">*</span></label>
                            <input type="text" name="title" id="tTitle" class="form-control" required placeholder="e.g. 🎉 Birthday Celebration Highlights">
                        </div>
                        <div class="col-md-5">
                            <label class="form-label small fw-semibold">Category <span class="text-danger">*</span></label>
                            <select name="category" id="tCategory" class="form-select">
                                <?php foreach ($categories as $c): ?>
                                    <option value="<?= htmlspecialchars($c) ?>"><?= htmlspecialchars($c) ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Badge Text</label>
                            <input type="text" name="badge" id="tBadge" class="form-control" placeholder="e.g. Romantic, Viral, Bass Drop">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Author</label>
                            <input type="text" name="author" id="tAuthor" class="form-control" value="ProCut Originals">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Display Order</label>
                            <input type="number" name="display_order" id="tOrder" class="form-control" value="1">
                        </div>
                    </div>

                    <!-- Video Editing Prompt Section -->
                    <div class="mb-3">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                            <label class="form-label small fw-semibold mb-0">Video Editing Prompt / AI Script</label>
                            <span class="text-muted small" style="font-size: 11px;">Prompt used to generate or direct this video edit</span>
                        </div>
                        <textarea name="prompt" id="tPrompt" class="form-control font-monospace" rows="2" placeholder="e.g. Ultra high-end luxury cinematic wedding teaser film..."></textarea>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Description</label>
                        <textarea name="description" id="tDesc" class="form-control" rows="2" placeholder="Describe the mood, transitions and style..."></textarea>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Aspect Ratio</label>
                            <select name="aspect_ratio" id="tRatio" class="form-select">
                                <option value="ratio9_16">9:16 (TikTok / Reels / Shorts)</option>
                                <option value="ratio16_9">16:9 (YouTube Widescreen)</option>
                                <option value="ratio1_1">1:1 (Square)</option>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Duration (ms)</label>
                            <input type="number" name="duration_ms" id="tDuration" class="form-control" value="10000" step="500">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Clips Required (Slots)</label>
                            <input type="number" name="clips_count" id="tClips" class="form-control" value="4" min="1" max="50">
                        </div>
                    </div>

                    <!-- Video Preview Asset Section with Live Video Player -->
                    <div class="card p-3 bg-light border-0 rounded-3 mb-3">
                        <h6 class="fw-bold small mb-2 text-uppercase text-secondary">
                            <i class="bi bi-camera-reels me-1"></i>Template Video Preview Asset
                        </h6>
                        <div class="row g-3 align-items-center">
                            <div class="col-md-7">
                                <label class="form-label small fw-semibold">Preview Video URL / Server Path</label>
                                <input type="text" name="preview_video_url" id="tVideoUrl" class="form-control form-control-sm" placeholder="/media/templates/urban_skate.mp4" oninput="updateModalTmplVideo(this.value)">
                                <div class="mt-2">
                                    <label class="form-label small text-muted mb-1">Or Upload New Video (.mp4, .mov, .webm):</label>
                                    <input type="file" name="preview_video_file" class="form-control form-control-sm" accept="video/*" onchange="previewTmplUploadedVideo(this)">
                                </div>
                            </div>
                            <div class="col-md-5 text-center">
                                <div class="border rounded-3 bg-black p-1 shadow-sm d-inline-block" style="width: 160px; height: 110px;">
                                    <video id="tModalVideoPreview" controls playsinline class="w-100 h-100 rounded-2" style="object-fit: cover; display: none;"></video>
                                    <div id="tModalVideoPlaceholder" class="w-100 h-100 d-flex flex-column align-items-center justify-content-center text-secondary small">
                                        <i class="bi bi-play-circle fs-3"></i>
                                        <span style="font-size: 10px;">Video Player Preview</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Preview Image Asset Section -->
                    <div class="row g-2 mb-3">
                        <div class="col-md-7">
                            <label class="form-label small fw-semibold">Preview Image URL / Path</label>
                            <input type="text" name="preview_image_url" id="tImageUrl" class="form-control" placeholder="/media/templates/tmpl-golden-hour.jpg">
                        </div>
                        <div class="col-md-5">
                            <label class="form-label small fw-semibold">Or Upload Preview Image</label>
                            <input type="file" name="preview_image_file" class="form-control" accept="image/*">
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Soundtrack Audio URL / Path</label>
                            <input type="text" name="audio_url" id="tAudioUrl" class="form-control" placeholder="/media/templates/phonk_beat.wav">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Audio Title</label>
                            <input type="text" name="audio_title" id="tAudio" class="form-control" placeholder="Song / Sound title">
                        </div>
                    </div>

                    <!-- Project Definition JSON -->
                    <div class="mb-3">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                            <label class="form-label small fw-semibold mb-0">
                                <i class="bi bi-code-square me-1 text-primary"></i>Editable Project JSON (Timeline, Clips, Text, Audio)
                            </label>
                            <span class="text-muted small" style="font-size: 11px;">ProjectModel definition downloaded by ProCut</span>
                        </div>
                        <textarea name="project_json" id="tProjectJson" class="form-control font-monospace" rows="4" style="font-size: 11.5px;" placeholder='{"id":"tmpl-1","aspectRatio":"ratio9_16","videoClips":[...],"textOverlays":[...]}'></textarea>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-12">
                            <label class="form-label small fw-semibold">Tags (comma separated)</label>
                            <input type="text" name="tags" id="tTags" class="form-control" placeholder="Birthday, Party, Celebration, Confetti">
                        </div>
                    </div>

                    <!-- Highlight Badges & Toggles -->
                    <div class="card p-3 bg-light border-0 rounded-3 mb-2">
                        <div class="row g-3">
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" name="is_trending" id="tTrending" value="1">
                                    <label class="form-check-label small fw-semibold" for="tTrending">🔥 Trending</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" name="is_new" id="tNew" value="1">
                                    <label class="form-check-label small fw-semibold" for="tNew">✨ New</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" name="is_popular" id="tPopular" value="1">
                                    <label class="form-check-label small fw-semibold" for="tPopular">⭐ Popular</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" name="is_pro" id="tPro" value="1">
                                    <label class="form-check-label small fw-semibold" for="tPro">👑 PRO Only</label>
                                </div>
                            </div>
                            <div class="col-12 mt-2 pt-2 border-top">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" name="is_enabled" id="tEnabled" value="1" checked>
                                    <label class="form-check-label small fw-bold text-success" for="tEnabled">Active in ProCut App Feed</label>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top bg-light py-2 px-4">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-3" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary rounded-pill px-4 shadow-sm">Save Template</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function updateModalTmplVideo(url) {
    const vid = document.getElementById('tModalVideoPreview');
    const ph = document.getElementById('tModalVideoPlaceholder');
    if (url && url.trim() !== '') {
        vid.src = url;
        vid.style.display = 'block';
        ph.style.display = 'none';
        vid.load();
    } else {
        vid.style.display = 'none';
        ph.style.display = 'flex';
    }
}

function previewTmplUploadedVideo(input) {
    if (input.files && input.files[0]) {
        const fileUrl = URL.createObjectURL(input.files[0]);
        updateModalTmplVideo(fileUrl);
    }
}

function copyTemplatePrompt(text, btn) {
    if (!text) return;
    navigator.clipboard.writeText(text).then(function() {
        const orig = btn.innerHTML;
        btn.innerHTML = '<i class="bi bi-check2 me-1 text-success"></i><span class="text-success fw-bold">Copied</span>';
        setTimeout(() => { btn.innerHTML = orig; }, 2000);
    }).catch(function() {
        alert('Prompt copied: ' + text);
    });
}

function openNewTemplate() {
    document.getElementById('tModalTitle').innerText = 'Create New Template';
    document.getElementById('tId').value = '';
    document.getElementById('tTitle').value = '';
    document.getElementById('tCategory').value = 'Trending';
    document.getElementById('tBadge').value = 'Trending';
    document.getElementById('tPrompt').value = '';
    document.getElementById('tAuthor').value = 'ProCut Originals';
    document.getElementById('tDesc').value = '';
    document.getElementById('tRatio').value = 'ratio9_16';
    document.getElementById('tDuration').value = '10000';
    document.getElementById('tClips').value = '4';
    document.getElementById('tGradStart').value = '0xFF7C3AED';
    document.getElementById('tGradEnd').value = '0xFFEC4899';
    document.getElementById('tVideoUrl').value = '/media/templates/urban_skate.mp4';
    document.getElementById('tImageUrl').value = '/media/templates/tmpl-golden-hour.jpg';
    document.getElementById('tAudioUrl').value = '/media/templates/phonk_beat.wav';
    document.getElementById('tAudio').value = 'Soundtrack';
    document.getElementById('tProjectJson').value = '';
    document.getElementById('tTags').value = 'Trending, Viral';
    document.getElementById('tOrder').value = '1';
    document.getElementById('tTrending').checked = false;
    document.getElementById('tNew').checked = true;
    document.getElementById('tPopular').checked = false;
    document.getElementById('tPro').checked = false;
    document.getElementById('tEnabled').checked = true;
    updateModalTmplVideo('/media/templates/urban_skate.mp4');
    new bootstrap.Modal(document.getElementById('templateModal')).show();
}

function editTemplate(t) {
    document.getElementById('tModalTitle').innerText = 'Edit Template: ' + t.title;
    document.getElementById('tId').value = t.id;
    document.getElementById('tTitle').value = t.title;
    document.getElementById('tCategory').value = t.category || 'Trending';
    document.getElementById('tBadge').value = t.badge || '';
    document.getElementById('tPrompt').value = t.prompt || '';
    document.getElementById('tAuthor').value = t.author;
    document.getElementById('tDesc').value = t.description || '';
    document.getElementById('tRatio').value = t.aspect_ratio || 'ratio9_16';
    document.getElementById('tDuration').value = t.duration_ms || 10000;
    document.getElementById('tClips').value = t.clips_count || 4;
    document.getElementById('tGradStart').value = t.preview_gradient_start || '0xFF7C3AED';
    document.getElementById('tGradEnd').value = t.preview_gradient_end || '0xFFEC4899';
    document.getElementById('tVideoUrl').value = t.preview_video_url || '';
    document.getElementById('tImageUrl').value = t.preview_image_url || '';
    document.getElementById('tAudioUrl').value = t.audio_url || '';
    document.getElementById('tAudio').value = t.audio_title || '';
    document.getElementById('tProjectJson').value = t.project_json || '';
    document.getElementById('tTags').value = t.tags || '';
    document.getElementById('tOrder').value = t.display_order || 1;
    document.getElementById('tTrending').checked = t.is_trending == 1;
    document.getElementById('tNew').checked = t.is_new == 1;
    document.getElementById('tPopular').checked = t.is_popular == 1;
    document.getElementById('tPro').checked = t.is_pro == 1;
    document.getElementById('tEnabled').checked = t.is_enabled == 1;
    updateModalTmplVideo(t.preview_video_url || '');
    new bootstrap.Modal(document.getElementById('templateModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
