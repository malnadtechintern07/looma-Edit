import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/filter_preset.dart';

class FilterPickerSheet extends StatelessWidget {
  final FilterType selectedFilter;
  final ValueChanged<FilterType> onFilterSelected;

  const FilterPickerSheet({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_vintage, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text('Color Filters & LUTs', style: AppTypography.titleMedium),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.success),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: FilterType.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final filter = FilterType.values[index];
                final isSelected = filter == selectedFilter;

                return InkWell(
                  onTap: () => onFilterSelected(filter),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            child: ColorFiltered(
                              colorFilter: filter.colorFilter ??
                                  const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFFEC4899), Color(0xFFF59E0B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.photo_size_select_actual, color: Colors.white70, size: 24),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Text(
                            filter.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.labelSmall.copyWith(
                              color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
