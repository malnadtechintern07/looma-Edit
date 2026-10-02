import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoRatioSheet extends ConsumerStatefulWidget {
  final PhotoProjectEntity project;
  final PhotoEditorController controller;

  const PhotoRatioSheet({
    super.key,
    required this.project,
    required this.controller,
  });

  static const List<int> bgColors = [
    0xFF0F172A, // Slate Navy
    0xFF000000, // Pitch Black
    0xFFFFFFFF, // Pure White
    0xFF1E293B, // Charcoal
    0xFF3B0764, // Royal Purple
    0xFF881337, // Crimson Red
    0xFF064E3B, // Emerald Green
    0xFF1E3A8A, // Deep Blue
    0xFFF59E0B, // Amber Orange
    0xFFEC4899, // Pink Rose
  ];

  static const List<List<int>> gradientPresets = [
    [0xFF0F172A, 0xFF1E293B], // Slate to Navy
    [0xFF3B0764, 0xFF1E1B4B], // Purple to Indigo
    [0xFF881337, 0xFF3B0764], // Crimson to Purple
    [0xFF064E3B, 0xFF022C22], // Emerald Forest
    [0xFF00C2CB, 0xFF007AFF], // Cyan to Blue
    [0xFFF43F5E, 0xFFFB923C], // Sunset Coral
  ];

  @override
  ConsumerState<PhotoRatioSheet> createState() => _PhotoRatioSheetState();
}

class _PhotoRatioSheetState extends ConsumerState<PhotoRatioSheet> {
  String _selectedCategory = 'All';

