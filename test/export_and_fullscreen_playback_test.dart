import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/services/gallery_saver_service.dart';
import 'package:procut/core/services/valid_mp4_generator.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/editor/presentation/widgets/canvas_preview.dart';
import 'package:procut/features/export/data/datasources/video_rendering_engine.dart';
import 'package:procut/features/export/domain/entities/export_config_entity.dart';
import 'package:procut/features/export/domain/entities/render_progress_entity.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gallery Export Video Validation Tests', () {
    test('ValidMp4Generator generates compliant H.264 MP4 container bytes', () async {
      final bytes = await ValidMp4Generator.getPlayableMp4Bytes();
      expect(bytes.isNotEmpty, isTrue);
      // Valid MP4 container starts with ftyp box at offset 4
      // bytes[4..8] should be 'ftyp'
      expect(bytes.length, greaterThanOrEqualTo(16));
      final ftypBox = String.fromCharCodes(bytes.sublist(4, 8));
      expect(ftypBox, equals('ftyp'));
    });

    test('GallerySaverService creates valid file on non-Android platform fallback', () async {
      final tempDir = Directory.systemTemp.createTempSync('looma_test_');
      final dummyVideo = File('${tempDir.path}/test_source.mp4');
      final validBytes = await ValidMp4Generator.getPlayableMp4Bytes();
      await dummyVideo.writeAsBytes(validBytes);

      final result = await GallerySaverService.saveVideoToDeviceGallery(
        sourceFilePath: dummyVideo.path,
        fileName: 'test_exported_vid',
      );

      expect(result, isNotNull);
      final savedFile = File(result!);
      expect(savedFile.existsSync(), isTrue);
      expect(savedFile.lengthSync(), equals(validBytes.length));

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });

    test('GallerySaverService replaces photo sources with valid MP4 container when exporting as video', () async {
      final tempDir = Directory.systemTemp.createTempSync('looma_photo_test_');
      final photoFile = File('${tempDir.path}/photo.jpg');
      await photoFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]); // JPEG magic bytes

      final result = await GallerySaverService.saveVideoToDeviceGallery(
        sourceFilePath: photoFile.path,
        fileName: 'test_photo_as_vid',
      );

      expect(result, isNotNull);
      final savedFile = File(result!);
      expect(savedFile.existsSync(), isTrue);
      final savedBytes = await savedFile.readAsBytes();
      // Saved file must NOT be a JPEG (must NOT start with 0xFF 0xD8)
      expect(savedBytes[0] == 0xFF && savedBytes[1] == 0xD8, isFalse);
      // Must be a valid MP4 with 'ftyp' box
      expect(String.fromCharCodes(savedBytes.sublist(4, 8)), equals('ftyp'));

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });
  });

  group('Full-Screen Video Playback Controller Sync Tests', () {
    testWidgets('FullScreen dialog plays, syncs controller, and renders tracks', (tester) async {
      final project = ProjectEntity(
        id: 'proj_full_screen',
        title: 'Full Screen Test Project',
        aspectRatio: AspectRatioType.ratio16_9,
        videoClips: const [
          VideoClipEntity(
            id: 'clip_main',
            name: 'Main Track Clip',
            mediaPath: 'assets/demo/alps_sunrise.mp4',
            sourceDurationMs: 10000,
            timelineStartMs: 0,
            timelineEndMs: 10000,
            trimEndMs: 10000,
          ),
          VideoClipEntity(
            id: 'clip_overlay',
            name: 'Overlay Clip',
            mediaPath: 'assets/demo/overlay_vid.mp4',
            sourceDurationMs: 5000,
            timelineStartMs: 0,
            timelineEndMs: 5000,
            trimEndMs: 5000,
            isOverlay: true,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = EditorController(project: project);
      addTearDown(() => controller.dispose());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 700,
              child: CanvasPreview(
                timelineState: controller.currentState,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Find full screen button by icon and tap it
      final fullScreenBtn = find.byIcon(Icons.fullscreen);
      expect(fullScreenBtn, findsWidgets);
      await tester.tap(fullScreenBtn.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Full screen dialog is now visible
      expect(find.text('Full Screen Test Project'), findsOneWidget);
      expect(find.text('Minimize'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNWidgets(2));

      // Tap Play in full screen dialog
      await tester.tap(find.byIcon(Icons.play_arrow).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Play state changes to pause icon
      expect(controller.currentState.isPlaying, isTrue);
      expect(find.byIcon(Icons.pause).last, findsOneWidget);

      // Tap Pause in full screen dialog
      await tester.tap(find.byIcon(Icons.pause).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.currentState.isPlaying, isFalse);
      expect(find.byIcon(Icons.play_arrow).last, findsOneWidget);

      // Tap Minimize
      await tester.tap(find.text('Minimize'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Minimize'), findsNothing);
    });
  });

  group('VideoRenderingEngine Pipeline Tests', () {
    test('executeRenderPipeline streams passes and yields completed output video', () async {
      final project = ProjectEntity(
        id: 'proj_pipeline_test',
        title: 'Pipeline Project',
        aspectRatio: AspectRatioType.ratio9_16,
        videoClips: const [
          VideoClipEntity(
            id: 'clip_bg',
            name: 'Background Photo',
            mediaPath: 'assets/demo/photo.jpg',
            sourceDurationMs: 3000,
            timelineStartMs: 0,
            timelineEndMs: 3000,
            trimEndMs: 3000,
          ),
          VideoClipEntity(
            id: 'clip_overlay',
            name: 'Overlay Green Screen',
            mediaPath: 'assets/demo/greenscreen.mp4',
            sourceDurationMs: 3000,
            timelineStartMs: 0,
            timelineEndMs: 3000,
            trimEndMs: 3000,
            isOverlay: true,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final engine = VideoRenderingEngineImpl();
      final stream = engine.executeRenderPipeline(
        project: project,
        config: const ExportConfigEntity(
          projectId: 'proj_pipeline_test',
          resolution: ExportResolution.res720p,
          fps: 30,
        ),
      );

      final progressEvents = <RenderProgressEntity>[];
      await for (final event in stream) {
        progressEvents.add(event);
      }

      expect(progressEvents.isNotEmpty, isTrue);
      expect(progressEvents.last.status, equals(RenderStatus.completed));
      expect(progressEvents.last.progress, equals(1.0));
      expect(progressEvents.last.outputPath, isNotNull);

      final outFile = File(progressEvents.last.outputPath!);
      expect(outFile.existsSync(), isTrue);
      expect(outFile.lengthSync(), greaterThan(100));
    });
  });
}
