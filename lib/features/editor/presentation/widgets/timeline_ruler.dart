import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/timecode_formatter.dart';

class TimelineRuler extends StatelessWidget {
  final int totalDurationMs;
  final double pixelsPerSecond;
  final int fps;

  const TimelineRuler({
    super.key,
    required this.totalDurationMs,
    required this.pixelsPerSecond,
    this.fps = 30,
  });

  @override
  Widget build(BuildContext context) {
    final totalSeconds = (totalDurationMs / 1000).ceil() + 2;
    final totalWidth = totalSeconds * pixelsPerSecond;

    return Container(
      height: AppConstants.timelineRulerHeight,
      width: totalWidth,
      decoration: const BoxDecoration(
        color: Color(0xFF161822),
        border: Border(bottom: BorderSide(color: Color(0xFF2E3240), width: 1)),
      ),
      child: CustomPaint(
        size: Size(totalWidth, AppConstants.timelineRulerHeight),
        painter: _RulerPainter(
          totalSeconds: totalSeconds,
          pixelsPerSecond: pixelsPerSecond,
          fps: fps,
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final int totalSeconds;
  final double pixelsPerSecond;
  final int fps;

  _RulerPainter({
    required this.totalSeconds,
    required this.pixelsPerSecond,
    required this.fps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final majorPaint = Paint()
      ..color = const Color(0xFFA0A6B8)
      ..strokeWidth = 1.5;

    final minorPaint = Paint()
      ..color = const Color(0xFF383D52)
      ..strokeWidth = 1.0;

    const textStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: Color(0xFFA0A6B8),
    );

    // Calculate adaptive step interval so timecodes never crowd/overlap
    int secStep;
    int subDivisions;
    if (pixelsPerSecond >= 80) {
      secStep = 1;
      subDivisions = (pixelsPerSecond >= 200) ? 10 : 4;
    } else if (pixelsPerSecond >= 35) {
      secStep = 2;
      subDivisions = 2;
    } else if (pixelsPerSecond >= 15) {
      secStep = 5;
      subDivisions = 5;
    } else if (pixelsPerSecond >= 6) {
      secStep = 10;
      subDivisions = 2;
    } else if (pixelsPerSecond >= 3) {
      secStep = 30;
      subDivisions = 3;
    } else if (pixelsPerSecond >= 1.2) {
      secStep = 60; // 1 min
      subDivisions = 2;
    } else if (pixelsPerSecond >= 0.6) {
      secStep = 120; // 2 min
      subDivisions = 2;
    } else {
      secStep = 300; // 5 min
      subDivisions = 5;
    }

    for (int sec = 0; sec <= totalSeconds; sec += secStep) {
      final x = sec * pixelsPerSecond;
      if (x > size.width) break;

      // Major tick
      canvas.drawLine(Offset(x, size.height - 10), Offset(x, size.height), majorPaint);

      // Timecode Label
      final timeStr = TimecodeFormatter.formatTimecode(sec * 1000, fps: fps);
      final textSpan = TextSpan(text: timeStr, style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 4, 3));

      // Minor subdivision ticks between major steps
      if (subDivisions > 1) {
        final subStepSeconds = secStep / subDivisions;
        for (int sub = 1; sub < subDivisions; sub++) {
          final subX = (sec + (sub * subStepSeconds)) * pixelsPerSecond;
          if (subX < size.width) {
            canvas.drawLine(Offset(subX, size.height - 5), Offset(subX, size.height), minorPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.totalSeconds != totalSeconds ||
      oldDelegate.pixelsPerSecond != pixelsPerSecond;
}
