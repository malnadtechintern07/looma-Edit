<?php
/**
 * ProCut Secure File Uploader Helper
 */

require_once __DIR__ . '/../config/config.php';

class Uploader {
    public static function uploadFile(array $file, string $targetDir, array $allowedMimes, int $maxSizeBytes = 52428800): array {
        if (!isset($file['error']) || is_array($file['error'])) {
            return ['success' => false, 'error' => 'Invalid file upload parameters.'];
        }

        switch ($file['error']) {
            case UPLOAD_ERR_OK:
                break;
            case UPLOAD_ERR_NO_FILE:
                return ['success' => false, 'error' => 'No file was uploaded.'];
            case UPLOAD_ERR_INI_SIZE:
            case UPLOAD_ERR_FORM_SIZE:
                return ['success' => false, 'error' => 'Exceeded file size limit.'];
            default:
                return ['success' => false, 'error' => 'Unknown upload error.'];
        }

        if ($file['size'] > $maxSizeBytes) {
            $mb = round($maxSizeBytes / 1048576);
            return ['success' => false, 'error' => "File exceeds maximum size of {$mb}MB."];
        }

        // Validate MIME type securely using finfo
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($file['tmp_name']);

        if (!in_array($mime, $allowedMimes)) {
            return ['success' => false, 'error' => "Invalid file format ({$mime})."];
        }

        // Generate safe unique filename
        $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
        $safeName = sprintf('%s_%s.%s', bin2hex(random_bytes(8)), time(), strtolower($ext));
        $targetPath = rtrim($targetDir, '/') . '/' . $safeName;

        if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
            return ['success' => false, 'error' => 'Failed to save uploaded file to destination.'];
        }

        // Determine relative web URL
        $relPath = str_replace(BASE_PATH, '', $targetPath);
        $webUrl = APP_BASE_URL . str_replace('\\', '/', $relPath);

        return [
            'success'       => true,
            'file_name'     => $safeName,
            'original_name' => basename($file['name']),
            'file_path'     => $targetPath,
            'web_url'       => $webUrl,
            'mime_type'     => $mime,
            'size_bytes'    => $file['size']
        ];
    }
}
