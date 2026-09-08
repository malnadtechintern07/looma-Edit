import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/core/services/gallery_saver_service.dart';
import 'package:looma/features/photo_editor/data/datasources/photo_exporter_service.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_frame_entity.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_project_entity.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_sticker_overlay_entity.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_text_overlay_entity.dart';
import 'package:looma/features/photo_editor/presentation/providers/photo_editor_controller.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_adjust_sheet.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_canvas.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_crop_sheet.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_layout_sheet.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_text_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> channelCalls = [];

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

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('looma/gallery_saver'),
      (MethodCall methodCall) async {
        channelCalls.add(methodCall);
        if (methodCall.method == 'saveImageToGallery') {
          return 'content://media/external/images/media/999';
        }
        if (methodCall.method == 'scanFile') {
          return methodCall.arguments['path'] ?? 'scanned_ok';
        }
        return null;
      },
    );
  });

  tearDown(() {
    channelCalls.clear();
  });

  group('Fix 1: Gallery Export Tests', () {
    test('GallerySaverService saveImageToDeviceGallery invokes channel or saves image', () async {
      // Create a temporary dummy file to test
      final tempFile = File('test_export_dummy.png');
      await tempFile.writeAsBytes([0, 1, 2, 3]);

      try {
        final result = await GallerySaverService.saveImageToDeviceGallery(
          sourceFilePath: tempFile.path,
          fileName: 'looma_test_photo.png',
          isPng: true,
        );

        expect(result, isNotNull);
      } finally {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    });

    test('PhotoExporterService exists and instantiates properly', () {
      final service = PhotoExporterService();
      expect(service, isNotNull);
    });
  });

  group('Fix 2 & 3: Tap to Add & Controller Slot Slot Setting', () {
    test('PhotoEditorController setPhotoFrameAt replaces or adds photo at slot index', () {
      final initialProject = PhotoProjectEntity(
        id: 'proj_slot_test',
        title: 'Slot Test',
        frames: const [
          PhotoFrameEntity(id: 'frame_0', imagePath: 'image_0.jpg'),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = PhotoEditorController(initialProject);

      // Add into slot 1 (empty slot)
      controller.setPhotoFrameAt(1, 'image_1.jpg');
      expect(controller.state.project.frames.length, 2);
      expect(controller.state.project.frames[1].imagePath, 'image_1.jpg');

      // Replace slot 0
      controller.setPhotoFrameAt(0, 'image_0_new.jpg');
      expect(controller.state.project.frames.length, 2);
      expect(controller.state.project.frames[0].imagePath, 'image_0_new.jpg');
    });

    testWidgets('PhotoCanvas empty slot shows Tap to add and triggers onImportSlot on tap', (tester) async {
      final emptyProject = PhotoProjectEntity(
        id: 'empty_proj',
        title: 'Empty Collage',
        collageLayout: CollageLayoutType.grid2Vertical,
        frames: const [], // Both slots are empty!
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = PhotoEditorController(emptyProject);
      int? tappedSlotIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoCanvas(
              boundaryKey: GlobalKey(),
              project: emptyProject,
              state: controller.state,
              controller: controller,
              onImportSlot: (slotIndex) {
                tappedSlotIndex = slotIndex;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find 'Tap to add' text widgets
      final tapToAddFinders = find.text('Tap to add');
      expect(tapToAddFinders, findsNWidgets(2));

      // Tap on the first empty slot
      await tester.tap(tapToAddFinders.first);
      await tester.pumpAndSettle();

      expect(tappedSlotIndex, 0);
    });
  });

  group('Fix 4: Text & Sticker Zooming, Rotating, and Selection Handles', () {
    testWidgets('PhotoCanvas renders selected text with Edit, Delete, and Rotate/Scale handles', (tester) async {
      const textItem = PhotoTextOverlayEntity(
        id: 'text_1',
        text: 'VIBRANT ART',
        positionX: 120,
        positionY: 120,
        scale: 1.2,
        rotation: 0.1,
        colorHex: 0xFFFF3B5C,
      );

      final projectWithText = PhotoProjectEntity(
        id: 'proj_text',
        title: 'Text Overlay',
        frames: const [PhotoFrameEntity(id: 'f1', imagePath: 'img.jpg')],
        textOverlays: const [textItem],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = PhotoEditorController(projectWithText);
      controller.selectText('text_1');

      PhotoTextOverlayEntity? editedText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoCanvas(
              boundaryKey: GlobalKey(),
              project: controller.state.project,
              state: controller.state,
              controller: controller,
              onEditText: (t) => editedText = t,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Text is rendered
      expect(find.text('VIBRANT ART'), findsOneWidget);

      // Selected handles are present: Close (Delete), Edit, Crop Rotate (Scale/Rotate)
      expect(find.byIcon(Icons.close), findsWidgets);
      expect(find.byIcon(Icons.edit), findsWidgets);
      expect(find.byIcon(Icons.crop_rotate), findsWidgets);

      // Floating quick color toolbar is visible
      expect(find.byIcon(Icons.palette), findsOneWidget);

      // Tapping Edit in toolbar triggers callback
      await tester.tap(find.byIcon(Icons.edit).at(1));
      await tester.pumpAndSettle();
      expect(editedText?.id, 'text_1');
    });

    testWidgets('PhotoCanvas renders selected sticker with Delete and Rotate/Scale handles', (tester) async {
      const stickerItem = PhotoStickerOverlayEntity(
        id: 'sticker_1',
        assetPath: '🔥',
        scale: 1.2,
        rotation: 0.1,
      );

      final projectWithSticker = PhotoProjectEntity(
        id: 'proj_sticker',
        title: 'Sticker Overlay',
        frames: const [PhotoFrameEntity(id: 'f1', imagePath: 'img.jpg')],
        stickerOverlays: const [stickerItem],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = PhotoEditorController(projectWithSticker);
      controller.selectSticker('sticker_1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoCanvas(
              boundaryKey: GlobalKey(),
              project: controller.state.project,
              state: controller.state,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🔥'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsWidgets);
      expect(find.byIcon(Icons.crop_rotate), findsWidgets);
    });
  });

  group('Fix 5: No Layout Overflows on Compact/Narrow Devices', () {
    testWidgets('PhotoCropSheet subtabs do not overflow on narrow (320px) screens', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testProject = PhotoProjectEntity(
        id: 'proj_narrow',
        title: 'Narrow Screen',
        frames: const [PhotoFrameEntity(id: 'f1', imagePath: 'img.jpg')],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoCropSheet(
              project: testProject,
              selectedFrameId: 'f1',
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow error and subtabs rendered
      expect(find.text('Crop & Perspective'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PhotoLayoutSheet background chips and swatches do not overflow on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testProject = PhotoProjectEntity(
        id: 'proj_narrow_layout',
        title: 'Narrow Layout',
        frames: const [PhotoFrameEntity(id: 'f1', imagePath: 'img.jpg')],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoLayoutSheet(
              project: testProject,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Solid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PhotoAdjustSheet header does not overflow on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testProject = PhotoProjectEntity(
        id: 'proj_narrow_adjust',
        title: 'Narrow Adjust',
        frames: const [PhotoFrameEntity(id: 'f1', imagePath: 'img.jpg')],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoAdjustSheet(
              project: testProject,
              selectedFrameId: 'f1',
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final error = tester.takeException();
      if (error is FlutterError) {
        for (final d in error.diagnostics) {
          debugPrint('NODE: ${d.name} => ${d.toDescription()}');
        }
      }
      expect(error, isNull);
    });

    testWidgets('PhotoTextSheet live typography preview is rendered', (tester) async {
      final testProject = PhotoProjectEntity(
        id: 'proj_text_sheet',
        title: 'Text Sheet Test',
        frames: const [PhotoFrameEntity(id: 'f1', imagePath: 'img.jpg')],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoTextSheet(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Typography Preview'), findsNothing); // Has default text LOOMA CREATIVE
      expect(find.text('LOOMA CREATIVE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
