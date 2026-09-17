<?php
/**
 * ProCut PHP Built-In Server Router
 * Routes API endpoints, Admin Console, and uploaded media cleanly.
 */

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

// 1. Serve static files if they exist on disk (CSS, JS, uploads, images, media)
$ext = strtolower(pathinfo($uri, PATHINFO_EXTENSION));
$staticFile = __DIR__ . $uri;
if ($ext !== 'php' && $uri !== '/' && file_exists($staticFile) && !is_dir($staticFile)) {
    // If document root matches __DIR__, let PHP built-in server handle natively
    if (isset($_SERVER['DOCUMENT_ROOT']) && realpath($_SERVER['DOCUMENT_ROOT']) === realpath(__DIR__)) {
        return false;
    }

    // Fallback: serve static file directly if document root is mismatched
    $mimeTypes = [
        'css'   => 'text/css',
        'js'    => 'application/javascript',
        'json'  => 'application/json',
        'png'   => 'image/png',
        'jpg'   => 'image/jpeg',
        'jpeg'  => 'image/jpeg',
        'gif'   => 'image/gif',
        'webp'  => 'image/webp',
        'svg'   => 'image/svg+xml',
        'ico'   => 'image/x-icon',
        'mp4'   => 'video/mp4',
        'mp3'   => 'audio/mpeg',
        'wav'   => 'audio/wav',
        'woff'  => 'font/woff',
        'woff2' => 'font/woff2',
        'ttf'   => 'font/ttf',
    ];
    $contentType = $mimeTypes[$ext] ?? (function_exists('mime_content_type') ? @mime_content_type($staticFile) : null) ?: 'application/octet-stream';
    header("Content-Type: {$contentType}");
    header("Content-Length: " . filesize($staticFile));
    readfile($staticFile);
    exit;
}

// 2. Root Redirect
if ($uri === '/' || $uri === '/index.php' || $uri === '/admin' || $uri === '/admin/') {
    header('Location: /admin/dashboard.php');
    exit;
}

// 3. API Routing
if (str_starts_with($uri, '/api/')) {
    // Health Check
    if ($uri === '/api/health') {
        require __DIR__ . '/api/health.php';
        exit;
    }

    // Auth endpoints
    if ($uri === '/api/auth/register') {
        require __DIR__ . '/api/auth/register.php';
        exit;
    }
    if ($uri === '/api/auth/login') {
        require __DIR__ . '/api/auth/login.php';
        exit;
    }
    if ($uri === '/api/auth/logout') {
        require __DIR__ . '/api/auth/logout.php';
        exit;
    }
    if ($uri === '/api/auth/forgot-password') {
        require __DIR__ . '/api/auth/forgot-password.php';
        exit;
    }
    if ($uri === '/api/auth/account') {
        require __DIR__ . '/api/auth/account.php';
        exit;
    }
    if ($uri === '/api/auth/check') {
        require __DIR__ . '/api/auth/check.php';
        exit;
    }
    if ($uri === '/api/auth/save-account') {
        require __DIR__ . '/api/auth/save-account.php';
        exit;
    }
    if ($uri === '/api/auth/update-profile') {
        require __DIR__ . '/api/auth/update-profile.php';
        exit;
    }

    // Projects endpoints
    if ($uri === '/api/projects' || $uri === '/api/projects/') {
        require __DIR__ . '/api/projects/index.php';
        exit;
    }
    if ($uri === '/api/projects/backup') {
        require __DIR__ . '/api/projects/backup.php';
        exit;
    }
    if ($uri === '/api/projects/upload') {
        require __DIR__ . '/api/projects/upload.php';
        exit;
    }
    if (preg_match('#^/api/projects/([^/]+)$#', $uri, $matches)) {
        $_GET['projectId'] = $matches[1];
        if ($method === 'DELETE') {
            require __DIR__ . '/api/projects/delete.php';
        } else {
            require __DIR__ . '/api/projects/index.php';
        }
        exit;
    }

    // AI endpoints
    if ($uri === '/api/ai/presets' || $uri === '/api/ai/presets.php') {
        require __DIR__ . '/api/ai/presets.php';
        exit;
    }

    // Templates endpoint
    if ($uri === '/api/templates' || $uri === '/api/templates/' || $uri === '/api/templates/index.php') {
        require __DIR__ . '/api/templates/index.php';
        exit;
    }

    // App endpoints
    if ($uri === '/api/app/config') {
        require __DIR__ . '/api/app/config.php';
        exit;
    }
    if ($uri === '/api/app/content') {
        require __DIR__ . '/api/app/content.php';
        exit;
    }
    if ($uri === '/api/app/notifications') {
        require __DIR__ . '/api/app/notifications.php';
        exit;
    }
    if ($uri === '/api/app/support-ticket') {
        require __DIR__ . '/api/app/support-ticket.php';
        exit;
    }

    // API 404
    http_response_code(404);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['success' => false, 'error' => "Endpoint not found: {$uri}"]);
    exit;
}

// 4. Admin Routing
if (str_starts_with($uri, '/admin/')) {
    $script = __DIR__ . $uri;
    if (file_exists($script) && !is_dir($script)) {
        require $script;
        exit;
    }
    // Try adding .php extension if omitted
    if (file_exists($script . '.php')) {
        require $script . '.php';
        exit;
    }
}

// 5. Default 404
http_response_code(404);
echo "404 Not Found - ProCut Backend Server";
