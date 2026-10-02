<?php
$pageTitle = 'Cloud Projects';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

// Handle Delete Project
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $action = $_POST['action'] ?? '';
        $projectId = trim($_POST['project_id'] ?? '');

        if ($action === 'delete_project' && !empty($projectId)) {
            $proj = Database::fetchOne("SELECT * FROM projects WHERE id = ?", [$projectId]);
            if ($proj) {
                Database::query("DELETE FROM projects WHERE id = ?", [$projectId]);
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'project_deleted_by_admin', "Admin deleted project {$proj['title']} ({$projectId}) owned by {$proj['user_email']}");
                $success = "Project permanently deleted.";
            } else {
                $error = "Project not found.";
            }
        }
    }
}

// Search
$search = trim($_GET['search'] ?? '');
$sql = "SELECT p.*, u.display_name FROM projects p LEFT JOIN users u ON p.user_id = u.id WHERE 1=1";
$params = [];

if (!empty($search)) {
    $sql .= " AND (LOWER(p.title) LIKE ? OR p.id LIKE ? OR LOWER(p.user_email) LIKE ? OR p.user_id LIKE ?)";
    $like = '%' . strtolower($search) . '%';
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

$sql .= " ORDER BY p.updated_at DESC";
$projects = Database::fetchAll($sql, $params);

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">User Cloud Projects</h3>
        <p class="text-muted small mb-0">Browse user video timelines, inspect project tracks and clips, and manage storage.</p>
    </div>
</div>

<?php if (!empty($error)): ?>
    <div class="alert alert-danger py-2 px-3 small mb-3"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if (!empty($success)): ?>
    <div class="alert alert-success py-2 px-3 small mb-3"><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<!-- Search Bar -->
<div class="pro-card p-3 mb-4">
    <form method="GET" class="row g-2 align-items-center">
        <div class="col-md-9">
            <div class="input-group">
                <span class="input-group-text bg-light border-end-0"><i class="bi bi-search text-muted"></i></span>
                <input type="text" name="search" class="form-control border-start-0" placeholder="Search by project title, ID, creator email or user ID..." value="<?= htmlspecialchars($search) ?>">
            </div>
        </div>
        <div class="col-md-3 d-flex gap-2">
            <button type="submit" class="btn btn-primary w-100">Search</button>
            <?php if (!empty($search)): ?>
                <a href="projects.php" class="btn btn-outline-secondary"><i class="bi bi-x-lg"></i></a>
            <?php endif; ?>
        </div>
    </form>
</div>

<!-- Projects Table -->
<div class="pro-card p-3">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead>
                <tr>
                    <th style="width: 28%;">Project Title</th>
                    <th style="width: 24%;">Creator</th>
                    <th style="width: 20%;">Video Specs & Ratio</th>
                    <th style="width: 14%;">Last Synced</th>
                    <th style="width: 14%;" class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($projects)): ?>
                    <tr>
                        <td colspan="5" class="text-center py-5 text-muted">
                            <i class="bi bi-folder-x fs-1 d-block mb-2 text-secondary"></i>
                            No cloud projects found.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($projects as $p): 
                        $payloadSize = strlen($p['project_json']);
                        $sizeKb = round($payloadSize / 1024, 1);
                    ?>
                    <tr>
                        <td>
                            <div class="fw-bold text-dark text-truncate" style="max-width: 260px;" title="<?= htmlspecialchars($p['title']) ?>"><?= htmlspecialchars($p['title']) ?></div>
                            <code class="text-muted" style="font-size: 11px;"><?= htmlspecialchars($p['id']) ?></code>
                        </td>
                        <td>
                            <div class="small fw-semibold text-truncate" style="max-width: 220px;"><?= htmlspecialchars($p['display_name'] ?: 'Creator') ?></div>
                            <div class="text-muted text-truncate" style="font-size: 11px; max-width: 220px;"><?= htmlspecialchars($p['user_email']) ?></div>
                        </td>
                        <td>
                            <div class="d-flex align-items-center gap-1 mb-1">
                                <span class="badge badge-soft-primary"><?= htmlspecialchars($p['aspect_ratio'] ?: 'ratio9_16') ?></span>
                                <span class="small fw-semibold text-dark"><?= round(($p['duration_ms'] ?? 0) / 1000, 1) ?>s</span>
                                <span class="text-muted small">@ <?= (int)$p['fps'] ?>fps</span>
                            </div>
                            <span class="text-muted small" style="font-size: 11px;"><i class="bi bi-hdd me-1"></i><?= $sizeKb ?> KB</span>
                        </td>
                        <td class="small text-muted">
                            <div class="text-dark fw-semibold"><?= date('M d, Y', strtotime($p['updated_at'])) ?></div>
                            <div style="font-size: 11px;"><?= date('H:i', strtotime($p['updated_at'])) ?></div>
                        </td>
                        <td class="text-end">
                            <div class="d-flex justify-content-end align-items-center gap-1">
                                <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 rounded-2" title="Inspect Timeline JSON" onclick='previewProject(<?= json_encode($p['id']) ?>, <?= json_encode($p['title']) ?>, <?= json_encode($p['project_json']) ?>)'>
                                    <i class="bi bi-filetype-json me-1"></i>Inspect
                                </button>
                                <form method="POST" action="" onsubmit="return confirm('Permanently delete this project from the user\'s cloud space?');" class="d-inline mb-0">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                    <input type="hidden" name="project_id" value="<?= htmlspecialchars($p['id']) ?>">
                                    <input type="hidden" name="action" value="delete_project">
                                    <button type="submit" class="btn btn-sm btn-outline-danger py-1 px-2 rounded-2" title="Delete Project">
                                        <i class="bi bi-trash3"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Project JSON Inspector Modal -->
<div class="modal fade" id="inspectModal" tabindex="-1">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <div>
                    <h5 class="modal-title fw-bold" id="modalProjectTitle">Project Timeline Structure</h5>
                    <code class="small text-muted" id="modalProjectId"></code>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body bg-dark text-light p-3">
                <pre class="mb-0 text-success" style="font-size: 12px; font-family: monospace; white-space: pre-wrap; word-break: break-all;" id="modalJsonContent"></pre>
            </div>
            <div class="modal-footer border-top">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary" onclick="copyJson()">Copy Raw JSON</button>
            </div>
        </div>
    </div>
</div>

<script>
let currentJson = '';
function previewProject(id, title, jsonStr) {
    document.getElementById('modalProjectId').innerText = id;
    document.getElementById('modalProjectTitle').innerText = title;
    currentJson = jsonStr;
    try {
        const parsed = JSON.parse(jsonStr);
        document.getElementById('modalJsonContent').innerText = JSON.stringify(parsed, null, 2);
    } catch(e) {
        document.getElementById('modalJsonContent').innerText = jsonStr;
    }
    new bootstrap.Modal(document.getElementById('inspectModal')).show();
}

function copyJson() {
    navigator.clipboard.writeText(currentJson).then(() => {
        alert('Project JSON copied to clipboard!');
    });
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
