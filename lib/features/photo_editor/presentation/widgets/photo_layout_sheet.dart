import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoLayoutSheet extends StatelessWidget {
  final PhotoProjectEntity project;
  final PhotoEditorController controller;

  const PhotoLayoutSheet({
    super.key,
    required this.project,
    required this.controller,
  });

  static const List<int> bgColors = [
    0xFF0F172A, // Dark Slate
    0xFF030712, // Midnight
    0xFF000000, // Pure Black
    0xFFFFFFFF, // Pure White
    0xFF3B0764, // Vibrant Purple
    0xFF881337, // Crimson
    0xFF064E3B, // Emerald
    0xFF1E293B, // Charcoal
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
              Text('Canvas Layout & Aspect Ratio', style: AppTypography.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Aspect Ratios
          Text('ASPECT RATIO', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PhotoAspectRatio.values.map((ratio) {
                final isSelected = project.aspectRatio == ratio;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(ratio.label),
                    selected: isSelected,
                    onSelected: (_) => controller.setAspectRatio(ratio),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Gap Spacing Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRID GAP SPACING', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              Text('${project.gapSpacing.round()} px', style: AppTypography.labelSmall),
            ],
          ),
          Slider(
            value: project.gapSpacing,
            min: 0,
            max: 20,
            activeColor: AppColors.primaryLight,
            onChanged: (val) => controller.setCanvasStyle(gapSpacing: val),
          ),

          // Corner Radius Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CORNER RADIUS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              Text('${project.borderRadius.round()} px', style: AppTypography.labelSmall),
            ],
          ),
          Slider(
            value: project.borderRadius,
            min: 0,
            max: 24,
            activeColor: AppColors.primaryLight,
            onChanged: (val) => controller.setCanvasStyle(borderRadius: val),
          ),

          // Background Color Palette
          const SizedBox(height: 10),
          Text('CANVAS BACKGROUND', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: bgColors.map((colorHex) {
              final isSelected = project.backgroundColorHex == colorHex;
              return GestureDetector(
                onTap: () => controller.setCanvasStyle(backgroundColorHex: colorHex),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(colorHex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : Colors.white24,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
