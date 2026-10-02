<?php
/**
 * ProCut FCM Push Notification Helper
 * Uses Firebase Cloud Messaging HTTP v1 API (modern, OAuth2 service account).
 *
 * SETUP REQUIRED:
 *   1. Go to Firebase Console → Project Settings → Service Accounts
 *   2. Click "Generate new private key" → download the JSON file
 *   3. Rename it to: firebase-service-account.json
 *   4. Upload it to: procut_backend_infinityfree/config/firebase-service-account.json
 *
 * The FCM_SERVICE_ACCOUNT_PATH constant is defined in config/config.php.
 */

class FcmHelper
{
    // ------------------------------------------------------------------ //
    //  SERVICE ACCOUNT LOADING                                            //
    // ------------------------------------------------------------------ //

    private static function getServiceAccount(): ?array
    {
        $path = defined('FCM_SERVICE_ACCOUNT_PATH') ? FCM_SERVICE_ACCOUNT_PATH : '';
        if (empty($path) || !file_exists($path)) {
            error_log('FcmHelper: Service account JSON not found at ' . $path);
            return null;
        }
        $json = @file_get_contents($path);
        if (!$json) {
            error_log('FcmHelper: Could not read service account JSON');
            return null;
        }
        $data = json_decode($json, true);
        if (!is_array($data) || empty($data['private_key']) || empty($data['client_email'])) {
            error_log('FcmHelper: Service account JSON is missing private_key or client_email');
            return null;
        }
        return $data;
    }

    // ------------------------------------------------------------------ //
    //  JWT / OAUTH2 TOKEN                                                  //
    // ------------------------------------------------------------------ //

