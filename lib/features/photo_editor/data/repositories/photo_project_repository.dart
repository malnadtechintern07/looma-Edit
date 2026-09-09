import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procut/features/auth/domain/repositories/auth_repository.dart';
import 'package:procut/features/auth/presentation/providers/auth_provider.dart';
import 'package:procut/features/cloud_sync/data/datasources/global_cloud_storage_datasource.dart';
import 'package:procut/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../datasources/photo_local_datasource.dart';

final photoLocalDataSourceProvider = Provider<PhotoLocalDataSource>((ref) {
  return PhotoLocalDataSource();
});

final photoProjectRepositoryProvider = Provider<PhotoProjectRepository>((ref) {
  final localDs = ref.watch(photoLocalDataSourceProvider);
  final globalDs = ref.watch(globalCloudStorageDataSourceProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return PhotoProjectRepository(
    localDs,
    cloudDataSource: globalDs,
    authRepository: authRepo,
  );
});

class PhotoProjectRepository {
  final PhotoLocalDataSource _dataSource;
  final GlobalCloudStorageDataSource? cloudDataSource;
  final AuthRepository? authRepository;

  PhotoProjectRepository(
    this._dataSource, {
    this.cloudDataSource,
    this.authRepository,
  });

  Future<List<PhotoProjectEntity>> getPhotoProjects() async {
    try {
      final user = await authRepository?.getCurrentUser();
      final cloud = cloudDataSource;
      if (user != null && cloud != null) {
        final cloudList = await cloud.getCloudPhotoProjects(user.id);
        for (final item in cloudList) {
          try {
            final p = PhotoProjectEntity.fromJson(item);
            await _dataSource.savePhotoProject(p);
          } catch (_) {}
        }
      }
    } catch (_) {}

    return _dataSource.getPhotoProjects();
  }

  Future<void> savePhotoProject(PhotoProjectEntity project) async {
    await _dataSource.savePhotoProject(project);

    try {
      final user = await authRepository?.getCurrentUser();
      final cloud = cloudDataSource;
      if (user != null && cloud != null) {
        await cloud.backupPhotoProject(user.id, project.toJson());
      }
    } catch (_) {}
  }

  Future<void> deletePhotoProject(String id) async {
    await _dataSource.deletePhotoProject(id);

    try {
      final user = await authRepository?.getCurrentUser();
      final cloud = cloudDataSource;
      if (user != null && cloud != null) {
        await cloud.deleteCloudPhotoProject(user.id, id);
      }
    } catch (_) {}
  }
}
