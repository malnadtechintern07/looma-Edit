import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/ai_photo_edit/data/ai_photo_presets_data.dart';
import 'package:procut/features/ai_photo_edit/presentation/screens/ai_photo_detail_screen.dart';
import 'package:procut/features/ai_photo_edit/presentation/widgets/ai_prompt_studio_sheet.dart';

void main() {
  group('AI Photo Expanded Presets & Prompts Tests', () {
    test('AiPhotoPresetsData contains 50+ presets with full pro specifications', () {
      final presets = AiPhotoPresetsData.presets;
      expect(presets.length, greaterThanOrEqualTo(50));

      for (final p in presets) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.title.isNotEmpty, isTrue);
        expect(p.prompt.length, greaterThanOrEqualTo(25));
        expect(p.referenceImagePath.isNotEmpty, isTrue);
        expect(p.likesCount, greaterThan(1000));
        expect(p.negativePrompt, isNotNull);
        expect(p.modelRecommendation, isNotNull);
        expect(p.lightingStyle, isNotNull);
        expect(p.cameraLens, isNotNull);
      }
    });

    test('All required artistic categories are populated', () {
      final categories = AiPhotoPresetsData.categories;
      expect(categories, containsAll([
        'All',
        'Trending',
        '80s',
        'Sci-Fi',
        'Fantasy',
        'Vintage',
        'Editorial',
        'Anime',
        '3D Pixar',
        'Cyberpunk',
        'Cinematic',
        'Gothic',
      ]));
    });

    testWidgets('AiPhotoDetailScreen renders Pro Generation Specs and Negative Prompt', (tester) async {
      final samplePreset = AiPhotoPresetsData.presets.firstWhere(
        (p) => p.id == 'photo_cyber_samurai',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiPhotoDetailScreen(preset: samplePreset),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cyber Samurai Ronin 2099'), findsWidgets);
      expect(find.text('Pro Generation Specs'), findsOneWidget);
      expect(find.text('Copy All Specs'), findsOneWidget);
      expect(find.text('Negative Prompt (Anti-Artifacts)'), findsOneWidget);
      expect(find.text('Copy Negative'), findsOneWidget);
    });

    testWidgets('AiPromptStudioSheet opens and renders interactive controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AiPromptStudioSheet.show(context),
                child: const Text('Open Studio'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Studio'));
      await tester.pumpAndSettle();

      expect(find.text('AI Prompt Studio'), findsOneWidget);
      expect(find.text('1. Choose Subject or Enter Custom'), findsOneWidget);
      expect(find.text('2. Visual Art Style'), findsOneWidget);
      expect(find.text('3. Lighting & Atmosphere'), findsOneWidget);
      expect(find.text('4. Camera, Lens & Depth of Field'), findsOneWidget);
      expect(find.text('5. AI Engine & Target Model'), findsOneWidget);
      expect(find.text('6. Aspect Ratio'), findsOneWidget);
      expect(find.text('Copy Prompt'), findsOneWidget);
      expect(find.text('+ Specs'), findsOneWidget);
    });
  });
}
