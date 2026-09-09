import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:procut/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:procut/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:procut/features/auth/domain/services/password_hasher.dart';
import 'package:procut/features/cloud_sync/data/datasources/cloud_storage_datasource.dart';
import 'package:procut/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart';
import 'package:procut/features/editor/domain/entities/transition_type.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/filters_effects/domain/entities/filter_preset.dart';
import 'package:procut/features/filters_effects/domain/entities/video_effect_type.dart';
import 'package:procut/features/projects/data/datasources/project_local_datasource.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';
import 'package:procut/features/text_stickers/domain/entities/overlay_animation_type.dart';
import 'package:procut/features/text_stickers/domain/entities/sticker_overlay_entity.dart';
import 'package:procut/features/text_stickers/domain/entities/text_overlay_entity.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late AuthLocalDataSource authLocalDataSource;
  late AuthRepositoryImpl authRepository;
  late CloudStorageDataSource cloudStorageDataSource;
  late ProjectLocalDataSource projectLocalDataSource;
  late CloudSyncRepositoryImpl cloudSyncRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = LocalStorageService();
    await storageService.clearAll();

    authLocalDataSource = AuthLocalDataSourceImpl(storageService: storageService);
    authRepository = AuthRepositoryImpl(localDataSource: authLocalDataSource);

    cloudStorageDataSource = CloudStorageDataSourceImpl(storageService: storageService);
    projectLocalDataSource = ProjectLocalDataSourceImpl(storageService: storageService);

    cloudSyncRepository = CloudSyncRepositoryImpl(
      cloudDataSource: cloudStorageDataSource,
      projectLocalDataSource: projectLocalDataSource,
      authRepository: authRepository,
    );
  });

  group('Password Hasher Tests', () {
    test('generateSalt returns distinct non-empty values', () {
      final salt1 = PasswordHasher.generateSalt();
      final salt2 = PasswordHasher.generateSalt();
      expect(salt1.isNotEmpty, isTrue);
      expect(salt2.isNotEmpty, isTrue);
      expect(salt1, isNot(equals(salt2)));
    });

    test('hashPassword is deterministic with same salt and password', () {
      final salt = PasswordHasher.generateSalt();
      final hash1 = PasswordHasher.hashPassword('SuperSecret123', salt);
      final hash2 = PasswordHasher.hashPassword('SuperSecret123', salt);
      expect(hash1, equals(hash2));
    });

    test('verifyPassword correctly matches password and rejects incorrect password', () {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hashPassword('MyPassword@2026', salt);

      expect(PasswordHasher.verifyPassword('MyPassword@2026', salt, hash), isTrue);
      expect(PasswordHasher.verifyPassword('WrongPassword', salt, hash), isFalse);
      expect(PasswordHasher.verifyPassword('mypassword@2026', salt, hash), isFalse);
    });
  });

  group('Authentication Flow Tests', () {
    test('Register new user succeeds and persists session', () async {
      final user = await authRepository.register(
        email: 'creator@looma.app',
        password: 'Password123',
        displayName: 'Elena Rostova',
      );

      expect(user.id.startsWith('usr_'), isTrue);
      expect(user.email, 'creator@looma.app');
      expect(user.displayName, 'Elena Rostova');

      // Check current user
      final current = await authRepository.getCurrentUser();
      expect(current, isNotNull);
      expect(current?.id, user.id);
    });

    test('Register duplicate email throws exception', () async {
      await authRepository.register(
        email: 'alex@looma.app',
        password: 'Password123',
        displayName: 'Alex',
      );

      expect(
        () => authRepository.register(
          email: 'alex@looma.app',
          password: 'AnotherPassword',
          displayName: 'Alex Clone',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Login with valid credentials succeeds and restores session', () async {
      await authRepository.register(
        email: 'sarah@looma.app',
        password: 'SecretPassword99',
        displayName: 'Sarah Connor',
      );

      // Logout
      await authRepository.logout();
      expect(await authRepository.getCurrentUser(), isNull);

      // Login
      final loggedIn = await authRepository.login(
        email: 'sarah@looma.app',
        password: 'SecretPassword99',
        rememberMe: true,
      );

      expect(loggedIn.email, 'sarah@looma.app');
      expect(await authRepository.getCurrentUser(), isNotNull);
    });

    test('Login with invalid password throws exception', () async {
      await authRepository.register(
        email: 'user@looma.app',
        password: 'ValidPassword123',
        displayName: 'User',
      );

      expect(
        () => authRepository.login(
          email: 'user@looma.app',
          password: 'WrongPassword!',
          rememberMe: true,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Forgot password updates credentials and allows login with new password', () async {
      await authRepository.register(
        email: 'reset_me@looma.app',
        password: 'OldPassword123',
        displayName: 'Reset User',
      );

      await authRepository.forgotPassword(
        email: 'reset_me@looma.app',
        newPassword: 'BrandNewPassword456',
      );

      // Old password must fail
      expect(
        () => authRepository.login(
          email: 'reset_me@looma.app',
          password: 'OldPassword123',
          rememberMe: true,
        ),
        throwsA(isA<Exception>()),
      );

      // New password must succeed
      final user = await authRepository.login(
        email: 'reset_me@looma.app',
        password: 'BrandNewPassword456',
        rememberMe: true,
      );
      expect(user.email, 'reset_me@looma.app');
    });

    test('Remember me false clears session on cold restart', () async {
      await authRepository.register(
        email: 'temp@looma.app',
        password: 'Password123',
        displayName: 'Temp User',
      );

      await authRepository.login(
        email: 'temp@looma.app',
        password: 'Password123',
        rememberMe: false,
      );

      // Simulate app kill & relaunch: read from local data source
      final freshAuthRepo = AuthRepositoryImpl(localDataSource: authLocalDataSource);
      final restored = await freshAuthRepo.restoreSession();
      expect(restored, isNull);
    });
  });

  group('Cloud Project Backup & Multi-User Isolation Tests', () {
    test('Unauthenticated user cannot access cloud storage', () async {
      expect(
        () => cloudStorageDataSource.getCloudProjects(''),
        throwsA(isA<Exception>()),
      );
      expect(
        () => cloudSyncRepository.backupProject('any-proj'),
        throwsA(isA<Exception>()),
      );
    });

    test('Complete project data is backed up to cloud and restored with 100% fidelity', () async {
      final user = await authRepository.register(
        email: 'filmmaker@looma.app',
        password: 'Password123',
        displayName: 'Cinematographer',
      );

      final fullProject = ProjectEntity(
        id: 'proj-epic-cinematic',
        title: 'Epic Sunset Vlog',
        aspectRatio: AspectRatioType.ratio9_16,
        fps: 60,
        resolutionWidth: 1080,
        resolutionHeight: 1920,
        durationMs: 25000,
        lastPlayheadPositionMs: 12500,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatusType.localOnly,
        videoClips: const [
          VideoClipEntity(
            id: 'v1',
            mediaPath: 'assets/demo/golden_hour.mp4',
            name: 'Golden Hour Shot',
            sourceDurationMs: 15000,
            timelineStartMs: 0,
            timelineEndMs: 12000,
            trimStartMs: 1000,
            trimEndMs: 13000,
            speed: 1.2,
            volume: 0.8,
            filterType: FilterType.cinematic,
            filterIntensity: 0.9,
            effectType: VideoEffectType.glitch,
            effectIntensity: 0.7,
            transitionIn: TransitionType.glitch,
            transitionDurationMs: 400,
            rotationDegrees: 90,
            opacity: 0.95,
          ),
        ],
        audioClips: const [
          AudioClipEntity(
            id: 'a1',
            mediaPath: 'assets/audio/ambient_nature.mp3',
            title: 'Nature Ambient Sound',
            category: AudioCategory.soundEffect,
            timelineStartMs: 0,
            timelineEndMs: 20000,
            trimStartMs: 0,
            trimEndMs: 20000,
            volume: 0.75,
            waveformSamples: [0.1, 0.4, 0.8, 0.6, 0.3],
          ),
        ],
        textOverlays: const [
          TextOverlayEntity(
            id: 't1',
            text: 'GOLDEN HOUR MAGIC',
            fontFamily: 'Inter',
            fontSize: 32,
            colorHex: 0xFFFFD700,
            posX: 0.5,
            posY: 0.3,
            timelineStartMs: 1000,
            timelineEndMs: 6000,
            animationType: OverlayAnimationType.slideUp,
          ),
        ],
        stickerOverlays: const [
          StickerOverlayEntity(
            id: 's1',
            stickerKey: 'sparkle',
            stickerName: 'Sparkles',
            assetEmojiOrPath: '✨',
            posX: 0.8,
            posY: 0.2,
            scale: 1.5,
            timelineStartMs: 500,
            timelineEndMs: 5000,
          ),
        ],
      );

      // Save locally first
      await projectLocalDataSource.saveProject(fullProject);

      // Backup to cloud
      await cloudSyncRepository.backupProject(fullProject.id);

      // Check cloud project
      final cloudProject = await cloudStorageDataSource.getCloudProject(user.id, fullProject.id);
      expect(cloudProject, isNotNull);
      expect(cloudProject?.id, fullProject.id);
      expect(cloudProject?.title, 'Epic Sunset Vlog');
      expect(cloudProject?.aspectRatio, AspectRatioType.ratio9_16);
      expect(cloudProject?.videoClips.length, 1);
      expect(cloudProject?.videoClips.first.filterType, FilterType.cinematic);
      expect(cloudProject?.videoClips.first.effectType, VideoEffectType.glitch);
      expect(cloudProject?.audioClips.length, 1);
      expect(cloudProject?.audioClips.first.waveformSamples, [0.1, 0.4, 0.8, 0.6, 0.3]);
      expect(cloudProject?.textOverlays.length, 1);
      expect(cloudProject?.textOverlays.first.text, 'GOLDEN HOUR MAGIC');
      expect(cloudProject?.stickerOverlays.length, 1);
      expect(cloudProject?.stickerOverlays.first.assetEmojiOrPath, '✨');
      expect(cloudProject?.syncStatus, SyncStatusType.synced);
    });

    test('Private cloud workspaces are strictly isolated between users', () async {
      // User 1 registers and creates project
      final user1 = await authRepository.register(
        email: 'user1@looma.app',
        password: 'Password123',
        displayName: 'User One',
      );

      final projectUser1 = ProjectEntity(
        id: 'u1-proj-secret',
        title: 'User One Confidential Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cloudStorageDataSource.backupProject(user1.id, projectUser1);

      // User 2 registers
      final user2 = await authRepository.register(
        email: 'user2@looma.app',
        password: 'Password123',
        displayName: 'User Two',
      );

      // User 2 must NOT see User 1's project
      final user2Projects = await cloudStorageDataSource.getCloudProjects(user2.id);
      expect(user2Projects.isEmpty, isTrue);

      final user2DirectAccess = await cloudStorageDataSource.getCloudProject(user2.id, projectUser1.id);
      expect(user2DirectAccess, isNull);

      // User 1 can see their project
      final user1Projects = await cloudStorageDataSource.getCloudProjects(user1.id);
      expect(user1Projects.length, 1);
      expect(user1Projects.first.id, projectUser1.id);
    });

    test('syncAllProjects restores cloud projects when logging into new device', () async {
      // 1. User registers and uploads project to cloud
      final user = await authRepository.register(
        email: 'cloud_traveller@looma.app',
        password: 'Password123',
        displayName: 'Traveller',
      );

      final cloudProj = ProjectEntity(
        id: 'traveller-film',
        title: 'Iceland Drone Odyssey',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cloudStorageDataSource.backupProject(user.id, cloudProj);

      // 2. Wipe local projects to simulate brand new phone or app re-install
      await storageService.deleteFile('projects/catalog.json');
      await storageService.deleteFile('projects/project_${cloudProj.id}.json');
      expect(await projectLocalDataSource.getProjectById(cloudProj.id), isNull);

      // 3. User logs in on new device and syncs
      await cloudSyncRepository.syncAllProjects();

      // 4. Project must now be restored locally in My Projects
      final restoredLocal = await projectLocalDataSource.getProjectById(cloudProj.id);
      expect(restoredLocal, isNotNull);
      expect(restoredLocal?.id, 'traveller-film');
      expect(restoredLocal?.title, 'Iceland Drone Odyssey');
      expect(restoredLocal?.syncStatus, SyncStatusType.synced);
    });

    test('Deleting cloud backup leaves local project intact', () async {
      await authRepository.register(
        email: 'safety_first@looma.app',
        password: 'Password123',
        displayName: 'Safety First',
      );

      final p = ProjectEntity(
        id: 'safety-proj',
        title: 'Local and Cloud Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatusType.synced,
      );

      await projectLocalDataSource.saveProject(p);
      await cloudSyncRepository.backupProject(p.id);

      // Delete cloud backup
      await cloudSyncRepository.deleteCloudProject(p.id);

      // Local project MUST NOT be deleted
      final local = await projectLocalDataSource.getProjectById(p.id);
      expect(local, isNotNull);
      expect(local?.title, 'Local and Cloud Project');
      expect(local?.syncStatus, SyncStatusType.localOnly);
    });
  });
}
