import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

class GetProjectsUseCase {
  final ProjectRepository repository;
  const GetProjectsUseCase(this.repository);

  Future<List<ProjectEntity>> call() => repository.getProjects();
}

class GetProjectByIdUseCase {
  final ProjectRepository repository;
  const GetProjectByIdUseCase(this.repository);

  Future<ProjectEntity?> call(String id) => repository.getProjectById(id);
}

class SaveProjectUseCase {
  final ProjectRepository repository;
  const SaveProjectUseCase(this.repository);

  Future<void> call(ProjectEntity project) => repository.saveProject(project);
}

class UpdateProjectUseCase {
  final ProjectRepository repository;
  const UpdateProjectUseCase(this.repository);

  Future<void> call(ProjectEntity project) => repository.updateProject(project);
}

class DuplicateProjectUseCase {
  final ProjectRepository repository;
  const DuplicateProjectUseCase(this.repository);

  Future<ProjectEntity> call(String id) => repository.duplicateProject(id);
}

class DeleteProjectUseCase {
  final ProjectRepository repository;
  const DeleteProjectUseCase(this.repository);

  Future<void> call(String id) => repository.deleteProject(id);
}

class ClaimGuestProjectsUseCase {
  final ProjectRepository repository;
  const ClaimGuestProjectsUseCase(this.repository);

  Future<void> call(String userId) => repository.claimGuestProjects(userId);
}
