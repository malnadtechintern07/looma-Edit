import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const String _prefKey = 'procut_server_base_url';

  // Primary server address.
  // - Physical devices on local network: http://192.168.31.248:5050
  // - Android Emulator: http://10.0.2.2:5050 or http://192.168.31.248:5050
  // - Localhost (macOS / desktop): http://127.0.0.1:5050
  static const String defaultLocalIp = '192.168.31.248';
  static const int defaultPort = 5050;

  static String? _cachedUrl;

  static String get defaultUrl {
    if (kIsWeb) return 'http://localhost:$defaultPort';
    if (Platform.isAndroid) {
      // Use the local network Wi-Fi IP so both physical phones and emulators can connect directly
      return 'http://$defaultLocalIp:$defaultPort';
    }
    return 'http://127.0.0.1:$defaultPort';
  }

  /// Gets the currently configured server base URL (without trailing slash)
  static Future<String> getBaseUrl() async {
    if (_cachedUrl != null) return _cachedUrl!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _cachedUrl = saved.trim();
        return _cachedUrl!;
      }
    } catch (_) {}
    _cachedUrl = defaultUrl;
    return _cachedUrl!;
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

  /// Resets back to the default URL
  static Future<void> resetToDefault() async {
    _cachedUrl = defaultUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }
}
