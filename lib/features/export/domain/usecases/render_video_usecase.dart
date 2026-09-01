import 'package:looma/features/export/domain/entities/export_config_entity.dart';
import 'package:looma/features/export/domain/entities/render_progress_entity.dart';
import 'package:looma/features/export/domain/repositories/export_repository.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';

class RenderVideoUseCase {
  final ExportRepository repository;
  const RenderVideoUseCase(this.repository);

  Stream<RenderProgressEntity> call({
    required ProjectEntity project,
    required ExportConfigEntity config,
  }) {
    return repository.renderProject(project: project, config: config);
  }
}
