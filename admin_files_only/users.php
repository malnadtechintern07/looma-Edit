<?php
$pageTitle = 'Users Management';
require_once __DIR__ . '/includes/auth_check.php';

$error = '';
$success = '';

// Helper function to format how long the user has been using the app
function formatAppTenure($createdAt) {
    if (empty($createdAt)) return 'New Member';
    try {
        $created = new DateTime($createdAt);
        $now = new DateTime();
        $diff = $created->diff($now);

        $parts = [];
        if ($diff->y > 0) {
            $parts[] = $diff->y . ' ' . ($diff->y === 1 ? 'yr' : 'yrs');
        }
        if ($diff->m > 0) {
            $parts[] = $diff->m . ' ' . ($diff->m === 1 ? 'mo' : 'mos');
        }
        if ($diff->d > 0 && empty($parts)) {
            $parts[] = $diff->d . ' ' . ($diff->d === 1 ? 'day' : 'days');
        }
        if (empty($parts)) {
            if ($diff->h > 0) {
                return $diff->h . ' ' . ($diff->h === 1 ? 'hour' : 'hours');
            }
            return 'Joined today';
        }
        return implode(', ', $parts);
    } catch (\Exception $e) {
        return 'Active Member';
    }
}

// Helper function to format human-readable last active time
function formatLastSeen($datetime) {
    if (empty($datetime)) return 'Never logged in';
    $time = strtotime($datetime);
    if (!$time) return 'Never';
    $diff = time() - $time;
    if ($diff < 60) return 'Active just now';
    if ($diff < 3600) return floor($diff / 60) . ' mins ago';
    if ($diff < 86400) return floor($diff / 3600) . ' hrs ago';
    if ($diff < 172800) return 'Yesterday';
    if ($diff < 2592000) return floor($diff / 86400) . ' days ago';
    return date('M d, Y', $time);
}

// Handle Admin Actions (PRO status, Ban, Delete) - NO PASSWORD RESET
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token.';
    } else {
        $action = $_POST['action'] ?? '';
        $targetUserId = trim($_POST['user_id'] ?? '');

        if (!empty($targetUserId)) {
            $user = Database::fetchOne("SELECT * FROM users WHERE id = ?", [$targetUserId]);
            if ($user) {
                if ($action === 'toggle_pro') {
                    $newPro = $user['is_pro'] ? 0 : 1;
                    Database::query("UPDATE users SET is_pro = ?, updated_at = NOW() WHERE id = ?", [$newPro, $targetUserId]);
                    $label = $newPro ? 'Granted PRO' : 'Removed PRO';
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'user_tier_updated', "{$label} for {$user['email']}");
                    $success = "User PRO subscription status updated.";
                } elseif ($action === 'toggle_status') {
                    $newStatus = ($user['status'] === 'active') ? 'banned' : 'active';
                    Database::query("UPDATE users SET status = ?, updated_at = NOW() WHERE id = ?", [$newStatus, $targetUserId]);
                    if ($newStatus === 'banned') {
                        Database::query("DELETE FROM sessions WHERE user_id = ?", [$targetUserId]);
                    }
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'user_status_updated', "User {$user['email']} set to {$newStatus}");
                    $success = "User access status set to {$newStatus}.";
                } elseif ($action === 'delete_user') {
                    Database::query("DELETE FROM users WHERE id = ?", [$targetUserId]);
                    Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'], 'user_deleted', "Deleted user {$user['email']} ({$targetUserId})");
                    $success = "User permanently removed along with associated cloud projects.";
                }
            } else {
                $error = 'User not found.';
            }
        }
    }
}

// Search and Filter Queries
$search = trim($_GET['search'] ?? '');
$statusFilter = $_GET['status'] ?? '';
$tierFilter = $_GET['tier'] ?? '';

$sql = "SELECT u.*, (SELECT COUNT(*) FROM projects p WHERE p.user_id = u.id) as projects_count FROM users u WHERE 1=1";
$params = [];

