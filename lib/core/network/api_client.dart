import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight response container
class ApiResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  const ApiResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  bool get isOk => statusCode >= 200 && statusCode < 300;

  dynamic get json {
    try {
      final trimmed = body.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        return jsonDecode(trimmed);
      }
    } catch (_) {}
    return null;
  }
}

/// Production-grade API Client with automatic InfinityFree AES bot protection bypass,
/// persistent cookie jar, browser User-Agent spoofing, and automatic 301/302 redirect handling.
class ApiClient {
  static const String _cookiePrefKeyPrefix = 'procut_api_cookie_';
  static const String defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  // In-memory cookie storage per host (e.g., 'procut.free.nf' -> {'__test': '...'})
  static final Map<String, Map<String, String>> _cookieJar = {};

  /// Synchronous or cached cookie header for a given URI host
  static String? getCookieHeader(String host) {
    final cookies = _cookieJar[host];
    if (cookies == null || cookies.isEmpty) return null;
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// Sets a cookie for a host in-memory and persists it asynchronously
  static Future<void> setCookie(String host, String name, String value) async {
    _cookieJar.putIfAbsent(host, () => {})[name] = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cookiePrefKeyPrefix${host}_$name', value);
    } catch (_) {}
  }

  /// Loads previously saved cookies from SharedPreferences
  static Future<void> loadPersistedCookies(String host) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final testCookie = prefs.getString('$_cookiePrefKeyPrefix${host}___test');
      if (testCookie != null && testCookie.isNotEmpty) {
        _cookieJar.putIfAbsent(host, () => {})['__test'] = testCookie;
      }
    } catch (_) {}
  }

  /// Solves InfinityFree's slowAES challenge if present in the response body
  static String? solveAesChallenge(String html) {
    final aMatch = RegExp(r'a=toNumbers\("([0-9a-fA-F]+)"\)').firstMatch(html);
    final bMatch = RegExp(r'b=toNumbers\("([0-9a-fA-F]+)"\)').firstMatch(html);
    final cMatch = RegExp(r'c=toNumbers\("([0-9a-fA-F]+)"\)').firstMatch(html);

    if (aMatch != null && bMatch != null && cMatch != null) {
      try {
        final keyBytes = _hexToBytes(aMatch.group(1)!);
        final ivBytes = _hexToBytes(bMatch.group(1)!);
        final cipherBytes = _hexToBytes(cMatch.group(1)!);

        final encrypter = enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc, padding: null));
        final decrypted = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: enc.IV(ivBytes));
        return _bytesToHex(decrypted);
      } catch (e) {
        debugPrint('ApiClient: Error solving AES challenge: $e');
      }
    }
    return null;
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Performs a GET request with automatic challenge solving and redirects
  static Future<ApiResponse> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 6),
    int redirectCount = 0,
  }) async {
    return _sendWithRetry(
      method: 'GET',
      uri: uri,
      headers: headers,
      timeout: timeout,
      redirectCount: redirectCount,
    );
  }

  /// Performs a POST request with automatic challenge solving
  static Future<ApiResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    return _sendWithRetry(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
      timeout: timeout,
    );
  }

  /// Performs a DELETE request
  static Future<ApiResponse> delete(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    return _sendWithRetry(
      method: 'DELETE',
      uri: uri,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Core HTTP execution loop that handles headers, cookies, redirects, and AES challenge retry
  static Future<ApiResponse> _sendWithRetry({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 6),
    int redirectCount = 0,
    bool isChallengeRetry = false,
  }) async {
    if (redirectCount > 5) {
      return const ApiResponse(statusCode: 310, body: 'Too many redirects');
    }

    // Load persisted cookies if host not loaded yet
    if (!_cookieJar.containsKey(uri.host)) {
      await loadPersistedCookies(uri.host);
    }

    final client = HttpClient()..connectionTimeout = timeout;

    try {
      HttpClientRequest request;
      if (method == 'POST') {
        request = await client.postUrl(uri).timeout(timeout);
      } else if (method == 'DELETE') {
        request = await client.deleteUrl(uri).timeout(timeout);
      } else {
        request = await client.getUrl(uri).timeout(timeout);
      }

      request.followRedirects = false;

      // 1. Standard Browser User-Agent & Accept headers
      request.headers.set('User-Agent', defaultUserAgent);
      request.headers.set('Accept', 'application/json, text/html, */*');

      // 2. Custom headers
      headers?.forEach((k, v) => request.headers.set(k, v));

      // 3. Attach Cookies
      final cookieHeader = getCookieHeader(uri.host);
      if (cookieHeader != null && cookieHeader.isNotEmpty) {
        request.headers.set('Cookie', cookieHeader);
      }

      // 4. Request Body
      if (body != null) {
        if (body is String) {
          final ct = request.headers.value('content-type');
          if (ct == null || !ct.contains('json')) {
            request.headers.set('Content-Type', 'application/json; charset=utf-8');
          }
          request.add(utf8.encode(body));
        } else if (body is List<int>) {
          request.add(body);
        } else if (body is Map || body is List) {
          request.headers.set('Content-Type', 'application/json; charset=utf-8');
          request.add(utf8.encode(jsonEncode(body)));
        }
      }

      final response = await request.close().timeout(timeout);

      // Save any Set-Cookie headers
      for (final cookie in response.cookies) {
        await setCookie(uri.host, cookie.name, cookie.value);
      }

      // Follow 301/302/307 redirects
      if (response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 307 ||
          response.statusCode == 308) {
        final location = response.headers.value('location');
        if (location != null && location.isNotEmpty) {
          final nextUri = uri.resolve(location);
          await response.drain();
          client.close();
          final nextMethod = (response.statusCode == 307 || response.statusCode == 308) ? method : 'GET';
          return await _sendWithRetry(
            method: nextMethod,
            uri: nextUri,
            headers: headers,
            body: (nextMethod == method) ? body : null,
            timeout: timeout,
            redirectCount: redirectCount + 1,
          );
        }
      }

      final responseBody = await response.transform(utf8.decoder).join().timeout(timeout);
      client.close();

      // Check if this response is an InfinityFree slowAES challenge
      if (!isChallengeRetry &&
          (responseBody.contains('slowAES.decrypt') || responseBody.contains('/aes.js'))) {
        final solvedCookie = solveAesChallenge(responseBody);
        if (solvedCookie != null && solvedCookie.isNotEmpty) {
          debugPrint('ApiClient: Successfully solved InfinityFree AES challenge for ${uri.host}');
          await setCookie(uri.host, '__test', solvedCookie);

          // Retry request with solved cookie!
          return await _sendWithRetry(
            method: method,
            uri: uri,
            headers: headers,
            body: body,
            timeout: timeout,
            redirectCount: redirectCount,
            isChallengeRetry: true,
          );
        }
      }

      final respHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        respHeaders[name] = values.join(', ');
      });

      return ApiResponse(
        statusCode: response.statusCode,
        body: responseBody,
        headers: respHeaders,
      );
    } catch (e) {
      client.close();
      return ApiResponse(statusCode: 0, body: e.toString());
    }
  }
}
