import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/editor/presentation/providers/editor_controller.dart';
import 'package:looma/features/filters_effects/domain/entities/filter_preset.dart';
import 'package:looma/features/filters_effects/presentation/widgets/filter_picker_sheet.dart';
import 'package:looma/features/filters_effects/presentation/widgets/filter_thumbnail_tile.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_frame_entity.dart';
import 'package:looma/features/photo_editor/domain/entities/photo_project_entity.dart';
import 'package:looma/features/photo_editor/presentation/providers/photo_editor_controller.dart';
import 'package:looma/features/photo_editor/presentation/widgets/photo_filter_sheet.dart';
import 'package:looma/features/projects/data/models/project_model.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') return <String, dynamic>{};
        return true;
      },
    );
  });

  group('Professional Filter Engine & Presets Tests', () {
    test('Contains 20+ professional filters including all requested styles', () {
      expect(FilterType.values.length, greaterThanOrEqualTo(20));

      // Verify all 20 explicitly requested filters exist
      final names = FilterType.values.map((f) => f.name).toSet();
      final requestedNames = [
        'cinematic',
        'vintage',
        'warm',
        'cool',
        'retro',
        'film',
        'moody',
        'fade',
        'noir',
        'bw',
        'sepia',
        'sunset',
        'golden',
        'dreamy',
        'vivid',
        'matte',
        'urban',
        'arctic',
        'summer',
        'dramatic',
      ];

      for (final req in requestedNames) {
        expect(
          names.contains(req),
          isTrue,
          reason: 'Expected filter "$req" to be present in FilterType enum',
        );
      }
    });

    test('All filter matrices (except none) have exactly 20 elements (4x5)', () {
      for (final filter in FilterType.values) {
        if (filter == FilterType.none) {
          expect(filter.matrix.isEmpty, isTrue);
        } else {
          expect(
            filter.matrix.length,
            equals(20),
            reason: '${filter.name} matrix should have exactly 20 floats',
          );
        }
      }
    });

    test('getInterpolatedMatrix at 0.0 intensity returns identity matrix', () {
      for (final filter in FilterType.values) {
        final matrix0 = filter.getInterpolatedMatrix(0.0);
        expect(matrix0.length, equals(20));
        expect(matrix0, equals(FilterType.identityMatrix));
      }
    });

    test('getInterpolatedMatrix at 1.0 intensity returns exact filter matrix', () {
      for (final filter in FilterType.values) {
        if (filter == FilterType.none) continue;
        final matrix1 = filter.getInterpolatedMatrix(1.0);
        expect(matrix1.length, equals(20));
        for (int i = 0; i < 20; i++) {
          expect(
            (matrix1[i] - filter.matrix[i]).abs(),
            lessThan(0.001),
            reason: 'Mismatch at index $i for ${filter.name}',
          );
        }
      }
    });

    test('getInterpolatedMatrix at 0.5 intensity blends half-way', () {
      final cinematic = FilterType.cinematic;
      final halfMatrix = cinematic.getInterpolatedMatrix(0.5);

      // Diagonal index 0: cinematic is 1.15, identity is 1.0 -> 1.0 + (1.15 - 1.0)*0.5 = 1.075
      expect(halfMatrix[0], closeTo(1.075, 0.001));

      // Translation index 4: cinematic is 10.0, identity is 0.0 -> 0.0 + (10.0 - 0.0)*0.5 = 5.0
      expect(halfMatrix[4], closeTo(5.0, 0.001));
    });

    test('getColorFilter returns null for none or 0.0 intensity', () {
      expect(FilterType.none.getColorFilter(1.0), isNull);
      expect(FilterType.cinematic.getColorFilter(0.0), isNull);
      expect(FilterType.cinematic.getColorFilter(0.0001), isNull);
      expect(FilterType.cinematic.getColorFilter(0.5), isNotNull);
      expect(FilterType.cinematic.getColorFilter(1.0), isNotNull);
    });

    test('FilterType.fromString handles normal and legacy names', () {
      expect(FilterType.fromString('cinematic'), equals(FilterType.cinematic));
      expect(FilterType.fromString('vintage'), equals(FilterType.vintage));
      expect(FilterType.fromString('monochrome'), equals(FilterType.bw));
      expect(FilterType.fromString('warmSunset'), equals(FilterType.sunset));
      expect(FilterType.fromString('vibrant'), equals(FilterType.vivid));
      expect(FilterType.fromString('unknown_filter'), equals(FilterType.none));
      expect(FilterType.fromString(null), equals(FilterType.none));
    });

    test('Every filter has a valid category and non-empty subtitle', () {
      for (final filter in FilterType.values) {
        expect(filter.label.isNotEmpty, isTrue);
        expect(filter.subtitle.isNotEmpty, isTrue);
        expect(filter.category, isNotNull);
      }
    });
  });

  group('Video Clip Entity & Project Persistence Tests', () {
    test('VideoClipEntity defaults filterIntensity to 1.0 and supports copyWith', () {
      final clip = VideoClipEntity(
        id: 'clip-1',
        mediaPath: 'video.mp4',
        name: 'Clip 1',
        sourceDurationMs: 5000,
        timelineStartMs: 0,
        timelineEndMs: 5000,
        trimEndMs: 5000,
      );

      expect(clip.filterType, equals(FilterType.none));
      expect(clip.filterIntensity, equals(1.0));

      final updated = clip.copyWith(
        filterType: FilterType.cinematic,
        filterIntensity: 0.75,
      );

      expect(updated.filterType, equals(FilterType.cinematic));
      expect(updated.filterIntensity, equals(0.75));
    });

    test('ProjectModel serializes and deserializes video clip filter and intensity', () {
      final clip = VideoClipEntity(
        id: 'clip-test-1',
        mediaPath: 'assets/demo.mp4',
        name: 'Demo Clip',
        sourceDurationMs: 6000,
        timelineStartMs: 0,
        timelineEndMs: 6000,
        trimEndMs: 6000,
        filterType: FilterType.noir,
        filterIntensity: 0.85,
      );

      final project = ProjectEntity(
        id: 'proj-1',
        title: 'Filter Test Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: [clip],
      );

      final json = ProjectModel.toJson(project);
      final restored = ProjectModel.fromJson(json);

      expect(restored.videoClips.length, equals(1));
      final restoredClip = restored.videoClips.first;
      expect(restoredClip.id, equals('clip-test-1'));
      expect(restoredClip.filterType, equals(FilterType.noir));
      expect(restoredClip.filterIntensity, closeTo(0.85, 0.001));
    });
  });

  group('Photo Frame Entity & Photo Project Persistence Tests', () {
    test('PhotoFrameEntity serializes and deserializes filter and intensity', () {
      const frame = PhotoFrameEntity(
        id: 'frame-1',
        imagePath: '/photos/scenic.jpg',
        filterType: FilterType.sepia,
        filterIntensity: 0.65,
      );

      final json = frame.toJson();
      expect(json['filterType'], equals('sepia'));
      expect(json['filterIntensity'], equals(0.65));

      final restored = PhotoFrameEntity.fromJson(json);
      expect(restored.id, equals('frame-1'));
      expect(restored.filterType, equals(FilterType.sepia));
      expect(restored.filterIntensity, closeTo(0.65, 0.001));
    });

    test('PhotoProjectEntity preserves frame filters across full project json roundtrip', () {
      final proj = PhotoProjectEntity(
        id: 'photo-p-1',
        title: 'Studio Portrait',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        frames: const [
          PhotoFrameEntity(
            id: 'f-1',
            imagePath: 'img1.png',
            filterType: FilterType.dramatic,
            filterIntensity: 0.9,
          ),
          PhotoFrameEntity(
            id: 'f-2',
            imagePath: 'img2.png',
            filterType: FilterType.vintage,
            filterIntensity: 0.4,
          ),
        ],
      );

      final json = proj.toJson();
      final restored = PhotoProjectEntity.fromJson(json);

      expect(restored.frames.length, equals(2));
      expect(restored.frames[0].filterType, equals(FilterType.dramatic));
      expect(restored.frames[0].filterIntensity, closeTo(0.9, 0.001));
      expect(restored.frames[1].filterType, equals(FilterType.vintage));
      expect(restored.frames[1].filterIntensity, closeTo(0.4, 0.001));
    });
  });

  group('Editor Controller Filter Methods Tests', () {
    test('setClipFilter and setClipFilterIntensity update selected clip in real-time', () {
      final clip = VideoClipEntity(
        id: 'clip-c1',
        mediaPath: 'video.mp4',
        name: 'Clip',
        sourceDurationMs: 4000,
        timelineStartMs: 0,
        timelineEndMs: 4000,
        trimEndMs: 4000,
      );

      final controller = EditorController(
        project: ProjectEntity(
          id: 'proj-c1',
          title: 'Controller Test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          videoClips: [clip],
        ),
      );

      // Apply filter
      controller.setClipFilter('clip-c1', FilterType.warm, intensity: 0.8);
      var currentClip = controller.state.project.videoClips.first;
      expect(currentClip.filterType, equals(FilterType.warm));
      expect(currentClip.filterIntensity, closeTo(0.8, 0.001));

      // Adjust intensity
      controller.setClipFilterIntensity('clip-c1', 0.45);
      currentClip = controller.state.project.videoClips.first;
      expect(currentClip.filterType, equals(FilterType.warm));
      expect(currentClip.filterIntensity, closeTo(0.45, 0.001));

      // Remove filter
      controller.removeClipFilter('clip-c1');
      currentClip = controller.state.project.videoClips.first;
      expect(currentClip.filterType, equals(FilterType.none));
      expect(currentClip.filterIntensity, equals(1.0));
    });
  });

  group('Photo Editor Controller Filter Methods Tests', () {
    test('updateFrameColorGrading and applyFilterToAllFrames update frames', () {
      final proj = PhotoProjectEntity(
        id: 'photo-p2',
        title: 'Photo Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        frames: const [
          PhotoFrameEntity(id: 'pf-1', imagePath: 'p1.jpg'),
          PhotoFrameEntity(id: 'pf-2', imagePath: 'p2.jpg'),
        ],
      );

      final controller = PhotoEditorController(proj);

      // Update single frame
      controller.updateFrameColorGrading(
        'pf-1',
        filterType: FilterType.sunset,
        filterIntensity: 0.7,
      );
      expect(controller.state.project.frames[0].filterType, equals(FilterType.sunset));
      expect(controller.state.project.frames[0].filterIntensity, closeTo(0.7, 0.001));
      expect(controller.state.project.frames[1].filterType, equals(FilterType.none));

      // Apply to all frames
      controller.applyFilterToAllFrames(FilterType.cool, filterIntensity: 0.85);
      expect(controller.state.project.frames[0].filterType, equals(FilterType.cool));
      expect(controller.state.project.frames[0].filterIntensity, closeTo(0.85, 0.001));
      expect(controller.state.project.frames[1].filterType, equals(FilterType.cool));
      expect(controller.state.project.frames[1].filterIntensity, closeTo(0.85, 0.001));

      // Remove filter from single frame
      controller.removeFilter('pf-1');
      expect(controller.state.project.frames[0].filterType, equals(FilterType.none));
      expect(controller.state.project.frames[1].filterType, equals(FilterType.cool));
    });
  });

  group('Filter UI Widgets Tests', () {
    testWidgets('FilterPickerSheet renders header, categories, thumbnails, and handles selection', (tester) async {
      FilterType selected = FilterType.none;
      double intensity = 1.0;
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterPickerSheet(
              selectedFilter: selected,
              filterIntensity: intensity,
              onFilterSelected: (f) => selected = f,
              onIntensityChanged: (i) => intensity = i,
              onFilterRemoved: () => removed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header title and count badge
      expect(find.text('Filters & LUTs'), findsOneWidget);
      expect(find.text('${FilterType.values.length - 1} PRO'), findsOneWidget);

      // All categories present
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Cinematic & Film'), findsOneWidget);

      // Check for thumbnails
      expect(find.byType(FilterThumbnailTile), findsWidgets);
      expect(find.text('Original'), findsOneWidget);

      // Select Cinematic filter
      final cinematicFinder = find.text('Cinematic');
      expect(cinematicFinder, findsOneWidget);
      await tester.tap(cinematicFinder);
      await tester.pumpAndSettle();

      expect(selected, equals(FilterType.cinematic));
      expect(removed, isFalse);
    });

    testWidgets('FilterPickerSheet displays intensity slider when non-none filter is active', (tester) async {
      double changedIntensity = 0.8;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterPickerSheet(
              selectedFilter: FilterType.vintage,
              filterIntensity: 0.8,
              onFilterSelected: (_) {},
              onIntensityChanged: (val) => changedIntensity = val,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Intensity bar is present
      expect(find.text('Filter Intensity'), findsOneWidget);
      expect(find.text('80%'), findsWidgets);
      expect(find.byType(Slider), findsOneWidget);

      // Drag slider
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(-50, 0));
      await tester.pumpAndSettle();

      expect(changedIntensity, lessThan(0.8));
    });

    testWidgets('PhotoFilterSheet renders and switches filters', (tester) async {
      final proj = PhotoProjectEntity(
        id: 'photo-p3',
        title: 'Photo UI Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        frames: const [
          PhotoFrameEntity(id: 'f-ui-1', imagePath: 'photo.jpg'),
        ],
      );

      final controller = PhotoEditorController(proj);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoFilterSheet(
              project: proj,
              selectedFrameId: 'f-ui-1',
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Photo Color Filters'), findsOneWidget);
      expect(find.byType(FilterThumbnailTile), findsWidgets);

      // Tap Cool filter
      final coolFinder = find.text('Cool');
      expect(coolFinder, findsOneWidget);
      await tester.tap(coolFinder);
      await tester.pumpAndSettle();

      expect(controller.state.project.frames.first.filterType, equals(FilterType.cool));
    });
  });
}
