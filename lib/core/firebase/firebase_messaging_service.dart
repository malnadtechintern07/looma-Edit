import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM Background message received: ${message.messageId} | ${message.notification?.title}');
}

/// Represents an in-app or push notification item
class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // announcement, update, promo, info
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
      title: msg.notification?.title ?? msg.data['title'] ?? 'ProCut Update',
      message: msg.notification?.body ?? msg.data['message'] ?? msg.data['body'] ?? '',
      type: msg.data['type'] ?? 'announcement',
      receivedAt: msg.sentTime ?? DateTime.now(),
      data: msg.data,
      isRead: false,
    );
  }

  factory AppNotificationItem.fromBackendJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return AppNotificationItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'ProCut Announcement',
      message: json['message'] ?? '',
      type: json['type'] ?? 'announcement',
      receivedAt: date,
      data: json,
      isRead: false,
    );
  }
}

/// Service managing Firebase Cloud Messaging push notifications
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  static const String _kFcmTokenPrefKey = 'procut_fcm_token_v1';
  static const List<String> _defaultTopics = ['all_users', 'procut_updates', 'prompts'];

  final _notificationStreamController = StreamController<AppNotificationItem>.broadcast();
  Stream<AppNotificationItem> get onNotificationReceived => _notificationStreamController.stream;

  final ValueNotifier<List<AppNotificationItem>> notificationsNotifier = ValueNotifier<List<AppNotificationItem>>([]);
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Callback when user taps a notification that directs to a route
  void Function(String route, Map<String, dynamic> data)? onNotificationNavigate;

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      debugPrint('FirebaseMessagingService: Skipping FCM setup in test environment.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions (Android 13+ and iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // 2. Set foreground presentation options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Retrieve & store FCM token
      try {
        _fcmToken = await messaging.getToken();
        if (_fcmToken != null) {
          debugPrint('====================================');
          debugPrint('🔥 ProCut FCM Token: $_fcmToken');
          debugPrint('====================================');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kFcmTokenPrefKey, _fcmToken!);
        }
      } catch (e) {
        debugPrint('Failed to retrieve FCM token: $e');
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kFcmTokenPrefKey, newToken);
      });

      // 5. Subscribe to default broadcast topics
      for (final topic in _defaultTopics) {
        try {
          await messaging.subscribeToTopic(topic);
          debugPrint('Subscribed to FCM topic: $topic');
        } catch (e) {
          debugPrint('Failed subscribing to topic $topic: $e');
        }
      }

      // 6. Handle foreground push notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title} - ${message.notification?.body}');
        final notif = AppNotificationItem.fromRemoteMessage(message);
        _addNotification(notif);
      });

      // 7. Handle notification taps when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification opened from background: ${message.data}');
        _handleMessageNavigation(message);
      });

      // 8. Check if app was launched from a terminated notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM App launched from terminated notification: ${initialMessage.data}');
        _handleMessageNavigation(initialMessage);
      }

      _initialized = true;
    } catch (e, stack) {
      debugPrint('FirebaseMessagingService init error: $e\n$stack');
    }
  }

  void _addNotification(AppNotificationItem item) {
    _notificationStreamController.add(item);
    final current = List<AppNotificationItem>.from(notificationsNotifier.value);
    current.insert(0, item);
    notificationsNotifier.value = current;
    unreadCountNotifier.value = current.where((n) => !n.isRead).length;
  }

  /// Add external/backend notifications fetched from the server API
  void addBackendNotifications(List<AppNotificationItem> items) {
    final current = List<AppNotificationItem>.from(notificationsNotifier.value);
    final existingIds = current.map((e) => e.id).toSet();
    final newItems = items.where((i) => !existingIds.contains(i.id)).toList();
    if (newItems.isNotEmpty) {
      current.addAll(newItems);
      current.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      notificationsNotifier.value = current;
      unreadCountNotifier.value = current.where((n) => !n.isRead).length;
    }
  }

  void markAsRead(String id) {
    final current = List<AppNotificationItem>.from(notificationsNotifier.value);
    final index = current.indexWhere((n) => n.id == id);
    if (index != -1) {
      current[index] = current[index].copyWith(isRead: true);
      notificationsNotifier.value = current;
      unreadCountNotifier.value = current.where((n) => !n.isRead).length;
    }
  }

  void markAllAsRead() {
    final current = notificationsNotifier.value.map((n) => n.copyWith(isRead: true)).toList();
    notificationsNotifier.value = current;
    unreadCountNotifier.value = 0;
  }

  void clearAll() {
    notificationsNotifier.value = [];
    unreadCountNotifier.value = 0;
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final route = message.data['route'] as String? ?? message.data['screen'] as String?;
    if (route != null && onNotificationNavigate != null) {
      onNotificationNavigate!(route, message.data);
    }
  }

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
