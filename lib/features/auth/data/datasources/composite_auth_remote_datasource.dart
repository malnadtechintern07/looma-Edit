import 'auth_remote_datasource.dart';

/// Composite remote data source that orchestrates multiple cloud providers
/// (Global Zero-Config Cloud Registry + Optional Bunny.net Storage) with resilient fallbacks.
class CompositeAuthRemoteDataSource implements AuthRemoteDataSource {
  final AuthRemoteDataSource primary;
  final AuthRemoteDataSource? secondary;

  CompositeAuthRemoteDataSource({
    required this.primary,
    this.secondary,
  });

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async {
    // 1. Try primary zero-config global cloud
    final account = await primary.getAccountByEmail(email);
    if (account != null) return account;

    // 2. Try secondary (e.g. Bunny.net if enabled)
    if (secondary != null) {
      return await secondary!.getAccountByEmail(email);
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getAccountById(String id) async {
    final account = await primary.getAccountById(id);
    if (account != null) return account;

    if (secondary != null) {
      return await secondary!.getAccountById(id);
    }
    return null;
  }

  @override
  Future<bool> saveAccount(Map<String, dynamic> accountData) async {
    final primaryOk = await primary.saveAccount(accountData);
    if (secondary != null) {
      await secondary!.saveAccount(accountData);
    }
    return primaryOk;
  }

  @override
  Future<bool> updateAccount(Map<String, dynamic> accountData) async {
    final primaryOk = await primary.updateAccount(accountData);
    if (secondary != null) {
      await secondary!.updateAccount(accountData);
    }
    return primaryOk;
  }
}
