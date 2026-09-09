import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/app/app.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';
import 'package:procut/features/auth/domain/entities/user_entity.dart';
import 'package:procut/features/auth/domain/repositories/auth_repository.dart';
import 'package:procut/features/auth/presentation/providers/auth_provider.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/editor/presentation/widgets/canvas_preview.dart';
import 'package:procut/features/media_picker/presentation/widgets/media_picker_modal.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:flutter/services.dart';
import 'package:procut/features/projects/domain/repositories/project_repository.dart';
import 'package:procut/features/projects/domain/usecases/project_usecases.dart';
import 'package:procut/features/projects/presentation/providers/projects_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (MethodCall methodCall) async {
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker_android'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  group('CapCut-Style Toolbar & Middle Options Tests (Image 1)', () {
    late ProjectEntity testProject;

    setUp(() {
      testProject = ProjectEntity(
        id: 'capcut_test_proj_1',
        title: 'CapCut Test Project',
        durationMs: 4000,
        aspectRatio: AspectRatioType.ratio9_16,
        fps: 30,
        videoClips: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('CanvasPreview displays Fullscreen, Play/Pause, Snapping ON/OFF, Undo, Redo, and Timecodes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(editorControllerProvider(testProject));
                  final controller = ref.read(editorControllerProvider(testProject).notifier);
                  return CanvasPreview(
                    timelineState: state,
                    controller: controller,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Fullscreen button exists
      expect(find.byIcon(Icons.fullscreen), findsWidgets);

      // 2. Play/Pause button exists (initially paused -> play_arrow)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // 3. Magnet / Snapping button exists with ON label initially
      expect(find.text('ON'), findsOneWidget);

      // 4. Undo and Redo icons exist
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);

      // 5. Timecodes exist
      expect(find.text('00:00 / 00:04'), findsOneWidget);
      expect(find.text('00:00'), findsWidgets);

      // 6. Test Snapping toggle: tap Snapping button -> toggles to OFF
      await tester.tap(find.text('ON'));
      await tester.pumpAndSettle();
      expect(find.text('OFF'), findsOneWidget);

      // Tap again -> toggles back to ON
      await tester.tap(find.text('OFF'));
      await tester.pumpAndSettle();
      expect(find.text('ON'), findsOneWidget);

      // 7. Test Play/Pause toggle
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Pause again
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });

  group('Royal Sapphire UI & Home Dashboard Tests (Image 2)', () {
    testWidgets('Home page renders PROCUT Ultra frosted badge, search button, and New video / Edit photo cards',
        (WidgetTester tester) async {
      final storage = LocalStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storage),
            projectsNotifierProvider.overrideWith((ref) => _FakeProjectsNotifier()),
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState(status: AuthStatus.unauthenticated, user: null, isLoading: false, errorMessage: null),
              ),
            ),
          ],
          child: const ProCutApp(),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 1. Frosted Glass Ultra Badge in AppBar
      expect(find.text('PROCUT'), findsOneWidget);
      expect(find.text('Ultra'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);

      // 2. Search Button in AppBar
      expect(find.byIcon(Icons.search), findsOneWidget);

      // 3. Hero Header Section
      expect(find.text('Video create'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);

      // 4. Crisp Action Cards
      expect(find.text('New video'), findsOneWidget);
      expect(find.text('Edit photo'), findsOneWidget);
    });
  });

  group('Storage Resilience & Auto-Repair Tests', () {
    test('LocalStorageService auto-repairs JSON with trailing corrupted braces', () async {
      final storage = LocalStorageService();
      const testPath = 'looma_test/corrupted_project.json';

      // Corrupted JSON with extra trailing brace '}}' exactly like the device log
      final corruptedJsonString = '{"id":"test_proj_123","title":"Repaired Project","tags":[]}}';
      await storage.writeString(testPath, corruptedJsonString);

      // readJson should automatically repair and return valid Map
      final result = await storage.readJson(testPath);
      expect(result, isNotNull);
      expect(result!['id'], 'test_proj_123');
      expect(result['title'], 'Repaired Project');
    });
  });

  group('Direct Gallery Invocation Tests for New Video & Photo', () {
    testWidgets('Tapping New video opens CapCut in-app gallery MediaPickerModal directly (Image 1)',
        (WidgetTester tester) async {
      final storage = LocalStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storage),
            projectsNotifierProvider.overrideWith((ref) => _FakeProjectsNotifier()),
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState(status: AuthStatus.unauthenticated, user: null, isLoading: false, errorMessage: null),
              ),
            ),
          ],
          child: const ProCutApp(),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 1. Tap New video
      final newVideoFinder = find.text('New video');
      expect(newVideoFinder, findsOneWidget);
      await tester.tap(newVideoFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 2. Directly opens MediaPickerModal matching Image 1
      expect(find.byType(MediaPickerModal), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('HD'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Add media'), findsOneWidget);
      expect(find.text('Script to video'), findsOneWidget);

      // 3. Close the gallery modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // 4. Back on HomeScreen: Edit photo card is visible
      final editPhotoFinder = find.text('Edit photo');
      expect(editPhotoFinder, findsOneWidget);
    });
  });
}

class _FakeProjectsNotifier extends ProjectsNotifier {
  _FakeProjectsNotifier()
      : super(
          getProjectsUseCase: GetProjectsUseCase(_FakeProjectsRepository()),
          saveProjectUseCase: SaveProjectUseCase(_FakeProjectsRepository()),
          duplicateProjectUseCase: DuplicateProjectUseCase(_FakeProjectsRepository()),
          deleteProjectUseCase: DeleteProjectUseCase(_FakeProjectsRepository()),
        ) {
    state = ProjectsState(
      projects: [
        ProjectEntity(
          id: 'proj_mock_1',
          title: 'Sample Sapphire Project',
          aspectRatio: AspectRatioType.ratio9_16,
          fps: 30,
          durationMs: 5000,
          videoClips: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }

  @override
  Future<void> loadProjects() async {}
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

  @override
  Future<void> claimGuestProjects(String userId) async {}
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

  @override
  Future<void> syncLocalAccountsToCloud() async {}
}
