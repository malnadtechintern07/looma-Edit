import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/asset_store/presentation/screens/asset_store_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/cloud_sync/presentation/screens/cloud_sync_screen.dart';
import '../../features/editor/presentation/screens/editor_screen.dart';
import '../../features/photo_editor/presentation/screens/photo_editor_screen.dart';
import '../../features/export/presentation/screens/export_screen.dart';
import '../../features/projects/presentation/screens/home_screen.dart';
import 'route_names.dart';
import 'route_paths.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.home,
  routes: [
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: RoutePaths.auth,
      name: RouteNames.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: RoutePaths.editor,
      name: RouteNames.editor,
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'] ?? '';
        return EditorScreen(projectId: projectId);
      },
    ),
    GoRoute(
      path: RoutePaths.photoEditor,
      name: 'photoEditor',
      builder: (context, state) {
        final extraProj = state.extra;
        if (extraProj != null) {
          return PhotoEditorScreen(project: extraProj as dynamic);
        }
        return const SizedBox.shrink();
      },
    ),
    GoRoute(
      path: RoutePaths.store,
      name: RouteNames.store,
      builder: (context, state) => const AssetStoreScreen(),
    ),
    GoRoute(
      path: RoutePaths.cloud,
      name: RouteNames.cloud,
      builder: (context, state) => const CloudSyncScreen(),
    ),
    GoRoute(
      path: RoutePaths.export,
      name: RouteNames.export,
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'] ?? '';
        return ExportScreen(projectId: projectId);
      },
    ),
  ],
);
