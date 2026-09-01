import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/looma_button.dart';
import '../../../../core/widgets/looma_slider.dart';

class EffectsPickerSheet extends StatefulWidget {
  final double initialBlur;
  final double initialZoom;
  final int initialFadeInMs;
  final int initialFadeOutMs;
  final double initialBrightness;
  final double initialContrast;
  final double initialSaturation;
  final Function({
    required double blur,
    required double zoom,
    required int fadeInMs,
    required int fadeOutMs,
    required double brightness,
    required double contrast,
    required double saturation,
  }) onEffectsChanged;

  const EffectsPickerSheet({
    super.key,
    required this.initialBlur,
    required this.initialZoom,
    required this.initialFadeInMs,
    required this.initialFadeOutMs,
    required this.initialBrightness,
    required this.initialContrast,
    required this.initialSaturation,
    required this.onEffectsChanged,
  });

  @override
  State<EffectsPickerSheet> createState() => _EffectsPickerSheetState();
}

class _EffectsPickerSheetState extends State<EffectsPickerSheet> {
  late double _blur;
  late double _zoom;
  late double _fadeInSec;
  late double _fadeOutSec;
  late double _brightness;
  late double _contrast;
  late double _saturation;

  @override
  void initState() {
    super.initState();
    _blur = widget.initialBlur;
    _zoom = widget.initialZoom;
    _fadeInSec = widget.initialFadeInMs / 1000.0;
    _fadeOutSec = widget.initialFadeOutMs / 1000.0;
    _brightness = widget.initialBrightness;
    _contrast = widget.initialContrast;
    _saturation = widget.initialSaturation;
  }

  void _notifyChange() {
    widget.onEffectsChanged(
      blur: _blur,
      zoom: _zoom,
      fadeInMs: (_fadeInSec * 1000).round(),
      fadeOutMs: (_fadeOutSec * 1000).round(),
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_fix_high, color: AppColors.secondaryLight, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Visual Effects & Tuning', style: AppTypography.titleMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Blur Slider
            LoomaSlider(
              label: 'Gaussian Blur',
              icon: Icons.blur_on,
              value: _blur,
              min: 0.0,
              max: 10.0,
              divisions: 20,
              valueFormatter: (v) => '${v.toStringAsFixed(1)}px',
              onChanged: (v) {
                setState(() => _blur = v);
                _notifyChange();
              },
            ),
            const SizedBox(height: 12),

            // 2. Zoom / Scale Slider
            LoomaSlider(
              label: 'Zoom / Crop Scale',
              icon: Icons.zoom_in,
              value: _zoom,
              min: 1.0,
              max: 2.0,
              divisions: 20,
              valueFormatter: (v) => '${v.toStringAsFixed(2)}x',
              onChanged: (v) {
                setState(() => _zoom = v);
                _notifyChange();
              },
            ),
            const SizedBox(height: 12),

            // 3. Fade In Duration
            LoomaSlider(
              label: 'Fade In Duration',
              icon: Icons.gradient,
              value: _fadeInSec,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              valueFormatter: (v) => '${v.toStringAsFixed(1)}s',
              onChanged: (v) {
                setState(() => _fadeInSec = v);
                _notifyChange();
              },
            ),
            const SizedBox(height: 12),

            // 4. Fade Out Duration
            LoomaSlider(
              label: 'Fade Out Duration',
              icon: Icons.gradient_outlined,
              value: _fadeOutSec,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              valueFormatter: (v) => '${v.toStringAsFixed(1)}s',
              onChanged: (v) {
                setState(() => _fadeOutSec = v);
                _notifyChange();
              },
            ),
            const SizedBox(height: 12),

            // 5. Brightness
            LoomaSlider(
              label: 'Brightness',
              icon: Icons.wb_sunny_outlined,
              value: _brightness,
              min: -0.5,
              max: 0.5,
              divisions: 20,
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (v) {
                setState(() => _brightness = v);
                _notifyChange();
              },
            ),
            const SizedBox(height: 12),

            // 6. Contrast
            LoomaSlider(
              label: 'Contrast',
              icon: Icons.contrast,
              value: _contrast,
              min: 0.5,
              max: 1.8,
              divisions: 20,
              valueFormatter: (v) => '${v.toStringAsFixed(2)}x',
              onChanged: (v) {
                setState(() => _contrast = v);
                _notifyChange();
              },
            ),
            const SizedBox(height: 20),

            // Done CTA
            LoomaButton(
              label: 'Apply Effects',
              icon: Icons.check,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
