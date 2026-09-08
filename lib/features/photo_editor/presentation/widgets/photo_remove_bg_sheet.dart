import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../../domain/services/photo_bg_remover_service.dart';
import '../providers/photo_editor_controller.dart';

class PhotoRemoveBgSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final String? selectedFrameId;
  final PhotoEditorController controller;

  const PhotoRemoveBgSheet({
    super.key,
    required this.project,
    this.selectedFrameId,
    required this.controller,
  });

  @override
  State<PhotoRemoveBgSheet> createState() => _PhotoRemoveBgSheetState();
}

enum _BackdropType { transparent, white, black, gray, gradientWarm, gradientCool }

class _PhotoRemoveBgSheetState extends State<PhotoRemoveBgSheet> {
  final PhotoBgRemoverService _service = PhotoBgRemoverService();

  late PhotoFrameEntity? _targetFrame;
  img.Image? _loadedImage;
  Uint8List? _previewBytes;
  bool _isLoading = true;
  bool _isApplying = false;

  double _sensitivity = 0.5; // 0.0 to 1.0
  int _featherRadius = 2; // 0 to 8 px
  _BackdropType _backdrop = _BackdropType.transparent;
  img.Color? _sampledColor;

  @override
  void initState() {
    super.initState();
    _resolveFrame();
    _loadImage();
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

  Future<void> _loadImage() async {
    if (_targetFrame == null || _targetFrame!.imagePath.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final decoded = await _service.loadImage(_targetFrame!.imagePath);
    if (!mounted) return;

    setState(() {
      _loadedImage = decoded;
      _isLoading = false;
    });

    _refreshPreview();
  }

  void _refreshPreview() {
    if (_loadedImage == null) return;

    img.Color? repColor;
    if (_backdrop == _BackdropType.white) {
      repColor = img.ColorRgba8(255, 255, 255, 255);
    } else if (_backdrop == _BackdropType.black) {
      repColor = img.ColorRgba8(18, 18, 22, 255);
    } else if (_backdrop == _BackdropType.gray) {
      repColor = img.ColorRgba8(128, 130, 140, 255);
    }

    final bytes = _service.generatePreviewBytes(
      original: _loadedImage!,
      sensitivity: _sensitivity,
      featherRadius: _featherRadius,
      sampleColor: _sampledColor,
      replacementColor: repColor,
      maxDimension: 480,
    );

    if (mounted) {
      setState(() {
        _previewBytes = bytes;
      });
    }
  }

  Future<void> _applyBackgroundRemoval() async {
    if (_targetFrame == null || _isApplying) return;

    setState(() => _isApplying = true);
    try {
      img.Color? repColor;
      if (_backdrop == _BackdropType.white) {
        repColor = img.ColorRgba8(255, 255, 255, 255);
      } else if (_backdrop == _BackdropType.black) {
        repColor = img.ColorRgba8(18, 18, 22, 255);
      } else if (_backdrop == _BackdropType.gray) {
        repColor = img.ColorRgba8(128, 130, 140, 255);
      }

      final result = await _service.removeBackground(
        imagePath: _targetFrame!.imagePath,
        sensitivity: _sensitivity,
        featherRadius: _featherRadius,
        sampleColor: _sampledColor,
        replacementColor: repColor,
      );

      if (result != null && mounted) {
        widget.controller.replacePhotoFrame(_targetFrame!.id, result.outputPath);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background removed successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Background removal failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
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
              'Add a photo to remove background',
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
        height: MediaQuery.of(context).size.height * 0.82,
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
                  child: const Icon(Icons.layers_clear, color: AppColors.primaryLight, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Remove Background',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Live Cutout Preview Box with checkerboard or gradient
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  decoration: _buildPreviewDecoration(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_backdrop == _BackdropType.transparent)
                        const CustomPaint(painter: CheckerboardPainter()),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      else if (_previewBytes != null)
                        Center(child: Image.memory(_previewBytes!, fit: BoxFit.contain))
                      else
                        const Center(
                          child: Text('Unable to preview image', style: TextStyle(color: Colors.white54)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Controls
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Backdrop Selector Chips
                    Text(
                      'BACKDROP',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildBackdropChip('Transparent', _BackdropType.transparent, Icons.grid_on),
                          _buildBackdropChip('White', _BackdropType.white, Icons.circle, iconColor: Colors.white),
                          _buildBackdropChip('Black', _BackdropType.black, Icons.circle, iconColor: Colors.black87),
                          _buildBackdropChip('Studio Gray', _BackdropType.gray, Icons.circle, iconColor: Colors.grey),
                          _buildBackdropChip('Warm Sky', _BackdropType.gradientWarm, Icons.gradient),
                          _buildBackdropChip('Neon Night', _BackdropType.gradientCool, Icons.gradient),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sensitivity Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SENSITIVITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        Text('${(_sensitivity * 100).round()}%', style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
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
                        value: _sensitivity,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          setState(() => _sensitivity = val);
                          _refreshPreview();
                        },
                      ),
                    ),

                    // Edge Smoothness / Feathering
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('EDGE SMOOTHNESS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        Text('${_featherRadius}px', style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
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
                        value: _featherRadius.toDouble(),
                        min: 0,
                        max: 6,
                        divisions: 6,
                        onChanged: (val) {
                          setState(() => _featherRadius = val.round());
                          _refreshPreview();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: _isApplying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, color: Colors.white, size: 20),
                label: Text(
                  _isApplying ? 'Processing Cutout...' : 'Apply Background Removal',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isApplying ? null : _applyBackgroundRemoval,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildPreviewDecoration() {
    switch (_backdrop) {
      case _BackdropType.transparent:
        return const BoxDecoration(color: Colors.transparent);
      case _BackdropType.white:
        return const BoxDecoration(color: Colors.white);
      case _BackdropType.black:
        return const BoxDecoration(color: Color(0xFF0F1015));
      case _BackdropType.gray:
        return const BoxDecoration(color: Color(0xFF6B7280));
      case _BackdropType.gradientWarm:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case _BackdropType.gradientCool:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }

  Widget _buildBackdropChip(String label, _BackdropType type, IconData icon, {Color? iconColor}) {
    final isSelected = _backdrop == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : (iconColor ?? AppColors.textSecondary)),
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _backdrop = type);
          _refreshPreview();
        },
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
}

class CheckerboardPainter extends CustomPainter {
  final double squareSize;
  const CheckerboardPainter({this.squareSize = 12.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFF161822);
    final paint2 = Paint()..color = const Color(0xFF232736);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        if (((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint2);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
