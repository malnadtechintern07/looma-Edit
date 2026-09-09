import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/services/permission_service.dart';
import 'package:procut/core/widgets/permissions_primer_dialog.dart';
import 'package:procut/features/profile/presentation/screens/profile_screen.dart';
import 'package:procut/features/projects/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PermissionService().resetPermissionPrimer();
  });

  group('PermissionService Unit Tests', () {
    test('Initial primer state is false and getRequestedPermissions returns 5 permissions', () async {
      final service = PermissionService();
      final hasSeen = await service.hasSeenPermissionPrimer();
      expect(hasSeen, isFalse);

      final perms = service.getRequestedPermissions();
      expect(perms.length, 5);

      final titles = perms.map((p) => p.title).toList();
      expect(titles, contains('Camera'));
      expect(titles, contains('Photos & Videos'));
      expect(titles, contains('Microphone'));
      expect(titles, contains('Notifications'));
      expect(titles, contains('Location (Optional)'));
    });

    test('markPermissionPrimerSeen updates state and persists in SharedPreferences', () async {
      final service = PermissionService();
      await service.markPermissionPrimerSeen();
      final hasSeen = await service.hasSeenPermissionPrimer();
      expect(hasSeen, isTrue);

      await service.resetPermissionPrimer();
      expect(await service.hasSeenPermissionPrimer(), isFalse);
    });
  });

  group('PermissionsPrimerDialog Widget Tests', () {
    testWidgets('Renders all 5 permissions, privacy pledge, and action buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool accepted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionsPrimerDialog(
              onAccepted: () {
                accepted = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header elements
      expect(find.text('Permissions & Privacy'), findsOneWidget);
      expect(find.text('Review features ProCut uses for video editing'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

      // All 5 Permission titles
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Photos & Videos'), findsOneWidget);
      expect(find.text('Microphone'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Location (Optional)'), findsOneWidget);

      // Privacy pledge
      expect(find.textContaining('ProCut respects your privacy', findRichText: true), findsOneWidget);

      // Buttons
      expect(find.text('Maybe Later'), findsOneWidget);
      expect(find.text('Continue & Allow'), findsOneWidget);

      // Tap Continue & Allow
      await tester.tap(find.text('Continue & Allow'));
      await tester.pumpAndSettle();

      expect(accepted, isTrue);
      expect(await PermissionService().hasSeenPermissionPrimer(), isTrue);
    });

    testWidgets('Tapping Maybe Later saves seen state without error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PermissionsPrimerDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();

      expect(await PermissionService().hasSeenPermissionPrimer(), isTrue);
    });
  });

  group('ProfileScreen App Permissions Tile Test', () {
    testWidgets('Profile screen contains App Permissions tile and tapping it opens the dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileMeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to Legal & Privacy section
      final permTile = find.byKey(const Key('me_app_permissions_tile'));
      await tester.scrollUntilVisible(permTile, 300);
      expect(permTile, findsOneWidget);
      expect(find.text('App Permissions'), findsOneWidget);

      // Tap App Permissions
      await tester.tap(permTile);
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.byType(PermissionsPrimerDialog), findsOneWidget);
      expect(find.text('Permissions & Privacy'), findsOneWidget);
    });
  });

  group('HomeScreen First-Launch Dialog Integration', () {
    testWidgets('HomeScreen triggers PermissionsPrimerDialog when forceAutoShowInTests is true on first launch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      PermissionService.forceAutoShowInTests = true;
      addTearDown(() {
        PermissionService.forceAutoShowInTests = false;
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Verify the primer dialog pops up automatically on first launch
      expect(find.byType(PermissionsPrimerDialog), findsOneWidget);
      expect(find.text('Permissions & Privacy'), findsOneWidget);
      expect(find.text('Continue & Allow'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Maybe Later'));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(PermissionsPrimerDialog), findsNothing);
      expect(await PermissionService().hasSeenPermissionPrimer(), isTrue);
    });
  });
}
