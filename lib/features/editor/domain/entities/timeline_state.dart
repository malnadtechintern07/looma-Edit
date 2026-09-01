import 'package:flutter/foundation.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';

enum SelectionType { none, videoClip, audioClip, textOverlay, stickerOverlay }

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
    this.pixelsPerSecond = 50.0,
    this.selectionType = SelectionType.none,
    this.selectedItemId,
    this.isLooping = false,
  });

  /// Currently active video clip at playhead position
  VideoClipEntity? get activeVideoClip {
    for (final clip in project.videoClips) {
      if (playheadPositionMs >= clip.timelineStartMs &&
          playheadPositionMs <= clip.timelineEndMs) {
        return clip;
      }
    }
    return project.videoClips.isNotEmpty ? project.videoClips.first : null;
  }

  /// Selected video clip if any
  VideoClipEntity? get selectedVideoClip {
    if (selectionType != SelectionType.videoClip || selectedItemId == null) return null;
    for (final clip in project.videoClips) {
      if (clip.id == selectedItemId) return clip;
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
