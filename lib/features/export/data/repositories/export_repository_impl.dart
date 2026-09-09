import 'package:procut/features/export/data/datasources/video_rendering_engine.dart';
import 'package:procut/features/export/domain/entities/export_config_entity.dart';
import 'package:procut/features/export/domain/entities/render_progress_entity.dart';
import 'package:procut/features/export/domain/repositories/export_repository.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

class ExportRepositoryImpl implements ExportRepository {
  final VideoRenderingEngine renderingEngine;

  ExportRepositoryImpl({required this.renderingEngine});

  @override
  Stream<RenderProgressEntity> renderProject({
    required ProjectEntity project,
    required ExportConfigEntity config,
  }) {
    return renderingEngine.executeRenderPipeline(
      project: project,
      config: config,
    );
  }
}
