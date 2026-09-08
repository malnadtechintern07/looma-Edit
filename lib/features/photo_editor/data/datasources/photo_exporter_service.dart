import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/gallery_saver_service.dart';

class PhotoExporterService {
  Future<String> exportCanvasToImage({
    required GlobalKey boundaryKey,
    required String projectTitle,
    bool isPng = true,
    double pixelRatio = 3.0,
    int? targetWidth,
    int? targetHeight,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Canvas render boundary not found');
      }

      // If target dimensions are specified, calculate adaptive pixelRatio or resize buffer
      double effectiveRatio = pixelRatio;
      if (targetWidth != null && boundary.size.width > 0) {
        effectiveRatio = (targetWidth / boundary.size.width).clamp(1.0, 5.0);
      }

      final image = await boundary.toImage(pixelRatio: effectiveRatio);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to encode image data');
      }

      var buffer = byteData.buffer.asUint8List();

      // If user specified exact custom export dimensions in Resize tool, resize pixel buffer exactly
      if (targetWidth != null && targetHeight != null) {
        final decoded = img.decodeImage(buffer);
        if (decoded != null) {
          final resized = img.copyResize(
            decoded,
            width: targetWidth,
            height: targetHeight,
            interpolation: img.Interpolation.cubic,
          );
          buffer = isPng
              ? Uint8List.fromList(img.encodePng(resized))
              : Uint8List.fromList(img.encodeJpg(resized, quality: 95));
        }
      } else if (!isPng) {
        // If JPEG chosen without custom dimensions, encode as high quality JPEG
        final decoded = img.decodeImage(buffer);
        if (decoded != null) {
          buffer = Uint8List.fromList(img.encodeJpg(decoded, quality: 95));
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final sanitizedTitle = projectTitle.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final ext = isPng ? 'png' : 'jpg';
      final fileName = 'LOOMA_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(buffer);

      // Save directly to user's device gallery (Pictures/Looma or MediaStore)
      final galleryPath = await GallerySaverService.saveImageToDeviceGallery(
        sourceFilePath: filePath,
        fileName: fileName,
        isPng: isPng,
      );

      return galleryPath ?? filePath;
    } catch (e) {
      rethrow;
    }
  }
}
