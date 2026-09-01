import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/app/app.dart';

void main() {
  testWidgets('LOOMA App Smoke Test - Renders Home and Branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LoomaApp(),
      ),
    );

    // Initial pump & settle
    await tester.pumpAndSettle();

    // Verify LOOMA brand logo & title
    expect(find.text('LOOMA'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
  });
}
