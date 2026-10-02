<?php
$pageTitle = 'Music Library';
require_once __DIR__ . '/includes/auth_check.php';
require_once __DIR__ . '/../helpers/uploader.php';

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $action = $_POST['action'] ?? '';

        if ($action === 'toggle_enabled') {
            $id = trim($_POST['id'] ?? '');
            $m = Database::fetchOne("SELECT * FROM music WHERE id = ?", [$id]);
            if ($m) {
                $newVal = $m['is_enabled'] ? 0 : 1;
                Database::query("UPDATE music SET is_enabled = ?, updated_at = NOW() WHERE id = ?", [$newVal, $id]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'music_toggled', "Toggled track {$id}");
                $success = "Track visibility updated.";
            }
        } elseif ($action === 'save_music') {
            $id = trim($_POST['id'] ?? '');
            $isNew = empty($id);
            if ($isNew) {
                $id = 'mus-' . bin2hex(random_bytes(6));
            }
            $title = trim($_POST['title'] ?? '');
            $artist = trim($_POST['artist'] ?? 'ProCut Sound');
            $category = trim($_POST['category'] ?? 'Upbeat');
            $durationMs = (int)($_POST['duration_ms'] ?? 60000);
            $audioUrl = trim($_POST['audio_url'] ?? '');
            $isPro = isset($_POST['is_pro']) ? 1 : 0;
            $enabled = isset($_POST['is_enabled']) ? 1 : 0;
            $order = (int)($_POST['display_order'] ?? 1);

            // Handle file upload if provided
            if (!empty($_FILES['audio_file']['name'])) {
                $allowed = ['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/aac', 'audio/ogg'];
                $upload = Uploader::uploadFile($_FILES['audio_file'], MUSIC_UPLOAD_DIR, $allowed, 31457280);
                if ($upload['success']) {
                    $audioUrl = $upload['web_url'];
                } else {
                    $error = $upload['error'];
                }
            }

            if (empty($error)) {
                if (empty($title) || empty($audioUrl)) {
                    $error = 'Track title and audio URL / uploaded file are required.';
                } else {
                    if ($isNew) {
                        Database::query(
                            "INSERT INTO music (id, title, artist, category, duration_ms, audio_url, is_pro, is_enabled, display_order)
                             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                            [$id, $title, $artist, $category, $durationMs, $audioUrl, $isPro, $enabled, $order]
                        );
                        Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'music_created', "Added track {$title} ({$id})");
                        $success = "Music track published.";
                    } else {
                        Database::query(
                            "UPDATE music SET title = ?, artist = ?, category = ?, duration_ms = ?, audio_url = ?, is_pro = ?, is_enabled = ?, display_order = ?, updated_at = NOW()
                             WHERE id = ?",
                            [$title, $artist, $category, $durationMs, $audioUrl, $isPro, $enabled, $order, $id]
                        );
                        Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'music_updated', "Updated track {$id}");
                        $success = "Music track updated.";
                    }
                }
            }
        } elseif ($action === 'delete_music') {
            $id = trim($_POST['id'] ?? '');
            Database::query("DELETE FROM music WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'music_deleted', "Deleted track {$id}");
            $success = "Track deleted.";
        }
    }
}

$musicList = Database::fetchAll("SELECT * FROM music ORDER BY display_order ASC");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Royalty-Free Music Library</h3>
        <p class="text-muted small mb-0">Manage background audio tracks, MP3 audio uploads, genres, and durations.</p>
    </div>
    <button type="button" class="btn btn-primary rounded-pill px-3" onclick="openNewMusic()">
        <i class="bi bi-plus-lg me-1"></i> Add Audio Track
    </button>
</div>

