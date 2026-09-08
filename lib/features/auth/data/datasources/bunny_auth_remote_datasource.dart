import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/features/cloud_sync/data/datasources/bunny_storage_service.dart';
import 'package:looma/features/cloud_sync/domain/entities/bunny_storage_config.dart';
import 'auth_remote_datasource.dart';

/// Bunny.net Edge Cloud Storage implementation for multi-device authentication,
/// with offline resilience and local cloud cache fallback.
class BunnyAuthRemoteDataSource implements AuthRemoteDataSource {
  final LocalStorageService localStorageService;
  final BunnyStorageConfig config;
  final BunnyStorageService bunnyService;

  BunnyAuthRemoteDataSource({
    required this.localStorageService,
    required this.config,
    BunnyStorageService? bunnyStorageService,
  }) : bunnyService = bunnyStorageService ?? BunnyStorageService(config: config);

  String _emailHash(String email) =>
      sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

  // Remote Bunny.net paths
  String _remoteAccountPath(String email) =>
      'looma/auth/accounts/account_${_emailHash(email)}.json';
  String _remoteUserPath(String userId) =>
      'looma/auth/users/user_$userId.json';
  static const String _remoteCatalogPath = 'looma/auth/catalog.json';

  // Local cloud fallback paths (enables cross-device simulation and offline resiliency)
  String _localAccountPath(String email) =>
      'cloud_storage/auth/accounts/account_${_emailHash(email)}.json';
  String _localUserPath(String userId) =>
      'cloud_storage/auth/users/user_$userId.json';
  static const String _localCatalogPath = 'cloud_storage/auth/catalog.json';

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    // 1. Try fetching directly from Bunny.net Edge Cloud
    try {
      final remoteContent = await bunnyService.downloadFile(_remoteAccountPath(cleanEmail));
      if (remoteContent != null && remoteContent.trim().isNotEmpty) {
        final decoded = jsonDecode(remoteContent);
        if (decoded is Map<String, dynamic>) {
          // Cache remotely verified account locally for offline resilience
          await localStorageService.writeJson(_localAccountPath(cleanEmail), decoded);
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('BunnyAuthRemoteDataSource: getAccountByEmail network check: $e');
    }

    // 2. Fallback to local cloud storage cache
    final localJson = await localStorageService.readJson(_localAccountPath(cleanEmail));
    if (localJson != null) {
      return localJson;
    }

    // 3. Fallback scan via catalog if individual hash file not directly resolved
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

    // 1. Try downloading from Bunny.net
    try {
      final remoteContent = await bunnyService.downloadFile(_remoteUserPath(cleanId));
      if (remoteContent != null && remoteContent.trim().isNotEmpty) {
        final decoded = jsonDecode(remoteContent);
        if (decoded is Map<String, dynamic>) {
          await localStorageService.writeJson(_localUserPath(cleanId), decoded);
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('BunnyAuthRemoteDataSource: getAccountById network check: $e');
    }

    // 2. Fallback to local cache
    return await localStorageService.readJson(_localUserPath(cleanId));
  }

  @override
  Future<bool> saveAccount(Map<String, dynamic> accountData) async {
    final email = (accountData['email'] as String? ?? '').trim().toLowerCase();
    final userId = (accountData['id'] as String? ?? '').trim();
    if (email.isEmpty || userId.isEmpty) return false;

    final jsonString = jsonEncode(accountData);
    final bytes = utf8.encode(jsonString);

    // 1. Always persist to local cloud cache
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

    // 2. Upload account to Bunny.net cloud storage
    try {
      await bunnyService.uploadFile(_remoteAccountPath(email), bytes);
      await bunnyService.uploadFile(_remoteUserPath(userId), bytes);

      // Upload catalog snapshot
      final catalogRaw = await localStorageService.readString(_localCatalogPath);
      if (catalogRaw != null) {
        await bunnyService.uploadFile(_remoteCatalogPath, utf8.encode(catalogRaw));
      }
      return true;
    } catch (e) {
      debugPrint('BunnyAuthRemoteDataSource: saveAccount upload error: $e');
      return true; // Local cloud cache succeeded
    }
  }

  @override
  Future<bool> updateAccount(Map<String, dynamic> accountData) async {
    return await saveAccount(accountData);
  }
}
