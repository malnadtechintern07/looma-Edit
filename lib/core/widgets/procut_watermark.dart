import 'package:flutter/material.dart';

/// Clean, minimal, compact ProCut watermark with "✦ ProCut",
/// small font size, and subtle opacity.
class ProCutWatermark extends StatelessWidget {
  final double opacity;
  final double scale;
  final String? text;

  const ProCutWatermark({
    super.key,
    this.opacity = 0.6,
    this.scale = 0.8,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '✦',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.0,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 2.0,
                    offset: Offset(0.5, 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2.5),
            Text(
              text?.trim().isNotEmpty == true ? text!.trim() : 'ProCut',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 2.0,
                    offset: Offset(0.5, 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef LoomaWatermark = ProCutWatermark;
