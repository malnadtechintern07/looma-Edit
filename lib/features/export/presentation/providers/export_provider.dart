import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procut/features/export/data/datasources/video_rendering_engine.dart';
import 'package:procut/features/export/data/repositories/export_repository_impl.dart';
import 'package:procut/features/export/domain/entities/export_config_entity.dart';
import 'package:procut/features/export/domain/entities/render_progress_entity.dart';
import 'package:procut/features/export/domain/repositories/export_repository.dart';
import 'package:procut/features/export/domain/usecases/render_video_usecase.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

final videoRenderingEngineProvider = Provider<VideoRenderingEngine>((ref) {
  return VideoRenderingEngineImpl();
});

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  final engine = ref.watch(videoRenderingEngineProvider);
  return ExportRepositoryImpl(renderingEngine: engine);
});

final renderVideoUseCaseProvider = Provider<RenderVideoUseCase>((ref) {
  return RenderVideoUseCase(ref.watch(exportRepositoryProvider));
});

class ExportController extends StateNotifier<RenderProgressEntity> {
  final RenderVideoUseCase _renderUseCase;
  StreamSubscription<RenderProgressEntity>? _sub;

  ExportController(this._renderUseCase) : super(const RenderProgressEntity());

  void startExport({
    required ProjectEntity project,
    required ExportConfigEntity config,
  }) {
    _sub?.cancel();
    state = const RenderProgressEntity(status: RenderStatus.rendering, progress: 0.01);

    _sub = _renderUseCase(project: project, config: config).listen(
      (progress) {
        state = progress;
      },
      onError: (err) {
        state = state.copyWith(
          status: RenderStatus.failed,
          errorMessage: err.toString(),
        );
      },
    );
  }

  void reset() {
    _sub?.cancel();
    state = const RenderProgressEntity();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final exportControllerProvider =
    StateNotifierProvider.autoDispose<ExportController, RenderProgressEntity>((ref) {
  return ExportController(ref.watch(renderVideoUseCaseProvider));
});
