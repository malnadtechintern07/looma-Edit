import 'package:procut/features/export/domain/entities/export_config_entity.dart';
import 'package:procut/features/export/domain/entities/render_progress_entity.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

abstract class ExportRepository {
  Stream<RenderProgressEntity> renderProject({
    required ProjectEntity project,
    required ExportConfigEntity config,
  });
}
