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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    if (_targetFrame == null || _targetFrame!.id.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text('Add a photo to adjust brightness, contrast and color grading'),
        ),
      );
    }

    final frame = _targetFrame!;

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
              Text('Color Adjustments', style: AppTypography.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Brightness
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BRIGHTNESS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              Text('${(frame.brightness * 100).round()}%', style: AppTypography.labelSmall),
            ],
          ),
          Slider(
            value: frame.brightness,
            min: -0.5,
            max: 0.5,
            activeColor: AppColors.primaryLight,
            onChanged: (val) {
              setState(() {
                _targetFrame = frame.copyWith(brightness: val);
              });
              widget.controller.updateFrameColorGrading(frame.id, brightness: val);
            },
          ),

          // Contrast
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CONTRAST', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              Text('${(frame.contrast * 100).round()}%', style: AppTypography.labelSmall),
            ],
          ),
          Slider(
            value: frame.contrast,
            min: 0.5,
            max: 1.8,
            activeColor: AppColors.primaryLight,
            onChanged: (val) {
              setState(() {
                _targetFrame = frame.copyWith(contrast: val);
              });
              widget.controller.updateFrameColorGrading(frame.id, contrast: val);
            },
          ),

          // Saturation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SATURATION', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              Text('${(frame.saturation * 100).round()}%', style: AppTypography.labelSmall),
            ],
          ),
          Slider(
            value: frame.saturation,
            min: 0.0,
            max: 2.0,
            activeColor: AppColors.primaryLight,
            onChanged: (val) {
              setState(() {
                _targetFrame = frame.copyWith(saturation: val);
              });
              widget.controller.updateFrameColorGrading(frame.id, saturation: val);
            },
          ),
        ],
      ),
    );
  }
}
