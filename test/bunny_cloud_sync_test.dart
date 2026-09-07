import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/features/auth/domain/entities/user_entity.dart';
import 'package:looma/features/auth/presentation/providers/auth_provider.dart';
import 'package:looma/features/cloud_sync/data/datasources/bunny_cloud_storage_datasource.dart';
import 'package:looma/features/cloud_sync/domain/entities/bunny_storage_config.dart';
import 'package:looma/features/cloud_sync/domain/entities/user_account_entity.dart';
import 'package:looma/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:looma/features/cloud_sync/presentation/screens/cloud_sync_screen.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/entities/sync_status_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late BunnyStorageConfig config;
  late BunnyCloudStorageDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = LocalStorageService();
    await storageService.clearAll();

    config = const BunnyStorageConfig(
      storageZoneName: 'test-zone',
      accessKey: 'test-key-123',
      storageEndpoint: 'storage.bunnycdn.com',
      cdnHostname: 'test-zone.b-cdn.net',
    );

    dataSource = BunnyCloudStorageDataSource(
      localStorageService: storageService,
      config: config,
    );
  });

  group('BunnyStorageConfig Tests', () {
    test('defaultConfig has valid default values', () {
      final def = BunnyStorageConfig.defaultConfig();
      expect(def.storageZoneName, 'looma-storage');
      expect(def.hasValidCredentials, isTrue);
      expect(def.storageEndpoint, 'storage.bunnycdn.com');
      expect(def.isEnabled, isTrue);
    });

    test('toJson and fromJson serialize accurately', () {
      final json = config.toJson();
      final reconstructed = BunnyStorageConfig.fromJson(json);

      expect(reconstructed.storageZoneName, config.storageZoneName);
      expect(reconstructed.accessKey, config.accessKey);
      expect(reconstructed.storageEndpoint, config.storageEndpoint);
      expect(reconstructed.cdnHostname, config.cdnHostname);
    });

    test('availableRegions contains standard Bunny.net regions', () {
      expect(BunnyStorageConfig.availableRegions.containsKey('Global / Falkenstein (Default)'), isTrue);
      expect(BunnyStorageConfig.availableRegions.containsKey('Asia (Singapore)'), isTrue);
      expect(BunnyStorageConfig.availableRegions.containsKey('US East (New York)'), isTrue);
    });
  });

  group('BunnyCloudStorageDataSource Tests', () {
    final testProject = ProjectEntity(
      id: 'proj_bunny_101',
      title: 'Cinematic Vlog with Bunny',
      aspectRatio: AspectRatioType.ratio9_16,
      fps: 30,
      durationMs: 12000,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 7),
      syncStatus: SyncStatusType.localOnly,
      videoClips: [
        const VideoClipEntity(
          id: 'clip_1',
          mediaPath: 'assets/branding/demo_vid1.mp4',
          name: 'Scene 1',
          sourceDurationMs: 6000,
          timelineStartMs: 0,
          timelineEndMs: 6000,
          trimStartMs: 0,
          trimEndMs: 6000,
        ),
      ],
    );


    test('backupProject creates local cache and backup record with bny_ prefix', () async {
      const userId = 'usr_test_1';
      final record = await dataSource.backupProject(userId, testProject);

      expect(record.projectId, 'proj_bunny_101');
      expect(record.projectTitle, 'Cinematic Vlog with Bunny');
      expect(record.cloudChecksum.startsWith('bny_'), isTrue);
      expect(record.fileSizeBytes, greaterThan(0));

      // Check local cache
      final cached = await dataSource.getCloudProject(userId, 'proj_bunny_101');
      expect(cached, isNotNull);
      expect(cached?.title, 'Cinematic Vlog with Bunny');
      expect(cached?.syncStatus, SyncStatusType.synced);
    });

    test('getCloudProjects lists user projects sorted by updatedAt descending', () async {
      const userId = 'usr_test_2';
      final projA = testProject.copyWith(id: 'proj_A', updatedAt: DateTime(2026, 9, 1));
      final projB = testProject.copyWith(id: 'proj_B', updatedAt: DateTime(2026, 9, 5));

      await dataSource.backupProject(userId, projA);
      await dataSource.backupProject(userId, projB);

      final list = await dataSource.getCloudProjects(userId);
      expect(list.length, 2);
      expect(list.first.id, 'proj_B'); // Newer first
      expect(list.last.id, 'proj_A');
    });

    test('deleteCloudProject removes project from catalog and backups', () async {
      const userId = 'usr_test_3';
      await dataSource.backupProject(userId, testProject);

      final initial = await dataSource.getCloudProjects(userId);
      expect(initial.length, 1);

      await dataSource.deleteCloudProject(userId, testProject.id);

      final after = await dataSource.getCloudProjects(userId);
      expect(after.isEmpty, isTrue);

      final backups = await dataSource.getBackupRecords(userId);
      expect(backups.isEmpty, isTrue);
    });

    test('User isolation: user A projects are isolated from user B', () async {
      const userA = 'usr_alice';
      const userB = 'usr_bob';

      await dataSource.backupProject(userA, testProject);

      final listA = await dataSource.getCloudProjects(userA);
      final listB = await dataSource.getCloudProjects(userB);

      expect(listA.length, 1);
      expect(listB.isEmpty, isTrue);
    });

    test('calculateUserStorageUsage aggregates file size correctly', () async {
      const userId = 'usr_test_4';
      await dataSource.backupProject(userId, testProject);

      final usage = await dataSource.calculateUserStorageUsage(userId);
      expect(usage, greaterThan(0));
    });
  });

  group('CloudSyncScreen Bunny.net UI Tests', () {
    testWidgets('Displays Bunny.net Cloud status card when user is authenticated', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockUser = UserEntity(
        id: 'usr_authenticated_1',
        email: 'creator@looma.app',
        displayName: 'Elena Rostova',
        createdAt: DateTime(2026, 1, 1),
        lastLoginAt: DateTime(2026, 1, 1),
        isPro: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => _MockAuthNotifier(
                AuthState(status: AuthStatus.authenticated, user: mockUser),
              ),
            ),
            userProfileFutureProvider.overrideWith((ref) async => UserAccountEntity(
              id: 'usr_authenticated_1',
              displayName: 'Elena Rostova',
              email: 'creator@looma.app',
              avatarUrl: '',
              memberSince: DateTime(2026, 1, 1),
              usedCloudStorageBytes: 1024,
              totalCloudStorageBytes: 15 * 1024 * 1024 * 1024,
              isProMember: true,
            )),
            cloudBackupsFutureProvider.overrideWith((ref) async => []),
          ],

          child: const MaterialApp(
            home: CloudSyncScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Bunny.net Cloud badge appears
      expect(find.text('Bunny.net Edge Cloud'), findsOneWidget);
      expect(find.text('Configure'), findsOneWidget);

      // Tap Configure to open settings dialog
      await tester.tap(find.text('Configure'));
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.text('Bunny.net Storage Settings 🐰'), findsOneWidget);
      expect(find.text('Storage Zone Name'), findsOneWidget);
      expect(find.text('Storage Region Endpoint'), findsOneWidget);
      expect(find.text('Save Settings'), findsOneWidget);
    });
  });
}

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(super.state);

  @override
  Future<void> checkCurrentSession() async {}

  @override
  Future<bool> login({required String email, required String password, bool rememberMe = true}) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> register({required String email, required String password, required String displayName}) async => true;

  @override
  void clearError() {}

  @override
  Future<bool> forgotPassword({required String email, required String newPassword}) async => true;
}


