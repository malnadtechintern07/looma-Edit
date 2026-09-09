import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:procut/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:procut/features/auth/data/datasources/bunny_auth_remote_datasource.dart';
import 'package:procut/features/auth/data/datasources/composite_auth_remote_datasource.dart';
import 'package:procut/features/auth/data/datasources/global_cloud_auth_remote_datasource.dart';
import 'package:procut/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:procut/features/auth/presentation/providers/auth_provider.dart';
import 'package:procut/features/auth/presentation/screens/auth_screen.dart';
import 'package:procut/features/cloud_sync/domain/entities/bunny_storage_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryAuthLocalDataSource implements AuthLocalDataSource {
  final Map<String, Map<String, dynamic>> _accountsByEmail = {};
  final Map<String, Map<String, dynamic>> _accountsById = {};
  String? _activeSessionUserId;
  bool _rememberMe = true;

  @override
  Future<List<Map<String, dynamic>>> getAccounts() async => _accountsById.values.toList();

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async =>
      _accountsByEmail[email.trim().toLowerCase()];

  @override
  Future<Map<String, dynamic>?> getAccountById(String id) async => _accountsById[id];

  @override
  Future<void> saveAccount(Map<String, dynamic> accountData) async {
    final email = (accountData['email'] as String).trim().toLowerCase();
    final id = accountData['id'] as String;
    _accountsByEmail[email] = Map<String, dynamic>.from(accountData);
    _accountsById[id] = Map<String, dynamic>.from(accountData);
  }

  @override
  Future<void> updateAccount(Map<String, dynamic> accountData) async {
    await saveAccount(accountData);
  }

  @override
  Future<void> saveSession(String userId, bool rememberMe) async {
    _activeSessionUserId = userId;
    _rememberMe = rememberMe;
  }

  @override
  Future<String?> getActiveSessionUserId() async {
    if (!_rememberMe) return null;
    return _activeSessionUserId;
  }

  @override
  Future<void> clearSession() async {
    _activeSessionUserId = null;
  }
}

class _InMemoryAuthRemoteDataSource implements AuthRemoteDataSource {
  final Map<String, Map<String, dynamic>> _cloudAccounts = {};

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async =>
      _cloudAccounts[email.trim().toLowerCase()];

  @override
  Future<Map<String, dynamic>?> getAccountById(String id) async {
    for (final acc in _cloudAccounts.values) {
      if (acc['id'] == id) return acc;
    }
    return null;
  }

  @override
  Future<bool> saveAccount(Map<String, dynamic> accountData) async {
    final email = (accountData['email'] as String).trim().toLowerCase();
    _cloudAccounts[email] = Map<String, dynamic>.from(accountData);
    return true;
  }

