import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/filter_preset.dart';
import 'filter_thumbnail_tile.dart';

/// Studio-grade bottom panel for professional color filters with:
/// - 20+ real-time filters with live thumbnails
/// - 0–100% intensity slider control
/// - Category quick-filters
/// - "Hold to Compare" original preview
/// - Filter removal and reset
class FilterPickerSheet extends StatefulWidget {
  final FilterType selectedFilter;
  final double filterIntensity;
  final ValueChanged<FilterType> onFilterSelected;
  final ValueChanged<double>? onIntensityChanged;
  final VoidCallback? onFilterRemoved;
  final ValueChanged<bool>? onHoldToCompare;
  final String? mediaPath;

  const FilterPickerSheet({
    super.key,
    required this.selectedFilter,
    this.filterIntensity = 1.0,
    required this.onFilterSelected,
    this.onIntensityChanged,
    this.onFilterRemoved,
    this.onHoldToCompare,
    this.mediaPath,
  });

  @override
  State<FilterPickerSheet> createState() => _FilterPickerSheetState();
}

class _FilterPickerSheetState extends State<FilterPickerSheet> {
  late FilterType _currentFilter;
  late double _currentIntensity;
  FilterCategory _selectedCategory = FilterCategory.all;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.selectedFilter;
    _currentIntensity = widget.filterIntensity.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(covariant FilterPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter) {
      setState(() => _currentFilter = widget.selectedFilter);
    }
    if (oldWidget.filterIntensity != widget.filterIntensity) {
      setState(() => _currentIntensity = widget.filterIntensity.clamp(0.0, 1.0));
    }
  }

  List<FilterType> get _filteredList {
    if (_selectedCategory == FilterCategory.all) {
      return FilterType.values;
    }
    return [
      FilterType.none,
      ...FilterType.values.where(
        (f) => f != FilterType.none && f.category == _selectedCategory,
      ),
    ];
  }

  void _selectFilter(FilterType filter) {
    setState(() {
      _currentFilter = filter;
      if (filter == FilterType.none) {
        _currentIntensity = 1.0;
      }
    });
    widget.onFilterSelected(filter);
    if (widget.onIntensityChanged != null && filter != FilterType.none) {
      widget.onIntensityChanged!(_currentIntensity);
    }
  }

  void _onIntensitySliderChanged(double value) {
    setState(() => _currentIntensity = value);
    widget.onIntensityChanged?.call(value);
  }

  void _removeFilter() {
    setState(() {
      _currentFilter = FilterType.none;
      _currentIntensity = 1.0;
    });
    widget.onFilterRemoved?.call();
    widget.onFilterSelected(FilterType.none);
  }

  void _setComparing(bool active) {
    setState(() => _isComparing = active);
    widget.onHoldToCompare?.call(active);
  }

  @override
  Widget build(BuildContext context) {
    final isNone = _currentFilter == FilterType.none;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13151D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.filter_vintage,
                          color: AppColors.primaryLight,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Filters & LUTs',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${FilterType.values.length - 1} PRO',
                                  style: const TextStyle(
                                    color: AppColors.secondaryLight,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            isNone
                                ? 'Tap any filter to preview live'
                                : '${_currentFilter.label} • ${(_currentIntensity * 100).round()}% strength',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      if (!isNone)
                        TextButton.icon(
                          onPressed: _removeFilter,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 15,
                            color: AppColors.accentRose,
                          ),
                          label: const Text(
                            'Remove',
                            style: TextStyle(
                              color: AppColors.accentRose,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                          ),
                        ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.check, color: AppColors.success),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Apply & Close',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Intensity Control Slider (visible when a filter is active)
              if (!isNone) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1E29),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2C3042)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tune,
                                size: 14,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Filter Intensity',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(_currentIntensity * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              // Hold to Compare Button
                              GestureDetector(
                                onTapDown: (_) => _setComparing(true),
                                onTapUp: (_) => _setComparing(false),
                                onTapCancel: () => _setComparing(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isComparing
                                        ? AppColors.primary
                                        : const Color(0xFF272B3B),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isComparing
                                            ? Icons.visibility
                                            : Icons.visibility_outlined,
                                        size: 13,
                                        color: _isComparing
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isComparing ? 'Original' : 'Hold Compare',
                                        style: TextStyle(
                                          color: _isComparing
                                              ? Colors.white
                                              : Colors.white70,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Quick 100% Reset
                              InkWell(
                                onTap: () => _onIntensitySliderChanged(1.0),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: const Text(
                                    '100%',
                                    style: TextStyle(
                                      color: AppColors.secondaryLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Slider with 0% and 100% labels
                      Row(
                        children: [
                          const Text(
                            '0%',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: const Color(0xFF2C3042),
                                thumbColor: Colors.white,
                                overlayColor: AppColors.primary.withValues(alpha: 0.2),
                                trackHeight: 3.5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                              ),
                              child: Slider(
                                value: _currentIntensity,
                                min: 0.0,
                                max: 1.0,
                                onChanged: _onIntensitySliderChanged,
                              ),
                            ),
                          ),
                          const Text(
                            '100%',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Category Filter Pills
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: FilterCategory.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = FilterCategory.values[index];
                    final isCatSelected = cat == _selectedCategory;

                    return InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCatSelected
                              ? AppColors.primary
                              : const Color(0xFF1E202B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCatSelected
                                ? AppColors.primaryLight
                                : const Color(0xFF2C2F3E),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 13,
                              color: isCatSelected ? Colors.white : Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              cat.label,
                              style: TextStyle(
                                color: isCatSelected ? Colors.white : Colors.white70,
                                fontSize: 11,
                                fontWeight: isCatSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Filter Thumbnails Horizontal Scroll List
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredList.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final filter = _filteredList[index];
                    final isSelected = filter == _currentFilter;

                    return FilterThumbnailTile(
                      filter: filter,
                      isSelected: isSelected,
                      intensity: isSelected ? _currentIntensity : 1.0,
                      mediaPath: widget.mediaPath,
                      onTap: () => _selectFilter(filter),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
