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

  /// Initialize Firebase Core, FCM, and Analytics safely.
  /// Designed to never throw or block app startup even if offline or in test environments.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      debugPrint('FirebaseService: Skipping initialization in FLUTTER_TEST environment.');
      return;
    }

    try {
      debugPrint('Initializing Firebase Core...');
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('Firebase Core initialized successfully.');

      // Initialize Analytics first
      await analytics.init();

      // Initialize Messaging & Notification listeners
      await messaging.init();

      // Log App Open event
      await analytics.logAppOpen();
    } catch (e, stack) {
      debugPrint('FirebaseService.initialize() notice: $e');
      if (kDebugMode) {
        debugPrint('$stack');
      }
    }
  }
}
