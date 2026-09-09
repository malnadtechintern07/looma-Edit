import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/photo_editor/domain/entities/drawing_stroke_entity.dart';
import 'package:procut/features/photo_editor/domain/entities/photo_frame_entity.dart';
import 'package:procut/features/photo_editor/domain/entities/photo_project_entity.dart';
import 'package:procut/features/photo_editor/data/datasources/photo_local_datasource.dart';
import 'package:procut/features/photo_editor/data/repositories/photo_project_repository.dart';
import 'package:procut/features/photo_editor/presentation/providers/photo_editor_controller.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_adjust_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_crop_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_curves_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_draw_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_export_dialog.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_hsl_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_layout_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_resize_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_sticker_sheet.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_text_sheet.dart';

class FakePhotoProjectRepository extends PhotoProjectRepository {
  FakePhotoProjectRepository() : super(PhotoLocalDataSource());

  @override
  Future<List<PhotoProjectEntity>> getPhotoProjects() async => [];

  @override
  Future<void> savePhotoProject(PhotoProjectEntity project) async {}

  @override
  Future<void> deletePhotoProject(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') return <String, dynamic>{};
        return true;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider_macos'),
      (MethodCall methodCall) async => '.',
    );
  });

  final testProject = PhotoProjectEntity(
    id: 'test_pro_project_1',
    title: 'Professional Masterpiece',
    frames: const [
      PhotoFrameEntity(id: 'frame_1', imagePath: 'test_image.jpg'),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('PhotoFrameEntity Pro Properties Tests', () {
    test('Default values are initialized properly', () {
      const frame = PhotoFrameEntity(id: 'frame_1', imagePath: 'test.jpg');

      expect(frame.cropLeft, 0.0);
      expect(frame.cropTop, 0.0);
      expect(frame.cropRight, 1.0);
      expect(frame.cropBottom, 1.0);
      expect(frame.flipHorizontal, false);
      expect(frame.flipVertical, false);
      expect(frame.straighten, 0.0);
      expect(frame.perspectiveX, 0.0);
      expect(frame.perspectiveY, 0.0);
      expect(frame.exposure, 0.0);
      expect(frame.highlights, 0.0);
      expect(frame.shadows, 0.0);
      expect(frame.vibrance, 0.0);
      expect(frame.temperature, 0.0);
      expect(frame.tint, 0.0);
      expect(frame.sharpness, 0.0);
      expect(frame.blur, 0.0);
      expect(frame.vignette, 0.0);
      expect(frame.grain, 0.0);
      expect(frame.fade, 0.0);
      expect(frame.hslAdjustments, isEmpty);
      expect(frame.toneCurves, isEmpty);
    });

    test('copyWith updates all pro editing values', () {
      final frame = const PhotoFrameEntity(id: 'frame_1', imagePath: 'test.jpg').copyWith(
        cropLeft: 0.1,
        cropTop: 0.1,
        cropRight: 0.9,
        cropBottom: 0.9,
        flipHorizontal: true,
        flipVertical: true,
        straighten: 15.0,
        perspectiveX: -10.0,
        perspectiveY: 12.0,
        exposure: 0.4,
        highlights: -0.3,
        shadows: 0.2,
        vibrance: 0.5,
        temperature: 0.3,
        tint: -0.2,
        sharpness: 0.6,
        blur: 5.0,
        vignette: 0.7,
        grain: 0.35,
        fade: 0.25,
        hslAdjustments: {
          'Red': {'hue': 10.0, 'sat': 20.0, 'lum': -10.0}
        },
        toneCurves: {
          'RGB': [0.0, 0.2, 0.5, 0.8, 1.0]
        },
      );

      expect(frame.cropLeft, 0.1);
      expect(frame.cropRight, 0.9);
      expect(frame.flipHorizontal, true);
      expect(frame.flipVertical, true);
      expect(frame.straighten, 15.0);
      expect(frame.perspectiveX, -10.0);
      expect(frame.perspectiveY, 12.0);
      expect(frame.exposure, 0.4);
      expect(frame.highlights, -0.3);
      expect(frame.shadows, 0.2);
      expect(frame.vibrance, 0.5);
      expect(frame.temperature, 0.3);
      expect(frame.tint, -0.2);
      expect(frame.sharpness, 0.6);
      expect(frame.blur, 5.0);
      expect(frame.vignette, 0.7);
      expect(frame.grain, 0.35);
      expect(frame.fade, 0.25);
      expect(frame.hslAdjustments['Red']?['hue'], 10.0);
      expect(frame.toneCurves['RGB'], [0.0, 0.2, 0.5, 0.8, 1.0]);
    });
  });

  group('PhotoProjectEntity Pro Background & Export Tests', () {
    test('Background options and custom export dimensions work correctly', () {
      final project = PhotoProjectEntity(
        id: 'proj_1',
        title: 'Pro Photo Project',
        frames: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        backgroundType: 'gradient',
        gradientColorsHex: const [0xFFFF0000, 0xFF0000FF],
        blurBackgroundRadius: 15.0,
        exportWidth: 3840,
        exportHeight: 2160,
      );

      expect(project.backgroundType, 'gradient');
      expect(project.gradientColorsHex.length, 2);
      expect(project.blurBackgroundRadius, 15.0);
      expect(project.exportWidth, 3840);
      expect(project.exportHeight, 2160);
    });
  });

  group('PhotoEditorController Pro State Management Tests', () {
    test('Adjustments, effects, HSL, and Curves update state properly', () {
      final controller = PhotoEditorController(testProject, FakePhotoProjectRepository());
      final frameId = testProject.frames.first.id;

      // Update Adjustments
      controller.updateFrameAdjustments(
        frameId,
        brightness: 0.2,
        contrast: 0.3,
        exposure: 0.1,
        highlights: -0.2,
        shadows: 0.15,
        saturation: 0.4,
        vibrance: 0.3,
        temperature: 0.1,
        tint: -0.05,
        sharpness: 0.5,
      );

      var updatedFrame = controller.state.project.frames.first;
      expect(updatedFrame.brightness, 0.2);
      expect(updatedFrame.contrast, 0.3);
      expect(updatedFrame.exposure, 0.1);
      expect(updatedFrame.highlights, -0.2);
      expect(updatedFrame.shadows, 0.15);
      expect(updatedFrame.saturation, 0.4);
      expect(updatedFrame.vibrance, 0.3);
      expect(updatedFrame.temperature, 0.1);
      expect(updatedFrame.tint, -0.05);
      expect(updatedFrame.sharpness, 0.5);

      // Update Effects
      controller.updateFrameEffects(
        frameId,
        blur: 4.0,
        vignette: 0.6,
        grain: 0.3,
        fade: 0.2,
      );

      updatedFrame = controller.state.project.frames.first;
      expect(updatedFrame.blur, 4.0);
      expect(updatedFrame.vignette, 0.6);
      expect(updatedFrame.grain, 0.3);
      expect(updatedFrame.fade, 0.2);

      // Update Transform & Geometry
      controller.updateFrameTransformGeometry(
        frameId,
        rotationDelta: pi / 2.0,
        flipHorizontal: true,
        flipVertical: false,
        straighten: 12.0,
        perspectiveX: 5.0,
        perspectiveY: -7.0,
      );

      updatedFrame = controller.state.project.frames.first;
      expect(updatedFrame.rotation, closeTo(pi / 2.0, 0.001));
      expect(updatedFrame.flipHorizontal, true);
      expect(updatedFrame.flipVertical, false);
      expect(updatedFrame.straighten, 12.0);
      expect(updatedFrame.perspectiveX, 5.0);
      expect(updatedFrame.perspectiveY, -7.0);

      // Update Crop
      controller.updateFrameCrop(
        frameId,
        cropLeft: 0.1,
        cropTop: 0.05,
        cropRight: 0.9,
        cropBottom: 0.95,
      );

      updatedFrame = controller.state.project.frames.first;
      expect(updatedFrame.cropLeft, 0.1);
      expect(updatedFrame.cropTop, 0.05);

      // Update HSL
      controller.updateFrameHsl(
        frameId,
        'Aqua',
        hue: 25.0,
        sat: -30.0,
        lum: 15.0,
      );

      updatedFrame = controller.state.project.frames.first;
      expect(updatedFrame.hslAdjustments['Aqua']?['hue'], 25.0);
      expect(updatedFrame.hslAdjustments['Aqua']?['sat'], -30.0);
      expect(updatedFrame.hslAdjustments['Aqua']?['lum'], 15.0);

      // Update Curves
      controller.updateFrameCurves(
        frameId,
        'Blue',
        blacks: 5.0,
        shadows: 10.0,
        midtones: -5.0,
        highlights: 15.0,
        whites: 20.0,
      );

      updatedFrame = controller.state.project.frames.first;
      expect(updatedFrame.toneCurves['Blue'], [5.0, 10.0, -5.0, 15.0, 20.0]);

      // Reset individual adjustments
      controller.resetFrameAdjustments(frameId);
      updatedFrame = controller.state.project.frames.first;
      expect(updatedFrame.brightness, 0.0);
      expect(updatedFrame.contrast, 1.0);
      expect(updatedFrame.exposure, 0.0);
      expect(updatedFrame.blur, 0.0);
      expect(updatedFrame.vignette, 0.0);

      // Reset All
      controller.resetAll(frameId);
      final resetFrame = controller.state.project.frames.first;
      expect(resetFrame.cropLeft, 0.0);
      expect(resetFrame.rotation, 0.0);
      expect(resetFrame.hslAdjustments, isEmpty);
      expect(resetFrame.toneCurves, isEmpty);
    });

    test('Undo, Redo, Compare toggle, and Zoom work reliably', () {
      final controller = PhotoEditorController(testProject, FakePhotoProjectRepository());
      final frameId = testProject.frames.first.id;

      // Make changes with history recording
      controller.updateFrameAdjustments(frameId, brightness: 0.5, recordHistory: true);
      expect(controller.state.project.frames.first.brightness, 0.5);
      expect(controller.state.canUndo, true);

      // Undo
      controller.undo();
      expect(controller.state.project.frames.first.brightness, 0.0);
      expect(controller.state.canRedo, true);

      // Redo
      controller.redo();
      expect(controller.state.project.frames.first.brightness, 0.5);

      // Compare mode toggle
      expect(controller.state.isComparing, false);
      controller.setComparing(true);
      expect(controller.state.isComparing, true);
      controller.setComparing(false);
      expect(controller.state.isComparing, false);

      // Zoom Scale
      expect(controller.state.zoomScale, 1.0);
      controller.setZoomScale(2.5);
      expect(controller.state.zoomScale, 2.5);
    });

    test('Drawing brush types and eraser mode', () {
      final controller = PhotoEditorController(testProject, FakePhotoProjectRepository());

      // Add a stroke
      const stroke = DrawingStrokeEntity(
        points: [Offset(50, 50), Offset(55, 55)],
        colorHex: 0xFFFFFF00,
        strokeWidth: 5.0,
        brushType: 'neon',
        opacity: 0.9,
      );
      controller.addDrawingStroke(stroke);
      expect(controller.state.project.drawingStrokes.length, 1);

      // Toggle eraser
      expect(controller.state.isEraserMode, false);
      controller.toggleEraserMode(true);
      expect(controller.state.isEraserMode, true);

      // Set brush type
      controller.setBrushType('marker');
      expect(controller.state.brushType, 'marker');

      // Erase stroke near (52, 52)
      controller.eraseStrokesNear(const Offset(52, 52), 20.0);
      expect(controller.state.project.drawingStrokes.isEmpty, true);
    });
  });

  group('Pro Bottom Sheets Widgets Tests', () {
    testWidgets('PhotoCropSheet renders all tabs, presets, rotate, flip, and sliders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late PhotoEditorController activeController;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(photoEditorControllerProvider(testProject).notifier);
              final state = ref.watch(photoEditorControllerProvider(testProject));
              activeController = controller;
              return MaterialApp(
                home: Scaffold(
                  body: PhotoCropSheet(
                    project: state.project,
                    controller: controller,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Crop & Perspective'), findsOneWidget);
      expect(find.text('✂️ Aspect'), findsOneWidget);
      expect(find.text('🔄 Rotate/Flip'), findsOneWidget);
      expect(find.text('📐 Straighten'), findsOneWidget);
      expect(find.text('🔲 3D Tilt'), findsOneWidget);

      // Crop Tab Presets
      expect(find.text('Freeform'), findsOneWidget);
      expect(find.text('1:1 Square'), findsOneWidget);
      expect(find.text('4:5 Feed'), findsOneWidget);
      expect(find.text('9:16 Story'), findsOneWidget);
      expect(find.text('16:9 Cinema'), findsOneWidget);

      // Switch to Rotate Tab
      await tester.tap(find.text('🔄 Rotate/Flip'));
      await tester.pumpAndSettle();

      expect(find.text('90° Left'), findsOneWidget);
      expect(find.text('90° Right'), findsOneWidget);
      expect(find.text('Flip Horiz'), findsOneWidget);
      expect(find.text('Flip Vert'), findsOneWidget);

      // Tap 90° Right
      await tester.tap(find.text('90° Right'));
      await tester.pumpAndSettle();
      expect(activeController.state.project.frames.first.rotation, closeTo(pi / 2.0, 0.001));

      // Tap Flip Horiz
      await tester.tap(find.text('Flip Horiz'));
      await tester.pumpAndSettle();
      expect(activeController.state.project.frames.first.flipHorizontal, true);

      // Switch to Straighten Tab
      await tester.tap(find.text('📐 Straighten'));
      await tester.pumpAndSettle();
      expect(find.text('FINE ROTATION'), findsOneWidget);

      // Switch to 3D Tilt Tab
      await tester.tap(find.text('🔲 3D Tilt'));
      await tester.pumpAndSettle();
      expect(find.text('VERTICAL PERSPECTIVE'), findsOneWidget);
      expect(find.text('HORIZONTAL PERSPECTIVE'), findsOneWidget);
    });

    testWidgets('PhotoResizeSheet renders custom resolution inputs and aspect presets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late PhotoEditorController activeController;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(photoEditorControllerProvider(testProject).notifier);
              final state = ref.watch(photoEditorControllerProvider(testProject));
              activeController = controller;
              return MaterialApp(
                home: Scaffold(
                  body: PhotoResizeSheet(
                    project: state.project,
                    controller: controller,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resize Dimensions'), findsOneWidget);
      expect(find.text('WIDTH (PX)'), findsOneWidget);
      expect(find.text('HEIGHT (PX)'), findsOneWidget);
      expect(find.text('4K UHD (3840x2160)'), findsOneWidget);
      expect(find.text('1080p FHD (1920x1080)'), findsOneWidget);
      expect(find.text('Apply Resize Dimensions'), findsOneWidget);

      // Tap 4K UHD preset
      await tester.tap(find.text('4K UHD (3840x2160)'));
      await tester.pumpAndSettle();

      // Tap Apply Resize Dimensions
      await tester.tap(find.text('Apply Resize Dimensions'));
      await tester.pumpAndSettle();

      expect(activeController.state.project.exportWidth, 3840);
      expect(activeController.state.project.exportHeight, 2160);
    });

    testWidgets('PhotoHslSheet renders 8 color channels and Hue/Sat/Lum sliders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(photoEditorControllerProvider(testProject).notifier);
              final state = ref.watch(photoEditorControllerProvider(testProject));
              return MaterialApp(
                home: Scaffold(
                  body: PhotoHslSheet(
                    project: state.project,
                    controller: controller,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HSL Color Channels'), findsOneWidget);
      expect(find.text('Red Channel'), findsOneWidget);
      expect(find.text('HUE'), findsOneWidget);
      expect(find.text('SATURATION'), findsOneWidget);
      expect(find.text('LUMINANCE'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('PhotoCurvesSheet renders RGB/R/G/B channels and tone curve visualizer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(photoEditorControllerProvider(testProject).notifier);
              final state = ref.watch(photoEditorControllerProvider(testProject));
              return MaterialApp(
                home: Scaffold(
                  body: PhotoCurvesSheet(
                    project: state.project,
                    controller: controller,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tone Curves'), findsOneWidget);
      expect(find.text('RGB'), findsOneWidget);
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Blacks'), findsOneWidget);
      expect(find.text('Shadows'), findsOneWidget);
      expect(find.text('Midtones'), findsOneWidget);
      expect(find.text('Highlights'), findsOneWidget);
      expect(find.text('Whites'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('PhotoAdjustSheet renders categorized sections and Hold to Compare', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(photoEditorControllerProvider(testProject).notifier);
              final state = ref.watch(photoEditorControllerProvider(testProject));
              return MaterialApp(
                home: Scaffold(
                  body: PhotoAdjustSheet(
                    project: state.project,
                    controller: controller,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LIGHT & TONE'), findsOneWidget);
      expect(find.text('COLOR & WHITE BALANCE'), findsOneWidget);
      expect(find.text('DETAIL & EFFECTS'), findsOneWidget);
      expect(find.text('Reset All'), findsOneWidget);
      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('BRIGHTNESS'), findsOneWidget);
      expect(find.text('CONTRAST'), findsOneWidget);
      expect(find.text('EXPOSURE'), findsOneWidget);
      expect(find.text('HIGHLIGHTS'), findsOneWidget);
      expect(find.text('SHADOWS'), findsOneWidget);
      expect(find.text('SATURATION'), findsOneWidget);
      expect(find.text('VIBRANCE'), findsOneWidget);
      expect(find.text('TEMPERATURE'), findsOneWidget);
      expect(find.text('TINT'), findsOneWidget);
      expect(find.text('SHARPNESS'), findsOneWidget);
      expect(find.text('BLUR'), findsOneWidget);
      expect(find.text('VIGNETTE'), findsOneWidget);
      expect(find.text('GRAIN'), findsOneWidget);
      expect(find.text('FADE'), findsOneWidget);
    });

    testWidgets('PhotoTextSheet allows configuring alignment, spacing, opacity', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late PhotoEditorController activeController;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(photoEditorControllerProvider(testProject).notifier);
              activeController = controller;
              return MaterialApp(
                home: Scaffold(
                  body: PhotoTextSheet(controller: controller),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Professional Text'), findsOneWidget);
      expect(find.text('FONT SIZE'), findsOneWidget);
      expect(find.text('LETTER SPACING'), findsOneWidget);
      expect(find.text('TEXT OPACITY'), findsOneWidget);
      expect(find.text('TEXT COLOR'), findsOneWidget);
      expect(find.text('Add to Canvas'), findsOneWidget);

      // Enter text and add
      await tester.enterText(find.byType(TextField), 'ProCut Pro Editor');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Canvas'));
      await tester.pumpAndSettle();

      expect(activeController.state.project.textOverlays.length, 1);
      expect(activeController.state.project.textOverlays.first.text, 'ProCut Pro Editor');
    });

    testWidgets('PhotoStickerSheet supports Shapes tab with vector shapes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late PhotoEditorController activeController;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(photoEditorControllerProvider(testProject).notifier);
              activeController = controller;
              return MaterialApp(
                home: Scaffold(
                  body: PhotoStickerSheet(controller: controller),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Vector Shapes Tab
      await tester.tap(find.text('Vector Shapes'));
      await tester.pumpAndSettle();

      expect(find.text('Circle'), findsOneWidget);
      expect(find.text('Rectangle'), findsOneWidget);
      expect(find.text('Rounded'), findsOneWidget);

      // Tap Circle shape
      await tester.tap(find.text('Circle'));
      await tester.pumpAndSettle();

      final stickers = activeController.state.project.stickerOverlays;
      expect(stickers.length, 1);
      expect(stickers.first.isShape, true);
      expect(stickers.first.shapeType, 'circle');
    });

    testWidgets('PhotoDrawSheet supports Pen, Marker, Neon and Eraser toggle', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late PhotoEditorController activeController;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(photoEditorControllerProvider(testProject).notifier);
              final state = ref.watch(photoEditorControllerProvider(testProject));
              activeController = controller;
              return MaterialApp(
                home: Scaffold(
                  body: PhotoDrawSheet(
                    state: state,
                    controller: controller,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🖊️ Solid Pen'), findsOneWidget);
      expect(find.text('🖍️ Marker'), findsOneWidget);
      expect(find.text('✨ Neon Glow'), findsOneWidget);
      expect(find.text('Brush Mode'), findsOneWidget);
      expect(find.text('Eraser Mode'), findsOneWidget);
      expect(find.text('STROKE WIDTH'), findsOneWidget);
      expect(find.text('BRUSH COLOR'), findsOneWidget);

      // Switch to Neon Glow
      await tester.tap(find.text('✨ Neon Glow'));
      await tester.pumpAndSettle();
      expect(activeController.state.brushType, 'neon');

      // Switch to Eraser Mode
      await tester.tap(find.text('Eraser Mode'));
      await tester.pumpAndSettle();
      expect(activeController.state.isEraserMode, true);
    });

    testWidgets('PhotoLayoutSheet supports solid, gradient, photo-blur backgrounds', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late PhotoEditorController activeController;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(photoEditorControllerProvider(testProject).notifier);
              final state = ref.watch(photoEditorControllerProvider(testProject));
              activeController = controller;
              return MaterialApp(
                home: Scaffold(
                  body: PhotoLayoutSheet(
                    project: state.project,
                    controller: controller,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BACKGROUND STYLE'), findsOneWidget);
      expect(find.text('Solid'), findsOneWidget);
      expect(find.text('Gradient'), findsOneWidget);
      expect(find.text('Photo Blur'), findsOneWidget);
      expect(find.text('Transparent'), findsOneWidget);

      // Select Gradient
      await tester.tap(find.text('Gradient'));
      await tester.pumpAndSettle();
      expect(activeController.state.project.backgroundType, 'gradient');

      // Select Photo Blur
      await tester.tap(find.text('Photo Blur'));
      await tester.pumpAndSettle();
      expect(activeController.state.project.backgroundType, 'blur');
    });

    testWidgets('PhotoExportDialog supports PNG, JPEG, 4K UHD, and Share Image', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PhotoExportDialog(
                boundaryKey: boundaryKey,
                projectTitle: 'Editorial Shoot',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export High-Res Image'), findsOneWidget);
      expect(find.text('FORMAT'), findsOneWidget);
      expect(find.text('PNG (Lossless)'), findsOneWidget);
      expect(find.text('JPEG (Compact)'), findsOneWidget);
      expect(find.text('RESOLUTION QUALITY'), findsOneWidget);
      expect(find.text('1080p (2x)'), findsOneWidget);
      expect(find.text('4K (3x Ultra)'), findsOneWidget);
      expect(find.text('Export Now'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
