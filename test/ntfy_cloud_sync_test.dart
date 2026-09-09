import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:procut/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:procut/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:procut/features/cloud_sync/data/datasources/cloud_storage_datasource.dart';
import 'package:procut/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart';
import 'package:procut/features/cloud_sync/domain/entities/cloud_backup_record.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/projects/data/datasources/project_local_datasource.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';

class _FakeNtfyHttpClient implements AuthRemoteDataSource, CloudStorageDataSource {
  final Map<String, List<Map<String, dynamic>>> _topics = {};

  @override
  Future<Map<String, dynamic>?> getAccountByEmail(String email) async {
    final list = _topics['procut_auth_${email.trim().toLowerCase()}'] ?? [];
    if (list.isEmpty) return null;
    return list.last;
  }

  @override
  Future<Map<String, dynamic>?> getAccountById(String id) async {
    for (final list in _topics.values) {
      for (final item in list) {
        if (item['id'] == id) return item;
      }
    }
    return null;
  }

  @override
  Future<bool> saveAccount(Map<String, dynamic> accountData) async {
    final email = (accountData['email'] as String).trim().toLowerCase();
    _topics.putIfAbsent('procut_auth_$email', () => []).add(Map<String, dynamic>.from(accountData));
    return true;
  }

  @override
  Future<bool> updateAccount(Map<String, dynamic> accountData) async {
    return await saveAccount(accountData);
  }

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId) async {
    final list = _topics['procut_proj_$userId'] ?? [];
    final Map<String, ProjectEntity> map = {};
    for (final item in list) {
      if (item['type'] == 'deleted') {
        map.remove(item['projectId']);
      } else {
        final p = ProjectEntity(
          id: item['id'] as String,
          title: item['title'] as String,
          aspectRatio: AspectRatioType.ratio9_16,
          createdAt: DateTime.parse(item['createdAt'] as String),
          updatedAt: DateTime.parse(item['updatedAt'] as String),
          userId: item['userId'] as String?,
          userEmail: item['userEmail'] as String?,
          syncStatus: SyncStatusType.synced,
        );
        map[p.id] = p;
      }
    }
    final result = map.values.toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  @override
  Future<ProjectEntity?> getCloudProject(String userId, String projectId) async {
    final projects = await getCloudProjects(userId);
    for (final p in projects) {
      if (p.id == projectId) return p;
    }
    return null;
  }

  @override
  Future<CloudBackupRecord> backupProject(String userId, ProjectEntity project) async {
    final json = {
      'id': project.id,
      'title': project.title,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'userId': project.userId ?? userId,
      'userEmail': project.userEmail,
    };
    _topics.putIfAbsent('procut_proj_$userId', () => []).add(json);
    return CloudBackupRecord(
      projectId: project.id,
      projectTitle: project.title,
      fileSizeBytes: 1024,
      backedUpAt: DateTime.now(),
      cloudChecksum: 'chk_${project.id}',
    );
  }

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    _topics.putIfAbsent('procut_proj_$userId', () => []).add({
      'type': 'deleted',
      'projectId': projectId,
    });
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async => [];

  @override
  Future<int> calculateUserStorageUsage(String userId) async => 1024;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Ntfy Cloud Sync & Cross-Device Email Restoration Tests', () {
    test('Device A creates projects with email, Device B signs in with same email and gets projects', () async {
      final fakeCloud = _FakeNtfyHttpClient();

      // Device A Setup
      final deviceAStorage = LocalStorageService();
      await deviceAStorage.clearAll();
      final deviceALocalAuth = AuthLocalDataSourceImpl(storageService: deviceAStorage);
      final deviceAAuthRepo = AuthRepositoryImpl(
        localDataSource: deviceALocalAuth,
        remoteDataSource: fakeCloud,
      );
      final deviceALocalProjects = ProjectLocalDataSourceImpl(storageService: deviceAStorage);
      final deviceACloudSyncRepo = CloudSyncRepositoryImpl(
        cloudDataSource: fakeCloud,
        projectLocalDataSource: deviceALocalProjects,
        authRepository: deviceAAuthRepo,
      );

      // 1. User registers on Device A
      final userA = await deviceAAuthRepo.register(
        email: 'creator@procut.io',
        password: 'Password999!',
        displayName: 'Pro Creator',
      );
      expect(userA.email, 'creator@procut.io');
      expect(userA.id.startsWith('usr_'), isTrue);

      deviceALocalProjects.setActiveUserId(userA.id);

      // 2. User creates 2 projects on Device A
      final project1 = ProjectEntity(
        id: 'proj_viral_reel_1',
        title: 'Viral Instagram Reel',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        userId: userA.id,
        userEmail: userA.email,
        videoClips: const [
          VideoClipEntity(
            id: 'c1',
            mediaPath: 'assets/demo/vid1.mp4',
            name: 'Intro Clip',
            sourceDurationMs: 5000,
            timelineStartMs: 0,
            timelineEndMs: 5000,
            trimStartMs: 0,
            trimEndMs: 5000,
          ),
        ],
      );

      final project2 = ProjectEntity(
        id: 'proj_youtube_vlog_2',
        title: 'Tokyo Street Food Vlog',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        userId: userA.id,
        userEmail: userA.email,
      );

      await deviceALocalProjects.saveProject(project1);
      await deviceALocalProjects.saveProject(project2);

      // 3. Device A syncs projects to Cloud
      await deviceACloudSyncRepo.syncAllProjects();

      // Verify Cloud has both projects under userA.id
      final cloudProjects = await fakeCloud.getCloudProjects(userA.id);
      expect(cloudProjects.length, 2);
      expect(cloudProjects.map((p) => p.title).toSet(), containsAll(['Viral Instagram Reel', 'Tokyo Street Food Vlog']));

      // ----------------------------------------------------------------------
      // Device B: Brand new device with clean slate
      // ----------------------------------------------------------------------
      final deviceBStorage = LocalStorageService();
      // Brand new SharedPreferences partition simulated by separate storage namespace
      final deviceBLocalAuth = AuthLocalDataSourceImpl(storageService: deviceBStorage);
      final deviceBAuthRepo = AuthRepositoryImpl(
        localDataSource: deviceBLocalAuth,
        remoteDataSource: fakeCloud,
      );
      final deviceBLocalProjects = ProjectLocalDataSourceImpl(storageService: deviceBStorage);
      final deviceBCloudSyncRepo = CloudSyncRepositoryImpl(
        cloudDataSource: fakeCloud,
        projectLocalDataSource: deviceBLocalProjects,
        authRepository: deviceBAuthRepo,
      );

      // 4. Device B signs in with the EXACT same email and password
      final userB = await deviceBAuthRepo.login(
        email: 'creator@procut.io',
        password: 'Password999!',
        rememberMe: true,
      );
      expect(userB.id, userA.id);
      expect(userB.email, 'creator@procut.io');
      expect(userB.displayName, 'Pro Creator');

      deviceBLocalProjects.setActiveUserId(userB.id);

      // 5. Device B syncs all projects upon login
      await deviceBCloudSyncRepo.syncAllProjects();

      // 6. Device B retrieves all projects from local storage
      final deviceBProjects = await deviceBLocalProjects.getProjects();

      expect(deviceBProjects.length, 2);
      expect(deviceBProjects.map((p) => p.title).toList(), ['Tokyo Street Food Vlog', 'Viral Instagram Reel']);
      expect(deviceBProjects.every((p) => p.userEmail == 'creator@procut.io'), isTrue);
      expect(deviceBProjects.every((p) => p.syncStatus == SyncStatusType.synced), isTrue);

      // 7. Verify Device B did NOT inject dummy starter projects (no "Cinematic Mountain Drone")
      expect(deviceBProjects.any((p) => p.title.contains('Cinematic Mountain')), isFalse);
    });
  });
}
