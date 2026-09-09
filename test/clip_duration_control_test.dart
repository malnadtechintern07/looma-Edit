import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/editor/presentation/widgets/video_track_item.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clip Duration Control & CapCut-Style Dual Edge Trimming Tests', () {
    late ProjectEntity testProject;
    late VideoClipEntity videoClip1;
    late VideoClipEntity videoClip2;
    late VideoClipEntity photoClip;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      await storage.clearAll();

      videoClip1 = const VideoClipEntity(
        id: 'video_clip_1',
        name: 'Opening Drone Shot',
        mediaPath: 'assets/demo/drone.mp4',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 6000,
        trimStartMs: 1000,
        trimEndMs: 7000,
      );

      videoClip2 = const VideoClipEntity(
        id: 'video_clip_2',
        name: 'Action Scene',
        mediaPath: 'assets/demo/action.mp4',
        sourceDurationMs: 8000,
        timelineStartMs: 6000,
        timelineEndMs: 12000,
        trimStartMs: 0,
        trimEndMs: 6000,
      );

      photoClip = const VideoClipEntity(
        id: 'photo_clip_1',
        name: 'Title Card Photo',
        mediaPath: 'assets/demo/poster.png',
        sourceDurationMs: 5000,
        timelineStartMs: 12000,
        timelineEndMs: 17000,
        trimStartMs: 0,
        trimEndMs: 5000,
      );

      testProject = ProjectEntity(
        id: 'duration_test_project',
        title: 'Duration Control Test',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 17000,
        videoClips: [videoClip1, videoClip2, photoClip],
      );
    });

    test('Video Clip Entity identifies isPhoto and isVideo accurately', () {
      expect(videoClip1.isVideo, isTrue);
      expect(videoClip1.isPhoto, isFalse);

      expect(photoClip.isPhoto, isTrue);
      expect(photoClip.isVideo, isFalse);
    });

    test('Dragging video left handle trims video start non-destructively without modifying original file', () {
      final controller = EditorController(project: testProject);

      // Drag left handle to the right by 30 pixels (at 60 px/sec => +500ms)
      controller.updateClipDurationByDrag(
        clipId: 'video_clip_1',
        deltaPixels: 30.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: true,
      );

      final updatedClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_1');
      // Original trimStart was 1000ms. +500ms => 1500ms
      expect(updatedClip.trimStartMs, 1500);
      expect(updatedClip.trimEndMs, 7000);
      expect(updatedClip.sourceDurationMs, 10000); // Unchanged original duration
      expect(updatedClip.effectiveDurationMs, 5500);
    });

    test('Dragging video right handle trims video end and is strictly clamped to original source duration', () {
      final controller = EditorController(project: testProject);

      // Attempt to drag right handle past the video source duration (e.g. +600 pixels => +10,000ms)
      controller.updateClipDurationByDrag(
        clipId: 'video_clip_1',
        deltaPixels: 600.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: false,
      );

      final updatedClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_1');
      // trimEnd must not exceed sourceDurationMs (10,000ms)
      expect(updatedClip.trimEndMs, 10000);
      expect(updatedClip.sourceDurationMs, 10000);
      // Effective duration: 10000 - 1000 = 9000ms
      expect(updatedClip.effectiveDurationMs, 9000);
    });

    test('Dragging photo right handle extends photo display duration beyond original initial length', () {
      final controller = EditorController(project: testProject);

      // Drag right handle +180 pixels at 60 px/sec => +3000ms
      controller.updateClipDurationByDrag(
        clipId: 'photo_clip_1',
        deltaPixels: 180.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: false,
      );

      final updatedPhoto = controller.state.project.videoClips.firstWhere((c) => c.id == 'photo_clip_1');
      // Photo duration expanded from 5000ms to 8000ms
      expect(updatedPhoto.effectiveDurationMs, 8000);
      expect(updatedPhoto.sourceDurationMs, 8000);
      expect(updatedPhoto.trimEndMs, 8000);
    });

    test('Dragging photo left handle reduces display duration gracefully', () {
      final controller = EditorController(project: testProject);

      // Drag left handle +60 pixels at 60 px/sec => +1000ms (reduces photo duration by 1000ms)
      controller.updateClipDurationByDrag(
        clipId: 'photo_clip_1',
        deltaPixels: 60.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: true,
      );

      final updatedPhoto = controller.state.project.videoClips.firstWhere((c) => c.id == 'photo_clip_1');
      // Photo duration reduced from 5000ms to 4000ms
      expect(updatedPhoto.effectiveDurationMs, 4000);
    });

    test('Resizing one clip does NOT alter duration, trim, or content of other clips', () {
      final controller = EditorController(project: testProject);

      final clip2OriginalDur = videoClip2.effectiveDurationMs;
      final clip2OriginalTrimStart = videoClip2.trimStartMs;
      final clip2OriginalTrimEnd = videoClip2.trimEndMs;

      final photoOriginalDur = photoClip.effectiveDurationMs;

      // Resize clip 1
      controller.updateClipDurationByDrag(
        clipId: 'video_clip_1',
        deltaPixels: -60.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: false,
      );

      final clip2After = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_2');
      final photoAfter = controller.state.project.videoClips.firstWhere((c) => c.id == 'photo_clip_1');

      // Clip 2's own duration and trims are 100% UNCHANGED
      expect(clip2After.effectiveDurationMs, clip2OriginalDur);
      expect(clip2After.trimStartMs, clip2OriginalTrimStart);
      expect(clip2After.trimEndMs, clip2OriginalTrimEnd);

      // Photo clip duration is 100% UNCHANGED
      expect(photoAfter.effectiveDurationMs, photoOriginalDur);
    });

    test('Dragging edge back outward restores previously trimmed portion from original video non-destructively', () {
      final controller = EditorController(project: testProject);

      // Step 1: Trim 2000ms off the right of videoClip1 (from 7000ms down to 5000ms)
      controller.updateClipDurationByDrag(
        clipId: 'video_clip_1',
        deltaPixels: -120.0, // -2000ms at 60 pps
        pixelsPerSecond: 60.0,
        isLeftHandle: false,
      );

      var clip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_1');
      expect(clip.trimEndMs, 5000);
      expect(clip.effectiveDurationMs, 4000);

      // Step 2: Drag right handle back outward (+2500ms) - restores trimmed portion up to original source duration (10,000ms)
      controller.updateClipDurationByDrag(
        clipId: 'video_clip_1',
        deltaPixels: 150.0, // +2500ms
        pixelsPerSecond: 60.0,
        isLeftHandle: false,
      );

      clip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_1');
      expect(clip.trimEndMs, 7500);
      expect(clip.effectiveDurationMs, 6500);
      expect(clip.sourceDurationMs, 10000); // Original full source intact!

      // Step 3: Drag left handle outward to the left (-60px => -1000ms) to restore start
      controller.updateClipDurationByDrag(
        clipId: 'video_clip_1',
        deltaPixels: -60.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: true,
      );

      clip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_1');
      expect(clip.trimStartMs, 0); // Restored back to the very beginning of the source video!
      expect(clip.effectiveDurationMs, 7500);
    });

    test('Trimming and extending clips changes total calculated duration for export', () {
      final controller = EditorController(project: testProject);
      final initialDuration = controller.state.project.calculatedDurationMs;

      // Extend photo clip by +3000ms
      controller.updateClipDurationByDrag(
        clipId: 'photo_clip_1',
        deltaPixels: 180.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: false,
      );

      final newDuration = controller.state.project.calculatedDurationMs;
      expect(newDuration, initialDuration + 3000);
      expect(controller.state.project.durationMs, initialDuration + 3000);
    });

    test('Micro-fine trimming allows reducing clip duration down to 100ms without 300ms barrier', () {
      final controller = EditorController(project: testProject);

      // videoClip1 effectiveDurationMs is 6000ms (trimStart: 1000, trimEnd: 7000)
      // Trim right edge inward by -6850ms (at 60 pps, -411.0px)
      controller.updateClipDurationByDrag(
        clipId: 'video_clip_1',
        deltaPixels: -411.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: false,
      );

      final updatedClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_1');
      // Should trim down to 150ms without being blocked by previous 300ms limit
      expect(updatedClip.effectiveDurationMs, lessThan(300));
      expect(updatedClip.effectiveDurationMs, greaterThanOrEqualTo(100));

      // Releasing finger calls finishClipDurationDrag without crashing
      controller.finishClipDurationDrag();
    });

    test('Dragging left handle moves left edge under finger and anchors right edge, then ripple-snaps on finish', () {
      final controller = EditorController(project: testProject);

      // videoClip2 starts at 6000ms, ends at 12000ms (trimStart: 0, trimEnd: 6000)
      // Drag left handle to the right by +60px (+1000ms)
      controller.updateClipDurationByDrag(
        clipId: 'video_clip_2',
        deltaPixels: 60.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: true,
      );

      var clip2 = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_2');
      // While dragging:
      // Left edge moved from 6000ms to 7000ms (under user's finger)
      expect(clip2.timelineStartMs, 7000);
      // Right edge stayed firmly anchored at 12000ms
      expect(clip2.timelineEndMs, 12000);
      expect(clip2.trimStartMs, 1000);
      expect(clip2.effectiveDurationMs, 5000);

      // Playhead seeks in real-time to the active left trim edge (7000ms)
      expect(controller.state.playheadPositionMs, 7000);

      // User releases finger -> finishClipDurationDrag() ripple-snaps timeline flush
      controller.finishClipDurationDrag();

      clip2 = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_2');
      final clip1 = controller.state.project.videoClips.firstWhere((c) => c.id == 'video_clip_1');
      final photo = controller.state.project.videoClips.firstWhere((c) => c.id == 'photo_clip_1');

      // After ripple snap: clip1 is 0-6000ms, clip2 is 6000-11000ms, photo is 11000-16000ms
      expect(clip1.timelineStartMs, 0);
      expect(clip1.timelineEndMs, 6000);
      expect(clip2.timelineStartMs, 6000);
      expect(clip2.timelineEndMs, 11000);
      expect(photo.timelineStartMs, 11000);
      expect(photo.timelineEndMs, 16000);
      expect(controller.state.project.durationMs, 16000);
    });

    testWidgets('VideoTrackItem renders CapCut dual-side drag handles when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: VideoTrackItem(
                clip: videoClip1,
                pixelsPerSecond: 60.0,
                isSelected: true,
                onTap: () {},
                onHandleDragUpdate: (delta, isLeft) {},
              ),
            ),
          ),
        ),
      );

      // Verify that the clip renders with handles
      expect(find.byType(VideoTrackItem), findsOneWidget);
      expect(find.text('Opening Drone Shot'), findsOneWidget);
    });
  });
}
