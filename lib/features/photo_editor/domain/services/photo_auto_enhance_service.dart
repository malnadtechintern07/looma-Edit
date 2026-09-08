import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

enum AutoEnhancePreset {
  balanced,
  portrait,
  landscape,
  lowLight,
  crisp,
}

class AutoEnhanceMetrics {
  final double meanLuminance;
  final double dynamicRange;
  final double colorCast; // Positive = warm, negative = cool
  final double averageSaturation;

  const AutoEnhanceMetrics({
    required this.meanLuminance,
    required this.dynamicRange,
    required this.colorCast,
    required this.averageSaturation,
  });
}

class AutoEnhanceResult {
  final double brightness;
  final double contrast;
  final double exposure;
  final double highlights;
  final double shadows;
  final double saturation;
  final double vibrance;
  final double temperature;
  final double tint;
  final double sharpness;
  final AutoEnhanceMetrics metrics;
  final List<String> highlightsApplied;

  const AutoEnhanceResult({
    required this.brightness,
    required this.contrast,
    required this.exposure,
    required this.highlights,
    required this.shadows,
    required this.saturation,
    required this.vibrance,
    required this.temperature,
    required this.tint,
    required this.sharpness,
    required this.metrics,
    required this.highlightsApplied,
  });
}

class PhotoAutoEnhanceService {
  Future<img.Image?> loadImage(String path) async {
    try {
      Uint8List bytes;
      if (path.startsWith('assets/')) {
        final byteData = await rootBundle.load(path);
        bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      } else {
        final file = File(path);
        if (!file.existsSync()) return null;
        bytes = await file.readAsBytes();
      }
      return img.decodeImage(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Analyzes an image and returns optimal adjustments based on histogram & dynamic range
  Future<AutoEnhanceResult> analyzeAndComputeAdjustments({
    required String imagePath,
    AutoEnhancePreset preset = AutoEnhancePreset.balanced,
    double intensity = 1.0, // 0.0 to 2.0 (1.0 = 100% optimal)
  }) async {
    final image = await loadImage(imagePath);
    if (image == null) {
      return _defaultResult(preset, intensity);
    }

    return computeAdjustmentsFromImage(
      image: image,
      preset: preset,
      intensity: intensity,
    );
  }

  /// Core histogram and dynamic range analysis
  AutoEnhanceResult computeAdjustmentsFromImage({
    required img.Image image,
    AutoEnhancePreset preset = AutoEnhancePreset.balanced,
    double intensity = 1.0,
  }) {
    final w = image.width;
    final h = image.height;
    final step = max(1, (w * h) ~/ 15000); // Sample ~15,000 pixels for fast analysis

    final lumHist = Int32List(256);
    double sumR = 0, sumG = 0, sumB = 0, sumLum = 0;
    int totalSamples = 0;

    for (int y = 0; y < h; y += max(1, sqrt(step).round())) {
      for (int x = 0; x < w; x += max(1, sqrt(step).round())) {
        final p = image.getPixel(x, y);
        final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
        lumHist[lum]++;
        sumR += p.r;
        sumG += p.g;
        sumB += p.b;
        sumLum += lum;
        totalSamples++;
      }
    }

    if (totalSamples == 0) return _defaultResult(preset, intensity);

    final meanLum = sumLum / totalSamples;
    final avgR = sumR / totalSamples;
    final avgG = sumG / totalSamples;
    final avgB = sumB / totalSamples;

    // Percentiles for dynamic range
    int count = 0;
    int p1 = 0, p99 = 255;
    final p1Target = (totalSamples * 0.02).round();
    final p99Target = (totalSamples * 0.98).round();

    for (int i = 0; i < 256; i++) {
      count += lumHist[i];
      if (p1 == 0 && count >= p1Target) p1 = i;
      if (count >= p99Target) {
        p99 = i;
        break;
      }
    }

    final dynamicRange = (p99 - p1).toDouble();
    final colorCast = (avgR - avgB) / 255.0; // Warm = >0, Cool = <0
    final maxChannel = max(avgR, max(avgG, avgB));
    final minChannel = min(avgR, min(avgG, avgB));
    final avgSat = maxChannel > 0 ? (maxChannel - minChannel) / maxChannel : 0.0;

    final metrics = AutoEnhanceMetrics(
      meanLuminance: meanLum,
      dynamicRange: dynamicRange,
      colorCast: colorCast,
      averageSaturation: avgSat,
    );

    // Compute base corrections
    double bBright = 0.0;
    double bContrast = 1.0;
    double bExposure = 0.0;
    double bHighlights = 0.0;
    double bShadows = 0.0;
    double bSaturation = 1.0;
    double bVibrance = 0.0;
    double bTemp = 0.0;
    double bTint = 0.0;
    double bSharpness = 0.25;

    final appliedNotes = <String>[];

    // 1. Exposure & Brightness correction
    if (meanLum < 95.0) {
      final lift = ((95.0 - meanLum) / 95.0) * 0.35;
      bExposure += lift;
      bShadows += 0.30;
      appliedNotes.add('Shadows & Exposure lifted (+${(lift * 100).round()}%)');
    } else if (meanLum > 175.0) {
      final drop = ((meanLum - 175.0) / 80.0) * 0.25;
      bExposure -= drop;
      bHighlights -= 0.30;
      appliedNotes.add('Highlights tamed (-${(drop * 100).round()}%)');
    }

    // 2. Contrast correction
    if (dynamicRange < 150.0) {
      final contrastBoost = ((150.0 - dynamicRange) / 150.0) * 0.35;
      bContrast += contrastBoost;
      appliedNotes.add('Dynamic contrast expanded (+${(contrastBoost * 100).round()}%)');
    } else {
      bContrast += 0.08;
    }

    // 3. Shadow & Highlight recovery
    if (p1 < 10) {
      bShadows += 0.20; // Open deep shadows
    }
    if (p99 > 245) {
      bHighlights -= 0.25; // Protect blown highlights
    }

    // 4. Color & Vibrance
    if (avgSat < 0.25) {
      bVibrance += 0.30;
      bSaturation += 0.12;
      appliedNotes.add('Vibrance & Color boosted (+30%)');
    } else {
      bVibrance += 0.15;
    }

    // 5. White balance cast balancing
    if (colorCast.abs() > 0.12) {
      bTemp = -colorCast * 0.4;
      appliedNotes.add('Auto white balance normalized');
    }

    // Apply Preset modifiers
    switch (preset) {
      case AutoEnhancePreset.balanced:
        bSharpness = 0.25;
        break;
      case AutoEnhancePreset.portrait:
        bTemp += 0.08; // Flattering skin warmth
        bShadows += 0.15; // Soften facial shadows
        bContrast = min(bContrast, 1.12); // Keep skin soft
        bVibrance += 0.10;
        bSharpness = 0.15;
        appliedNotes.add('Portrait warmth & soft skin lighting');
        break;
      case AutoEnhancePreset.landscape:
        bContrast += 0.15;
        bVibrance += 0.35;
        bSaturation += 0.15;
        bHighlights -= 0.15;
        bSharpness = 0.45;
        appliedNotes.add('Sky & landscape clarity boost');
        break;
      case AutoEnhancePreset.lowLight:
        bExposure += 0.35;
        bShadows += 0.45;
        bContrast += 0.10;
        bSharpness = 0.20;
        appliedNotes.add('Low-light shadow recovery');
        break;
      case AutoEnhancePreset.crisp:
        bContrast += 0.25;
        bSharpness = 0.55;
        bVibrance += 0.15;
        appliedNotes.add('High definition & crisp detail');
        break;
    }

    // Scale by intensity slider (0.0 = original unedited, 1.0 = 100%, 2.0 = 200%)
    final k = intensity.clamp(0.0, 2.0);

    return AutoEnhanceResult(
      brightness: (bBright * k).clamp(-0.5, 0.5),
      contrast: (1.0 + (bContrast - 1.0) * k).clamp(0.5, 2.0),
      exposure: (bExposure * k).clamp(-1.0, 1.0),
      highlights: (bHighlights * k).clamp(-1.0, 1.0),
      shadows: (bShadows * k).clamp(-1.0, 1.0),
      saturation: (1.0 + (bSaturation - 1.0) * k).clamp(0.0, 2.0),
      vibrance: (bVibrance * k).clamp(-1.0, 1.0),
      temperature: (bTemp * k).clamp(-1.0, 1.0),
      tint: (bTint * k).clamp(-1.0, 1.0),
      sharpness: (bSharpness * k).clamp(0.0, 1.0),
      metrics: metrics,
      highlightsApplied: appliedNotes,
    );
  }

  AutoEnhanceResult _defaultResult(AutoEnhancePreset preset, double intensity) {
    return AutoEnhanceResult(
      brightness: 0.05 * intensity,
      contrast: 1.0 + 0.15 * intensity,
      exposure: 0.10 * intensity,
      highlights: -0.10 * intensity,
      shadows: 0.20 * intensity,
      saturation: 1.0 + 0.10 * intensity,
      vibrance: 0.20 * intensity,
      temperature: 0.0,
      tint: 0.0,
      sharpness: 0.25 * intensity,
      metrics: const AutoEnhanceMetrics(
        meanLuminance: 128.0,
        dynamicRange: 180.0,
        colorCast: 0.0,
        averageSaturation: 0.25,
      ),
      highlightsApplied: const ['Intelligent lighting & color tone balanced'],
    );
  }
}
