import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/looma_slider.dart';
import '../../domain/entities/transition_type.dart';

class TransitionPickerSheet extends StatefulWidget {
  final TransitionType currentTransition;
  final int currentDurationMs;
  final Function(TransitionType transition, int durationMs) onTransitionSelected;

  const TransitionPickerSheet({
    super.key,
    required this.currentTransition,
    this.currentDurationMs = 500,
    required this.onTransitionSelected,
  });

  @override
  State<TransitionPickerSheet> createState() => _TransitionPickerSheetState();
}

class _TransitionPickerSheetState extends State<TransitionPickerSheet> {
  late TransitionType _selectedTransition;
  late double _durationSec;

  @override
  void initState() {
    super.initState();
    _selectedTransition = widget.currentTransition;
    _durationSec = widget.currentDurationMs / 1000.0;
  }

  void _applyChange() {
    widget.onTransitionSelected(
      _selectedTransition,
      (_durationSec * 1000).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.transform, color: AppColors.primaryLight, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text('Clip Transition & Duration FX', style: AppTypography.titleMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.success),
                  onPressed: () {
                    _applyChange();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transition Presets Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: TransitionType.values.map((trans) {
                final isSelected = _selectedTransition == trans;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedTransition = trans);
                    _applyChange();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getTransitionIcon(trans),
                          size: 28,
                          color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          trans.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Transition Duration Slider
            if (_selectedTransition != TransitionType.none) ...[
              LoomaSlider(
                label: 'Transition Duration',
                icon: Icons.timer_outlined,
                value: _durationSec,
                min: 0.2,
                max: 3.0,
                divisions: 28,
                valueFormatter: (v) => '${v.toStringAsFixed(1)}s',
                onChanged: (v) {
                  setState(() => _durationSec = v);
                  _applyChange();
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTransitionIcon(TransitionType trans) {
    switch (trans) {
      case TransitionType.none:
        return Icons.block;
      case TransitionType.crossFade:
        return Icons.blur_on;
      case TransitionType.slideLeft:
        return Icons.swipe_left;
      case TransitionType.slideUp:
        return Icons.swipe_up;
      case TransitionType.wipeRight:
        return Icons.gradient;
      case TransitionType.zoomIn:
        return Icons.zoom_in;
      case TransitionType.glitch:
        return Icons.electric_bolt;
    }
  }
}
