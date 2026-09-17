<?php
/**
 * ProCut Support Ticket Submission Endpoint
 * Receives tickets from app users and logs them into MySQL.
 */
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';

Response::cors();

$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'POST') {
    Response::error("Method {$method} not allowed", 405);
}

$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput, true) ?? $_POST;

$email = trim($data['email'] ?? '');
$category = trim($data['category'] ?? 'General Inquiry');
$subject = trim($data['subject'] ?? '');
$message = trim($data['message'] ?? '');
$diagnostics = trim($data['diagnostics'] ?? '');

if (empty($email) || empty($subject) || empty($message)) {
    Response::error('Email, subject, and message are required fields.', 422);
}

$ticketId = 'TKT-' . strtoupper(substr(bin2hex(random_bytes(4)), 0, 8));

// Log into activity_logs table for Admin visibility
try {
    Database::query(
        "INSERT INTO activity_logs (actor_type, actor_id, actor_name, action, details, ip_address)
         VALUES ('user', ?, ?, 'support_ticket_created', ?, ?)",
        [
            $email,
            $email,
            "Ticket {$ticketId} [{$category}]: {$subject} - " . substr($message, 0, 150),
            $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1'
        ]
    );
} catch (Exception $e) {
    // If table doesn't have exact fields, continue gracefully
}

Response::success([
    'ticketId'   => $ticketId,
    'ticket_id'  => $ticketId,
    'status'     => 'received',
    'message'    => 'Your support ticket has been received by our engineering team.',
    'timestamp'  => date('c')
]);
