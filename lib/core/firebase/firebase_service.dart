import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_analytics_service.dart';
import 'firebase_messaging_service.dart';

/// Central facade managing all Firebase services in ProCut
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static FirebaseMessagingService get messaging => FirebaseMessagingService();
  static FirebaseAnalyticsService get analytics => FirebaseAnalyticsService();

  /// Initialize Firebase Core safely with a fast timeout so it NEVER blocks app launch.
  static Future<void> initializeCore() async {
    if (_isInitialized) return;

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      debugPrint('FirebaseService: Skipping initialization in FLUTTER_TEST environment.');
      return;
    }

    try {
      debugPrint('Initializing Firebase Core...');
      await Firebase.initializeApp().timeout(const Duration(seconds: 2));
      _isInitialized = true;
      debugPrint('Firebase Core initialized successfully.');
    } catch (e, stack) {
      debugPrint('FirebaseService.initializeCore() notice: $e');
      if (kDebugMode) {
        debugPrint('$stack');
      }
    }
  }

  /// Initialize background services (analytics & messaging) asynchronously without blocking UI
  static void initializeBackgroundServices() {
    Future.microtask(() async {
      try {
        if (!_isInitialized) {
          await initializeCore();
        }
        if (_isInitialized) {
          // Initialize Analytics in background
          analytics.init().ignore();

          // Initialize Messaging in background
          messaging.init().ignore();

          // Log App Open event in background
          analytics.logAppOpen().ignore();
        }
      } catch (e) {
        debugPrint('Firebase background services init notice: $e');
      }
    });
  }

  /// Backward compatible initialization method
  static Future<void> initialize() async {
    await initializeCore();
    initializeBackgroundServices();
  }
}
