import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart' show Offset;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

enum RetouchMode {
  blemish, // Patch-based inpainting / acne & spot removal
  smooth, // Bilateral edge-preserving skin softening
  brighten, // Dodge / teeth whitening & eye sparkle
  darken, // Burn / contouring & shadow sculpting
}

class RetouchStroke {
  final RetouchMode mode;
  final List<Offset> points; // Normalized coordinates (0.0 to 1.0)
  final double radius; // Normalized radius relative to image width
  final double intensity; // 0.0 to 1.0

  const RetouchStroke({
    required this.mode,
    required this.points,
    required this.radius,
    this.intensity = 0.5,
  });
}

class RetouchResult {
  final String outputPath;
  final int width;
  final int height;

  const RetouchResult({
    required this.outputPath,
    required this.width,
    required this.height,
  });
}

class PhotoRetouchService {
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

  /// Applies retouch strokes to the image and writes the new file
  Future<RetouchResult?> applyRetouch({
    required String imagePath,
    required List<RetouchStroke> strokes,
  }) async {
    final image = await loadImage(imagePath);
    if (image == null) return null;

    final output = img.Image.from(image);
    for (final stroke in strokes) {
      applyStrokeToImage(image: output, stroke: stroke);
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'LOOMA_RETOUCH_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(img.encodePng(output));

    return RetouchResult(
      outputPath: file.path,
      width: output.width,
      height: output.height,
    );
  }

  /// Renders a fast preview with all strokes applied
  Uint8List? generatePreviewBytes({
    required img.Image original,
    required List<RetouchStroke> strokes,
    int maxDimension = 720,
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

    final output = img.Image.from(working);
    for (final stroke in strokes) {
      applyStrokeToImage(image: output, stroke: stroke);
    }

    return Uint8List.fromList(img.encodePng(output));
  }

  /// Executes retouching on image buffer
  void applyStrokeToImage({
    required img.Image image,
    required RetouchStroke stroke,
  }) {
    switch (stroke.mode) {
      case RetouchMode.blemish:
        _applyBlemishRemoval(image, stroke);
        break;
      case RetouchMode.smooth:
        _applySkinSmoothing(image, stroke);
        break;
      case RetouchMode.brighten:
        _applyBrighten(image, stroke);
        break;
      case RetouchMode.darken:
        _applyDarken(image, stroke);
        break;
    }
  }

  /// Inpainting: Replaces blemish area with interpolated texture from surrounding ring
  void _applyBlemishRemoval(img.Image image, RetouchStroke stroke) {
    final w = image.width;
    final h = image.height;
    final radPx = (stroke.radius * w).clamp(3.0, 80.0);
    final radSq = radPx * radPx;
    final outerRadPx = radPx * 1.6;
    final outerRadSq = outerRadPx * outerRadPx;

    for (final pt in stroke.points) {
      final cx = (pt.dx * w).round();
      final cy = (pt.dy * h).round();

      // Sample healthy donor pixels in the outer ring [radPx, outerRadPx]
      double donorR = 0, donorG = 0, donorB = 0;
      int donorCount = 0;

      final minOuterX = max(0, (cx - outerRadPx).floor());
      final maxOuterX = min(w - 1, (cx + outerRadPx).ceil());
      final minOuterY = max(0, (cy - outerRadPx).floor());
      final maxOuterY = min(h - 1, (cy + outerRadPx).ceil());

      for (int y = minOuterY; y <= maxOuterY; y++) {
        final dy = y - cy;
        for (int x = minOuterX; x <= maxOuterX; x++) {
          final dx = x - cx;
          final dSq = dx * dx + dy * dy;
          if (dSq > radSq && dSq <= outerRadSq) {
            final p = image.getPixel(x, y);
            donorR += p.r;
            donorG += p.g;
            donorB += p.b;
            donorCount++;
          }
        }
      }

      if (donorCount == 0) continue;
      final avgR = donorR / donorCount;
      final avgG = donorG / donorCount;
      final avgB = donorB / donorCount;

      // Inpaint blemish disk with Gaussian blend towards donor mean
      final minX = max(0, (cx - radPx).floor());
      final maxX = min(w - 1, (cx + radPx).ceil());
      final minY = max(0, (cy - radPx).floor());
      final maxY = min(h - 1, (cy + radPx).ceil());

      for (int y = minY; y <= maxY; y++) {
        final dy = y - cy;
        for (int x = minX; x <= maxX; x++) {
          final dx = x - cx;
          final dSq = dx * dx + dy * dy;
          if (dSq <= radSq) {
            final p = image.getPixel(x, y);
            // Weight falls off towards edges so blend is seamless
            final dist = sqrt(dSq) / radPx;
            final weight = (cos(dist * pi) + 1.0) / 2.0; // Smooth cosine curve
            final blend = weight * stroke.intensity.clamp(0.2, 1.0);

            final newR = (p.r * (1.0 - blend) + avgR * blend).round();
            final newG = (p.g * (1.0 - blend) + avgG * blend).round();
            final newB = (p.b * (1.0 - blend) + avgB * blend).round();

            image.setPixelRgba(x, y, newR, newG, newB, p.a);
          }
        }
      }
    }
  }

  /// Edge-preserving bilateral skin softening
  void _applySkinSmoothing(img.Image image, RetouchStroke stroke) {
    final w = image.width;
    final h = image.height;
    final radPx = (stroke.radius * w).clamp(4.0, 70.0);
    final radSq = radPx * radPx;

    final filterR = max(1, (radPx * 0.35).round().clamp(1, 6));

    for (final pt in stroke.points) {
      final cx = (pt.dx * w).round();
      final cy = (pt.dy * h).round();

      final minX = max(0, (cx - radPx).floor());
      final maxX = min(w - 1, (cx + radPx).ceil());
      final minY = max(0, (cy - radPx).floor());
      final maxY = min(h - 1, (cy + radPx).ceil());

      for (int y = minY; y <= maxY; y++) {
        final dy = y - cy;
        for (int x = minX; x <= maxX; x++) {
          final dx = x - cx;
          final dSq = dx * dx + dy * dy;
          if (dSq <= radSq) {
            final centerP = image.getPixel(x, y);
            final centerLum = 0.299 * centerP.r + 0.587 * centerP.g + 0.114 * centerP.b;

            // Compute bilateral neighborhood weight (spatial + intensity similarity)
            double sumR = 0, sumG = 0, sumB = 0, totalWeight = 0;

            for (int fy = -filterR; fy <= filterR; fy++) {
              final ny = (y + fy).clamp(0, h - 1);
              for (int fx = -filterR; fx <= filterR; fx++) {
                final nx = (x + fx).clamp(0, w - 1);
                final np = image.getPixel(nx, ny);
                final nLum = 0.299 * np.r + 0.587 * np.g + 0.114 * np.b;

                // Edge preservation: only smooth pixels with similar luminance
                final lumDiff = (centerLum - nLum).abs();
                final spatialDistSq = (fx * fx + fy * fy) / (filterR * filterR);
                if (lumDiff < 45.0) {
                  final spatialWeight = exp(-spatialDistSq);
                  final rangeWeight = exp(-lumDiff / 20.0);
                  final weight = spatialWeight * rangeWeight;

                  sumR += np.r * weight;
                  sumG += np.g * weight;
                  sumB += np.b * weight;
                  totalWeight += weight;
                }
              }
            }

            if (totalWeight > 0.01) {
              final smoothR = sumR / totalWeight;
              final smoothG = sumG / totalWeight;
              final smoothB = sumB / totalWeight;

              final brushFalloff = (1.0 - (sqrt(dSq) / radPx)).clamp(0.0, 1.0);
              final blend = brushFalloff * stroke.intensity.clamp(0.1, 1.0);

              final newR = (centerP.r * (1.0 - blend) + smoothR * blend).round();
              final newG = (centerP.g * (1.0 - blend) + smoothG * blend).round();
              final newB = (centerP.b * (1.0 - blend) + smoothB * blend).round();

              image.setPixelRgba(x, y, newR, newG, newB, centerP.a);
            }
          }
        }
      }
    }
  }

  /// Dodge / Brighten tool
  void _applyBrighten(img.Image image, RetouchStroke stroke) {
    final w = image.width;
    final h = image.height;
    final radPx = (stroke.radius * w).clamp(3.0, 70.0);
    final radSq = radPx * radPx;

    for (final pt in stroke.points) {
      final cx = (pt.dx * w).round();
      final cy = (pt.dy * h).round();

      final minX = max(0, (cx - radPx).floor());
      final maxX = min(w - 1, (cx + radPx).ceil());
      final minY = max(0, (cy - radPx).floor());
      final maxY = min(h - 1, (cy + radPx).ceil());

      for (int y = minY; y <= maxY; y++) {
        final dy = y - cy;
        for (int x = minX; x <= maxX; x++) {
          final dx = x - cx;
          final dSq = dx * dx + dy * dy;
          if (dSq <= radSq) {
            final p = image.getPixel(x, y);
            final falloff = (1.0 - sqrt(dSq) / radPx).clamp(0.0, 1.0);
            final factor = falloff * stroke.intensity * 0.45;

            final newR = (p.r + (255 - p.r) * factor).round().clamp(0, 255);
            final newG = (p.g + (255 - p.g) * factor).round().clamp(0, 255);
            final newB = (p.b + (255 - p.b) * factor).round().clamp(0, 255);

            image.setPixelRgba(x, y, newR, newG, newB, p.a);
          }
        }
      }
    }
  }

  /// Burn / Darken tool
  void _applyDarken(img.Image image, RetouchStroke stroke) {
    final w = image.width;
    final h = image.height;
    final radPx = (stroke.radius * w).clamp(3.0, 70.0);
    final radSq = radPx * radPx;

    for (final pt in stroke.points) {
      final cx = (pt.dx * w).round();
      final cy = (pt.dy * h).round();

      final minX = max(0, (cx - radPx).floor());
      final maxX = min(w - 1, (cx + radPx).ceil());
      final minY = max(0, (cy - radPx).floor());
      final maxY = min(h - 1, (cy + radPx).ceil());

      for (int y = minY; y <= maxY; y++) {
        final dy = y - cy;
        for (int x = minX; x <= maxX; x++) {
          final dx = x - cx;
          final dSq = dx * dx + dy * dy;
          if (dSq <= radSq) {
            final p = image.getPixel(x, y);
            final falloff = (1.0 - sqrt(dSq) / radPx).clamp(0.0, 1.0);
            final factor = falloff * stroke.intensity * 0.45;

            final newR = (p.r * (1.0 - factor)).round().clamp(0, 255);
            final newG = (p.g * (1.0 - factor)).round().clamp(0, 255);
            final newB = (p.b * (1.0 - factor)).round().clamp(0, 255);

            image.setPixelRgba(x, y, newR, newG, newB, p.a);
          }
        }
      }
    }
  }
}
