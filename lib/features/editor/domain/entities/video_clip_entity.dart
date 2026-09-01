import 'package:flutter/foundation.dart';
import 'package:looma/features/editor/domain/entities/transition_type.dart';
import 'package:looma/features/filters_effects/domain/entities/filter_preset.dart';

@immutable
class VideoClipEntity {
  final String id;
  final String mediaPath;
  final String name;
  final int sourceDurationMs;
  final int timelineStartMs;
  final int timelineEndMs;
  final int trimStartMs;
  final int trimEndMs;
  final double speed;
  final double volume;
  final FilterType filterType;
  final double brightness; // -1.0 to 1.0
  final double contrast; // 0.5 to 2.0
  final double saturation; // 0.0 to 2.0
  final TransitionType transitionIn;
  final int transitionDurationMs;
  final double rotationDegrees;
  final bool isFlippedHorizontally;

  // Real Visual Effects & Manual Canvas Transformations
  final double blurSigma; // 0.0 to 10.0
  final double zoomScale; // 0.5 to 5.0
  final double positionX; // Offset X in pixels
  final double positionY; // Offset Y in pixels
  final int fadeInDurationMs; // 0 to 2000
  final int fadeOutDurationMs; // 0 to 2000

  const VideoClipEntity({
    required this.id,
    required this.mediaPath,
    required this.name,
    required this.sourceDurationMs,
    required this.timelineStartMs,
    required this.timelineEndMs,
    this.trimStartMs = 0,
    required this.trimEndMs,
    this.speed = 1.0,
    this.volume = 1.0,
    this.filterType = FilterType.none,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.transitionIn = TransitionType.none,
    this.transitionDurationMs = 500,
    this.rotationDegrees = 0.0,
    this.isFlippedHorizontally = false,
    this.blurSigma = 0.0,
    this.zoomScale = 1.0,
    this.positionX = 0.0,
    this.positionY = 0.0,
    this.fadeInDurationMs = 0,
    this.fadeOutDurationMs = 0,
  });

  /// Duration on the timeline in milliseconds taking speed into account
  int get effectiveDurationMs => timelineEndMs - timelineStartMs;

  /// Trimmed duration in raw source milliseconds
  int get trimmedSourceDurationMs => trimEndMs - trimStartMs;

  VideoClipEntity copyWith({
    String? id,
    String? mediaPath,
    String? name,
    int? sourceDurationMs,
    int? timelineStartMs,
    int? timelineEndMs,
    int? trimStartMs,
    int? trimEndMs,
    double? speed,
    double? volume,
    FilterType? filterType,
    double? brightness,
    double? contrast,
    double? saturation,
    TransitionType? transitionIn,
    int? transitionDurationMs,
    double? rotationDegrees,
    bool? isFlippedHorizontally,
    double? blurSigma,
    double? zoomScale,
    double? positionX,
    double? positionY,
    int? fadeInDurationMs,
    int? fadeOutDurationMs,
  }) {
    return VideoClipEntity(
      id: id ?? this.id,
      mediaPath: mediaPath ?? this.mediaPath,
      name: name ?? this.name,
      sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
      timelineStartMs: timelineStartMs ?? this.timelineStartMs,
      timelineEndMs: timelineEndMs ?? this.timelineEndMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      filterType: filterType ?? this.filterType,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      transitionIn: transitionIn ?? this.transitionIn,
      transitionDurationMs: transitionDurationMs ?? this.transitionDurationMs,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      isFlippedHorizontally: isFlippedHorizontally ?? this.isFlippedHorizontally,
      blurSigma: blurSigma ?? this.blurSigma,
      zoomScale: zoomScale ?? this.zoomScale,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      fadeInDurationMs: fadeInDurationMs ?? this.fadeInDurationMs,
      fadeOutDurationMs: fadeOutDurationMs ?? this.fadeOutDurationMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoClipEntity &&
          id == other.id &&
          timelineStartMs == other.timelineStartMs &&
          timelineEndMs == other.timelineEndMs &&
          trimStartMs == other.trimStartMs &&
          trimEndMs == other.trimEndMs &&
          speed == other.speed &&
          volume == other.volume &&
          filterType == other.filterType &&
          brightness == other.brightness &&
          contrast == other.contrast &&
          saturation == other.saturation &&
          transitionIn == other.transitionIn &&
          blurSigma == other.blurSigma &&
          zoomScale == other.zoomScale &&
          positionX == other.positionX &&
          positionY == other.positionY &&
          fadeInDurationMs == other.fadeInDurationMs &&
          fadeOutDurationMs == other.fadeOutDurationMs;

  @override
  int get hashCode => Object.hash(
        id,
        timelineStartMs,
        timelineEndMs,
        trimStartMs,
        trimEndMs,
        speed,
        volume,
        filterType,
        blurSigma,
        zoomScale,
        positionX,
        positionY,
      );
}
