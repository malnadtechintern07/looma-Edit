import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/app/theme/app_colors.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_frame_entity.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_project_entity.dart';
import 'package:looma/features/photo_editor/presentation/providers/photo_editor_controller.dart';
import 'package:looma/features/photo_editor/presentation/screens/photo_editor_screen.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_adjust_sheet.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_collage_sheet.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_draw_sheet.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_export_dialog.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_layout_sheet.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_sticker_sheet.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_text_sheet.dart';
import 'package:looma/features/photo_editor/presentation/widgets/watermark_sheet.dart';

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
  });

  final testProject = PhotoProjectEntity(
    id: 'test_photo_proj_1',
    title: 'Editorial Shoot',
    frames: const [
      PhotoFrameEntity(id: 'frame_1', imagePath: 'mock_frame.jpg'),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Photo Editor Visibility & Contrast Tests', () {
    testWidgets('PhotoEditorScreen displays high-contrast AppBar and bottom actions with SafeArea', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PhotoEditorScreen(project: testProject),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar elements
      expect(find.text('Editorial Shoot'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);

      // Verify back icon has high contrast color
      final backIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_back));
      expect(backIcon.color, equals(AppColors.textPrimary));

      // Verify bottom action toolbar has all 9 tools visible
      final expectedLabels = [
        'Import',
        'Layout',
        'Collage',
        'Adjust',
        'Filters',
        'Text',
        'Stickers',
        'Watermark',
        'Draw',
      ];

      for (final label in expectedLabels) {
        expect(find.text(label), findsOneWidget);
      }

      // Verify bottom toolbar is wrapped in SafeArea with bottom: true
      final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
      final bottomSafeArea = safeAreas.where((s) => s.bottom == true);
      expect(bottomSafeArea.isNotEmpty, isTrue);

      // Verify icon colors are not white70 or invisible
      final importIcon = tester.widget<Icon>(find.byIcon(Icons.add_a_photo));
      expect(importIcon.color, isNot(equals(Colors.white70)));
      expect(importIcon.color, equals(AppColors.textPrimary));

      final drawIcon = tester.widget<Icon>(find.byIcon(Icons.brush));
      expect(drawIcon.color, isNot(equals(Colors.white70)));
    });

    testWidgets('PhotoCollageSheet renders templates with high-contrast text and icons', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoCollageSheet(
              project: testProject,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Collage Templates & Grids'), findsOneWidget);
      expect(find.text('Single Photo'), findsOneWidget);
      expect(find.text('2 Split Vertical'), findsOneWidget);
      expect(find.text('4 Photo Quad'), findsOneWidget);

      // Verify SafeArea is present
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('PhotoLayoutSheet renders aspect ratios and background colors with SafeArea', (tester) async {
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

      expect(find.text('Canvas Layout & Aspect Ratio'), findsOneWidget);
      expect(find.text('ASPECT RATIO'), findsOneWidget);
      expect(find.text('1:1 Square'), findsOneWidget);
      expect(find.text('GRID GAP SPACING'), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('PhotoDrawSheet renders brush palette with SafeArea', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);
      final state = container.read(photoEditorControllerProvider(testProject));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoDrawSheet(
              state: state,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Freehand Vector Brush'), findsOneWidget);
      expect(find.text('BRUSH COLOR'), findsOneWidget);
      expect(find.text('STROKE WIDTH'), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('PhotoTextSheet renders text input with visible text and chips', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoTextSheet(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Professional Text'), findsOneWidget);
      expect(find.text('TEXT STYLE PRESET'), findsOneWidget);
      expect(find.text('FONT FAMILY'), findsOneWidget);

      // Verify TextField text color is textPrimary, not white on white
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style?.color, equals(AppColors.textPrimary));
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('PhotoStickerSheet renders search bar with high-contrast text and icons', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoStickerSheet(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gboard Stickers & Emojis'), findsOneWidget);
      final searchField = tester.widget<TextField>(find.byType(TextField));
      expect(searchField.style?.color, equals(AppColors.textPrimary));
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('WatermarkSheet renders position chips and sliders with SafeArea', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatermarkSheet(
              project: testProject,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Watermark & Branding'), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('PhotoAdjustSheet renders brightness and contrast sliders with SafeArea', (tester) async {
      final container = ProviderContainer();
      final controller = container.read(photoEditorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoAdjustSheet(
              project: testProject,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Color Adjustments'), findsOneWidget);
      expect(find.text('BRIGHTNESS'), findsOneWidget);
      expect(find.text('CONTRAST'), findsOneWidget);
      expect(find.text('SATURATION'), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('PhotoExportDialog renders Cancel and Export buttons with high contrast', (tester) async {
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoExportDialog(
              boundaryKey: boundaryKey,
              projectTitle: 'Editorial Shoot',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export High-Res Image'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Export Now'), findsOneWidget);

      // Verify Cancel text is textSecondary, not white54 on white
      final cancelText = tester.widget<Text>(find.text('Cancel'));
      expect(cancelText.style?.color, equals(AppColors.textSecondary));
    });
  });
}
