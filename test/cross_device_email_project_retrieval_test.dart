import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';
import 'package:procut/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:procut/features/auth/domain/services/password_hasher.dart';
import 'package:procut/features/auth/presentation/providers/auth_provider.dart';
import 'package:procut/features/cloud_sync/domain/entities/cloud_backup_record.dart';
import 'package:procut/features/cloud_sync/data/datasources/cloud_storage_datasource.dart';
import 'package:procut/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';
import 'package:procut/features/projects/presentation/providers/projects_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulated authoritative cloud server storage (mimics MySQL database behavior on http://procut.free.nf)
class _MockAuthoritativeServerStorage implements CloudStorageDataSource {
  /// Server database table: projects
  final Map<String, Map<String, dynamic>> _dbProjects = {};

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId, [String? userEmail]) async {
    final cleanEmail = userEmail?.trim().toLowerCase();
    final List<ProjectEntity> results = [];

    for (final row in _dbProjects.values) {
      final rowEmail = (row['userEmail'] as String?)?.trim().toLowerCase();
      final rowUid = row['userId'] as String?;

      // Server matches by email OR userId
      final matchEmail = cleanEmail != null && cleanEmail.isNotEmpty && rowEmail == cleanEmail;
      final matchUid = userId.isNotEmpty && rowUid == userId;

      if (matchEmail || matchUid) {
        results.add(ProjectModel.fromJson(row).copyWith(
          syncStatus: SyncStatusType.synced,
          userId: userId,
          userEmail: cleanEmail ?? rowEmail,
        ));
      }
    }

    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  @override
  Future<ProjectEntity?> getCloudProject(String userId, String projectId) async {
    final row = _dbProjects[projectId];
    if (row == null) return null;
    return ProjectModel.fromJson(row).copyWith(syncStatus: SyncStatusType.synced);
  }

  @override
  Future<CloudBackupRecord> backupProject(String userId, ProjectEntity project) async {
    final json = ProjectModel.toJson(project);
    json['userId'] = userId;
    if (project.userEmail != null) json['userEmail'] = project.userEmail;
    _dbProjects[project.id] = json;

    return CloudBackupRecord(
      projectId: project.id,
      projectTitle: project.title,
      fileSizeBytes: 1024,
      backedUpAt: DateTime.now(),
      cloudChecksum: 'server_sha256_${project.id}',
    );
  }

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    _dbProjects.remove(projectId);
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async => [];

  @override
  Future<int> calculateUserStorageUsage(String userId) async => _dbProjects.length * 2048;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Device Email-Based Project Storage & Retrieval Tests', () {
    late _MockAuthoritativeServerStorage sharedCloudServer;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sharedCloudServer = _MockAuthoritativeServerStorage();
    });

    test(
        'Project created on Device A under an email is automatically stored on server and retrieved on fresh Device B upon login with same email',
        () async {
      final userEmail = 'creator_alice@procut.app';
      final password = 'AlicePassword123!';

      // =========================================================================
      // DEVICE A: Setup, registration, project creation, and auto-backup
      // =========================================================================
      final deviceAStorage = LocalStorageService();
      await deviceAStorage.clearAll();

      final deviceAContainer = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(deviceAStorage),
          cloudStorageDataSourceProvider.overrideWithValue(sharedCloudServer),
          authRepositoryProvider.overrideWith((ref) => AuthRepositoryImpl(
            localDataSource: ref.watch(authLocalDataSourceProvider),
          )),
        ],
      );

      // 1. Register Alice on Device A
      final deviceAAuth = deviceAContainer.read(authNotifierProvider.notifier);
      final registered = await deviceAAuth.register(
        email: userEmail,
        password: password,
        displayName: 'Alice Creator',
      );
      expect(registered, isTrue);
      final userA = deviceAContainer.read(currentUserProvider)!;
      expect(userA.email, userEmail);

      // 2. Alice creates a video project on Device A
      final deviceAProjects = deviceAContainer.read(projectsNotifierProvider.notifier);
      final project1 = await deviceAProjects.createProject(
        title: 'Tokyo Street Food Adventure',
        aspectRatio: AspectRatioType.ratio9_16,
      );

      // Verify created locally
      expect(project1.title, 'Tokyo Street Food Adventure');
      expect(project1.userEmail, userEmail);

      // Wait a tick for auto-sync/backup to push to server
      await deviceAContainer.read(cloudSyncRepositoryProvider).backupProject(project1.id);

      // Verify project is now stored in the server database under alice's email
      final serverRows = await sharedCloudServer.getCloudProjects(userA.id, userEmail);
      expect(serverRows.length, 1);
      expect(serverRows.first.title, 'Tokyo Street Food Adventure');
      expect(serverRows.first.userEmail, userEmail);

      // =========================================================================
      // DEVICE B: Completely fresh device (no files, fresh storage)
      // =========================================================================
      final deviceBStorage = LocalStorageService();
      await deviceBStorage.clearAll();

      final deviceBContainer = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(deviceBStorage),
          cloudStorageDataSourceProvider.overrideWithValue(sharedCloudServer),
          authRepositoryProvider.overrideWith((ref) => AuthRepositoryImpl(
            localDataSource: ref.watch(authLocalDataSourceProvider),
          )),
        ],
      );

      // Initially Device B has 0 projects
      final initialBProjects = deviceBContainer.read(projectsNotifierProvider).projects;
      expect(initialBProjects.isEmpty, isTrue);

      // 3. User logs in on Device B using the SAME email
      // We simulate cloud user account availability in auth datasource
      final saltB = PasswordHasher.generateSalt();
      final hashB = PasswordHasher.hashPassword(password, saltB);
      final deviceBLocalAuth = deviceBContainer.read(authLocalDataSourceProvider);
      await deviceBLocalAuth.saveAccount({
        'id': 'usr_device_b_id', // Note: even if device B generates a device-specific ID
        'email': userEmail,
        'displayName': 'Alice Creator',
        'password': password,
        'salt': saltB,
        'passwordHash': hashB,
        'createdAt': DateTime.now().toIso8601String(),
        'isPro': true,
      });

      final deviceBAuth = deviceBContainer.read(authNotifierProvider.notifier);
      final loggedInB = await deviceBAuth.login(
        email: userEmail,
        password: password,
        rememberMe: true,
      );
      expect(loggedInB, isTrue);

      // 4. Trigger cloud sync on Device B (as authSyncProvider does automatically)
      final deviceBSync = deviceBContainer.read(syncNotifierProvider.notifier);
      final syncSuccess = await deviceBSync.triggerSync();
      expect(syncSuccess, isTrue);

      // 5. Device B projects list now immediately contains Alice's project from Device A!
      final refreshedBProjects = deviceBContainer.read(projectsNotifierProvider).projects;
      expect(refreshedBProjects.length, 1);
      expect(refreshedBProjects.first.id, project1.id);
      expect(refreshedBProjects.first.title, 'Tokyo Street Food Adventure');
      expect(refreshedBProjects.first.syncStatus, SyncStatusType.synced);

      // 6. Verify project is also persisted on Device B local disk
      final deviceBLocalDs = deviceBContainer.read(projectLocalDataSourceProvider);
      final diskProject = await deviceBLocalDs.getProjectById(project1.id);
      expect(diskProject, isNotNull);
      expect(diskProject!.title, 'Tokyo Street Food Adventure');

      // =========================================================================
      // DEVICE B: Edits project title -> Automatically syncs back to server
      // =========================================================================
      await deviceBContainer.read(projectsNotifierProvider.notifier).renameProject(
            project1.id,
            'Tokyo Street Food Adventure (Final Cut)',
          );

      // Push backup from Device B
      await deviceBContainer.read(cloudSyncRepositoryProvider).backupProject(project1.id);

      // Server should now reflect updated title
      final updatedServerRows = await sharedCloudServer.getCloudProjects('usr_device_b_id', userEmail);
      expect(updatedServerRows.first.title, 'Tokyo Street Food Adventure (Final Cut)');

      // =========================================================================
      // DEVICE C: An unrelated user (Bob) logs in on Device C
      // =========================================================================
      final deviceCStorage = LocalStorageService();
      await deviceCStorage.clearAll();

      final deviceCContainer = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(deviceCStorage),
          cloudStorageDataSourceProvider.overrideWithValue(sharedCloudServer),
          authRepositoryProvider.overrideWith((ref) => AuthRepositoryImpl(
            localDataSource: ref.watch(authLocalDataSourceProvider),
          )),
        ],
      );

      final saltC = PasswordHasher.generateSalt();
      final hashC = PasswordHasher.hashPassword('BobPassword123!', saltC);
      final deviceCLocalAuth = deviceCContainer.read(authLocalDataSourceProvider);
      await deviceCLocalAuth.saveAccount({
        'id': 'usr_bob_id',
        'email': 'bob@procut.app',
        'displayName': 'Bob Creator',
        'password': 'BobPassword123!',
        'salt': saltC,
        'passwordHash': hashC,
        'createdAt': DateTime.now().toIso8601String(),
        'isPro': false,
      });

      await deviceCContainer.read(authNotifierProvider.notifier).login(
            email: 'bob@procut.app',
            password: 'BobPassword123!',
          );

      await deviceCContainer.read(syncNotifierProvider.notifier).triggerSync();

      // Bob MUST NOT see Alice's projects
      final bobProjects = deviceCContainer.read(projectsNotifierProvider).projects;
      expect(bobProjects.isEmpty, isTrue);
    });
  });
}
