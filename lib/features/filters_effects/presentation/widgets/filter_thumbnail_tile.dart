import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/filter_preset.dart';
import 'scenic_filter_preview.dart';

/// Studio thumbnail tile for a single filter preset in the horizontal bottom panel
class FilterThumbnailTile extends StatelessWidget {
  final FilterType filter;
  final bool isSelected;
  final double intensity;
  final String? mediaPath;
  final VoidCallback onTap;

  const FilterThumbnailTile({
    super.key,
    required this.filter,
    required this.isSelected,
    this.intensity = 1.0,
    this.mediaPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNone = filter == FilterType.none;
    final colorFilter = filter.getColorFilter(1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 84,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : const Color(0xFF1E202B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF2C2F3E),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Thumbnail
            SizedBox(
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Filtered live preview
                    if (colorFilter != null)
                      ColorFiltered(
                        colorFilter: colorFilter,
                        child: ScenicFilterPreview(mediaPath: mediaPath),
                      )
                    else
                      ScenicFilterPreview(mediaPath: mediaPath),

                    // "Original" tag for none
                    if (isNone)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RAW',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // Active checkmark badge
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),

                    // Active intensity badge when selected and not none
                    if (isSelected && !isNone)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${(intensity * 100).round()}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Filter Name
            Text(
              filter.label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Subtitle
            Text(
              filter.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? AppColors.secondaryLight
                    : const Color(0xFF94A3B8),
                fontSize: 8.5,
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
