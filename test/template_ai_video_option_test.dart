import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';
import 'package:procut/features/ai_video_edit/data/ai_video_presets_data.dart';
import 'package:procut/features/ai_video_edit/presentation/screens/ai_video_edit_screen.dart';
import 'package:procut/features/asset_store/presentation/screens/template_feed_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AI Video Presets Data & Content Tests', () {
    test('AiVideoPresetsData contains 13+ rich presets with prompts and models', () {
      final presets = AiVideoPresetsData.presets;
      expect(presets.length, greaterThanOrEqualTo(13));

      // Verify specific new presets exist
      final ids = presets.map((p) => p.id).toSet();
      expect(ids.contains('video_cosmic_hyperdrive'), isTrue);
      expect(ids.contains('video_neon_puddle_reflection'), isTrue);
      expect(ids.contains('video_alpine_helicopter_orbit'), isTrue);
      expect(ids.contains('video_sunset_boulevard_cruise'), isTrue);
      expect(ids.contains('video_quantum_portal_chamber'), isTrue);
      expect(ids.contains('video_tokyo_night_walk'), isTrue);

      // Verify prompt quality and completeness
      for (final p in presets) {
        expect(p.prompt.trim().isNotEmpty, isTrue, reason: '${p.id} prompt must not be empty');
        expect(p.videoAssetPath.trim().isNotEmpty, isTrue, reason: '${p.id} videoAssetPath must not be empty');
        expect(p.modelName.trim().isNotEmpty, isTrue, reason: '${p.id} modelName must not be empty');
        expect(p.style.trim().isNotEmpty, isTrue, reason: '${p.id} style must not be empty');
        expect(p.cameraMovement.trim().isNotEmpty, isTrue, reason: '${p.id} cameraMovement must not be empty');
      }
    });

    test('AiVideoPresetsData categories include Sci-Fi & Cyberpunk, Nature & Travel, Trending', () {
      final cats = AiVideoPresetsData.categories;
      expect(cats.contains('All'), isTrue);
      expect(cats.contains('Trending'), isTrue);
      expect(cats.contains('Sci-Fi & Cyberpunk'), isTrue);
      expect(cats.contains('Nature & Travel'), isTrue);
    });
  });

  group('Template Option - AI Video Switcher Widget Tests', () {
    testWidgets('TemplateFeedScreen shows Video Templates and AI Video switcher options', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storageService = LocalStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storageService),
          ],
          child: const MaterialApp(
            home: TemplateFeedScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify header and switcher options are rendered
      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Video Templates'), findsOneWidget);
      expect(find.text('AI Video Prompts'), findsOneWidget);
      expect(find.text('✨ AI Video'), findsOneWidget);
    });

    testWidgets('Tapping AI Video Prompts switcher switches to embedded AiVideoEditScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storageService = LocalStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storageService),
          ],
          child: const MaterialApp(
            home: TemplateFeedScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on the AI Video Prompts option
      final aiVideoSwitcher = find.text('AI Video Prompts');
      expect(aiVideoSwitcher, findsOneWidget);
      await tester.tap(aiVideoSwitcher);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Embedded AiVideoEditScreen should now be present
      expect(find.byType(AiVideoEditScreen), findsOneWidget);
      // Prompt search box should be visible
      expect(
        find.byWidgetPredicate((w) =>
            w is TextField &&
            (w.decoration?.hintText?.contains('Search prompts, models') ?? false)),
        findsOneWidget,
      );
    });

    testWidgets('Tapping ✨ AI Video category chip also activates AI Video option', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storageService = LocalStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storageService),
          ],
          child: const MaterialApp(
            home: TemplateFeedScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on ✨ AI Video chip
      final aiVideoChip = find.text('✨ AI Video');
      expect(aiVideoChip, findsOneWidget);
      await tester.tap(aiVideoChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify that AI Video option is now active
      expect(find.byType(AiVideoEditScreen), findsOneWidget);
    });
  });
}
