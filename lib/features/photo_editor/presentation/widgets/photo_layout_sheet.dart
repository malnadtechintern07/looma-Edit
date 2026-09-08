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

  static const List<List<int>> gradientPresets = [
    [0xFF0F172A, 0xFF1E293B], // Slate to Navy
    [0xFF3B0764, 0xFF1E1B4B], // Purple to Indigo
    [0xFF881337, 0xFF3B0764], // Crimson to Purple
    [0xFF064E3B, 0xFF022C22], // Emerald Forest
    [0xFF00C2CB, 0xFF007AFF], // Electric Blue
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Canvas Layout & Aspect Ratio',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Aspect Ratios
              Text('ASPECT RATIO', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
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
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Background Style Modes: Color, Gradient, Blur, Transparent
              Text('BACKGROUND STYLE', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildBgTypeChip(context, 'Solid', 'color', Icons.color_lens),
                    const SizedBox(width: 8),
                    _buildBgTypeChip(context, 'Gradient', 'gradient', Icons.gradient),
                    const SizedBox(width: 8),
                    _buildBgTypeChip(context, 'Photo Blur', 'blur', Icons.blur_on),
                    const SizedBox(width: 8),
                    _buildBgTypeChip(context, 'Transparent', 'transparent', Icons.opacity),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (project.backgroundType == 'color') ...[
                // Solid Color Palette
                Text('CANVAS BACKGROUND', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: bgColors.map((colorHex) {
                      final isSelected = project.backgroundColorHex == colorHex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => controller.setCanvasStyle(backgroundColorHex: colorHex, backgroundType: 'color'),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(colorHex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (colorHex == 0xFFFFFFFF ? const Color(0xFFCBD5E1) : const Color(0x33000000)),
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [const BoxShadow(color: Color(0x330D6EFD), blurRadius: 6, spreadRadius: 1)]
                                  : null,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: colorHex == 0xFFFFFFFF ? Colors.black : Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else if (project.backgroundType == 'gradient') ...[
                Text('GRADIENT PRESETS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: gradientPresets.map((grads) {
                      return GestureDetector(
                        onTap: () => controller.setCanvasStyle(gradientColorsHex: grads, backgroundType: 'gradient'),
                        child: Container(
                          width: 48,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: grads.map(Color.new).toList()),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else if (project.backgroundType == 'blur') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BLUR INTENSITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    Text('${project.blurBackgroundRadius.round()} px', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: project.blurBackgroundRadius.clamp(5.0, 50.0),
                  min: 5,
                  max: 50,
                  activeColor: AppColors.primary,
                  onChanged: (val) => controller.setCanvasStyle(blurBackgroundRadius: val, backgroundType: 'blur'),
                ),
              ],
              const SizedBox(height: 16),

              // Gap Spacing Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GRID GAP SPACING', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${project.gapSpacing.round()} px', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: project.gapSpacing.clamp(0.0, 20.0),
                min: 0,
                max: 20,
                activeColor: AppColors.primary,
                onChanged: (val) => controller.setCanvasStyle(gapSpacing: val),
              ),

              // Corner Radius Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CORNER RADIUS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${project.borderRadius.round()} px', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: project.borderRadius.clamp(0.0, 24.0),
                min: 0,
                max: 24,
                activeColor: AppColors.primary,
                onChanged: (val) => controller.setCanvasStyle(borderRadius: val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBgTypeChip(BuildContext context, String label, String type, IconData icon) {
    final isSelected = project.backgroundType == type;
    return InkWell(
      onTap: () => controller.setCanvasStyle(backgroundType: type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primaryLight : Colors.white70),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryLight : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
