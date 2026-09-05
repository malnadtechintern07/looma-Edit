import 'package:flutter/material.dart';
import '../../features/editor/domain/entities/chroma_key_config_entity.dart';

/// High-performance GPU-accelerated Chroma Key Color Filter Engine.
/// Generates Skia/Impeller-compatible 4x5 ColorMatrix with real-time
/// tolerance/strength, edge feathering, and color spill suppression.
class ChromaKeyFilter {
  ChromaKeyFilter._();

  /// Builds a 20-element 4x5 ColorMatrix from the given [ChromaKeyConfigEntity].
  static List<double> createMatrix(ChromaKeyConfigEntity config) {
    if (!config.isEnabled) {
      return identityMatrix;
    }

    final keyHex = config.keyColorHex;
    final double kr = ((keyHex >> 16) & 0xFF) / 255.0;
    final double kg = ((keyHex >> 8) & 0xFF) / 255.0;
    final double kb = (keyHex & 0xFF) / 255.0;

    // Tolerance (0.0 to 1.0): sensitivity 0-100%
    final double tolerance = config.intensity.clamp(0.0, 1.0);
    // Feather (0.0 to 1.0): edge smoothness 0-100%
    final double feather = config.edgeSoftness.clamp(0.01, 1.0);
    // Spill (0.0 to 1.0): edge bounce desaturation 0-100%
    final double spill = config.spillSuppression.clamp(0.0, 1.0);

    // Dynamic threshold: at 0.5 (default), threshold is ~25 (keys all real-world green screens completely)
    // Higher tolerance lowers threshold to remove darker and desaturated green shades
    final double threshold = 70.0 * (1.0 - tolerance) - (tolerance * 25.0);

    // Steepness multiplier: higher = rapid drop to 0 alpha for complete transparency
    // Feather slightly relaxes steepness for soft edge anti-aliasing
    final double k = 14.0 + (1.0 - feather) * 16.0;

    double aR, aG, aB;
    // Row 4 offset: when delta <= threshold, A' >= 255 (opaque). When delta > threshold, A' drops below 0 (transparent).
    final double aOffset = k * threshold;

    // Color spill suppression rows
    double rR = 1.0, rG = 0.0, rB = 0.0;
    double gR = 0.0, gG = 1.0, gB = 0.0;
    double bR = 0.0, bG = 0.0, bB = 1.0;

    if (kg >= kr && kg >= kb && kg > 0.15) {
      // --- GREEN KEY ---
      // delta = G - (weightR * R + weightB * B)
      final double totalOpponent = (kr + kb);
      final double wR = totalOpponent > 0.05 ? (kr / totalOpponent).clamp(0.3, 0.7) : 0.5;
      final double wB = totalOpponent > 0.05 ? (kb / totalOpponent).clamp(0.3, 0.7) : 0.5;

      // A' = k * wR * R - k * G + k * wB * B + 1.0 * A + aOffset
      aR = k * wR;
      aG = -k;
      aB = k * wB;

      // Spill suppression: desaturate green bounce lighting towards ambient (R + B)/2
      gR = spill * 0.5;
      gG = 1.0 - spill;
      gB = spill * 0.5;
    } else if (kb >= kr && kb >= kg && kb > 0.15) {
      // --- BLUE KEY ---
      final double totalOpponent = (kr + kg);
      final double wR = totalOpponent > 0.05 ? (kr / totalOpponent).clamp(0.3, 0.7) : 0.5;
      final double wG = totalOpponent > 0.05 ? (kg / totalOpponent).clamp(0.3, 0.7) : 0.5;

      aR = k * wR;
      aG = k * wG;
      aB = -k;

      bR = spill * 0.5;
      bG = spill * 0.5;
      bB = 1.0 - spill;
    } else {
      // --- RED / MAGENTA KEY ---
      final double totalOpponent = (kg + kb);
      final double wG = totalOpponent > 0.05 ? (kg / totalOpponent).clamp(0.3, 0.7) : 0.5;
      final double wB = totalOpponent > 0.05 ? (kb / totalOpponent).clamp(0.3, 0.7) : 0.5;

      aR = -k;
      aG = k * wG;
      aB = k * wB;

      rR = 1.0 - spill;
      rG = spill * 0.5;
      rB = spill * 0.5;
    }

    return <double>[
      // Red row
      rR, rG, rB, 0.0, 0.0,
      // Green row
      gR, gG, gB, 0.0, 0.0,
      // Blue row
      bR, bG, bB, 0.0, 0.0,
      // Alpha row: A' = aR*R + aG*G + aB*B + 1.0*A + aOffset
      aR, aG, aB, 1.0, aOffset,
    ];
  }

  /// Wraps a widget with the GPU-accelerated Chroma Key ColorFiltered widget.
  static Widget apply({
    required Widget child,
    required ChromaKeyConfigEntity config,
  }) {
    if (!config.isEnabled) return child;
    final matrix = createMatrix(config);
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: child,
    );
  }

  static const List<double> identityMatrix = <double>[
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];
}
