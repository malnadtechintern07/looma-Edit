<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

Response::cors();

$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
$token = '';

if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
    $token = trim($matches[1]);
} elseif (!empty($_REQUEST['token'])) {
    $token = trim($_REQUEST['token']);
}

if (!empty($token)) {
    Auth::revokeToken($token);
}

Response::success([], 'Logged out successfully');
