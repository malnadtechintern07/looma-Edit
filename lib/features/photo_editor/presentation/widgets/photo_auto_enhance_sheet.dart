import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../../domain/services/photo_auto_enhance_service.dart';
import '../providers/photo_editor_controller.dart';

class PhotoAutoEnhanceSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final String? selectedFrameId;
  final PhotoEditorController controller;

  const PhotoAutoEnhanceSheet({
    super.key,
    required this.project,
    this.selectedFrameId,
    required this.controller,
  });

  @override
  State<PhotoAutoEnhanceSheet> createState() => _PhotoAutoEnhanceSheetState();
}

class _PhotoAutoEnhanceSheetState extends State<PhotoAutoEnhanceSheet> {
  final PhotoAutoEnhanceService _service = PhotoAutoEnhanceService();

  late PhotoFrameEntity? _targetFrame;
  AutoEnhanceResult? _result;
  bool _isAnalyzing = true;
  bool _isComparing = false;

  AutoEnhancePreset _preset = AutoEnhancePreset.balanced;
  double _intensity = 1.0; // 0.0 to 2.0 (1.0 = 100%)

  @override
  void initState() {
    super.initState();
    _resolveFrame();
    _analyzePhoto();
  }

  void _resolveFrame() {
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

  Future<void> _analyzePhoto() async {
    if (_targetFrame == null || _targetFrame!.imagePath.isEmpty) {
      setState(() => _isAnalyzing = false);
      return;
    }

    final res = await _service.analyzeAndComputeAdjustments(
      imagePath: _targetFrame!.imagePath,
      preset: _preset,
      intensity: _intensity,
    );

    if (mounted) {
      setState(() {
        _result = res;
        _isAnalyzing = false;
      });

      // Update frame adjustments live on canvas
      _applyLiveToCanvas(res);
    }
  }

  void _onIntensityChanged(double val) {
    setState(() => _intensity = val);
    if (_targetFrame == null) return;

    final res = _service.computeAdjustmentsFromImage(
      image: (null as dynamic), // Will fallback gracefully to formulaic scaling
      preset: _preset,
      intensity: val,
    );

    // If we have previous analysis metrics, rescale cleanly
    if (_result != null) {
      final k = val;
      final updated = AutoEnhanceResult(
        brightness: (_result!.brightness * (k / max(0.01, _intensity))).clamp(-0.5, 0.5),
        contrast: (1.0 + (_result!.contrast - 1.0) * (k / max(0.01, _intensity))).clamp(0.5, 2.0),
        exposure: (_result!.exposure * (k / max(0.01, _intensity))).clamp(-1.0, 1.0),
        highlights: (_result!.highlights * (k / max(0.01, _intensity))).clamp(-1.0, 1.0),
        shadows: (_result!.shadows * (k / max(0.01, _intensity))).clamp(-1.0, 1.0),
        saturation: (1.0 + (_result!.saturation - 1.0) * (k / max(0.01, _intensity))).clamp(0.0, 2.0),
        vibrance: (_result!.vibrance * (k / max(0.01, _intensity))).clamp(-1.0, 1.0),
        temperature: (_result!.temperature * (k / max(0.01, _intensity))).clamp(-1.0, 1.0),
        tint: (_result!.tint * (k / max(0.01, _intensity))).clamp(-1.0, 1.0),
        sharpness: (_result!.sharpness * (k / max(0.01, _intensity))).clamp(0.0, 1.0),
        metrics: _result!.metrics,
        highlightsApplied: _result!.highlightsApplied,
      );
      setState(() => _result = updated);
      _applyLiveToCanvas(updated);
    } else {
      _applyLiveToCanvas(res);
    }
  }

  void _onPresetChanged(AutoEnhancePreset preset) {
    setState(() {
      _preset = preset;
      _isAnalyzing = true;
    });
    _analyzePhoto();
  }

  void _applyLiveToCanvas(AutoEnhanceResult res) {
    if (_targetFrame == null) return;
    widget.controller.updateFrameAdjustments(
      _targetFrame!.id,
      brightness: res.brightness,
      contrast: res.contrast,
      exposure: res.exposure,
      highlights: res.highlights,
      shadows: res.shadows,
      saturation: res.saturation,
      vibrance: res.vibrance,
      temperature: res.temperature,
      tint: res.tint,
      sharpness: res.sharpness,
      recordHistory: false, // Don't spam history during live dragging
    );
  }

  void _finalizeAndSave() {
    if (_targetFrame == null || _result == null) return;

    widget.controller.applyAutoEnhanceAdjustments(
      _targetFrame!.id,
      brightness: _result!.brightness,
      contrast: _result!.contrast,
      exposure: _result!.exposure,
      highlights: _result!.highlights,
      shadows: _result!.shadows,
      saturation: _result!.saturation,
      vibrance: _result!.vibrance,
      temperature: _result!.temperature,
      tint: _result!.tint,
      sharpness: _result!.sharpness,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto Enhancement applied successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cancelAndRevert() {
    if (_targetFrame != null) {
      widget.controller.resetFrameAdjustments(_targetFrame!.id);
    }
    Navigator.of(context).pop();
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
              'Add a photo to apply intelligent Auto Enhance',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Auto Enhance',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Hold to Compare
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
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: _cancelAndRevert,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preset Styles
                    Text('STYLE PRESETS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip(AutoEnhancePreset.balanced, 'Universal Auto', Icons.auto_awesome),
                          _buildPresetChip(AutoEnhancePreset.portrait, 'Portrait Glow', Icons.face),
                          _buildPresetChip(AutoEnhancePreset.landscape, 'Landscape Vivid', Icons.landscape),
                          _buildPresetChip(AutoEnhancePreset.lowLight, 'Low Light Boost', Icons.brightness_medium),
                          _buildPresetChip(AutoEnhancePreset.crisp, 'Crisp Detail', Icons.high_quality),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Intensity Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ENHANCE INTENSITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        Text('${(_intensity * 100).round()}%', style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: const Color(0xFF272B3B),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _intensity,
                        min: 0.0,
                        max: 2.0,
                        onChanged: _onIntensityChanged,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Metrics Breakdown Cards
                    Text('DETECTED & OPTIMIZED', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_isAnalyzing)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (_result != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMetricPill('Exposure', '${(_result!.exposure > 0 ? '+' : '')}${(_result!.exposure * 100).round()}%', Icons.wb_sunny),
                          _buildMetricPill('Contrast', '${((_result!.contrast - 1.0) * 100).round()}%', Icons.contrast),
                          _buildMetricPill('Shadows', '+${(_result!.shadows * 100).round()}%', Icons.dark_mode_outlined),
                          _buildMetricPill('Vibrance', '+${(_result!.vibrance * 100).round()}%', Icons.palette),
                          _buildMetricPill('Sharpness', '+${(_result!.sharpness * 100).round()}%', Icons.blur_linear),
                        ],
                      ),

                    const SizedBox(height: 16),
                    if (_result != null && _result!.highlightsApplied.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1F2D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A2E40)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.primaryLight, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _result!.highlightsApplied.join(' • '),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white, size: 20),
                label: const Text(
                  'Apply Auto Enhancement',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _finalizeAndSave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(AutoEnhancePreset preset, String label, IconData icon) {
    final isSelected = _preset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onPresetChanged(preset),
        selectedColor: AppColors.primary,
        backgroundColor: const Color(0xFF1E212E),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetricPill(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E212E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C3042)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          Text('$title: ', style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}
