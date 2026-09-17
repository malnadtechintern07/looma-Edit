import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/auth/data/datasources/mysql_auth_remote_datasource.dart';
import 'package:procut/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:procut/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:procut/features/cloud_sync/data/datasources/mysql_cloud_storage_datasource.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLocalStorageService implements LocalStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> clearAll() async => _storage.clear();

  @override
  Future<List<String>> listProjectFiles({String? directoryPrefix}) async => _storage.keys.toList();

  @override
  Future<Map<String, dynamic>?> readJson(String path) async {
    final val = _storage[path];
    if (val == null) return null;
    return jsonDecode(val) as Map<String, dynamic>?;
  }

  @override
  Future<void> writeJson(String path, Map<String, dynamic> data) async {
    _storage[path] = jsonEncode(data);
  }

  @override
  Future<String?> readString(String path) async => _storage[path];

  @override
  Future<void> writeString(String path, String content) async {
    _storage[path] = content;
  }

  @override
  Future<bool> deleteFile(String path) async {
    final existed = _storage.containsKey(path);
    _storage.remove(path);
    return existed;
  }

  Future<bool> fileExists(String path) async => _storage.containsKey(path);
}

class _MockAuthLocalDataSource implements AuthLocalDataSource {
  final Map<String, Map<String, dynamic>> _accounts = {};
  String? _sessionUserId;

  @override
  Future<List<Map<String, dynamic>>> getAccounts() async => _accounts.values.toList();

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async =>
      _accounts[email.trim().toLowerCase()];

  @override
  Future<Map<String, dynamic>?> getAccountById(String id) async => _accounts[id];

  @override
  Future<void> saveAccount(Map<String, dynamic> accountData) async {
    final email = (accountData['email'] as String).trim().toLowerCase();
    final id = accountData['id'] as String;
    _accounts[email] = Map<String, dynamic>.from(accountData);
    _accounts[id] = Map<String, dynamic>.from(accountData);
  }

  @override
  Future<void> updateAccount(Map<String, dynamic> accountData) async => saveAccount(accountData);

  @override
  Future<void> saveSession(String userId, bool rememberMe) async {
    _sessionUserId = userId;
  }

  @override
  Future<String?> getActiveSessionUserId() async => _sessionUserId;

  @override
  Future<void> clearSession() async {
    _sessionUserId = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUp(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({
      'procut_server_base_url': 'http://127.0.0.1:5050',
    });
  });

  group('Live PHP + MySQL Backend End-to-End Tests', () {
    test('Direct Server Health & Availability', () async {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:5050/api/health'));
      final res = await req.close();
      expect(res.statusCode, 200);
      final body = await res.transform(utf8.decoder).join();
      expect(body, contains('MySQL (InnoDB)'));
      client.close();
    });

    test('User Registration, Cross-Device Login, and Cloud Project Isolation', () async {
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'creator_$uniqueSuffix@procut.app';
      final testPassword = 'SecretPassword123!';

      // --- Device 1: Register User ---
      final device1Storage = _MockLocalStorageService();
      final device1LocalAuth = _MockAuthLocalDataSource();
      final device1RemoteAuth = MySqlAuthRemoteDataSource(localStorageService: device1Storage);
      final device1Repo = AuthRepositoryImpl(
        localDataSource: device1LocalAuth,
        remoteDataSource: device1RemoteAuth,
      );

      final userD1 = await device1Repo.register(
        email: testEmail,
        password: testPassword,
        displayName: 'Creator $uniqueSuffix',
      );
      expect(userD1.email, testEmail);
      expect(userD1.id, isNotEmpty);

      // --- Device 2: New device (completely empty local storage) ---
      final device2Storage = _MockLocalStorageService();
      final device2LocalAuth = _MockAuthLocalDataSource();
      final device2RemoteAuth = MySqlAuthRemoteDataSource(localStorageService: device2Storage);
      final device2Repo = AuthRepositoryImpl(
        localDataSource: device2LocalAuth,
        remoteDataSource: device2RemoteAuth,
      );

      // Verify incorrect password throws clear error
      expect(
        () => device2Repo.login(
          email: testEmail,
          password: 'WrongPassword!',
          rememberMe: true,
        ),
        throwsA(predicate((e) =>
            e.toString().contains('Incorrect password'))),
      );

      // Verify non-existent email throws clear error
      expect(
        () => device2Repo.login(
          email: 'nonexistent_$uniqueSuffix@procut.app',
          password: 'AnyPassword123!',
          rememberMe: true,
        ),
        throwsA(predicate((e) =>
            e.toString().contains('No account found'))),
      );

      // Verify successful login on Device 2
      final userD2 = await device2Repo.login(
        email: testEmail,
        password: testPassword,
        rememberMe: true,
      );
      expect(userD2.id, userD1.id);
      expect(userD2.email, testEmail);

      // --- Cloud Projects Sync & Isolation ---
      final device1CloudStorage = MySqlCloudStorageDataSource(localStorageService: device1Storage);
      final project1 = ProjectEntity(
        id: 'proj_cloud_$uniqueSuffix',
        title: 'Cinematic Vlog $uniqueSuffix',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: userD1.id,
        userEmail: testEmail,
        syncStatus: SyncStatusType.synced,
      );

      // Save project from Device 1
      await device1CloudStorage.backupProject(userD1.id, project1);

      // Fetch projects from Device 2 for this user
      final device2CloudStorage = MySqlCloudStorageDataSource(localStorageService: device2Storage);
      final d2Projects = await device2CloudStorage.getCloudProjects(userD1.id);
      expect(d2Projects.any((p) => p.id == project1.id), isTrue);

      // Isolation check: Another user MUST NOT see this project
      final anotherUserId = 'usr_another_unrelated_user';
      final unrelatedProjects = await device2CloudStorage.getCloudProjects(anotherUserId);
      expect(unrelatedProjects.any((p) => p.id == project1.id), isFalse);
    });
  });
}
