import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/utils/font_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FontHelper Tests', () {
    test('All availableFonts resolve to valid TextStyle with fontFamily', () {
      expect(FontHelper.availableFonts.length, greaterThanOrEqualTo(48));

      for (final font in FontHelper.availableFonts) {
        final style = FontHelper.getTextStyle(font);
        expect(style.fontFamily, isNotNull, reason: 'Font $font should have fontFamily');
        expect(style.fontSize, equals(28.0));
      }
    });

    test('Single-weight fonts resolve gracefully without throwing', () {
      const singleWeightFonts = [
        'Pacifico',
        'Lobster',
        'Bungee',
        'Monoton',
        'Abril Fatface',
        'Bangers',
        'Titan One',
        'Permanent Marker',
        'Righteous',
        'Alfa Slab One',
        'Great Vibes',
        'Sacramento',
        'Shadows Into Light',
        'Indie Flower',
        'Press Start 2P',
        'VT323',
        'Russo One',
        'Archivo Black',
        'Kaushan Script',
      ];

      for (final font in singleWeightFonts) {
        final style = FontHelper.getTextStyle(font, fontWeight: FontWeight.bold);
        expect(style.fontFamily, isNotNull);
      }
    });

    test('Custom/unknown font gracefully falls back to TextStyle', () {
      final style = FontHelper.getTextStyle('NonExistentCustomFont123');
      expect(style.fontFamily, equals('NonExistentCustomFont123'));
      expect(style.fontFamilyFallback, contains('Inter'));
    });
  });
}
