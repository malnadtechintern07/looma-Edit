import 'package:flutter/material.dart';

/// Centralized Color Palette for ProCut Video Editor & Design System
abstract class AppColors {
  // Light Backgrounds & Crisp Surfaces (From Reference UI)
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF3F4F8);
  static const Color surfaceBorder = Color(0xFFECEEF5);
  static const Color surfaceLight = Color(0xFFFAFAFC);

  // Editor Dark Workspace Colors
  static const Color darkWorkspace = Color(0xFF0D0E12);
  static const Color darkSurface = Color(0xFF16181F);
  static const Color darkBorder = Color(0xFF2E3240);

  // Brand Accents (Vibrant Royal Sapphire & Electric Cyan Palette from Reference UI)
  static const Color primary = Color(0xFF0D6EFD); // Vibrant Royal Sapphire Blue
  static const Color primaryDark = Color(0xFF0A58CA); // Deep Cobalt
  static const Color primaryLight = Color(0xFF2563EB); // Electric Blue

  static const Color secondary = Color(0xFF00C2CB); // Soft Electric Cyan
  static const Color secondaryLight = Color(0xFF38BDF8); // Sky Cyan

  static const List<Color> headerGradient = [
    Color(0xFF084298),
    Color(0xFF0D6EFD),
    Color(0xFF0284C7),
  ];

  static const Color accent = Color(0xFFFFB800); // Amber / Gold PRO Badge
  static const Color accentRose = Color(0xFFFF3B5C); // Coral Rose / Red
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Timeline Specific Colors
  static const Color videoTrack = Color(0xFF3B82F6);
  static const Color audioTrack = Color(0xFF10B981);
  static const Color voiceoverTrack = Color(0xFFEC4899);
  static const Color textTrack = Color(0xFFFFB800);
  static const Color stickerTrack = Color(0xFF5B4DFB);
  static const Color filterTrack = Color(0xFF00C2CB);

  static const Color playhead = Color(0xFFFF3B5C);
  static const Color timelineGrid = Color(0xFFE5E7EB);
  static const Color timelineRulerText = Color(0xFF6B7280);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  // Soft Elevation Shadows
  static const Color shadowColor = Color(0x0C000000);
  static const Color cardShadow = Color(0x140D6EFD);
}
