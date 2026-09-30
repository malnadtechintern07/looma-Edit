import 'dart:io' show Platform;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Safe observer that delegates to FirebaseAnalyticsObserver only when Firebase is initialized.
class SafeFirebaseAnalyticsObserver extends NavigatorObserver {
  FirebaseAnalyticsObserver? _delegate;

  FirebaseAnalyticsObserver? get _activeDelegate {
    if (_delegate != null) return _delegate;
    try {
      if (Firebase.apps.isNotEmpty) {
        _delegate = FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);
      }
    } catch (_) {}
    return _delegate;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    try {
      _activeDelegate?.didPush(route, previousRoute);
    } catch (_) {}
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      _activeDelegate?.didPop(route, previousRoute);
    } catch (_) {}
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    try {
      _activeDelegate?.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    } catch (_) {}
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    try {
      _activeDelegate?.didRemove(route, previousRoute);
    } catch (_) {}
  }
}

/// Service providing typed methods for tracking user events, conversions, and screens in Firebase Analytics
class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalytics? get analytics {
    if (_analytics != null) return _analytics;
    try {
      if (Firebase.apps.isNotEmpty) {
        _analytics = FirebaseAnalytics.instance;
      }
    } catch (_) {}
    return _analytics;
  }

  NavigatorObserver? _safeObserver;
  NavigatorObserver get observer => _safeObserver ??= SafeFirebaseAnalyticsObserver();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      debugPrint('FirebaseAnalyticsService: Skipping Analytics in test environment.');
      return;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        _analytics ??= FirebaseAnalytics.instance;
        await _analytics!.setAnalyticsCollectionEnabled(true);
        _initialized = true;
        debugPrint('FirebaseAnalyticsService: Successfully initialized.');
      }
    } catch (e) {
      debugPrint('FirebaseAnalyticsService init failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core & Lifecycle Events
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logAppOpen() async {
    try {
      await _analytics?.logAppOpen();
    } catch (e) {
      debugPrint('Analytics logAppOpen error: $e');
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Analytics logScreenView error: $e');
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserId error: $e');
    }
  }

  Future<void> setUserProperty({required String name, required String value}) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics setUserProperty error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Authentication Events
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logLogin({required String method, String? userId}) async {
    try {
      if (userId != null) await setUserId(userId);
      await _analytics?.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics?.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics logSignUp error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI Creation & Prompt Events
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logAiPhotoGenerate({
    required String prompt,
    required String style,
    bool isLongPrompt = false,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'ai_photo_generate',
        parameters: {
          'style': style,
          'prompt_preview': prompt.length > 50 ? prompt.substring(0, 50) : prompt,
          'prompt_length': prompt.length,
          'is_long_prompt': isLongPrompt ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('Analytics logAiPhotoGenerate error: $e');
    }
  }

  Future<void> logAiVideoGenerate({
    required String prompt,
    String? ratio,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'ai_video_generate',
        parameters: {
          'prompt_preview': prompt.length > 50 ? prompt.substring(0, 50) : prompt,
          'prompt_length': prompt.length,
          'ratio': ?ratio,
        },
      );
    } catch (e) {
      debugPrint('Analytics logAiVideoGenerate error: $e');
    }
  }

  Future<void> logPromptShare({
    required String promptTitle,
    required String promptType, // 'photo' or 'video'
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'prompt_shared',
        parameters: {
          'prompt_title': promptTitle,
          'prompt_type': promptType,
          'share_method': 'deep_link_copy',
        },
      );
    } catch (e) {
      debugPrint('Analytics logPromptShare error: $e');
    }
  }

  Future<void> logPromptCopy({
    required String promptTitle,
    required String promptType,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'prompt_copied',
        parameters: {
          'prompt_title': promptTitle,
          'prompt_type': promptType,
        },
      );
    } catch (e) {
      debugPrint('Analytics logPromptCopy error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Editor & Export Events
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logProjectCreated({
    required String title,
    required String aspectRatio,
    int clipCount = 0,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'project_created',
        parameters: {
          'project_title': title,
          'aspect_ratio': aspectRatio,
          'clip_count': clipCount,
        },
      );
    } catch (e) {
      debugPrint('Analytics logProjectCreated error: $e');
    }
  }

  Future<void> logProjectExport({
    required String resolution,
    required int durationMs,
    required int clipCount,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'project_exported',
        parameters: {
          'resolution': resolution,
          'duration_seconds': (durationMs / 1000).round(),
          'clip_count': clipCount,
        },
      );
    } catch (e) {
      debugPrint('Analytics logProjectExport error: $e');
    }
  }

  Future<void> logAssetDownload({
    required String assetId,
    required String assetTitle,
    required String category,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'asset_download',
        parameters: {
          'asset_id': assetId,
          'asset_title': assetTitle,
          'category': category,
        },
      );
    } catch (e) {
      debugPrint('Analytics logAssetDownload error: $e');
    }
  }

  Future<void> logNotificationInteraction({
    required String notificationId,
    required String action, // 'open', 'dismiss'
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'notification_interaction',
        parameters: {
          'notification_id': notificationId,
          'action': action,
        },
      );
    } catch (e) {
      debugPrint('Analytics logNotificationInteraction error: $e');
    }
  }

  /// Custom generic event logging
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logCustomEvent error: $e');
    }
  }
}
