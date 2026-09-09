import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/editor/presentation/widgets/clip_volume_sheet.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

void main() {
  group('Video Clip Audio & Volume Control Tests', () {
    late ProjectEntity initialProject;
    late VideoClipEntity clip1;
    late VideoClipEntity clip2;

    setUp(() {
      clip1 = VideoClipEntity(
        id: 'clip_1',
        name: 'Video 1',
        mediaPath: 'assets/branding/demo_vid1.mp4',
        sourceDurationMs: 5000,
        timelineStartMs: 0,
        timelineEndMs: 5000,
        trimStartMs: 0,
        trimEndMs: 5000,
      );

      clip2 = VideoClipEntity(
        id: 'clip_2',
        name: 'Video 2',
        mediaPath: 'assets/branding/demo_vid2.mp4',
        sourceDurationMs: 6000,
        timelineStartMs: 5000,
        timelineEndMs: 11000,
        trimStartMs: 0,
        trimEndMs: 6000,
      );

      initialProject = ProjectEntity(
        id: 'test_project',
        title: 'Audio Test Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 11000,
        videoClips: [clip1, clip2],
      );
    });

    test('Default video clip keeps original audio unchanged (volume=1.0, isMuted=false)', () {
      expect(clip1.volume, 1.0);
      expect(clip1.isMuted, false);
      expect(clip1.effectiveVolume, 1.0);

      expect(clip2.volume, 1.0);
      expect(clip2.isMuted, false);
      expect(clip2.effectiveVolume, 1.0);
    });

    test('Volume adjustment affects only the selected video clip', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(initialProject).notifier);

      // Adjust volume of clip 1 to 1.5 (150% boost)
      controller.setClipVolume('clip_1', 1.5);

      final state = container.read(editorControllerProvider(initialProject));
      final updatedClip1 = state.project.videoClips.firstWhere((c) => c.id == 'clip_1');
      final updatedClip2 = state.project.videoClips.firstWhere((c) => c.id == 'clip_2');

      expect(updatedClip1.volume, 1.5);
      expect(updatedClip1.isMuted, false);
      expect(updatedClip1.effectiveVolume, 1.5);

      // Clip 2 remains completely unchanged at 1.0
      expect(updatedClip2.volume, 1.0);
      expect(updatedClip2.isMuted, false);
      expect(updatedClip2.effectiveVolume, 1.0);
    });

    test('Muting affects only the selected video clip', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(initialProject).notifier);

      // Mute clip 1
      controller.setClipMute('clip_1', true);

      final state = container.read(editorControllerProvider(initialProject));
      final updatedClip1 = state.project.videoClips.firstWhere((c) => c.id == 'clip_1');
      final updatedClip2 = state.project.videoClips.firstWhere((c) => c.id == 'clip_2');

      expect(updatedClip1.isMuted, true);
      expect(updatedClip1.effectiveVolume, 0.0);

      // Clip 2 remains completely unmuted
      expect(updatedClip2.isMuted, false);
      expect(updatedClip2.effectiveVolume, 1.0);
    });

    test('Restoring volume resets to 1.0 and unmutes only selected clip', () {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(initialProject).notifier);

      // Mute clip 1 and reduce volume
      controller.setClipVolume('clip_1', 0.2);
      controller.setClipMute('clip_1', true);

      // Reset volume
      controller.resetClipVolume('clip_1');

      final state = container.read(editorControllerProvider(initialProject));
      final restoredClip1 = state.project.videoClips.firstWhere((c) => c.id == 'clip_1');

      expect(restoredClip1.volume, 1.0);
      expect(restoredClip1.isMuted, false);
      expect(restoredClip1.effectiveVolume, 1.0);
    });

    test('Extracting audio adds separate audio clip without muting or changing original video clip', () async {
      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(initialProject).notifier);

      await controller.extractAudioFromClip('clip_1');

      final state = container.read(editorControllerProvider(initialProject));
      final c1 = state.project.videoClips.firstWhere((c) => c.id == 'clip_1');

      // Original video clip must NOT be muted and volume remains 1.0
      expect(c1.isMuted, false);
      expect(c1.volume, 1.0);
      expect(c1.effectiveVolume, 1.0);

      // Extracted audio must be added as a separate audio clip on audio track
      expect(state.project.audioClips.length, 1);
      final extracted = state.project.audioClips.first;
      expect(extracted.title, contains('Video 1'));
      expect(extracted.timelineStartMs, c1.timelineStartMs);
      expect(extracted.waveformSamples.isNotEmpty, true);
    });

    test('ProjectModel JSON serialization preserves volume and isMuted', () {
      final modifiedClip = clip1.copyWith(volume: 1.8, isMuted: true);
      final project = initialProject.copyWith(videoClips: [modifiedClip, clip2]);

      final json = ProjectModel.toJson(project);
      final deserialized = ProjectModel.fromJson(json);

      expect(deserialized.videoClips.first.volume, 1.8);
      expect(deserialized.videoClips.first.isMuted, true);
      expect(deserialized.videoClips.first.effectiveVolume, 0.0);

      expect(deserialized.videoClips[1].volume, 1.0);
      expect(deserialized.videoClips[1].isMuted, false);
      expect(deserialized.videoClips[1].effectiveVolume, 1.0);
    });

    testWidgets('ClipVolumeSheet renders slider, preset buttons, and restore button', (tester) async {
      double changedVolume = 1.0;
      bool changedMute = false;
      bool resetCalled = false;
      bool extractCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClipVolumeSheet(
              clip: clip1,
              onVolumeChanged: (v) => changedVolume = v,
              onMuteChanged: (m) => changedMute = m,
              onResetVolume: () => resetCalled = true,
              onExtractAudio: () => extractCalled = true,
            ),
          ),
        ),
      );

      // Verify header and UI elements
      expect(find.text('Clip Volume'), findsOneWidget);
      expect(find.text('Video 1'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Volume Level'), findsOneWidget);
      expect(find.text('100% (Original)'), findsOneWidget);

      // Verify preset buttons
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('150%'), findsOneWidget);
      expect(find.text('200%'), findsNWidgets(2));

      // Verify Extract Audio card
      expect(find.text('Extract Audio to Separate Track'), findsOneWidget);

      // Tap 150% button
      await tester.tap(find.text('150%'));
      await tester.pump();
      expect(changedVolume, 1.5);
      expect(find.text('150% (Boosted)'), findsOneWidget);

      // Tap Mute button
      await tester.tap(find.text('Mute'));
      await tester.pump();
      expect(changedMute, true);
      expect(find.text('Muted (0%)'), findsOneWidget);

      // Tap Restore button
      await tester.tap(find.text('Restore'));
      await tester.pump();
      expect(resetCalled, true);
      expect(find.text('100% (Original)'), findsOneWidget);

      // Tap Extract Audio button
      await tester.tap(find.text('Extract Audio to Separate Track'));
      await tester.pump();
      expect(extractCalled, true);
    });
  });
}
