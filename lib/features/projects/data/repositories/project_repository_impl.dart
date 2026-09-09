import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/repositories/project_repository.dart';
import 'package:procut/features/projects/data/datasources/project_local_datasource.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectLocalDataSource localDataSource;

  ProjectRepositoryImpl({required this.localDataSource});

  @override
  Future<List<ProjectEntity>> getProjects() async {
    return await localDataSource.getProjects();
  }

  @override
  Future<ProjectEntity?> getProjectById(String id) async {
    return await localDataSource.getProjectById(id);
  }

  @override
  Future<void> saveProject(ProjectEntity project) async {
    await localDataSource.saveProject(project);
  }

  @override
  Future<void> updateProject(ProjectEntity project) async {
    await localDataSource.updateProject(project);
  }

  @override
  Future<ProjectEntity> duplicateProject(String id) async {
    return await localDataSource.duplicateProject(id);
  }

  @override
  Future<void> deleteProject(String id) async {
    await localDataSource.deleteProject(id);
  }

  @override
  Future<void> claimGuestProjects(String userId) async {
    await localDataSource.claimGuestProjects(userId);
  }
}
