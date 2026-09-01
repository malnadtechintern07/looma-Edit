import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/looma_slider.dart';

class ClipSpeedSheet extends StatefulWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  const ClipSpeedSheet({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  State<ClipSpeedSheet> createState() => _ClipSpeedSheetState();
}

class _ClipSpeedSheetState extends State<ClipSpeedSheet> {
  late double _speed;

  final List<double> _presetSpeeds = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0];

  @override
  void initState() {
    super.initState();
    _speed = widget.currentSpeed;
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
                  const Icon(Icons.speed, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('Speed Ramping & Duration', style: AppTypography.titleMedium),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.success),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Speed Slider
          LoomaSlider(
            label: 'Playback Speed',
            icon: Icons.fast_forward,
            value: _speed,
            min: 0.25,
            max: 4.0,
            divisions: 15,
            valueFormatter: (v) => '${v.toStringAsFixed(2)}x',
            onChanged: (v) {
              setState(() => _speed = v);
              widget.onSpeedChanged(v);
            },
          ),
          const SizedBox(height: 16),

          // Presets row
          Text('Speed Presets', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetSpeeds.map((preset) {
              final isSelected = (_speed - preset).abs() < 0.05;
              return ChoiceChip(
                label: Text('${preset}x'),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _speed = preset);
                  widget.onSpeedChanged(preset);
                },
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
