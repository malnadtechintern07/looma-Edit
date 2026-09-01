import '../entities/project_entity.dart';

/// Domain repository contract for LOOMA project persistence
abstract class ProjectRepository {
  /// Fetch all locally saved projects, ordered by last modified
  Future<List<ProjectEntity>> getProjects();

  /// Retrieve a specific project by unique ID
  Future<ProjectEntity?> getProjectById(String id);

  /// Create and persist a new project
  Future<void> saveProject(ProjectEntity project);

  /// Update an existing project's timeline and metadata
  Future<void> updateProject(ProjectEntity project);

  /// Duplicate a project with a new ID and title suffix
  Future<ProjectEntity> duplicateProject(String id);

  /// Permanently delete a project from local storage
  Future<void> deleteProject(String id);
}
