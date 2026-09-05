import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/app/app.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/core/storage/storage_providers.dart';
import 'package:looma/features/auth/domain/entities/user_entity.dart';
import 'package:looma/features/auth/domain/repositories/auth_repository.dart';
import 'package:looma/features/auth/presentation/providers/auth_provider.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/repositories/project_repository.dart';
import 'package:looma/features/projects/domain/usecases/project_usecases.dart';
import 'package:looma/features/projects/presentation/providers/projects_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home page shows Sign In / Register Account button when not signed in, and Me tab has sign in options',
      (WidgetTester tester) async {
    final storageService = LocalStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storageService),
          projectsNotifierProvider.overrideWith((ref) => _FakeProjectsNotifier()),
          // User is NOT signed in
          authNotifierProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              const AuthState(
                status: AuthStatus.unauthenticated,
                user: null,
                isLoading: false,
                errorMessage: null,
              ),
            ),
          ),
        ],
        child: const LoomaApp(),
      ),
    );

    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // 1. Home page shows Sign In / Register Account button in AppBar and Banner
    expect(find.byKey(const Key('home_signin_register_button')), findsOneWidget);
    expect(find.byKey(const Key('home_banner_signin_register_btn')), findsOneWidget);
    expect(find.text('Sign In / Register Account'), findsWidgets);

    // 2. Switch to 'Me' Tab
    await tester.tap(find.text('Me'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // 3. Me Tab shows Guest status and Sign In / Register button
    expect(find.text('GUEST'), findsOneWidget);
    expect(find.byKey(const Key('me_tab_signin_register_btn')), findsOneWidget);
    expect(find.byKey(const Key('me_account_signin_list_tile')), findsOneWidget);
    expect(find.byKey(const Key('me_account_signout_list_tile')), findsNothing);
  });

  testWidgets('Home page hides Sign In / Register Account button after sign in, and account details show on Me tab',
      (WidgetTester tester) async {
    final storageService = LocalStorageService();
    final testUser = UserEntity(
      id: 'usr_abc123',
      email: 'creator@looma.app',
      displayName: 'Alex Director',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storageService),
          projectsNotifierProvider.overrideWith((ref) => _FakeProjectsNotifier()),
          // User IS signed in
          authNotifierProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: testUser,
                isLoading: false,
                errorMessage: null,
              ),
            ),
          ),
        ],
        child: const LoomaApp(),
      ),
    );

    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // 1. On Home page, Sign In / Register Account buttons and banners are GONE
    expect(find.byKey(const Key('home_signin_register_button')), findsNothing);
    expect(find.byKey(const Key('home_banner_signin_register_btn')), findsNothing);
    expect(find.text('Sign In / Register Account'), findsNothing);

    // 2. Switch to 'Me' Tab
    await tester.tap(find.text('Me'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // 3. Me Tab shows Account status, active user email, and Sign Out button
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Alex Director'), findsOneWidget);
    expect(find.text('creator@looma.app'), findsOneWidget);
    expect(find.byKey(const Key('me_account_status_list_tile')), findsOneWidget);
    expect(find.byKey(const Key('me_account_signout_list_tile')), findsOneWidget);
    expect(find.byKey(const Key('me_tab_signin_register_btn')), findsNothing);
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
