import 'dart:io';
import 'package:flutter/material.dart';

/// Renders either the user's media image or a rich multi-chromatic scenic landscape
/// that showcases highlights, shadows, skin tones, skies, and foliage for filter previews.
class ScenicFilterPreview extends StatelessWidget {
  final String? mediaPath;
  final double width;
  final double height;

  const ScenicFilterPreview({
    super.key,
    this.mediaPath,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaPath != null && mediaPath!.isNotEmpty) {
      final path = mediaPath!;
      if (path.startsWith('assets/')) {
        return Image.asset(
          path,
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => const _FallbackScenicCanvas(),
        );
      } else if (File(path).existsSync()) {
        final lower = path.toLowerCase();
        final isImg = lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp');
        if (isImg) {
          return Image.file(
            File(path),
            fit: BoxFit.cover,
            width: width,
            height: height,
            errorBuilder: (_, _, _) => const _FallbackScenicCanvas(),
          );
        }
      }
    }

    return const _FallbackScenicCanvas();
  }
}

class _FallbackScenicCanvas extends StatelessWidget {
  const _FallbackScenicCanvas();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _ScenicLandscapePainter(),
      size: Size.infinite,
    );
  }
}

/// Custom painter that creates a beautiful, colorful landscape:
/// - Cyan/Azure Sky fading to golden sunset horizon
/// - Sun with soft aura
/// - Mountain silhouette in navy/teal
/// - Lush warm foreground hill in amber/green
/// - Rich contrast that reacts dynamically to color matrices
class _ScenicLandscapePainter extends CustomPainter {
  const _ScenicLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient (Azure blue to radiant golden twilight)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E3A8A), // Deep Sky Blue
          Color(0xFF3B82F6), // Azure
          Color(0xFFF59E0B), // Warm Golden
          Color(0xFFEC4899), // Sunset Rose
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.7));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.7), skyPaint);

    // 2. Sun Glow
    final sunCenter = Offset(w * 0.7, h * 0.35);
    final sunAuraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          const Color(0xFFFDE047).withValues(alpha: 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: w * 0.28));
    canvas.drawCircle(sunCenter, w * 0.28, sunAuraPaint);

    final sunCorePaint = Paint()..color = const Color(0xFFFFFBEB);
    canvas.drawCircle(sunCenter, w * 0.09, sunCorePaint);

    // 3. Distant Mountains (Teal & Navy)
    final mountainPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF312E81), Color(0xFF1E293B)],
      ).createShader(Rect.fromLTWH(0, h * 0.35, w, h * 0.35));

    final mountainPath = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.22, h * 0.38)
      ..lineTo(w * 0.42, h * 0.52)
      ..lineTo(w * 0.68, h * 0.35)
      ..lineTo(w * 0.88, h * 0.48)
      ..lineTo(w, h * 0.42)
      ..lineTo(w, h * 0.7)
      ..lineTo(0, h * 0.7)
      ..close();
    canvas.drawPath(mountainPath, mountainPaint);

    // 4. Midground Rolling Hill (Rich Emerald Green)
    final hillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF059669), Color(0xFF064E3B)],
      ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.3));

    final hillPath = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.35, h * 0.48, w * 0.7, h * 0.60)
      ..quadraticBezierTo(w * 0.85, h * 0.65, w, h * 0.58)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    // 5. Foreground Warm Earth & Flora (Warm Amber & Coral)
    final fgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD97706), Color(0xFF92400E)],
      ).createShader(Rect.fromLTWH(0, h * 0.72, w, h * 0.28));

    final fgPath = Path()
      ..moveTo(0, h * 0.75)
      ..quadraticBezierTo(w * 0.45, h * 0.82, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(fgPath, fgPaint);

    // 6. Vibrant Highlights / Flowers
    final flowerPaint1 = Paint()..color = const Color(0xFFF43F5E);
    final flowerPaint2 = Paint()..color = const Color(0xFFA855F7);
    canvas.drawCircle(Offset(w * 0.2, h * 0.84), 3.0, flowerPaint1);
    canvas.drawCircle(Offset(w * 0.32, h * 0.88), 2.5, flowerPaint2);
    canvas.drawCircle(Offset(w * 0.65, h * 0.82), 3.5, flowerPaint1);
    canvas.drawCircle(Offset(w * 0.8, h * 0.86), 2.5, flowerPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
