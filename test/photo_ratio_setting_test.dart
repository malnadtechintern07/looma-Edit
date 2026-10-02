import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procut/features/photo_editor/data/datasources/photo_local_datasource.dart';
import 'package:procut/features/photo_editor/data/repositories/photo_project_repository.dart';
import 'package:procut/features/photo_editor/domain/entities/photo_project_entity.dart';
import 'package:procut/features/photo_editor/presentation/providers/photo_editor_controller.dart';
import 'package:procut/features/photo_editor/presentation/screens/photo_editor_screen.dart';
import 'package:procut/features/photo_editor/presentation/widgets/photo_ratio_sheet.dart';

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

  late PhotoProjectEntity sampleProject;

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sampleProject = PhotoProjectEntity(
      id: 'test_project_ratio',
      title: 'Ratio Test Project',
      aspectRatio: PhotoAspectRatio.square,
      frames: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });

  group('PhotoAspectRatio Enum & Metadata Tests', () {
    test('All aspect ratios have valid positive ratios and descriptions', () {
      expect(PhotoAspectRatio.values.length, 10);

      for (final ratio in PhotoAspectRatio.values) {
        expect(ratio.ratio, greaterThan(0));
        expect(ratio.label.isNotEmpty, true);
        expect(ratio.ratioText.isNotEmpty, true);
        expect(ratio.platform.isNotEmpty, true);
        expect(ratio.resolutionEstimate.isNotEmpty, true);
        expect(ratio.description.isNotEmpty, true);
        expect(ratio.category.isNotEmpty, true);
      }
    });

    test('Social media presets have expected proportional ratios', () {
      expect(PhotoAspectRatio.square.ratio, 1.0);
      expect(PhotoAspectRatio.portrait4x5.ratio, closeTo(0.8, 0.001));
      expect(PhotoAspectRatio.portrait9x16.ratio, closeTo(9 / 16, 0.001));
      expect(PhotoAspectRatio.landscape16x9.ratio, closeTo(16 / 9, 0.001));
      expect(PhotoAspectRatio.portrait2x3.ratio, closeTo(2 / 3, 0.001));
      expect(PhotoAspectRatio.cinematic21x9.ratio, closeTo(21 / 9, 0.001));
    });

    test('JSON serialization & deserialization handles all aspect ratios cleanly', () {
      for (final ratio in PhotoAspectRatio.values) {
        final project = sampleProject.copyWith(aspectRatio: ratio);
        final json = project.toJson();
        final reconstituted = PhotoProjectEntity.fromJson(json);
        expect(reconstituted.aspectRatio, ratio);
      }
    });
  });

  group('PhotoEditorController Ratio Manipulation & Undo/Redo', () {
    test('setAspectRatio records history and updates state project', () {
      final container = ProviderContainer(
        overrides: [
          photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(photoEditorControllerProvider(sampleProject).notifier);
      expect(container.read(photoEditorControllerProvider(sampleProject)).project.aspectRatio, PhotoAspectRatio.square);

      // Change to 9:16 Story
      controller.setAspectRatio(PhotoAspectRatio.portrait9x16);
      expect(container.read(photoEditorControllerProvider(sampleProject)).project.aspectRatio, PhotoAspectRatio.portrait9x16);
      expect(container.read(photoEditorControllerProvider(sampleProject)).canUndo, true);

      // Change to 16:9 Cinema
      controller.setAspectRatio(PhotoAspectRatio.landscape16x9);
      expect(container.read(photoEditorControllerProvider(sampleProject)).project.aspectRatio, PhotoAspectRatio.landscape16x9);

      // Undo back to 9:16
      controller.undo();
      expect(container.read(photoEditorControllerProvider(sampleProject)).project.aspectRatio, PhotoAspectRatio.portrait9x16);

      // Undo back to 1:1 Square
      controller.undo();
      expect(container.read(photoEditorControllerProvider(sampleProject)).project.aspectRatio, PhotoAspectRatio.square);

      // Redo back to 9:16
      controller.redo();
      expect(container.read(photoEditorControllerProvider(sampleProject)).project.aspectRatio, PhotoAspectRatio.portrait9x16);
    });

    test('setCanvasStyle updates background style and blur radius', () {
      final container = ProviderContainer(
        overrides: [
          photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(photoEditorControllerProvider(sampleProject).notifier);

      controller.setCanvasStyle(
        backgroundType: 'blur',
        blurBackgroundRadius: 25.0,
      );

      final state = container.read(photoEditorControllerProvider(sampleProject));
      expect(state.project.backgroundType, 'blur');
      expect(state.project.blurBackgroundRadius, 25.0);
    });
  });

  group('PhotoRatioSheet UI & Interactivity Tests', () {
    testWidgets('PhotoRatioSheet renders all options without overflow and allows ratio selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(photoEditorControllerProvider(sampleProject).notifier);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PhotoRatioSheet(
                project: sampleProject,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and titles
      expect(find.text('Ratio Setting'), findsOneWidget);
      expect(find.text('CANVAS BACKGROUND FILL'), findsOneWidget);

      // Verify category filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Landscape'), findsOneWidget);

      // Switch category filter to Social
      await tester.tap(find.text('Social'));
      await tester.pumpAndSettle();

      // Tap on 9:16 ratio card
      final storyCard = find.text('9:16');
      expect(storyCard, findsOneWidget);
      await tester.tap(storyCard);
      await tester.pumpAndSettle();

      // Verify controller state changed to portrait9x16
      expect(container.read(photoEditorControllerProvider(sampleProject)).project.aspectRatio, PhotoAspectRatio.portrait9x16);

      // Switch to Blur background mode
      final blurButton = find.text('Blur');
      expect(blurButton, findsOneWidget);
      await tester.tap(blurButton);
      await tester.pumpAndSettle();

      expect(container.read(photoEditorControllerProvider(sampleProject)).project.backgroundType, 'blur');
    });

    testWidgets('PhotoEditorScreen displays dedicated Ratio button that opens Ratio sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          photoProjectRepositoryProvider.overrideWithValue(FakePhotoProjectRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: PhotoEditorScreen(project: sampleProject),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for Ratio button in toolbar
      final ratioButton = find.text('Ratio');
      expect(ratioButton, findsOneWidget);

      // Tap on Ratio button
      await tester.tap(ratioButton);
      await tester.pumpAndSettle();

      // Sheet should now be displayed
      expect(find.text('Ratio Setting'), findsOneWidget);
      expect(find.text('CANVAS BACKGROUND FILL'), findsOneWidget);

      // Tap Apply to close
      final applyButton = find.textContaining('Apply');
      expect(applyButton, findsOneWidget);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Sheet dismissed
      expect(find.text('Ratio Setting'), findsNothing);
    });
  });
}
