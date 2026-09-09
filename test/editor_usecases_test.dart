import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/domain/usecases/editor_usecases.dart';
import 'package:procut/features/filters_effects/domain/entities/video_effect_type.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

void main() {
  group('Editor UseCases Tests', () {
    late ProjectEntity testProject;

    setUp(() {
      testProject = ProjectEntity(
        id: 'proj-1',
        title: 'Editor Test Project',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'clip-1',
            mediaPath: 'video1.mp4',
            name: 'First Clip',
            sourceDurationMs: 10000,
            timelineStartMs: 0,
            timelineEndMs: 10000,
            trimStartMs: 0,
            trimEndMs: 10000,
          ),
        ],
      );
    });

    test('SplitClipUseCase splits a 10s clip at 4s into two 4s and 6s clips', () {
      final useCase = SplitClipUseCase();
      final updated = useCase(
        project: testProject,
        clipId: 'clip-1',
        splitPositionMs: 4000,
      );

      expect(updated.videoClips.length, 2);
      expect(updated.videoClips[0].timelineStartMs, 0);
      expect(updated.videoClips[0].timelineEndMs, 4000);
      expect(updated.videoClips[1].timelineStartMs, 4000);
      expect(updated.videoClips[1].timelineEndMs, 10000);
    });

    test('UpdateClipSpeedUseCase accelerates clip to 2x and halves duration', () {
      final useCase = UpdateClipSpeedUseCase();
      final updated = useCase(
        project: testProject,
        clipId: 'clip-1',
        newSpeed: 2.0,
      );

      expect(updated.videoClips.first.speed, 2.0);
      expect(updated.videoClips.first.effectiveDurationMs, 5000);
    });

    test('TrimClipUseCase shortens clip and preserves timeline boundaries', () {
      final useCase = TrimClipUseCase();
      final updated = useCase(
        project: testProject,
        clipId: 'clip-1',
        newTrimStartMs: 2000,
        newTrimEndMs: 8000,
      );

      expect(updated.videoClips.first.trimEndMs, 8000);
      expect(updated.videoClips.first.effectiveDurationMs, 6000);
    });

    test('DeleteClipUseCase deletes middle clip and automatically shifts subsequent clips left with no gap', () {
      final multiClipProject = testProject.copyWith(
        videoClips: const [
          VideoClipEntity(
            id: 'clip-1',
            mediaPath: 'video1.mp4',
            name: 'Clip 1',
            sourceDurationMs: 5000,
            timelineStartMs: 0,
            timelineEndMs: 5000,
            trimEndMs: 5000,
          ),
          VideoClipEntity(
            id: 'clip-2',
            mediaPath: 'video2.mp4',
            name: 'Clip 2',
            sourceDurationMs: 4000,
            timelineStartMs: 5000,
            timelineEndMs: 9000,
            trimEndMs: 4000,
          ),
          VideoClipEntity(
            id: 'clip-3',
            mediaPath: 'video3.mp4',
            name: 'Clip 3',
            sourceDurationMs: 6000,
            timelineStartMs: 9000,
            timelineEndMs: 15000,
            trimEndMs: 6000,
          ),
        ],
        durationMs: 15000,
      );

      final useCase = DeleteClipUseCase();
      final updated = useCase(
        project: multiClipProject,
        clipId: 'clip-2',
      );

      expect(updated.videoClips.length, 2);
      expect(updated.videoClips[0].id, 'clip-1');
      expect(updated.videoClips[0].timelineStartMs, 0);
      expect(updated.videoClips[0].timelineEndMs, 5000);

      // Clip 3 takes Clip 2's place immediately with 0 gap
      expect(updated.videoClips[1].id, 'clip-3');
      expect(updated.videoClips[1].timelineStartMs, 5000);
      expect(updated.videoClips[1].timelineEndMs, 11000);
      expect(updated.calculatedDurationMs, 11000);
    });

    test('Full clip size matches true video duration', () {
      const fullDurationMs = 24500; // 24.5s video
      const clip = VideoClipEntity(
        id: 'clip-long',
        mediaPath: 'long_video.mp4',
        name: 'Long Video',
        sourceDurationMs: fullDurationMs,
        timelineStartMs: 0,
        timelineEndMs: fullDurationMs,
        trimStartMs: 0,
        trimEndMs: fullDurationMs,
      );

      expect(clip.sourceDurationMs, fullDurationMs);
      expect(clip.effectiveDurationMs, fullDurationMs);
      expect(clip.trimmedSourceDurationMs, fullDurationMs);
    });

    test('VideoEffectType properly assigns and configures effect attributes', () {
      const clipWithEffect = VideoClipEntity(
        id: 'clip-effect-1',
        mediaPath: 'video.mp4',
        name: 'Explosion Clip',
        sourceDurationMs: 5000,
        timelineStartMs: 0,
        timelineEndMs: 5000,
        trimStartMs: 0,
        trimEndMs: 5000,
        effectType: VideoEffectType.explosion,
        effectIntensity: 0.85,
      );

      expect(clipWithEffect.effectType, VideoEffectType.explosion);
      expect(clipWithEffect.effectIntensity, 0.85);
      expect(clipWithEffect.effectType.label, 'Explosion');
      expect(clipWithEffect.effectType.category, VideoEffectCategory.trending);
    });
  });
}
