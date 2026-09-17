<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../helpers/auth.php';

Auth::logoutAdmin();
header('Location: ' . APP_BASE_URL . '/admin/login.php?success=logged_out');
exit;
