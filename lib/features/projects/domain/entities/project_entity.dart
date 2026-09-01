import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/sticker_overlay_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/text_overlay_entity.dart';
import 'aspect_ratio_type.dart';
import 'sync_status_type.dart';

@immutable
class ProjectEntity {
  final String id;
  final String title;
  final AspectRatioType aspectRatio;
  final int fps;
  final int resolutionWidth;
  final int resolutionHeight;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final int durationMs;
  final List<VideoClipEntity> videoClips;
  final List<AudioClipEntity> audioClips;
  final List<TextOverlayEntity> textOverlays;
  final List<StickerOverlayEntity> stickerOverlays;
  final SyncStatusType syncStatus;

  const ProjectEntity({
    required this.id,
    required this.title,
    this.aspectRatio = AspectRatioType.ratio9_16,
    this.fps = 30,
    this.resolutionWidth = 1080,
    this.resolutionHeight = 1920,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.durationMs = 15000,
    this.videoClips = const [],
    this.audioClips = const [],
    this.textOverlays = const [],
    this.stickerOverlays = const [],
    this.syncStatus = SyncStatusType.localOnly,
  });

  /// Computes the true project duration from all tracks
  int get calculatedDurationMs {
    int maxEnd = 0;
    for (final clip in videoClips) {
      maxEnd = max(maxEnd, clip.timelineEndMs);
    }
    for (final audio in audioClips) {
      maxEnd = max(maxEnd, audio.timelineEndMs);
    }
    for (final text in textOverlays) {
      maxEnd = max(maxEnd, text.timelineEndMs);
    }
    for (final sticker in stickerOverlays) {
      maxEnd = max(maxEnd, sticker.timelineEndMs);
    }
    return max(maxEnd, durationMs > 0 ? durationMs : 5000);
  }

  ProjectEntity copyWith({
    String? id,
    String? title,
    AspectRatioType? aspectRatio,
    int? fps,
    int? resolutionWidth,
    int? resolutionHeight,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailPath,
    int? durationMs,
    List<VideoClipEntity>? videoClips,
    List<AudioClipEntity>? audioClips,
    List<TextOverlayEntity>? textOverlays,
    List<StickerOverlayEntity>? stickerOverlays,
    SyncStatusType? syncStatus,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      fps: fps ?? this.fps,
      resolutionWidth: resolutionWidth ?? this.resolutionWidth,
      resolutionHeight: resolutionHeight ?? this.resolutionHeight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      durationMs: durationMs ?? this.durationMs,
      videoClips: videoClips ?? this.videoClips,
      audioClips: audioClips ?? this.audioClips,
      textOverlays: textOverlays ?? this.textOverlays,
      stickerOverlays: stickerOverlays ?? this.stickerOverlays,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectEntity &&
          id == other.id &&
          title == other.title &&
          aspectRatio == other.aspectRatio &&
          fps == other.fps &&
          updatedAt == other.updatedAt &&
          syncStatus == other.syncStatus;

  @override
  int get hashCode => Object.hash(id, title, aspectRatio, fps, updatedAt, syncStatus);
}
