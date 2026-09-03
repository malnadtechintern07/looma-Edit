import 'package:looma/core/utils/id_generator.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/animation_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/chroma_key_config_entity.dart';
import 'package:looma/features/editor/domain/entities/clip_animation_type.dart';
import 'package:looma/features/editor/domain/entities/crop_rect_entity.dart';
import 'package:looma/features/editor/domain/entities/keyframe_entity.dart';
import 'package:looma/features/editor/domain/entities/mask_config_entity.dart';
import 'package:looma/features/editor/domain/entities/speed_curve_type.dart';
import 'package:looma/features/editor/domain/entities/subtitle_entity.dart';
import 'package:looma/features/editor/domain/entities/transition_type.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/filters_effects/domain/entities/effect_clip_entity.dart';
import 'package:looma/features/filters_effects/domain/entities/filter_preset.dart';
import 'package:looma/features/filters_effects/domain/entities/video_effect_type.dart';
import 'package:looma/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/entities/sync_status_type.dart';
import 'package:looma/features/text_stickers/domain/entities/overlay_animation_type.dart';
import 'package:looma/features/text_stickers/domain/entities/sticker_overlay_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/text_overlay_entity.dart';

/// Data Model with serialization/deserialization for ProjectEntity
class ProjectModel {
  static Map<String, dynamic> toJson(ProjectEntity entity) {
    return {
      'id': entity.id,
      'title': entity.title,
      'aspectRatio': entity.aspectRatio.name,
      'fps': entity.fps,
      'resolutionWidth': entity.resolutionWidth,
      'resolutionHeight': entity.resolutionHeight,
      'createdAt': entity.createdAt.toIso8601String(),
      'updatedAt': entity.updatedAt.toIso8601String(),
      'thumbnailPath': entity.thumbnailPath,
      'durationMs': entity.durationMs,
      'syncStatus': entity.syncStatus.name,
      'lastPlayheadPositionMs': entity.lastPlayheadPositionMs,
      'videoClips': entity.videoClips.map((v) => _videoClipToJson(v)).toList(),
      'audioClips': entity.audioClips.map((a) => _audioClipToJson(a)).toList(),
      'textOverlays': entity.textOverlays.map((t) => _textOverlayToJson(t)).toList(),
      'stickerOverlays': entity.stickerOverlays.map((s) => _stickerOverlayToJson(s)).toList(),
      'subtitles': entity.subtitles.map((sub) => _subtitleToJson(sub)).toList(),
      'effectClips': entity.effectClips.map((e) => e.toJson()).toList(),
      'animationClips': entity.animationClips.map((a) => a.toJson()).toList(),
    };
  }

