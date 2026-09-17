<?php
/**
 * ProCut Application & Security Configuration
 */

// Ensure output buffering is active early to prevent headers-already-sent issues
if (!ob_get_level()) {
    @ob_start();
}

// Error Reporting & Diagnostics
// Suppress display of errors in production to prevent layout breakage & header corruption
$hostHeader = $_SERVER['HTTP_HOST'] ?? '';
$isLocalhost = in_array($hostHeader, ['localhost', '127.0.0.1', 'localhost:5050', '127.0.0.1:5050'])
    || str_starts_with($hostHeader, 'localhost:')
    || str_starts_with($hostHeader, '127.0.0.1:');

if ($isLocalhost) {
    ini_set('display_errors', '1');
    ini_set('display_startup_errors', '1');
} else {
    ini_set('display_errors', '0');
    ini_set('display_startup_errors', '0');
}
error_reporting(E_ALL & ~E_NOTICE & ~E_DEPRECATED);

// Timezone
date_default_timezone_set('UTC');

// Polyfill getallheaders() if running under FastCGI/FPM/Nginx/InfinityFree
if (!function_exists('getallheaders')) {
    function getallheaders() {
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (substr($name, 0, 5) === 'HTTP_') {
                $headerName = str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))));
                $headers[$headerName] = $value;
            } elseif ($name === 'CONTENT_TYPE') {
                $headers['Content-Type'] = $value;
            } elseif ($name === 'CONTENT_LENGTH') {
                $headers['Content-Length'] = $value;
            }
        }
        if (!isset($headers['Authorization'])) {
            if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
                $headers['Authorization'] = $_SERVER['HTTP_AUTHORIZATION'];
            } elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
                $headers['Authorization'] = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
            }
        }
        return $headers;
    }
}

// ============================================================
// Database Connection Settings
// ============================================================
if ($isLocalhost) {
    define('DB_HOST', '127.0.0.1');
    define('DB_PORT', '3306');
    define('DB_NAME', 'procut_db');
    define('DB_USER', 'root');
    define('DB_PASS', '');
} else {
    // InfinityFree Production Settings (auto-applied when on procut.free.nf)
    define('DB_HOST', 'sql307.infinityfree.com');
    define('DB_PORT', '3306');
    define('DB_NAME', 'if0_42932260_ProCut');
    define('DB_USER', 'if0_42932260'); // Correct InfinityFree username (without 'roo'...'t')
    define('DB_PASS', '');             // Replace with your InfinityFree vPanel password
}

// Paths
define('BASE_PATH', dirname(__DIR__));
define('UPLOAD_DIR', BASE_PATH . '/uploads');
define('MEDIA_UPLOAD_DIR', UPLOAD_DIR . '/media');
define('THUMBNAIL_UPLOAD_DIR', UPLOAD_DIR . '/thumbnails');
define('MUSIC_UPLOAD_DIR', UPLOAD_DIR . '/music');
define('STICKER_UPLOAD_DIR', UPLOAD_DIR . '/stickers');

// Ensure upload directories exist
foreach ([UPLOAD_DIR, MEDIA_UPLOAD_DIR, THUMBNAIL_UPLOAD_DIR, MUSIC_UPLOAD_DIR, STICKER_UPLOAD_DIR] as $dir) {
    if (!is_dir($dir)) {
        @mkdir($dir, 0775, true);
    }
}

// Session Security Configuration
define('SESSION_LIFETIME', 1800); // 30 minutes inactivity timeout
define('TOKEN_LIFETIME_DAYS', 30); // 30 days token expiry for mobile app
define('ADMIN_SESSION_KEY', 'procut_admin_session');

// App Info
define('APP_NAME', 'ProCut');
define('APP_VERSION', '1.0.0');

// Base URL detection
$isHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
    || (!empty($_SERVER['HTTP_X_FORWARDED_PROTO']) && strtolower($_SERVER['HTTP_X_FORWARDED_PROTO']) === 'https')
    || (!empty($_SERVER['HTTP_X_FORWARDED_SSL']) && strtolower($_SERVER['HTTP_X_FORWARDED_SSL']) === 'on')
    || (isset($_SERVER['SERVER_PORT']) && $_SERVER['SERVER_PORT'] == 443);
$protocol = $isHttps ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost:5050';
define('APP_BASE_URL', "{$protocol}://{$host}");
