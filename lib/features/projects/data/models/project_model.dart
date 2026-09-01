import 'package:looma/core/utils/id_generator.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/transition_type.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/filters_effects/domain/entities/filter_preset.dart';
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
      'videoClips': entity.videoClips.map((v) => _videoClipToJson(v)).toList(),
      'audioClips': entity.audioClips.map((a) => _audioClipToJson(a)).toList(),
      'textOverlays': entity.textOverlays.map((t) => _textOverlayToJson(t)).toList(),
      'stickerOverlays': entity.stickerOverlays.map((s) => _stickerOverlayToJson(s)).toList(),
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
      'filterType': entity.filterType.name,
      'brightness': entity.brightness,
      'contrast': entity.contrast,
      'saturation': entity.saturation,
      'transitionIn': entity.transitionIn.name,
      'transitionDurationMs': entity.transitionDurationMs,
      'rotationDegrees': entity.rotationDegrees,
      'isFlippedHorizontally': entity.isFlippedHorizontally,
      'zoomScale': entity.zoomScale,
      'positionX': entity.positionX,
      'positionY': entity.positionY,
      'blurSigma': entity.blurSigma,
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
      filterType: FilterType.fromString(json['filterType'] as String?),
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
      transitionIn: TransitionType.fromString(json['transitionIn'] as String?),
      transitionDurationMs: json['transitionDurationMs'] as int? ?? 500,
      rotationDegrees: (json['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
      isFlippedHorizontally: json['isFlippedHorizontally'] as bool? ?? false,
      zoomScale: (json['zoomScale'] as num?)?.toDouble() ?? 1.0,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.0,
      blurSigma: (json['blurSigma'] as num?)?.toDouble() ?? 0.0,
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
}
