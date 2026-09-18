import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/ai_video_edit/data/ai_video_presets_data.dart';
import 'package:procut/features/ai_video_edit/presentation/screens/ai_video_edit_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Video Presets & Prompt Length Tests', () {
    test('AiVideoPresetsData contains 20 video presets with long cinematic prompts', () {
      final presets = AiVideoPresetsData.presets;
      expect(presets.length, equals(20));

      for (final p in presets) {
        // Every video prompt should be specific, cinematic, and long (at least 300 characters)
        expect(p.prompt.length, greaterThanOrEqualTo(300),
            reason: '${p.id} prompt is too short (${p.prompt.length} chars)');
        expect(p.title.isNotEmpty, isTrue);
        expect(p.category.isNotEmpty, isTrue);
        expect(p.cameraMovement.isNotEmpty, isTrue);
        expect(p.lighting.isNotEmpty, isTrue);
        expect(p.modelName.isNotEmpty, isTrue);
        expect(p.tags.length, greaterThanOrEqualTo(3));
      }
    });

    test('AiVideoPresetsData categories include all expected genres', () {
      final categories = AiVideoPresetsData.categories;
      expect(categories, contains('All'));
      expect(categories, contains('Trending'));
      expect(categories, contains('Cinematic'));
      expect(categories, contains('Sci-Fi & Cyberpunk'));
      expect(categories, contains('Nature & Travel'));
    });
  });

  group('AI Video Edit Screen Overflow & UI Tests', () {
    testWidgets('AiVideoEditScreen AppBar does not overflow on narrow mobile screen (320px)', (tester) async {
      // Set a narrow mobile screen width (e.g. 320x640)
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AiVideoEditScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the title renders without overflow
      expect(find.text('AI Video Edit'), findsOneWidget);
      expect(find.text('Playable AI Video Generation & Prompts'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('AiVideoEditScreen card prompt expands and collapses when tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiVideoEditScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check for prompt header
      final promptLabelFinder = find.text('PROMPT');
      expect(promptLabelFinder, findsWidgets);

      // Verify initial state has "More"
      expect(find.text('More'), findsWidgets);

      // Tap on the prompt box to expand
      await tester.tap(find.text('More').first);
      await tester.pump();

      // Verify toggled to "Less"
      expect(find.text('Less'), findsWidgets);

      expect(tester.takeException(), isNull);
    });
  });
}
