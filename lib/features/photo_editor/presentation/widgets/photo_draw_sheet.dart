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
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                    child: Row(
                      children: [
                        const Icon(Icons.brush, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Freehand Vector Brush',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.redAccent),
                    label: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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

              // Brush vs Eraser Mode Selector
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E212E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.toggleEraserMode(false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !state.isEraserMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.brush, size: 16, color: !state.isEraserMode ? Colors.white : Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                'Brush Mode',
                                style: TextStyle(
                                  color: !state.isEraserMode ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.toggleEraserMode(true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: state.isEraserMode ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_fix_high, size: 16, color: state.isEraserMode ? Colors.white : Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                'Eraser Mode',
                                style: TextStyle(
                                  color: state.isEraserMode ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (!state.isEraserMode) ...[
                // Brush Types: Pen, Marker, Neon
                Text('BRUSH TYPE', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBrushTypeChip('🖊️ Solid Pen', 'pen'),
                    const SizedBox(width: 8),
                    _buildBrushTypeChip('🖍️ Marker', 'marker'),
                    const SizedBox(width: 8),
                    _buildBrushTypeChip('✨ Neon Glow', 'neon'),
                  ],
                ),
                const SizedBox(height: 14),

                // Brush Color Palette
                Text('BRUSH COLOR', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: brushPalette.map((color) {
                    final isSelected = state.currentBrushColor == color;
                    return GestureDetector(
                      onTap: () => controller.setBrushColor(color),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (color == const Color(0xFFFFFFFF) ? const Color(0xFFCBD5E1) : const Color(0x33000000)),
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
                                color: color == const Color(0xFFFFFFFF) || color == const Color(0xFFFFCC00) || color == const Color(0xFF00FFCC) || color == const Color(0xFF00FF66) ? Colors.black : Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Stroke Size Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('STROKE WIDTH', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${state.currentBrushSize.round()} px', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: state.currentBrushSize.clamp(2.0, 35.0),
                min: 2,
                max: 35,
                activeColor: AppColors.primary,
                onChanged: (val) => controller.setBrushSize(val),
              ),

              if (!state.isEraserMode) ...[
                // Opacity Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('OPACITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    Text('${(state.brushOpacity * 100).round()}%', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: state.brushOpacity.clamp(0.1, 1.0),
                  min: 0.1,
                  max: 1.0,
                  activeColor: AppColors.primary,
                  onChanged: (val) => controller.setBrushOpacity(val),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrushTypeChip(String label, String type) {
    final isSelected = state.brushType == type;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setBrushType(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFF1E212E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFF2C3042)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryLight : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
