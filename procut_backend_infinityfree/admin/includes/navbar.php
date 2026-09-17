<div class="main-wrapper">
    <header class="top-navbar d-flex align-items-center justify-content-between">
        <div class="d-flex align-items-center gap-3">
            <button class="btn btn-sm btn-outline-secondary d-lg-none" onclick="toggleSidebar()">
                <i class="bi bi-list fs-5"></i>
            </button>
            <h6 class="mb-0 fw-semibold text-dark d-none d-md-block"><?= htmlspecialchars($pageTitle ?? 'Admin Console') ?></h6>
        </div>

        <div class="d-flex align-items-center gap-3">

            <!-- Admin Profile Dropdown -->
            <div class="dropdown">
                <button class="btn btn-light d-flex align-items-center gap-2 rounded-pill px-3 py-1 border shadow-sm dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                    <div class="rounded-circle bg-primary text-white d-flex align-items-center justify-content-center fw-bold" style="width: 30px; height: 30px; font-size: 13px;">
                        <?= strtoupper(substr($currentAdmin['name'] ?? 'A', 0, 1)) ?>
                    </div>
                    <div class="text-start d-none d-sm-block">
                        <div class="fw-semibold text-dark" style="font-size: 12.5px; line-height: 1.1;"><?= htmlspecialchars($currentAdmin['name'] ?? 'Admin') ?></div>
                        <span class="badge bg-secondary text-white text-uppercase" style="font-size: 9px; padding: 1px 5px;"><?= htmlspecialchars($currentAdmin['role'] ?? 'admin') ?></span>
                    </div>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow border-0 rounded-4 mt-2 p-2" style="min-width: 220px;">
                    <li class="px-3 py-2 border-bottom mb-1">
                        <div class="fw-bold"><?= htmlspecialchars($currentAdmin['name'] ?? 'Admin') ?></div>
                        <div class="small text-muted text-truncate"><?= htmlspecialchars($currentAdmin['email'] ?? '') ?></div>
                    </li>
                    <li><a class="dropdown-item rounded-2 py-2" href="<?= APP_BASE_URL ?>/admin/change-password.php"><i class="bi bi-key me-2 text-primary"></i>Change Password</a></li>
                    <li><a class="dropdown-item rounded-2 py-2" href="<?= APP_BASE_URL ?>/admin/activity-logs.php?admin_id=<?= (int)$currentAdmin['id'] ?>"><i class="bi bi-clock-history me-2 text-info"></i>My Activity</a></li>
                    <li><hr class="dropdown-divider"></li>
                    <li><a class="dropdown-item rounded-2 py-2 text-danger" href="<?= APP_BASE_URL ?>/admin/logout.php"><i class="bi bi-box-arrow-right me-2"></i>Sign Out</a></li>
                </ul>
            </div>
        </div>
    </header>
    <main class="page-content">
