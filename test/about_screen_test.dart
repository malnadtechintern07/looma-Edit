import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/profile/presentation/screens/about_screen.dart';
import 'package:procut/features/profile/presentation/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AboutScreen Widget Tests', () {
    testWidgets('renders hero header, version, engine badges, and about overview', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AboutScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Title & Brand
      expect(find.text('About ProCut'), findsWidgets);
      expect(find.text('PROCut'), findsOneWidget);
      expect(find.text('Pro Mobile Video Editor & Creative Studio'), findsOneWidget);

      // Verify Badges
      expect(find.text('v2.4.0 (Build 240)'), findsOneWidget);
      expect(find.text('64-BIT OFFLINE ENGINE'), findsOneWidget);
      expect(find.text('PRODUCTION STABLE'), findsOneWidget);

      // Verify Core Sections
      expect(find.text('About ProCut'), findsWidgets);
      expect(find.text('Core Engine Capabilities'), findsOneWidget);
      expect(find.text('Technical Specifications'), findsOneWidget);
      expect(find.text('Developer & Studio'), findsOneWidget);
      expect(find.text('Legal & Resources'), findsOneWidget);
    });

    testWidgets('renders technical specifications and developer studio details', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AboutScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Technical Specs
      expect(find.text('Render Pipeline'), findsOneWidget);
      expect(find.text('Architecture'), findsOneWidget);
      expect(find.text('Supported Video Codecs'), findsOneWidget);
      expect(find.text('Export Resolutions'), findsOneWidget);

      // Developer Studio info
      expect(find.text('Developer / Studio'), findsOneWidget);
      expect(find.text('Official Creator Support'), findsOneWidget);
      expect(find.text('Official Web Portal'), findsOneWidget);
      expect(find.text('procut.free.nf'), findsOneWidget);

      // Copyright
      expect(find.text('© 2026 ProCut Studio. All rights reserved.'), findsOneWidget);
    });

    testWidgets('ProfileMeScreen includes About ProCut tiles', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileMeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify About tiles are present on Profile screen
      final aboutTile = find.byKey(const Key('me_about_tile'));
      expect(aboutTile, findsOneWidget);

      final aboutLegalTile = find.byKey(const Key('me_about_legal_tile'));
      expect(aboutLegalTile, findsOneWidget);
      expect(find.text('About ProCut Video Editor'), findsWidgets);
    });
  });
}
