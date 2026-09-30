import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/server_config.dart';
import '../network/api_client.dart';

/// Top-level background message handler for Firebase Cloud Messaging.
/// Must be a top-level (non-class) function annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint(
      'FCM Background message received: ${message.messageId} | ${message.notification?.title}');

  // If message came without a system notification payload (e.g. data-only push), show it locally
  if (message.notification == null) {
    final title = message.data['title']?.toString() ?? 'ProCut Update';
    final body = message.data['message']?.toString() ?? message.data['body']?.toString() ?? '';
    if (body.isNotEmpty) {
      await showLocalNotification(
        title: title,
        body: body,
        payload: message.data['route']?.toString(),
      ).catchError((_) {});
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Local Notifications plugin (singleton, shared across the app)
// ─────────────────────────────────────────────────────────────────────────────

/// A single shared instance of FlutterLocalNotificationsPlugin for the app.
final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _localNotificationsInitialized = false;

/// Initialise flutter_local_notifications.  Safe to call multiple times.
Future<void> initLocalNotifications() async {
  if (_localNotificationsInitialized) return;

  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await _localNotificationsPlugin.initialize(initSettings);

  // Create the Android notification channel (Android 8.0+ requirement)
  const channel = AndroidNotificationChannel(
    'procut_notifications', // must match AndroidManifest.xml
    'ProCut Notifications',
    description: 'Announcements and updates from ProCut',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  await _localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  _localNotificationsInitialized = true;
}

/// Show a local popup notification (used when the app is in the foreground or background).
Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  if (!_localNotificationsInitialized) await initLocalNotifications();

  const androidDetails = AndroidNotificationDetails(
    'procut_notifications',
    'ProCut Notifications',
    channelDescription: 'Announcements and updates from ProCut',
    importance: Importance.max,
    priority: Priority.max,
    showWhen: true,
    enableVibration: true,
    playSound: true,
    icon: '@mipmap/ic_launcher',
    visibility: NotificationVisibility.public,
    channelShowBadge: true,
    ticker: 'ProCut Notification',
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const details =
      NotificationDetails(android: androidDetails, iOS: iosDetails);

  await _localNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch & 0xFFFF, // unique ID
    title,
    body,
    details,
    payload: payload,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  AppNotificationItem model
// ─────────────────────────────────────────────────────────────────────────────

/// Represents an in-app or push notification item.
class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // announcement | update | promotion | info
  final DateTime receivedAt;
  final Map<String, dynamic> data;
  final bool isRead;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'info',
    required this.receivedAt,
    this.data = const {},
    this.isRead = false,
  });

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    DateTime? receivedAt,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      receivedAt: receivedAt ?? this.receivedAt,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotificationItem.fromRemoteMessage(RemoteMessage msg) {
    return AppNotificationItem(
      id: msg.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title:
          msg.notification?.title ?? msg.data['title'] ?? 'ProCut Update',
      message: msg.notification?.body ??
          msg.data['message'] ??
          msg.data['body'] ??
          '',
      type: msg.data['type'] ?? 'announcement',
      receivedAt: msg.sentTime ?? DateTime.now(),
      data: {...msg.data, 'is_push': true},
      isRead: false,
    );
  }

  factory AppNotificationItem.fromBackendJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      final raw = json['created_at']?.toString() ?? '';
      date = DateTime.tryParse(raw.replaceAll(' ', 'T')) ??
          DateTime.tryParse(raw) ??
          DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return AppNotificationItem(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'ProCut Announcement',
      message: json['message'] ?? '',
      type: json['type'] ?? 'announcement',
      receivedAt: date,
      data: json,
      isRead: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FirebaseMessagingService
// ─────────────────────────────────────────────────────────────────────────────

/// Service managing Firebase Cloud Messaging push notifications.
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  static const String _kFcmTokenPrefKey = 'procut_fcm_token_v1';
  static const List<String> _defaultTopics = [
    'all_users',
    'procut_updates',
    'prompts',
  ];

  final _notificationStreamController =
      StreamController<AppNotificationItem>.broadcast();
  Stream<AppNotificationItem> get onNotificationReceived =>
      _notificationStreamController.stream;

  final ValueNotifier<List<AppNotificationItem>> notificationsNotifier =
      ValueNotifier<List<AppNotificationItem>>([]);
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Callback when user taps a notification that directs to a route.
  void Function(String route, Map<String, dynamic> data)? onNotificationNavigate;

  // ------------------------------------------------------------------ //
  //  Initialisation                                                      //
  // ------------------------------------------------------------------ //

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      debugPrint(
          'FirebaseMessagingService: Skipping FCM setup in test environment.');
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint(
            'FirebaseMessagingService: Firebase Core not initialized yet.');
        return;
      }

      // Initialise local notifications so we can show popups in foreground
      await initLocalNotifications().catchError((e) {
        debugPrint('initLocalNotifications error (non-fatal): $e');
      });

      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions (Android 13+ and iOS)
      try {
        final settings = await messaging
            .requestPermission(
              alert: true,
              announcement: false,
              badge: true,
              carPlay: false,
              criticalAlert: false,
              provisional: false,
              sound: true,
            )
            .timeout(const Duration(seconds: 3));
        debugPrint('FCM Permission status: ${settings.authorizationStatus}');
      } catch (e) {
        debugPrint('FCM requestPermission non-blocking notice: $e');
      }

      // 2. Set foreground presentation options (iOS / macOS)
      try {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

      // 3. Register background message handler
      try {
        FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler);
      } catch (_) {}

      // 4. Retrieve & store FCM token, then register it with the backend
      try {
        _fcmToken =
            await messaging.getToken().timeout(const Duration(seconds: 4));
        if (_fcmToken != null) {
          debugPrint('====================================');
          debugPrint('🔥 ProCut FCM Token: $_fcmToken');
          debugPrint('====================================');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kFcmTokenPrefKey, _fcmToken!);
          // Register with backend (non-blocking)
          _registerTokenWithBackend(_fcmToken!).ignore();
        }
      } catch (e) {
        debugPrint('Failed to retrieve FCM token: $e');
      }

      // Listen for token refresh – re-register whenever the token rotates
      messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kFcmTokenPrefKey, newToken);
        } catch (_) {}
        _registerTokenWithBackend(newToken).ignore();
      });

      // 5. Subscribe to default broadcast topics
      Future.wait(
        _defaultTopics.map(
          (topic) => messaging
              .subscribeToTopic(topic)
              .timeout(const Duration(seconds: 3))
              .catchError((e) {
            debugPrint('Failed subscribing to topic $topic: $e');
          }),
        ),
      ).ignore();

      // 6. Handle foreground push notifications
      //    → Show a local popup so the user sees it even when the app is open
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint(
            'FCM Foreground message: ${message.notification?.title} – ${message.notification?.body}');
        final notif = AppNotificationItem.fromRemoteMessage(message);
        _addNotification(notif);

        // Show native popup (Android: local notification; iOS: handled by setForegroundNotificationPresentationOptions)
        if (!kIsWeb) {
          await showLocalNotification(
            title: notif.title,
            body: notif.message,
            payload: notif.data['route']?.toString(),
          ).catchError((e) {
            debugPrint('showLocalNotification error: $e');
          });
        }
      });

      // 7. Handle notification taps when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
            'FCM Notification opened from background: ${message.data}');
        _handleMessageNavigation(message);
      });

      // 8. Check if app was launched from a terminated-state notification
      try {
        final initialMessage = await messaging
            .getInitialMessage()
            .timeout(const Duration(seconds: 2));
        if (initialMessage != null) {
          debugPrint(
              'FCM App launched from terminated notification: ${initialMessage.data}');
          _handleMessageNavigation(initialMessage);
        }
      } catch (_) {}

      _initialized = true;
    } catch (e, stack) {
      debugPrint('FirebaseMessagingService init error: $e\n$stack');
    }
  }

  // ------------------------------------------------------------------ //
  //  Backend token registration                                          //
  // ------------------------------------------------------------------ //

  /// Sends this device's FCM token to the ProCut backend so the admin panel
  /// can deliver targeted push notifications.
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final baseUrl = await ServerConfig.getBaseUrl()
          .timeout(const Duration(seconds: 5));

      // Determine current platform label
      String platform = 'android';
      if (!kIsWeb) {
        if (Platform.isIOS || Platform.isMacOS) {
          platform = 'ios';
        }
      }

      final uri = Uri.parse('$baseUrl/api/app/register-fcm-token');
      await ApiClient.post(
        uri,
        body: {
          'fcm_token': token,
          'platform': platform,
        },
      ).timeout(const Duration(seconds: 6));

      debugPrint('FCM token registered with backend ✓');
    } catch (e) {
      // Non-critical – topic-based global broadcasts still work without registration
      debugPrint('_registerTokenWithBackend non-fatal error: $e');
    }
  }

  // ------------------------------------------------------------------ //
  //  Notification list management                                        //
  // ------------------------------------------------------------------ //

  void _addNotification(AppNotificationItem item) {
    _notificationStreamController.add(item);
    final current =
        List<AppNotificationItem>.from(notificationsNotifier.value);
    current.insert(0, item);
    notificationsNotifier.value = current;
    unreadCountNotifier.value =
        current.where((n) => !n.isRead).length;
  }

  /// Add external/backend notifications fetched from the server API.
  void addBackendNotifications(List<AppNotificationItem> items) {
    syncBackendNotifications(items);
  }

  /// Syncs notifications fetched from the server API, preserving local read-states
  /// and keeping any live push items that may not be in the backend list yet.
  void syncBackendNotifications(List<AppNotificationItem> backendItems) {
    final readIds = notificationsNotifier.value
        .where((n) => n.isRead)
        .map((n) => n.id)
        .toSet();

    // Keep live FCM-pushed notifications that aren't in the backend list yet
    final backendIds = backendItems.map((b) => b.id).toSet();
    final localLive = notificationsNotifier.value
        .where(
            (n) => !backendIds.contains(n.id) && (n.data['is_push'] == true))
        .toList();

    final result = <AppNotificationItem>[];
    for (final item in backendItems) {
      final isRead = readIds.contains(item.id);
      result.add(isRead ? item.copyWith(isRead: true) : item);
    }
    result.addAll(localLive);
    result.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

    notificationsNotifier.value = result;
    unreadCountNotifier.value = result.where((n) => !n.isRead).length;
  }

  void markAsRead(String id) {
    final current =
        List<AppNotificationItem>.from(notificationsNotifier.value);
    final index = current.indexWhere((n) => n.id == id);
    if (index != -1) {
      current[index] = current[index].copyWith(isRead: true);
      notificationsNotifier.value = current;
      unreadCountNotifier.value =
          current.where((n) => !n.isRead).length;
    }
  }

  void markAllAsRead() {
    final current =
        notificationsNotifier.value.map((n) => n.copyWith(isRead: true)).toList();
    notificationsNotifier.value = current;
    unreadCountNotifier.value = 0;
  }

  void clearAll() {
    notificationsNotifier.value = [];
    unreadCountNotifier.value = 0;
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final route = message.data['route'] as String? ??
        message.data['screen'] as String?;
    if (route != null && onNotificationNavigate != null) {
      onNotificationNavigate!(route, message.data);
    }
  }

  // ------------------------------------------------------------------ //
  //  Topic helpers                                                       //
  // ------------------------------------------------------------------ //

  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Returns the cached FCM token, or reads it from SharedPreferences.
  Future<String?> getSavedToken() async {
    if (_fcmToken != null) return _fcmToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kFcmTokenPrefKey);
    } catch (_) {
      return null;
    }
  }
}
