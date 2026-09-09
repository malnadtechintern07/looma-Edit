import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/rendering/chroma_key_filter.dart';
import 'package:procut/features/editor/domain/entities/chroma_key_config_entity.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/editor/presentation/widgets/canvas_preview.dart';
import 'package:procut/features/editor/presentation/widgets/chroma_key_sheet.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChromaKeyConfigEntity & Model Tests', () {
    test('default configuration values are accurate', () {
      const config = ChromaKeyConfigEntity();
      expect(config.isEnabled, isFalse);
      expect(config.keyColorHex, equals(0xFF00FF00));
      expect(config.intensity, equals(0.50));
      expect(config.edgeSoftness, equals(0.15));
      expect(config.spillSuppression, equals(0.30));
      expect(config.shadow, equals(0.15));
      expect(config.edgeSmoothing, equals(0.15));
    });

    test('copyWith properly updates all chroma key parameters', () {
      const initial = ChromaKeyConfigEntity();
      final updated = initial.copyWith(
        isEnabled: true,
        keyColorHex: 0xFF0000FF,
        intensity: 0.75,
        edgeSoftness: 0.35,
        spillSuppression: 0.60,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.keyColorHex, equals(0xFF0000FF));
      expect(updated.intensity, equals(0.75));
      expect(updated.edgeSoftness, equals(0.35));
      expect(updated.spillSuppression, equals(0.60));
    });

    test('ProjectModel serializes and deserializes ChromaKeyConfigEntity with full fidelity', () {
      final clip = VideoClipEntity(
        id: 'clip_chroma_1',
        mediaPath: 'assets/demo/greenscreen.mp4',
        name: 'Green Screen Actor',
        sourceDurationMs: 5000,
        timelineStartMs: 0,
        timelineEndMs: 5000,
        trimEndMs: 5000,
        chromaKey: const ChromaKeyConfigEntity(
          isEnabled: true,
          keyColorHex: 0xFF12E555,
          intensity: 0.65,
          edgeSoftness: 0.22,
          spillSuppression: 0.45,
        ),
      );

      final project = ProjectEntity(
        id: 'proj_chroma_test',
        title: 'Chroma Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 5000,
        videoClips: [clip],
      );

      final json = ProjectModel.toJson(project);
      final restored = ProjectModel.fromJson(json);

      final restoredClip = restored.videoClips.first;
      expect(restoredClip.chromaKey, isNotNull);
      expect(restoredClip.chromaKey!.isEnabled, isTrue);
      expect(restoredClip.chromaKey!.keyColorHex, equals(0xFF12E555));
      expect(restoredClip.chromaKey!.intensity, closeTo(0.65, 0.01));
      expect(restoredClip.chromaKey!.edgeSoftness, closeTo(0.22, 0.01));
      expect(restoredClip.chromaKey!.spillSuppression, closeTo(0.45, 0.01));
    });
  });

  group('ChromaKeyFilter Matrix & Mathematical Transparency Tests', () {
    test('disabled config returns 4x5 identity matrix', () {
      const config = ChromaKeyConfigEntity(isEnabled: false);
      final matrix = ChromaKeyFilter.createMatrix(config);
      expect(matrix, equals(ChromaKeyFilter.identityMatrix));
    });

    test('enabled green screen generates alpha drop and green spill suppression', () {
      const config = ChromaKeyConfigEntity(
        isEnabled: true,
        keyColorHex: 0xFF00FF00,
        intensity: 0.50,
        edgeSoftness: 0.20,
        spillSuppression: 0.40,
      );
      final matrix = ChromaKeyFilter.createMatrix(config);

      expect(matrix.length, equals(20));
      // Alpha row is row 4 (indices 15..19): -aR, -aG, -aB, 1.0, aOffset
      // For green, -aG should be negative (subtracting alpha when green is high)
      expect(matrix[16], lessThan(0.0));
      // Spill suppression on green row (indices 5..9): gG should be less than 1.0
      expect(matrix[6], lessThan(1.0));
      expect(matrix[5], greaterThan(0.0)); // Red blend
      expect(matrix[7], greaterThan(0.0)); // Blue blend
    });

    test('enabled blue screen generates alpha drop and blue spill suppression', () {
      const config = ChromaKeyConfigEntity(
        isEnabled: true,
        keyColorHex: 0xFF0000FF,
        intensity: 0.50,
        edgeSoftness: 0.20,
        spillSuppression: 0.40,
      );
      final matrix = ChromaKeyFilter.createMatrix(config);

      expect(matrix.length, equals(20));
      // Alpha row for blue: -aB should be negative
      expect(matrix[17], lessThan(0.0));
      // Blue spill row (indices 10..14): bB should be less than 1.0
      expect(matrix[12], lessThan(1.0));
    });

    testWidgets('ColorFiltered with ChromaKeyFilter renders real transparency on canvas', (tester) async {
      final boundaryKey = GlobalKey();

      // Green foreground layer with Chroma Key enabled over Red background
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    // Background: Solid Red
                    Positioned.fill(
                      child: Container(color: const Color(0xFFFF0000)),
                    ),
                    // Foreground: Solid Green with ChromaKeyFilter enabled for Green (0x00FF00)
                    Positioned.fill(
                      child: ChromaKeyFilter.apply(
                        config: const ChromaKeyConfigEntity(
                          isEnabled: true,
                          keyColorHex: 0xFF00FF00,
                          intensity: 0.60,
                          edgeSoftness: 0.15,
                          spillSuppression: 0.30,
                        ),
                        child: Container(color: const Color(0xFF00FF00)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(byteData, isNotNull);

        // Sample center pixel (50, 50)
        final offset = (50 * image.width + 50) * 4;
        final r = byteData!.getUint8(offset);
        final g = byteData.getUint8(offset + 1);
        final b = byteData.getUint8(offset + 2);
        final a = byteData.getUint8(offset + 3);

        // Green layer became transparent, revealing the Red background beneath it!
        expect(r, greaterThan(180));
        expect(g, lessThan(80));
        expect(b, lessThan(80));
        expect(a, equals(255));
      });
    });
  });

  group('EditorController Chroma Key Workflow Tests', () {
    test('openChromaKeyMode, setChromaKeyCrosshair, sampleChromaKeyColor, and closeChromaKeyMode', () {
      final clip = VideoClipEntity(
        id: 'clip_actor',
        mediaPath: 'actor.mp4',
        name: 'Actor',
        sourceDurationMs: 5000,
        timelineStartMs: 0,
        timelineEndMs: 5000,
        trimEndMs: 5000,
      );

      final project = ProjectEntity(
        id: 'p1',
        title: 'Project 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 5000,
        videoClips: [clip],
      );

      final controller = EditorController(project: project);

      // 1. Initially picking mode is off
      expect(controller.state.isChromaKeyPickingMode, isFalse);
      expect(controller.state.chromaKeyTargetClipId, isNull);

      // 2. Open chroma key mode
      controller.openChromaKeyMode('clip_actor');
      expect(controller.state.isChromaKeyPickingMode, isTrue);
      expect(controller.state.chromaKeyTargetClipId, equals('clip_actor'));

      final clipWithChroma = controller.state.project.videoClips.first;
      expect(clipWithChroma.chromaKey, isNotNull);
      expect(clipWithChroma.chromaKey!.isEnabled, isTrue);

      // 3. Move crosshair coordinates
      controller.setChromaKeyCrosshair(0.25, 0.75);
      expect(controller.state.chromaKeyCrosshairX, equals(0.25));
      expect(controller.state.chromaKeyCrosshairY, equals(0.75));

      // 4. Sample color under crosshair
      controller.sampleChromaKeyColor('clip_actor', 0xFF00FF88);
      final sampledClip = controller.state.project.videoClips.first;
      expect(sampledClip.chromaKey!.keyColorHex, equals(0xFF00FF88));

      // 5. Reset chroma key
      controller.resetChromaKey('clip_actor');
      final resetClip = controller.state.project.videoClips.first;
      expect(resetClip.chromaKey, isNull);

      // 6. Close chroma key mode
      controller.closeChromaKeyMode();
      expect(controller.state.isChromaKeyPickingMode, isFalse);
      expect(controller.state.chromaKeyTargetClipId, isNull);

      controller.dispose();
    });
  });

  group('ChromaKeySheet & UI Widget Tests', () {
    testWidgets('ChromaKeySheet renders header, toggle, sliders, and preset chips', (tester) async {
      ChromaKeyConfigEntity? changedConfig;
      bool resetCalled = false;
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChromaKeySheet(
              currentConfig: const ChromaKeyConfigEntity(
                isEnabled: true,
                keyColorHex: 0xFF00FF00,
                intensity: 0.50,
                edgeSoftness: 0.15,
                spillSuppression: 0.30,
              ),
              isPickingMode: true,
              onConfigChanged: (cfg) => changedConfig = cfg,
              onReset: () => resetCalled = true,
              onClose: () => closeCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title and icons
      expect(find.text('Chroma Key'), findsOneWidget);
      expect(find.byKey(const ValueKey('chroma_enable_switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('chroma_reset_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('chroma_done_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('chroma_eyedropper_btn')), findsOneWidget);

      // Check sliders
      expect(find.byKey(const ValueKey('chroma_strength_slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('chroma_feather_slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('chroma_spill_slider')), findsOneWidget);

      // Check presets
      expect(find.text('Green Screen'), findsOneWidget);
      expect(find.text('Blue Screen'), findsOneWidget);
      expect(find.text('Magenta'), findsOneWidget);
      expect(find.text('Cyan'), findsOneWidget);

      // Tap Blue Screen preset chip and verify onConfigChanged fired
      await tester.tap(find.text('Blue Screen'));
      await tester.pumpAndSettle();
      expect(changedConfig, isNotNull);
      expect(changedConfig!.keyColorHex, equals(0xFF0000FF));

      // Tap Reset button
      await tester.tap(find.byKey(const ValueKey('chroma_reset_btn')));
      await tester.pumpAndSettle();
      expect(resetCalled, isTrue);

      // Tap Done button
      await tester.tap(find.byKey(const ValueKey('chroma_done_btn')));
      await tester.pumpAndSettle();
      expect(closeCalled, isTrue);
    });

    testWidgets('CanvasPreview renders crosshair target marker in picking mode and handles tap', (tester) async {
      final clip = VideoClipEntity(
        id: 'clip_green',
        mediaPath: 'greenscreen.mp4',
        name: 'Scene 1',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 10000,
        trimEndMs: 10000,
        chromaKey: const ChromaKeyConfigEntity(
          isEnabled: true,
          keyColorHex: 0xFF00FF00,
        ),
      );

      final project = ProjectEntity(
        id: 'p_test',
        title: 'Chroma Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 10000,
        videoClips: [clip],
      );

      final controller = EditorController(project: project);
      addTearDown(() => controller.dispose());

      // Activate chroma key picking mode
      controller.openChromaKeyMode('clip_green');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 700,
              child: CanvasPreview(
                timelineState: controller.state,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Pump frames for preview to render without waiting indefinitely on mock video controller
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify guide banner and crosshair are rendered
      expect(find.text('Tap to pick color'), findsOneWidget);

      // Tap at center of CanvasPreview
      final canvasCenter = tester.getCenter(find.byType(CanvasPreview));
      await tester.tapAt(canvasCenter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.state.chromaKeyCrosshairX, closeTo(0.5, 0.05));
      expect(controller.state.chromaKeyCrosshairY, closeTo(0.5, 0.05));

      // Tap 'Done' button on banner
      final doneBtn = find.byKey(const ValueKey('chroma_banner_done_btn'));
      expect(doneBtn, findsOneWidget);
      await tester.tap(doneBtn);
      await tester.pump();
      expect(controller.state.isChromaKeyPickingMode, isFalse);
    });

    test('ChromaKeyFilter preserves white text / lyrics while removing compressed green screen', () {
      const config = ChromaKeyConfigEntity(
        isEnabled: true,
        keyColorHex: 0xFF00FF00,
        intensity: 0.50,
        edgeSoftness: 0.15,
        spillSuppression: 0.30,
      );
      final matrix = ChromaKeyFilter.createMatrix(config);
      final aR = matrix[15];
      final aG = matrix[16];
      final aB = matrix[17];
      final aA = matrix[18];
      final aOffset = matrix[19];

      // 1. Compressed/shadowed green pixel: R=25, G=160, B=35, A=255
      final alphaGreen = aR * 25 + aG * 160 + aB * 35 + aA * 255 + aOffset;
      expect(alphaGreen, lessThanOrEqualTo(0.0), reason: 'Green pixels must drop below 0 alpha for 100% transparency');

      // 2. White lyrics / text pixel: R=255, G=255, B=255, A=255
      final alphaWhiteText = aR * 255 + aG * 255 + aB * 255 + aA * 255 + aOffset;
      expect(alphaWhiteText, greaterThanOrEqualTo(255.0), reason: 'White text/lyrics must remain 100% solid opaque');

      // 3. Natural skin / hair tone: R=190, G=130, B=90, A=255
      final alphaSkin = aR * 190 + aG * 130 + aB * 90 + aA * 255 + aOffset;
      expect(alphaSkin, greaterThanOrEqualTo(255.0), reason: 'Skin tones must remain 100% solid opaque');
    });

    test('Overlay clip duration sync preserves timelineStartMs and expands project duration', () {
      final mainClip = VideoClipEntity(
        id: 'main_photo',
        mediaPath: 'photo.jpg',
        name: 'Main Photo',
        sourceDurationMs: 4000,
        timelineStartMs: 0,
        timelineEndMs: 4000,
        trimStartMs: 0,
        trimEndMs: 4000,
      );

      final project = ProjectEntity(
        id: 'p_test',
        title: 'Overlay Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 4000,
        videoClips: [mainClip],
      );

      final controller = EditorController(project: project);
      addTearDown(() => controller.dispose());

      // Add overlay video at playhead 1000ms
      controller.seekTo(1000);
      controller.addOverlayClip(
        name: 'Overlay Lyrics Video',
        mediaPath: 'overlay.mp4',
        durationMs: 3000,
      );

      final overlayClip = controller.state.project.videoClips.firstWhere((c) => c.isOverlay);
      expect(overlayClip.timelineStartMs, equals(1000));
      expect(overlayClip.timelineEndMs, equals(4000));

      // Simulate video controller reporting real duration of 7200ms
      controller.syncClipRealDuration(overlayClip.id, 7200);

      final syncedOverlay = controller.state.project.videoClips.firstWhere((c) => c.id == overlayClip.id);
      // Verify timelineStartMs was PRESERVED (not pushed sequentially to the end!)
      expect(syncedOverlay.timelineStartMs, equals(1000));
      expect(syncedOverlay.timelineEndMs, equals(8200));
      expect(controller.state.project.durationMs, greaterThanOrEqualTo(8200));

      // Test toggleChromaKeyPickingMode
      expect(controller.state.isChromaKeyPickingMode, isFalse);
      controller.openChromaKeyMode(overlayClip.id);
      expect(controller.state.isChromaKeyPickingMode, isTrue);
      expect(controller.state.chromaKeyTargetClipId, equals(overlayClip.id));

      controller.toggleChromaKeyPickingMode();
      expect(controller.state.isChromaKeyPickingMode, isFalse);
      // Target clip remains set so ChromaKeySheet stays visible for adjusting sliders
      expect(controller.state.chromaKeyTargetClipId, equals(overlayClip.id));
    });
  });
}
