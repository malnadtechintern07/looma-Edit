import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/photo_editor_controller.dart';

class PhotoDrawSheet extends StatelessWidget {
  final PhotoEditorState state;
  final PhotoEditorController controller;

  const PhotoDrawSheet({
    super.key,
    required this.state,
    required this.controller,
  });

  static const List<Color> brushPalette = [
    Color(0xFFFF0055), // Neon Pink
    Color(0xFFFFCC00), // Neon Yellow
    Color(0xFF00FFCC), // Neon Cyan
    Color(0xFF00FF66), // Neon Green
    Color(0xFF9900FF), // Neon Purple
    Color(0xFFFFFFFF), // White
    Color(0xFF000000), // Black
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  const Icon(Icons.brush, color: AppColors.accent, size: 22),
                  const SizedBox(width: 8),
                  Text('Freehand Vector Brush', style: AppTypography.titleMedium),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.redAccent),
                label: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                onPressed: () {
                  controller.clearDrawingStrokes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cleared drawing strokes')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Enable Draw Mode Toggle
          SwitchListTile(
            title: const Text('Enable Freehand Drawing Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
            subtitle: const Text('Draw directly on the canvas using your finger or stylus', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            value: state.isDrawMode,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            inactiveThumbColor: Colors.white,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Colors.transparent : const Color(0xFF94A3B8),
            ),
            onChanged: (val) => controller.toggleDrawMode(val),
          ),
          const SizedBox(height: 12),

          // Brush Color Palette
          Text('BRUSH COLOR', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: brushPalette.map((color) {
              final isSelected = state.currentBrushColor == color;
              return GestureDetector(
                onTap: () => controller.setBrushColor(color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : Colors.white24,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Stroke Size Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STROKE WIDTH', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              Text('${state.currentBrushSize.round()} px', style: AppTypography.labelSmall),
            ],
          ),
          Slider(
            value: state.currentBrushSize.clamp(2.0, 20.0),
            min: 2,
            max: 20,
            activeColor: AppColors.primaryLight,
            onChanged: (val) => controller.setBrushSize(val),
          ),
        ],
      ),
    );
  }
}
