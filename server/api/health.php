<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/response.php';

Response::cors();

try {
    $db = Database::getConnection();
    $usersCount = Database::fetchOne("SELECT COUNT(*) as cnt FROM users")['cnt'] ?? 0;
    $projectsCount = Database::fetchOne("SELECT COUNT(*) as cnt FROM projects")['cnt'] ?? 0;

    Response::success([
        'service'   => 'ProCut Backend Server',
        'version'   => APP_VERSION,
        'database'  => 'MySQL (InnoDB)',
        'users'     => (int)$usersCount,
        'projects'  => (int)$projectsCount,
        'timestamp' => date('c')
    ]);
} catch (Exception $e) {
    Response::error('Health check failed: ' . $e->getMessage(), 500);
}
