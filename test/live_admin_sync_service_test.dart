import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/services/live_admin_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LiveAdminSyncService Unit Tests', () {
    test('Initializes, starts background sync timer, and executes syncNow cleanly', () async {
      // Trigger syncNow directly
      final element = ProviderContainer();
      final syncService = element.read(liveAdminSyncServiceProvider);

      expect(syncService, isNotNull);

      // Test lifecycle change
      syncService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Explicit sync invocation
      await syncService.syncNow();

      // Clean disposal
      element.dispose();
    });
  });
}
