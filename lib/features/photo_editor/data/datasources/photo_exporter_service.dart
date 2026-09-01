import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class PhotoExporterService {
  Future<String> exportCanvasToImage({
    required GlobalKey boundaryKey,
    required String projectTitle,
    bool isPng = true,
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Canvas render boundary not found');
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(
        format: isPng ? ui.ImageByteFormat.png : ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to encode image data');
      }

      final buffer = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedTitle = projectTitle.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final ext = isPng ? 'png' : 'jpg';
      final fileName = 'LOOMA_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(buffer);

      return filePath;
    } catch (e) {
      rethrow;
    }
  }
}
