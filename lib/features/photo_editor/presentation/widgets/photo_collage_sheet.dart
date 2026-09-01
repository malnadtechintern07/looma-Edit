import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoCollageSheet extends StatelessWidget {
  final PhotoProjectEntity project;
  final PhotoEditorController controller;

  const PhotoCollageSheet({
    super.key,
    required this.project,
    required this.controller,
  });

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
              Text('Collage Templates & Grids', style: AppTypography.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            'Choose a multi-photo collage template (2, 3, 4, 6, or 9 slots)',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Collage Templates Grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
            children: CollageLayoutType.values.map((layout) {
              final isSelected = project.collageLayout == layout;

              return InkWell(
                onTap: () {
                  controller.setCollageLayout(layout);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryLight : AppColors.surfaceBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getLayoutIcon(layout),
                        color: isSelected ? AppColors.accent : Colors.white70,
                        size: 26,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        layout.title,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
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
        ],
      ),
    );
  }

  IconData _getLayoutIcon(CollageLayoutType layout) {
    switch (layout) {
      case CollageLayoutType.single:
        return Icons.crop_square;
      case CollageLayoutType.grid2Vertical:
        return Icons.view_agenda;
      case CollageLayoutType.grid2Horizontal:
        return Icons.view_column;
      case CollageLayoutType.grid3Hero:
        return Icons.dashboard;
      case CollageLayoutType.grid4Quad:
        return Icons.grid_view;
      case CollageLayoutType.grid6Grid:
        return Icons.apps;
      case CollageLayoutType.grid9Grid:
        return Icons.grid_on;
    }
  }
}