  List<PhotoAspectRatio> _getFilteredRatios() {
    if (_selectedCategory == 'Social') {
      return PhotoAspectRatio.values.where((r) => r.category == 'Social').toList();
    } else if (_selectedCategory == 'Portrait') {
      return PhotoAspectRatio.values.where((r) => r.category == 'Portrait' || r == PhotoAspectRatio.portrait9x16 || r == PhotoAspectRatio.portrait4x5 || r == PhotoAspectRatio.portrait2x3).toList();
    } else if (_selectedCategory == 'Landscape') {
      return PhotoAspectRatio.values.where((r) => r.category == 'Landscape' || r == PhotoAspectRatio.landscape16x9).toList();
    }
    return PhotoAspectRatio.values;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photoEditorControllerProvider(widget.project));
    final currentProject = state.project;
    final currentRatio = currentProject.aspectRatio;
    final filteredRatios = _getFilteredRatios();

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFF2C3042), width: 1.0),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
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
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.aspect_ratio_rounded,
                          color: AppColors.primaryLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ratio Setting',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Adjust canvas format & background',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Ratio Details Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Visual wireframe of currently active ratio
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10121A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E3347)),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 38, maxHeight: 38),
                        child: AspectRatio(
                          aspectRatio: currentRatio.ratio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.primaryLight,
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.crop_free,
                                size: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentRatio.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  currentRatio.platform,
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Estimated Export: ${currentRatio.resolutionEstimate}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentRatio.description,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (currentRatio != PhotoAspectRatio.square)
                      IconButton(
                        tooltip: 'Reset to 1:1',
                        icon: const Icon(Icons.restart_alt, color: Colors.white60, size: 20),
                        onPressed: () => widget.controller.setAspectRatio(PhotoAspectRatio.square),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildCategoryChip('All', PhotoAspectRatio.values.length),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Social', 5),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Portrait', 5),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Landscape', 4),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Ratio Presets Horizontal Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: filteredRatios.map((ratio) {
                    final isSelected = currentRatio == ratio;
                    return _buildRatioCard(ratio, isSelected);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),

              // Canvas Background Style Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CANVAS BACKGROUND FILL',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    currentProject.backgroundType.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Background Type Switcher
              Row(
                children: [
                  Expanded(
                    child: _buildBgTypeButton(
                      label: 'Blur',
                      typeKey: 'blur',
                      icon: Icons.blur_on,
                      isActive: currentProject.backgroundType == 'blur',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildBgTypeButton(
                      label: 'Solid',
                      typeKey: 'color',
                      icon: Icons.palette_outlined,
                      isActive: currentProject.backgroundType == 'color',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildBgTypeButton(
                      label: 'Gradient',
                      typeKey: 'gradient',
                      icon: Icons.gradient,
                      isActive: currentProject.backgroundType == 'gradient',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildBgTypeButton(
                      label: 'Clear',
                      typeKey: 'transparent',
                      icon: Icons.grid_4x4,
                      isActive: currentProject.backgroundType == 'transparent',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dynamic Background Controls
              if (currentProject.backgroundType == 'blur') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Blur Intensity',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${currentProject.blurBackgroundRadius.toInt()} px',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: const Color(0xFF2C3042),
                    thumbColor: AppColors.primaryLight,
                    overlayColor: AppColors.primary.withValues(alpha: 0.2),
                    trackHeight: 3.5,
                  ),
                  child: Slider(
                    value: currentProject.blurBackgroundRadius,
                    min: 5.0,
                    max: 45.0,
                    onChanged: (val) {
                      widget.controller.setCanvasStyle(blurBackgroundRadius: val);
                    },
                  ),
                ),
              ] else if (currentProject.backgroundType == 'color') ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: PhotoRatioSheet.bgColors.map((colorHex) {
                      final isCurrentColor = currentProject.backgroundColorHex == colorHex;
                      return GestureDetector(
                        onTap: () {
                          widget.controller.setCanvasStyle(
                            backgroundType: 'color',
                            backgroundColorHex: colorHex,
                          );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Color(colorHex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrentColor ? AppColors.primary : Colors.white24,
                              width: isCurrentColor ? 2.5 : 1.0,
                            ),
                            boxShadow: isCurrentColor
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isCurrentColor
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: colorHex == 0xFFFFFFFF ? Colors.black : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else if (currentProject.backgroundType == 'gradient') ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: PhotoRatioSheet.gradientPresets.map((grads) {
                      final isSelectedGrad = currentProject.gradientColorsHex.length == grads.length &&
                          currentProject.gradientColorsHex.first == grads.first;
                      return GestureDetector(
                        onTap: () {
                          widget.controller.setCanvasStyle(
                            backgroundType: 'gradient',
                            gradientColorsHex: grads,
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 34,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(grads[0]), Color(grads[1])],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelectedGrad ? AppColors.primary : Colors.white24,
                              width: isSelectedGrad ? 2.5 : 1.0,
                            ),
                          ),
                          child: isSelectedGrad
                              ? const Center(
                                  child: Icon(Icons.check, size: 16, color: Colors.white),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Bottom Actions: Undo, Reset, Apply
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.undo,
                      color: state.canUndo ? Colors.white : Colors.white30,
                    ),
                    tooltip: 'Undo',
                    onPressed: state.canUndo ? () => widget.controller.undo() : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.redo,
                      color: state.canRedo ? Colors.white : Colors.white30,
                    ),
                    tooltip: 'Redo',
                    onPressed: state.canRedo ? () => widget.controller.redo() : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text('Apply (${currentRatio.ratioText})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Canvas ratio set to ${currentRatio.label}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String title, int count) {
    final isSelected = _selectedCategory == title;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF1E212E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : const Color(0xFF2C3042),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioCard(PhotoAspectRatio ratio, bool isSelected) {
    return GestureDetector(
      onTap: () {
        widget.controller.setAspectRatio(ratio);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 86,
        height: 118,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFF1A1D28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF2C3042),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Wireframe representation of aspect ratio
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: ratio.ratio,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : Colors.white10,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryLight : Colors.white38,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            // Ratio Title & Subtitle
            Column(
              children: [
                Text(
                  ratio.ratioText,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ratio.platform,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryLight : Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBgTypeButton({
    required String label,
    required String typeKey,
    required IconData icon,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () {
        widget.controller.setCanvasStyle(backgroundType: typeKey);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFF1E212E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFF2C3042),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primaryLight : Colors.white60,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primaryLight : Colors.white70,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
