<?php
/**
 * ProCut Admin Authentication Middleware
 * Included at the top of every administrative page.
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/auth.php';

Auth::startSession();

if (!Auth::isAdminAuthenticated()) {
    $req = $_SERVER['REQUEST_URI'] ?? '';
    $redirectParam = (!empty($req) && !str_contains($req, 'login.php') && !str_contains($req, 'logout.php')) 
        ? '?redirect=' . urlencode($req) . '&error=unauthorized' 
        : '?error=unauthorized';
    header('Location: ' . APP_BASE_URL . '/admin/login.php' . $redirectParam);
    exit;
}

$currentAdmin = Auth::getAdmin();
$csrfToken = Auth::getCsrfToken();
