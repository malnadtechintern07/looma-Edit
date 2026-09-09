import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:procut/features/photo_editor/domain/entities/photo_frame_entity.dart';
import 'package:procut/features/photo_editor/domain/entities/photo_project_entity.dart';
import 'package:procut/features/photo_editor/domain/services/photo_auto_enhance_service.dart';
import 'package:procut/features/photo_editor/domain/services/photo_autocut_service.dart';
import 'package:procut/features/photo_editor/domain/services/photo_bg_remover_service.dart';
import 'package:procut/features/photo_editor/domain/services/photo_retouch_service.dart';
import 'package:procut/features/photo_editor/presentation/providers/photo_editor_controller.dart';
import 'package:procut/features/photo_editor/presentation/screens/photo_editor_screen.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_auto_enhance_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_autocut_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_remove_bg_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_retouch_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoBgRemoverService Unit Tests', () {
    late PhotoBgRemoverService service;

    setUp(() {
      service = PhotoBgRemoverService();
    });

    test('processImageMatte generates transparent background for white border pixels', () {
      // Create a 100x100 test image with white background (border) and blue center subject
      final testImage = img.Image(width: 100, height: 100, numChannels: 4);
      // Fill background with pure white
      img.fill(testImage, color: img.ColorRgba8(255, 255, 255, 255));
      // Draw a center circle with vibrant blue (subject)
      img.fillCircle(testImage, x: 50, y: 50, radius: 25, color: img.ColorRgba8(0, 50, 220, 255));

      final output = service.processImageMatte(
        image: testImage,
        sensitivity: 0.5,
        featherRadius: 1,
      );

      // Border corners should be transparent
      final cornerPixel = output.getPixel(0, 0);
      expect(cornerPixel.a, lessThan(20));

      // Center subject pixel should remain solid
      final centerPixel = output.getPixel(50, 50);
      expect(centerPixel.a, greaterThan(200));
      expect(centerPixel.b, greaterThan(150));
    });

    test('generatePreviewBytes produces valid non-empty PNG buffer', () {
      final testImage = img.Image(width: 80, height: 80);
      img.fill(testImage, color: img.ColorRgb8(240, 240, 240));
      img.fillRect(testImage, x1: 20, y1: 20, x2: 60, y2: 60, color: img.ColorRgb8(10, 180, 50));

      final bytes = service.generatePreviewBytes(
        original: testImage,
        sensitivity: 0.6,
        featherRadius: 1,
      );

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
    });
  });

  group('PhotoAutoCutService Unit Tests', () {
    late PhotoAutoCutService service;

    setUp(() {
      service = PhotoAutoCutService();
    });

    test('generateInitialMask segments central subject and applyStrokesToMask refines', () {
      final testImage = img.Image(width: 60, height: 60);
      img.fill(testImage, color: img.ColorRgb8(255, 255, 255)); // white bg
      img.fillCircle(testImage, x: 30, y: 30, radius: 15, color: img.ColorRgb8(200, 20, 40)); // red subject

      final mask = service.generateInitialMask(testImage);
      expect(mask.length, equals(60 * 60));

      // Center pixel should be foreground (255)
      expect(mask[30 * 60 + 30], equals(255));
      // Corner pixel should be background (0)
      expect(mask[0], equals(0));

      // Apply Erase stroke over center to erase it
      service.applyStrokesToMask(
        mask: mask,
        width: 60,
        height: 60,
        strokes: [
          const CutoutStroke(
            points: [Offset(0.5, 0.5)],
            isErase: true,
            radius: 0.15,
          ),
        ],
      );

      // Center pixel should now be erased (0)
      expect(mask[30 * 60 + 30], equals(0));
    });
  });

  group('PhotoRetouchService Unit Tests', () {
    late PhotoRetouchService service;

    setUp(() {
      service = PhotoRetouchService();
    });

    test('Blemish removal inpainting replaces spot with donor neighborhood color', () {
      // Create 50x50 image of skin tone (approx R=210, G=160, B=140)
      final testImage = img.Image(width: 50, height: 50, numChannels: 4);
      img.fill(testImage, color: img.ColorRgba8(210, 160, 140, 255));
      // Add a dark blemish at (25, 25)
      img.fillCircle(testImage, x: 25, y: 25, radius: 3, color: img.ColorRgba8(30, 20, 20, 255));

      // Verify blemish exists before retouch
      final beforePixel = testImage.getPixel(25, 25);
      expect(beforePixel.r, lessThan(60));

      // Apply Blemish Heal stroke
      service.applyStrokeToImage(
        image: testImage,
        stroke: const RetouchStroke(
          mode: RetouchMode.blemish,
          points: [Offset(0.5, 0.5)],
          radius: 0.12,
          intensity: 1.0,
        ),
      );

      // Center pixel should now be healed towards skin tone
      final afterPixel = testImage.getPixel(25, 25);
      expect(afterPixel.r, greaterThan(150));
      expect(afterPixel.g, greaterThan(110));
    });

    test('Brighten and Darken adjust luminance cleanly', () {
      final testImage = img.Image(width: 40, height: 40, numChannels: 4);
      img.fill(testImage, color: img.ColorRgba8(100, 100, 100, 255));

      // Brighten stroke on left side
      service.applyStrokeToImage(
        image: testImage,
        stroke: const RetouchStroke(
          mode: RetouchMode.brighten,
          points: [Offset(0.25, 0.5)],
          radius: 0.2,
          intensity: 0.8,
        ),
      );
      final brightened = testImage.getPixel(10, 20);
      expect(brightened.r, greaterThan(100));

      // Darken stroke on right side
      service.applyStrokeToImage(
        image: testImage,
        stroke: const RetouchStroke(
          mode: RetouchMode.darken,
          points: [Offset(0.75, 0.5)],
          radius: 0.2,
          intensity: 0.8,
        ),
      );
      final darkened = testImage.getPixel(30, 20);
      expect(darkened.r, lessThan(100));
    });
  });

  group('PhotoAutoEnhanceService Unit Tests', () {
    late PhotoAutoEnhanceService service;

    setUp(() {
      service = PhotoAutoEnhanceService();
    });

    test('computeAdjustmentsFromImage lifts shadows on underexposed images', () {
      // Dark image
      final darkImage = img.Image(width: 50, height: 50);
      img.fill(darkImage, color: img.ColorRgb8(30, 30, 30));

      final result = service.computeAdjustmentsFromImage(
        image: darkImage,
        preset: AutoEnhancePreset.balanced,
        intensity: 1.0,
      );

      expect(result.exposure, greaterThan(0.0));
      expect(result.shadows, greaterThan(0.0));
      expect(result.highlightsApplied.isNotEmpty, isTrue);
    });

    test('Preset variations apply distinct style parameters', () {
      final image = img.Image(width: 50, height: 50);
      img.fill(image, color: img.ColorRgb8(120, 120, 120));

      final portrait = service.computeAdjustmentsFromImage(
        image: image,
        preset: AutoEnhancePreset.portrait,
        intensity: 1.0,
      );
      final landscape = service.computeAdjustmentsFromImage(
        image: image,
        preset: AutoEnhancePreset.landscape,
        intensity: 1.0,
      );

      // Portrait boosts warmth (temperature) and keeps sharpness moderate
      expect(portrait.temperature, greaterThan(0.0));
      // Landscape boosts sharpness and vibrance higher
      expect(landscape.sharpness, greaterThan(portrait.sharpness));
      expect(landscape.vibrance, greaterThan(portrait.vibrance));
    });
  });

  group('Photo Editor UI & Sheet Widget Tests', () {
    final testProject = PhotoProjectEntity(
      id: 'proj_test_1',
      title: 'Studio Portrait',
      frames: const [
        PhotoFrameEntity(
          id: 'frame_test_1',
          imagePath: 'assets/branding/demo_photo1.jpg',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Widget createTestApp(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('PhotoEditorScreen renders Enhance, Remove BG, AutoCut, Retouch buttons in toolbar', (tester) async {
      await tester.pumpWidget(createTestApp(PhotoEditorScreen(project: testProject)));
      await tester.pumpAndSettle();

      // Top bar actions
      expect(find.text('Studio Portrait'), findsOneWidget);
      expect(find.byTooltip('Undo'), findsOneWidget);
      expect(find.byTooltip('Redo'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);

      // Bottom toolbar actions
      expect(find.text('Enhance'), findsOneWidget);
      expect(find.text('Remove BG'), findsOneWidget);
      expect(find.text('AutoCut'), findsOneWidget);
      expect(find.text('Retouch'), findsOneWidget);
      expect(find.text('Crop'), findsOneWidget);
      expect(find.text('Adjust'), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
    });

    testWidgets('PhotoAutoEnhanceSheet renders intensity slider, preset chips, and apply button', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        createTestApp(
          PhotoAutoEnhanceSheet(
            project: testProject,
            selectedFrameId: 'frame_test_1',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Auto Enhance'), findsOneWidget);
      expect(find.text('ENHANCE INTENSITY'), findsOneWidget);
      expect(find.text('Universal Auto'), findsOneWidget);
      expect(find.text('Portrait Glow'), findsOneWidget);
      expect(find.text('Apply Auto Enhancement'), findsOneWidget);
    });

    testWidgets('PhotoRemoveBgSheet renders sensitivity slider, backdrop chips, and apply button', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        createTestApp(
          PhotoRemoveBgSheet(
            project: testProject,
            selectedFrameId: 'frame_test_1',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remove Background'), findsOneWidget);
      expect(find.text('SENSITIVITY'), findsOneWidget);
      expect(find.text('EDGE SMOOTHNESS'), findsOneWidget);
      expect(find.text('Transparent'), findsOneWidget);
      expect(find.text('Apply Background Removal'), findsOneWidget);
    });

    testWidgets('PhotoAutoCutSheet renders Erase and Restore mode toggles and brush slider', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        createTestApp(
          PhotoAutoCutSheet(
            project: testProject,
            selectedFrameId: 'frame_test_1',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AutoCut & Refine'), findsOneWidget);
      expect(find.text('Erase BG'), findsOneWidget);
      expect(find.text('Restore Subject'), findsOneWidget);
      expect(find.text('BRUSH SIZE'), findsOneWidget);
      expect(find.text('Apply Cutout'), findsOneWidget);
    });

    testWidgets('PhotoRetouchSheet renders tool chips (Blemish, Smooth, Brighten, Darken)', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        createTestApp(
          PhotoRetouchSheet(
            project: testProject,
            selectedFrameId: 'frame_test_1',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retouch Studio'), findsOneWidget);
      expect(find.text('Blemish Heal'), findsOneWidget);
      expect(find.text('Smooth Skin'), findsOneWidget);
      expect(find.text('Brighten (Dodge)'), findsOneWidget);
      expect(find.text('Darken (Burn)'), findsOneWidget);
      expect(find.text('BRUSH SIZE'), findsOneWidget);
      expect(find.text('INTENSITY'), findsOneWidget);
    });
  });
}
