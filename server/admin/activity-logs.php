<?php
$pageTitle = 'Activity & Audit Logs';
require_once __DIR__ . '/includes/auth_check.php';

$search = trim($_GET['search'] ?? '');
$actorType = $_GET['actor_type'] ?? '';

$sql = "SELECT * FROM activity_logs WHERE 1=1";
$params = [];

if (!empty($search)) {
    $sql .= " AND (LOWER(actor_name) LIKE ? OR LOWER(action) LIKE ? OR LOWER(details) LIKE ? OR ip_address LIKE ?)";
    $like = '%' . strtolower($search) . '%';
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

if (!empty($actorType)) {
    $sql .= " AND actor_type = ?";
    $params[] = $actorType;
}

$sql .= " ORDER BY created_at DESC LIMIT 150";
$logs = Database::fetchAll($sql, $params);

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">Audit & Activity Logs</h3>
        <p class="text-muted small mb-0">Complete historical security trail of logins, administrative changes, and user operations.</p>
    </div>
</div>

<!-- Search & Filter -->
<div class="pro-card p-3 mb-4">
    <form method="GET" class="row g-2 align-items-center">
        <div class="col-md-7">
            <div class="input-group">
                <span class="input-group-text bg-light border-end-0"><i class="bi bi-search text-muted"></i></span>
                <input type="text" name="search" class="form-control border-start-0" placeholder="Search by actor name, action, or IP..." value="<?= htmlspecialchars($search) ?>">
            </div>
        </div>
        <div class="col-md-3">
            <select name="actor_type" class="form-select" onchange="this.form.submit()">
                <option value="">All Actors (Admin, User, System)</option>
                <option value="admin" <?= $actorType === 'admin' ? 'selected' : '' ?>>Admin Actions</option>
                <option value="user" <?= $actorType === 'user' ? 'selected' : '' ?>>User Actions</option>
                <option value="system" <?= $actorType === 'system' ? 'selected' : '' ?>>System Security</option>
            </select>
        </div>
        <div class="col-md-2 d-flex gap-2">
            <button type="submit" class="btn btn-primary w-100">Filter</button>
            <?php if (!empty($search) || !empty($actorType)): ?>
                <a href="activity-logs.php" class="btn btn-outline-secondary"><i class="bi bi-x-lg"></i></a>
            <?php endif; ?>
        </div>
    </form>
</div>

<!-- Logs Table -->
<div class="pro-card overflow-hidden">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead>
                <tr>
                    <th style="width: 170px;">Timestamp</th>
                    <th>Actor</th>
                    <th>Action</th>
                    <th>Details</th>
                    <th>IP Address & Client</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($logs)): ?>
                    <tr>
                        <td colspan="5" class="text-center py-5 text-muted">
                            <i class="bi bi-journal-x fs-1 d-block mb-2 text-secondary"></i>
                            No activity records found matching filters.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($logs as $l): ?>
                    <tr>
                        <td class="small text-muted text-nowrap">
                            <?= date('M d, Y H:i:s', strtotime($l['created_at'])) ?>
                        </td>
                        <td>
                            <div class="d-flex align-items-center gap-2">
                                <?php if ($l['actor_type'] === 'admin'): ?>
                                    <span class="badge badge-soft-primary"><i class="bi bi-shield-fill me-1"></i>Admin</span>
                                <?php elseif ($l['actor_type'] === 'user'): ?>
                                    <span class="badge badge-soft-success"><i class="bi bi-person-fill me-1"></i>User</span>
                                <?php else: ?>
                                    <span class="badge badge-soft-warning"><i class="bi bi-gear-fill me-1"></i>System</span>
                                <?php endif; ?>
                                <span class="fw-semibold text-dark small"><?= htmlspecialchars($l['actor_name']) ?></span>
                            </div>
                        </td>
                        <td>
                            <span class="badge bg-light text-dark border"><?= htmlspecialchars($l['action']) ?></span>
                        </td>
                        <td class="small text-muted" style="max-width: 320px; word-break: break-word;">
                            <?= htmlspecialchars($l['details'] ?? '—') ?>
                        </td>
                        <td class="small text-muted">
                            <code><?= htmlspecialchars($l['ip_address'] ?? '127.0.0.1') ?></code>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
