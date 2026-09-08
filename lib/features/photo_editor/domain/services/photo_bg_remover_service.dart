import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class BgRemovalResult {
  final String outputPath;
  final int width;
  final int height;

  const BgRemovalResult({
    required this.outputPath,
    required this.width,
    required this.height,
  });
}

class PhotoBgRemoverService {
  /// Loads an image from a local file path or flutter asset
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

  /// Removes background and generates transparent (or custom backdrop) PNG file.
  Future<BgRemovalResult?> removeBackground({
    required String imagePath,
    double sensitivity = 0.5, // 0.0 to 1.0 (higher = removes more)
    int featherRadius = 2, // 0 to 8 px edge softening
    img.Color? sampleColor, // Optional custom sampled background color
    img.Color? replacementColor, // Optional solid backdrop color (null = transparent)
  }) async {
    final image = await loadImage(imagePath);
    if (image == null) return null;

    final processed = processImageMatte(
      image: image,
      sensitivity: sensitivity,
      featherRadius: featherRadius,
      sampleColor: sampleColor,
      replacementColor: replacementColor,
    );

    // Save output PNG file
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'LOOMA_BG_REMOVED_${DateTime.now().millisecondsSinceEpoch}.png';
    final outputFile = File('${dir.path}/$fileName');
    final pngBytes = img.encodePng(processed);
    await outputFile.writeAsBytes(pngBytes);

    return BgRemovalResult(
      outputPath: outputFile.path,
      width: processed.width,
      height: processed.height,
    );
  }

  /// Generates a fast, low-latency preview image for UI sliders
  Uint8List? generatePreviewBytes({
    required img.Image original,
    double sensitivity = 0.5,
    int featherRadius = 2,
    img.Color? sampleColor,
    img.Color? replacementColor,
    int maxDimension = 512,
  }) {
    img.Image working = original;
    if (original.width > maxDimension || original.height > maxDimension) {
      working = img.copyResize(
        original,
        width: original.width > original.height ? maxDimension : null,
        height: original.height >= original.width ? maxDimension : null,
        interpolation: img.Interpolation.linear,
      );
    }

    final processed = processImageMatte(
      image: working,
      sensitivity: sensitivity,
      featherRadius: featherRadius,
      sampleColor: sampleColor,
      replacementColor: replacementColor,
    );

    return Uint8List.fromList(img.encodePng(processed));
  }

