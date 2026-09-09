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
}

