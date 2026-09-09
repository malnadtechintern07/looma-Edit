import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/filters_effects/domain/entities/effect_clip_entity.dart';
import 'package:procut/features/filters_effects/domain/entities/video_effect_type.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/text_stickers/domain/entities/sticker_overlay_entity.dart';
import 'package:procut/features/text_stickers/domain/entities/text_overlay_entity.dart';

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

  group('Independent Effect Clip System Tests', () {
    late ProjectEntity baseProject;

    setUp(() {
      final videoClip1 = VideoClipEntity(
        id: 'video-1',
        mediaPath: '/path/video1.mp4',
        name: 'Video 1',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 10000,
      );

      final audioClip1 = const AudioClipEntity(
        id: 'audio-1',
        mediaPath: '/path/music.mp3',
        title: 'Background Music',
        category: AudioCategory.music,
        timelineStartMs: 0,
        timelineEndMs: 8000,
        trimStartMs: 0,
        trimEndMs: 8000,
      );

      final textOverlay1 = const TextOverlayEntity(
        id: 'text-1',
        text: 'Title Intro',
        timelineStartMs: 1000,
        timelineEndMs: 4000,
      );

      final sticker1 = const StickerOverlayEntity(
        id: 'sticker-1',
        stickerKey: 'fire',
        stickerName: 'Fire',
        assetEmojiOrPath: '🔥',
        timelineStartMs: 2000,
        timelineEndMs: 5000,
      );

      final effectClip1 = const EffectClipEntity(
        id: 'effect-1',
        effectType: VideoEffectType.cyberGrid,
        timelineStartMs: 2000,
        durationMs: 4000,
        intensity: 0.8,
      );

      baseProject = ProjectEntity(
        id: 'proj-1',
        title: 'MultiTrack Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: [videoClip1],
        audioClips: [audioClip1],
        textOverlays: [textOverlay1],
        stickerOverlays: [sticker1],
        effectClips: [effectClip1],
        durationMs: 10000,
      );
    });

    test('EffectClipEntity serialization & calculatedDurationMs', () {
      final modelJson = ProjectModel.toJson(baseProject);
      final restoredProject = ProjectModel.fromJson(modelJson);

      expect(restoredProject.effectClips.length, 1);
      expect(restoredProject.effectClips.first.id, 'effect-1');
      expect(restoredProject.effectClips.first.effectType, VideoEffectType.cyberGrid);
      expect(restoredProject.effectClips.first.timelineStartMs, 2000);
      expect(restoredProject.effectClips.first.durationMs, 4000);
      expect(restoredProject.effectClips.first.timelineEndMs, 6000);
      expect(restoredProject.effectClips.first.intensity, 0.8);
      expect(restoredProject.calculatedDurationMs, 10000);
    });

    test('TimelineState activeEffectClips at playhead position', () {
      final controller = EditorController(project: baseProject);

      // Playhead at 1000ms: Before effect-1 (2000-6000ms)
      controller.seekTo(1000);
      expect(controller.state.activeEffectClips.isEmpty, true);

      // Playhead at 3000ms: Inside effect-1 (2000-6000ms)
      controller.seekTo(3000);
      expect(controller.state.activeEffectClips.length, 1);
      expect(controller.state.activeEffectClips.first.id, 'effect-1');

      // Playhead at 7000ms: After effect-1 (2000-6000ms)
      controller.seekTo(7000);
      expect(controller.state.activeEffectClips.isEmpty, true);
    });

    test('Add new EffectClipEntity at playhead independently', () {
      final controller = EditorController(project: baseProject);
      controller.seekTo(5000);

      controller.addEffectClip(
        effectType: VideoEffectType.matrixRain,
        durationMs: 3000,
        intensity: 0.9,
      );

      expect(controller.state.project.effectClips.length, 2);
      final newEffect = controller.state.project.effectClips.last;
      expect(newEffect.effectType, VideoEffectType.matrixRain);
      expect(newEffect.timelineStartMs, 5000);
      expect(newEffect.durationMs, 3000);
      expect(newEffect.timelineEndMs, 8000);
      expect(newEffect.intensity, 0.9);

      // Verify other clips are completely unaffected
      expect(controller.state.project.videoClips.length, 1);
      expect(controller.state.project.audioClips.length, 1);
      expect(controller.state.project.textOverlays.length, 1);
      expect(controller.state.project.stickerOverlays.length, 1);
    });

    test('Replace EffectClipEntity independently without altering others', () {
      final controller = EditorController(project: baseProject);

      // Replace effect-1 (cyberGrid -> fireEmbers)
      controller.replaceEffectClip('effect-1', VideoEffectType.fireEmbers);

      final updated = controller.state.project.effectClips.firstWhere((e) => e.id == 'effect-1');
      expect(updated.effectType, VideoEffectType.fireEmbers);
      expect(updated.timelineStartMs, 2000); // timing preserved
      expect(updated.durationMs, 4000); // duration preserved

      // Check other tracks untouched
      expect(controller.state.project.videoClips.first.mediaPath, '/path/video1.mp4');
      expect(controller.state.project.audioClips.first.mediaPath, '/path/music.mp3');
    });

    test('Trim and Slide EffectClipEntity independently', () {
      final controller = EditorController(project: baseProject);

      // Slide effect-1 forward by 1 second (60 pixels at 60 pps)
      controller.moveEffectClipPosition(
        effectId: 'effect-1',
        deltaPixels: 60,
        pixelsPerSecond: 60,
      );

      var updated = controller.state.project.effectClips.firstWhere((e) => e.id == 'effect-1');
      expect(updated.timelineStartMs, 3000);
      expect(updated.durationMs, 4000);
      expect(updated.timelineEndMs, 7000);

      // Trim right handle to extend duration by 1000ms (60 pixels at 60 pps)
      controller.updateEffectDurationByDrag(
        effectId: 'effect-1',
        deltaPixels: 60,
        pixelsPerSecond: 60,
        isLeftHandle: false,
      );

      updated = controller.state.project.effectClips.firstWhere((e) => e.id == 'effect-1');
      expect(updated.timelineStartMs, 3000);
      expect(updated.durationMs, 5000);
      expect(updated.timelineEndMs, 8000);
    });

    test('Split and Duplicate EffectClipEntity independently', () {
      final controller = EditorController(project: baseProject);

      // Move playhead to 4000ms (middle of effect-1 which runs 2000-6000ms)
      controller.seekTo(4000);
      controller.splitEffectClipAtPlayhead('effect-1');

      expect(controller.state.project.effectClips.length, 2);
      final part1 = controller.state.project.effectClips[0];
      final part2 = controller.state.project.effectClips[1];

      expect(part1.timelineStartMs, 2000);
      expect(part1.durationMs, 2000);
      expect(part1.timelineEndMs, 4000);

      expect(part2.timelineStartMs, 4000);
      expect(part2.durationMs, 2000);
      expect(part2.timelineEndMs, 6000);

      // Duplicate part2
      controller.duplicateEffectClip(part2.id);
      expect(controller.state.project.effectClips.length, 3);
      final part3 = controller.state.project.effectClips[2];
      expect(part3.timelineStartMs, 6000);
      expect(part3.durationMs, 2000);
      expect(part3.timelineEndMs, 8000);
    });

    test('Delete EffectClipEntity independently without affecting other clips', () {
      final controller = EditorController(project: baseProject);

      controller.deleteEffectClip('effect-1');

      expect(controller.state.project.effectClips.isEmpty, true);
      expect(controller.state.project.videoClips.length, 1);
      expect(controller.state.project.audioClips.length, 1);
      expect(controller.state.project.textOverlays.length, 1);
      expect(controller.state.project.stickerOverlays.length, 1);
    });

    test('Independent Replace for Video, Audio, and Sticker clips', () {
      final controller = EditorController(project: baseProject);

      // Replace Video Clip
      controller.replaceVideoClip(
        clipId: 'video-1',
        newMediaPath: '/path/new_video.mp4',
        newName: 'New Video 4K',
        newSourceDurationMs: 12000,
      );
      expect(controller.state.project.videoClips.first.mediaPath, '/path/new_video.mp4');
      expect(controller.state.project.videoClips.first.name, 'New Video 4K');

      // Replace Audio Clip
      controller.replaceAudioClip(
        audioId: 'audio-1',
        newAudioPath: '/path/epic_rock.mp3',
        newTitle: 'Epic Rock',
      );
      expect(controller.state.project.audioClips.first.mediaPath, '/path/epic_rock.mp3');
      expect(controller.state.project.audioClips.first.title, 'Epic Rock');

      // Replace Sticker
      controller.replaceSticker(
        stickerId: 'sticker-1',
        newAssetPath: '⚡',
      );
      expect(controller.state.project.stickerOverlays.first.assetEmojiOrPath, '⚡');
    });

    test('New CapCut effects (videoCam, phoneDrift, lightningCloud, crossSplit, obliqueBlur, edgeSilhouette, citySunset, verticalFilm, prismRainbow) serialization & categories', () {
      final newEffects = [
        VideoEffectType.videoCam,
        VideoEffectType.phoneDrift,
        VideoEffectType.lightningCloud,
        VideoEffectType.crossSplit,
        VideoEffectType.obliqueBlur,
        VideoEffectType.edgeSilhouette,
        VideoEffectType.citySunset,
        VideoEffectType.verticalFilm,
        VideoEffectType.prismRainbow,
      ];

      for (final eff in newEffects) {
        // Correct roundtrip string serialization
        final str = eff.name;
        final restored = VideoEffectType.fromString(str);
        expect(restored, eff);

        // Valid non-empty labels and descriptions
        expect(eff.label.isNotEmpty, true);
        expect(eff.description.isNotEmpty, true);

        // Check in EffectClipEntity
        final clip = EffectClipEntity(
          id: 'eff-${eff.name}',
          effectType: eff,
          timelineStartMs: 0,
          durationMs: 3000,
        );
        final json = clip.toJson();
        final fromJson = EffectClipEntity.fromJson(json);
        expect(fromJson.effectType, eff);
      }

      // Verify Trending category contains the screenshot's primary effects
      expect(VideoEffectCategory.values.first, VideoEffectCategory.trending);
      expect(VideoEffectType.explosion.category, VideoEffectCategory.trending);
      expect(VideoEffectType.videoCam.category, VideoEffectCategory.trending);
      expect(VideoEffectType.rollingFilm.category, VideoEffectCategory.trending);
      expect(VideoEffectType.phoneDrift.category, VideoEffectCategory.trending);
      expect(VideoEffectType.lightningCloud.category, VideoEffectCategory.trending);
      expect(VideoEffectType.crossSplit.category, VideoEffectCategory.trending);
      expect(VideoEffectType.superLarge.category, VideoEffectCategory.trending);
      expect(VideoEffectType.obliqueBlur.category, VideoEffectCategory.trending);
      expect(VideoEffectType.edgeSilhouette.category, VideoEffectCategory.trending);
      expect(VideoEffectType.citySunset.category, VideoEffectCategory.trending);
    });
  });
}
