import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/app/app.dart';
import 'package:procut/core/firebase/firebase_messaging_service.dart';
import 'package:procut/core/firebase/firebase_service.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Services & Notification Integration Tests', () {
    test('FirebaseService initializes safely without throwing in test environment', () async {
      expect(() async => await FirebaseService.initialize(), returnsNormally);
      expect(FirebaseService.messaging, isNotNull);
      expect(FirebaseService.analytics, isNotNull);
    });

    test('AppNotificationItem properly parses backend notification JSON', () {
      final json = {
        'id': 42,
        'title': 'New 8K Preset Released',
        'message': 'Cyber Samurai style is now available with high dynamic range.',
        'type': 'update',
        'created_at': '2026-09-18T10:00:00Z',
      };

      final item = AppNotificationItem.fromBackendJson(json);
      expect(item.id, '42');
      expect(item.title, 'New 8K Preset Released');
      expect(item.message, contains('Cyber Samurai'));
      expect(item.type, 'update');
      expect(item.isRead, isFalse);
    });

    test('FirebaseMessagingService handles notifications and unread counts', () {
      final service = FirebaseMessagingService();
      service.clearAll();
      expect(service.notificationsNotifier.value.length, 0);
      expect(service.unreadCountNotifier.value, 0);

      final item1 = AppNotificationItem(
        id: 'n1',
        title: 'Welcome',
        message: 'Welcome to ProCut',
        receivedAt: DateTime.now(),
      );
      final item2 = AppNotificationItem(
        id: 'n2',
        title: 'New Feature',
        message: 'Try our new filters',
        receivedAt: DateTime.now(),
      );

      service.addBackendNotifications([item1, item2]);
      expect(service.notificationsNotifier.value.length, 2);
      expect(service.unreadCountNotifier.value, 2);

      // Mark one read
      service.markAsRead('n1');
      expect(service.unreadCountNotifier.value, 1);

      // Mark all read
      service.markAllAsRead();
      expect(service.unreadCountNotifier.value, 0);
    });

    testWidgets('Home Screen displays Notification Bell and opens Notification Sheet', (WidgetTester tester) async {
      final storageService = LocalStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storageService),
          ],
          child: const ProCutApp(),
        ),
      );

      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify Notification Bell icon exists on Home Screen
      final notifButton = find.byKey(const Key('home_notifications_button'));
      expect(notifButton, findsOneWidget);

      // Tap Notification Bell
      await tester.tap(notifButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Notification Center Sheet opened
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Stay updated with announcements and alerts'), findsOneWidget);

      // Verify notifications list shows items added earlier
      expect(find.text('Welcome'), findsOneWidget);

      // Now clear notifications and verify empty state
      FirebaseMessagingService().clearAll();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.text('Copy FCM Device Token'), findsOneWidget);
    });
  });
}