  /// Core pixel processing engine: builds background color model, computes distance,
  /// applies central prior, and softens edges.
  img.Image processImageMatte({
    required img.Image image,
    required double sensitivity,
    required int featherRadius,
    img.Color? sampleColor,
    img.Color? replacementColor,
  }) {
    final w = image.width;
    final h = image.height;

    // Convert to RGBA format if needed
    final output = img.Image(width: w, height: h, numChannels: 4);

    // 1. Determine background color reference(s)
    late final double bgR, bgG, bgB;
    if (sampleColor != null) {
      bgR = sampleColor.r.toDouble();
      bgG = sampleColor.g.toDouble();
      bgB = sampleColor.b.toDouble();
    } else {
      // Statistical sampling of borders (top, bottom, left, right edges)
      double sumR = 0, sumG = 0, sumB = 0;
      int count = 0;
      final stepX = max(1, w ~/ 40);
      final stepY = max(1, h ~/ 40);

      // Top and bottom borders
      for (int x = 0; x < w; x += stepX) {
        final pTop = image.getPixel(x, 0);
        final pBot = image.getPixel(x, h - 1);
        sumR += pTop.r + pBot.r;
        sumG += pTop.g + pBot.g;
        sumB += pTop.b + pBot.b;
        count += 2;
      }
      // Left and right borders
      for (int y = 0; y < h; y += stepY) {
        final pLeft = image.getPixel(0, y);
        final pRight = image.getPixel(w - 1, y);
        sumR += pLeft.r + pRight.r;
        sumG += pLeft.g + pRight.g;
        sumB += pLeft.b + pRight.b;
        count += 2;
      }

      bgR = sumR / max(1, count);
      bgG = sumG / max(1, count);
      bgB = sumB / max(1, count);
    }

    // Dynamic threshold based on sensitivity slider (0.0 to 1.0)
    // Distance in RGB space: 0 to ~441
    final threshold = 25.0 + (sensitivity * 160.0);
    final softRange = 35.0; // Transition ramp width for anti-aliasing

    final cx = w / 2.0;
    final cy = h / 2.0;
    final maxDistFromCenter = sqrt(cx * cx + cy * cy);

    // Initial alpha map buffer
    final alphaMap = Uint8List(w * h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        final pr = p.r.toDouble();
        final pg = p.g.toDouble();
        final pb = p.b.toDouble();

        // Color distance in weighted RGB (perceptual weights)
        final dr = pr - bgR;
        final dg = pg - bgG;
        final db = pb - bgB;
        final dist = sqrt(0.299 * dr * dr + 0.587 * dg * dg + 0.114 * db * db);

        // Subject centrality prior (closer to center slightly boosts foreground retention)
        final dx = (x - cx);
        final dy = (y - cy);
        final distCenterRatio = sqrt(dx * dx + dy * dy) / maxDistFromCenter;
        final centerBias = (1.0 - distCenterRatio) * 15.0;

        final effectiveDist = dist + centerBias;

        int alpha;
        if (effectiveDist <= threshold) {
          alpha = 0; // Transparent background
        } else if (effectiveDist >= threshold + softRange) {
          alpha = 255; // Solid foreground subject
        } else {
          final t = (effectiveDist - threshold) / softRange;
          alpha = (t * 255).clamp(0, 255).toInt();
        }

        alphaMap[y * w + x] = alpha;
      }
    }

    // 2. Optional edge smoothing / feathering
    final refinedAlpha = featherRadius > 0 ? _featherAlpha(alphaMap, w, h, featherRadius) : alphaMap;

    // 3. Construct output image
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        final alpha = refinedAlpha[y * w + x];

        if (replacementColor != null) {
          // Composite over solid color
          final fgA = alpha / 255.0;
          final bgA = 1.0 - fgA;
          final outR = (p.r * fgA + replacementColor.r * bgA).round();
          final outG = (p.g * fgA + replacementColor.g * bgA).round();
          final outB = (p.b * fgA + replacementColor.b * bgA).round();
          output.setPixelRgba(x, y, outR, outG, outB, 255);
        } else {
          // Transparent PNG
          output.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
        }
      }
    }

    return output;
  }

  /// Fast box-blur on the alpha mask for silky-smooth feathered edges
  Uint8List _featherAlpha(Uint8List alpha, int w, int h, int radius) {
    final result = Uint8List(w * h);
    final r = radius.clamp(1, 6);
    final kernelSize = 2 * r + 1;

    // Horizontal pass
    final temp = Float32List(w * h);
    for (int y = 0; y < h; y++) {
      int sum = 0;
      for (int i = -r; i <= r; i++) {
        final px = i.clamp(0, w - 1);
        sum += alpha[y * w + px];
      }
      temp[y * w + 0] = sum / kernelSize;

      for (int x = 1; x < w; x++) {
        final addX = (x + r).clamp(0, w - 1);
        final remX = (x - r - 1).clamp(0, w - 1);
        sum += alpha[y * w + addX] - alpha[y * w + remX];
        temp[y * w + x] = sum / kernelSize;
      }
    }

    // Vertical pass
    for (int x = 0; x < w; x++) {
      double sum = 0;
      for (int j = -r; j <= r; j++) {
        final py = j.clamp(0, h - 1);
        sum += temp[py * w + x];
      }
      result[0 * w + x] = sum.clamp(0, 255).toInt();

      for (int y = 1; y < h; y++) {
        final addY = (y + r).clamp(0, h - 1);
        final remY = (y - r - 1).clamp(0, h - 1);
        sum += temp[addY * w + x] - temp[remY * w + x];
        result[y * w + x] = (sum / kernelSize).clamp(0, 255).toInt();
      }
    }

    return result;
  }
}
