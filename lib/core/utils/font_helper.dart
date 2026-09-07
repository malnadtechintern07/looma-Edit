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
    'Lato',
    'Merriweather',
    'Nunito',
    'Rubik',
    'Syne',
    'Urbanist',
    'DM Sans',
    'Work Sans',
    'Lora',
    'Cormorant Garamond',
    'Great Vibes',
    'Sacramento',
    'Shadows Into Light',
    'Indie Flower',
    'Orbitron',
    'Press Start 2P',
    'VT323',
    'Russo One',
    'Archivo Black',
    'Fjalla One',
    'Alfa Slab One',
    'Bungee',
    'Kaushan Script',
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
      case 'lato':
        return 'Lato';
      case 'merriweather':
        return 'Merriweather';
      case 'nunito':
        return 'Nunito';
      case 'rubik':
        return 'Rubik';
      case 'syne':
        return 'Syne';
      case 'urbanist':
        return 'Urbanist';
      case 'dmsans':
        return 'DM Sans';
      case 'worksans':
        return 'Work Sans';
      case 'lora':
        return 'Lora';
      case 'cormorantgaramond':
        return 'Cormorant Garamond';
      case 'greatvibes':
        return 'Great Vibes';
      case 'sacramento':
        return 'Sacramento';
      case 'shadowsintolight':
        return 'Shadows Into Light';
      case 'indieflower':
        return 'Indie Flower';
      case 'orbitron':
        return 'Orbitron';
      case 'pressstart2p':
        return 'Press Start 2P';
      case 'vt323':
        return 'VT323';
      case 'russoone':
        return 'Russo One';
      case 'archivoblack':
        return 'Archivo Black';
      case 'fjallaone':
        return 'Fjalla One';
      case 'alfaslabone':
        return 'Alfa Slab One';
      case 'bungee':
        return 'Bungee';
      case 'kaushanscript':
        return 'Kaushan Script';
      default:
        return fontName;
    }
  }

  /// Direct static dispatch to GoogleFonts methods for maximum speed and rock-solid reliability
  static TextStyle _resolveGoogleFont(
    String normalized, {
    double fontSize = 28.0,
    FontWeight? fontWeight,
    Color? color = Colors.white,
    List<Shadow>? shadows,
    Paint? foreground,
    double? letterSpacing,
    double? height,
  }) {
    switch (normalized) {
      case 'Inter':
        return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Roboto':
        return GoogleFonts.roboto(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Outfit':
        return GoogleFonts.outfit(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Montserrat':
        return GoogleFonts.montserrat(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Poppins':
        return GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Bebas Neue':
        return GoogleFonts.bebasNeue(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Pacifico':
        return GoogleFonts.pacifico(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Dancing Script':
        return GoogleFonts.dancingScript(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Caveat':
        return GoogleFonts.caveat(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Anton':
        return GoogleFonts.anton(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Cinzel':
        return GoogleFonts.cinzel(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Lobster':
        return GoogleFonts.lobster(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Oswald':
        return GoogleFonts.oswald(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Raleway':
        return GoogleFonts.raleway(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Satisfy':
        return GoogleFonts.satisfy(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Righteous':
        return GoogleFonts.righteous(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Monoton':
        return GoogleFonts.monoton(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Permanent Marker':
        return GoogleFonts.permanentMarker(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Space Mono':
        return GoogleFonts.spaceMono(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Bangers':
        return GoogleFonts.bangers(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Titan One':
        return GoogleFonts.titanOne(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Fredoka':
        return GoogleFonts.fredoka(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Comfortaa':
        return GoogleFonts.comfortaa(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Abril Fatface':
        return GoogleFonts.abrilFatface(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Lato':
        return GoogleFonts.lato(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Merriweather':
        return GoogleFonts.merriweather(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Nunito':
        return GoogleFonts.nunito(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Rubik':
        return GoogleFonts.rubik(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Syne':
        return GoogleFonts.syne(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Urbanist':
        return GoogleFonts.urbanist(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'DM Sans':
        return GoogleFonts.dmSans(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Work Sans':
        return GoogleFonts.workSans(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Lora':
        return GoogleFonts.lora(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Cormorant Garamond':
        return GoogleFonts.cormorantGaramond(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Great Vibes':
        return GoogleFonts.greatVibes(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Sacramento':
        return GoogleFonts.sacramento(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Shadows Into Light':
        return GoogleFonts.shadowsIntoLight(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Indie Flower':
        return GoogleFonts.indieFlower(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Orbitron':
        return GoogleFonts.orbitron(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Press Start 2P':
        return GoogleFonts.pressStart2p(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'VT323':
        return GoogleFonts.vt323(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Russo One':
        return GoogleFonts.russoOne(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Archivo Black':
        return GoogleFonts.archivoBlack(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Fjalla One':
        return GoogleFonts.fjallaOne(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Alfa Slab One':
        return GoogleFonts.alfaSlabOne(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Bungee':
        return GoogleFonts.bungee(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      case 'Kaushan Script':
        return GoogleFonts.kaushanScript(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: shadows, foreground: foreground, letterSpacing: letterSpacing, height: height);
      default:
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

    // 1. Primary resolution using direct statically-typed GoogleFonts dispatches
    try {
      return _resolveGoogleFont(
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
      // 2. Single-weight fallback: Some display/script Google Fonts don't have bold variants.
      // Retry without fontWeight constraint so their unique typeface displays cleanly.
      try {
        return _resolveGoogleFont(
          normalized,
          fontSize: fontSize,
          color: color,
          shadows: shadows,
          foreground: foreground,
          letterSpacing: letterSpacing,
          height: height,
        );
      } catch (_) {
        // 3. Try with compact font name (e.g. without spaces)
        try {
          final compact = normalized.replaceAll(' ', '');
          return GoogleFonts.getFont(
            compact,
            fontSize: fontSize,
            color: color,
            shadows: shadows,
            foreground: foreground,
            letterSpacing: letterSpacing,
            height: height,
          );
        } catch (_) {
          // 4. Safe fallback to local font family or standard fallback typography stack
          return TextStyle(
            fontFamily: fontName,
            fontFamilyFallback: const ['Inter', 'Roboto', 'sans-serif'],
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

  /// Warm up and preload popular Google Fonts asynchronously in the background
  static void preloadPopularFonts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final font in availableFonts.take(15)) {
        getTextStyle(font, fontSize: 12);
      }
    });
  }
}
