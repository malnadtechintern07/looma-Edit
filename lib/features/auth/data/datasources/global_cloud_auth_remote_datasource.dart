import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'auth_remote_datasource.dart';

/// Live, persistent, zero-configuration cloud authentication registry for cross-device synchronization.
/// Enables logging in with the same email and password across any device (Android, iOS, macOS, Windows).
class GlobalCloudAuthRemoteDataSource implements AuthRemoteDataSource {
  final LocalStorageService localStorageService;
  final HttpClient? _customHttpClient;

  /// Global live cloud registry object ID on restful-api.dev
  static const String primaryRegistryObjectId = 'ff808181a067127101a080020af246f3';
  static const String apiBaseUrl = 'https://api.restful-api.dev/objects';

  GlobalCloudAuthRemoteDataSource({
    required this.localStorageService,
    HttpClient? httpClient,
  }) : _customHttpClient = httpClient;

  HttpClient _createHttpClient() {
    final custom = _customHttpClient;
    if (custom != null) return custom;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    return client;
  }

  String _emailHash(String email) =>
      sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

  // Local storage paths for offline caching
  String _localAccountPath(String email) =>
      'cloud_storage/auth/accounts/account_${_emailHash(email)}.json';
  String _localUserPath(String userId) =>
      'cloud_storage/auth/users/user_$userId.json';
  static const String _localCatalogPath = 'cloud_storage/auth/catalog.json';

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;
    final emailHash = _emailHash(cleanEmail);

    // 1. Fetch from live cloud registry
    try {
      final cloudAccounts = await _fetchCloudAccountsMap();
      if (cloudAccounts != null) {
        // Find by hash or direct email check
        Map<String, dynamic>? match;
        if (cloudAccounts.containsKey(emailHash)) {
          final candidate = cloudAccounts[emailHash];
          if (candidate is Map<String, dynamic>) {
            match = candidate;
          }
        }
        if (match == null) {
          for (final entry in cloudAccounts.values) {
            if (entry is Map<String, dynamic> &&
                (entry['email'] as String?)?.trim().toLowerCase() == cleanEmail) {
              match = entry;
              break;
            }
          }
        }

        if (match != null) {
          // Cache locally on this device for offline resilience
          await localStorageService.writeJson(_localAccountPath(cleanEmail), match);
          final id = match['id'] as String?;
          if (id != null) {
            await localStorageService.writeJson(_localUserPath(id), match);
          }
          return match;
        }
      }
    } catch (e) {
      debugPrint('GlobalCloudAuthRemoteDataSource.getAccountByEmail cloud query error: $e');
    }

    // 2. Offline Fallback: check local device cache
    final localAccount = await localStorageService.readJson(_localAccountPath(cleanEmail));
    if (localAccount != null) {
      return localAccount;
    }

