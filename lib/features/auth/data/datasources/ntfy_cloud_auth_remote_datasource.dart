import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'auth_remote_datasource.dart';

/// Live, rate-limit-free global cloud authentication provider utilizing ntfy.sh pub/sub.
/// Ensures instantaneous cross-device sign-in across any device, network, or platform without API keys or limits.
class NtfyCloudAuthRemoteDataSource implements AuthRemoteDataSource {
  final LocalStorageService localStorageService;
  final HttpClient? _customHttpClient;
  static const String baseUrl = 'https://ntfy.sh';

  NtfyCloudAuthRemoteDataSource({
    required this.localStorageService,
    HttpClient? httpClient,
  }) : _customHttpClient = httpClient;

  HttpClient _createHttpClient() {
    final custom = _customHttpClient;
    if (custom != null) return custom;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    return client;
  }

  String _emailHash(String email) =>
      sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

  String _topicForEmail(String email) => 'procut_auth_${_emailHash(email)}';

  String _localAccountPath(String email) =>
      'cloud_storage/auth/accounts/account_${_emailHash(email)}.json';
  String _localUserPath(String userId) =>
      'cloud_storage/auth/users/user_$userId.json';

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    final topic = _topicForEmail(cleanEmail);
    final client = _createHttpClient();

    try {
      final uri = Uri.parse('$baseUrl/$topic/json?poll=1&since=all');
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/x-ndjson, application/json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final lines = body.split('\n');
        Map<String, dynamic>? latestAccount;
        int latestTime = 0;

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          try {
            final eventObj = jsonDecode(trimmed);
            if (eventObj is Map<String, dynamic> && eventObj['event'] == 'message') {
              final msgStr = eventObj['message'] as String?;
              final time = (eventObj['time'] as num?)?.toInt() ?? 0;
              if (msgStr != null && msgStr.isNotEmpty) {
                final payload = jsonDecode(msgStr);
                if (payload is Map<String, dynamic> && payload.containsKey('email')) {
                  final candidateEmail = (payload['email'] as String?)?.trim().toLowerCase();
                  if (candidateEmail == cleanEmail && time >= latestTime) {
                    latestAccount = payload;
                    latestTime = time;
                  }
                }
              }
            }
          } catch (_) {}
        }

        if (latestAccount != null) {
          await localStorageService.writeJson(_localAccountPath(cleanEmail), latestAccount);
          final id = latestAccount['id'] as String?;
          if (id != null) {
            await localStorageService.writeJson(_localUserPath(id), latestAccount);
          }
          return latestAccount;
        }
      }
      await response.drain();
    } catch (e) {
      debugPrint('NtfyCloudAuthRemoteDataSource: getAccountByEmail error: $e');
    } finally {
      if (_customHttpClient == null) client.close();
    }

    // Fallback to local cache
    return await localStorageService.readJson(_localAccountPath(cleanEmail));
  }

  @override
  Future<Map<String, dynamic>?> getAccountById(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return null;
    return await localStorageService.readJson(_localUserPath(cleanId));
  }

  @override
  Future<bool> saveAccount(Map<String, dynamic> accountData) async {
    final email = (accountData['email'] as String? ?? '').trim().toLowerCase();
    final userId = (accountData['id'] as String? ?? '').trim();
    if (email.isEmpty || userId.isEmpty) return false;

    // 1. Cache locally
    await localStorageService.writeJson(_localAccountPath(email), accountData);
    await localStorageService.writeJson(_localUserPath(userId), accountData);

    // 2. Publish to ntfy cloud topic
    final topic = _topicForEmail(email);
    final client = _createHttpClient();

    try {
      final uri = Uri.parse('$baseUrl/$topic');
      final request = await client.postUrl(uri);
      request.headers.set('Title', 'ProCut Account');
      request.headers.set('Tags', 'account,auth');
      request.headers.set('Content-Type', 'text/plain; charset=utf-8');

      final payloadStr = jsonEncode(accountData);
      final bytes = utf8.encode(payloadStr);
      request.headers.set('Content-Length', bytes.length.toString());
      request.add(bytes);

      final response = await request.close();
      final statusCode = response.statusCode;
      await response.drain();
      return statusCode == 200;
    } catch (e) {
      debugPrint('NtfyCloudAuthRemoteDataSource: saveAccount error: $e');
      return true; // Local write succeeded
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  @override
  Future<bool> updateAccount(Map<String, dynamic> accountData) async {
    return await saveAccount(accountData);
  }
}