  @override
  Future<bool> updateAccount(Map<String, dynamic> accountData) async {
    return await saveAccount(accountData);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Multi-Device Cloud Authentication Tests', () {
    late AuthRemoteDataSource sharedCloudAuthDataSource;

    late AuthLocalDataSource device1LocalDataSource;
    late AuthRepositoryImpl device1AuthRepo;

    late AuthLocalDataSource device2LocalDataSource;
    late AuthRepositoryImpl device2AuthRepo;

    setUp(() async {
      // Shared cloud storage representing Bunny.net Edge Cloud Storage
      sharedCloudAuthDataSource = _InMemoryAuthRemoteDataSource();

      // Device 1: Creator's primary phone
      device1LocalDataSource = _InMemoryAuthLocalDataSource();
      device1AuthRepo = AuthRepositoryImpl(
        localDataSource: device1LocalDataSource,
        remoteDataSource: sharedCloudAuthDataSource,
      );

      // Device 2: Creator's secondary device (clean slate with NO local data)
      device2LocalDataSource = _InMemoryAuthLocalDataSource();
      device2AuthRepo = AuthRepositoryImpl(
        localDataSource: device2LocalDataSource,
        remoteDataSource: sharedCloudAuthDataSource,
      );
    });

    test('User can register on Device 1 and immediately log in on Device 2 with the same email and password', () async {
      // 1. Device 1: Register account
      final registeredUser = await device1AuthRepo.register(
        email: 'creator@looma.app',
        password: 'Password123!',
        displayName: 'Elena Mobile Pro',
      );

      expect(registeredUser.id.startsWith('usr_'), isTrue);
      expect(registeredUser.email, 'creator@looma.app');
      expect(registeredUser.displayName, 'Elena Mobile Pro');

      // 2. Verify Device 2 has NO local account data initially
      final device2LocalAccount = await device2LocalDataSource.getAccountByEmail('creator@looma.app');
      expect(device2LocalAccount, isNull);

      // 3. Device 2: User logs in using the exact same email & password
      final device2User = await device2AuthRepo.login(
        email: 'creator@looma.app',
        password: 'Password123!',
        rememberMe: true,
      );

      // 4. Verify Device 2 authenticated with the exact same identity
      expect(device2User.id, registeredUser.id);
      expect(device2User.email, 'creator@looma.app');
      expect(device2User.displayName, 'Elena Mobile Pro');

      // 5. Verify Device 2 now has the account cached locally for fast offline access
      final cachedOnDevice2 = await device2LocalDataSource.getAccountByEmail('creator@looma.app');
      expect(cachedOnDevice2, isNotNull);
      expect(cachedOnDevice2?['id'], registeredUser.id);

      // 6. Verify Device 2 has an active session
      final sessionUser = await device2AuthRepo.getCurrentUser();
      expect(sessionUser?.id, registeredUser.id);
    });

    test('Device 2 rejects login with incorrect password', () async {
      // Register on Device 1
      await device1AuthRepo.register(
        email: 'director@looma.app',
        password: 'CorrectPassword99',
        displayName: 'Director',
      );

      // Attempt login on Device 2 with wrong password
      expect(
        () => device2AuthRepo.login(
          email: 'director@looma.app',
          password: 'WrongPassword!',
          rememberMe: true,
        ),
        throwsA(
          predicate((e) => e.toString().contains('Incorrect password')),
        ),
      );
    });

    test('Device 2 rejects login when email does not exist on any device', () async {
      expect(
        () => device2AuthRepo.login(
          email: 'nonexistent@looma.app',
          password: 'SomePassword123',
          rememberMe: true,
        ),
        throwsA(
          predicate((e) => e.toString().contains('No account found with this email')),
        ),
      );
    });

    test('Device 2 cannot register with an email already registered on Device 1', () async {
      // Register on Device 1
      await device1AuthRepo.register(
        email: 'sam@looma.app',
        password: 'Password123',
        displayName: 'Sam Original',
      );

      // Attempt duplicate registration on Device 2
      expect(
        () => device2AuthRepo.register(
          email: 'sam@looma.app',
          password: 'AnotherPassword456',
          displayName: 'Sam Clone',
        ),
        throwsA(
          predicate((e) => e.toString().contains('An account with this email already exists')),
        ),
      );
    });

    test('Password reset on Device 1 syncs to cloud and allows login on Device 2 with new password', () async {
      // 1. Register on Device 1
      await device1AuthRepo.register(
        email: 'filmmaker@looma.app',
        password: 'OldPassword123',
        displayName: 'Filmmaker',
      );

      // 2. Reset password on Device 1
      await device1AuthRepo.forgotPassword(
        email: 'filmmaker@looma.app',
        newPassword: 'BrandNewPassword789',
      );

      // 3. Old password must be rejected on Device 2
      expect(
        () => device2AuthRepo.login(
          email: 'filmmaker@looma.app',
          password: 'OldPassword123',
          rememberMe: true,
        ),
        throwsA(
          predicate((e) => e.toString().contains('Incorrect password')),
        ),
      );

      // 4. New password succeeds on Device 2
      final user = await device2AuthRepo.login(
        email: 'filmmaker@looma.app',
        password: 'BrandNewPassword789',
        rememberMe: true,
      );

      expect(user.email, 'filmmaker@looma.app');
    });

    test('Password reset on Device 1 syncs even if Device 2 already cached old credentials locally', () async {
      // 1. Register on Device 1
      await device1AuthRepo.register(
        email: 'sync_test@looma.app',
        password: 'Password1',
        displayName: 'Sync User',
      );

      // 2. Log in on Device 2 with Password1 (so Device 2 caches Password1 locally)
      await device2AuthRepo.login(
        email: 'sync_test@looma.app',
        password: 'Password1',
        rememberMe: true,
      );
      await device2AuthRepo.logout();

      // 3. Device 1 updates password to Password2
      await device1AuthRepo.forgotPassword(
        email: 'sync_test@looma.app',
        newPassword: 'Password2',
      );

      // 4. Device 2 tries to log in with Password2:
      // Even though local cache had Password1, AuthRepositoryImpl re-checks remote and succeeds!
      final loggedIn = await device2AuthRepo.login(
        email: 'sync_test@looma.app',
        password: 'Password2',
        rememberMe: true,
      );

      expect(loggedIn.email, 'sync_test@looma.app');
    });
  });

  group('GlobalCloudAuthRemoteDataSource & CompositeAuthRemoteDataSource Tests', () {
    test('GlobalCloudAuthRemoteDataSource caches account locally and resolves by email and ID', () async {
      final storage = LocalStorageService();
      await storage.clearAll();
      final globalDs = GlobalCloudAuthRemoteDataSource(
        localStorageService: storage,
      );

      final account = {
        'id': 'usr_global_cloud_456',
        'email': 'global_creator@looma.app',
        'displayName': 'Global Creator',
        'passwordHash': 'cloud_hash_789',
        'salt': 'cloud_salt_789',
        'isPro': true,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
      };

      final saved = await globalDs.saveAccount(account);
      expect(saved, isTrue);

      final fetched = await globalDs.getAccountByEmail('GLOBAL_CREATOR@LOOMA.APP');
      expect(fetched, isNotNull);
      expect(fetched?['id'], 'usr_global_cloud_456');
      expect(fetched?['displayName'], 'Global Creator');

      final fetchedById = await globalDs.getAccountById('usr_global_cloud_456');
      expect(fetchedById, isNotNull);
      expect(fetchedById?['email'], 'global_creator@looma.app');
    });

    test('CompositeAuthRemoteDataSource resolves from primary and writes to both', () async {
      final primary = _InMemoryAuthRemoteDataSource();
      final secondary = _InMemoryAuthRemoteDataSource();
      final composite = CompositeAuthRemoteDataSource(primary: primary, secondary: secondary);

      final account = {
        'id': 'usr_comp_1',
        'email': 'comp@looma.app',
        'displayName': 'Composite User',
        'passwordHash': 'h1',
        'salt': 's1',
      };

      await composite.saveAccount(account);

      // Verify both received it
      expect(await primary.getAccountByEmail('comp@looma.app'), isNotNull);
      expect(await secondary.getAccountByEmail('comp@looma.app'), isNotNull);

      // Verify lookup works
      final lookedUp = await composite.getAccountByEmail('comp@looma.app');
      expect(lookedUp?['id'], 'usr_comp_1');
    });

    test('AuthRepositoryImpl syncLocalAccountsToCloud backfills local accounts to remote cloud', () async {
      final localDs = _InMemoryAuthLocalDataSource();
      final remoteDs = _InMemoryAuthRemoteDataSource();
      final repo = AuthRepositoryImpl(localDataSource: localDs, remoteDataSource: remoteDs);

      // Pre-seed local storage with an account that was created before cloud sync was active
      await localDs.saveAccount({
        'id': 'usr_preseed_1',
        'email': 'preseed@looma.app',
        'displayName': 'Preseeded Creator',
        'passwordHash': 'h_pre',
        'salt': 's_pre',
        'isPro': true,
      });

      // Remote cloud initially has NO record of this account
      expect(await remoteDs.getAccountByEmail('preseed@looma.app'), isNull);

      // Trigger backfill sync
      await repo.syncLocalAccountsToCloud();

      // Remote cloud now has the account!
      final remoteAcc = await remoteDs.getAccountByEmail('preseed@looma.app');
      expect(remoteAcc, isNotNull);
      expect(remoteAcc?['id'], 'usr_preseed_1');
      expect(remoteAcc?['displayName'], 'Preseeded Creator');
    });

    test('End-to-end: Register on Device 1 and log in on Device 2 with same credentials', () async {
      final sharedCloud = _InMemoryAuthRemoteDataSource();

      final d1Local = _InMemoryAuthLocalDataSource();
      final d1Composite = CompositeAuthRemoteDataSource(primary: sharedCloud);
      final d1Repo = AuthRepositoryImpl(localDataSource: d1Local, remoteDataSource: d1Composite);

      final d2Local = _InMemoryAuthLocalDataSource();
      final d2Composite = CompositeAuthRemoteDataSource(primary: sharedCloud);
      final d2Repo = AuthRepositoryImpl(localDataSource: d2Local, remoteDataSource: d2Composite);

      final registered = await d1Repo.register(
        email: 'multidevice@looma.app',
        password: 'Password999!',
        displayName: 'Multi Device User',
      );
      expect(registered.email, 'multidevice@looma.app');

      final loggedInD2 = await d2Repo.login(
        email: 'multidevice@looma.app',
        password: 'Password999!',
        rememberMe: true,
      );

      expect(loggedInD2.id, registered.id);
      expect(loggedInD2.displayName, 'Multi Device User');

      expect(
        () => d2Repo.login(
          email: 'multidevice@looma.app',
          password: 'WrongPassword',
          rememberMe: true,
        ),
        throwsA(predicate((e) => e.toString().contains('Incorrect password'))),
      );
    });
  });

  group('BunnyAuthRemoteDataSource Tests', () {
    test('BunnyAuthRemoteDataSource saves account and resolves across devices', () async {
      final storage = LocalStorageService();
      await storage.clearAll();
      final bunnyDs = BunnyAuthRemoteDataSource(
        localStorageService: storage,
        config: BunnyStorageConfig.defaultConfig(),
      );

      final account = {
        'id': 'usr_bunny_123',
        'email': 'bunny_user@looma.app',
        'displayName': 'Bunny Creator',
        'passwordHash': 'hash123',
        'salt': 'salt123',
        'isPro': true,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
      };

      await bunnyDs.saveAccount(account);

      // Verify fetch by email (case-insensitive)
      final fetched = await bunnyDs.getAccountByEmail('BUNNY_USER@LOOMA.APP');
      expect(fetched, isNotNull);
      expect(fetched?['id'], 'usr_bunny_123');
      expect(fetched?['displayName'], 'Bunny Creator');

      // Verify fetch by ID
      final fetchedById = await bunnyDs.getAccountById('usr_bunny_123');
      expect(fetchedById, isNotNull);
      expect(fetchedById?['email'], 'bunny_user@looma.app');
    });
  });

  group('AuthScreen UI Tests', () {
    testWidgets('AuthScreen displays multi-device cloud sync pill banner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => _FakeStaticAuthNotifier(
                const AuthState(
                  status: AuthStatus.unauthenticated,
                  user: null,
                  isLoading: false,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('One account • Log in on all your devices'), findsOneWidget);
      expect(find.byIcon(Icons.devices_rounded), findsOneWidget);
    });
  });
}

class _FakeStaticAuthNotifier extends AuthNotifier {
  final AuthState _initial;
  _FakeStaticAuthNotifier(this._initial) : super(_StubAuthRepo()) {
    state = _initial;
  }
}

class _StubAuthRepo extends AuthRepositoryImpl {
  _StubAuthRepo() : super(localDataSource: _InMemoryAuthLocalDataSource());
}
