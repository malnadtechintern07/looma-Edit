<?php
/**
 * ProCut Standardized API Response and Request Helpers
 */

class Response {
    public static function cors(): void {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-CSRF-Token');
        header('Access-Control-Max-Age: 86400');
        
        if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
            http_response_code(200);
            exit;
        }
    }

    public static function json(int $statusCode, array $data): void {
        self::cors();
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-cache, no-store, must-revalidate');
        header('Pragma: no-cache');
        header('Expires: 0');
        echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function success(array $data = [], string $message = 'Success', int $statusCode = 200): void {
        self::json($statusCode, array_merge(['success' => true, 'message' => $message], $data));
    }

    public static function error(string $message, int $statusCode = 400, array $extra = []): void {
        self::json($statusCode, array_merge(['success' => false, 'error' => $message], $extra));
    }

    public static function getJsonBody(): array {
        $raw = file_get_contents('php://input');
        if (empty($raw)) {
            return [];
        }
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    }

    public static function sanitize(string $input): string {
        return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
    }
}
