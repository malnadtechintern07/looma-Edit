import 'package:looma/core/utils/id_generator.dart';
import 'package:looma/features/editor/domain/entities/keyframe_entity.dart';
import 'package:looma/features/editor/domain/entities/speed_curve_type.dart';
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
    // Split position must be strictly inside the clip bounds (50ms minimum margin)
    if (splitPositionMs <= clip.timelineStartMs + 50 ||
        splitPositionMs >= clip.timelineEndMs - 50) {
      return project;
    }

    final durationFirstPart = splitPositionMs - clip.timelineStartMs;
    final sourceDeltaFirst = (durationFirstPart * clip.speed).round();

    List<KeyframeEntity> firstKeyframes = const [];
    List<KeyframeEntity> secondKeyframes = const [];

    if (clip.keyframes.isNotEmpty) {
      final baseValues = KeyframeValues(
        posX: clip.positionX,
        posY: clip.positionY,
        scale: clip.zoomScale,
        rotation: clip.rotationDegrees,
        opacity: clip.opacity,
      );
      final splitValues = KeyframeInterpolator.interpolate(
        keyframes: clip.keyframes,
        currentOffsetMs: durationFirstPart,
        baseValues: baseValues,
      );

      final kfBoundaryFirst = KeyframeEntity(
        id: IdGenerator.generate(),
        timestampMs: durationFirstPart,
        posX: splitValues.posX,
        posY: splitValues.posY,
        scale: splitValues.scale,
        rotation: splitValues.rotation,
        opacity: splitValues.opacity,
      );

      final kfBoundarySecond = KeyframeEntity(
        id: IdGenerator.generate(),
        timestampMs: 0,
        posX: splitValues.posX,
        posY: splitValues.posY,
        scale: splitValues.scale,
        rotation: splitValues.rotation,
        opacity: splitValues.opacity,
      );

      final before = clip.keyframes.where((k) => k.timestampMs < durationFirstPart - 20).toList();
      firstKeyframes = [...before, kfBoundaryFirst];

      final after = clip.keyframes
          .where((k) => k.timestampMs > durationFirstPart + 20)
          .map((k) => k.copyWith(
                id: IdGenerator.generate(),
                timestampMs: k.timestampMs - durationFirstPart,
              ))
          .toList();
      secondKeyframes = [kfBoundarySecond, ...after];
    }

    final firstClip = clip.copyWith(
      timelineEndMs: splitPositionMs,
      trimEndMs: clip.trimStartMs + sourceDeltaFirst,
      keyframes: firstKeyframes,
    );

    final secondClip = clip.copyWith(
      id: IdGenerator.generate(),
      timelineStartMs: splitPositionMs,
      trimStartMs: clip.trimStartMs + sourceDeltaFirst,
      name: '${clip.name} (Part 2)',
      keyframes: secondKeyframes,
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
    double? newSpeed,
    SpeedCurveType? newSpeedCurve,
  }) {
    final clipIndex = project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return project;

    final clip = project.videoClips[clipIndex];
    final speed = (newSpeed != null && newSpeed > 0) ? newSpeed : clip.speed;
    final curve = newSpeedCurve ?? clip.speedCurve;
    final effectiveMultiplier = speed * curve.averageSpeedMultiplier;
    final newDurationMs = (clip.trimmedSourceDurationMs / effectiveMultiplier).round().clamp(100, 100000000);

    final updatedClip = clip.copyWith(
      speed: speed,
      speedCurve: curve,
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
