import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/crop_rect_entity.dart';
import '../../domain/entities/video_clip_entity.dart';

class CropTransformSheet extends StatefulWidget {
  final VideoClipEntity clip;
  final ValueChanged<CropRectEntity?> onCropChanged;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onFlipHorizontal;
  final VoidCallback onFlipVertical;
  final VoidCallback onReset;

  const CropTransformSheet({
    super.key,
    required this.clip,
    required this.onCropChanged,
    required this.onOpacityChanged,
    required this.onFlipHorizontal,
    required this.onFlipVertical,
    required this.onReset,
  });

  @override
  State<CropTransformSheet> createState() => _CropTransformSheetState();
}

class _CropTransformSheetState extends State<CropTransformSheet> {
  late double _opacity;
  late String _selectedRatio;

  final List<Map<String, dynamic>> _ratios = [
    {'label': 'Free', 'left': 0.0, 'top': 0.0, 'right': 1.0, 'bottom': 1.0},
    {'label': '9:16', 'left': 0.15, 'top': 0.0, 'right': 0.85, 'bottom': 1.0},
    {'label': '16:9', 'left': 0.0, 'top': 0.2, 'right': 1.0, 'bottom': 0.8},
    {'label': '1:1', 'left': 0.1, 'top': 0.1, 'right': 0.9, 'bottom': 0.9},
    {'label': '4:5', 'left': 0.1, 'top': 0.05, 'right': 0.9, 'bottom': 0.95},
    {'label': '4:3', 'left': 0.05, 'top': 0.15, 'right': 0.95, 'bottom': 0.85},
  ];

  @override
  void initState() {
    super.initState();
    _opacity = widget.clip.opacity;
    _selectedRatio = widget.clip.crop?.ratioName ?? 'Free';
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
                  Icon(Icons.crop, color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Transform & Crop',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _opacity = 1.0;
                    _selectedRatio = 'Free';
                  });
                  widget.onReset();
                  widget.onOpacityChanged(1.0);
                  widget.onCropChanged(null);
                },
                icon: const Icon(Icons.refresh, size: 16, color: AppColors.accent),
                label: const Text('Reset', style: TextStyle(color: AppColors.accent, fontSize: 13)),
              ),
            ],
          ),
          const Divider(color: Color(0xFF2E3240), height: 20),

          // Aspect Ratio Crop Presets
          const Text(
            'Crop Aspect Ratio',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _ratios.map((r) {
                final isSelected = _selectedRatio == r['label'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(r['label'] as String),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFF262A38),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFF383D52),
                    ),
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedRatio = r['label'] as String);
                        widget.onCropChanged(
                          CropRectEntity(
                            left: r['left'] as double,
                            top: r['top'] as double,
                            right: r['right'] as double,
                            bottom: r['bottom'] as double,
                            ratioName: r['label'] as String,
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Transform Controls (Flip H & V)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onFlipHorizontal,
                  icon: const Icon(Icons.flip, size: 18, color: AppColors.secondary),
                  label: const Text('Flip Horizontal', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF383D52)),
                    backgroundColor: const Color(0xFF262A38),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onFlipVertical,
                  icon: const Icon(Icons.flip_camera_android, size: 18, color: AppColors.secondary),
                  label: const Text('Flip Vertical', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF383D52)),
                    backgroundColor: const Color(0xFF262A38),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Opacity Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Clip Opacity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              Text('${(_opacity * 100).round()}%', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFF2E3240),
              thumbColor: Colors.white,
              trackHeight: 4,
            ),
            child: Slider(
              value: _opacity.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: (v) {
                setState(() => _opacity = v);
                widget.onOpacityChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
