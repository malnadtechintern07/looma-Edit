import 'package:flutter_test/flutter_test.dart';
import 'package:looma/core/constants/app_constants.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/editor/presentation/providers/editor_controller.dart';
import 'package:looma/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';

void main() {
  group('Timeline Zoom & Long Video Navigation Tests', () {
    late ProjectEntity shortProject;
    late ProjectEntity mediumProject;
    late ProjectEntity longProject;
    late ProjectEntity veryLongProject;

    setUp(() {
      // Short project: 3 seconds (3,000 ms)
      shortProject = ProjectEntity(
        id: 'proj-short',
        title: 'Short 3s Video',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'c-short',
            mediaPath: 'short.mp4',
            name: 'Short Clip',
            sourceDurationMs: 3000,
            timelineStartMs: 0,
            timelineEndMs: 3000,
            trimStartMs: 0,
            trimEndMs: 3000,
          ),
        ],
      );

      // Medium project: 30 seconds (30,000 ms)
      mediumProject = ProjectEntity(
        id: 'proj-med',
        title: 'Medium 30s Video',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'c-med-1',
            mediaPath: 'med1.mp4',
            name: 'Med Clip 1',
            sourceDurationMs: 15000,
            timelineStartMs: 0,
            timelineEndMs: 15000,
            trimStartMs: 0,
            trimEndMs: 15000,
          ),
          VideoClipEntity(
            id: 'c-med-2',
            mediaPath: 'med2.mp4',
            name: 'Med Clip 2',
            sourceDurationMs: 15000,
            timelineStartMs: 15000,
            timelineEndMs: 30000,
            trimStartMs: 0,
            trimEndMs: 15000,
          ),
        ],
      );

      // Long project: 5 minutes (300,000 ms)
      longProject = ProjectEntity(
        id: 'proj-long',
        title: 'Long 5-min Video',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'c-long',
            mediaPath: 'long.mp4',
            name: 'Long 5min Clip',
            sourceDurationMs: 300000,
            timelineStartMs: 0,
            timelineEndMs: 300000,
            trimStartMs: 0,
            trimEndMs: 300000,
          ),
        ],
      );

      // Very long project: 30 minutes (1,800,000 ms)
      veryLongProject = ProjectEntity(
        id: 'proj-very-long',
        title: 'Very Long 30-min Video',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'c-vlong',
            mediaPath: 'vlong.mp4',
            name: 'Very Long 30min Clip',
            sourceDurationMs: 1800000,
            timelineStartMs: 0,
            timelineEndMs: 1800000,
            trimStartMs: 0,
            trimEndMs: 1800000,
          ),
        ],
      );
    });

    test('Zoom in increases pixelsPerSecond up to 200.0 without changing clip duration or speed', () {
      final controller = EditorController(project: shortProject);
      expect(controller.state.pixelsPerSecond, AppConstants.defaultPixelsPerSecond);
      expect(controller.state.project.calculatedDurationMs, 3000);

      // Zoom in to 150.0 px/s
      controller.setTimelineZoom(150.0);
      expect(controller.state.pixelsPerSecond, 150.0);
      expect(controller.state.project.calculatedDurationMs, 3000);
      expect(controller.state.project.videoClips.first.speed, 1.0);

      // Zoom in past max clamp (e.g. 500.0) -> clamps to 200.0
      controller.setTimelineZoom(500.0);
      expect(controller.state.pixelsPerSecond, AppConstants.maxTimelinePixelsPerSecond);
      expect(controller.state.project.calculatedDurationMs, 3000);
    });

    test('Zoom out decreases pixelsPerSecond down to 8.0 for long videos', () {
      final controller = EditorController(project: longProject);
      expect(controller.state.project.calculatedDurationMs, 300000);

      // Zoom out to 15.0 px/s
      controller.setTimelineZoom(15.0);
      expect(controller.state.pixelsPerSecond, 15.0);
      expect(controller.state.project.calculatedDurationMs, 300000);

      // Zoom out below min clamp -> clamps to 8.0
      controller.setTimelineZoom(0.1);
      expect(controller.state.pixelsPerSecond, AppConstants.minTimelinePixelsPerSecond);
      expect(controller.state.project.calculatedDurationMs, 300000);
    });

    test('Fit Timeline calculates correct pixelsPerSecond for short 3s video', () {
      final controller = EditorController(project: shortProject);
      const viewportWidth = 360.0;
      controller.fitTimelineToScreen(viewportWidth);

      // (360 * 0.85) / 3s = 102.0 px/s
      expect(controller.state.pixelsPerSecond, closeTo(102.0, 0.1));
      expect(controller.state.project.calculatedDurationMs, 3000);
    });

    test('Fit Timeline calculates correct pixelsPerSecond for medium 30s video', () {
      final controller = EditorController(project: mediumProject);
      const viewportWidth = 360.0;
      controller.fitTimelineToScreen(viewportWidth);

      // (360 * 0.85) / 30s = 10.2 px/s
      expect(controller.state.pixelsPerSecond, closeTo(10.2, 0.1));
      expect(controller.state.project.calculatedDurationMs, 30000);
    });

    test('Fit Timeline calculates correct pixelsPerSecond for long 5-minute video (clamped to min 8.0 px/s)', () {
      final controller = EditorController(project: longProject);
      const viewportWidth = 360.0;
      controller.fitTimelineToScreen(viewportWidth);

      // (360 * 0.85) / 300s = 1.02 -> clamped to min 8.0 px/s
      expect(controller.state.pixelsPerSecond, AppConstants.minTimelinePixelsPerSecond);
      expect(controller.state.project.calculatedDurationMs, 300000);
    });

    test('Fit Timeline calculates correct pixelsPerSecond for very long 30-minute video (clamped to min 8.0 px/s)', () {
      final controller = EditorController(project: veryLongProject);
      const viewportWidth = 360.0;
      controller.fitTimelineToScreen(viewportWidth);

      // (360 * 0.85) / 1800s = 0.17 -> clamped to min 8.0 px/s
      expect(controller.state.pixelsPerSecond, AppConstants.minTimelinePixelsPerSecond);
      expect(controller.state.project.calculatedDurationMs, 1800000);
    });

    test('Playhead position is preserved exactly when zooming or fitting timeline', () {
      final controller = EditorController(project: mediumProject);
      controller.seekTo(14500); // 14.5s
      expect(controller.state.playheadPositionMs, 14500);

      // Zoom in
      controller.setTimelineZoom(150.0);
      expect(controller.state.playheadPositionMs, 14500);

      // Fit timeline
      controller.fitTimelineToScreen(400.0);
      expect(controller.state.playheadPositionMs, 14500);

      // Zoom out
      controller.setTimelineZoom(10.0);
      expect(controller.state.playheadPositionMs, 14500);
    });
  });
}
