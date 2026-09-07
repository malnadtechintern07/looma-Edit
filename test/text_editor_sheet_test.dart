import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/features/text_stickers/domain/entities/overlay_animation_type.dart';
import 'package:looma/features/text_stickers/domain/entities/text_overlay_entity.dart';
import 'package:looma/features/text_stickers/presentation/widgets/text_editor_sheet.dart';

void main() {
  testWidgets('TextEditorSheet renders three main buttons in one line across top and switches tabs', (tester) async {
    String? savedText;
    String? savedFont;
    double? savedSize;
    int? savedColor;
    int? savedBg;
    OverlayAnimationType? savedAnim;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextEditorSheet(
            initialText: const TextOverlayEntity(
              id: 'text_1',
              text: 'CINEMATIC VLOG',
              fontFamily: 'Inter',
              fontSize: 32.0,
              colorHex: 0xFFFFFFFF,
              timelineStartMs: 0,
              timelineEndMs: 5000,
            ),
            onSave: ({
              required text,
              required fontFamily,
              required fontSize,
              required colorHex,
              backgroundColorHex,
              required animationType,
            }) {
              savedText = text;
              savedFont = fontFamily;
              savedSize = fontSize;
              savedColor = colorHex;
              savedBg = backgroundColorHex;
              savedAnim = animationType;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify the three main buttons in one line are present
    final fontTabFinder = find.byKey(const Key('text_font_tab_btn'));
    final animTabFinder = find.byKey(const Key('text_anim_tab_btn'));
    final colorTabFinder = find.byKey(const Key('text_color_tab_btn'));

    expect(fontTabFinder, findsOneWidget);
    expect(animTabFinder, findsOneWidget);
    expect(colorTabFinder, findsOneWidget);

    expect(find.text('Text Font'), findsOneWidget);
    expect(find.text('Text Animation'), findsOneWidget);
    expect(find.text('Text Color'), findsOneWidget);

    // Verify they are laid out horizontally in a single Row
    final fontTop = tester.getTopLeft(fontTabFinder).dy;
    final animTop = tester.getTopLeft(animTabFinder).dy;
    final colorTop = tester.getTopLeft(colorTabFinder).dy;
    expect(fontTop, equals(animTop));
    expect(animTop, equals(colorTop));

    // 2. Default tab is Text Font: verify font controls are visible
    expect(find.byKey(const ValueKey('tab_view_font')), findsOneWidget);
    expect(find.textContaining('Typography Font'), findsOneWidget);
    expect(find.text('Font Size'), findsOneWidget);

    // 3. Tap on Text Animation tab
    await tester.tap(animTabFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tab_view_animation')), findsOneWidget);
    expect(find.text('Entry Animation Preset'), findsOneWidget);
    expect(find.text('Fade In'), findsOneWidget);
    expect(find.text('Typewriter'), findsOneWidget);
    expect(find.text('Bounce'), findsOneWidget);

    // Select 'Typewriter' animation
    await tester.tap(find.text('Typewriter'));
    await tester.pumpAndSettle();

    // 4. Tap on Text Color tab
    await tester.tap(colorTabFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tab_view_color')), findsOneWidget);
    expect(find.text('Text Font Color'), findsOneWidget);
    expect(find.text('Text Background Highlight'), findsOneWidget);

    // Toggle background highlight
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Highlight Box Color'), findsOneWidget);

    // 5. Scroll and tap Update Overlay button
    final updateBtnFinder = find.text('Update Overlay');
    await tester.ensureVisible(updateBtnFinder);
    await tester.tap(updateBtnFinder);
    await tester.pumpAndSettle();

    expect(savedText, equals('CINEMATIC VLOG'));
    expect(savedFont, equals('Inter'));
    expect(savedSize, equals(32.0));
    expect(savedColor, equals(0xFFFFFFFF));
    expect(savedAnim, equals(OverlayAnimationType.typewriter));
    expect(savedBg, isNotNull);
  });

  testWidgets('TextEditorSheet supports vertical font filtering, expanded animation presets, and colors', (tester) async {
    String? savedFont;
    OverlayAnimationType? savedAnim;
    int? savedColor;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextEditorSheet(
            initialText: const TextOverlayEntity(
              id: 'text_2',
              text: 'SUMMER VIBES',
              fontFamily: 'Inter',
              fontSize: 28.0,
              colorHex: 0xFFFFFFFF,
              timelineStartMs: 0,
              timelineEndMs: 4000,
            ),
            onSave: ({
              required text,
              required fontFamily,
              required fontSize,
              required colorHex,
              backgroundColorHex,
              required animationType,
            }) {
              savedFont = fontFamily;
              savedAnim = animationType;
              savedColor = colorHex;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify font search input filters fonts in vertical gallery
    final searchInput = find.byKey(const Key('font_search_input'));
    await tester.enterText(searchInput, 'Montserrat');
    await tester.pumpAndSettle();

    final montserratCard = find.byKey(const Key('font_card_Montserrat'));
    expect(montserratCard, findsOneWidget);
    await tester.tap(montserratCard);
    await tester.pumpAndSettle();

    // 2. Switch to Animation tab and select one of the new animation presets
    await tester.tap(find.byKey(const Key('text_anim_tab_btn')));
    await tester.pumpAndSettle();

    final zoomInCard = find.byKey(const Key('anim_card_zoomIn'));
    expect(zoomInCard, findsOneWidget);
    expect(find.text('Neon Pulse'), findsOneWidget);

    await tester.tap(zoomInCard);
    await tester.pumpAndSettle();

    // 3. Switch to Color tab and verify expanded palette
    await tester.tap(find.byKey(const Key('text_color_tab_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Text Font Color'), findsOneWidget);

    // Tap Update Overlay
    final updateBtn = find.text('Update Overlay');
    await tester.ensureVisible(updateBtn);
    await tester.tap(updateBtn);
    await tester.pumpAndSettle();

    expect(savedFont, equals('Montserrat'));
    expect(savedAnim, equals(OverlayAnimationType.zoomIn));
    expect(savedColor, equals(0xFFFFFFFF));
  });
}
