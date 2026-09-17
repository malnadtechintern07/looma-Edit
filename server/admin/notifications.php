<?php
$pageTitle = 'In-App Notifications';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $action = $_POST['action'] ?? '';
        
        if ($action === 'create_notification') {
            $title = trim($_POST['title'] ?? '');
            $message = trim($_POST['message'] ?? '');
            $type = trim($_POST['type'] ?? 'info');
            $targetUserId = trim($_POST['target_user_id'] ?? '');

            if (empty($title) || empty($message)) {
                $error = 'Title and message are required.';
            } else {
                Database::query(
                    "INSERT INTO notifications (title, message, type, target_user_id, is_active)
                     VALUES (?, ?, ?, ?, 1)",
                    [$title, $message, $type, !empty($targetUserId) ? $targetUserId : null]
                );
                $targetLabel = !empty($targetUserId) ? "user {$targetUserId}" : 'all users';
                Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'notification_sent', "Dispatched announcement '{$title}' to {$targetLabel}");
                $success = "Notification sent successfully to {$targetLabel}.";
            }
        } elseif ($action === 'delete_notification') {
            $id = (int)($_POST['id'] ?? 0);
            Database::query("DELETE FROM notifications WHERE id = ?", [$id]);
            Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'notification_deleted', "Deleted notification ID {$id}");
            $success = "Notification removed.";
        }
    }
}

$notifications = Database::fetchAll("SELECT * FROM notifications ORDER BY created_at DESC LIMIT 50");
$users = Database::fetchAll("SELECT id, email, display_name FROM users ORDER BY display_name ASC LIMIT 100");

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">In-App Notifications & Alerts</h3>
        <p class="text-muted small mb-0">Push broadcast notices, maintenance advisories, and targeted messages to mobile users.</p>
    </div>
    <button type="button" class="btn btn-primary rounded-pill px-3" data-bs-toggle="modal" data-bs-target="#newNotifModal">
        <i class="bi bi-send-fill me-1"></i> Send Announcement
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
                    <th>Type</th>
                    <th>Announcement</th>
                    <th>Target Audience</th>
                    <th>Dispatched Date</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($notifications)): ?>
                    <tr>
                        <td colspan="5" class="text-center py-5 text-muted">
                            <i class="bi bi-bell-slash fs-1 d-block mb-2 text-secondary"></i>
                            No notifications have been dispatched yet.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($notifications as $n): ?>
                    <tr>
                        <td>
                            <?php if ($n['type'] === 'announcement'): ?>
                                <span class="badge badge-soft-warning"><i class="bi bi-megaphone-fill me-1"></i>Announcement</span>
                            <?php elseif ($n['type'] === 'update'): ?>
                                <span class="badge badge-soft-primary"><i class="bi bi-arrow-repeat me-1"></i>Update</span>
                            <?php elseif ($n['type'] === 'promotion'): ?>
                                <span class="badge badge-soft-success"><i class="bi bi-gift-fill me-1"></i>Promo</span>
                            <?php else: ?>
                                <span class="badge badge-soft-info"><i class="bi bi-info-circle-fill me-1"></i>Info</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <div class="fw-bold text-dark"><?= htmlspecialchars($n['title']) ?></div>
                            <small class="text-muted text-truncate d-inline-block" style="max-width: 400px;"><?= htmlspecialchars($n['message']) ?></small>
                        </td>
                        <td>
                            <?php if (!empty($n['target_user_id'])): ?>
                                <span class="badge bg-light text-dark border">User: <?= htmlspecialchars($n['target_user_id']) ?></span>
                            <?php else: ?>
                                <span class="badge badge-soft-primary"><i class="bi bi-globe me-1"></i>All App Users</span>
                            <?php endif; ?>
                        </td>
                        <td class="small text-muted">
                            <?= date('M d, Y H:i', strtotime($n['created_at'])) ?>
                        </td>
                        <td class="text-end">
                            <form method="POST" action="" onsubmit="return confirm('Remove this notification?');">
                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                <input type="hidden" name="id" value="<?= (int)$n['id'] ?>">
                                <input type="hidden" name="action" value="delete_notification">
                                <button type="submit" class="btn btn-sm btn-outline-danger py-1 px-2 rounded-2">
                                    <i class="bi bi-trash3"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Send Notification Modal -->
<div class="modal fade" id="newNotifModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
                <h5 class="modal-title fw-bold">Dispatch In-App Notification</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                    <input type="hidden" name="action" value="create_notification">

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Target Audience</label>
                        <select name="target_user_id" class="form-select">
                            <option value="">Broadcast to All Users (Global)</option>
                            <?php foreach ($users as $usr): ?>
                                <option value="<?= htmlspecialchars($usr['id']) ?>">
                                    <?= htmlspecialchars($usr['display_name']) ?> (<?= htmlspecialchars($usr['email']) ?>)
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-8">
                            <label class="form-label small fw-semibold">Notification Title</label>
                            <input type="text" name="title" class="form-control" placeholder="e.g. New 4K AI Filters Released!" required>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-semibold">Type</label>
                            <select name="type" class="form-select">
                                <option value="announcement">Announcement</option>
                                <option value="info">Info</option>
                                <option value="update">Update</option>
                                <option value="promotion">Promo</option>
                            </select>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Message Body</label>
                        <textarea name="message" class="form-control" rows="3" placeholder="Compose message visible in app..." required></textarea>
                    </div>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary px-4"><i class="bi bi-send me-1"></i> Dispatch</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
