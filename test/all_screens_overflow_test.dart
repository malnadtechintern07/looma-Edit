import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';
import 'package:procut/features/auth/domain/entities/user_entity.dart';
import 'package:procut/features/auth/domain/repositories/auth_repository.dart';
import 'package:procut/features/auth/presentation/providers/auth_provider.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/repositories/project_repository.dart';
import 'package:procut/features/projects/domain/usecases/project_usecases.dart';
import 'package:procut/features/projects/presentation/providers/projects_provider.dart';
import 'package:procut/features/projects/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Future<void> claimGuestProjects(String userId, [String? userEmail]) async {}
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

  @override
  Future<UserEntity> updateProfile({
    required String displayName,
    String? handle,
    String? bio,
    String? avatarUrl,
  }) async {
    return UserEntity(
      id: 'usr_test',
      email: 'test@procut.app',
      displayName: displayName,
      isPro: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testSizes = [
    const Size(320, 568),
    const Size(340, 680),
    const Size(360, 640),
    const Size(375, 667),
    const Size(390, 844),
    const Size(412, 915),
  ];

  for (final size in testSizes) {
    testWidgets('HomeScreen unauthenticated test on ${size.width}x${size.height}', (tester) async {
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
            authNotifierProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthState(status: AuthStatus.unauthenticated, user: null))),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'HomeScreen overflow on ${size.width}');
    });
  }
}
