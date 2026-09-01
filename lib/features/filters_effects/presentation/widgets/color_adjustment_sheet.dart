import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/looma_slider.dart';

class ColorAdjustmentSheet extends StatefulWidget {
  final double initialBrightness;
  final double initialContrast;
  final double initialSaturation;
  final Function(double brightness, double contrast, double saturation) onAdjustmentsChanged;

  const ColorAdjustmentSheet({
    super.key,
    required this.initialBrightness,
    required this.initialContrast,
    required this.initialSaturation,
    required this.onAdjustmentsChanged,
  });

  @override
  State<ColorAdjustmentSheet> createState() => _ColorAdjustmentSheetState();
}

class _ColorAdjustmentSheetState extends State<ColorAdjustmentSheet> {
  late double _brightness;
  late double _contrast;
  late double _saturation;

  @override
  void initState() {
    super.initState();
    _brightness = widget.initialBrightness;
    _contrast = widget.initialContrast;
    _saturation = widget.initialSaturation;
  }

  void _notify() {
    widget.onAdjustmentsChanged(_brightness, _contrast, _saturation);
  }

  void _reset() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text('Color & Light Adjustments', style: AppTypography.titleMedium),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: _reset,
                    child: Text('Reset', style: AppTypography.labelSmall.copyWith(color: AppColors.error)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.success),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Brightness
          LoomaSlider(
            label: 'Brightness',
            icon: Icons.wb_sunny_outlined,
            value: _brightness,
            min: -0.5,
            max: 0.5,
            divisions: 20,
            valueFormatter: (v) => '${(v * 100).toInt()}%',
            onChanged: (v) {
              setState(() => _brightness = v);
              _notify();
            },
          ),
          const SizedBox(height: 12),

          // Contrast
          LoomaSlider(
            label: 'Contrast',
            icon: Icons.contrast_outlined,
            value: _contrast,
            min: 0.5,
            max: 1.8,
            divisions: 26,
            valueFormatter: (v) => '${(v * 100).toInt()}%',
            onChanged: (v) {
              setState(() => _contrast = v);
              _notify();
            },
          ),
          const SizedBox(height: 12),

          // Saturation
          LoomaSlider(
            label: 'Saturation',
            icon: Icons.palette_outlined,
            value: _saturation,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            valueFormatter: (v) => '${(v * 100).toInt()}%',
            onChanged: (v) {
              setState(() => _saturation = v);
              _notify();
            },
          ),
        ],
      ),
    );
  }
}
