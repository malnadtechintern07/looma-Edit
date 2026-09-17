import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/presentation/screens/editor_screen.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/repositories/project_repository.dart';
import 'package:procut/features/projects/presentation/providers/projects_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProjectRepo implements ProjectRepository {
  final ProjectEntity project;
  _FakeProjectRepo(this.project);

  @override
  Future<List<ProjectEntity>> getProjects() async => [project];

  @override
  Future<ProjectEntity?> getProjectById(String id) async => project;

  @override
  Future<void> saveProject(ProjectEntity project) async {}

  @override
  Future<void> updateProject(ProjectEntity project) async {}

  @override
  Future<ProjectEntity> duplicateProject(String id) async => project;

  @override
  Future<void> deleteProject(String id) async {}

  @override
  Future<void> claimGuestProjects(String userId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testProject = ProjectEntity(
    id: 'test_proj',
    title: 'Cinematic Vlog 2026 With A Long Name Here',
    aspectRatio: AspectRatioType.ratio16_9,
    fps: 30,
    durationMs: 15000,
    videoClips: [
      const VideoClipEntity(
        id: 'clip_1',
        name: 'Scene 1',
        mediaPath: 'assets/demo/tokyo_street.mp4',
        sourceDurationMs: 8000,
        timelineStartMs: 0,
        timelineEndMs: 8000,
        trimStartMs: 0,
        trimEndMs: 8000,
      ),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final widths = [320.0, 340.0, 360.0, 375.0, 384.0, 390.0, 392.7, 393.0, 400.0, 411.4, 412.0, 414.0, 428.0];

  for (final w in widths) {
    testWidgets('EditorScreen does not overflow on width $w', (WidgetTester tester) async {
      tester.view.physicalSize = Size(w, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storageService = LocalStorageService();
      final repo = _FakeProjectRepo(testProject);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storageService),
            projectRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: EditorScreen(projectId: testProject.id),
          ),
        ),
      );

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'Overflow error on width $w');
    });
  }
}
