import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoFilterSheet extends StatelessWidget {
  final PhotoProjectEntity project;
  final String? selectedFrameId;
  final PhotoEditorController controller;

  const PhotoFilterSheet({
    super.key,
    required this.project,
    this.selectedFrameId,
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
              Text('Color Filters & LUT Presets', style: AppTypography.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: FilterType.values.length,
              itemBuilder: (context, index) {
                final filter = FilterType.values[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      if (selectedFrameId != null) {
                        controller.updateFrameColorGrading(selectedFrameId!, filterType: filter);
                      } else {
                        controller.applyFilterToAllFrames(filter);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                            child: const Icon(Icons.palette, color: AppColors.secondary, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            filter.label,
                            style: AppTypography.labelSmall.copyWith(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
