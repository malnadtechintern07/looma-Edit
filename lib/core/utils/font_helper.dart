import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontHelper {
  /// Curated collection of modern fonts supported out-of-the-box
  static const List<String> availableFonts = [
    'Inter',
    'Roboto',
    'Outfit',
    'Montserrat',
    'Poppins',
    'Bebas Neue',
    'Pacifico',
    'Playfair Display',
    'Dancing Script',
    'Caveat',
    'Anton',
    'Cinzel',
    'Lobster',
    'Oswald',
    'Raleway',
    'Satisfy',
    'Righteous',
    'Monoton',
    'Permanent Marker',
    'Space Mono',
    'Bangers',
    'Titan One',
    'Fredoka',
    'Comfortaa',
    'Abril Fatface',
  ];

  /// Normalized font lookup for GoogleFonts
  static String normalizeFontName(String fontName) {
    switch (fontName.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '')) {
      case 'inter':
        return 'Inter';
      case 'roboto':
        return 'Roboto';
      case 'outfit':
        return 'Outfit';
      case 'montserrat':
        return 'Montserrat';
      case 'poppins':
        return 'Poppins';
      case 'bebasneue':
        return 'Bebas Neue';
      case 'pacifico':
        return 'Pacifico';
      case 'playfairdisplay':
        return 'Playfair Display';
      case 'dancingscript':
        return 'Dancing Script';
      case 'caveat':
        return 'Caveat';
      case 'anton':
        return 'Anton';
      case 'cinzel':
        return 'Cinzel';
      case 'lobster':
        return 'Lobster';
      case 'oswald':
        return 'Oswald';
      case 'raleway':
        return 'Raleway';
      case 'satisfy':
        return 'Satisfy';
      case 'righteous':
        return 'Righteous';
      case 'monoton':
        return 'Monoton';
      case 'permanentmarker':
        return 'Permanent Marker';
      case 'spacemono':
        return 'Space Mono';
      case 'bangers':
        return 'Bangers';
      case 'titanone':
        return 'Titan One';
      case 'fredoka':
        return 'Fredoka';
      case 'comfortaa':
        return 'Comfortaa';
      case 'abrilfatface':
        return 'Abril Fatface';
      default:
        return fontName;
    }
  }

  /// Get TextStyle with dynamic GoogleFonts loading & safe fallbacks
  static TextStyle getTextStyle(
    String fontName, {
    double fontSize = 28.0,
    FontWeight fontWeight = FontWeight.bold,
    Color? color = Colors.white,
    List<Shadow>? shadows,
    Paint? foreground,
    double? letterSpacing,
    double? height,
  }) {
    final normalized = normalizeFontName(fontName);
    try {
      return GoogleFonts.getFont(
        normalized,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        shadows: shadows,
        foreground: foreground,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (_) {
      try {
        final compact = normalized.replaceAll(' ', '');
        return GoogleFonts.getFont(
          compact,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          shadows: shadows,
          foreground: foreground,
          letterSpacing: letterSpacing,
          height: height,
        );
      } catch (_) {
        return TextStyle(
          fontFamily: fontName,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          shadows: shadows,
          foreground: foreground,
          letterSpacing: letterSpacing,
          height: height,
        );
      }
    }
  }
}
