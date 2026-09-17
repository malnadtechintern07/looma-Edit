import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class ServerConfig {
  static const String _prefKey = 'procut_server_base_url';

  // Live Production Host URL (InfinityFree Hosted Admin Panel)
  static const String liveHostUrl = 'http://procut.free.nf';

  // Local development fallback
  static const String defaultLocalIp = '192.168.31.251';
  static const int defaultPort = 5050;

  static String? _cachedUrl;

  /// Synchronous fallback / current active base URL
  static String get baseUrl => _cachedUrl ?? defaultUrl;

  /// Production-first default URL
  static String get defaultUrl => liveHostUrl;

  /// Verifies if a given server URL is currently reachable using ApiClient
  static Future<bool> isReachable(String url, {int timeoutMs = 6000}) async {
    try {
      final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
      final res = await ApiClient.get(
        Uri.parse('$clean/api/health'),
        timeout: Duration(milliseconds: timeoutMs),
      );
      if (res.isOk && res.json is Map) {
        final map = res.json as Map<String, dynamic>;
        return map['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Detailed health check result for diagnostics UI in Settings
  static Future<Map<String, dynamic>?> checkHealthDetails() async {
    try {
      final baseUrl = await getBaseUrl();
      final stopwatch = Stopwatch()..start();
      final res = await ApiClient.get(
        Uri.parse('$baseUrl/api/health'),
        timeout: const Duration(seconds: 10),
      );
      stopwatch.stop();

      if (res.isOk && res.json is Map) {
        final json = Map<String, dynamic>.from(res.json as Map);
        json['latencyMs'] = stopwatch.elapsedMilliseconds;
        json['url'] = baseUrl;
        json['status'] = (json['success'] == true) ? 'ok' : 'error';
        json['databaseConnected'] = json['database'] != null && json['database'].toString().isNotEmpty;
        _cachedUrl = baseUrl;
        return json;
      }
    } catch (_) {}
    return null;
  }

  /// Gets the currently configured or auto-detected server base URL
  static Future<String> getBaseUrl({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUrl != null) {
      if (await isReachable(_cachedUrl!, timeoutMs: 3000)) {
        return _cachedUrl!;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey)?.trim();
      if (saved != null && saved.isNotEmpty) {
        if (await isReachable(saved, timeoutMs: 4000)) {
          _cachedUrl = saved;
          return saved;
        }
      }
    } catch (_) {}

    // Priority candidates: 1. Live production server, 2. LAN IP, 3. Emulator, 4. Localhost
    final candidates = <String>[
      liveHostUrl,
      'http://$defaultLocalIp:$defaultPort',
      if (!kIsWeb && Platform.isAndroid) 'http://10.0.2.2:$defaultPort',
      'http://127.0.0.1:$defaultPort',
      'http://localhost:$defaultPort',
    ];

    final detected = await _autoDetectServer(candidates);
    _cachedUrl = detected;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, detected);
    } catch (_) {}
    return detected;
  }

  static Future<String> _autoDetectServer(List<String> candidates) async {
    // Check live server first
    for (final candidate in candidates) {
      if (await isReachable(candidate, timeoutMs: 5000)) {
        debugPrint('ServerConfig: Connected to backend at $candidate');
        return candidate;
      }
    }

    // Default to live production server if offline
    return liveHostUrl;
  }

  /// Sets and persists a custom server base URL
  static Future<void> setBaseUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    _cachedUrl = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, clean);
    } catch (_) {}
  }

  /// Resets back to the live production URL
  static Future<void> resetToDefault() async {
    _cachedUrl = liveHostUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, liveHostUrl);
    } catch (_) {}
  }
}
