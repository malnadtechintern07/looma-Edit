import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../../filters_effects/presentation/widgets/filter_thumbnail_tile.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

/// Studio-grade bottom panel for professional photo filters with:
/// - 20+ live preview thumbnails using the photo image
/// - 0–100% intensity slider control
/// - Category quick-filters
/// - "Apply to all frames" toggle
/// - "Hold to Compare" original preview
/// - Remove & Reset actions
class PhotoFilterSheet extends StatefulWidget {
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
  State<PhotoFilterSheet> createState() => _PhotoFilterSheetState();
}

class _PhotoFilterSheetState extends State<PhotoFilterSheet> {
  late FilterType _currentFilter;
  late double _currentIntensity;
  FilterCategory _selectedCategory = FilterCategory.all;
  bool _applyToAll = false;
  bool _isComparing = false;
  FilterType? _preCompareFilter;

  PhotoFrameEntity? get _activeFrame {
    if (widget.project.frames.isEmpty) return null;
    if (widget.selectedFrameId != null) {
      return widget.project.frames.firstWhere(
        (f) => f.id == widget.selectedFrameId,
        orElse: () => widget.project.frames.first,
      );
    }
    return widget.project.frames.first;
  }

  @override
  void initState() {
    super.initState();
    final frame = _activeFrame;
    _currentFilter = frame?.filterType ?? FilterType.none;
    _currentIntensity = frame?.filterIntensity.clamp(0.0, 1.0) ?? 1.0;
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

  void _applyFilter(FilterType filter, {double? intensity}) {
    final frame = _activeFrame;
    final targetIntensity = intensity ?? _currentIntensity;

    setState(() {
      _currentFilter = filter;
      _currentIntensity = targetIntensity;
    });

    if (_applyToAll) {
      widget.controller.applyFilterToAllFrames(
        filter,
        filterIntensity: targetIntensity,
      );
    } else if (frame != null) {
      widget.controller.updateFrameColorGrading(
        frame.id,
        filterType: filter,
        filterIntensity: targetIntensity,
      );
    }
  }

  void _onIntensityChanged(double value) {
    setState(() => _currentIntensity = value);
    final frame = _activeFrame;

    if (_applyToAll) {
      widget.controller.applyFilterToAllFrames(
        _currentFilter,
        filterIntensity: value,
      );
    } else if (frame != null) {
      widget.controller.updateFrameColorGrading(
        frame.id,
        filterType: _currentFilter,
        filterIntensity: value,
      );
    }
  }

  void _removeFilter() {
    final frame = _activeFrame;
    setState(() {
      _currentFilter = FilterType.none;
      _currentIntensity = 1.0;
    });

    if (_applyToAll) {
      widget.controller.applyFilterToAllFrames(
        FilterType.none,
        filterIntensity: 1.0,
      );
    } else if (frame != null) {
      widget.controller.removeFilter(frame.id);
    }
  }

  void _setComparing(bool active) {
    final frame = _activeFrame;
    if (active) {
      _preCompareFilter = _currentFilter;
      setState(() => _isComparing = true);
      // Temporarily show original
      if (_applyToAll) {
        widget.controller.applyFilterToAllFrames(FilterType.none);
      } else if (frame != null) {
        widget.controller.updateFrameColorGrading(
          frame.id,
          filterType: FilterType.none,
        );
      }
    } else {
      setState(() => _isComparing = false);
      final restore = _preCompareFilter ?? _currentFilter;
      if (_applyToAll) {
        widget.controller.applyFilterToAllFrames(
          restore,
          filterIntensity: _currentIntensity,
        );
      } else if (frame != null) {
        widget.controller.updateFrameColorGrading(
          frame.id,
          filterType: restore,
          filterIntensity: _currentIntensity,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = _activeFrame;
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
                          Icons.palette_outlined,
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
                                'Photo Color Filters',
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
                                onTap: () => _onIntensityChanged(1.0),
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

                      // Slider
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
                                onChanged: _onIntensityChanged,
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
                const SizedBox(height: 10),
              ],

              // Options row: Category pills + Apply to All toggle
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: FilterCategory.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final cat = FilterCategory.values[index];
                          final isCatSelected = cat == _selectedCategory;

                          return InkWell(
                            onTap: () => setState(() => _selectedCategory = cat),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isCatSelected
                                    ? AppColors.primary
                                    : const Color(0xFF1E202B),
                                borderRadius: BorderRadius.circular(14),
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
                                    size: 12,
                                    color: isCatSelected
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      color: isCatSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: isCatSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Apply to all frames toggle (if multi-frame collage)
                  if (widget.project.frames.length > 1) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() => _applyToAll = !_applyToAll);
                        if (_applyToAll) {
                          widget.controller.applyFilterToAllFrames(
                            _currentFilter,
                            filterIntensity: _currentIntensity,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _applyToAll
                              ? AppColors.secondary.withValues(alpha: 0.2)
                              : const Color(0xFF1E202B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _applyToAll
                                ? AppColors.secondary
                                : const Color(0xFF2C2F3E),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _applyToAll
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 13,
                              color: _applyToAll
                                  ? AppColors.secondaryLight
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'All Frames',
                              style: TextStyle(
                                color: _applyToAll
                                    ? AppColors.secondaryLight
                                    : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
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
                      mediaPath: frame?.imagePath,
                      onTap: () => _applyFilter(filter),
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
