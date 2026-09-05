import 'dart:convert';
import 'package:looma/core/storage/local_storage_service.dart';

abstract class AuthLocalDataSource {
  Future<List<Map<String, dynamic>>> getAccounts();
  Future<Map<String, dynamic>?> getAccountByEmail(String email);
  Future<Map<String, dynamic>?> getAccountById(String id);
  Future<void> saveAccount(Map<String, dynamic> accountData);
  Future<void> updateAccount(Map<String, dynamic> accountData);
  Future<void> saveSession(String userId, bool rememberMe);
  Future<String?> getActiveSessionUserId();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStorageService storageService;

  static const String _accountsPath = 'auth/accounts.json';
  static const String _sessionPath = 'auth/session.json';

  AuthLocalDataSourceImpl({required this.storageService});

  @override
  Future<List<Map<String, dynamic>>> getAccounts() async {
    final raw = await storageService.readString(_accountsPath);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async {
    final accounts = await getAccounts();
    final normalized = email.trim().toLowerCase();
    for (final acc in accounts) {
      if ((acc['email'] as String?)?.trim().toLowerCase() == normalized) {
        return acc;
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getAccountById(String id) async {
    final accounts = await getAccounts();
    for (final acc in accounts) {
      if (acc['id'] == id) {
        return acc;
      }
    }
    return null;
  }

  @override
  Future<void> saveAccount(Map<String, dynamic> accountData) async {
    final accounts = await getAccounts();
    final email = (accountData['email'] as String).trim().toLowerCase();
    accounts.removeWhere((a) => (a['email'] as String?)?.trim().toLowerCase() == email);
    accounts.add(accountData);
    await storageService.writeString(_accountsPath, jsonEncode(accounts));
  }

  @override
  Future<void> updateAccount(Map<String, dynamic> accountData) async {
    final accounts = await getAccounts();
    final id = accountData['id'];
    final idx = accounts.indexWhere((a) => a['id'] == id);
    if (idx != -1) {
      accounts[idx] = accountData;
    } else {
      accounts.add(accountData);
    }
    await storageService.writeString(_accountsPath, jsonEncode(accounts));
  }

  @override
  Future<void> saveSession(String userId, bool rememberMe) async {
    final sessionData = {
      'userId': userId,
      'rememberMe': rememberMe,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await storageService.writeJson(_sessionPath, sessionData);
  }

  @override
  Future<String?> getActiveSessionUserId() async {
    final session = await storageService.readJson(_sessionPath);
    if (session == null) return null;
    final rememberMe = session['rememberMe'] as bool? ?? true;
    if (!rememberMe) {
      // Session expires if remember me wasn't checked
      await clearSession();
      return null;
    }
    return session['userId'] as String?;
  }

  @override
  Future<void> clearSession() async {
    await storageService.deleteFile(_sessionPath);
  }
}
