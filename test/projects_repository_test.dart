import 'package:flutter_test/flutter_test.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/features/projects/data/datasources/project_local_datasource.dart';
import 'package:looma/features/projects/data/repositories/project_repository_impl.dart';
import 'package:looma/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';

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
    test('Initial getProjects returns default seeded sample projects', () async {
      final projects = await repository.getProjects();
      expect(projects.isNotEmpty, isTrue);
      expect(projects.any((p) => p.id == 'sample-tokyo-vlog'), isTrue);
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
      final duplicated = await repository.duplicateProject('sample-tokyo-vlog');
      expect(duplicated.id, isNot('sample-tokyo-vlog'));
      expect(duplicated.title, contains('(Copy)'));
      expect(duplicated.videoClips.length, 2);
    });

    test('Delete project removes it from catalog', () async {
      await repository.deleteProject('sample-tokyo-vlog');
      final deleted = await repository.getProjectById('sample-tokyo-vlog');
      expect(deleted, isNull);
    });
  });
}
