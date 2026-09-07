import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/timeline_state.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/editor/presentation/providers/editor_controller.dart';
import 'package:looma/features/editor/presentation/widgets/multi_track_timeline.dart';
import 'package:looma/features/filters_effects/domain/entities/effect_clip_entity.dart';
import 'package:flutter/services.dart';
import 'package:looma/features/filters_effects/domain/entities/video_effect_type.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/text_overlay_entity.dart';

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async => <String, dynamic>{},
    );
  });

  group('Timeline Scrolling, Bottom Clearance & Collision Tests', () {
    late ProjectEntity testProject;
    late VideoClipEntity mainClip1;
    late VideoClipEntity mainClip2;
    late VideoClipEntity overlayClip1;
    late VideoClipEntity overlayClip2;
    late AudioClipEntity audioClip1;
    late AudioClipEntity audioClip2;

    setUp(() {
      mainClip1 = VideoClipEntity(
        id: 'main_1',
        name: 'Main Clip 1',
        mediaPath: 'assets/test1.mp4',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 4000,
        trimStartMs: 0,
        trimEndMs: 4000,
        isOverlay: false,
      );

      mainClip2 = VideoClipEntity(
        id: 'main_2',
        name: 'Main Clip 2',
        mediaPath: 'assets/test2.mp4',
        sourceDurationMs: 5000,
        timelineStartMs: 4000,
        timelineEndMs: 9000,
        trimStartMs: 0,
        trimEndMs: 5000,
        isOverlay: false,
      );

      overlayClip1 = VideoClipEntity(
        id: 'overlay_1',
        name: 'Overlay 1',
        mediaPath: 'assets/test_overlay1.mp4',
        sourceDurationMs: 3000,
        timelineStartMs: 1000,
        timelineEndMs: 4000,
        trimStartMs: 0,
        trimEndMs: 3000,
        isOverlay: true,
      );

      overlayClip2 = VideoClipEntity(
        id: 'overlay_2',
        name: 'Overlay 2',
        mediaPath: 'assets/test_overlay2.mp4',
        sourceDurationMs: 3000,
        timelineStartMs: 6000,
        timelineEndMs: 9000,
        trimStartMs: 0,
        trimEndMs: 3000,
        isOverlay: true,
      );

      audioClip1 = AudioClipEntity(
        id: 'audio_1',
        title: 'Music 1',
        mediaPath: 'assets/music1.mp3',
        category: AudioCategory.music,
        timelineStartMs: 0,
        timelineEndMs: 3000,
        trimStartMs: 0,
        trimEndMs: 3000,
      );

      audioClip2 = AudioClipEntity(
        id: 'audio_2',
        title: 'Music 2',
        mediaPath: 'assets/music2.mp3',
        category: AudioCategory.music,
        timelineStartMs: 5000,
        timelineEndMs: 8000,
        trimStartMs: 0,
        trimEndMs: 3000,
      );

      testProject = ProjectEntity(
        id: 'timeline_test_proj',
        title: 'Timeline Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
        videoClips: [mainClip1, mainClip2, overlayClip1, overlayClip2],
        audioClips: [audioClip1, audioClip2],
        textOverlays: [
          TextOverlayEntity(
            id: 'txt_1',
            text: 'Sample Subtitle',
            timelineStartMs: 500,
            timelineEndMs: 3000,
          ),
        ],
        effectClips: [
          EffectClipEntity(
            id: 'eff_1',
            effectType: VideoEffectType.glitch,
            timelineStartMs: 2000,
            durationMs: 2000,
          ),
        ],
      );
    });

    testWidgets('MultiTrackTimeline renders on small screen without 24px bottom overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(testProject).notifier);
      final state = container.read(editorControllerProvider(testProject));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 280, // Small height to test overflow immunity
              child: MultiTrackTimeline(
                state: state,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No Flutter overflow error occurs
      expect(tester.takeException(), isNull);

      // Verify the vertical Scrollbar is rendered
      expect(find.byType(Scrollbar), findsOneWidget);

      // Verify Scrollable exists in both vertical and horizontal directions
      final scrollables = find.byType(Scrollable);
      expect(scrollables, findsWidgets);
    });

    test('Overlay clip collision: cannot drag overlay clip to overlap adjacent overlay clip', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(testProject).notifier);

      // overlayClip1 is at [1000, 4000]. overlayClip2 is at [6000, 9000].
      // If we move overlayClip1 forward by 5000ms (5000 * 50px/s = 250px),
      // it would land at 6000ms, which touches overlayClip2.
      // If we try to move it by 8000ms, it should be clamped so its end does not exceed 6000ms (i.e. start <= 3000ms).
      controller.moveVideoClipPosition(
        clipId: 'overlay_1',
        deltaPixels: 400.0, // 400px / 50pps = 8000ms
        pixelsPerSecond: 50.0,
      );

      final state = container.read(editorControllerProvider(testProject));
      final updatedOverlay1 = state.project.videoClips.firstWhere((c) => c.id == 'overlay_1');

      // The duration is 3000ms. Since overlayClip2 starts at 6000ms,
      // max allowed start is 6000 - 3000 = 3000ms!
      expect(updatedOverlay1.timelineStartMs, lessThanOrEqualTo(3000));
      expect(updatedOverlay1.timelineEndMs, lessThanOrEqualTo(6000));
    });

    test('moveClipToTrack moves clip vertically between Main Track and Overlay Track', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(testProject).notifier);

      // Initially mainClip2 (id: 'main_2') is on Main Track
      expect(container.read(editorControllerProvider(testProject)).project.videoClips.firstWhere((c) => c.id == 'main_2').isOverlay, false);

      // Move mainClip2 to Overlay track
      controller.moveClipToTrack(clipId: 'main_2', toOverlay: true);

      var state = container.read(editorControllerProvider(testProject));
      var movedClip = state.project.videoClips.firstWhere((c) => c.id == 'main_2');
      expect(movedClip.isOverlay, true);

      // Move it back to Main Track
      controller.moveClipToTrack(clipId: 'main_2', toOverlay: false);

      state = container.read(editorControllerProvider(testProject));
      movedClip = state.project.videoClips.firstWhere((c) => c.id == 'main_2');
      expect(movedClip.isOverlay, false);

      // Remaining main clips are recalculated sequentially without gap or overlap
      final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
      expect(mainClips[0].timelineStartMs, 0);
      expect(mainClips[1].timelineStartMs, mainClips[0].timelineEndMs);
    });

    test('switchClipToEmptySpace moves overlay clip to an empty time slot without overlapping', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(testProject).notifier);

      // overlayClip1 is at [1000, 4000]. overlayClip2 is at [6000, 9000].
      // Switching overlayClip1 to empty space should place it after 9000ms where space is clean.
      controller.switchClipToEmptySpace('overlay_1');

      final state = container.read(editorControllerProvider(testProject));
      final switched = state.project.videoClips.firstWhere((c) => c.id == 'overlay_1');

      // The new position must not overlap overlayClip2 [6000, 9000]
      final overlapsOther = (switched.timelineStartMs < 9000 && switched.timelineEndMs > 6000);
      expect(overlapsOther, false);
      expect(switched.timelineStartMs, greaterThanOrEqualTo(9000));
    });

    test('Audio clip collision: moving audio clip cannot overlap adjacent audio clip', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(testProject).notifier);

      // audioClip1 is at [0, 3000]. audioClip2 is at [5000, 8000].
      // Moving audioClip1 forward by 8000ms should clamp so it doesn't overlap audioClip2.
      controller.moveAudioTimelinePosition(
        clipId: 'audio_1',
        deltaPixels: 400.0, // 400px / 50pps = 8000ms
        pixelsPerSecond: 50.0,
      );

      final state = container.read(editorControllerProvider(testProject));
      final movedAudio1 = state.project.audioClips.firstWhere((a) => a.id == 'audio_1');

      // Max allowed start is 5000 - 3000 = 2000ms!
      expect(movedAudio1.timelineStartMs, lessThanOrEqualTo(2000));
      expect(movedAudio1.timelineEndMs, lessThanOrEqualTo(5000));
    });

    test('Adding multiple text clips at the same playhead creates separate individual clips at current frame like CapCut', () {
      final cleanProject = testProject.copyWith(textOverlays: []);
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(cleanProject).notifier);

      // Seek playhead to 0ms
      controller.seekTo(0);

      // Add first text clip
      controller.addTextOverlay(text: 'First Text');
      var state = container.read(editorControllerProvider(cleanProject));
      final text1 = state.project.textOverlays.last;
      expect(text1.text, 'First Text');
      expect(text1.timelineStartMs, 0);

      // Playhead is at 0ms, add second text clip
      controller.seekTo(0);
      controller.addTextOverlay(text: 'Second Text');
      state = container.read(editorControllerProvider(cleanProject));
      final text2 = state.project.textOverlays.last;
      expect(text2.text, 'Second Text');

      // Second text is created at current playhead (frame) with unique ID and staggered posY for multi-lane stacking
      expect(text2.timelineStartMs, 0);
      expect(text2.id != text1.id, true);
      expect(text2.posY != text1.posY, true);

      // Add a third text clip without moving playhead
      controller.addTextOverlay(text: 'Third Text');
      state = container.read(editorControllerProvider(cleanProject));
      final text3 = state.project.textOverlays.last;
      expect(text3.text, 'Third Text');
      expect(text3.timelineStartMs, 0);
      expect(text3.id != text2.id, true);
    });

    test('Adding stickers, effects, animations and audio sequentially creates separate individual clips at current playhead', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(testProject).notifier);

      // 1. Stickers
      controller.seekTo(0);
      controller.addStickerOverlay(stickerKey: 'fire', stickerName: 'Fire', assetEmojiOrPath: '🔥');
      var state = container.read(editorControllerProvider(testProject));
      final sticker1 = state.project.stickerOverlays.last;

      controller.seekTo(0);
      controller.addStickerOverlay(stickerKey: 'star', stickerName: 'Star', assetEmojiOrPath: '⭐');
      state = container.read(editorControllerProvider(testProject));
      final sticker2 = state.project.stickerOverlays.last;
      expect(sticker2.timelineStartMs, 0);
      expect(sticker2.id != sticker1.id, true);

      // 2. Effects
      controller.seekTo(0);
      controller.addEffectClip(effectType: VideoEffectType.rgbSplit);
      state = container.read(editorControllerProvider(testProject));
      final eff1 = state.project.effectClips.last;

      controller.seekTo(0);
      controller.addEffectClip(effectType: VideoEffectType.explosion);
      state = container.read(editorControllerProvider(testProject));
      final eff2 = state.project.effectClips.last;
      expect(eff2.timelineStartMs, 0);
      expect(eff2.id != eff1.id, true);

      // 3. Audio clips
      controller.seekTo(0);
      final newAudio1 = AudioClipEntity(
        id: 'aud_new_1',
        title: 'New Track 1',
        mediaPath: 'assets/new1.mp3',
        category: AudioCategory.music,
        timelineStartMs: 0,
        timelineEndMs: 3000,
        trimEndMs: 3000,
      );
      controller.addAudioClip(newAudio1);
      state = container.read(editorControllerProvider(testProject));
      final addedAud1 = state.project.audioClips.firstWhere((a) => a.id == 'aud_new_1');

      final newAudio2 = AudioClipEntity(
        id: 'aud_new_2',
        title: 'New Track 2',
        mediaPath: 'assets/new2.mp3',
        category: AudioCategory.music,
        timelineStartMs: 0,
        timelineEndMs: 3000,
        trimEndMs: 3000,
      );
      controller.addAudioClip(newAudio2);
      state = container.read(editorControllerProvider(testProject));
      final addedAud2 = state.project.audioClips.firstWhere((a) => a.id == 'aud_new_2');
      expect(addedAud2.timelineStartMs, greaterThanOrEqualTo(addedAud1.timelineEndMs));
    });

    test('Expanding real-time duration of main clip extends duration and ripples subsequent clips', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(testProject).notifier);

      // Select mainClip1 (duration was 4000ms: [0, 4000], mainClip2 was [4000, 9000])
      controller.setSelection(SelectionType.videoClip, 'main_1');

      // Drag right handle by +100px (at 50pps, +2000ms)
      controller.updateClipDurationByDrag(
        clipId: 'main_1',
        deltaPixels: 100.0,
        pixelsPerSecond: 50.0,
        isLeftHandle: false,
      );

      var state = container.read(editorControllerProvider(testProject));
      var updatedClip1 = state.project.videoClips.firstWhere((c) => c.id == 'main_1');
      var updatedClip2 = state.project.videoClips.firstWhere((c) => c.id == 'main_2');

      // main_1 expanded from 4000ms to 6000ms in real time
      expect(updatedClip1.effectiveDurationMs, 6000);
      expect(updatedClip1.timelineEndMs, 6000);

      // Subsequent main clip rippled forward seamlessly without overlap
      expect(updatedClip2.timelineStartMs, 6000);
      expect(updatedClip2.timelineEndMs, 11000);

      // Now trim inward with left handle on main_2 (deltaPixels: +50px = +1000ms trim in)
      controller.updateClipDurationByDrag(
        clipId: 'main_2',
        deltaPixels: 50.0,
        pixelsPerSecond: 50.0,
        isLeftHandle: true,
      );

      state = container.read(editorControllerProvider(testProject));
      updatedClip2 = state.project.videoClips.firstWhere((c) => c.id == 'main_2');
      expect(updatedClip2.trimStartMs, 1000);
    });

    testWidgets('Horizontal drag when no clip is selected smoothly scrolls timeline without moving clips', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 350,
                width: 400,
                child: Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(editorControllerProvider(testProject));
                    final controller = ref.read(editorControllerProvider(testProject).notifier);
                    return MultiTrackTimeline(
                      state: state,
                      controller: controller,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the horizontal Scrollable
      final horizontalScrollable = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScrollable, findsOneWidget);

      // Perform horizontal scroll drag across the track
      final initialOffset = tester.getTopLeft(find.text('Main Clip 1'));
      await tester.drag(horizontalScrollable, const Offset(-100, 0));
      await tester.pumpAndSettle();

      final postScrollOffset = tester.getTopLeft(find.text('Main Clip 1'));
      // The clip scrolled smoothly to the left on the screen
      expect(postScrollOffset.dx, lessThan(initialOffset.dx));

      // But clip's logical timeline positions in state did NOT change!
      final currentState = container.read(editorControllerProvider(testProject));
      expect(currentState.project.videoClips.firstWhere((c) => c.id == 'main_1').timelineStartMs, 0);
      expect(currentState.project.videoClips.firstWhere((c) => c.id == 'main_2').timelineStartMs, 4000);
    });
  });
}
