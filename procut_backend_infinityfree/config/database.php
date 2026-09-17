<?php
/**
 * ProCut Database Connection Manager (PDO)
 */

class Database {
    private static ?PDO $pdo = null;

    public static function getConnection(): PDO {
        if (self::$pdo !== null) {
            return self::$pdo;
        }

        require_once __DIR__ . '/config.php';

        $cfgFile = dirname(__DIR__) . '/config.json';
        $cfg = [];
        if (file_exists($cfgFile)) {
            $cfg = @json_decode(file_get_contents($cfgFile), true) ?: [];
        }
        $mysqlCfg = $cfg['mysql'] ?? [];

        // 1. Check defined constants from config.php
        // 2. Check config.json
        // 3. Fallback to getenv() or defaults
        $host = (defined('DB_HOST') && DB_HOST !== '127.0.0.1' && DB_HOST !== 'localhost')
            ? DB_HOST
            : ($mysqlCfg['host'] ?? getenv('DB_HOST') ?: (defined('DB_HOST') ? DB_HOST : '127.0.0.1'));

        // Prevent UNIX domain socket lookup on Linux when "localhost" is used
        if ($host === 'localhost') {
            $host = '127.0.0.1';
        }

        $port = (defined('DB_PORT') && DB_PORT != '3306')
            ? DB_PORT
            : ($mysqlCfg['port'] ?? getenv('DB_PORT') ?: '3306');

        $dbname = (defined('DB_NAME') && DB_NAME !== 'procut_db')
            ? DB_NAME
            : ($mysqlCfg['database'] ?? getenv('DB_NAME') ?: (defined('DB_NAME') ? DB_NAME : 'procut_db'));

        $user = (defined('DB_USER') && DB_USER !== 'root')
            ? DB_USER
            : ($mysqlCfg['user'] ?? getenv('DB_USER') ?: (defined('DB_USER') ? DB_USER : 'root'));

        $pass = (defined('DB_PASS') && DB_PASS !== '')
            ? DB_PASS
            : ($mysqlCfg['password'] ?? (getenv('DB_PASS') !== false ? getenv('DB_PASS') : (defined('DB_PASS') ? DB_PASS : '')));

        $socket = '/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock';

        $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
        ];

        try {
            self::$pdo = new PDO($dsn, $user, $pass, $options);
        } catch (PDOException $e) {
            // Try unix socket if on local Mac XAMPP
            if (PHP_OS_FAMILY === 'Darwin' && empty(ini_get('open_basedir')) && @file_exists($socket)) {
                try {
                    $socketDsn = "mysql:unix_socket={$socket};dbname={$dbname};charset=utf8mb4";
                    self::$pdo = new PDO($socketDsn, $user, $pass, $options);
                    return self::$pdo;
                } catch (PDOException $e2) {
                    // Fall through to error handler
                }
            }

            // If an API request (JSON)
            $isApi = str_contains($_SERVER['REQUEST_URI'] ?? '', '/api/');
            if ($isApi) {
                http_response_code(500);
                header('Content-Type: application/json; charset=utf-8');
                die(json_encode([
                    'success' => false,
                    'error' => 'Database connection failed: ' . $e->getMessage()
                ]));
            }

            // Web browser / Admin Panel error view
            http_response_code(200); // Keep 200 so free hosting proxies (InfinityFree) don't replace custom help page with generic browser 500 error
            header('Content-Type: text/html; charset=utf-8');
            die('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Database Connection Required — ProCut</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        body { font-family: "Plus Jakarta Sans", sans-serif; background: #0F172A; color: #E2E8F0; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; padding: 20px; }
        .box { background: rgba(30, 41, 59, 0.85); border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; max-width: 580px; width: 100%; padding: 32px; box-shadow: 0 20px 50px rgba(0,0,0,0.5); }
        h2 { color: #F59E0B; margin-top: 0; font-size: 1.4rem; display: flex; align-items: center; gap: 8px; }
        p { line-height: 1.6; color: #94A3B8; font-size: 0.95rem; }
        .error-chip { background: rgba(239, 68, 68, 0.15); color: #F87171; border: 1px solid rgba(239,68,68,0.3); border-radius: 8px; padding: 10px 14px; font-family: monospace; font-size: 0.85rem; word-break: break-all; margin: 16px 0; }
        .code-box { background: #080e1a; border: 1px solid rgba(255,255,255,0.08); border-radius: 8px; padding: 14px; font-family: monospace; font-size: 0.85rem; color: #38BDF8; line-height: 1.5; margin: 16px 0; }
        .step { margin-top: 12px; color: #CBD5E1; font-size: 0.9rem; }
        strong { color: #FFF; }
    </style>
</head>
<body>
    <div class="box">
        <h2>⚠️ Database Connection Setup Required</h2>
        <p>The ProCut server cannot connect to your MySQL database with the current credentials.</p>
        <div class="error-chip">' . htmlspecialchars($e->getMessage()) . '</div>
        <p><strong>Attempted Connection:</strong><br>
        Host: <code>' . htmlspecialchars($host) . '</code> | Database: <code>' . htmlspecialchars($dbname) . '</code> | User: <code>' . htmlspecialchars($user) . '</code></p>
        <div class="step"><strong>How to Fix on InfinityFree:</strong></div>
        <p>Open <strong>File Manager</strong> &rarr; <strong>htdocs</strong> &rarr; <strong>config/config.php</strong> (or <strong>config.json</strong>) and enter your InfinityFree MySQL details:</p>
        <div class="code-box">
define(\'DB_HOST\', \'<strong>sql3xx.infinityfree.com</strong>\');<br>
define(\'DB_NAME\', \'<strong>epiz_xxxxxxx_procut_db</strong>\');<br>
define(\'DB_USER\', \'<strong>epiz_xxxxxxx</strong>\');<br>
define(\'DB_PASS\', \'<strong>your_vpanel_password</strong>\');
        </div>
        <p style="font-size:0.85rem; color:#64748B;">You can copy these 4 details directly from your InfinityFree Account Management page under <em>Database Details</em>.</p>
    </div>
</body>
</html>');
        }

        return self::$pdo;
    }

    public static function query(string $sql, array $params = []): PDOStatement {
        $stmt = self::getConnection()->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }

    public static function fetchAll(string $sql, array $params = []): array {
        return self::query($sql, $params)->fetchAll();
    }

    public static function fetchOne(string $sql, array $params = []): ?array {
        $row = self::query($sql, $params)->fetch();
        return $row ?: null;
    }

    public static function execute(string $sql, array $params = []): bool {
        return self::query($sql, $params)->rowCount() >= 0;
    }

    public static function lastInsertId(): string {
        return self::getConnection()->lastInsertId();
    }
}
