<?php
$currentPage = basename($_SERVER['PHP_SELF']);
?>
<aside class="sidebar" id="sidebar">
    <div class="sidebar-brand">
        <div class="d-flex align-items-center justify-content-between w-100">
            <div class="d-flex align-items-center gap-2">
                <i class="bi bi-film fs-3 text-primary"></i>
                <div>
                    <div class="d-flex align-items-center gap-2">
                        <span class="fs-5 fw-bold text-white brand-font">PROCUT</span>
                        <span class="sidebar-brand-badge">PRO ADMIN</span>
                    </div>
                    <small class="text-secondary" style="font-size: 11px;">Studio Control Center</small>
                </div>
            </div>
            <button class="btn btn-sm btn-link text-secondary d-lg-none" onclick="toggleSidebar()">
                <i class="bi bi-x-lg"></i>
            </button>
        </div>
    </div>

    <div class="sidebar-menu">
        <div class="sidebar-section-title">Overview</div>
        <a href="<?= APP_BASE_URL ?>/admin/dashboard.php" class="sidebar-nav-link <?= $currentPage === 'dashboard.php' ? 'active' : '' ?>">
            <i class="bi bi-grid-1x2-fill"></i>
            <span>Dashboard</span>
        </a>

        <div class="sidebar-section-title">Users & Cloud</div>
        <a href="<?= APP_BASE_URL ?>/admin/users.php" class="sidebar-nav-link <?= $currentPage === 'users.php' ? 'active' : '' ?>">
            <i class="bi bi-people-fill"></i>
            <span>Users Management</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/projects.php" class="sidebar-nav-link <?= $currentPage === 'projects.php' ? 'active' : '' ?>">
            <i class="bi bi-cloud-arrow-up-fill"></i>
            <span>User Cloud Projects</span>
        </a>

        <div class="sidebar-section-title">App Appearance</div>
        <a href="<?= APP_BASE_URL ?>/admin/home-sections.php" class="sidebar-nav-link <?= $currentPage === 'home-sections.php' ? 'active' : '' ?>">
            <i class="bi bi-layout-text-window-reverse"></i>
            <span>Home Sections</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/features.php" class="sidebar-nav-link <?= $currentPage === 'features.php' ? 'active' : '' ?>">
            <i class="bi bi-stars"></i>
            <span>Features & Tools</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/banners.php" class="sidebar-nav-link <?= $currentPage === 'banners.php' ? 'active' : '' ?>">
            <i class="bi bi-megaphone-fill"></i>
            <span>Banners & CTA</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/notifications.php" class="sidebar-nav-link <?= $currentPage === 'notifications.php' ? 'active' : '' ?>">
            <i class="bi bi-bell-fill"></i>
            <span>Notifications</span>
        </a>

        <div class="sidebar-section-title">AI & Creative Studio</div>
        <a href="<?= APP_BASE_URL ?>/admin/ai_edits.php" class="sidebar-nav-link <?= $currentPage === 'ai_edits.php' ? 'active' : '' ?>">
            <i class="bi bi-robot"></i>
            <div class="d-flex align-items-center justify-content-between w-100">
                <span>AI Edit Studio</span>
                <span class="badge bg-warning text-dark fw-bold" style="font-size: 9px; padding: 2px 6px;">PRO AI</span>
            </div>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/templates.php" class="sidebar-nav-link <?= $currentPage === 'templates.php' ? 'active' : '' ?>">
            <i class="bi bi-collection-play-fill"></i>
            <span>Templates</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/effects.php" class="sidebar-nav-link <?= $currentPage === 'effects.php' ? 'active' : '' ?>">
            <i class="bi bi-magic"></i>
            <span>Video Effects</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/filters.php" class="sidebar-nav-link <?= $currentPage === 'filters.php' ? 'active' : '' ?>">
            <i class="bi bi-palette-fill"></i>
            <span>Filters & LUTs</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/transitions.php" class="sidebar-nav-link <?= $currentPage === 'transitions.php' ? 'active' : '' ?>">
            <i class="bi bi-arrow-left-right"></i>
            <span>Transitions</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/animations.php" class="sidebar-nav-link <?= $currentPage === 'animations.php' ? 'active' : '' ?>">
            <i class="bi bi-play-circle-fill"></i>
            <span>Clip Animations</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/music.php" class="sidebar-nav-link <?= $currentPage === 'music.php' ? 'active' : '' ?>">
            <i class="bi bi-music-note-beamed"></i>
            <span>Music & Audio</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/stickers.php" class="sidebar-nav-link <?= $currentPage === 'stickers.php' ? 'active' : '' ?>">
            <i class="bi bi-emoji-smile-fill"></i>
            <span>Stickers & Clipart</span>
        </a>

        <div class="sidebar-section-title">System & Governance</div>
        <a href="<?= APP_BASE_URL ?>/admin/watermark.php" class="sidebar-nav-link <?= $currentPage === 'watermark.php' ? 'active' : '' ?>">
            <i class="bi bi-shield-check"></i>
            <span>Watermark & Export</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/settings.php" class="sidebar-nav-link <?= $currentPage === 'settings.php' ? 'active' : '' ?>">
            <i class="bi bi-gear-fill"></i>
            <span>App Settings & Version</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/admins.php" class="sidebar-nav-link <?= $currentPage === 'admins.php' ? 'active' : '' ?>">
            <i class="bi bi-person-badge-fill"></i>
            <span>Admin Staff & Roles</span>
        </a>
        <a href="<?= APP_BASE_URL ?>/admin/activity-logs.php" class="sidebar-nav-link <?= $currentPage === 'activity-logs.php' ? 'active' : '' ?>">
            <i class="bi bi-journal-text"></i>
            <span>Audit & Activity Logs</span>
        </a>
    </div>
</aside>
