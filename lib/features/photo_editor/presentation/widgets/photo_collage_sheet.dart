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
                      'Collage Templates & Grids',
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
              const SizedBox(height: 12),

              Text(
                'Choose a multi-photo collage template (2, 3, 4, 6, or 9 slots)',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Collage Templates Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getLayoutIcon(layout),
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            layout.title,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
        ),
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
