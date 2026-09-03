import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/app/app.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/core/storage/storage_providers.dart';

void main() {
  testWidgets('LOOMA App Smoke Test - Renders Home and Branding', (WidgetTester tester) async {
    final storageService = LocalStorageService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storageService),
        ],
        child: const LoomaApp(),
      ),
    );

    // Initial pump across async provider loading
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify LOOMA brand logo & title
    expect(find.text('LOOMA'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
  });
}
