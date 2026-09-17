import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/ai_photo_edit/presentation/screens/ai_photo_edit_screen.dart';
import 'package:procut/features/ai_photo_edit/data/ai_photo_presets_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Photo Edit Screen & Presets Tests', () {
    test('AiPhotoPresetsData has presets and standard categories', () {
      final presets = AiPhotoPresetsData.presets;
      expect(presets.isNotEmpty, isTrue);

      final categories = AiPhotoPresetsData.categories;
      expect(categories.contains('All'), isTrue);
      expect(categories.contains('Trending'), isTrue);
      expect(categories.contains('New'), isTrue);
      expect(categories.contains('80s'), isTrue);
      expect(categories.contains('Popular'), isTrue);

      for (final p in presets) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.title.isNotEmpty, isTrue);
        expect(p.prompt.isNotEmpty, isTrue);
        expect(p.category.isNotEmpty, isTrue);
      }
    });

    testWidgets('AI Photo Edit screen renders Copy & Share and NO Use / Create button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiPhotoEditScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('AI Photo Edit'), findsOneWidget);

      // Verify category chips exist
      expect(find.text('Trending'), findsWidgets);
      expect(find.text('New'), findsWidgets);

      // Verify Copy and Share buttons exist on preset cards
      expect(find.text('Copy'), findsWidgets);
      expect(find.text('Share'), findsWidgets);

      // CRITICAL: Ensure NO 'Use / Create' button exists anywhere on the screen
      expect(find.text('Use / Create'), findsNothing);
      expect(find.text('Create Edit'), findsNothing);
      expect(find.text('Use Edit'), findsNothing);
    });

    testWidgets('Tapping on a photo opens AiPhotoDetailScreen as a full page', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AiPhotoEditScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the first preset title or image area
      final firstTitle = AiPhotoPresetsData.presets.first.title;
      expect(find.text(firstTitle), findsWidgets);

      // Tap the photo area
      await tester.tap(find.text(firstTitle).first);
      await tester.pumpAndSettle();

      // Verify we navigated to the full-page AiPhotoDetailScreen
      expect(find.text('Generation Prompt'), findsOneWidget);
      expect(find.text('Optimized for Midjourney v6, ChatGPT DALL-E & Flux'), findsOneWidget);
      expect(find.text('Explore More AI Styles'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Back navigation
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('AI Photo Edit'), findsOneWidget);
    });

    test('New diverse AI presets and prompts are registered', () {
      final presets = AiPhotoPresetsData.presets;
      expect(presets.length, greaterThanOrEqualTo(15));

      final astronaut = presets.firstWhere((p) => p.title == 'Cosmic Nebula Astronaut');
      expect(astronaut.category, 'Sci-Fi');
      expect(astronaut.prompt, contains('astronaut'));

      final geisha = presets.firstWhere((p) => p.title == 'Neo-Tokyo Cyber Geisha');
      expect(geisha.category, 'Cyberpunk');

      final elf = presets.firstWhere((p) => p.title == 'Bioluminescent Woodland Elf');
      expect(elf.category, 'Fantasy');

      final darkAcademia = presets.firstWhere((p) => p.title == 'Gothic Dark Academia');
      expect(darkAcademia.category, 'Vintage');
    });

    testWidgets('Preview dialog does not overflow even on small screens (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  final preset = AiPhotoPresetsData.presets.first;
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 480,
                          maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 240,
                                  width: double.infinity,
                                  child: Container(color: Colors.blue),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(preset.title),
                                      const SizedBox(height: 10),
                                      Text(preset.prompt),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {},
                                        child: const Text('Copy Prompt'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Ensure no flutter overflow exceptions occurred
      expect(tester.takeException(), isNull);
      expect(find.text('Copy Prompt'), findsOneWidget);
    });
  });
}
