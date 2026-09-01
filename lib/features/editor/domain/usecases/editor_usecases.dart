import 'package:looma/core/utils/id_generator.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';

class SplitClipUseCase {
  ProjectEntity call({
    required ProjectEntity project,
    required String clipId,
    required int splitPositionMs,
  }) {
    final clipIndex = project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return project;

    final clip = project.videoClips[clipIndex];
    // Split position must be strictly inside the clip bounds
    if (splitPositionMs <= clip.timelineStartMs + 200 ||
        splitPositionMs >= clip.timelineEndMs - 200) {
      return project;
    }

    final durationFirstPart = splitPositionMs - clip.timelineStartMs;
    final sourceDeltaFirst = (durationFirstPart * clip.speed).round();

    final firstClip = clip.copyWith(
      timelineEndMs: splitPositionMs,
      trimEndMs: clip.trimStartMs + sourceDeltaFirst,
    );

    final secondClip = clip.copyWith(
      id: IdGenerator.generate(),
      timelineStartMs: splitPositionMs,
      trimStartMs: clip.trimStartMs + sourceDeltaFirst,
      name: '${clip.name} (Part 2)',
    );

    final updatedClips = List<VideoClipEntity>.from(project.videoClips);
    updatedClips[clipIndex] = firstClip;
    updatedClips.insert(clipIndex + 1, secondClip);

    return project.copyWith(videoClips: updatedClips);
  }
}

class TrimClipUseCase {
  ProjectEntity call({
    required ProjectEntity project,
    required String clipId,
    required int newTrimStartMs,
    required int newTrimEndMs,
  }) {
    final clipIndex = project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return project;

    final clip = project.videoClips[clipIndex];
    if (newTrimEndMs - newTrimStartMs < 200) return project;

    final newDurationMs = ((newTrimEndMs - newTrimStartMs) / clip.speed).round();
    final updatedClip = clip.copyWith(
      trimStartMs: newTrimStartMs,
      trimEndMs: newTrimEndMs,
      timelineEndMs: clip.timelineStartMs + newDurationMs,
    );

    final updatedClips = List<VideoClipEntity>.from(project.videoClips);
    updatedClips[clipIndex] = updatedClip;

    // Recalibrate subsequent clips in sequence
    int currentOffset = updatedClip.timelineEndMs;
    for (int i = clipIndex + 1; i < updatedClips.length; i++) {
      final c = updatedClips[i];
      final cDuration = c.effectiveDurationMs;
      updatedClips[i] = c.copyWith(
        timelineStartMs: currentOffset,
        timelineEndMs: currentOffset + cDuration,
      );
      currentOffset += cDuration;
    }

    return project.copyWith(
      videoClips: updatedClips,
      durationMs: currentOffset,
    );
  }
}

class UpdateClipSpeedUseCase {
  ProjectEntity call({
    required ProjectEntity project,
    required String clipId,
    required double newSpeed,
  }) {
    final clipIndex = project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return project;

    final clip = project.videoClips[clipIndex];
    final newDurationMs = (clip.trimmedSourceDurationMs / newSpeed).round();

    final updatedClip = clip.copyWith(
      speed: newSpeed,
      timelineEndMs: clip.timelineStartMs + newDurationMs,
    );

    final updatedClips = List<VideoClipEntity>.from(project.videoClips);
    updatedClips[clipIndex] = updatedClip;

    // Recalibrate following clips
    int currentOffset = updatedClip.timelineEndMs;
    for (int i = clipIndex + 1; i < updatedClips.length; i++) {
      final c = updatedClips[i];
      final cDuration = c.effectiveDurationMs;
      updatedClips[i] = c.copyWith(
        timelineStartMs: currentOffset,
        timelineEndMs: currentOffset + cDuration,
      );
      currentOffset += cDuration;
    }

    return project.copyWith(
      videoClips: updatedClips,
      durationMs: currentOffset,
    );
  }
}

class DeleteClipUseCase {
  ProjectEntity call({
    required ProjectEntity project,
    required String clipId,
  }) {
    if (project.videoClips.length <= 1) return project;
    final remaining = project.videoClips.where((c) => c.id != clipId).toList();
    if (remaining.length == project.videoClips.length) return project;

    // Ripple shift all remaining clips to close the gap seamlessly
    int currentOffset = 0;
    final updatedClips = <VideoClipEntity>[];
    for (final clip in remaining) {
      final dur = clip.effectiveDurationMs;
      updatedClips.add(
        clip.copyWith(
          timelineStartMs: currentOffset,
          timelineEndMs: currentOffset + dur,
        ),
      );
      currentOffset += dur;
    }

    return project.copyWith(
      videoClips: updatedClips,
      durationMs: currentOffset,
    );
  }
}
