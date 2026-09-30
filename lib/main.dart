import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/server_config.dart';
import 'core/firebase/firebase_service.dart';
import 'core/notifications/pusher_hub_client.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/storage_providers.dart';
export 'pusher_hub.dart';
export 'core/notifications/pusher_hub_client.dart' show pusherHub;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Concurrently initialize critical local storage, core Firebase, and PusherHub configuration
  final storageService = LocalStorageService();
  await Future.wait([
    storageService.init(),
    FirebaseService.initializeCore(),
  ]);

  // Step 8: Check if app was launched directly from tapping a push notification
  RemoteMessage? initialMessage;
  try {
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  } catch (_) {}

  // Step 5: Register device with PusherHub
  try {
    await pusherHub.registerDevice();
    // Enriches device record with brand, model, app version, language, country, timezone
    await pusherHub.collectDeviceMetadata();
    if (initialMessage != null) {
      pusherHub.trackNotificationOpened(initialMessage);
    }
  } catch (e) {
    debugPrint('PusherHub initialization notice: $e');
  }

  // Fast pre-warm backend server connection cache
  ServerConfig.getBaseUrl().ignore();

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storageService),
      ],
      child: const ProCutApp(),
    ),
  );

  // Initialize non-blocking background Firebase services (topics, analytics)
  FirebaseService.initializeBackgroundServices();
}
