import 'package:flutter/material.dart';

/// Clean, minimal ProCut watermark with "✦ ProCut",
/// no background box, small font size, and subtle 65% opacity.
class ProCutWatermark extends StatelessWidget {
  final double opacity;
  final double scale;

  const ProCutWatermark({
    super.key,
    this.opacity = 0.65,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '✦',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 3.0,
                    offset: Offset(0.5, 0.5),
                  ),
                ],
              ),
            ),
            SizedBox(width: 3.0),
            Text(
              'ProCut',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 3.0,
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