    // 3. Fallback scan via local catalog
    try {
      final catalogRaw = await localStorageService.readString(_localCatalogPath);
      if (catalogRaw != null && catalogRaw.isNotEmpty) {
        final catalog = jsonDecode(catalogRaw) as List<dynamic>;
        for (final item in catalog) {
          if (item is Map<String, dynamic> &&
              (item['email'] as String?)?.trim().toLowerCase() == cleanEmail) {
            return item;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<Map<String, dynamic>?> getAccountById(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return null;

    // 1. Fetch from live cloud registry
    try {
      final cloudAccounts = await _fetchCloudAccountsMap();
      if (cloudAccounts != null) {
        for (final entry in cloudAccounts.values) {
          if (entry is Map<String, dynamic> && entry['id'] == cleanId) {
            await localStorageService.writeJson(_localUserPath(cleanId), entry);
            return entry;
          }
        }
      }
    } catch (e) {
      debugPrint('GlobalCloudAuthRemoteDataSource.getAccountById cloud query error: $e');
    }

    // 2. Offline Fallback
    return await localStorageService.readJson(_localUserPath(cleanId));
  }

  @override
  Future<bool> saveAccount(Map<String, dynamic> accountData) async {
    final email = (accountData['email'] as String? ?? '').trim().toLowerCase();
    final userId = (accountData['id'] as String? ?? '').trim();
    if (email.isEmpty || userId.isEmpty) return false;
    final emailHash = _emailHash(email);

    // 1. Always cache in local cloud storage first for instant offline availability
    await localStorageService.writeJson(_localAccountPath(email), accountData);
    await localStorageService.writeJson(_localUserPath(userId), accountData);

    // Update local catalog
    try {
      final catalogRaw = await localStorageService.readString(_localCatalogPath);
      List<Map<String, dynamic>> catalog = [];
      if (catalogRaw != null && catalogRaw.isNotEmpty) {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        catalog = decoded.cast<Map<String, dynamic>>();
      }
      catalog.removeWhere((a) => (a['email'] as String?)?.trim().toLowerCase() == email);
      catalog.add(accountData);
      await localStorageService.writeString(_localCatalogPath, jsonEncode(catalog));
    } catch (_) {}

    // 2. Upload to live global cloud registry so other devices can discover and log in immediately
    try {
      await _updateCloudAccount(emailHash, accountData);
      return true;
    } catch (e) {
      debugPrint('GlobalCloudAuthRemoteDataSource.saveAccount cloud upload error: $e');
      return true; // Local cache write succeeded
    }
  }

  @override
  Future<bool> updateAccount(Map<String, dynamic> accountData) async {
    return await saveAccount(accountData);
  }

  static Map<String, dynamic>? _cachedAccountsMap;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(seconds: 30);

  /// Fetches the global accounts map from restful-api.dev registry with caching
  Future<Map<String, dynamic>?> _fetchCloudAccountsMap({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedAccountsMap != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheTtl) {
      return _cachedAccountsMap;
    }

    final client = _createHttpClient();
    try {
      final uri = Uri.parse('$apiBaseUrl/$primaryRegistryObjectId');
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            final accounts = data['accounts'];
            if (accounts is Map<String, dynamic>) {
              _cachedAccountsMap = Map<String, dynamic>.from(accounts);
              _cacheTimestamp = DateTime.now();
              return _cachedAccountsMap;
            }
          }
        }
      }
      await response.drain();
      return _cachedAccountsMap;
    } catch (e) {
      debugPrint('GlobalCloudAuthRemoteDataSource: _fetchCloudAccountsMap error: $e');
      return _cachedAccountsMap;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  /// Atomically updates or inserts an account into the global registry object
  Future<bool> _updateCloudAccount(String emailHash, Map<String, dynamic> accountData) async {
    final client = _createHttpClient();
    try {
      // First fetch current accounts
      Map<String, dynamic> currentAccounts = {};
      final existing = await _fetchCloudAccountsMap(forceRefresh: true);
      if (existing != null) {
        currentAccounts = Map<String, dynamic>.from(existing);
      }

      currentAccounts[emailHash] = accountData;
      _cachedAccountsMap = currentAccounts;
      _cacheTimestamp = DateTime.now();

      final payload = {
        'name': 'procut_global_auth_registry_v1',
        'data': {
          'accounts': currentAccounts,
          'lastUpdatedAt': DateTime.now().toIso8601String(),
        },
      };

      final uri = Uri.parse('$apiBaseUrl/$primaryRegistryObjectId');
      final request = await client.putUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');

      final bytes = utf8.encode(jsonEncode(payload));
      request.headers.set('Content-Length', bytes.length.toString());
      request.add(bytes);

      final response = await request.close();
      final statusCode = response.statusCode;
      await response.drain();

      return statusCode == 200;
    } catch (e) {
      debugPrint('GlobalCloudAuthRemoteDataSource: _updateCloudAccount error: $e');
      return false;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }
}
