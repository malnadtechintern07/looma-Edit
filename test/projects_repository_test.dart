import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/projects/data/datasources/project_local_datasource.dart';
import 'package:procut/features/projects/data/repositories/project_repository_impl.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late ProjectLocalDataSource dataSource;
  late ProjectRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = LocalStorageService();
    await storageService.clearAll();
    dataSource = ProjectLocalDataSourceImpl(storageService: storageService);
    repository = ProjectRepositoryImpl(localDataSource: dataSource);
    // Initialize seed catalog
    await repository.getProjects();
  });

  group('ProjectRepository Tests', () {
    test('Initial getProjects returns clean empty list before projects are created', () async {
      final projects = await repository.getProjects();
      expect(projects.isEmpty, isTrue);
    });

    test('Save and retrieve a new project', () async {
      final project = ProjectEntity(
        id: 'test-project-1',
        title: 'My Custom Reel',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveProject(project);

      final retrieved = await repository.getProjectById('test-project-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'My Custom Reel');
      expect(retrieved.aspectRatio, AspectRatioType.ratio9_16);
    });

    test('Duplicate project creates copy with unique ID', () async {
      final project = ProjectEntity(
        id: 'test-proj-dup',
        title: 'My Vlog',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.saveProject(project);

      final duplicated = await repository.duplicateProject('test-proj-dup');
      expect(duplicated.id, isNot('test-proj-dup'));
      expect(duplicated.title, contains('(Copy)'));
    });

    test('Delete project removes it from catalog', () async {
      final project = ProjectEntity(
        id: 'test-proj-del',
        title: 'To Delete',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.saveProject(project);

      await repository.deleteProject('test-proj-del');
      final deleted = await repository.getProjectById('test-proj-del');
      expect(deleted, isNull);
    });
  });
}
