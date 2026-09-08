import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoCropSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final String? selectedFrameId;
  final PhotoEditorController controller;

  const PhotoCropSheet({
    super.key,
    required this.project,
    this.selectedFrameId,
    required this.controller,
  });

  @override
  State<PhotoCropSheet> createState() => _PhotoCropSheetState();
}

enum _CropToolTab { crop, rotate, straighten, perspective }

class _PhotoCropSheetState extends State<PhotoCropSheet> {
  late PhotoFrameEntity? _targetFrame;
  _CropToolTab _activeTab = _CropToolTab.crop;

  @override
  void initState() {
    super.initState();
    _resolveFrame();
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

  void _applyAspectRatioCrop(double widthRatio, double heightRatio) {
    if (_targetFrame == null) return;
    final frame = _targetFrame!;

    if (widthRatio <= 0 || heightRatio <= 0) {
      // Freeform / Reset crop
      setState(() {
        _targetFrame = frame.copyWith(cropLeft: 0.0, cropTop: 0.0, cropRight: 1.0, cropBottom: 1.0);
      });
      widget.controller.updateFrameCrop(frame.id, cropLeft: 0.0, cropTop: 0.0, cropRight: 1.0, cropBottom: 1.0);
      return;
    }

    final targetRatio = widthRatio / heightRatio;
    double newLeft = 0.0, newTop = 0.0, newRight = 1.0, newBottom = 1.0;

    if (targetRatio > 1.0) {
      // Wider than tall (e.g. 16:9)
      final cropHeight = (1.0 / targetRatio).clamp(0.1, 1.0);
      newTop = (1.0 - cropHeight) / 2.0;
      newBottom = 1.0 - newTop;
    } else {
      // Taller than wide (e.g. 9:16 or 4:5)
      final cropWidth = targetRatio.clamp(0.1, 1.0);
      newLeft = (1.0 - cropWidth) / 2.0;
      newRight = 1.0 - newLeft;
    }

    setState(() {
      _targetFrame = frame.copyWith(
        cropLeft: newLeft,
        cropTop: newTop,
        cropRight: newRight,
        cropBottom: newBottom,
      );
    });
    widget.controller.updateFrameCrop(
      frame.id,
      cropLeft: newLeft,
      cropTop: newTop,
      cropRight: newRight,
      cropBottom: newBottom,
    );
  }

  void _rotate90(bool clockwise) {
    if (_targetFrame == null) return;
    final frame = _targetFrame!;
    final delta = clockwise ? (pi / 2.0) : (-pi / 2.0);
    setState(() {
      _targetFrame = frame.copyWith(rotation: frame.rotation + delta);
    });
    widget.controller.updateFrameTransformGeometry(frame.id, rotationDelta: delta);
  }

  void _toggleFlip(bool horizontal) {
    if (_targetFrame == null) return;
    final frame = _targetFrame!;
    if (horizontal) {
      final newFlip = !frame.flipHorizontal;
      setState(() => _targetFrame = frame.copyWith(flipHorizontal: newFlip));
      widget.controller.updateFrameTransformGeometry(frame.id, flipHorizontal: newFlip);
    } else {
      final newFlip = !frame.flipVertical;
      setState(() => _targetFrame = frame.copyWith(flipVertical: newFlip));
      widget.controller.updateFrameTransformGeometry(frame.id, flipVertical: newFlip);
    }
  }

  void _resetAllTransforms() {
    if (_targetFrame == null) return;
    final frame = _targetFrame!;
    setState(() {
      _targetFrame = frame.copyWith(
        cropLeft: 0.0,
        cropTop: 0.0,
        cropRight: 1.0,
        cropBottom: 1.0,
        rotation: 0.0,
        straighten: 0.0,
        perspectiveX: 0.0,
        perspectiveY: 0.0,
        flipHorizontal: false,
        flipVertical: false,
      );
    });
    widget.controller.updateFrameCrop(frame.id, cropLeft: 0.0, cropTop: 0.0, cropRight: 1.0, cropBottom: 1.0);
    widget.controller.updateFrameTransformGeometry(
      frame.id,
      straighten: 0.0,
      perspectiveX: 0.0,
      perspectiveY: 0.0,
      flipHorizontal: false,
      flipVertical: false,
      rotationDelta: -frame.rotation,
    );
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
              'Add a photo to crop and transform',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.crop, color: AppColors.primaryLight, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Crop & Perspective',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetAllTransforms,
                      child: const Text('Reset', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.success),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Apply',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Buttons: Crop, Rotate, Straighten, Perspective
            Container(
              height: 38,
              decoration: BoxDecoration(color: const Color(0xFF1E212E), borderRadius: BorderRadius.circular(10)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildSubTab('✂️ Aspect', _CropToolTab.crop),
                    _buildSubTab('🔄 Rotate/Flip', _CropToolTab.rotate),
                    _buildSubTab('📐 Straighten', _CropToolTab.straighten),
                    _buildSubTab('🔲 3D Tilt', _CropToolTab.perspective),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            if (_activeTab == _CropToolTab.crop) ...[
              Text('ASPECT RATIO PRESETS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildAspectPresetChip('Freeform', 0, 0),
                    _buildAspectPresetChip('1:1 Square', 1, 1),
                    _buildAspectPresetChip('4:5 Feed', 4, 5),
                    _buildAspectPresetChip('9:16 Story', 9, 16),
                    _buildAspectPresetChip('16:9 Cinema', 16, 9),
                    _buildAspectPresetChip('3:4 Classic', 3, 4),
                    _buildAspectPresetChip('2:3 Portrait', 2, 3),
                    _buildAspectPresetChip('21:9 Ultrawide', 21, 9),
                  ],
                ),
              ),
            ] else if (_activeTab == _CropToolTab.rotate) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.rotate_left,
                    label: '90° Left',
                    onTap: () => _rotate90(false),
                  ),
                  _buildActionButton(
                    icon: Icons.rotate_right,
                    label: '90° Right',
                    onTap: () => _rotate90(true),
                  ),
                  _buildActionButton(
                    icon: Icons.flip,
                    label: 'Flip Horiz',
                    isActive: frame.flipHorizontal,
                    onTap: () => _toggleFlip(true),
                  ),
                  _buildActionButton(
                    icon: Icons.flip_camera_android,
                    label: 'Flip Vert',
                    isActive: frame.flipVertical,
                    onTap: () => _toggleFlip(false),
                  ),
                ],
              ),
            ] else if (_activeTab == _CropToolTab.straighten) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('FINE ROTATION', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${frame.straighten.toStringAsFixed(1)}°', style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: frame.straighten.clamp(-45.0, 45.0),
                min: -45.0,
                max: 45.0,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _targetFrame = frame.copyWith(straighten: val));
                  widget.controller.updateFrameTransformGeometry(frame.id, straighten: val);
                },
              ),
            ] else if (_activeTab == _CropToolTab.perspective) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('HORIZONTAL PERSPECTIVE', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${frame.perspectiveX.toStringAsFixed(1)}°', style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: frame.perspectiveX.clamp(-30.0, 30.0),
                min: -30.0,
                max: 30.0,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _targetFrame = frame.copyWith(perspectiveX: val));
                  widget.controller.updateFrameTransformGeometry(frame.id, perspectiveX: val);
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('VERTICAL PERSPECTIVE', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${frame.perspectiveY.toStringAsFixed(1)}°', style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: frame.perspectiveY.clamp(-30.0, 30.0),
                min: -30.0,
                max: 30.0,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _targetFrame = frame.copyWith(perspectiveY: val));
                  widget.controller.updateFrameTransformGeometry(frame.id, perspectiveY: val);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTab(String title, _CropToolTab tab) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAspectPresetChip(String label, double w, double h) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        backgroundColor: const Color(0xFF1E212E),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF2C3042)),
        ),
        onPressed: () => _applyAspectRatioCrop(w, h),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFF1E212E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primary : const Color(0xFF2C3042)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? AppColors.primaryLight : Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? AppColors.primaryLight : Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
