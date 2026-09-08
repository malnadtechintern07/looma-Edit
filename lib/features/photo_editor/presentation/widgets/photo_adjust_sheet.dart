import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoAdjustSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final String? selectedFrameId;
  final PhotoEditorController controller;

  const PhotoAdjustSheet({
    super.key,
    required this.project,
    this.selectedFrameId,
    required this.controller,
  });

  @override
  State<PhotoAdjustSheet> createState() => _PhotoAdjustSheetState();
}

class _PhotoAdjustSheetState extends State<PhotoAdjustSheet> {
  late PhotoFrameEntity? _targetFrame;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _resolveTargetFrame();
  }

  void _resolveTargetFrame() {
    if (widget.selectedFrameId != null) {
      _targetFrame = widget.project.frames.firstWhere(
        (f) => f.id == widget.selectedFrameId,
        orElse: () => widget.project.frames.isNotEmpty
            ? widget.project.frames.first
            : const PhotoFrameEntity(id: '', imagePath: ''),
      );
    } else {
      _targetFrame = widget.project.frames.isNotEmpty ? widget.project.frames.first : null;
    }
  }

  void _resetAll() {
    if (_targetFrame == null) return;
    widget.controller.resetFrameAdjustments(_targetFrame!.id);
    setState(() {
      _targetFrame = _targetFrame!.copyWith(
        brightness: 0.0,
        contrast: 1.0,
        exposure: 0.0,
        highlights: 0.0,
        shadows: 0.0,
        saturation: 1.0,
        vibrance: 0.0,
        temperature: 0.0,
        tint: 0.0,
        sharpness: 0.0,
        blur: 0.0,
        vignette: 0.0,
        grain: 0.0,
        fade: 0.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_targetFrame == null || _targetFrame!.id.isEmpty) {
      return SafeArea(
        top: false,
        bottom: true,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Text(
              'Add a photo to adjust brightness, contrast and color grading',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final frame = _targetFrame!;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Top Bar: Drag handle, Header, Compare button, Reset All, Close
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune, color: AppColors.primaryLight, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Color Adjustments',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hold to Compare Button
                        GestureDetector(
                          onTapDown: (_) {
                            setState(() => _isComparing = true);
                            widget.controller.setComparing(true);
                          },
                          onTapUp: (_) {
                            setState(() => _isComparing = false);
                            widget.controller.setComparing(false);
                          },
                          onTapCancel: () {
                            setState(() => _isComparing = false);
                            widget.controller.setComparing(false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: _isComparing ? AppColors.primary : const Color(0xFF272B3B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isComparing ? Icons.visibility : Icons.visibility_outlined,
                                  size: 13,
                                  color: _isComparing ? Colors.white : Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isComparing ? 'Original' : 'Compare',
                                  style: TextStyle(
                                    color: _isComparing ? Colors.white : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Reset All
                        TextButton(
                          onPressed: _resetAll,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Reset All',
                            style: TextStyle(color: AppColors.accentRose, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.check, color: AppColors.success),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Done',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scrollable list of all adjustments grouped by category
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: LIGHT & TONE ---
                    _buildSectionHeader('LIGHT & TONE'),
                    _buildAdjustmentSlider(
                      label: 'BRIGHTNESS',
                      value: frame.brightness,
                      min: -0.5,
                      max: 0.5,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(brightness: val));
                        widget.controller.updateFrameAdjustments(frame.id, brightness: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'CONTRAST',
                      value: frame.contrast,
                      min: 0.5,
                      max: 1.8,
                      defaultValue: 1.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(contrast: val));
                        widget.controller.updateFrameAdjustments(frame.id, contrast: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'EXPOSURE',
                      value: frame.exposure,
                      min: -1.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(exposure: val));
                        widget.controller.updateFrameAdjustments(frame.id, exposure: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'HIGHLIGHTS',
                      value: frame.highlights,
                      min: -1.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(highlights: val));
                        widget.controller.updateFrameAdjustments(frame.id, highlights: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'SHADOWS',
                      value: frame.shadows,
                      min: -1.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(shadows: val));
                        widget.controller.updateFrameAdjustments(frame.id, shadows: val);
                      },
                    ),

                    const SizedBox(height: 8),
                    // --- SECTION 2: COLOR & WHITE BALANCE ---
                    _buildSectionHeader('COLOR & WHITE BALANCE'),
                    _buildAdjustmentSlider(
                      label: 'SATURATION',
                      value: frame.saturation,
                      min: 0.0,
                      max: 2.0,
                      defaultValue: 1.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(saturation: val));
                        widget.controller.updateFrameAdjustments(frame.id, saturation: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'VIBRANCE',
                      value: frame.vibrance,
                      min: -1.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(vibrance: val));
                        widget.controller.updateFrameAdjustments(frame.id, vibrance: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'TEMPERATURE',
                      value: frame.temperature,
                      min: -1.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(temperature: val));
                        widget.controller.updateFrameAdjustments(frame.id, temperature: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'TINT',
                      value: frame.tint,
                      min: -1.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(tint: val));
                        widget.controller.updateFrameAdjustments(frame.id, tint: val);
                      },
                    ),

                    const SizedBox(height: 8),
                    // --- SECTION 3: DETAIL & EFFECTS ---
                    _buildSectionHeader('DETAIL & EFFECTS'),
                    _buildAdjustmentSlider(
                      label: 'SHARPNESS',
                      value: frame.sharpness,
                      min: 0.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(sharpness: val));
                        widget.controller.updateFrameAdjustments(frame.id, sharpness: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'BLUR',
                      value: frame.blur,
                      min: 0.0,
                      max: 20.0,
                      defaultValue: 0.0,
                      unit: 'px',
                      isPercent: false,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(blur: val));
                        widget.controller.updateFrameEffects(frame.id, blur: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'VIGNETTE',
                      value: frame.vignette,
                      min: 0.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(vignette: val));
                        widget.controller.updateFrameEffects(frame.id, vignette: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'GRAIN',
                      value: frame.grain,
                      min: 0.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(grain: val));
                        widget.controller.updateFrameEffects(frame.id, grain: val);
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'FADE',
                      value: frame.fade,
                      min: 0.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      unit: '',
                      isPercent: true,
                      onChanged: (val) {
                        setState(() => _targetFrame = frame.copyWith(fade: val));
                        widget.controller.updateFrameEffects(frame.id, fade: val);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required double defaultValue,
    required String unit,
    required bool isPercent,
    required ValueChanged<double> onChanged,
  }) {
    final isModified = (value - defaultValue).abs() > 0.01;
    final displayValue = isPercent
        ? '${(value * 100).round()}%'
        : '${value.toStringAsFixed(1)} $unit';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E29),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isModified ? AppColors.primaryLight.withValues(alpha: 0.6) : const Color(0xFF2C3042),
          width: isModified ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isModified)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isModified ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    displayValue,
                    style: AppTypography.labelSmall.copyWith(
                      color: isModified ? AppColors.primaryLight : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isModified) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => onChanged(defaultValue),
                      child: const Icon(Icons.refresh, size: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFF2C3042),
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
