import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../datasources/photo_local_datasource.dart';

final photoLocalDataSourceProvider = Provider<PhotoLocalDataSource>((ref) {
  return PhotoLocalDataSource();
});

final photoProjectRepositoryProvider = Provider<PhotoProjectRepository>((ref) {
  return PhotoProjectRepository(ref.watch(photoLocalDataSourceProvider));
});

class PhotoProjectRepository {
  final PhotoLocalDataSource _dataSource;

  PhotoProjectRepository(this._dataSource);

  Future<List<PhotoProjectEntity>> getPhotoProjects() {
    return _dataSource.getPhotoProjects();
  }

  Future<void> savePhotoProject(PhotoProjectEntity project) {
    return _dataSource.savePhotoProject(project);
  }

  Future<void> deletePhotoProject(String id) {
    return _dataSource.deletePhotoProject(id);
  }
}
