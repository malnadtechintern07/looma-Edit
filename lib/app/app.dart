import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/services/app_remote_config_service.dart';
import '../core/services/live_admin_sync_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class ProCutApp extends ConsumerWidget {
  const ProCutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Automatically keep app in real-time sync with hosted Admin Panel
    ref.watch(liveAdminSyncServiceProvider);

    final configAsync = ref.watch(appRemoteConfigProvider);

    // Resolve dynamic theme — falls back to static darkTheme while loading/error
    final ThemeData resolvedTheme = configAsync.when(
      data: (cfg) => AppTheme.fromRemoteConfig(cfg.theme),
      loading: () => AppTheme.darkTheme,
      error: (e, _) => AppTheme.darkTheme,
    );

    // Resolve app title from remote config
    final String appTitle = configAsync.valueOrNull?.appName ??
        configAsync.valueOrNull?.branding.appName ??
        AppConstants.appName;

    // Maintenance mode overlay
    final bool maintenanceOn = configAsync.valueOrNull?.maintenanceMode ?? false;
    final String maintTitle   = configAsync.valueOrNull?.maintenanceTitle ?? 'Scheduled Maintenance';
    final String maintMsg     = configAsync.valueOrNull?.maintenanceMessage ?? '';

    return MaterialApp.router(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: resolvedTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        if (maintenanceOn) {
          return _MaintenanceOverlay(title: maintTitle, message: maintMsg);
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

/// Full-screen maintenance overlay shown to all users when maintenance mode is active.
class _MaintenanceOverlay extends StatelessWidget {
  final String title;
  final String message;

  const _MaintenanceOverlay({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFB800), width: 2),
                  ),
                  child: const Icon(Icons.engineering_rounded, color: Color(0xFFFFB800), size: 44),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  message.isNotEmpty ? message : 'ProCut is temporarily undergoing scheduled maintenance.\nOffline editing remains fully functional.',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Image.asset('assets/icon/app_icon.png', width: 48, height: 48,
                    errorBuilder: (ctx, e, _) => const SizedBox.shrink()),
                const SizedBox(height: 8),
                const Text(
                  'ProCut',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias for legacy tests and references
typedef LoomaApp = ProCutApp;