    private static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Obtain a short-lived OAuth2 access token using a service account JWT.
     */
    private static function getAccessToken(array $sa): ?string
    {
        if (!function_exists('openssl_sign')) {
            error_log('FcmHelper: openssl_sign() not available on this host');
            return null;
        }

        $now    = time();
        $header  = self::base64UrlEncode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $payload = self::base64UrlEncode(json_encode([
            'iss'   => $sa['client_email'],
            'sub'   => $sa['client_email'],
            'aud'   => 'https://oauth2.googleapis.com/token',
            'iat'   => $now,
            'exp'   => $now + 3600,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        ]));

        $unsigned   = "{$header}.{$payload}";
        $privateKey = @openssl_pkey_get_private($sa['private_key']);
        if (!$privateKey) {
            error_log('FcmHelper: Failed to parse private key from service account');
            return null;
        }

        $signature = '';
        if (!openssl_sign($unsigned, $signature, $privateKey, 'sha256WithRSAEncryption')) {
            error_log('FcmHelper: openssl_sign() failed');
            return null;
        }

        $jwt = "{$unsigned}." . self::base64UrlEncode($signature);

        // Exchange the signed JWT for a short-lived OAuth2 access token
        $resp = self::httpPost(
            'https://oauth2.googleapis.com/token',
            [],
            ['Content-Type: application/x-www-form-urlencoded'],
            http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ])
        );

        if (!$resp['ok']) {
            error_log('FcmHelper: Token exchange failed: ' . json_encode($resp));
            return null;
        }

        $data = json_decode($resp['body'], true);
        return $data['access_token'] ?? null;
    }

    // ------------------------------------------------------------------ //
    //  PUBLIC SEND API                                                     //
    // ------------------------------------------------------------------ //

    /**
     * Send a push notification to a topic (broadcast) and/or individual device tokens.
     *
     * @param string      $title     Notification title shown on device
     * @param string      $body      Notification body text
     * @param string      $type      One of: announcement | info | update | promotion
     * @param string|null $topic     FCM topic to broadcast to (use 'all_users' for global). Pass null to skip.
     * @param string[]    $tokens    Individual device FCM tokens for targeted delivery
     * @param array       $extraData Additional key-value pairs added to FCM data payload
     * @return array{success:bool,results:array}
     */
    public static function send(
        string $title,
        string $body,
        string $type = 'info',
        ?string $topic = 'all_users',
        array $tokens = [],
        array $extraData = []
    ): array {
        $sa = self::getServiceAccount();
        if (!$sa) {
            return ['success' => false, 'error' => 'FCM service account not configured. See helpers/fcm_helper.php for setup instructions.'];
        }

        $accessToken = self::getAccessToken($sa);
        if (!$accessToken) {
            return ['success' => false, 'error' => 'Failed to obtain FCM OAuth2 access token'];
        }

        $projectId = $sa['project_id'] ?? '';
        if (empty($projectId)) {
            return ['success' => false, 'error' => 'project_id missing from service account JSON'];
        }

        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
        $headers = [
            "Authorization: Bearer {$accessToken}",
            'Content-Type: application/json',
        ];

        // Build the shared notification payload fields
        $dataPayload = array_map('strval', array_merge($extraData, [
            'type'         => $type,
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ]));

        $notificationBase = [
            'notification' => [
                'title' => $title,
                'body'  => $body,
            ],
            'data'    => $dataPayload,
            'android' => [
                'priority'     => 'high',
                'notification' => [
                    'channel_id'         => 'procut_notifications',
                    'sound'              => 'default',
                    'notification_count' => 1,
                ],
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                ],
                'payload' => [
                    'aps' => [
                        'alert' => [
                            'title' => $title,
                            'body'  => $body,
                        ],
                        'sound' => 'default',
                        'badge' => 1,
                    ],
                ],
            ],
        ];

        $results = [];

        // 1) Topic broadcast (global notifications)
        if (!empty($topic)) {
            $payload = ['message' => array_merge($notificationBase, ['topic' => $topic])];
            $resp    = self::httpPost($url, $payload, $headers);
            $results[] = $resp;
            if (!$resp['ok']) {
                error_log('FcmHelper topic send failed: ' . json_encode($resp));
            }
        }

        // 2) Individual device token delivery (targeted notifications)
        foreach ($tokens as $token) {
            $token = trim((string)$token);
            if (empty($token)) continue;
            $payload   = ['message' => array_merge($notificationBase, ['token' => $token])];
            $resp      = self::httpPost($url, $payload, $headers);
            $results[] = $resp;
        }

        $anySuccess = !empty(array_filter($results, static fn($r) => $r['ok']));
        return ['success' => $anySuccess, 'results' => $results];
    }

    /**
     * Look up a user's registered FCM tokens from the database and send them a targeted push.
     *
     * @param string $userId User ID to send to
     */
    public static function sendToUser(string $userId, string $title, string $body, string $type = 'info'): array
    {
        if (empty($userId)) {
            return ['success' => false, 'error' => 'No user ID provided'];
        }

        try {
            $rows   = Database::fetchAll(
                "SELECT fcm_token FROM device_tokens WHERE user_id = ? AND is_active = 1 ORDER BY updated_at DESC LIMIT 10",
                [$userId]
            );
            $tokens = array_column($rows, 'fcm_token');
        } catch (\Throwable $e) {
            error_log('FcmHelper.sendToUser DB error: ' . $e->getMessage());
            $tokens = [];
        }

        if (empty($tokens)) {
            return ['success' => false, 'error' => 'No registered device tokens found for user ' . $userId];
        }

        return self::send($title, $body, $type, null, $tokens, ['target_user_id' => $userId]);
    }

    // ------------------------------------------------------------------ //
    //  INTERNAL HTTP UTILITY                                               //
    // ------------------------------------------------------------------ //

    /**
     * Make an HTTP POST request using cURL (with file_get_contents fallback).
     *
     * @param string      $url
     * @param array|null  $jsonBody   JSON-encoded body (leave null for raw $rawBody)
     * @param string[]    $headers
     * @param string|null $rawBody    Used when $jsonBody is null (form-encoded etc.)
     * @return array{ok:bool,body:string,code:int}
     */
    private static function httpPost(string $url, ?array $jsonBody, array $headers, ?string $rawBody = null): array
    {
        $postBody = $rawBody !== null ? $rawBody : json_encode($jsonBody);

        if (function_exists('curl_init')) {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_POST           => true,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => 12,
                CURLOPT_CONNECTTIMEOUT => 8,
                CURLOPT_POSTFIELDS     => $postBody,
                CURLOPT_HTTPHEADER     => $headers,
                CURLOPT_SSL_VERIFYPEER => true,
            ]);
            $body = curl_exec($ch);
            $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $err  = curl_error($ch);
            curl_close($ch);

            if ($body === false) {
                error_log("FcmHelper cURL error: $err");
                return ['ok' => false, 'body' => '', 'code' => 0, 'error' => $err];
            }
        } else {
            // Fallback: stream context (available even without cURL)
            $headerStr = implode("\r\n", $headers);
            $context   = stream_context_create([
                'http' => [
                    'method'        => 'POST',
                    'header'        => $headerStr,
                    'content'       => $postBody,
                    'timeout'       => 12,
                    'ignore_errors' => true,
                ],
                'ssl' => [
                    'verify_peer'      => true,
                    'verify_peer_name' => true,
                ],
            ]);
            $body = @file_get_contents($url, false, $context);
            if ($body === false) {
                return ['ok' => false, 'body' => '', 'code' => 0, 'error' => 'file_get_contents failed'];
            }
            $code = 200; // Cannot easily get status code via file_get_contents; treat as OK
        }

        $ok = ($code === 0 || ($code >= 200 && $code < 300));
        // For FCM v1, a successful response contains a 'name' field
        if ($jsonBody !== null && $code >= 200 && $code < 300) {
            $decoded = json_decode($body, true);
            $ok      = isset($decoded['name']);
        }

        return ['ok' => $ok, 'body' => (string)$body, 'code' => $code];
    }
}
