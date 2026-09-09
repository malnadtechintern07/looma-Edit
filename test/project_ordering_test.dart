import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/auth/domain/entities/user_entity.dart';
import 'package:procut/features/auth/domain/repositories/auth_repository.dart';
import 'package:procut/features/cloud_sync/data/datasources/cloud_storage_datasource.dart';
import 'package:procut/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart';
import 'package:procut/features/cloud_sync/domain/entities/cloud_backup_record.dart';
import 'package:procut/features/projects/data/datasources/project_local_datasource.dart';
import 'package:procut/features/projects/data/repositories/project_repository_impl.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/usecases/project_usecases.dart';
import 'package:procut/features/projects/presentation/providers/projects_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  final UserEntity _user = UserEntity(
    id: 'user_123',
    email: 'creator@looma.app',
    displayName: 'Looma Creator',
    createdAt: DateTime(2026, 1, 1),
    lastLoginAt: DateTime(2026, 1, 1),
  );

  @override
  Future<UserEntity?> getCurrentUser() async => _user;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async => _user;

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String displayName,
  }) async => _user;

  @override
  Future<void> forgotPassword({
    required String email,
    required String newPassword,
  }) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<UserEntity?> restoreSession() async => _user;

  @override
  Future<void> syncLocalAccountsToCloud() async {}
}

class _FakeCloudStorageDataSource implements CloudStorageDataSource {
  final Map<String, ProjectEntity> cloudProjects = {};

  @override
  Future<CloudBackupRecord> backupProject(String userId, ProjectEntity project) async {
    cloudProjects[project.id] = project;
    return CloudBackupRecord(
      projectId: project.id,
      projectTitle: project.title,
      fileSizeBytes: 1024,
      backedUpAt: DateTime.now(),
      cloudChecksum: 'checksum_test',
    );
  }

  @override
  Future<int> calculateUserStorageUsage(String userId) async => 1024;

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    cloudProjects.remove(projectId);
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async => [];

  @override
  Future<ProjectEntity?> getCloudProject(String userId, String projectId) async => cloudProjects[projectId];

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId) async => cloudProjects.values.toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late ProjectLocalDataSource localDataSource;
  late ProjectRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = LocalStorageService();
    await storageService.clearAll();
    localDataSource = ProjectLocalDataSourceImpl(storageService: storageService);
    repository = ProjectRepositoryImpl(localDataSource: localDataSource);
    final now = DateTime.now();
    await repository.saveProject(
      ProjectEntity(
        id: 'p1',
        title: 'Project 1',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
    );
    await repository.saveProject(
      ProjectEntity(
        id: 'p2',
        title: 'Project 2',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
    );
  });

  group('Project Sorting & Refresh Stability Tests', () {
    test('Initial getProjects always returns default projects sorted by updatedAt descending', () async {
      final projects = await repository.getProjects();
      expect(projects.length, greaterThanOrEqualTo(2));

      for (int i = 0; i < projects.length - 1; i++) {
        final current = projects[i].updatedAt;
        final next = projects[i + 1].updatedAt;
        expect(
          current.isAfter(next) || current.isAtSameMomentAs(next),
          isTrue,
          reason: 'Project at index $i must be newer than or equal to index ${i + 1}',
        );
      }
    });

    test('Editing an existing project moves it to the top (index 0) of the list', () async {
      final initial = await repository.getProjects();
      // Pick the last project (oldest)
      final oldestProject = initial.last;

      // Edit this project with a new updatedAt timestamp
      final updatedProject = oldestProject.copyWith(
        title: '${oldestProject.title} - Edited Just Now',
        updatedAt: DateTime.now().add(const Duration(seconds: 5)),
      );
      await repository.saveProject(updatedProject);

      final reloaded = await repository.getProjects();
      expect(reloaded.first.id, equals(oldestProject.id));
      expect(reloaded.first.title, contains('Edited Just Now'));
    });

    test('Multiple consecutive cloud sync operations NEVER flip or invert project order', () async {
      final initial = await repository.getProjects();
      final initialOrderIds = initial.map((p) => p.id).toList();

      final fakeAuth = _FakeAuthRepository();
      final fakeCloud = _FakeCloudStorageDataSource();
      final syncRepo = CloudSyncRepositoryImpl(
        cloudDataSource: fakeCloud,
        projectLocalDataSource: localDataSource,
        authRepository: fakeAuth,
      );

      // Trigger sync multiple times in a row (simulating multiple app refreshes)
      for (int i = 0; i < 5; i++) {
        await syncRepo.syncAllProjects();
        final refreshedProjects = await repository.getProjects();
        final refreshedIds = refreshedProjects.map((p) => p.id).toList();

        expect(
          refreshedIds,
          equals(initialOrderIds),
          reason: 'Refresh iteration $i must preserve exact project order and not invert',
        );
      }
    });

    test('ProjectsNotifier loadProjects and filteredProjectsProvider reliably keep newest project first', () async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          getProjectsUseCaseProvider.overrideWithValue(GetProjectsUseCase(repository)),
          getProjectByIdUseCaseProvider.overrideWithValue(GetProjectByIdUseCase(repository)),
          saveProjectUseCaseProvider.overrideWithValue(SaveProjectUseCase(repository)),
          updateProjectUseCaseProvider.overrideWithValue(UpdateProjectUseCase(repository)),
          deleteProjectUseCaseProvider.overrideWithValue(DeleteProjectUseCase(repository)),
          duplicateProjectUseCaseProvider.overrideWithValue(DuplicateProjectUseCase(repository)),
        ],
      );

      // Let initial load complete
      await container.read(projectsNotifierProvider.notifier).loadProjects();
      var stateProjects = container.read(projectsNotifierProvider).projects;
      expect(stateProjects.isNotEmpty, isTrue);

      // Create a brand new project
      final created = await container.read(projectsNotifierProvider.notifier).createProject(
        title: 'Brand New Vlog',
        aspectRatio: AspectRatioType.ratio9_16,
      );

      // Newly created project MUST be at index 0
      stateProjects = container.read(projectsNotifierProvider).projects;
      expect(stateProjects.first.id, equals(created.id));

      var filtered = container.read(filteredProjectsProvider);
      expect(filtered.first.id, equals(created.id));

      // Rename an older project
      final olderProject = stateProjects.last;
      await container.read(projectsNotifierProvider.notifier).renameProject(
        olderProject.id,
        'Old Project Renamed to Top',
      );

      // Renamed project should now be at the very top (index 0) because rename updates updatedAt
      stateProjects = container.read(projectsNotifierProvider).projects;
      expect(stateProjects.first.id, equals(olderProject.id));
      expect(stateProjects.first.title, equals('Old Project Renamed to Top'));

      filtered = container.read(filteredProjectsProvider);
      expect(filtered.first.id, equals(olderProject.id));

      container.dispose();
    });
  });
}
