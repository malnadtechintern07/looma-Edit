import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/editor/domain/entities/keyframe_entity.dart';
import 'package:procut/features/editor/domain/entities/timeline_state.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/domain/usecases/editor_usecases.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/editor/presentation/widgets/editor_action_bar.dart';
import 'package:procut/features/editor/presentation/widgets/video_track_item.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  group('Keyframe Interpolation Tests', () {
    const baseValues = KeyframeValues(
      posX: 0.0,
      posY: 0.0,
      scale: 1.0,
      rotation: 0.0,
      opacity: 1.0,
    );

    test('Returns base values when keyframes list is empty', () {
      final result = KeyframeInterpolator.interpolate(
        keyframes: const [],
        currentOffsetMs: 1500,
        baseValues: baseValues,
      );

      expect(result.posX, 0.0);
      expect(result.scale, 1.0);
      expect(result.opacity, 1.0);
    });

    test('Returns first keyframe values when current time is before first keyframe', () {
      final keyframes = [
        const KeyframeEntity(
          id: 'k1',
          timestampMs: 1000,
          posX: 50.0,
          scale: 1.5,
          opacity: 0.8,
        ),
        const KeyframeEntity(
          id: 'k2',
          timestampMs: 3000,
          posX: 150.0,
          scale: 2.0,
          opacity: 0.5,
        ),
      ];

      final result = KeyframeInterpolator.interpolate(
        keyframes: keyframes,
        currentOffsetMs: 500,
        baseValues: baseValues,
      );

      expect(result.posX, 50.0);
      expect(result.scale, 1.5);
      expect(result.opacity, 0.8);
    });

    test('Returns last keyframe values when current time is after last keyframe', () {
      final keyframes = [
        const KeyframeEntity(
          id: 'k1',
          timestampMs: 1000,
          posX: 50.0,
          scale: 1.5,
        ),
        const KeyframeEntity(
          id: 'k2',
          timestampMs: 3000,
          posX: 150.0,
          scale: 2.0,
        ),
      ];

      final result = KeyframeInterpolator.interpolate(
        keyframes: keyframes,
        currentOffsetMs: 4000,
        baseValues: baseValues,
      );

      expect(result.posX, 150.0);
      expect(result.scale, 2.0);
    });

    test('Interpolates smoothly between two keyframes at midpoint', () {
      final keyframes = [
        const KeyframeEntity(
          id: 'k1',
          timestampMs: 1000,
          posX: 0.0,
          scale: 1.0,
          opacity: 1.0,
        ),
        const KeyframeEntity(
          id: 'k2',
          timestampMs: 3000,
          posX: 100.0,
          scale: 2.0,
          opacity: 0.0,
        ),
      ];

      final result = KeyframeInterpolator.interpolate(
        keyframes: keyframes,
        currentOffsetMs: 2000, // exact midpoint
        baseValues: baseValues,
      );

      // Smooth cosine ease reaches 50% at midpoint
      expect(result.posX, closeTo(50.0, 0.1));
      expect(result.scale, closeTo(1.5, 0.1));
      expect(result.opacity, closeTo(0.5, 0.1));
    });

    test('Interpolates rotation using shortest angular path (350 deg to 10 deg)', () {
      final keyframes = [
        const KeyframeEntity(
          id: 'k1',
          timestampMs: 0,
          rotation: 350.0,
        ),
        const KeyframeEntity(
          id: 'k2',
          timestampMs: 2000,
          rotation: 10.0,
        ),
      ];

      final result = KeyframeInterpolator.interpolate(
        keyframes: keyframes,
        currentOffsetMs: 1000, // midpoint
        baseValues: baseValues,
      );

      // Shortest path goes through 360/0 degrees, so midpoint is 360 (or 0)
      expect(result.rotation % 360.0, closeTo(0.0, 0.1));
    });
  });

  group('CapCut Keyframe Controller Workflows', () {
    late ProjectEntity testProject;

    setUp(() {
      final clip = VideoClipEntity(
        id: 'clip-1',
        mediaPath: '/test/video.mp4',
        name: 'Test Clip',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 10000,
        positionX: 0.0,
        positionY: 0.0,
        zoomScale: 1.0,
        rotationDegrees: 0.0,
        opacity: 1.0,
        keyframes: const [],
      );

      testProject = ProjectEntity(
        id: 'project-kf',
        title: 'KF Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
        videoClips: [clip],
      );
    });

    test('addKeyframeAtPlayhead captures current interpolated transform without resetting to base', () {
      final controller = EditorController(project: testProject);

      // Add keyframe 1 at t=0s with pos 0
      controller.seekTo(0);
      controller.addKeyframeAtPlayhead('clip-1', customValues: const KeyframeValues(
        posX: 0.0,
        posY: 0.0,
        scale: 1.0,
        rotation: 0.0,
        opacity: 1.0,
      ));

      // Add keyframe 2 at t=4000ms with pos 400
      controller.seekTo(4000);
      controller.addKeyframeAtPlayhead('clip-1', customValues: const KeyframeValues(
        posX: 400.0,
        posY: 0.0,
        scale: 2.0,
        rotation: 0.0,
        opacity: 1.0,
      ));

      // Now seek to t=2000ms (midpoint) and add keyframe 3 without custom values
      controller.seekTo(2000);
      controller.addKeyframeAtPlayhead('clip-1');

      final updatedClip = controller.state.project.videoClips.first;
      expect(updatedClip.keyframes.length, 3);

      final midKf = updatedClip.keyframes.firstWhere((k) => k.timestampMs == 2000);
      // Midpoint posX must be ~200 (interpolated), NOT 0 (static clip positionX)
      expect(midKf.posX, closeTo(200.0, 0.5));
      expect(midKf.scale, closeTo(1.5, 0.1));
    });

    test('isAtKeyframe, hasPrevKeyframe, hasNextKeyframe detect keyframe positions accurately', () {
      final controller = EditorController(project: testProject);

      controller.seekTo(1000);
      controller.addKeyframeAtPlayhead('clip-1');

      controller.seekTo(5000);
      controller.addKeyframeAtPlayhead('clip-1');

      // At 1000ms -> is at keyframe, no prev, has next
      controller.seekTo(1000);
      expect(controller.isAtKeyframe('clip-1'), isTrue);
      expect(controller.hasPrevKeyframe('clip-1'), isFalse);
      expect(controller.hasNextKeyframe('clip-1'), isTrue);

      // At 3000ms -> not at keyframe, has prev, has next
      controller.seekTo(3000);
      expect(controller.isAtKeyframe('clip-1'), isFalse);
      expect(controller.hasPrevKeyframe('clip-1'), isTrue);
      expect(controller.hasNextKeyframe('clip-1'), isTrue);

      // At 5000ms -> is at keyframe, has prev, no next
      controller.seekTo(5000);
      expect(controller.isAtKeyframe('clip-1'), isTrue);
      expect(controller.hasPrevKeyframe('clip-1'), isTrue);
      expect(controller.hasNextKeyframe('clip-1'), isFalse);
    });

    test('toggleKeyframeAtPlayhead removes keyframe when on it and adds when not', () {
      final controller = EditorController(project: testProject);

      controller.seekTo(2000);
      expect(controller.state.project.videoClips.first.keyframes.isEmpty, isTrue);

      // First toggle: adds keyframe at 2000ms
      controller.toggleKeyframeAtPlayhead('clip-1');
      expect(controller.state.project.videoClips.first.keyframes.length, 1);
      expect(controller.isAtKeyframe('clip-1'), isTrue);

      // Second toggle at same position: removes keyframe
      controller.toggleKeyframeAtPlayhead('clip-1');
      expect(controller.state.project.videoClips.first.keyframes.isEmpty, isTrue);
      expect(controller.isAtKeyframe('clip-1'), isFalse);
    });

    test('jumpToNextKeyframe and jumpToPrevKeyframe seek accurately between keyframes', () {
      final controller = EditorController(project: testProject);

      controller.seekTo(1000);
      controller.addKeyframeAtPlayhead('clip-1');
      controller.seekTo(3000);
      controller.addKeyframeAtPlayhead('clip-1');
      controller.seekTo(6000);
      controller.addKeyframeAtPlayhead('clip-1');

      controller.seekTo(0);
      controller.jumpToNextKeyframe('clip-1');
      expect(controller.state.playheadPositionMs, 1000);

      controller.jumpToNextKeyframe('clip-1');
      expect(controller.state.playheadPositionMs, 3000);

      controller.jumpToNextKeyframe('clip-1');
      expect(controller.state.playheadPositionMs, 6000);

      controller.jumpToPrevKeyframe('clip-1');
      expect(controller.state.playheadPositionMs, 3000);

      controller.jumpToPrevKeyframe('clip-1');
      expect(controller.state.playheadPositionMs, 1000);
    });

    test('CapCut Auto-Keyframing: updateClipTransform auto-records keyframes when keyframes exist', () {
      final controller = EditorController(project: testProject);

      // Clip starts with 0 keyframes. updateClipTransform should update base values (backward compatibility)
      controller.updateClipTransform(clipId: 'clip-1', positionX: 50.0, zoomScale: 1.5);
      var clip = controller.state.project.videoClips.first;
      expect(clip.positionX, 50.0);
      expect(clip.zoomScale, 1.5);
      expect(clip.keyframes.isEmpty, isTrue);

      // Add first keyframe at t=0
      controller.seekTo(0);
      controller.addKeyframeAtPlayhead('clip-1');
      clip = controller.state.project.videoClips.first;
      expect(clip.keyframes.length, 1);

      // Now scrub to t=2500ms and transform on canvas via updateClipTransform
      // CapCut auto-keyframing should auto-insert a keyframe at t=2500ms!
      controller.seekTo(2500);
      controller.updateClipTransform(clipId: 'clip-1', positionX: 120.0, zoomScale: 2.0);

      clip = controller.state.project.videoClips.first;
      expect(clip.keyframes.length, 2);

      final secondKf = clip.keyframes.firstWhere((k) => k.timestampMs == 2500);
      expect(secondKf.posX, 120.0);
      expect(secondKf.scale, 2.0);

      // Transforming near an existing keyframe updates that keyframe
      controller.updateClipTransform(clipId: 'clip-1', positionX: 140.0);
      clip = controller.state.project.videoClips.first;
      expect(clip.keyframes.length, 2); // Still 2 keyframes, updated in place
      final updatedSecondKf = clip.keyframes.firstWhere((k) => k.timestampMs == 2500);
      expect(updatedSecondKf.posX, 140.0);
    });

    test('CapCut Auto-Keyframing: setClipOpacity auto-records keyframes when keyframes exist', () {
      final controller = EditorController(project: testProject);

      controller.seekTo(0);
      controller.addKeyframeAtPlayhead('clip-1');

      // Scrub to 3000ms and adjust opacity
      controller.seekTo(3000);
      controller.setClipOpacity('clip-1', 0.4);

      final clip = controller.state.project.videoClips.first;
      expect(clip.keyframes.length, 2);
      final kf = clip.keyframes.firstWhere((k) => k.timestampMs == 3000);
      expect(kf.opacity, 0.4);
    });
  });

  group('SplitClipUseCase Keyframe Preservation Tests', () {
    test('Splitting a clip partitions keyframes cleanly between Part 1 and Part 2 with continuity', () {
      final keyframes = [
        const KeyframeEntity(id: 'k1', timestampMs: 1000, posX: 10.0, scale: 1.0),
        const KeyframeEntity(id: 'k2', timestampMs: 3000, posX: 50.0, scale: 1.5),
        const KeyframeEntity(id: 'k3', timestampMs: 7000, posX: 90.0, scale: 2.0),
      ];

      final clip = VideoClipEntity(
        id: 'clip-split',
        mediaPath: '/test/video.mp4',
        name: 'Split Test Clip',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 10000,
        keyframes: keyframes,
      );

      final project = ProjectEntity(
        id: 'proj-split',
        title: 'Split KF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
        videoClips: [clip],
      );

      final useCase = SplitClipUseCase();
      final updatedProject = useCase(
        project: project,
        clipId: 'clip-split',
        splitPositionMs: 4000,
      );

      expect(updatedProject.videoClips.length, 2);
      final part1 = updatedProject.videoClips[0];
      final part2 = updatedProject.videoClips[1];

      // Part 1: starts at 0, ends at 4000
      expect(part1.timelineStartMs, 0);
      expect(part1.timelineEndMs, 4000);
      // Keyframe 1 (1000ms) + boundary keyframe at 4000ms
      expect(part1.keyframes.any((k) => k.timestampMs == 1000), isTrue);
      expect(part1.keyframes.any((k) => k.timestampMs == 4000), isTrue);

      // Part 2: starts at 4000, ends at 10000
      expect(part2.timelineStartMs, 4000);
      expect(part2.timelineEndMs, 10000);
      // Boundary keyframe at 0ms in Part 2 + keyframe at 3000ms in Part 2 (7000 - 4000)
      expect(part2.keyframes.any((k) => k.timestampMs == 0), isTrue);
      expect(part2.keyframes.any((k) => k.timestampMs == 3000), isTrue);

      // Continuity check: split boundary values match
      final part1EndKf = part1.keyframes.firstWhere((k) => k.timestampMs == 4000);
      final part2StartKf = part2.keyframes.firstWhere((k) => k.timestampMs == 0);
      expect(part1EndKf.posX, part2StartKf.posX);
      expect(part1EndKf.scale, part2StartKf.scale);
    });
  });

  group('CapCut Keyframe Widget UI Tests', () {
    testWidgets('EditorActionBar displays dynamic Add/Remove KF button and toggles state', (tester) async {
      final clip = VideoClipEntity(
        id: 'clip-ui',
        mediaPath: '/test/video.mp4',
        name: 'UI Clip',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 10000,
        keyframes: const [],
      );

      final project = ProjectEntity(
        id: 'proj-ui',
        title: 'UI Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
        videoClips: [clip],
      );

      final controller = EditorController(project: project);
      controller.setSelection(SelectionType.videoClip, 'clip-ui');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorActionBar(
              state: controller.state,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially at t=0 with no keyframes, button label is 'Keyframe'
      expect(find.text('Keyframe'), findsOneWidget);

      // Scroll to Keyframe button and tap to add a keyframe
      await tester.ensureVisible(find.text('Keyframe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keyframe'));
      await tester.pumpAndSettle();

      // Now clip has keyframe at t=0 and playhead is at 0 -> button shows 'Remove KF'
      expect(controller.state.project.videoClips.first.keyframes.length, 1);
      expect(controller.isAtKeyframe('clip-ui'), isTrue);

      // Re-pump with updated controller state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorActionBar(
              state: controller.state,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Remove KF'));
      await tester.pumpAndSettle();
      expect(find.text('Remove KF'), findsOneWidget);

      // Tap 'Remove KF' to toggle off
      await tester.tap(find.text('Remove KF'));
      await tester.pumpAndSettle();
      expect(controller.state.project.videoClips.first.keyframes.isEmpty, isTrue);
    });

    testWidgets('VideoTrackItem renders interactive diamond markers with tap-to-seek', (tester) async {
      final clipWithKf = VideoClipEntity(
        id: 'clip-track',
        mediaPath: '/test/video.mp4',
        name: 'Track Clip',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 10000,
        keyframes: const [
          KeyframeEntity(id: 'kf-1', timestampMs: 2000, posX: 10.0),
          KeyframeEntity(id: 'kf-2', timestampMs: 5000, posX: 50.0),
        ],
      );

      int tappedTimestamp = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                VideoTrackItem(
                  clip: clipWithKf,
                  pixelsPerSecond: 50.0,
                  isSelected: true,
                  currentPlayheadMs: 2000, // Near kf-1 (proximity glow active)
                  onKeyframeTap: (ts) => tappedTimestamp = ts,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the first diamond marker (ValueKey 'keyframe-marker-kf-1')
      final markerFinder = find.byKey(const ValueKey('keyframe-marker-kf-1'));
      expect(markerFinder, findsOneWidget);
      await tester.tap(markerFinder);
      expect(tappedTimestamp, 2000);
    });
  });
}

