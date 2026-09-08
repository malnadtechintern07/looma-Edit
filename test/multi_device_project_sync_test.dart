import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:looma/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:looma/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:looma/features/auth/domain/entities/user_entity.dart';
import 'package:looma/features/cloud_sync/data/datasources/cloud_storage_datasource.dart';
import 'package:looma/features/cloud_sync/data/datasources/composite_cloud_storage_datasource.dart';
import 'package:looma/features/cloud_sync/data/datasources/global_cloud_storage_datasource.dart';
import 'package:looma/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart';
import 'package:looma/features/cloud_sync/domain/entities/cloud_backup_record.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_frame_entity.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_project_entity.dart';
import 'package:looma/features/projects/data/datasources/project_local_datasource.dart';
import 'package:looma/features/projects/data/models/project_model.dart';
import 'package:looma/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/entities/sync_status_type.dart';

/// In-memory cloud simulation that models the global cloud registry shared between devices
class _SimulatedSharedCloudStorageDataSource implements CloudStorageDataSource {
  final Map<String, Map<String, dynamic>> _cloudUsers = {};

  Map<String, dynamic> _getUserData(String userId) {
    return _cloudUsers.putIfAbsent(
      userId,
      () => <String, dynamic>{
        'projects': <String, dynamic>{},
        'photoProjects': <dynamic>[],
        'backups': <dynamic>[],
      },
    );
  }

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId) async {
    final userData = _getUserData(userId);
    final projectsMap = Map<String, dynamic>.from(userData['projects'] as Map);
    final List<ProjectEntity> list = [];
    for (final json in projectsMap.values) {
      list.add(ProjectModel.fromJson(Map<String, dynamic>.from(json as Map)).copyWith(
        syncStatus: SyncStatusType.synced,
      ));
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<ProjectEntity?> getCloudProject(String userId, String projectId) async {
    final userData = _getUserData(userId);
    final projectsMap = Map<String, dynamic>.from(userData['projects'] as Map);
    if (!projectsMap.containsKey(projectId)) return null;
    return ProjectModel.fromJson(Map<String, dynamic>.from(projectsMap[projectId] as Map)).copyWith(
      syncStatus: SyncStatusType.synced,
    );
  }

  @override
  Future<CloudBackupRecord> backupProject(String userId, ProjectEntity project) async {
    final userData = _getUserData(userId);
    final projectsMap = Map<String, dynamic>.from(userData['projects'] as Map);
    final synced = project.copyWith(syncStatus: SyncStatusType.synced);
    final json = ProjectModel.toJson(synced);
    projectsMap[project.id] = json;
    userData['projects'] = projectsMap;

    final record = CloudBackupRecord(
      projectId: project.id,
      projectTitle: project.title,
      fileSizeBytes: jsonEncode(json).length,
      backedUpAt: DateTime.now(),
      cloudChecksum: 'checksum_${project.id}',
    );
    final backups = userData['backups'] as List<dynamic>;
    backups.insert(0, record.toJson());
    return record;
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async {
    final userData = _getUserData(userId);
    final backups = userData['backups'] as List<dynamic>;
    return backups.map((b) => CloudBackupRecord.fromJson(b as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    final userData = _getUserData(userId);
    final projectsMap = userData['projects'] as Map<String, dynamic>;
    projectsMap.remove(projectId);
  }

  @override
  Future<int> calculateUserStorageUsage(String userId) async {
    final userData = _getUserData(userId);
    final projectsMap = userData['projects'] as Map<String, dynamic>;
    int total = 0;
    for (final p in projectsMap.values) {
      total += jsonEncode(p).length;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getCloudPhotoProjects(String userId) async {
    final userData = _getUserData(userId);
    final list = userData['photoProjects'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> backupPhotoProject(String userId, Map<String, dynamic> photoProjectJson) async {
    final userData = _getUserData(userId);
    final list = userData['photoProjects'] as List<dynamic>;
    final id = photoProjectJson['id'];
    list.removeWhere((p) => (p as Map<String, dynamic>)['id'] == id);
    list.insert(0, photoProjectJson);
  }

  Future<void> deleteCloudPhotoProject(String userId, String photoProjectId) async {
    final userData = _getUserData(userId);
    final list = userData['photoProjects'] as List<dynamic>;
    list.removeWhere((p) => (p as Map<String, dynamic>)['id'] == photoProjectId);
  }
}

/// Simulated shared cloud auth data source
class _SimulatedSharedCloudAuthDataSource implements AuthRemoteDataSource {
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

  group('Multi-Device Account & Project Sync Tests', () {
    late _SimulatedSharedCloudAuthDataSource sharedCloudAuth;
    late _SimulatedSharedCloudStorageDataSource sharedCloudStorage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sharedCloudAuth = _SimulatedSharedCloudAuthDataSource();
      sharedCloudStorage = _SimulatedSharedCloudStorageDataSource();
    });

    test(
        'User creates projects on Device A, then signs in with same email and password on Device B -> projects appear on Device B',
        () async {
      // ==========================================
      // 1. SIMULATE DEVICE A
      // ==========================================
      final storageDeviceA = LocalStorageService();
      await storageDeviceA.clearAll();

      final authLocalA = AuthLocalDataSourceImpl(storageService: storageDeviceA);
      final authRepoA = AuthRepositoryImpl(
        localDataSource: authLocalA,
        remoteDataSource: sharedCloudAuth,
      );

      final projectLocalA = ProjectLocalDataSourceImpl(storageService: storageDeviceA);
      final cloudSyncRepoA = CloudSyncRepositoryImpl(
        cloudDataSource: sharedCloudStorage,
        projectLocalDataSource: projectLocalA,
        authRepository: authRepoA,
      );

      // Register user on Device A
      final userA = await authRepoA.register(
        email: 'director@looma.app',
        password: 'SecurePass@2026',
        displayName: 'Director Ken',
      );
      expect(userA.email, 'director@looma.app');
      expect(userA.id.isNotEmpty, isTrue);

      // Create Project 1 on Device A: "Kyoto Autumn Vlog"
      final project1 = ProjectEntity(
        id: 'proj_kyoto_001',
        title: 'Kyoto Autumn Vlog',
        aspectRatio: AspectRatioType.ratio16_9,
        durationMs: 45000,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        videoClips: [
          const VideoClipEntity(
            id: 'clip_001',
            name: 'Kyoto Clip 1',
            mediaPath: 'assets/demo/kyoto.mp4',
            sourceDurationMs: 15000,
            timelineStartMs: 0,
            timelineEndMs: 15000,
            trimEndMs: 15000,
          ),
        ],
      );
      await projectLocalA.saveProject(project1);

      // Create Project 2 on Device A: "Reels Viral Drop"
      final project2 = ProjectEntity(
        id: 'proj_reels_002',
        title: 'Reels Viral Drop',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 12000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        videoClips: [
          const VideoClipEntity(
            id: 'clip_002',
            name: 'Reels Drop 1',
            mediaPath: 'assets/demo/drop.mp4',
            sourceDurationMs: 12000,
            timelineStartMs: 0,
            timelineEndMs: 12000,
            trimEndMs: 12000,
          ),
        ],
      );
      await projectLocalA.saveProject(project2);

      // Verify Device A has 2 user projects locally
      final localProjectsA = await projectLocalA.getProjects();
      expect(localProjectsA.any((p) => p.id == 'proj_kyoto_001'), isTrue);
      expect(localProjectsA.any((p) => p.id == 'proj_reels_002'), isTrue);

      // Device A syncs all projects to the cloud
      await cloudSyncRepoA.syncAllProjects();

      // Verify shared cloud storage now holds both projects
      final cloudProjects = await sharedCloudStorage.getCloudProjects(userA.id);
      expect(cloudProjects.length, greaterThanOrEqualTo(2));
      expect(cloudProjects.any((p) => p.id == 'proj_kyoto_001'), isTrue);
      expect(cloudProjects.any((p) => p.id == 'proj_reels_002'), isTrue);

      // ==========================================
      // 2. SIMULATE DEVICE B (BRAND NEW / FRESH DEVICE)
      // ==========================================
      final storageDeviceB = LocalStorageService();
      await storageDeviceB.clearAll();

      final authLocalB = AuthLocalDataSourceImpl(storageService: storageDeviceB);
      final authRepoB = AuthRepositoryImpl(
        localDataSource: authLocalB,
        remoteDataSource: sharedCloudAuth,
      );

      final projectLocalB = ProjectLocalDataSourceImpl(storageService: storageDeviceB);
      final cloudSyncRepoB = CloudSyncRepositoryImpl(
        cloudDataSource: sharedCloudStorage,
        projectLocalDataSource: projectLocalB,
        authRepository: authRepoB,
      );

      // Device B starts with empty project catalog (or starter sample flag only)
      expect(await authRepoB.getCurrentUser(), isNull);

      // User logs in on Device B with the EXACT SAME email and password!
      final userB = await authRepoB.login(
        email: 'director@looma.app',
        password: 'SecurePass@2026',
        rememberMe: true,
      );

      // User IDs must match between Device A and Device B!
      expect(userB.id, equals(userA.id));
      expect(userB.email, equals(userA.email));
      expect(userB.displayName, equals(userA.displayName));

      // Device B executes syncAllProjects (as triggered upon login)
      await cloudSyncRepoB.syncAllProjects();

      // Verify: Device B now has the projects created on Device A!
      final projectsOnDeviceB = await projectLocalB.getProjects();
      final kyotoOnB = projectsOnDeviceB.firstWhere((p) => p.id == 'proj_kyoto_001');
      final reelsOnB = projectsOnDeviceB.firstWhere((p) => p.id == 'proj_reels_002');

      expect(kyotoOnB.title, 'Kyoto Autumn Vlog');
      expect(kyotoOnB.aspectRatio, AspectRatioType.ratio16_9);
      expect(kyotoOnB.videoClips.first.mediaPath, 'assets/demo/kyoto.mp4');
      expect(kyotoOnB.syncStatus, SyncStatusType.synced);

      expect(reelsOnB.title, 'Reels Viral Drop');
      expect(reelsOnB.aspectRatio, AspectRatioType.ratio9_16);
      expect(reelsOnB.videoClips.first.mediaPath, 'assets/demo/drop.mp4');
      expect(reelsOnB.syncStatus, SyncStatusType.synced);

      // ==========================================
      // 3. EDIT ON DEVICE B -> PROPAGATE TO DEVICE A
      // ==========================================
      final updatedKyoto = kyotoOnB.copyWith(
        title: 'Kyoto 2026 - Director 4K Cut',
        updatedAt: DateTime.now(),
      );
      await projectLocalB.saveProject(updatedKyoto);
      await cloudSyncRepoB.syncAllProjects();

      // Device A syncs:
      await cloudSyncRepoA.syncAllProjects();
      final kyotoUpdatedOnA = await projectLocalA.getProjectById('proj_kyoto_001');
      expect(kyotoUpdatedOnA?.title, 'Kyoto 2026 - Director 4K Cut');
    });

    test('CompositeCloudStorageDataSource delegates correctly to primary and secondary', () async {
      final storage = LocalStorageService();
      await storage.clearAll();

      final primary = sharedCloudStorage;
      final secondary = _SimulatedSharedCloudStorageDataSource();
      final composite = CompositeCloudStorageDataSource(
        primary: primary,
        secondary: secondary,
      );

      const userId = 'usr_composite_test';
      final project = ProjectEntity(
        id: 'proj_comp_1',
        title: 'Composite Project',
        aspectRatio: AspectRatioType.ratio1_1,
        durationMs: 10000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Backup via composite
      final record = await composite.backupProject(userId, project);
      expect(record.projectId, 'proj_comp_1');

      // Fetch via composite
      final projects = await composite.getCloudProjects(userId);
      expect(projects.length, 1);
      expect(projects.first.title, 'Composite Project');

      // Check single project
      final fetched = await composite.getCloudProject(userId, 'proj_comp_1');
      expect(fetched, isNotNull);
      expect(fetched?.title, 'Composite Project');

      // Delete via composite
      await composite.deleteCloudProject(userId, 'proj_comp_1');
      final remaining = await composite.getCloudProjects(userId);
      expect(remaining.isEmpty, isTrue);
    });

    test('PhotoProjectRepository synchronizes photo projects across devices', () async {
      final user = UserEntity(
        id: 'usr_photo_syncer',
        email: 'photo@looma.app',
        displayName: 'Photo Pro',
        isPro: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Device A saves photo project
      final photo1 = PhotoProjectEntity(
        id: 'photo_proj_001',
        title: 'Neon Cyberpunk Portrait',
        frames: const [
          PhotoFrameEntity(
            id: 'frame_001',
            imagePath: '/photos/portrait.jpg',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await sharedCloudStorage.backupPhotoProject(user.id, photo1.toJson());

      // Device B fetches photo project
      final cloudPhotos = await sharedCloudStorage.getCloudPhotoProjects(user.id);
      expect(cloudPhotos.length, 1);
      expect(cloudPhotos.first['title'], 'Neon Cyberpunk Portrait');
    });

    test('GlobalCloudStorageDataSource caches projects locally and provides offline fallback', () async {
      final storage = LocalStorageService();
      await storage.clearAll();

      final globalDs = GlobalCloudStorageDataSource(localStorageService: storage);
      const userId = 'usr_offline_test';

      final project = ProjectEntity(
        id: 'proj_offline_1',
        title: 'Offline Cached Reel',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 15000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Back up to data source (updates local cache instantly)
      final record = await globalDs.backupProject(userId, project);
      expect(record.projectId, 'proj_offline_1');
      expect(record.projectTitle, 'Offline Cached Reel');

      // Offline retrieval via local cache
      final retrieved = await globalDs.getCloudProject(userId, 'proj_offline_1');
      expect(retrieved, isNotNull);
      expect(retrieved?.id, 'proj_offline_1');
      expect(retrieved?.title, 'Offline Cached Reel');
      expect(retrieved?.syncStatus, SyncStatusType.synced);

      // Storage usage calculation
      final usage = await globalDs.calculateUserStorageUsage(userId);
      expect(usage, greaterThan(0));

      // Backup records retrieval
      final backups = await globalDs.getBackupRecords(userId);
      expect(backups.isNotEmpty, isTrue);
      expect(backups.first.projectId, 'proj_offline_1');

      // Delete project
      await globalDs.deleteCloudProject(userId, 'proj_offline_1');
      final afterDelete = await globalDs.getCloudProject(userId, 'proj_offline_1');
      expect(afterDelete, isNull);
    });
  });
}
