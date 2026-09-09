import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:procut/core/config/server_config.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'auth_remote_datasource.dart';

/// Dedicated MySQL Cloud Authentication Provider connecting to ProCut's backend server.
class MySqlAuthRemoteDataSource implements AuthRemoteDataSource {
  final LocalStorageService localStorageService;
  final HttpClient? _customHttpClient;

  MySqlAuthRemoteDataSource({
    required this.localStorageService,
    HttpClient? httpClient,
  }) : _customHttpClient = httpClient;

  HttpClient _createHttpClient() {
    final custom = _customHttpClient;
    if (custom != null) return custom;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    return client;
  }

  String _localAccountPath(String email) =>
      'cloud_storage/auth/accounts/account_${email.trim().toLowerCase().hashCode}.json';
  String _localUserPath(String userId) =>
      'cloud_storage/auth/users/user_$userId.json';

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    final baseUrl = await ServerConfig.getBaseUrl();
    final client = _createHttpClient();

    try {
      final uri = Uri.parse('$baseUrl/api/auth/account?email=${Uri.encodeComponent(cleanEmail)}');
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic> && decoded['email'] != null) {
          await localStorageService.writeJson(_localAccountPath(cleanEmail), decoded);
          final id = decoded['id'] as String?;
          if (id != null) {
            await localStorageService.writeJson(_localUserPath(id), decoded);
          }
          return decoded;
        }
      }
      await response.drain();
    } catch (e) {
      debugPrint('MySqlAuthRemoteDataSource.getAccountByEmail server query error: $e');
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

    // Cache locally
    await localStorageService.writeJson(_localAccountPath(email), accountData);
    await localStorageService.writeJson(_localUserPath(userId), accountData);

    // Save to MySQL server if password is provided
    final password = accountData['password'] as String?;
    final displayName = accountData['displayName'] as String? ?? 'ProCut Creator';

    if (password != null && password.isNotEmpty) {
      final baseUrl = await ServerConfig.getBaseUrl();
      final client = _createHttpClient();
      try {
        final uri = Uri.parse('$baseUrl/api/auth/register');
        final request = await client.postUrl(uri);
        request.headers.set('Content-Type', 'application/json');
        final payload = jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName,
        });
        request.add(utf8.encode(payload));
        final response = await request.close();
        final ok = response.statusCode == 200 || response.statusCode == 201;
        await response.drain();
        return ok;
      } catch (e) {
        debugPrint('MySqlAuthRemoteDataSource.saveAccount server error: $e');
      } finally {
        if (_customHttpClient == null) client.close();
      }
    }

    return true;
  }

  @override
  Future<bool> updateAccount(Map<String, dynamic> accountData) async {
    return await saveAccount(accountData);
  }

  /// Direct server login
  Future<Map<String, dynamic>?> loginOnServer(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final baseUrl = await ServerConfig.getBaseUrl();
    final client = _createHttpClient();

    try {
      final uri = Uri.parse('$baseUrl/api/auth/login');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      final payload = jsonEncode({
        'email': cleanEmail,
        'password': password,
      });
      request.add(utf8.encode(payload));

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          await localStorageService.writeJson(_localAccountPath(cleanEmail), decoded);
          final id = decoded['id'] as String?;
          if (id != null) {
            await localStorageService.writeJson(_localUserPath(id), decoded);
          }
          return decoded;
        }
      }
      await response.drain();
    } catch (e) {
      debugPrint('MySqlAuthRemoteDataSource.loginOnServer error: $e');
    } finally {
      if (_customHttpClient == null) client.close();
    }
    return null;
  }

  /// Direct server password reset
  Future<bool> forgotPasswordOnServer(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    final baseUrl = await ServerConfig.getBaseUrl();
    final client = _createHttpClient();

    try {
      final uri = Uri.parse('$baseUrl/api/auth/forgot-password');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      final payload = jsonEncode({
        'email': cleanEmail,
        'newPassword': newPassword,
      });
      request.add(utf8.encode(payload));

      final response = await request.close();
      final ok = response.statusCode == 200;
      await response.drain();
      return ok;
    } catch (e) {
      debugPrint('MySqlAuthRemoteDataSource.forgotPasswordOnServer error: $e');
      return false;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }
}
