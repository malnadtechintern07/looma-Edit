import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/procut_slider.dart';
import '../../domain/entities/mask_config_entity.dart';

class MaskSheet extends StatefulWidget {
  final MaskConfigEntity? currentMask;
  final ValueChanged<MaskConfigEntity?> onMaskChanged;

  const MaskSheet({
    super.key,
    required this.currentMask,
    required this.onMaskChanged,
  });

  @override
  State<MaskSheet> createState() => _MaskSheetState();
}

class _MaskSheetState extends State<MaskSheet> {
  late MaskShape _shape;
  late double _feather;
  late double _widthFactor;
  late double _heightFactor;
  late double _rotation;
  late bool _isInverted;

  @override
  void initState() {
    super.initState();
    final m = widget.currentMask ?? const MaskConfigEntity();
    _shape = m.shape;
    _feather = m.feather;
    _widthFactor = m.widthFactor;
    _heightFactor = m.heightFactor;
    _rotation = m.rotationDegrees;
    _isInverted = m.isInverted;
  }

  void _notify() {
    if (_shape == MaskShape.none) {
      widget.onMaskChanged(null);
    } else {
      widget.onMaskChanged(
        MaskConfigEntity(
          shape: _shape,
          feather: _feather,
          widthFactor: _widthFactor,
          heightFactor: _heightFactor,
          rotationDegrees: _rotation,
          isInverted: _isInverted,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 28, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF161822),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.masks, color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Video Masking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_shape != MaskShape.none)
                TextButton(
                  onPressed: () {
                    setState(() => _shape = MaskShape.none);
                    _notify();
                  },
                  child: const Text('Remove', style: TextStyle(color: AppColors.accentRose, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Divider(color: Color(0xFF2E3240), height: 20),

          // Shape Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShapeButton(MaskShape.none, 'None', Icons.block),
              _buildShapeButton(MaskShape.rectangle, 'Rectangle', Icons.crop_din),
              _buildShapeButton(MaskShape.circle, 'Circle', Icons.circle_outlined),
              _buildShapeButton(MaskShape.linear, 'Linear', Icons.linear_scale),
              _buildShapeButton(MaskShape.filmstrip, 'Film', Icons.view_compact),
            ],
          ),

          if (_shape != MaskShape.none) ...[
            const SizedBox(height: 20),
            // Invert Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invert Mask', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                Switch(
                  value: _isInverted,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFF2E3240),
                  inactiveThumbColor: const Color(0xFF9CA3AF),
                  trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected) ? Colors.transparent : const Color(0xFF4B5563),
                  ),
                  onChanged: (val) {
                    setState(() => _isInverted = val);
                    _notify();
                  },
                ),
              ],
            ),

            // Feather Slider
            ProCutSlider(
              label: 'Feather (Soft Edge)',
              icon: Icons.blur_on,
              value: _feather.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (val) {
                setState(() => _feather = val);
                _notify();
              },
            ),
            const SizedBox(height: 12),

            // Size / Width Factor Slider
            ProCutSlider(
              label: 'Mask Size',
              icon: Icons.aspect_ratio,
              value: _widthFactor.clamp(0.1, 1.0),
              min: 0.1,
              max: 1.0,
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (val) {
                setState(() {
                  _widthFactor = val;
                  _heightFactor = val;
                });
                _notify();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShapeButton(MaskShape shape, String label, IconData icon) {
    final isSelected = _shape == shape;
    return InkWell(
      onTap: () {
        setState(() => _shape = shape);
        _notify();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.35) : const Color(0xFF262A38),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.secondary : const Color(0xFF383D52),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.secondary : Colors.white70),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFA0A6B8),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
