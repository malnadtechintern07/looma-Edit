import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/app/app.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';

void main() {
  testWidgets('ProCut App Smoke Test - Renders Home and Branding', (WidgetTester tester) async {
    final storageService = LocalStorageService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storageService),
        ],
        child: const ProCutApp(),
      ),
    );

    // Initial pump across async provider loading
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify PROCUT brand logo & title
    expect(find.text('PROCUT'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
  });
}
