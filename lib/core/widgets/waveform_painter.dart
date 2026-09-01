import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color waveColor;
  final double progress; // 0.0 to 1.0

  WaveformPainter({
    required this.samples,
    this.waveColor = AppColors.primary,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final barWidth = 3.0;
    final barSpacing = 2.0;
    final totalBars = (size.width / (barWidth + barSpacing)).floor();

    final paintPlayed = Paint()
      ..color = waveColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final paintUnplayed = Paint()
      ..color = waveColor.withValues(alpha: 0.25)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.9;

    for (int i = 0; i < totalBars; i++) {
      final sampleIndex = (i * samples.length / totalBars).floor().clamp(0, samples.length - 1);
      final sampleVal = samples[sampleIndex].clamp(0.05, 1.0);
      final barHeight = max(4.0, sampleVal * maxBarHeight);

      final x = i * (barWidth + barSpacing) + barWidth / 2;
      final isPlayed = (x / size.width) <= progress;

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        isPlayed ? paintPlayed : paintUnplayed,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.progress != progress;
  }
}
