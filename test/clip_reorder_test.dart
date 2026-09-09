import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/editor/presentation/widgets/reorder_clips_sheet.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

void main() {
  group('Clip Reorder & Order Changing Tests', () {
    late ProjectEntity initialProject;
    late VideoClipEntity clipA;
    late VideoClipEntity clipB;
    late VideoClipEntity clipC;

    setUp(() {
      clipA = VideoClipEntity(
        id: 'clip_A',
        name: 'Scene 1',
        mediaPath: 'assets/branding/demo_vid1.mp4',
        sourceDurationMs: 4000,
        timelineStartMs: 0,
        timelineEndMs: 4000,
        trimStartMs: 0,
        trimEndMs: 4000,
      );

      clipB = VideoClipEntity(
        id: 'clip_B',
        name: 'Scene 2',
        mediaPath: 'assets/branding/demo_vid2.mp4',
        sourceDurationMs: 6000,
        timelineStartMs: 4000,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 6000,
      );

      clipC = VideoClipEntity(
        id: 'clip_C',
        name: 'Scene 3',
        mediaPath: 'assets/branding/demo_vid3.mp4',
        sourceDurationMs: 5000,
        timelineStartMs: 10000,
        timelineEndMs: 15000,
        trimStartMs: 0,
        trimEndMs: 5000,
      );

      initialProject = ProjectEntity(
        id: 'test_project',
        title: 'Reorder Test Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 15000,
        videoClips: [clipA, clipB, clipC],
      );
    });

    test('reorderVideoClips moves clip from index 0 to index 2 and recalculates timeline sequentially', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(initialProject).notifier);

      // Move clipA (index 0) to end (index 2) -> Order becomes [B, C, A]
      controller.reorderVideoClips(0, 2);

      final state = container.read(editorControllerProvider(initialProject));
      final clips = state.project.videoClips;

      expect(clips.length, 3);
      expect(clips[0].id, 'clip_B');
      expect(clips[1].id, 'clip_C');
      expect(clips[2].id, 'clip_A');

      // Check sequential timeline offsets
      // Clip B: 6000ms duration -> [0, 6000]
      expect(clips[0].timelineStartMs, 0);
      expect(clips[0].timelineEndMs, 6000);

      // Clip C: 5000ms duration -> [6000, 11000]
      expect(clips[1].timelineStartMs, 6000);
      expect(clips[1].timelineEndMs, 11000);

      // Clip A: 4000ms duration -> [11000, 15000]
      expect(clips[2].timelineStartMs, 11000);
      expect(clips[2].timelineEndMs, 15000);

      expect(state.project.durationMs, 15000);
    });

    test('moveClipRight moves clip one step to the right', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(initialProject).notifier);

      // Move clipA right -> Order becomes [B, A, C]
      controller.moveClipRight('clip_A');

      final state = container.read(editorControllerProvider(initialProject));
      final clips = state.project.videoClips;

      expect(clips[0].id, 'clip_B');
      expect(clips[1].id, 'clip_A');
      expect(clips[2].id, 'clip_C');

      expect(clips[0].timelineStartMs, 0);
      expect(clips[0].timelineEndMs, 6000);

      expect(clips[1].timelineStartMs, 6000);
      expect(clips[1].timelineEndMs, 10000);

      expect(clips[2].timelineStartMs, 10000);
      expect(clips[2].timelineEndMs, 15000);
    });

    test('moveClipLeft moves clip one step to the left', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(initialProject).notifier);

      // Move clipC left -> Order becomes [A, C, B]
      controller.moveClipLeft('clip_C');

      final state = container.read(editorControllerProvider(initialProject));
      final clips = state.project.videoClips;

      expect(clips[0].id, 'clip_A');
      expect(clips[1].id, 'clip_C');
      expect(clips[2].id, 'clip_B');

      expect(clips[0].timelineStartMs, 0);
      expect(clips[0].timelineEndMs, 4000);

      expect(clips[1].timelineStartMs, 4000);
      expect(clips[1].timelineEndMs, 9000);

      expect(clips[2].timelineStartMs, 9000);
      expect(clips[2].timelineEndMs, 15000);
    });

    test('moveClipToStart and moveClipToEnd move clips to extremes', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(initialProject).notifier);

      // Move clipC to start -> [C, A, B]
      controller.moveClipToStart('clip_C');

      var state = container.read(editorControllerProvider(initialProject));
      expect(state.project.videoClips[0].id, 'clip_C');
      expect(state.project.videoClips[1].id, 'clip_A');
      expect(state.project.videoClips[2].id, 'clip_B');

      // Move clipC to end -> [A, B, C]
      controller.moveClipToEnd('clip_C');

      state = container.read(editorControllerProvider(initialProject));
      expect(state.project.videoClips[0].id, 'clip_A');
      expect(state.project.videoClips[1].id, 'clip_B');
      expect(state.project.videoClips[2].id, 'clip_C');
    });

    testWidgets('ReorderClipsSheet renders all clips with reorder tools', (tester) async {
      final controller = EditorController(project: initialProject);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderClipsSheet(
              clips: [clipA, clipB, clipC],
              controller: controller,
              selectedClipId: 'clip_A',
            ),
          ),
        ),
      );

      // Check header
      expect(find.text('Reorder Clips'), findsOneWidget);
      expect(find.textContaining('3 clips'), findsOneWidget);

      // Check clip names
      expect(find.text('Scene 1'), findsOneWidget);
      expect(find.text('Scene 2'), findsOneWidget);
      expect(find.text('Scene 3'), findsOneWidget);

      // Check position badges
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);

      // Tap Move Down on Scene 1
      final moveDownButton = find.byKey(const ValueKey('move_down_clip_A'));
      expect(moveDownButton, findsOneWidget);
      await tester.ensureVisible(moveDownButton);
      await tester.tap(moveDownButton);
      await tester.pumpAndSettle();

      final state = controller.state;
      expect(state.project.videoClips[0].id, 'clip_B');
      expect(state.project.videoClips[1].id, 'clip_A');
      expect(state.project.videoClips[2].id, 'clip_C');
    });
  });
}
