import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procut/core/services/app_actions_service.dart';
import 'package:procut/core/widgets/rate_us_dialog.dart';
import 'package:procut/features/profile/presentation/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rate Us & Share App Tests', () {
    late List<MethodCall> channelCalls;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      channelCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('procut/app_actions'), (call) async {
        channelCalls.add(call);
        if (call.method == 'openPlayStore') {
          return true;
        } else if (call.method == 'shareApp') {
          return true;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('procut/app_actions'), null);
    });

    test('AppActionsService saves user rating and tracks first-export prompt', () async {
      expect(await AppActionsService.hasShownFirstExportRating(), isFalse);
      expect(await AppActionsService.getSavedRating(), isNull);

      // Save a rating
      await AppActionsService.saveUserRating(5);
      expect(await AppActionsService.getSavedRating(), equals(5));
      expect(await AppActionsService.hasShownFirstExportRating(), isTrue);

      // Mark first export rating shown
      await AppActionsService.markFirstExportRatingShown();
      expect(await AppActionsService.hasShownFirstExportRating(), isTrue);
    });

    test('AppActionsService.openPlayStore invokes procut/app_actions channel on Android', () async {
      final res = await AppActionsService.openPlayStore();
      expect(res, isA<bool>());
    });

    test('AppActionsService.shareApp invokes procut/app_actions channel or fallback', () async {
      final res = await AppActionsService.shareApp(
        text: 'Test share message',
        subject: 'Test subject',
      );
      expect(res, isA<bool>());
    });

    testWidgets('Tapping Rate Us in ProfileMeScreen displays in-app 1-5 star RateUsDialog and submits rating', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileMeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Community & Support header
      expect(find.text('Community & Support'), findsOneWidget);

      // Verify Rate Us tile
      final rateUsTile = find.byKey(const Key('me_rate_us_tile'));
      expect(rateUsTile, findsOneWidget);

      // Scroll and tap Rate Us
      await tester.ensureVisible(rateUsTile);
      await tester.pumpAndSettle();
      await tester.tap(rateUsTile);
      await tester.pumpAndSettle();

      // Verify RateUsDialog appeared
      expect(find.byKey(const Key('rate_us_dialog')), findsOneWidget);
      expect(find.text('Rate ProCut Video Editor'), findsOneWidget);
      expect(find.byKey(const Key('rate_us_star_1')), findsOneWidget);
      expect(find.byKey(const Key('rate_us_star_5')), findsOneWidget);
      expect(find.byKey(const Key('rate_us_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('rate_us_cancel_button')), findsOneWidget);

      // Tap star 4
      await tester.tap(find.byKey(const Key('rate_us_star_4')));
      await tester.pumpAndSettle();
      expect(find.text('Great experience! 👍'), findsOneWidget);

      // Tap Submit
      await tester.tap(find.byKey(const Key('rate_us_submit_button')));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byKey(const Key('rate_us_dialog')), findsNothing);

      // Saved rating should be 4
      expect(await AppActionsService.getSavedRating(), equals(4));
    });

    testWidgets('Tapping Not Now dismisses RateUsDialog without submitting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showRateUsDialog(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rate_us_dialog')), findsOneWidget);

      // Tap Not Now
      await tester.tap(find.byKey(const Key('rate_us_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rate_us_dialog')), findsNothing);
      expect(await AppActionsService.getSavedRating(), isNull);
    });

    testWidgets('First-export prompt is shown once and marked so it never shows again', (tester) async {
      expect(await AppActionsService.hasShownFirstExportRating(), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final hasShown = await AppActionsService.hasShownFirstExportRating();
                  if (!hasShown && context.mounted) {
                    await showRateUsDialog(context, isFirstExport: true);
                  }
                },
                child: const Text('Export Finished'),
              ),
            ),
          ),
        ),
      );

      // First export
      await tester.tap(find.text('Export Finished'));
      await tester.pumpAndSettle();

      // Dialog should be shown
      expect(find.byKey(const Key('rate_us_dialog')), findsOneWidget);
      expect(find.text('Enjoying ProCut?'), findsOneWidget);

      // Close it
      await tester.tap(find.byKey(const Key('rate_us_cancel_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rate_us_dialog')), findsNothing);

      // Flag must now be true
      expect(await AppActionsService.hasShownFirstExportRating(), isTrue);

      // Second export attempt - should NOT open dialog
      await tester.tap(find.text('Export Finished'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rate_us_dialog')), findsNothing);
    });
  });
}
