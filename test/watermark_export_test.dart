import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looma/core/widgets/looma_watermark.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/export/domain/entities/export_config_entity.dart';
import 'package:looma/features/export/presentation/screens/export_screen.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/usecases/project_usecases.dart';
import 'package:looma/features/projects/presentation/providers/projects_provider.dart';

class FakeGetProjectByIdUseCase extends Fake implements GetProjectByIdUseCase {
  final ProjectEntity project;
  FakeGetProjectByIdUseCase(this.project);

  @override
  Future<ProjectEntity?> call(String id) async => project;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Looma Watermark Feature Tests', () {
    test('ExportConfigEntity defaults includeWatermark to true', () {
      const config = ExportConfigEntity(projectId: 'test_project');
      expect(config.includeWatermark, isTrue);

      final updated = config.copyWith(includeWatermark: false);
      expect(updated.includeWatermark, isFalse);
      expect(updated.projectId, 'test_project');
    });

    testWidgets('LoomaWatermark renders logo icon and Looma text with subtle styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoomaWatermark(opacity: 0.65),
          ),
        ),
      );

      expect(find.text('Looma'), findsOneWidget);
      expect(find.text('✦'), findsOneWidget);

      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsOneWidget);
      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, 0.65);
    });

    testWidgets('ExportScreen shows Looma Watermark toggle enabled by default', (tester) async {
      final mockProject = ProjectEntity(
        id: 'proj_watermark_1',
        title: 'Watermark Test Video',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'clip_1',
            name: 'Clip 1',
            mediaPath: '/dummy/path.mp4',
            timelineStartMs: 0,
            timelineEndMs: 4000,
            sourceDurationMs: 4000,
            trimStartMs: 0,
            trimEndMs: 4000,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getProjectByIdUseCaseProvider.overrideWithValue(
              FakeGetProjectByIdUseCase(mockProject),
            ),
          ],
          child: const MaterialApp(
            home: ExportScreen(projectId: 'proj_watermark_1'),
          ),
        ),
      );

      // Wait for project load
      await tester.pumpAndSettle();

      // Find Looma Watermark section
      expect(find.text('Looma Watermark'), findsOneWidget);
      expect(find.text('Clean watermark in bottom-right corner'), findsOneWidget);

      // Verify switch is present and enabled by default
      final switchFinder = find.byKey(const Key('watermark_toggle'));
      expect(switchFinder, findsOneWidget);

      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);

      // Toggle switch to off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final updatedSwitch = tester.widget<Switch>(switchFinder);
      expect(updatedSwitch.value, isFalse);

      // Toggle switch back on
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final reEnabledSwitch = tester.widget<Switch>(switchFinder);
      expect(reEnabledSwitch.value, isTrue);
    });
  });
}
