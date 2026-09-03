import 'package:flutter/foundation.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/subtitle_entity.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/filters_effects/domain/entities/effect_clip_entity.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/sticker_overlay_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/text_overlay_entity.dart';

enum SelectionType { none, videoClip, overlayClip, audioClip, textOverlay, stickerOverlay, subtitle, effectClip }

@immutable
class TimelineState {
  final ProjectEntity project;
  final int playheadPositionMs;
  final bool isPlaying;
  final double pixelsPerSecond;
  final SelectionType selectionType;
  final String? selectedItemId;
  final bool isLooping;

  const TimelineState({
    required this.project,
    this.playheadPositionMs = 0,
    this.isPlaying = false,
    this.pixelsPerSecond = 60.0,
    this.selectionType = SelectionType.none,
    this.selectedItemId,
    this.isLooping = false,
  });

  /// Currently active video clip at playhead position (main track)
  VideoClipEntity? get activeVideoClip {
    final mainClips = project.videoClips.where((c) => !c.isOverlay).toList();
    final clipsToSearch = mainClips.isNotEmpty ? mainClips : project.videoClips;
    for (final clip in clipsToSearch) {
      if (playheadPositionMs >= clip.timelineStartMs &&
          playheadPositionMs <= clip.timelineEndMs) {
        return clip;
      }
    }
    if (clipsToSearch.isNotEmpty) {
      if (playheadPositionMs >= clipsToSearch.last.timelineEndMs) {
        return clipsToSearch.last;
      }
      return clipsToSearch.first;
    }
    return null;
  }

  /// Currently active overlay/PIP video clips at playhead position
  List<VideoClipEntity> get activeOverlayClips {
    return project.videoClips.where((c) {
      return c.isOverlay &&
          playheadPositionMs >= c.timelineStartMs &&
          playheadPositionMs <= c.timelineEndMs;
    }).toList();
  }

  /// Currently active effect clips at playhead position
  List<EffectClipEntity> get activeEffectClips {
    return project.effectClips.where((e) {
      return playheadPositionMs >= e.timelineStartMs &&
          playheadPositionMs <= e.timelineEndMs;
    }).toList();
  }

  /// Selected video clip if any
  VideoClipEntity? get selectedVideoClip {
    if ((selectionType != SelectionType.videoClip && selectionType != SelectionType.overlayClip) ||
        selectedItemId == null) {
      return null;
    }
    for (final clip in project.videoClips) {
      if (clip.id == selectedItemId) return clip;
    }
    return null;
  }

  /// Selected effect clip if any
  EffectClipEntity? get selectedEffectClip {
    if (selectionType != SelectionType.effectClip || selectedItemId == null) return null;
    for (final eff in project.effectClips) {
      if (eff.id == selectedItemId) return eff;
    }
    return null;
  }

  /// Selected audio clip if any
  AudioClipEntity? get selectedAudioClip {
    if (selectionType != SelectionType.audioClip || selectedItemId == null) return null;
    for (final a in project.audioClips) {
      if (a.id == selectedItemId) return a;
    }
    return null;
  }

  /// Selected text overlay if any
  TextOverlayEntity? get selectedTextOverlay {
    if (selectionType != SelectionType.textOverlay || selectedItemId == null) return null;
    for (final t in project.textOverlays) {
      if (t.id == selectedItemId) return t;
    }
    return null;
  }

  /// Selected sticker overlay if any
  StickerOverlayEntity? get selectedStickerOverlay {
    if (selectionType != SelectionType.stickerOverlay || selectedItemId == null) return null;
    for (final s in project.stickerOverlays) {
      if (s.id == selectedItemId) return s;
    }
    return null;
  }

  /// Selected subtitle if any
  SubtitleEntity? get selectedSubtitle {
    if (selectionType != SelectionType.subtitle || selectedItemId == null) return null;
    for (final sub in project.subtitles) {
      if (sub.id == selectedItemId) return sub;
    }
    return null;
  }

  TimelineState copyWith({
    ProjectEntity? project,
    int? playheadPositionMs,
    bool? isPlaying,
    double? pixelsPerSecond,
    SelectionType? selectionType,
    String? selectedItemId,
    bool? isLooping,
  }) {
    return TimelineState(
      project: project ?? this.project,
      playheadPositionMs: playheadPositionMs ?? this.playheadPositionMs,
      isPlaying: isPlaying ?? this.isPlaying,
      pixelsPerSecond: pixelsPerSecond ?? this.pixelsPerSecond,
      selectionType: selectionType ?? this.selectionType,
      selectedItemId: selectedItemId,
      isLooping: isLooping ?? this.isLooping,
    );
  }
}
