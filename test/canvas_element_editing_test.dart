import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/features/editor/domain/entities/timeline_state.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/editor/presentation/providers/editor_controller.dart';
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

  group('Canvas Element Editing & Selection Synchronization Tests', () {
    late ProjectEntity baseProject;

    setUp(() {
      final videoClip = VideoClipEntity(
        id: 'video-main',
        mediaPath: '/media/video.mp4',
        name: 'Main Video',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 10000,
        positionX: 0.0,
        positionY: 0.0,
        zoomScale: 1.0,
        rotationDegrees: 0.0,
      );

      final photoClip = VideoClipEntity(
        id: 'photo-clip',
        mediaPath: '/media/photo.jpg',
        name: 'Photo Clip',
        sourceDurationMs: 5000,
        timelineStartMs: 10000,
        timelineEndMs: 15000,
        trimStartMs: 0,
        trimEndMs: 5000,
        positionX: 10.0,
        positionY: 20.0,
        zoomScale: 1.2,
        rotationDegrees: 15.0,
      );

      final overlayClip = VideoClipEntity(
        id: 'pip-overlay-1',
        mediaPath: '/media/overlay.mp4',
        name: 'PIP Overlay',
        sourceDurationMs: 6000,
        timelineStartMs: 2000,
        timelineEndMs: 8000,
        trimStartMs: 0,
        trimEndMs: 6000,
        isOverlay: true,
        positionX: 50.0,
        positionY: -30.0,
        zoomScale: 0.5,
        rotationDegrees: 45.0,
      );

      final textOverlay = const TextOverlayEntity(
        id: 'text-1',
        text: 'Editable Text',
        posX: 0.5,
        posY: 0.5,
        scale: 1.0,
        rotation: 0.0,
        timelineStartMs: 1000,
        timelineEndMs: 7000,
      );

      final stickerOverlay = const StickerOverlayEntity(
        id: 'sticker-1',
        stickerKey: 'sparkle',
        stickerName: 'Sparkle',
        assetEmojiOrPath: '✨',
        posX: 0.3,
        posY: 0.4,
        scale: 1.0,
        rotation: 0.0,
        timelineStartMs: 1500,
        timelineEndMs: 6500,
      );

      baseProject = ProjectEntity(
        id: 'proj-edit-test',
        title: 'Edit Test Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: [videoClip, photoClip, overlayClip],
        textOverlays: [textOverlay],
        stickerOverlays: [stickerOverlay],
      );
    });

    test('Video & Photo Clip: selection, drag to move, pinch to zoom, and rotate', () {
      final controller = EditorController(project: baseProject);

      // Select main video clip
      controller.setSelection(SelectionType.videoClip, 'video-main');
      expect(controller.state.selectionType, SelectionType.videoClip);
      expect(controller.state.selectedItemId, 'video-main');

      // Drag to move
      controller.updateClipTransform(
        clipId: 'video-main',
        positionX: 35.0,
        positionY: -20.0,
      );

      var mainClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video-main');
      expect(mainClip.positionX, 35.0);
      expect(mainClip.positionY, -20.0);

      // Pinch to zoom and rotate
      controller.updateClipTransform(
        clipId: 'video-main',
        zoomScale: 1.85,
        rotationDegrees: 30.0,
      );

      mainClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video-main');
      expect(mainClip.zoomScale, 1.85);
      expect(mainClip.rotationDegrees, 30.0);

      // Verify other clips are unchanged
      final photoClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'photo-clip');
      expect(photoClip.positionX, 10.0);
      expect(photoClip.positionY, 20.0);
      expect(photoClip.zoomScale, 1.2);
      expect(photoClip.rotationDegrees, 15.0);

      // Select and modify photo clip
      controller.setSelection(SelectionType.videoClip, 'photo-clip');
      expect(controller.state.selectedItemId, 'photo-clip');
      expect(photoClip.isPhoto, true);

      controller.updateClipTransform(
        clipId: 'photo-clip',
        positionX: -40.0,
        positionY: 60.0,
        zoomScale: 2.2,
        rotationDegrees: 90.0,
      );

      final updatedPhoto = controller.state.project.videoClips.firstWhere((c) => c.id == 'photo-clip');
      expect(updatedPhoto.positionX, -40.0);
      expect(updatedPhoto.positionY, 60.0);
      expect(updatedPhoto.zoomScale, 2.2);
      expect(updatedPhoto.rotationDegrees, 90.0);

      // Verify main clip was NOT affected when editing photo clip
      mainClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video-main');
      expect(mainClip.positionX, 35.0);
      expect(mainClip.positionY, -20.0);
    });

    test('Overlay (PIP) Clip: independent selection and transform changes', () {
      final controller = EditorController(project: baseProject);

      controller.setSelection(SelectionType.overlayClip, 'pip-overlay-1');
      expect(controller.state.selectionType, SelectionType.overlayClip);
      expect(controller.state.selectedItemId, 'pip-overlay-1');

      controller.updateClipTransform(
        clipId: 'pip-overlay-1',
        positionX: -80.0,
        positionY: 100.0,
        zoomScale: 0.75,
        rotationDegrees: 180.0,
      );

      final pip = controller.state.project.videoClips.firstWhere((c) => c.id == 'pip-overlay-1');
      expect(pip.positionX, -80.0);
      expect(pip.positionY, 100.0);
      expect(pip.zoomScale, 0.75);
      expect(pip.rotationDegrees, 180.0);

      // Main clip unchanged
      final mainClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video-main');
      expect(mainClip.positionX, 0.0);
      expect(mainClip.zoomScale, 1.0);
    });

    test('Text Overlay: independent selection, move, scale, and rotate', () {
      final controller = EditorController(project: baseProject);

      controller.setSelection(SelectionType.textOverlay, 'text-1');
      expect(controller.state.selectionType, SelectionType.textOverlay);
      expect(controller.state.selectedItemId, 'text-1');

      controller.updateTextTransform(
        textId: 'text-1',
        posX: 0.65,
        posY: 0.35,
        scale: 1.6,
        rotation: 0.523, // ~30 deg in radians
      );

      final text = controller.state.project.textOverlays.firstWhere((t) => t.id == 'text-1');
      expect(text.posX, 0.65);
      expect(text.posY, 0.35);
      expect(text.scale, 1.6);
      expect(text.rotation, 0.523);
    });

    test('Sticker Overlay: independent selection, move, scale, and rotate', () {
      final controller = EditorController(project: baseProject);

      controller.setSelection(SelectionType.stickerOverlay, 'sticker-1');
      expect(controller.state.selectionType, SelectionType.stickerOverlay);
      expect(controller.state.selectedItemId, 'sticker-1');

      controller.updateStickerTransform(
        stickerId: 'sticker-1',
        posX: 0.8,
        posY: 0.2,
        scale: 2.1,
        rotation: 1.047, // ~60 deg in radians
      );

      final sticker = controller.state.project.stickerOverlays.firstWhere((s) => s.id == 'sticker-1');
      expect(sticker.posX, 0.8);
      expect(sticker.posY, 0.2);
      expect(sticker.scale, 2.1);
      expect(sticker.rotation, 1.047);
    });

    test('Timeline & Canvas Selection Synchronization and Clear Selection', () {
      final controller = EditorController(project: baseProject);

      // 1. Select Video
      controller.setSelection(SelectionType.videoClip, 'video-main');
      expect(controller.state.selectionType, SelectionType.videoClip);
      expect(controller.state.selectedItemId, 'video-main');

      // 2. Switch to Text
      controller.setSelection(SelectionType.textOverlay, 'text-1');
      expect(controller.state.selectionType, SelectionType.textOverlay);
      expect(controller.state.selectedItemId, 'text-1');

      // 3. Switch to Sticker
      controller.setSelection(SelectionType.stickerOverlay, 'sticker-1');
      expect(controller.state.selectionType, SelectionType.stickerOverlay);
      expect(controller.state.selectedItemId, 'sticker-1');

      // 4. Switch to Overlay
      controller.setSelection(SelectionType.overlayClip, 'pip-overlay-1');
      expect(controller.state.selectionType, SelectionType.overlayClip);
      expect(controller.state.selectedItemId, 'pip-overlay-1');

      // 5. Clear selection (tap empty canvas)
      controller.clearSelection();
      expect(controller.state.selectionType, SelectionType.none);
      expect(controller.state.selectedItemId, null);
    });

    test('Continuous multi-frame transformation: simultaneous drag, zoom, and rotate across 50 frames', () {
      final controller = EditorController(project: baseProject);
      controller.setSelection(SelectionType.overlayClip, 'pip-overlay-1');

      var clip = controller.state.project.videoClips.firstWhere((c) => c.id == 'pip-overlay-1');
      double curX = clip.positionX;
      double curY = clip.positionY;
      double curZoom = clip.zoomScale;
      double curRot = clip.rotationDegrees;

      // Simulate 50 continuous frames of simultaneous dragging, pinching, and rotating
      for (int frame = 1; frame <= 50; frame++) {
        curX += 2.0; // dragging right
        curY -= 1.0; // dragging up
        curZoom = (curZoom * 1.01).clamp(0.1, 5.0); // zooming in
        curRot = (curRot + 2.5) % 360.0; // rotating clockwise

        controller.updateClipTransform(
          clipId: 'pip-overlay-1',
          positionX: curX,
          positionY: curY,
          zoomScale: curZoom,
          rotationDegrees: curRot,
          persist: false, // in-flight frame
        );

        // Verify updated on EVERY gesture update frame
        final active = controller.state.project.videoClips.firstWhere((c) => c.id == 'pip-overlay-1');
        expect(active.positionX, curX);
        expect(active.positionY, curY);
        expect(active.zoomScale, curZoom);
        expect(active.rotationDegrees, curRot);
      }

      // Gesture ends: persist final transform
      controller.updateClipTransform(
        clipId: 'pip-overlay-1',
        positionX: curX,
        positionY: curY,
        zoomScale: curZoom,
        rotationDegrees: curRot,
        persist: true,
      );

      final finalClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'pip-overlay-1');
      expect(finalClip.positionX, 50.0 + (50 * 2.0));
      expect(finalClip.positionY, -30.0 - (50 * 1.0));
      expect(finalClip.zoomScale, closeTo(0.5 * 1.6446, 0.05));
      expect(finalClip.rotationDegrees, (45.0 + (50 * 2.5)) % 360.0);

      // Verify main video and photo clips were completely untouched
      final mainClip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video-main');
      expect(mainClip.positionX, 0.0);
      expect(mainClip.positionY, 0.0);
      expect(mainClip.zoomScale, 1.0);
      expect(mainClip.rotationDegrees, 0.0);
    });

    test('Preserve transform between successive distinct gestures', () {
      final controller = EditorController(project: baseProject);
      controller.setSelection(SelectionType.videoClip, 'video-main');

      // Gesture 1: Pure Drag
      controller.updateClipTransform(
        clipId: 'video-main',
        positionX: 120.0,
        positionY: 80.0,
        persist: true,
      );
      var clip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video-main');
      expect(clip.positionX, 120.0);
      expect(clip.positionY, 80.0);
      expect(clip.zoomScale, 1.0); // original scale preserved

      // Gesture 2: Pure Zoom immediately after
      controller.updateClipTransform(
        clipId: 'video-main',
        zoomScale: 2.2,
        persist: true,
      );
      clip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video-main');
      expect(clip.positionX, 120.0); // position preserved!
      expect(clip.positionY, 80.0); // position preserved!
      expect(clip.zoomScale, 2.2);

      // Gesture 3: Pure Rotate immediately after
      controller.updateClipTransform(
        clipId: 'video-main',
        rotationDegrees: 75.0,
        persist: true,
      );
      clip = controller.state.project.videoClips.firstWhere((c) => c.id == 'video-main');
      expect(clip.positionX, 120.0); // position preserved!
      expect(clip.positionY, 80.0); // position preserved!
      expect(clip.zoomScale, 2.2); // scale preserved!
      expect(clip.rotationDegrees, 75.0);
    });
  });
}
