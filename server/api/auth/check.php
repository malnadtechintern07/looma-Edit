<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';

Response::cors();

$email = strtolower(trim($_GET['email'] ?? ''));

if (empty($email)) {
    Response::error('Email parameter is required.', 400);
}

$user = Database::fetchOne("SELECT id FROM users WHERE LOWER(email) = ?", [$email]);

Response::json(200, [
    'exists' => $user !== null,
    'email'  => $email
]);
