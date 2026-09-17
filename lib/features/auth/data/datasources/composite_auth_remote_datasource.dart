import 'auth_remote_datasource.dart';

/// Composite remote data source that orchestrates multiple cloud providers
/// (Ntfy.sh Global Pub/Sub, Zero-Config Cloud Registry, and Optional Bunny.net) with resilient fallbacks.
class CompositeAuthRemoteDataSource implements AuthRemoteDataSource {
  final List<AuthRemoteDataSource> _sources;

  CompositeAuthRemoteDataSource({
    AuthRemoteDataSource? primary,
    AuthRemoteDataSource? secondary,
    List<AuthRemoteDataSource>? dataSources,
  }) : _sources = dataSources ?? [
          ?primary,
          ?secondary,
        ];

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async {
    for (final source in _sources) {
      try {
        final account = await source.getAccountByEmail(email);
        if (account != null && account['email'] != null) {
          return account;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getAccountById(String id) async {
    for (final source in _sources) {
      try {
        final account = await source.getAccountById(id);
        if (account != null && account['id'] != null) {
          return account;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<bool> saveAccount(Map<String, dynamic> accountData) async {
    bool anySuccess = false;
    for (final source in _sources) {
      try {
        final ok = await source.saveAccount(accountData);
        if (ok) anySuccess = true;
      } catch (_) {}
    }
    return anySuccess || _sources.isEmpty;
  }

  @override
  Future<bool> updateAccount(Map<String, dynamic> accountData) async {
    bool anySuccess = false;
    for (final source in _sources) {
      try {
        final ok = await source.updateAccount(accountData);
        if (ok) anySuccess = true;
      } catch (_) {}
    }
    return anySuccess || _sources.isEmpty;
  }

  @override
  Future<Map<String, dynamic>> register(String email, String password, String displayName) async {
    for (final source in _sources) {
      try {
        final result = await source.register(email, password, displayName);
        return result;
      } catch (e) {
        // If it's a specific user error (like 409 conflict), rethrow immediately
        final err = e.toString();
        if (err.contains('already exists') || err.contains('Registration failed')) {
          rethrow;
        }
      }
    }
    throw Exception('Unable to register account. Please check your connection.');
  }

  @override
  Future<Map<String, dynamic>?> login(String email, String password) async {
    for (final source in _sources) {
      try {
        final result = await source.login(email, password);
        if (result != null) return result;
      } catch (e) {
        rethrow;
      }
    }
    return null;
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    for (final source in _sources) {
      try {
        final exists = await source.checkEmailExists(email);
        if (exists) return true;
      } catch (_) {}
    }
    return false;
  }

  @override
  Future<bool> forgotPassword(String email, String newPassword) async {
    for (final source in _sources) {
      try {
        final ok = await source.forgotPassword(email, newPassword);
        if (ok) return true;
      } catch (e) {
        rethrow;
      }
    }
    return false;
  }
}

