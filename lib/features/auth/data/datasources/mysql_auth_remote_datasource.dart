import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:procut/core/config/server_config.dart';
import 'package:procut/core/network/api_client.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'auth_remote_datasource.dart';

/// Dedicated MySQL Cloud Authentication Provider connecting to ProCut's backend server.
class MySqlAuthRemoteDataSource implements AuthRemoteDataSource {
  final LocalStorageService localStorageService;

  MySqlAuthRemoteDataSource({
    required this.localStorageService,
    HttpClient? httpClient,
  });

  String _localAccountPath(String email) =>
      'cloud_storage/auth/accounts/account_${email.trim().toLowerCase().hashCode}.json';
  String _localUserPath(String userId) =>
      'cloud_storage/auth/users/user_$userId.json';

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    final baseUrl = await ServerConfig.getBaseUrl();

    try {
      final uri = Uri.parse('$baseUrl/api/auth/account?email=${Uri.encodeComponent(cleanEmail)}');
      final response = await ApiClient.get(uri);
      if (response.isOk && response.json is Map) {
        final decoded = response.json as Map<String, dynamic>;
        if (decoded['email'] != null) {
          await localStorageService.writeJson(_localAccountPath(cleanEmail), decoded);
          final id = decoded['id'] as String?;
          if (id != null) {
            await localStorageService.writeJson(_localUserPath(id), decoded);
          }
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('MySqlAuthRemoteDataSource.getAccountByEmail server query error: $e');
    }

    // Fallback to local cache
    return await localStorageService.readJson(_localAccountPath(cleanEmail));
  }

  /// Check if an email is registered on the server (no credentials returned)
  @override
  Future<bool> checkEmailExists(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;
    final baseUrl = await ServerConfig.getBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/auth/check?email=${Uri.encodeComponent(cleanEmail)}');
      final response = await ApiClient.get(uri);
      if (response.isOk && response.json is Map) {
        final decoded = response.json as Map<String, dynamic>;
        return decoded['exists'] == true;
      }
    } catch (e) {
      debugPrint('MySqlAuthRemoteDataSource.checkEmailExists error: $e');
    }
    return false;
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
    if (email.isEmpty && userId.isEmpty) return false;

    // 1. Cache locally
    if (email.isNotEmpty) {
      await localStorageService.writeJson(_localAccountPath(email), accountData);
    }
    if (userId.isNotEmpty) {
      await localStorageService.writeJson(_localUserPath(userId), accountData);
    }

    // 2. Persist to server via dedicated /api/auth/save-account endpoint
    final baseUrl = await ServerConfig.getBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/auth/save-account');
      final response = await ApiClient.post(uri, body: accountData);
      return response.isOk;
    } catch (e) {
      debugPrint('MySqlAuthRemoteDataSource.saveAccount server error: $e');
    }