  static ProjectEntity fromJson(Map<String, dynamic> json) {
    return ProjectEntity(
      id: json['id'] as String? ?? IdGenerator.generate(),
      title: json['title'] as String? ?? 'Untitled Project',
      aspectRatio: AspectRatioType.fromString(json['aspectRatio'] as String?),
      fps: json['fps'] as int? ?? 30,
      resolutionWidth: json['resolutionWidth'] as int? ?? 1080,
      resolutionHeight: json['resolutionHeight'] as int? ?? 1920,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      thumbnailPath: json['thumbnailPath'] as String?,
      durationMs: json['durationMs'] as int? ?? 15000,
      syncStatus: SyncStatusType.fromString(json['syncStatus'] as String?),
      lastPlayheadPositionMs: (json['lastPlayheadPositionMs'] as num?)?.toInt() ?? 0,
      videoClips: (json['videoClips'] as List<dynamic>?)
              ?.map((v) => _videoClipFromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      audioClips: (json['audioClips'] as List<dynamic>?)
              ?.map((a) => _audioClipFromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      textOverlays: (json['textOverlays'] as List<dynamic>?)
              ?.map((t) => _textOverlayFromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      stickerOverlays: (json['stickerOverlays'] as List<dynamic>?)
              ?.map((s) => _stickerOverlayFromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      subtitles: (json['subtitles'] as List<dynamic>?)
              ?.map((sub) => _subtitleFromJson(sub as Map<String, dynamic>))
              .toList() ??
          [],
      effectClips: (json['effectClips'] as List<dynamic>?)
              ?.map((e) => EffectClipEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      animationClips: (json['animationClips'] as List<dynamic>?)
              ?.map((a) => AnimationClipEntity.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // --- Video Clip ---
  static Map<String, dynamic> _videoClipToJson(VideoClipEntity entity) {
    return {
      'id': entity.id,
      'mediaPath': entity.mediaPath,
      'name': entity.name,
      'sourceDurationMs': entity.sourceDurationMs,
      'timelineStartMs': entity.timelineStartMs,
      'timelineEndMs': entity.timelineEndMs,
      'trimStartMs': entity.trimStartMs,
      'trimEndMs': entity.trimEndMs,
      'speed': entity.speed,
      'volume': entity.volume,
      'isMuted': entity.isMuted,
      'filterType': entity.filterType.name,
      'effectType': entity.effectType.name,
      'effectIntensity': entity.effectIntensity,
      'brightness': entity.brightness,
      'contrast': entity.contrast,
      'saturation': entity.saturation,
      'transitionIn': entity.transitionIn.name,
      'transitionDurationMs': entity.transitionDurationMs,
      'rotationDegrees': entity.rotationDegrees,
      'isFlippedHorizontally': entity.isFlippedHorizontally,
      'isFlippedVertically': entity.isFlippedVertically,
      'opacity': entity.opacity,
      'zoomScale': entity.zoomScale,
      'positionX': entity.positionX,
      'positionY': entity.positionY,
      'blurSigma': entity.blurSigma,
      'fadeInDurationMs': entity.fadeInDurationMs,
      'fadeOutDurationMs': entity.fadeOutDurationMs,
      'animationIn': entity.animationIn.name,
      'animationInDurationMs': entity.animationInDurationMs,
      'animationOut': entity.animationOut.name,
      'animationOutDurationMs': entity.animationOutDurationMs,
      'animationCombo': entity.animationCombo.name,
      'speedCurve': entity.speedCurve.name,
      'isReversed': entity.isReversed,
      'isOverlay': entity.isOverlay,
      'crop': entity.crop != null ? _cropRectToJson(entity.crop!) : null,
      'mask': entity.mask != null ? _maskToJson(entity.mask!) : null,
      'chromaKey': entity.chromaKey != null ? _chromaKeyToJson(entity.chromaKey!) : null,
      'keyframes': entity.keyframes.map((k) => _keyframeToJson(k)).toList(),
    };
  }

  static VideoClipEntity _videoClipFromJson(Map<String, dynamic> json) {
    return VideoClipEntity(
      id: json['id'] as String? ?? IdGenerator.generate(),
      mediaPath: json['mediaPath'] as String? ?? '',
      name: json['name'] as String? ?? 'Clip',
      sourceDurationMs: json['sourceDurationMs'] as int? ?? 5000,
      timelineStartMs: json['timelineStartMs'] as int? ?? 0,
      timelineEndMs: json['timelineEndMs'] as int? ?? 5000,
      trimStartMs: json['trimStartMs'] as int? ?? 0,
      trimEndMs: json['trimEndMs'] as int? ?? 5000,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
      filterType: FilterType.fromString(json['filterType'] as String?),
      effectType: VideoEffectType.fromString(json['effectType'] as String?),
      effectIntensity: (json['effectIntensity'] as num?)?.toDouble() ?? 1.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
      transitionIn: TransitionType.fromString(json['transitionIn'] as String?),
      transitionDurationMs: json['transitionDurationMs'] as int? ?? 500,
      rotationDegrees: (json['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
      isFlippedHorizontally: json['isFlippedHorizontally'] as bool? ?? false,
      isFlippedVertically: json['isFlippedVertically'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      zoomScale: (json['zoomScale'] as num?)?.toDouble() ?? 1.0,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.0,
      blurSigma: (json['blurSigma'] as num?)?.toDouble() ?? 0.0,
      fadeInDurationMs: json['fadeInDurationMs'] as int? ?? 0,
      fadeOutDurationMs: json['fadeOutDurationMs'] as int? ?? 0,
      animationIn: ClipAnimationIn.values.firstWhere(
        (a) => a.name == json['animationIn'],
        orElse: () => ClipAnimationIn.none,
      ),
      animationInDurationMs: json['animationInDurationMs'] as int? ?? 500,
      animationOut: ClipAnimationOut.values.firstWhere(
        (a) => a.name == json['animationOut'],
        orElse: () => ClipAnimationOut.none,
      ),
      animationOutDurationMs: json['animationOutDurationMs'] as int? ?? 500,
      animationCombo: ClipAnimationCombo.values.firstWhere(
        (a) => a.name == json['animationCombo'],
        orElse: () => ClipAnimationCombo.none,
      ),
      speedCurve: SpeedCurveType.values.firstWhere(
        (s) => s.name == json['speedCurve'],
        orElse: () => SpeedCurveType.none,
      ),
      isReversed: json['isReversed'] as bool? ?? false,
      isOverlay: json['isOverlay'] as bool? ?? false,
      crop: json['crop'] != null ? _cropRectFromJson(json['crop'] as Map<String, dynamic>) : null,
      mask: json['mask'] != null ? _maskFromJson(json['mask'] as Map<String, dynamic>) : null,
      chromaKey: json['chromaKey'] != null ? _chromaKeyFromJson(json['chromaKey'] as Map<String, dynamic>) : null,
      keyframes: (json['keyframes'] as List<dynamic>?)
              ?.map((k) => _keyframeFromJson(k as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  // --- Keyframe ---
  static Map<String, dynamic> _keyframeToJson(KeyframeEntity entity) {
    return {
      'id': entity.id,
      'timestampMs': entity.timestampMs,
      'posX': entity.posX,
      'posY': entity.posY,
      'scale': entity.scale,
      'rotation': entity.rotation,
      'opacity': entity.opacity,
    };
  }

  static KeyframeEntity _keyframeFromJson(Map<String, dynamic> json) {
    return KeyframeEntity(
      id: json['id'] as String? ?? IdGenerator.generate(),
      timestampMs: (json['timestampMs'] as num?)?.toInt() ?? 0,
      posX: (json['posX'] as num?)?.toDouble(),
      posY: (json['posY'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble(),
    );
  }

  // --- Crop Rect ---
  static Map<String, dynamic> _cropRectToJson(CropRectEntity entity) {
    return {
      'left': entity.left,
      'top': entity.top,
      'right': entity.right,
      'bottom': entity.bottom,
      'ratioName': entity.ratioName,
    };
  }

  static CropRectEntity _cropRectFromJson(Map<String, dynamic> json) {
    return CropRectEntity(
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      top: (json['top'] as num?)?.toDouble() ?? 0.0,
      right: (json['right'] as num?)?.toDouble() ?? 1.0,
      bottom: (json['bottom'] as num?)?.toDouble() ?? 1.0,
      ratioName: json['ratioName'] as String? ?? 'Free',
    );
  }

  // --- Mask Config ---
  static Map<String, dynamic> _maskToJson(MaskConfigEntity entity) {
    return {
      'shape': entity.shape.name,
      'centerX': entity.centerX,
      'centerY': entity.centerY,
      'widthFactor': entity.widthFactor,
      'heightFactor': entity.heightFactor,
      'rotationDegrees': entity.rotationDegrees,
      'feather': entity.feather,
      'isInverted': entity.isInverted,
    };
  }

  static MaskConfigEntity _maskFromJson(Map<String, dynamic> json) {
    return MaskConfigEntity(
      shape: MaskShape.values.firstWhere((s) => s.name == json['shape'], orElse: () => MaskShape.none),
      centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
      centerY: (json['centerY'] as num?)?.toDouble() ?? 0.5,
      widthFactor: (json['widthFactor'] as num?)?.toDouble() ?? 0.8,
      heightFactor: (json['heightFactor'] as num?)?.toDouble() ?? 0.8,
      rotationDegrees: (json['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.0,
      isInverted: json['isInverted'] as bool? ?? false,
    );
  }

  // --- Chroma Key Config ---
  static Map<String, dynamic> _chromaKeyToJson(ChromaKeyConfigEntity entity) {
    return {
      'isEnabled': entity.isEnabled,
      'keyColorHex': entity.keyColorHex,
      'intensity': entity.intensity,
      'shadow': entity.shadow,
      'edgeSmoothing': entity.edgeSmoothing,
    };
  }

  static ChromaKeyConfigEntity _chromaKeyFromJson(Map<String, dynamic> json) {
    return ChromaKeyConfigEntity(
      isEnabled: json['isEnabled'] as bool? ?? false,
      keyColorHex: json['keyColorHex'] as int? ?? 0xFF00FF00,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.45,
      shadow: (json['shadow'] as num?)?.toDouble() ?? 0.2,
      edgeSmoothing: (json['edgeSmoothing'] as num?)?.toDouble() ?? 0.1,
    );
  }

  // --- Audio Clip ---
  static Map<String, dynamic> _audioClipToJson(AudioClipEntity entity) {
    return {
      'id': entity.id,
      'mediaPath': entity.mediaPath,
      'title': entity.title,
      'category': entity.category.name,
      'timelineStartMs': entity.timelineStartMs,
      'timelineEndMs': entity.timelineEndMs,
      'trimStartMs': entity.trimStartMs,
      'trimEndMs': entity.trimEndMs,
      'volume': entity.volume,
      'isMuted': entity.isMuted,
      'fadeInMs': entity.fadeInMs,
      'fadeOutMs': entity.fadeOutMs,
      'waveformSamples': entity.waveformSamples,
    };
  }

  static AudioClipEntity _audioClipFromJson(Map<String, dynamic> json) {
    return AudioClipEntity(
      id: json['id'] as String? ?? IdGenerator.generate(),
      mediaPath: json['mediaPath'] as String? ?? '',
      title: json['title'] as String? ?? 'Audio',
      category: AudioCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AudioCategory.music,
      ),
      timelineStartMs: json['timelineStartMs'] as int? ?? 0,
      timelineEndMs: json['timelineEndMs'] as int? ?? 5000,
      trimStartMs: json['trimStartMs'] as int? ?? 0,
      trimEndMs: json['trimEndMs'] as int? ?? 5000,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
      fadeInMs: json['fadeInMs'] as int? ?? 0,
      fadeOutMs: json['fadeOutMs'] as int? ?? 0,
      waveformSamples: (json['waveformSamples'] as List<dynamic>?)
              ?.map((s) => (s as num).toDouble())
              .toList() ??
          [],
    );
  }

  // --- Text Overlay ---
  static Map<String, dynamic> _textOverlayToJson(TextOverlayEntity entity) {
    return {
      'id': entity.id,
      'text': entity.text,
      'fontFamily': entity.fontFamily,
      'fontSize': entity.fontSize,
      'colorHex': entity.colorHex,
      'backgroundColorHex': entity.backgroundColorHex,
      'outlineColorHex': entity.outlineColorHex,
      'outlineWidth': entity.outlineWidth,
      'posX': entity.posX,
      'posY': entity.posY,
      'scale': entity.scale,
      'rotation': entity.rotation,
      'timelineStartMs': entity.timelineStartMs,
      'timelineEndMs': entity.timelineEndMs,
      'animationType': entity.animationType.name,
    };
  }

  static TextOverlayEntity _textOverlayFromJson(Map<String, dynamic> json) {
    return TextOverlayEntity(
      id: json['id'] as String? ?? IdGenerator.generate(),
      text: json['text'] as String? ?? '',
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      colorHex: json['colorHex'] as int? ?? 0xFFFFFFFF,
      backgroundColorHex: json['backgroundColorHex'] as int?,
      outlineColorHex: json['outlineColorHex'] as int?,
      outlineWidth: (json['outlineWidth'] as num?)?.toDouble() ?? 0.0,
      posX: (json['posX'] as num?)?.toDouble() ?? 0.5,
      posY: (json['posY'] as num?)?.toDouble() ?? 0.5,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      timelineStartMs: json['timelineStartMs'] as int? ?? 0,
      timelineEndMs: json['timelineEndMs'] as int? ?? 5000,
      animationType: OverlayAnimationType.fromString(json['animationType'] as String?),
    );
  }

  // --- Sticker Overlay ---
  static Map<String, dynamic> _stickerOverlayToJson(StickerOverlayEntity entity) {
    return {
      'id': entity.id,
      'stickerKey': entity.stickerKey,
      'stickerName': entity.stickerName,
      'assetEmojiOrPath': entity.assetEmojiOrPath,
      'posX': entity.posX,
      'posY': entity.posY,
      'scale': entity.scale,
      'rotation': entity.rotation,
      'timelineStartMs': entity.timelineStartMs,
      'timelineEndMs': entity.timelineEndMs,
    };
  }

  static StickerOverlayEntity _stickerOverlayFromJson(Map<String, dynamic> json) {
    return StickerOverlayEntity(
      id: json['id'] as String? ?? IdGenerator.generate(),
      stickerKey: json['stickerKey'] as String? ?? '',
      stickerName: json['stickerName'] as String? ?? 'Sticker',
      assetEmojiOrPath: json['assetEmojiOrPath'] as String? ?? '✨',
      posX: (json['posX'] as num?)?.toDouble() ?? 0.5,
      posY: (json['posY'] as num?)?.toDouble() ?? 0.5,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      timelineStartMs: json['timelineStartMs'] as int? ?? 0,
      timelineEndMs: json['timelineEndMs'] as int? ?? 5000,
    );
  }

  // --- Subtitles ---
  static Map<String, dynamic> _subtitleToJson(SubtitleEntity entity) {
    return {
      'id': entity.id,
      'text': entity.text,
      'timelineStartMs': entity.timelineStartMs,
      'timelineEndMs': entity.timelineEndMs,
      'fontFamily': entity.fontFamily,
      'fontSize': entity.fontSize,
      'colorHex': entity.colorHex,
      'backgroundColorHex': entity.backgroundColorHex,
      'posY': entity.posY,
    };
  }

  static SubtitleEntity _subtitleFromJson(Map<String, dynamic> json) {
    return SubtitleEntity(
      id: json['id'] as String? ?? IdGenerator.generate(),
      text: json['text'] as String? ?? '',
      timelineStartMs: json['timelineStartMs'] as int? ?? 0,
      timelineEndMs: json['timelineEndMs'] as int? ?? 3000,
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 20.0,
      colorHex: json['colorHex'] as int? ?? 0xFFFFFFFF,
      backgroundColorHex: json['backgroundColorHex'] as int? ?? 0x88000000,
      posY: (json['posY'] as num?)?.toDouble() ?? 0.85,
    );
  }
}
