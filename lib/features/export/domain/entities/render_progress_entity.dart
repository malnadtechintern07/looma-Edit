enum RenderStatus { idle, rendering, completed, failed }

class RenderProgressEntity {
  final RenderStatus status;
  final double progress; // 0.0 to 1.0
  final int currentFrame;
  final int totalFrames;
  final String stageDescription;
  final String? outputPath;
  final String? errorMessage;

  const RenderProgressEntity({
    this.status = RenderStatus.idle,
    this.progress = 0.0,
    this.currentFrame = 0,
    this.totalFrames = 0,
    this.stageDescription = 'Ready to export',
    this.outputPath,
    this.errorMessage,
  });

  RenderProgressEntity copyWith({
    RenderStatus? status,
    double? progress,
    int? currentFrame,
    int? totalFrames,
    String? stageDescription,
    String? outputPath,
    String? errorMessage,
  }) {
    return RenderProgressEntity(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentFrame: currentFrame ?? this.currentFrame,
      totalFrames: totalFrames ?? this.totalFrames,
      stageDescription: stageDescription ?? this.stageDescription,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
