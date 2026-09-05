import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/core/storage/storage_providers.dart';
import 'package:looma/features/auth/domain/entities/user_entity.dart';
import 'package:looma/features/auth/domain/repositories/auth_repository.dart';
import 'package:looma/features/auth/presentation/providers/auth_provider.dart';
import 'package:looma/features/auth/presentation/screens/auth_screen.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/editor/presentation/providers/editor_controller.dart';
import 'package:looma/features/editor/presentation/widgets/reorder_clips_sheet.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/repositories/project_repository.dart';
import 'package:looma/features/projects/domain/usecases/project_usecases.dart';
import 'package:looma/features/projects/presentation/providers/projects_provider.dart';
import 'package:looma/features/projects/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final size in [const Size(320, 568), const Size(360, 640), const Size(390, 844), const Size(428, 926)]) {
    testWidgets('HomeScreen does not overflow on ${size.width}x${size.height}', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storageService = LocalStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storageService),
            projectsNotifierProvider.overrideWith((ref) => _FakeProjectsNotifier()),
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState(status: AuthStatus.unauthenticated, user: null),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Must not have any overflow errors
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home_signin_register_button')), findsOneWidget);
      expect(find.byKey(const Key('home_banner_signin_register_btn')), findsOneWidget);
    });
  }

  for (final size in [const Size(320, 568), const Size(360, 640), const Size(390, 844), const Size(428, 926)]) {
    testWidgets('AuthScreen does not overflow on ${size.width}x${size.height}', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storageService = LocalStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storageService),
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState(status: AuthStatus.unauthenticated, user: null),
              ),
            ),
          ],
          child: const MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tester.takeException(), isNull);
      expect(
        find.text('End-to-end user workspace isolation & salted password encryption'),
        findsOneWidget,
      );
    });
  }

  for (final size in [const Size(320, 568), const Size(360, 640), const Size(390, 844), const Size(428, 926)]) {
    testWidgets('ReorderClipsSheet does not overflow on ${size.width}x${size.height}', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final clipA = VideoClipEntity(
        id: 'clip_A',
        name: 'Scene 1',
        mediaPath: 'assets/branding/demo_vid1.mp4',
        sourceDurationMs: 4000,
        timelineStartMs: 0,
        timelineEndMs: 4000,
        trimStartMs: 0,
        trimEndMs: 4000,
      );

      final clipB = VideoClipEntity(
        id: 'clip_B',
        name: 'Middle Scene 2 Long',
        mediaPath: 'assets/branding/demo_vid2.mp4',
        sourceDurationMs: 6000,
        timelineStartMs: 4000,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 6000,
      );

      final clipC = VideoClipEntity(
        id: 'clip_C',
        name: 'Scene 3',
        mediaPath: 'assets/branding/demo_vid3.mp4',
        sourceDurationMs: 5000,
        timelineStartMs: 10000,
        timelineEndMs: 15000,
        trimStartMs: 0,
        trimEndMs: 5000,
      );

      final testProject = ProjectEntity(
        id: 'p1',
        title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 15000,
        videoClips: [clipA, clipB, clipC],
      );

      final container = ProviderContainer();
      final controller = container.read(editorControllerProvider(testProject).notifier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderClipsSheet(
              clips: [clipA, clipB, clipC],
              controller: controller,
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tester.takeException(), isNull);
      expect(find.text('Reorder Clips'), findsOneWidget);
      expect(find.byKey(const ValueKey('move_up_clip_B')), findsOneWidget);
      expect(find.byKey(const ValueKey('move_down_clip_B')), findsOneWidget);
      expect(find.byKey(const ValueKey('move_start_clip_B')), findsOneWidget);
      expect(find.byKey(const ValueKey('move_end_clip_B')), findsOneWidget);
    });
  }
}

class _FakeProjectsNotifier extends ProjectsNotifier {
  _FakeProjectsNotifier()
      : super(
          getProjectsUseCase: GetProjectsUseCase(_FakeProjectsRepository()),
          saveProjectUseCase: SaveProjectUseCase(_FakeProjectsRepository()),
          duplicateProjectUseCase: DuplicateProjectUseCase(_FakeProjectsRepository()),
          deleteProjectUseCase: DeleteProjectUseCase(_FakeProjectsRepository()),
        ) {
    state = const ProjectsState(isLoading: false, projects: []);
  }

  @override
  Future<void> loadProjects() async {
    state = const ProjectsState(isLoading: false, projects: []);
  }
}

class _FakeProjectsRepository implements ProjectRepository {
  @override
  Future<List<ProjectEntity>> getProjects() async => [];

  @override
  Future<ProjectEntity?> getProjectById(String id) async => null;

  @override
  Future<void> saveProject(ProjectEntity project) async {}

  @override
  Future<void> updateProject(ProjectEntity project) async {}

  @override
  Future<ProjectEntity> duplicateProject(String id) async => throw UnimplementedError();

  @override
  Future<void> deleteProject(String id) async {}
}

class _FakeAuthNotifier extends AuthNotifier {
  final AuthState _initial;
  _FakeAuthNotifier(this._initial) : super(_FakeAuthRepository()) {
    state = _initial;
  }

  @override
  Future<void> checkCurrentSession() async {
    state = _initial;
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserEntity> login({required String email, required String password, bool rememberMe = true}) async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> register({required String email, required String password, required String displayName}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> forgotPassword({required String email, required String newPassword}) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<UserEntity?> restoreSession() async => null;
}
