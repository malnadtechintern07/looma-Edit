import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart' show Offset;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CutoutStroke {
  final List<Offset> points; // Normalized coordinates (0.0 to 1.0) or canvas pixels
  final bool isErase; // true = erase background, false = restore foreground
  final double radius; // Radius in normalized percentage of image width

  const CutoutStroke({
    required this.points,
    required this.isErase,
    required this.radius,
  });
}

class AutoCutResult {
  final String outputPath;
  final int width;
  final int height;

  const AutoCutResult({
    required this.outputPath,
    required this.width,
    required this.height,
  });
}

class PhotoAutoCutService {
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

  /// Generates initial automatic cutout mask
  Uint8List generateInitialMask(img.Image image) {
    final w = image.width;
    final h = image.height;
    final mask = Uint8List(w * h);

    // Sample background from borders
    double bgR = 0, bgG = 0, bgB = 0;
    int count = 0;
    final stepX = max(1, w ~/ 30);
    final stepY = max(1, h ~/ 30);

    for (int x = 0; x < w; x += stepX) {
      final p1 = image.getPixel(x, 0);
      final p2 = image.getPixel(x, h - 1);
      bgR += p1.r + p2.r;
      bgG += p1.g + p2.g;
      bgB += p1.b + p2.b;
      count += 2;
    }
    for (int y = 0; y < h; y += stepY) {
      final p1 = image.getPixel(0, y);
      final p2 = image.getPixel(w - 1, y);
      bgR += p1.r + p2.r;
      bgG += p1.g + p2.g;
      bgB += p1.b + p2.b;
      count += 2;
    }
    bgR /= max(1, count);
    bgG /= max(1, count);
    bgB /= max(1, count);

    final cx = w / 2.0;
    final cy = h / 2.0;
    final maxDist = sqrt(cx * cx + cy * cy);
    const threshold = 55.0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        final dr = p.r - bgR;
        final dg = p.g - bgG;
        final db = p.b - bgB;
        final dist = sqrt(0.299 * dr * dr + 0.587 * dg * dg + 0.114 * db * db);

        final dx = x - cx;
        final dy = y - cy;
        final centerRatio = sqrt(dx * dx + dy * dy) / maxDist;
        final effectiveDist = dist + (1.0 - centerRatio) * 20.0;

        mask[y * w + x] = effectiveDist > threshold ? 255 : 0;
      }
    }

    return mask;
  }

  /// Applies manual refinement strokes (Erase and Restore) to the mask
  void applyStrokesToMask({
    required Uint8List mask,
    required int width,
    required int height,
    required List<CutoutStroke> strokes,
  }) {
    for (final stroke in strokes) {
      final val = stroke.isErase ? 0 : 255;
      final radPx = (stroke.radius * width).clamp(2.0, 100.0);
      final radSq = radPx * radPx;

      for (final pt in stroke.points) {
        final px = (pt.dx * width).round();
        final py = (pt.dy * height).round();

        final minX = max(0, (px - radPx).floor());
        final maxX = min(width - 1, (px + radPx).ceil());
        final minY = max(0, (py - radPx).floor());
        final maxY = min(height - 1, (py + radPx).ceil());

        for (int y = minY; y <= maxY; y++) {
          final dy = y - py;
          for (int x = minX; x <= maxX; x++) {
            final dx = x - px;
            if (dx * dx + dy * dy <= radSq) {
              mask[y * width + x] = val;
            }
          }
        }
      }
    }
  }

  /// Produces the final cut out transparent image
  Future<AutoCutResult?> renderCutout({
    required String imagePath,
    required List<CutoutStroke> strokes,
    bool invert = false,
    int featherRadius = 2,
  }) async {
    final image = await loadImage(imagePath);
    if (image == null) return null;

    final w = image.width;
    final h = image.height;
    final mask = generateInitialMask(image);

    // Apply manual user brush refinements
    applyStrokesToMask(mask: mask, width: w, height: h, strokes: strokes);

    if (invert) {
      for (int i = 0; i < mask.length; i++) {
        mask[i] = 255 - mask[i];
      }
    }

    // Feather edges for clean silhouette
    final refined = featherRadius > 0 ? _featherMask(mask, w, h, featherRadius) : mask;

    final output = img.Image(width: w, height: h, numChannels: 4);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        final a = refined[y * w + x];
        output.setPixelRgba(x, y, p.r, p.g, p.b, a);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'PROCUT_AUTOCUT_${DateTime.now().millisecondsSinceEpoch}.png';
    final outputFile = File('${dir.path}/$fileName');
    await outputFile.writeAsBytes(img.encodePng(output));

    return AutoCutResult(
      outputPath: outputFile.path,
      width: w,
      height: h,
    );
  }

  /// Fast preview generator for the cutout refinement sheet
  Uint8List? generatePreviewBytes({
    required img.Image original,
    required List<CutoutStroke> strokes,
    bool invert = false,
    int featherRadius = 1,
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

    final w = working.width;
    final h = working.height;
    final mask = generateInitialMask(working);
    applyStrokesToMask(mask: mask, width: w, height: h, strokes: strokes);

    if (invert) {
      for (int i = 0; i < mask.length; i++) {
        mask[i] = 255 - mask[i];
      }
    }

    final refined = featherRadius > 0 ? _featherMask(mask, w, h, featherRadius) : mask;
    final output = img.Image(width: w, height: h, numChannels: 4);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = working.getPixel(x, y);
        final a = refined[y * w + x];
        output.setPixelRgba(x, y, p.r, p.g, p.b, a);
      }
    }

    return Uint8List.fromList(img.encodePng(output));
  }

  Uint8List _featherMask(Uint8List mask, int w, int h, int radius) {
    final result = Uint8List(w * h);
    final r = radius.clamp(1, 4);
    final kernel = 2 * r + 1;

    final temp = Float32List(w * h);
    for (int y = 0; y < h; y++) {
      int sum = 0;
      for (int i = -r; i <= r; i++) {
        sum += mask[y * w + i.clamp(0, w - 1)];
      }
      temp[y * w + 0] = sum / kernel;

      for (int x = 1; x < w; x++) {
        sum += mask[y * w + (x + r).clamp(0, w - 1)] - mask[y * w + (x - r - 1).clamp(0, w - 1)];
        temp[y * w + x] = sum / kernel;
      }
    }

    for (int x = 0; x < w; x++) {
      double sum = 0;
      for (int j = -r; j <= r; j++) {
        sum += temp[j.clamp(0, h - 1) * w + x];
      }
      result[0 * w + x] = sum.clamp(0, 255).toInt();

      for (int y = 1; y < h; y++) {
        sum += temp[(y + r).clamp(0, h - 1) * w + x] - temp[(y - r - 1).clamp(0, h - 1) * w + x];
        result[y * w + x] = (sum / kernel).clamp(0, 255).toInt();
      }
    }

    return result;
  }
}