<?php if (!empty($error)): ?>
    <div class="alert alert-danger py-2 px-3 small mb-3"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if (!empty($success)): ?>
    <div class="alert alert-success py-2 px-3 small mb-3"><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<div class="pro-card p-4">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead>
                <tr>
                    <th style="width: 70px;">Order</th>
                    <th>Track & Artist</th>
                    <th>Category</th>
                    <th>Duration</th>
                    <th>Preview</th>
                    <th>Tier</th>
                    <th>Status</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($musicList as $m): ?>
                <tr>
                    <td>
                        <span class="badge bg-light text-dark border fw-bold"><?= (int)$m['display_order'] ?></span>
                    </td>
                    <td>
                        <div class="fw-bold text-dark d-flex align-items-center gap-2">
                            <i class="bi bi-music-note-beamed text-primary"></i>
                            <?= htmlspecialchars($m['title']) ?>
                        </div>
                        <small class="text-muted">By <?= htmlspecialchars($m['artist']) ?></small>
                    </td>
                    <td>
                        <span class="badge badge-soft-info"><?= htmlspecialchars($m['category']) ?></span>
                    </td>
                    <td class="small fw-semibold">
                        <?= floor($m['duration_ms'] / 60000) ?>:<?= sprintf('%02d', floor(($m['duration_ms'] % 60000) / 1000)) ?>
                    </td>
                    <td>
                        <?php if (!empty($m['audio_url'])): ?>
                            <audio controls style="height: 30px; width: 180px;">
                                <source src="<?= htmlspecialchars($m['audio_url']) ?>">
                            </audio>
                        <?php else: ?>
                            <span class="text-muted small">No file</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <?php if ($m['is_pro']): ?>
                            <span class="badge bg-warning text-dark fw-bold">PRO</span>
                        <?php else: ?>
                            <span class="badge bg-light text-muted border">Free</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <form method="POST" action="" class="d-inline">
                            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                            <input type="hidden" name="id" value="<?= htmlspecialchars($m['id']) ?>">
                            <input type="hidden" name="action" value="toggle_enabled">
                            <?php if ($m['is_enabled']): ?>
                                <button type="submit" class="badge badge-soft-success border-0 px-2 py-1">Active</button>
                            <?php else: ?>
                                <button type="submit" class="badge badge-soft-danger border-0 px-2 py-1">Hidden</button>
                            <?php endif; ?>
                        </form>
                    </td>
                    <td class="text-end">
                        <div class="d-flex justify-content-end gap-1">
                            <button class="btn btn-sm btn-outline-primary py-1 px-2" onclick='editMusic(<?= json_encode($m) ?>)'><i class="bi bi-pencil"></i></button>
                            <form method="POST" action="" onsubmit="return confirm('Delete this track?');">
                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                <input type="hidden" name="id" value="<?= htmlspecialchars($m['id']) ?>">
                                <input type="hidden" name="action" value="delete_music">
                                <button type="submit" class="btn btn-sm btn-outline-danger py-1 px-2"><i class="bi bi-trash3"></i></button>
                            </form>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Music -->
<div class="modal fade" id="musicModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold" id="mModalTitle">Configure Track</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="" enctype="multipart/form-data">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="save_music">
                    <input type="hidden" name="id" id="mId" value="">

                    <div class="row g-2 mb-3">
                        <div class="col-md-7">
                            <label class="form-label small fw-semibold">Track Title</label>
                            <input type="text" name="title" id="mTitle" class="form-control" required>
                        </div>
                        <div class="col-md-5">
                            <label class="form-label small fw-semibold">Artist / Band</label>
                            <input type="text" name="artist" id="mArtist" class="form-control" required>
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Genre / Category</label>
                            <select name="category" id="mCategory" class="form-select">
                                <option value="Phonk">Phonk</option>
                                <option value="Vlog">Vlog / Acoustic</option>
                                <option value="Electronic">Electronic / Synth</option>
                                <option value="Lo-Fi">Lo-Fi Chill</option>
                                <option value="Cinematic">Cinematic</option>
                                <option value="Hip-Hop">Hip-Hop / Trap</option>
                                <option value="Upbeat">Upbeat Pop</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Duration (ms)</label>
                            <input type="number" name="duration_ms" id="mDur" class="form-control" value="60000" step="1000">
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Upload Audio File (MP3 / WAV)</label>
                        <input type="file" name="audio_file" class="form-control" accept="audio/*">
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Or Direct Audio Asset URL</label>
                        <input type="text" name="audio_url" id="mUrl" class="form-control" placeholder="assets/demo/track.mp3 or https://...">
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold">Display Order</label>
                            <input type="number" name="display_order" id="mOrder" class="form-control" value="1">
                        </div>
                        <div class="col-md-6 d-flex align-items-center mt-3 gap-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" name="is_pro" id="mPro" value="1">
                                <label class="form-check-label fw-semibold small" for="mPro">Requires PRO</label>
                            </div>
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" name="is_enabled" id="mEnabled" value="1" checked>
                                <label class="form-check-label fw-semibold small" for="mEnabled">Active</label>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Track</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function openNewMusic() {
    document.getElementById('mModalTitle').innerText = 'Add Audio Track';
    document.getElementById('mId').value = '';
    document.getElementById('mTitle').value = '';
    document.getElementById('mArtist').value = 'ProCut Sound';
    document.getElementById('mCategory').value = 'Phonk';
    document.getElementById('mDur').value = '120000';
    document.getElementById('mUrl').value = 'assets/demo/phonk_beat.mp3';
    document.getElementById('mOrder').value = '1';
    document.getElementById('mPro').checked = false;
    document.getElementById('mEnabled').checked = true;
    new bootstrap.Modal(document.getElementById('musicModal')).show();
}

function editMusic(m) {
    document.getElementById('mModalTitle').innerText = 'Edit Track';
    document.getElementById('mId').value = m.id;
    document.getElementById('mTitle').value = m.title;
    document.getElementById('mArtist').value = m.artist;
    document.getElementById('mCategory').value = m.category;
    document.getElementById('mDur').value = m.duration_ms;
    document.getElementById('mUrl').value = m.audio_url;
    document.getElementById('mOrder').value = m.display_order;
    document.getElementById('mPro').checked = m.is_pro == 1;
    document.getElementById('mEnabled').checked = m.is_enabled == 1;
    new bootstrap.Modal(document.getElementById('musicModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
