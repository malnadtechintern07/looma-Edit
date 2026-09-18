import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/ai_photo_edit/presentation/screens/ai_photo_edit_screen.dart';
import '../../features/ai_video_edit/presentation/screens/ai_video_edit_screen.dart';
import '../../features/asset_store/presentation/screens/asset_store_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/cloud_sync/presentation/screens/cloud_sync_screen.dart';
import '../../features/editor/presentation/screens/editor_screen.dart';
import '../../features/photo_editor/presentation/screens/photo_editor_screen.dart';
import '../../features/export/presentation/screens/export_screen.dart';
import '../../features/profile/presentation/screens/contact_support_screen.dart';
import '../../features/profile/presentation/screens/help_center_screen.dart';
import '../../features/profile/presentation/screens/privacy_policy_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../core/firebase/firebase_service.dart';
import '../../features/projects/presentation/screens/home_screen.dart';
import 'route_names.dart';
import 'route_paths.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.home,
  observers: [
    FirebaseService.analytics.observer,
  ],
  routes: [
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: RoutePaths.settings,
      name: RouteNames.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: RoutePaths.aiPhotoEdit,
      name: RouteNames.aiPhotoEdit,
      builder: (context, state) => const AiPhotoEditScreen(),
    ),
    GoRoute(
      path: RoutePaths.aiVideoEdit,
      name: RouteNames.aiVideoEdit,
      builder: (context, state) => const AiVideoEditScreen(),
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
    GoRoute(
      path: RoutePaths.privacyPolicy,
      name: RouteNames.privacyPolicy,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: RoutePaths.helpCenter,
      name: RouteNames.helpCenter,
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: RoutePaths.contactSupport,
      name: RouteNames.contactSupport,
      builder: (context, state) => const ContactSupportScreen(),
    ),
  ],
);
