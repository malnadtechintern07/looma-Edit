import 'package:flutter/foundation.dart';
import '../../../projects/domain/entities/aspect_ratio_type.dart';

enum ExportResolution {
  res480p('480p SD', 854, 480),
  res720p('720p HD', 1280, 720),
  res1080p('1080p FHD', 1920, 1080),
  res4k('4K UHD', 3840, 2160);

  final String label;
  final int width;
  final int height;

  const ExportResolution(this.label, this.width, this.height);
}

enum ExportQuality {
  normal('Standard (Recommended)', 8000),
  high('High Bitrate', 15000),
  master('Pro Master (ProRes)', 35000);

  final String label;
  final int bitrateKbps;

  const ExportQuality(this.label, this.bitrateKbps);
}

@immutable
class ExportConfigEntity {
  final String projectId;
  final ExportResolution resolution;
  final int fps;
  final AspectRatioType aspectRatio;
  final ExportQuality quality;

  const ExportConfigEntity({
    required this.projectId,
    this.resolution = ExportResolution.res1080p,
    this.fps = 30,
    this.aspectRatio = AspectRatioType.ratio9_16,
    this.quality = ExportQuality.normal,
  });

  /// Approximate output file size in megabytes
  double getEstimatedSizeMb(int durationMs) {
    final seconds = durationMs / 1000.0;
    final totalKilobits = seconds * quality.bitrateKbps;
    return (totalKilobits / 8192); // bits to megabytes
  }

  ExportConfigEntity copyWith({
    String? projectId,
    ExportResolution? resolution,
    int? fps,
    AspectRatioType? aspectRatio,
    ExportQuality? quality,
  }) {
    return ExportConfigEntity(
      projectId: projectId ?? this.projectId,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      quality: quality ?? this.quality,
    );
  }
}
