import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_remote_config_service.dart';
import '../../features/asset_store/presentation/providers/asset_store_provider.dart';
import '../../features/ai_photo_edit/data/ai_photo_presets_data.dart';
import '../../features/ai_video_edit/data/ai_video_presets_data.dart';

/// Silent, production-grade Live Admin Panel Synchronizer.
/// Automatically and continuously synchronizes all changes made in the
/// hosted Admin Panel (templates, banners, AI photo & video styles, music, branding,
/// and features) directly into the app with zero manual intervention.
class LiveAdminSyncService with WidgetsBindingObserver {
  final Ref ref;
  Timer? _pollingTimer;
  bool _isSyncing = false;

  LiveAdminSyncService(this.ref) {
    WidgetsBinding.instance.addObserver(this);
    _startSyncLoop();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the admin or user returns to the app from the browser or background,
    // immediately pull any newly published changes from the admin panel.
    if (state == AppLifecycleState.resumed) {
      syncNow();
    }
  }

  void _startSyncLoop() {
    // Initial sync on app launch
    Future.microtask(() => syncNow());

    // Continuous background sync every 12 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      syncNow();
    });
  }

  /// Triggers a silent, non-blocking refresh of all admin-controlled data
  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Invalidate and re-fetch App Remote Config (banners, branding, theme, home sections)
      ref.invalidate(appRemoteConfigProvider);

      // 2. Invalidate and re-fetch Video Templates
      ref.invalidate(storeTemplatesFutureProvider);

      // 3. Invalidate and re-fetch Music Catalog
      ref.invalidate(musicCatalogFutureProvider);

      // 4. Fetch latest AI Photo Presets from server
      await AiPhotoPresetsData.fetchServerPresets();

      // 5. Fetch latest AI Video Presets from server
      await AiVideoPresetsData.fetchServerPresets();
    } catch (_) {
      // Offline-resilient: keep existing cached data without throwing errors
    } finally {
      _isSyncing = false;
    }
  }
}

final liveAdminSyncServiceProvider = Provider<LiveAdminSyncService>((ref) {
  final service = LiveAdminSyncService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
