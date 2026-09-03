import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/animation_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/clip_animation_type.dart';
import 'package:looma/features/editor/domain/entities/timeline_state.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/editor/presentation/providers/editor_controller.dart';
import 'package:looma/features/editor/presentation/widgets/animation_track_item.dart';
import 'package:looma/features/editor/presentation/widgets/multi_track_timeline.dart';
import 'package:looma/features/filters_effects/domain/entities/effect_clip_entity.dart';
import 'package:looma/features/filters_effects/domain/entities/video_effect_type.dart';
import 'package:looma/features/filters_effects/presentation/widgets/effect_track_item.dart';
import 'package:looma/features/projects/data/models/project_model.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/sticker_overlay_entity.dart';
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
  });

  group('8 Independent Timeline Clips and Tracks Tests', () {
    late ProjectEntity baseProject;

    setUp(() {
      final videoClip = const VideoClipEntity(
        id: 'video-main-1',
        mediaPath: '/path/main_video.mp4',
        name: 'Main Video',
        sourceDurationMs: 12000,
        timelineStartMs: 0,
        timelineEndMs: 12000,
        trimStartMs: 0,
        trimEndMs: 12000,
      );

      final photoClip = const VideoClipEntity(
        id: 'photo-main-2',
        mediaPath: '/path/photo.jpg',
        name: 'Cover Photo',
        sourceDurationMs: 4000,
        timelineStartMs: 12000,
        timelineEndMs: 16000,
        trimStartMs: 0,
        trimEndMs: 4000,
      );

      final overlayClip = const VideoClipEntity(
        id: 'overlay-pip-1',
        mediaPath: '/path/pip_overlay.mp4',
        name: 'PIP Video',
        sourceDurationMs: 6000,
        timelineStartMs: 2000,
        timelineEndMs: 8000,
        trimStartMs: 0,
        trimEndMs: 6000,
        isOverlay: true,
      );

      final textOverlay = const TextOverlayEntity(
        id: 'text-track-1',
        text: 'Looma Magic',
        timelineStartMs: 1000,
        timelineEndMs: 5000,
      );

      final stickerOverlay = const StickerOverlayEntity(
        id: 'sticker-track-1',
        stickerKey: 'sparkle',
        stickerName: 'Sparkle',
        assetEmojiOrPath: '✨',
        timelineStartMs: 3000,
        timelineEndMs: 7000,
      );

      final effectClip = const EffectClipEntity(
        id: 'effect-track-1',
        effectType: VideoEffectType.explosion,
        timelineStartMs: 1500,
        durationMs: 3000,
      );

      final animationClip = const AnimationClipEntity(
        id: 'animation-track-1',
        name: 'Pulse',
        animationType: ClipAnimationCombo.pulse,
        timelineStartMs: 2500,
        durationMs: 2500,
      );

      final audioClip = const AudioClipEntity(
        id: 'audio-track-1',
        mediaPath: '/path/audio.mp3',
        title: 'Theme Song',
        category: AudioCategory.music,
        timelineStartMs: 0,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 10000,
      );

      baseProject = ProjectEntity(
        id: 'project-independent-all',
        title: 'Full 8 Track Independent Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: [videoClip, photoClip, overlayClip],
        textOverlays: [textOverlay],
        stickerOverlays: [stickerOverlay],
        effectClips: [effectClip],
        animationClips: [animationClip],
        audioClips: [audioClip],
      );
    });

    test('1. ProjectEntity calculates duration across all 8 independent tracks', () {
      // video: 12000, photo: 16000, overlay: 8000, text: 5000, sticker: 7000, effect: 4500, anim: 5000, audio: 10000
      expect(baseProject.calculatedDurationMs, 16000);
      expect(baseProject.videoClips.length, 3);
      expect(baseProject.effectClips.length, 1);
      expect(baseProject.animationClips.length, 1);
      expect(baseProject.textOverlays.length, 1);
      expect(baseProject.stickerOverlays.length, 1);
      expect(baseProject.audioClips.length, 1);
    });

    test('2. Independent Effects Track: Add, Trim, Slide, Duplicate, and Delete', () {
      final controller = EditorController(project: baseProject);

      // Add a new independent effect clip at playhead 6000ms
      controller.seekTo(6000);
      controller.addEffectClip(effectType: VideoEffectType.videoCam, durationMs: 4000);

      expect(controller.state.project.effectClips.length, 2);
      final newEff = controller.state.project.effectClips.last;
      expect(newEff.effectType, VideoEffectType.videoCam);
      expect(newEff.timelineStartMs, 6000);
      expect(newEff.durationMs, 4000);
      expect(controller.state.selectionType, SelectionType.effectClip);
      expect(controller.state.selectedItemId, newEff.id);

      // Trim right handle by dragging
      controller.updateEffectDurationByDrag(
        effectId: newEff.id,
        deltaPixels: 60.0, // 60px at 60 pps = 1000ms
        pixelsPerSecond: 60.0,
        isLeftHandle: false,
      );
      expect(controller.state.project.effectClips.last.durationMs, 5000);

      // Slide reposition
      controller.moveEffectClipPosition(
        effectId: newEff.id,
        deltaPixels: 30.0, // 500ms
        pixelsPerSecond: 60.0,
      );
      expect(controller.state.project.effectClips.last.timelineStartMs, 6500);

      // Duplicate
      controller.duplicateEffectClip(newEff.id);
      expect(controller.state.project.effectClips.length, 3);

      // Delete
      controller.deleteEffectClip(newEff.id);
      expect(controller.state.project.effectClips.length, 2);
      expect(controller.state.selectionType, SelectionType.none);
    });

    test('3. Independent Animations Track: Add, Trim, Slide, Replace, Duplicate, and Delete', () {
      final controller = EditorController(project: baseProject);

      // Add independent animation clip at playhead 4000ms
      controller.seekTo(4000);
      controller.addAnimationClip(animationType: ClipAnimationCombo.bounce, durationMs: 3000);

      expect(controller.state.project.animationClips.length, 2);
      final newAnim = controller.state.project.animationClips.last;
      expect(newAnim.animationType, ClipAnimationCombo.bounce);
      expect(newAnim.timelineStartMs, 4000);
      expect(newAnim.durationMs, 3000);
      expect(controller.state.selectionType, SelectionType.animationClip);
      expect(controller.state.selectedItemId, newAnim.id);

      // Replace animation type
      controller.replaceAnimationClip(newAnim.id, ClipAnimationCombo.floating);
      expect(controller.state.project.animationClips.last.animationType, ClipAnimationCombo.floating);

      // Trim duration by drag
      controller.updateAnimationDurationByDrag(
        animationId: newAnim.id,
        deltaPixels: 60.0,
        pixelsPerSecond: 60.0,
        isLeftHandle: false,
      );
      expect(controller.state.project.animationClips.last.durationMs, 4000);

      // Slide drag
      controller.moveAnimationPositionByDrag(
        animationId: newAnim.id,
        deltaPixels: 60.0,
        pixelsPerSecond: 60.0,
      );
      expect(controller.state.project.animationClips.last.timelineStartMs, 5000);

      // Duplicate
      controller.duplicateSelected();
      expect(controller.state.project.animationClips.length, 3);

      // Delete selected
      controller.deleteSelected();
      expect(controller.state.project.animationClips.length, 2);
      expect(controller.state.selectionType, SelectionType.none);
    });

    test('4. Independent Photo and Video clips on timeline', () {
      final controller = EditorController(project: baseProject);

      // Add independent Photo clip
      controller.addPhotoClip(
        name: 'New Nature Photo',
        mediaPath: '/photos/sunset.jpg',
        durationMs: 5000,
      );

      final addedPhoto = controller.state.project.videoClips.last;
      expect(addedPhoto.isPhoto, true);
      expect(addedPhoto.isVideo, false);
      expect(addedPhoto.effectiveDurationMs, 5000);
      expect(controller.state.selectionType, SelectionType.videoClip);

      // Add independent Video clip
      controller.addVideoClip(
        name: 'New Drone Clip',
        mediaPath: '/videos/drone.mp4',
        durationMs: 8000,
      );

      final addedVideo = controller.state.project.videoClips.last;
      expect(addedVideo.isPhoto, false);
      expect(addedVideo.isVideo, true);
      expect(addedVideo.effectiveDurationMs, 8000);
    });

    test('5. Independent Overlay (PIP) video and photo clips', () {
      final controller = EditorController(project: baseProject);

      // Add PIP photo overlay
      controller.addPhotoClip(
        name: 'Logo Watermark Photo',
        mediaPath: '/images/watermark.png',
        durationMs: 6000,
        isOverlay: true,
      );

      final pipPhoto = controller.state.project.videoClips.last;
      expect(pipPhoto.isOverlay, true);
      expect(pipPhoto.isPhoto, true);
      expect(controller.state.selectionType, SelectionType.overlayClip);

      // Add PIP video overlay
      controller.addOverlayClip(
        name: 'Reaction Cam Video',
        mediaPath: '/videos/reaction.mp4',
        durationMs: 7000,
      );

      final pipVideo = controller.state.project.videoClips.last;
      expect(pipVideo.isOverlay, true);
      expect(pipVideo.isVideo, true);
      expect(controller.state.selectionType, SelectionType.overlayClip);
    });

    test('6. Synchronized Selection switches control across all 8 independent elements', () {
      final controller = EditorController(project: baseProject);

      // Select Video
      controller.setSelection(SelectionType.videoClip, 'video-main-1');
      expect(controller.state.selectionType, SelectionType.videoClip);
      expect(controller.state.selectedVideoClip?.id, 'video-main-1');

      // Select Photo
      controller.setSelection(SelectionType.videoClip, 'photo-main-2');
      expect(controller.state.selectedVideoClip?.isPhoto, true);

      // Select Overlay
      controller.setSelection(SelectionType.overlayClip, 'overlay-pip-1');
      expect(controller.state.selectionType, SelectionType.overlayClip);
      expect(controller.state.selectedVideoClip?.isOverlay, true);

      // Select Text
      controller.setSelection(SelectionType.textOverlay, 'text-track-1');
      expect(controller.state.selectionType, SelectionType.textOverlay);
      expect(controller.state.selectedTextOverlay?.text, 'Looma Magic');

      // Select Sticker
      controller.setSelection(SelectionType.stickerOverlay, 'sticker-track-1');
      expect(controller.state.selectionType, SelectionType.stickerOverlay);
      expect(controller.state.selectedStickerOverlay?.id, 'sticker-track-1');

      // Select Effect
      controller.setSelection(SelectionType.effectClip, 'effect-track-1');
      expect(controller.state.selectionType, SelectionType.effectClip);
      expect(controller.state.selectedEffectClip?.effectType, VideoEffectType.explosion);

      // Select Animation
      controller.setSelection(SelectionType.animationClip, 'animation-track-1');
      expect(controller.state.selectionType, SelectionType.animationClip);
      expect(controller.state.selectedAnimationClip?.animationType, ClipAnimationCombo.pulse);

      // Select Audio
      controller.setSelection(SelectionType.audioClip, 'audio-track-1');
      expect(controller.state.selectionType, SelectionType.audioClip);
      expect(controller.state.selectedAudioClip?.title, 'Theme Song');
    });

    test('7. JSON Serialization & Persistence preserves all 8 independent track types', () {
      final json = ProjectModel.toJson(baseProject);
      final restored = ProjectModel.fromJson(json);

      expect(restored.videoClips.length, 3);
      expect(restored.textOverlays.length, 1);
      expect(restored.stickerOverlays.length, 1);
      expect(restored.effectClips.length, 1);
      expect(restored.effectClips.first.effectType, VideoEffectType.explosion);
      expect(restored.animationClips.length, 1);
      expect(restored.animationClips.first.animationType, ClipAnimationCombo.pulse);
      expect(restored.audioClips.length, 1);
      expect(restored.calculatedDurationMs, 16000);
    });

    testWidgets('8. MultiTrackTimeline renders independent Effects and Animations tracks and items', (tester) async {
      final controller = EditorController(project: baseProject);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: MultiTrackTimeline(
                state: controller.state,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Effects track icon in header and EffectTrackItem in timeline
      expect(find.byIcon(Icons.auto_fix_high), findsWidgets);
      expect(find.byType(EffectTrackItem), findsOneWidget);

      // Verify Animations track icon in header and AnimationTrackItem in timeline
      expect(find.byIcon(Icons.animation), findsWidgets);
      expect(find.byType(AnimationTrackItem), findsOneWidget);
    });
  });
}