    return true;
  }

  @override
  Future<bool> updateAccount(Map<String, dynamic> accountData) async {
    final email = (accountData['email'] as String? ?? '').trim().toLowerCase();
    final userId = (accountData['id'] as String? ?? '').trim();
    if (email.isEmpty && userId.isEmpty) return false;

    // Cache locally
    if (email.isNotEmpty) {
      await localStorageService.writeJson(_localAccountPath(email), accountData);
    }
    if (userId.isNotEmpty) {
      await localStorageService.writeJson(_localUserPath(userId), accountData);
    }

    final displayName = accountData['displayName'] as String?;
    final baseUrl = await ServerConfig.getBaseUrl();

    try {
      final uri = Uri.parse('$baseUrl/api/auth/update-profile');
      final response = await ApiClient.post(uri, body: {
        'email': email,
        'id': userId,
        'displayName': displayName,
      });
      return response.isOk;
    } catch (e) {
      debugPrint('MySqlAuthRemoteDataSource.updateAccount error: $e');
      return true; // Local cached successfully
    }
  }

  /// Direct server registration with bcrypt password hashing in MySQL
  @override
  Future<Map<String, dynamic>> register(String email, String password, String displayName) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim();
    final baseUrl = await ServerConfig.getBaseUrl();

    try {
      final uri = Uri.parse('$baseUrl/api/auth/register');
      final response = await ApiClient.post(
        uri,
        body: {
          'email': cleanEmail,
          'password': password,
          'displayName': cleanName,
        },
      );

      final decoded = response.json is Map ? response.json as Map<String, dynamic> : null;

      if (response.isOk && decoded != null) {
        Map<String, dynamic> userData;
        if (decoded['data'] is Map<String, dynamic>) {
          final dataMap = decoded['data'] as Map<String, dynamic>;
          userData = dataMap['user'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(dataMap['user'] as Map)
              : Map<String, dynamic>.from(dataMap);
        } else {
          userData = Map<String, dynamic>.from(decoded);
        }

        // Cache locally for offline availability
        await localStorageService.writeJson(_localAccountPath(cleanEmail), userData);
        final id = userData['id'] as String?;
        if (id != null) {
          await localStorageService.writeJson(_localUserPath(id), userData);
        }
        return userData;
      }

      final errorMsg = decoded != null && decoded['message'] != null
          ? decoded['message'].toString()
          : (response.statusCode == 409
              ? 'An account with this email already exists. Please log in or reset password.'
              : 'Registration failed (code: ${response.statusCode})');

      throw Exception(errorMsg);
    } on SocketException catch (_) {
      throw Exception('Unable to reach ProCut server at $baseUrl. Please verify your connection or server settings.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to register account: $e');
    }
  }

  /// Direct server login
  @override
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final baseUrl = await ServerConfig.getBaseUrl();

    try {
      final uri = Uri.parse('$baseUrl/api/auth/login');
      final response = await ApiClient.post(
        uri,
        body: {
          'email': cleanEmail,
          'password': password,
        },
      );

      final decoded = response.json is Map ? response.json as Map<String, dynamic> : null;

      if (response.statusCode == 200 && decoded != null) {
        // Unpack user map
        Map<String, dynamic> userData;
        if (decoded['data'] is Map<String, dynamic>) {
          final dataMap = decoded['data'] as Map<String, dynamic>;
          userData = dataMap['user'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(dataMap['user'] as Map)
              : Map<String, dynamic>.from(dataMap);
        } else {
          userData = Map<String, dynamic>.from(decoded);
        }

        // Cache locally for offline availability
        await localStorageService.writeJson(_localAccountPath(cleanEmail), userData);
        final id = userData['id'] as String?;
        if (id != null) {
          await localStorageService.writeJson(_localUserPath(id), userData);
        }
        return userData;
      }

      final errorMsg = decoded != null && decoded['message'] != null
          ? decoded['message'].toString()
          : (response.statusCode == 401
              ? 'Incorrect password. Please try again or tap Forgot Password.'
              : response.statusCode == 404
                  ? 'No account found with this email. Please create an account first.'
                  : response.statusCode == 403
                      ? 'This account has been suspended by an administrator.'
                      : 'Authentication failed (code: ${response.statusCode})');

      throw Exception(errorMsg);
    } on SocketException catch (_) {
      throw Exception('Unable to reach ProCut server at $baseUrl. Please verify your connection or server settings.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to sign in: $e');
    }
  }

  /// Alias for backward compatibility
  Future<Map<String, dynamic>?> loginOnServer(String email, String password) =>
      login(email, password);

  /// Direct server password reset
  @override
  Future<bool> forgotPassword(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    final baseUrl = await ServerConfig.getBaseUrl();

    try {
      final uri = Uri.parse('$baseUrl/api/auth/forgot-password');
      final response = await ApiClient.post(
        uri,
        body: {
          'email': cleanEmail,
          'newPassword': newPassword,
        },
      );

      final decoded = response.json is Map ? response.json as Map<String, dynamic> : null;

      if (response.isOk) {
        return true;
      }

      final errorMsg = decoded != null && decoded['message'] != null
          ? decoded['message'].toString()
          : (response.statusCode == 404
              ? 'No account found with this email address.'
              : 'Password reset failed (code: ${response.statusCode})');
      throw Exception(errorMsg);
    } on SocketException catch (_) {
      throw Exception('Unable to reach ProCut server at $baseUrl.');
    }
  }

  /// Alias for backward compatibility
  Future<bool> forgotPasswordOnServer(String email, String newPassword) =>
      forgotPassword(email, newPassword);
}
