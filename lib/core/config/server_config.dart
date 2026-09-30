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

  /// Gets the currently configured server base URL instantly without blocking network timeouts.
  static Future<String> getBaseUrl({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUrl != null) {
      return _cachedUrl!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey)?.trim();
      if (saved != null && saved.isNotEmpty) {
        _cachedUrl = saved;
        return saved;
      }
    } catch (_) {}

    _cachedUrl = defaultUrl;
    return defaultUrl;
  }

  /// Explicitly auto-detects reachable server (used when user tests/detects server in Settings)
  static Future<String> autoDetectServerCandidates() async {
    final candidates = <String>[
      liveHostUrl,
      'http://$defaultLocalIp:$defaultPort',
      if (!kIsWeb && Platform.isAndroid) 'http://10.0.2.2:$defaultPort',
      'http://127.0.0.1:$defaultPort',
      'http://localhost:$defaultPort',
    ];

    for (final candidate in candidates) {
      if (await isReachable(candidate, timeoutMs: 2500)) {
        debugPrint('ServerConfig: Connected to backend at $candidate');
        await setBaseUrl(candidate);
        return candidate;
      }
    }

    return defaultUrl;
  }

  static final List<void Function(String newUrl)> _listeners = [];

  static void addListener(void Function(String newUrl) listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function(String newUrl) listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners(String url) {
    for (final listener in List.of(_listeners)) {
      try {
        listener(url);
      } catch (_) {}
    }
  }

  /// Sets and persists a custom server base URL
  static Future<void> setBaseUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    _cachedUrl = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, clean);
    } catch (_) {}
    _notifyListeners(clean);
  }

  /// Resets back to the live production URL
  static Future<void> resetToDefault() async {
    _cachedUrl = liveHostUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, liveHostUrl);
    } catch (_) {}
    _notifyListeners(liveHostUrl);
  }
}
