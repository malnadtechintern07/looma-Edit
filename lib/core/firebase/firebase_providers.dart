import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/server_config.dart';
import '../network/api_client.dart';
import 'firebase_analytics_service.dart';
import 'firebase_messaging_service.dart';

final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  return FirebaseMessagingService();
});

final firebaseAnalyticsServiceProvider = Provider<FirebaseAnalyticsService>((ref) {
  return FirebaseAnalyticsService();
});

/// Reactive stream of in-app & push notification items
final notificationsListProvider = StreamProvider<List<AppNotificationItem>>((ref) async* {
  final service = ref.watch(firebaseMessagingServiceProvider);
  yield service.notificationsNotifier.value;

  // Re-emit whenever notificationsNotifier changes
  void listener() {}
  service.notificationsNotifier.addListener(listener);
  ref.onDispose(() => service.notificationsNotifier.removeListener(listener));

  await for (final _ in service.onNotificationReceived) {
    yield service.notificationsNotifier.value;
  }
});

/// Unread notification count provider
final unreadNotificationCountProvider = StateProvider<int>((ref) {
  final service = ref.watch(firebaseMessagingServiceProvider);
  final notifier = ref.watch(StateProvider<int>((_) => service.unreadCountNotifier.value).notifier);

  void update() {
    notifier.state = service.unreadCountNotifier.value;
  }

  service.unreadCountNotifier.addListener(update);
  ref.onDispose(() => service.unreadCountNotifier.removeListener(update));
  return service.unreadCountNotifier.value;
});

/// Fetches server announcements and notifications from the backend API
final fetchBackendNotificationsProvider = FutureProvider<List<AppNotificationItem>>((ref) async {
  try {
    final baseUrl = await ServerConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/app/notifications');
    final res = await ApiClient.get(uri, timeout: const Duration(seconds: 8));

    if (res.isOk && res.json is Map) {
      final data = res.json as Map<String, dynamic>;
      final rawList = data['data']?['notifications'] ?? data['notifications'] ?? [];
      if (rawList is List) {
        final items = rawList
            .whereType<Map<String, dynamic>>()
            .map((j) => AppNotificationItem.fromBackendJson(j))
            .toList();

        // Feed to FirebaseMessagingService notification state
        ref.read(firebaseMessagingServiceProvider).addBackendNotifications(items);
        return items;
      }
    }
  } catch (_) {}
  return [];
});
