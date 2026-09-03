import 'package:flutter/foundation.dart';
import 'package:looma/features/editor/domain/entities/clip_animation_type.dart';
import 'package:looma/features/editor/domain/entities/crop_rect_entity.dart';
import 'package:looma/features/editor/domain/entities/keyframe_entity.dart';
import 'package:looma/features/editor/domain/entities/mask_config_entity.dart';
import 'package:looma/features/editor/domain/entities/chroma_key_config_entity.dart';
import 'package:looma/features/editor/domain/entities/speed_curve_type.dart';
import 'package:looma/features/editor/domain/entities/transition_type.dart';
import 'package:looma/features/filters_effects/domain/entities/filter_preset.dart';
import 'package:looma/features/filters_effects/domain/entities/video_effect_type.dart';

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
  final double volume; // 0.0 to 2.0 (default 1.0 = unchanged original audio)
  final bool isMuted; // User-controlled mute state
  final FilterType filterType;
  final double brightness; // -1.0 to 1.0
  final double contrast; // 0.5 to 2.0
  final double saturation; // 0.0 to 2.0
  final TransitionType transitionIn;
  final int transitionDurationMs;
  final double rotationDegrees;
  final bool isFlippedHorizontally;
  final bool isFlippedVertically;
  final double opacity; // 0.0 to 1.0

  // Real Visual Effects & Manual Canvas Transformations
  final VideoEffectType effectType;
  final double effectIntensity; // 0.0 to 1.0
  final double blurSigma; // 0.0 to 10.0
  final double zoomScale; // 0.2 to 5.0
  final double positionX; // Offset X in pixels
  final double positionY; // Offset Y in pixels
  final int fadeInDurationMs; // 0 to 2000
  final int fadeOutDurationMs; // 0 to 2000

  // Keyframes, In/Out/Combo Animations, Framing, Mask, ChromaKey, Speed Curves
  final List<KeyframeEntity> keyframes;
  final ClipAnimationIn animationIn;
  final int animationInDurationMs;
  final ClipAnimationOut animationOut;
  final int animationOutDurationMs;
  final ClipAnimationCombo animationCombo;
  final CropRectEntity? crop;
  final MaskConfigEntity? mask;
  final ChromaKeyConfigEntity? chromaKey;
  final SpeedCurveType speedCurve;
  final bool isReversed;
  final bool isOverlay; // Picture-in-picture / second video track

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
    this.isMuted = false,
    this.filterType = FilterType.none,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.transitionIn = TransitionType.none,
    this.transitionDurationMs = 500,
    this.rotationDegrees = 0.0,
    this.isFlippedHorizontally = false,
    this.isFlippedVertically = false,
    this.opacity = 1.0,
    this.effectType = VideoEffectType.none,
    this.effectIntensity = 1.0,
    this.blurSigma = 0.0,
    this.zoomScale = 1.0,
    this.positionX = 0.0,
    this.positionY = 0.0,
    this.fadeInDurationMs = 0,
    this.fadeOutDurationMs = 0,
    this.keyframes = const [],
    this.animationIn = ClipAnimationIn.none,
    this.animationInDurationMs = 500,
    this.animationOut = ClipAnimationOut.none,
    this.animationOutDurationMs = 500,
    this.animationCombo = ClipAnimationCombo.none,
    this.crop,
    this.mask,
    this.chromaKey,
    this.speedCurve = SpeedCurveType.none,
    this.isReversed = false,
    this.isOverlay = false,
  });

  /// Duration on the timeline in milliseconds taking speed into account
  int get effectiveDurationMs => timelineEndMs - timelineStartMs;

  /// Trimmed duration in raw source milliseconds
  int get trimmedSourceDurationMs => trimEndMs - trimStartMs;

  /// Effective audio volume (0.0 if muted, otherwise volume level)
  double get effectiveVolume => isMuted ? 0.0 : volume;

  /// Whether this clip represents a photo / still image
  bool get isPhoto {
    final lower = mediaPath.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  /// Whether this clip represents a video
  bool get isVideo => !isPhoto;

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
    bool? isMuted,
    FilterType? filterType,
    double? brightness,
    double? contrast,
    double? saturation,
    TransitionType? transitionIn,
    int? transitionDurationMs,
    double? rotationDegrees,
    bool? isFlippedHorizontally,
    bool? isFlippedVertically,
    double? opacity,
    VideoEffectType? effectType,
    double? effectIntensity,
    double? blurSigma,
    double? zoomScale,
    double? positionX,
    double? positionY,
    int? fadeInDurationMs,
    int? fadeOutDurationMs,
    List<KeyframeEntity>? keyframes,
    ClipAnimationIn? animationIn,
    int? animationInDurationMs,
    ClipAnimationOut? animationOut,
    int? animationOutDurationMs,
    ClipAnimationCombo? animationCombo,
    CropRectEntity? crop,
    MaskConfigEntity? mask,
    ChromaKeyConfigEntity? chromaKey,
    SpeedCurveType? speedCurve,
    bool? isReversed,
    bool? isOverlay,
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
      isMuted: isMuted ?? this.isMuted,
      filterType: filterType ?? this.filterType,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      transitionIn: transitionIn ?? this.transitionIn,
      transitionDurationMs: transitionDurationMs ?? this.transitionDurationMs,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      isFlippedHorizontally: isFlippedHorizontally ?? this.isFlippedHorizontally,
      isFlippedVertically: isFlippedVertically ?? this.isFlippedVertically,
      opacity: opacity ?? this.opacity,
      effectType: effectType ?? this.effectType,
      effectIntensity: effectIntensity ?? this.effectIntensity,
      blurSigma: blurSigma ?? this.blurSigma,
      zoomScale: zoomScale ?? this.zoomScale,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      fadeInDurationMs: fadeInDurationMs ?? this.fadeInDurationMs,
      fadeOutDurationMs: fadeOutDurationMs ?? this.fadeOutDurationMs,
      keyframes: keyframes ?? this.keyframes,
      animationIn: animationIn ?? this.animationIn,
      animationInDurationMs: animationInDurationMs ?? this.animationInDurationMs,
      animationOut: animationOut ?? this.animationOut,
      animationOutDurationMs: animationOutDurationMs ?? this.animationOutDurationMs,
      animationCombo: animationCombo ?? this.animationCombo,
      crop: crop ?? this.crop,
      mask: mask ?? this.mask,
      chromaKey: chromaKey ?? this.chromaKey,
      speedCurve: speedCurve ?? this.speedCurve,
      isReversed: isReversed ?? this.isReversed,
      isOverlay: isOverlay ?? this.isOverlay,
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
          effectType == other.effectType &&
          effectIntensity == other.effectIntensity &&
          blurSigma == other.blurSigma &&
          zoomScale == other.zoomScale &&
          positionX == other.positionX &&
          positionY == other.positionY &&
          fadeInDurationMs == other.fadeInDurationMs &&
          fadeOutDurationMs == other.fadeOutDurationMs &&
          isFlippedHorizontally == other.isFlippedHorizontally &&
          isFlippedVertically == other.isFlippedVertically &&
          opacity == other.opacity &&
          animationIn == other.animationIn &&
          animationOut == other.animationOut &&
          animationCombo == other.animationCombo &&
          speedCurve == other.speedCurve &&
          isReversed == other.isReversed &&
          isOverlay == other.isOverlay;

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
        effectType,
        effectIntensity,
        blurSigma,
        zoomScale,
        positionX,
        positionY,
        opacity,
        isOverlay,
      );
}

