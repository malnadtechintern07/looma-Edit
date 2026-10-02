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

// Graceful Error & Exception Handler (prevents opaque HTTP 500 errors on free hosting)
set_exception_handler(function(Throwable $e) {
    if (str_contains($_SERVER['REQUEST_URI'] ?? '', '/admin/')) {
        http_response_code(200);
        echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Admin Error — ProCut</title></head><body style="background:#f8f9fe;margin:0;padding:20px;">';
        echo '<div style="font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;padding:30px;background:#fff;border:1.5px solid #fed7d7;border-radius:14px;margin:30px auto;max-width:850px;box-shadow:0 10px 30px rgba(0,0,0,0.06);">';
        echo '<h3 style="color:#c53030;margin-top:0;display:flex;align-items:center;gap:10px;">⚠️ ProCut Admin Error</h3>';
        echo '<p style="color:#4a5568;font-size:14px;line-height:1.5;">An error occurred while executing this administrative action:</p>';
        echo '<pre style="background:#1a202c;color:#f7fafc;padding:16px;border-radius:8px;overflow-x:auto;font-size:13px;line-height:1.6;">' . htmlspecialchars($e->getMessage()) . "\n\nFile: " . htmlspecialchars($e->getFile()) . ' (Line ' . $e->getLine() . ')' . '</pre>';
        echo '<div style="margin-top:20px;display:flex;gap:10px;">';
        echo '<a href="dashboard.php" style="padding:10px 18px;background:#0d6efd;color:#fff;text-decoration:none;border-radius:8px;font-size:13px;font-weight:600;">Return to Dashboard</a>';
        echo '<a href="javascript:history.back()" style="padding:10px 18px;background:#e2e8f0;color:#334155;text-decoration:none;border-radius:8px;font-size:13px;font-weight:600;">Go Back</a>';
        echo '</div></div></body></html>';
        exit;
    }
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    exit;
});

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

// ============================================================
// Firebase Cloud Messaging – Service Account Key
// ============================================================
// Download from: Firebase Console → Project Settings → Service Accounts
//                → Generate new private key  → save as firebase-service-account.json
// Then upload the file to: procut_backend_infinityfree/config/firebase-service-account.json
define('FCM_SERVICE_ACCOUNT_PATH', BASE_PATH . '/config/firebase-service-account.json');
