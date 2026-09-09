import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/editor/presentation/utils/timeline_layout_helper.dart';
import 'package:procut/features/editor/presentation/widgets/multi_track_timeline.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/text_stickers/domain/entities/text_overlay_entity.dart';
import 'package:procut/features/text_stickers/presentation/widgets/sticker_picker_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Timeline Multi-Lane & Vertical Placement Tests', () {
    test('computeClipLanes assigns separate lanes to overlapping intervals', () {
      final clips = [
        const TextOverlayEntity(
          id: 'text_1',
          text: 'NEW CAPTION 1',
          timelineStartMs: 0,
          timelineEndMs: 3000,
        ),
        const TextOverlayEntity(
          id: 'text_2',
          text: 'NEW CAPTION 2',
          timelineStartMs: 1500, // Overlaps with text_1
          timelineEndMs: 4500,
        ),
        const TextOverlayEntity(
          id: 'text_3',
          text: 'NEW CAPTION 3',
          timelineStartMs: 3500, // Overlaps with text_2, but not text_1
          timelineEndMs: 6000,
        ),
      ];

      final lanes = TimelineLayoutHelper.computeClipLanes<TextOverlayEntity>(
        items: clips,
        getStart: (t) => t.timelineStartMs,
        getEnd: (t) => t.timelineEndMs,
        getId: (t) => t.id,
      );

      // text_1 and text_2 overlap, so they MUST be in different lanes
      expect(lanes['text_1'], isNot(equals(lanes['text_2'])));
      expect(lanes['text_1'], 0);
      expect(lanes['text_2'], 1);

      // text_3 starts at 3500 (after text_1 ends at 3000), so it can reuse lane 0
      expect(lanes['text_3'], 0);
    });

    test('computeClipLanes respects manual lane assignment', () {
      final clips = [
        const TextOverlayEntity(
          id: 'text_1',
          text: 'NEW CAPTION 1',
          timelineStartMs: 0,
          timelineEndMs: 3000,
        ),
        const TextOverlayEntity(
          id: 'text_2',
          text: 'NEW CAPTION 2',
          timelineStartMs: 5000, // Non-overlapping
          timelineEndMs: 8000,
        ),
      ];

      // User manually shifted text_2 to lane 2
      final manualLanes = {'text_2': 2};

      final lanes = TimelineLayoutHelper.computeClipLanes<TextOverlayEntity>(
        items: clips,
        getStart: (t) => t.timelineStartMs,
        getEnd: (t) => t.timelineEndMs,
        getId: (t) => t.id,
        manualLanes: manualLanes,
      );

      expect(lanes['text_1'], 0);
      expect(lanes['text_2'], 2);
    });

    test('calculateTrackHeight dynamically expands for multiple lanes', () {
      final lanes = {'c1': 0, 'c2': 1, 'c3': 2};
      final h = TimelineLayoutHelper.calculateTrackHeight(
        lanes: lanes,
        laneHeight: 34,
        laneGap: 4,
      );

      // 3 lanes * 34 + 2 gaps * 4 = 102 + 8 = 110
      expect(h, 110.0);
    });

    test('moveClipVerticalLane updates state.clipLanes', () {
      final project = ProjectEntity(
        id: 'p1',
        title: 'Project 1',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'main_1',
            mediaPath: 'video1.mp4',
            name: 'Main Clip 1',
            sourceDurationMs: 5000,
            timelineStartMs: 0,
            timelineEndMs: 5000,
            trimStartMs: 0,
            trimEndMs: 5000,
          ),
        ],
        textOverlays: const [
          TextOverlayEntity(
            id: 't1',
            text: 'Overlay 1',
            timelineStartMs: 0,
            timelineEndMs: 3000,
          ),
        ],
      );

      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(project).notifier);

      expect(container.read(editorControllerProvider(project)).clipLanes['t1'], isNull);

      controller.moveClipVerticalLane('t1', 1);
      expect(container.read(editorControllerProvider(project)).clipLanes['t1'], 1);

      controller.moveClipVerticalLane('t1', 1);
      expect(container.read(editorControllerProvider(project)).clipLanes['t1'], 2);

      controller.moveClipVerticalLane('t1', -1);
      expect(container.read(editorControllerProvider(project)).clipLanes['t1'], 1);
    });

    test('switchClipToEmptySpace moves overlapping clip to non-overlapping slot', () {
      final project = ProjectEntity(
        id: 'p1',
        title: 'Project 1',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'main_1',
            mediaPath: 'video1.mp4',
            name: 'Main',
            sourceDurationMs: 10000,
            timelineStartMs: 0,
            timelineEndMs: 10000,
            trimStartMs: 0,
            trimEndMs: 10000,
          ),
        ],
        textOverlays: const [
          TextOverlayEntity(
            id: 't1',
            text: 'First Text',
            timelineStartMs: 0,
            timelineEndMs: 3000,
          ),
          TextOverlayEntity(
            id: 't2',
            text: 'Second Text Overlapping',
            timelineStartMs: 1000, // Overlaps with t1
            timelineEndMs: 4000,
          ),
        ],
      );

      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(project).notifier);

      controller.switchClipToEmptySpace('t2');

      final updatedState = container.read(editorControllerProvider(project));
      final t2 = updatedState.project.textOverlays.firstWhere((t) => t.id == 't2');

      // t2 was moved to an empty slot >= t1.timelineEndMs (3000)
      expect(t2.timelineStartMs, greaterThanOrEqualTo(3000));
      expect(t2.timelineEndMs - t2.timelineStartMs, 3000); // Duration preserved
    });

    testWidgets('MultiTrackTimeline renders overlapping text clips on distinct vertical lanes (not on top of each other)', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final project = ProjectEntity(
        id: 'p1',
        title: 'Multi Lane UI Test',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'main_1',
            mediaPath: 'video.mp4',
            name: 'Main Video',
            sourceDurationMs: 10000,
            timelineStartMs: 0,
            timelineEndMs: 10000,
            trimStartMs: 0,
            trimEndMs: 10000,
          ),
        ],
        textOverlays: const [
          TextOverlayEntity(
            id: 't1',
            text: 'NEW CAPTION 1',
            timelineStartMs: 0,
            timelineEndMs: 4000,
          ),
          TextOverlayEntity(
            id: 't2',
            text: 'NEW CAPTION 2',
            timelineStartMs: 1000, // Starts while t1 is active
            timelineEndMs: 5000,
          ),
        ],
      );

      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(project).notifier);
      final state = container.read(editorControllerProvider(project));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 380,
              width: 500,
              child: MultiTrackTimeline(
                state: state,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Both text clips are rendered on screen
      final t1Finder = find.text('NEW CAPTION 1');
      final t2Finder = find.text('NEW CAPTION 2');

      expect(t1Finder, findsOneWidget);
      expect(t2Finder, findsOneWidget);

      // Verify that their top positions differ vertically so neither obscures the other
      final t1Top = tester.getTopLeft(t1Finder).dy;
      final t2Top = tester.getTopLeft(t2Finder).dy;

      // Because they overlap in time [0..4000] and [1000..5000], they MUST be in separate rows!
      expect((t1Top - t2Top).abs(), greaterThanOrEqualTo(30.0));
    });

    test('Dragging a clip horizontally stops at the edge of adjacent clip on the same lane', () {
      final project = ProjectEntity(
        id: 'p1',
        title: 'Clamping Test',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'main_1',
            mediaPath: 'video1.mp4',
            name: 'Main',
            sourceDurationMs: 15000,
            timelineStartMs: 0,
            timelineEndMs: 15000,
            trimStartMs: 0,
            trimEndMs: 15000,
          ),
        ],
        textOverlays: const [
          TextOverlayEntity(
            id: 't1',
            text: 'First Text',
            timelineStartMs: 0,
            timelineEndMs: 3000,
          ),
          TextOverlayEntity(
            id: 't2',
            text: 'Second Text',
            timelineStartMs: 4000,
            timelineEndMs: 7000,
          ),
          TextOverlayEntity(
            id: 't3',
            text: 'Third Text',
            timelineStartMs: 8000,
            timelineEndMs: 11000,
          ),
        ],
      );

      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(project).notifier);

      // Attempt to drag t2 to the left by 5000ms (500 pixels at 100pps)
      // It MUST stop at t1's right edge (3000ms), NOT overlap or go below 3000ms
      controller.moveTextTimelinePosition(textId: 't2', deltaPixels: -500.0, pixelsPerSecond: 100.0);
      var state = container.read(editorControllerProvider(project));
      var t2 = state.project.textOverlays.firstWhere((t) => t.id == 't2');
      expect(t2.timelineStartMs, 3000);
      expect(t2.timelineEndMs, 6000);

      // Attempt to drag t2 to the right by 8000ms (800 pixels at 100pps)
      // It MUST stop at t3's left edge (8000ms - 3000ms duration = 5000ms start)
      controller.moveTextTimelinePosition(textId: 't2', deltaPixels: 800.0, pixelsPerSecond: 100.0);
      state = container.read(editorControllerProvider(project));
      t2 = state.project.textOverlays.firstWhere((t) => t.id == 't2');
      expect(t2.timelineStartMs, 5000);
      expect(t2.timelineEndMs, 8000);
    });

    test('Project calculatedDurationMs extends to cover all clips and timeline includes padding', () {
      final project = ProjectEntity(
        id: 'p1',
        title: 'Long Project',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 15000, // Default duration
        videoClips: const [
          VideoClipEntity(
            id: 'main_1',
            mediaPath: 'video1.mp4',
            name: 'Main',
            sourceDurationMs: 15000,
            timelineStartMs: 0,
            timelineEndMs: 15000,
            trimStartMs: 0,
            trimEndMs: 15000,
          ),
        ],
        textOverlays: const [
          TextOverlayEntity(
            id: 't_far',
            text: 'Far text',
            timelineStartMs: 42000,
            timelineEndMs: 47000,
          ),
        ],
      );

      // calculatedDurationMs MUST be 47000ms, not cut off at 15000ms
      expect(project.calculatedDurationMs, 47000);
    });

    test('Multiple Overlays can be added at the exact same frame and stack one under the other like CapCut', () {
      final project = ProjectEntity(
        id: 'p_multi_overlay',
        title: 'Multi Overlay Project',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
        videoClips: const [
          VideoClipEntity(
            id: 'main_clip',
            mediaPath: 'main.mp4',
            name: 'Main Video',
            sourceDurationMs: 10000,
            timelineStartMs: 0,
            timelineEndMs: 10000,
            trimStartMs: 0,
            trimEndMs: 10000,
            isOverlay: false,
          ),
        ],
      );

      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(project).notifier);

      // Seek to 1500ms
      controller.seekTo(1500);

      // Add 1st overlay
      controller.addOverlayClip(
        mediaPath: 'overlay1.mp4',
        name: 'Overlay 1',
        durationMs: 4000,
      );

      var state = container.read(editorControllerProvider(project));
      final overlay1 = state.project.videoClips.firstWhere((c) => c.isOverlay && c.name == 'Overlay 1');
      expect(overlay1.timelineStartMs, 1500);

      // Seek back to 1500ms and add 2nd overlay at the EXACT same timestamp
      controller.seekTo(1500);
      controller.addOverlayClip(
        mediaPath: 'overlay2.mp4',
        name: 'Overlay 2',
        durationMs: 4000,
      );

      state = container.read(editorControllerProvider(project));
      final overlay2 = state.project.videoClips.firstWhere((c) => c.isOverlay && c.name == 'Overlay 2');
      expect(overlay2.timelineStartMs, 1500);
      expect(overlay2.id != overlay1.id, true);

      // Check that computeClipLanes stacks them into separate vertical lanes (Row 0 and Row 1)
      final overlayClips = state.project.videoClips.where((c) => c.isOverlay).toList();
      final lanes = TimelineLayoutHelper.computeClipLanes<VideoClipEntity>(
        items: overlayClips,
        getStart: (c) => c.timelineStartMs,
        getEnd: (c) => c.timelineEndMs,
        getId: (c) => c.id,
      );

      expect(lanes[overlay1.id], 0);
      expect(lanes[overlay2.id], 1);

      // Add 3rd overlay at 1500ms
      controller.seekTo(1500);
      controller.addOverlayClip(
        mediaPath: 'overlay3.mp4',
        name: 'Overlay 3',
        durationMs: 4000,
      );

      state = container.read(editorControllerProvider(project));
      final overlay3 = state.project.videoClips.firstWhere((c) => c.isOverlay && c.name == 'Overlay 3');
      expect(overlay3.timelineStartMs, 1500);

      final allOverlays = state.project.videoClips.where((c) => c.isOverlay).toList();
      final updatedLanes = TimelineLayoutHelper.computeClipLanes<VideoClipEntity>(
        items: allOverlays,
        getStart: (c) => c.timelineStartMs,
        getEnd: (c) => c.timelineEndMs,
        getId: (c) => c.id,
      );
      expect(updatedLanes[overlay1.id], 0);
      expect(updatedLanes[overlay2.id], 1);
      expect(updatedLanes[overlay3.id], 2);
    });

    test('Multiple Text Overlays can be added at the same frame and stack one under the other with staggered canvas posY', () {
      final project = ProjectEntity(
        id: 'p_multi_text',
        title: 'Multi Text Project',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
      );

      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(project).notifier);

      controller.seekTo(2000);

      // Add Text 1
      controller.addTextOverlay(text: 'Title Line 1');
      var state = container.read(editorControllerProvider(project));
      final t1 = state.project.textOverlays[0];
      expect(t1.timelineStartMs, 2000);
      expect(t1.posY, 0.5);

      // Add Text 2 at same frame
      controller.seekTo(2000);
      controller.addTextOverlay(text: 'Subtitle Line 2');
      state = container.read(editorControllerProvider(project));
      final t2 = state.project.textOverlays[1];
      expect(t2.timelineStartMs, 2000);
      expect(t2.posY, closeTo(0.58, 0.01)); // Staggered vertical position on canvas

      // Add Text 3 at same frame
      controller.seekTo(2000);
      controller.addTextOverlay(text: 'Callout Line 3');
      state = container.read(editorControllerProvider(project));
      final t3 = state.project.textOverlays[2];
      expect(t3.timelineStartMs, 2000);
      expect(t3.posY, closeTo(0.66, 0.01));

      // Multi-lane timeline automatically gives each text an independent lane
      final textLanes = TimelineLayoutHelper.computeClipLanes<TextOverlayEntity>(
        items: state.project.textOverlays,
        getStart: (t) => t.timelineStartMs,
        getEnd: (t) => t.timelineEndMs,
        getId: (t) => t.id,
      );
      expect(textLanes[t1.id], 0);
      expect(textLanes[t2.id], 1);
      expect(textLanes[t3.id], 2);
    });

    test('Dragging a main clip vertically down to overlay converts it without overlapping existing overlay clips', () {
      final project = ProjectEntity(
        id: 'p_vert_drag',
        title: 'Vertical Drag Project',
        aspectRatio: AspectRatioType.ratio9_16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
        videoClips: const [
          VideoClipEntity(
            id: 'main_1',
            mediaPath: 'main1.mp4',
            name: 'Main Clip 1',
            sourceDurationMs: 5000,
            timelineStartMs: 0,
            timelineEndMs: 5000,
            trimStartMs: 0,
            trimEndMs: 5000,
            isOverlay: false,
          ),
          VideoClipEntity(
            id: 'main_2',
            mediaPath: 'main2.mp4',
            name: 'Main Clip 2',
            sourceDurationMs: 5000,
            timelineStartMs: 5000,
            timelineEndMs: 10000,
            trimStartMs: 0,
            trimEndMs: 5000,
            isOverlay: false,
          ),
          VideoClipEntity(
            id: 'overlay_existing',
            mediaPath: 'overlay1.mp4',
            name: 'Overlay 1',
            sourceDurationMs: 4000,
            timelineStartMs: 0,
            timelineEndMs: 4000,
            trimStartMs: 0,
            trimEndMs: 4000,
            isOverlay: true,
          ),
        ],
      );

      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(project).notifier);

      // Move main_1 vertically down to Overlay track
      controller.moveClipToTrack(clipId: 'main_1', toOverlay: true);

      var state = container.read(editorControllerProvider(project));
      final movedToOverlay = state.project.videoClips.firstWhere((c) => c.id == 'main_1');
      expect(movedToOverlay.isOverlay, true);

      // The remaining main track clip rippled flush to start at 0ms
      final remainingMain = state.project.videoClips.firstWhere((c) => c.id == 'main_2');
      expect(remainingMain.isOverlay, false);
      expect(remainingMain.timelineStartMs, 0);
      expect(remainingMain.timelineEndMs, 5000);

      // Moving back to Main Track inserts cleanly as an individual clip
      controller.moveClipToTrack(clipId: 'main_1', toOverlay: false, targetTimelineStartMs: 5000);
      state = container.read(editorControllerProvider(project));
      final backToMain = state.project.videoClips.firstWhere((c) => c.id == 'main_1');
      expect(backToMain.isOverlay, false);
      expect(backToMain.timelineStartMs, 5000);
      expect(backToMain.timelineEndMs, 10000);
    });

    testWidgets('StickerPickerSheet renders iOS stickers & Memojis and handles selection', (tester) async {
      String? selectedKey;
      String? selectedName;
      String? selectedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StickerPickerSheet(
              onStickerSelected: (key, name, emoji) {
                selectedKey = key;
                selectedName = name;
                selectedEmoji = emoji;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check iOS Stickers header
      expect(find.text('iOS Stickers & Memojis'), findsOneWidget);
      expect(find.text('🍏 iOS Memojis'), findsOneWidget);
      expect(find.text('🔥 Expressions'), findsOneWidget);
      expect(find.text('Heart Hands'), findsOneWidget);

      // Tap an iOS sticker
      await tester.tap(find.text('Heart Hands'));
      await tester.pumpAndSettle();

      expect(selectedKey, 'ios_heart_hands');
      expect(selectedName, 'Heart Hands');
      expect(selectedEmoji, '🫶');
    });
  });
}