if (!empty($search)) {
    $sql .= " AND (LOWER(u.email) LIKE ? OR LOWER(u.display_name) LIKE ? OR u.id LIKE ?)";
    $like = '%' . strtolower($search) . '%';
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

if (!empty($statusFilter)) {
    $sql .= " AND u.status = ?";
    $params[] = $statusFilter;
}

if ($tierFilter === 'pro') {
    $sql .= " AND u.is_pro = 1";
} elseif ($tierFilter === 'free') {
    $sql .= " AND u.is_pro = 0";
}

$sql .= " ORDER BY u.created_at DESC";
$users = Database::fetchAll($sql, $params);

// Calculate Aggregate Metrics
$totalCreators = count($users);
$totalProjectsBuilt = array_sum(array_column($users, 'projects_count'));

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">User Accounts & Creator Analytics</h3>
        <p class="text-muted small mb-0">Monitor registered mobile users, how long they've been using ProCut, and total cloud projects built.</p>
    </div>
    <div class="d-flex align-items-center gap-2">
        <span class="badge bg-primary-subtle text-primary border border-primary-subtle px-3 py-2 rounded-pill">
            <i class="bi bi-people-fill me-1"></i><?= $totalCreators ?> Creators
        </span>
        <span class="badge bg-success-subtle text-success border border-success-subtle px-3 py-2 rounded-pill">
            <i class="bi bi-film me-1"></i><?= $totalProjectsBuilt ?> Total Projects Built
        </span>
    </div>
</div>

<?php if (!empty($error)): ?>
    <div class="alert alert-danger py-2 px-3 small mb-3"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if (!empty($success)): ?>
    <div class="alert alert-success py-2 px-3 small mb-3"><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<!-- Search and Filter Bar -->
<div class="pro-card p-3 mb-4">
    <form method="GET" class="row g-2 align-items-center">
        <div class="col-12 col-md-5">
            <div class="input-group">
                <span class="input-group-text bg-light border-end-0"><i class="bi bi-search text-muted"></i></span>
                <input type="text" name="search" class="form-control border-start-0" placeholder="Search by name, email, or user ID..." value="<?= htmlspecialchars($search) ?>">
            </div>
        </div>
        <div class="col-6 col-md-3">
            <select name="status" class="form-select" onchange="this.form.submit()">
                <option value="">All Statuses</option>
                <option value="active" <?= $statusFilter === 'active' ? 'selected' : '' ?>>Active Users</option>
                <option value="banned" <?= $statusFilter === 'banned' ? 'selected' : '' ?>>Banned Users</option>
            </select>
        </div>
        <div class="col-6 col-md-2">
            <select name="tier" class="form-select" onchange="this.form.submit()">
                <option value="">All Tiers</option>
                <option value="pro" <?= $tierFilter === 'pro' ? 'selected' : '' ?>>PRO Creators</option>
                <option value="free" <?= $tierFilter === 'free' ? 'selected' : '' ?>>Free Tier</option>
            </select>
        </div>
        <div class="col-12 col-md-2 d-flex gap-2">
            <button type="submit" class="btn btn-primary w-100">Filter</button>
            <?php if (!empty($search) || !empty($statusFilter) || !empty($tierFilter)): ?>
                <a href="users.php" class="btn btn-outline-secondary" title="Clear Filters"><i class="bi bi-x-lg"></i></a>
            <?php endif; ?>
        </div>
    </form>
</div>

<!-- Users Table -->
<div class="pro-card overflow-hidden">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead>
                <tr>
                    <th>Creator Profile</th>
                    <th>Email & User ID</th>
                    <th>Time Using App</th>
                    <th>Projects Built</th>
                    <th>Tier</th>
                    <th>Status</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($users)): ?>
                    <tr>
                        <td colspan="7" class="text-center py-5 text-muted">
                            <i class="bi bi-people fs-1 d-block mb-2 text-secondary"></i>
                            No users found matching current filters.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($users as $u): 
                        $tenure = formatAppTenure($u['created_at']);
                        $lastSeen = formatLastSeen($u['last_login_at']);
                        $joinedDate = !empty($u['created_at']) ? date('M d, Y', strtotime($u['created_at'])) : 'Unknown';
                        $fullJoinedDate = !empty($u['created_at']) ? date('F d, Y \a\t h:i A', strtotime($u['created_at'])) : 'Unknown';
                        $fullLastSeen = !empty($u['last_login_at']) ? date('F d, Y \a\t h:i A', strtotime($u['last_login_at'])) : 'Never logged in';
                    ?>
                    <tr>
                        <td>
                            <div class="d-flex align-items-center gap-2">
                                <div class="rounded-circle bg-primary bg-opacity-10 text-primary d-flex align-items-center justify-content-center fw-bold flex-shrink-0" style="width: 40px; height: 40px;">
                                    <?= strtoupper(substr($u['display_name'] ?: 'U', 0, 1)) ?>
                                </div>
                                <div class="min-w-0">
                                    <div class="fw-bold text-dark text-truncate"><?= htmlspecialchars($u['display_name'] ?: 'ProCut Creator') ?></div>
                                    <small class="text-muted d-block"><?= htmlspecialchars($u['handle'] ?? '@creator') ?></small>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="small fw-semibold"><?= htmlspecialchars($u['email']) ?></div>
                            <code class="text-muted" style="font-size: 11px;"><?= htmlspecialchars($u['id']) ?></code>
                        </td>
                        <td>
                            <div class="fw-bold text-dark d-flex align-items-center gap-1">
                                <i class="bi bi-clock-history text-primary"></i>
                                <span><?= htmlspecialchars($tenure) ?></span>
                            </div>
                            <div class="text-muted small" style="font-size: 11.5px;">Since <?= $joinedDate ?></div>
                            <div class="text-muted" style="font-size: 11px;">
                                <i class="bi bi-activity text-success me-1"></i><?= htmlspecialchars($lastSeen) ?>
                            </div>
                        </td>
                        <td>
                            <a href="<?= APP_BASE_URL ?>/admin/projects.php?search=<?= urlencode($u['id']) ?>" class="btn btn-sm btn-outline-primary py-1 px-3 rounded-pill fw-bold d-inline-flex align-items-center gap-1">
                                <i class="bi bi-film"></i>
                                <span><?= (int)$u['projects_count'] ?> Built</span>
                            </a>
                        </td>
                        <td>
                            <?php if ($u['is_pro']): ?>
                                <span class="badge bg-warning text-dark fw-bold px-2 py-1"><i class="bi bi-star-fill me-1"></i>PRO</span>
                            <?php else: ?>
                                <span class="badge bg-light text-muted border px-2 py-1">Free</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if ($u['status'] === 'active'): ?>
                                <span class="badge badge-soft-success px-2 py-1">Active</span>
                            <?php else: ?>
                                <span class="badge badge-soft-danger px-2 py-1">Banned</span>
                            <?php endif; ?>
                        </td>
                        <td class="text-end">
                            <div class="d-flex align-items-center justify-content-end gap-1">
                                <button class="btn btn-sm btn-light border py-1 px-2 rounded-2" type="button" title="View Creator Usage Details" onclick="openDetailsModal(<?= htmlspecialchars(json_encode([
                                    'id' => $u['id'],
                                    'name' => $u['display_name'] ?: 'ProCut Creator',
                                    'handle' => $u['handle'] ?? '@creator',
                                    'email' => $u['email'],
                                    'tenure' => $tenure,
                                    'joined_date' => $fullJoinedDate,
                                    'last_seen' => $fullLastSeen,
                                    'projects_count' => (int)$u['projects_count'],
                                    'is_pro' => (bool)$u['is_pro'],
                                    'status' => $u['status']
                                ]), ENT_QUOTES, 'UTF-8') ?>)">
                                    <i class="bi bi-eye text-primary"></i>
                                </button>
                                <div class="dropdown">
                                    <button class="btn btn-sm btn-light border py-1 px-2 rounded-2" type="button" data-bs-toggle="dropdown">
                                        <i class="bi bi-three-dots-vertical"></i>
                                    </button>
                                    <ul class="dropdown-menu dropdown-menu-end shadow-sm border-0">
                                        <li>
                                            <form method="POST" action="">
                                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                                <input type="hidden" name="user_id" value="<?= htmlspecialchars($u['id']) ?>">
                                                <input type="hidden" name="action" value="toggle_pro">
                                                <button type="submit" class="dropdown-item">
                                                    <i class="bi bi-star me-2 text-warning"></i><?= $u['is_pro'] ? 'Revoke PRO Tier' : 'Grant PRO Tier' ?>
                                                </button>
                                            </form>
                                        </li>
                                        <li>
                                            <form method="POST" action="">
                                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                                <input type="hidden" name="user_id" value="<?= htmlspecialchars($u['id']) ?>">
                                                <input type="hidden" name="action" value="toggle_status">
                                                <button type="submit" class="dropdown-item">
                                                    <i class="bi bi-slash-circle me-2 text-danger"></i><?= $u['status'] === 'active' ? 'Suspend / Ban User' : 'Unban / Activate' ?>
                                                </button>
                                            </form>
                                        </li>
                                        <li><hr class="dropdown-divider"></li>
                                        <li>
                                            <form method="POST" action="" onsubmit="return confirm('Permanently delete this user account and all associated cloud timelines? This action cannot be undone.');">
                                                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">
                                                <input type="hidden" name="user_id" value="<?= htmlspecialchars($u['id']) ?>">
                                                <input type="hidden" name="action" value="delete_user">
                                                <button type="submit" class="dropdown-item text-danger">
                                                    <i class="bi bi-trash3 me-2"></i>Delete User Account
                                                </button>
                                            </form>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Read-Only User Analytics & Usage Details Modal (NO Password Editing) -->
