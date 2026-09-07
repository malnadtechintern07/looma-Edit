import 'package:flutter/foundation.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/animation_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/subtitle_entity.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/filters_effects/domain/entities/effect_clip_entity.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/sticker_overlay_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/text_overlay_entity.dart';

enum SelectionType { none, videoClip, overlayClip, audioClip, textOverlay, stickerOverlay, subtitle, effectClip, animationClip }

@immutable
class TimelineState {
  final ProjectEntity project;
  final int playheadPositionMs;
  final bool isPlaying;
  final double pixelsPerSecond;
  final SelectionType selectionType;
  final String? selectedItemId;
  final bool isLooping;
  final bool isChromaKeyPickingMode;
  final String? chromaKeyTargetClipId;
  final double chromaKeyCrosshairX; // normalized 0..1
  final double chromaKeyCrosshairY; // normalized 0..1
  final Map<String, int> clipLanes;
  final bool isSnappingEnabled;

  const TimelineState({
    required this.project,
    this.playheadPositionMs = 0,
    this.isPlaying = false,
    this.pixelsPerSecond = 60.0,
    this.selectionType = SelectionType.none,
    this.selectedItemId,
    this.isLooping = false,
    this.isChromaKeyPickingMode = false,
    this.chromaKeyTargetClipId,
    this.chromaKeyCrosshairX = 0.5,
    this.chromaKeyCrosshairY = 0.5,
    this.clipLanes = const {},
    this.isSnappingEnabled = true,
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

  /// Currently active animation clips at playhead position
  List<AnimationClipEntity> get activeAnimationClips {
    return project.animationClips.where((a) {
      return playheadPositionMs >= a.timelineStartMs &&
          playheadPositionMs <= a.timelineEndMs;
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

  /// Selected animation clip if any
  AnimationClipEntity? get selectedAnimationClip {
    if (selectionType != SelectionType.animationClip || selectedItemId == null) return null;
    for (final anim in project.animationClips) {
      if (anim.id == selectedItemId) return anim;
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
    bool? isChromaKeyPickingMode,
    String? chromaKeyTargetClipId,
    bool clearChromaKeyTarget = false,
    double? chromaKeyCrosshairX,
    double? chromaKeyCrosshairY,
    Map<String, int>? clipLanes,
    bool? isSnappingEnabled,
  }) {
    final effectiveSelectionType = selectionType ?? this.selectionType;
    final effectiveSelectedItemId = effectiveSelectionType == SelectionType.none
        ? null
        : (selectedItemId ?? (selectionType != null ? null : this.selectedItemId));

    final effectivePickingMode = isChromaKeyPickingMode ?? this.isChromaKeyPickingMode;
    final effectiveChromaKeyTargetClipId = clearChromaKeyTarget
        ? null
        : (chromaKeyTargetClipId ?? this.chromaKeyTargetClipId);

    return TimelineState(
      project: project ?? this.project,
      playheadPositionMs: playheadPositionMs ?? this.playheadPositionMs,
      isPlaying: isPlaying ?? this.isPlaying,
      pixelsPerSecond: pixelsPerSecond ?? this.pixelsPerSecond,
      selectionType: effectiveSelectionType,
      selectedItemId: effectiveSelectedItemId,
      isLooping: isLooping ?? this.isLooping,
      isChromaKeyPickingMode: effectivePickingMode,
      chromaKeyTargetClipId: effectiveChromaKeyTargetClipId,
      chromaKeyCrosshairX: chromaKeyCrosshairX ?? this.chromaKeyCrosshairX,
      chromaKeyCrosshairY: chromaKeyCrosshairY ?? this.chromaKeyCrosshairY,
      clipLanes: clipLanes ?? this.clipLanes,
      isSnappingEnabled: isSnappingEnabled ?? this.isSnappingEnabled,
    );
  }
}
