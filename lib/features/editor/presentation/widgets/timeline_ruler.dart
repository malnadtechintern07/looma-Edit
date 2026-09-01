import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
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
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 1)),
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
      ..color = AppColors.timelineRulerText
      ..strokeWidth = 1.5;

    final minorPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..strokeWidth = 1.0;

    final textStyle = AppTypography.labelSmall.copyWith(
      fontSize: 9,
      color: AppColors.timelineRulerText,
    );

    for (int sec = 0; sec <= totalSeconds; sec++) {
      final x = sec * pixelsPerSecond;

      // Major second tick
      canvas.drawLine(Offset(x, size.height - 10), Offset(x, size.height), majorPaint);

      // Second Label
      final timeStr = TimecodeFormatter.formatTimecode(sec * 1000, fps: fps);
      final textSpan = TextSpan(text: timeStr, style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 4, 3));

      // Minor frame subdivision ticks (4 per second)
      for (int sub = 1; sub < 4; sub++) {
        final subX = x + (sub * (pixelsPerSecond / 4));
        if (subX < size.width) {
          canvas.drawLine(Offset(subX, size.height - 5), Offset(subX, size.height), minorPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.totalSeconds != totalSeconds ||
      oldDelegate.pixelsPerSecond != pixelsPerSecond;
}