<div class="modal fade" id="detailsModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom pb-3">
                <div class="d-flex align-items-center gap-2">
                    <div class="rounded-circle bg-primary text-white d-flex align-items-center justify-content-center fw-bold" style="width: 38px; height: 38px;" id="modalAvatar">
                        U
                    </div>
                    <div>
                        <h5 class="modal-title fw-bold mb-0" id="modalUserName">Creator Details</h5>
                        <small class="text-muted" id="modalUserHandle">@creator</small>
                    </div>
                </div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-4">
                <div class="p-3 bg-light rounded-3 border mb-3">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <span class="text-muted small">Email Address:</span>
                        <strong class="text-dark small" id="modalUserEmail"></strong>
                    </div>
                    <div class="d-flex justify-content-between align-items-center">
                        <span class="text-muted small">User UUID:</span>
                        <code class="text-secondary small" id="modalUserId"></code>
                    </div>
                </div>

                <div class="row g-3 mb-3">
                    <div class="col-6">
                        <div class="p-3 border rounded-3 text-center bg-white h-100">
                            <span class="text-muted small d-block mb-1">Time Using App</span>
                            <div class="fs-5 fw-bold text-primary" id="modalUserTenure">—</div>
                            <small class="text-muted d-block mt-1" style="font-size: 11px;">Active Tenure</small>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="p-3 border rounded-3 text-center bg-white h-100">
                            <span class="text-muted small d-block mb-1">Projects Built</span>
                            <div class="fs-5 fw-bold text-success" id="modalUserProjects">0</div>
                            <small class="text-muted d-block mt-1" style="font-size: 11px;">Cloud Timelines</small>
                        </div>
                    </div>
                </div>

                <ul class="list-group list-group-flush border rounded-3 small mb-0">
                    <li class="list-group-item d-flex justify-content-between align-items-center py-2">
                        <span class="text-muted"><i class="bi bi-calendar-event me-2 text-secondary"></i>Account Created:</span>
                        <span class="fw-semibold text-dark" id="modalUserJoined">—</span>
                    </li>
                    <li class="list-group-item d-flex justify-content-between align-items-center py-2">
                        <span class="text-muted"><i class="bi bi-activity me-2 text-secondary"></i>Last Active:</span>
                        <span class="fw-semibold text-dark" id="modalUserLastSeen">—</span>
                    </li>
                    <li class="list-group-item d-flex justify-content-between align-items-center py-2">
                        <span class="text-muted"><i class="bi bi-star me-2 text-secondary"></i>Subscription Tier:</span>
                        <span id="modalUserTier"></span>
                    </li>
                    <li class="list-group-item d-flex justify-content-between align-items-center py-2">
                        <span class="text-muted"><i class="bi bi-shield-check me-2 text-secondary"></i>Account Status:</span>
                        <span id="modalUserStatus"></span>
                    </li>
                </ul>
            </div>
            <div class="modal-footer border-top pt-2">
                <a id="modalProjectsLink" href="#" class="btn btn-sm btn-outline-primary rounded-pill">
                    <i class="bi bi-film me-1"></i> View User's Cloud Projects
                </a>
                <button type="button" class="btn btn-sm btn-secondary rounded-pill px-3" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<script>
function openDetailsModal(user) {
    document.getElementById('modalAvatar').innerText = (user.name ? user.name.charAt(0).toUpperCase() : 'U');
    document.getElementById('modalUserName').innerText = user.name;
    document.getElementById('modalUserHandle').innerText = user.handle;
    document.getElementById('modalUserEmail').innerText = user.email;
    document.getElementById('modalUserId').innerText = user.id;
    document.getElementById('modalUserTenure').innerText = user.tenure;
    document.getElementById('modalUserProjects').innerText = user.projects_count;
    document.getElementById('modalUserJoined').innerText = user.joined_date;
    document.getElementById('modalUserLastSeen').innerText = user.last_seen;

    const tierEl = document.getElementById('modalUserTier');
    if (user.is_pro) {
        tierEl.innerHTML = '<span class="badge bg-warning text-dark fw-bold"><i class="bi bi-star-fill me-1"></i>PRO Creator</span>';
    } else {
        tierEl.innerHTML = '<span class="badge bg-light text-muted border">Free Tier</span>';
    }

    const statusEl = document.getElementById('modalUserStatus');
    if (user.status === 'active') {
        statusEl.innerHTML = '<span class="badge badge-soft-success">Active</span>';
    } else {
        statusEl.innerHTML = '<span class="badge badge-soft-danger">Banned / Suspended</span>';
    }

    document.getElementById('modalProjectsLink').href = '<?= APP_BASE_URL ?>/admin/projects.php?search=' + encodeURIComponent(user.id);

    new bootstrap.Modal(document.getElementById('detailsModal')).show();
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
