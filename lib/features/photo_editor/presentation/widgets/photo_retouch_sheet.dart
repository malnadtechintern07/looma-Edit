import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../../domain/services/photo_retouch_service.dart';
import '../providers/photo_editor_controller.dart';

class PhotoRetouchSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final String? selectedFrameId;
  final PhotoEditorController controller;

  const PhotoRetouchSheet({
    super.key,
    required this.project,
    this.selectedFrameId,
    required this.controller,
  });

  @override
  State<PhotoRetouchSheet> createState() => _PhotoRetouchSheetState();
}

class _PhotoRetouchSheetState extends State<PhotoRetouchSheet> {
  final PhotoRetouchService _service = PhotoRetouchService();
  final TransformationController _transController = TransformationController();

  late PhotoFrameEntity? _targetFrame;
  img.Image? _loadedImage;
  Uint8List? _previewBytes;
  Uint8List? _originalBytes;
  bool _isLoading = true;
  bool _isApplying = false;
  bool _isComparing = false;
  bool _isPanZoomMode = false; // When true, touches pan/zoom; when false, touches paint retouch strokes

  RetouchMode _activeMode = RetouchMode.blemish;
  double _brushSize = 22.0; // px
  double _intensity = 0.65; // 0.0 to 1.0

  final List<RetouchStroke> _strokes = [];
  final List<RetouchStroke> _redoStrokes = [];
  List<Offset> _currentPoints = [];
  Offset? _hoverPoint;

  @override
  void initState() {
    super.initState();
    _resolveFrame();
    _loadImage();
  }

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
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

    final origBytes = Uint8List.fromList(img.encodePng(decoded!));

    setState(() {
      _loadedImage = decoded;
      _originalBytes = origBytes;
      _isLoading = false;
    });

    _refreshPreview();
  }

  void _refreshPreview() {
    if (_loadedImage == null) return;

    if (_strokes.isEmpty) {
      setState(() => _previewBytes = _originalBytes);
      return;
    }

    final bytes = _service.generatePreviewBytes(
      original: _loadedImage!,
      strokes: _strokes,
      maxDimension: 640,
    );

    if (mounted) {
      setState(() => _previewBytes = bytes);
    }
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStrokes.add(_strokes.removeLast());
    });
    _refreshPreview();
  }

  void _redo() {
    if (_redoStrokes.isEmpty) return;
    setState(() {
      _strokes.add(_redoStrokes.removeLast());
    });
    _refreshPreview();
  }

  Future<void> _applyRetouch() async {
    if (_targetFrame == null || _strokes.isEmpty || _isApplying) return;

    setState(() => _isApplying = true);
    try {
      final result = await _service.applyRetouch(
        imagePath: _targetFrame!.imagePath,
        strokes: _strokes,
      );

      if (result != null && mounted) {
        widget.controller.replacePhotoFrame(_targetFrame!.id, result.outputPath);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retouch applied successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retouch failed: $e')),
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
              'Add a photo to use professional retouch tools',
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
        height: MediaQuery.of(context).size.height * 0.88,
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
            // Header with Compare, Undo, Redo, Pan/Zoom
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.face_retouching_natural, color: AppColors.primaryLight, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Retouch Studio',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Hold to Compare
                GestureDetector(
                  onTapDown: (_) => setState(() => _isComparing = true),
                  onTapUp: (_) => setState(() => _isComparing = false),
                  onTapCancel: () => setState(() => _isComparing = false),
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
                  icon: Icon(Icons.pan_tool, size: 18, color: _isPanZoomMode ? AppColors.primary : Colors.white60),
                  tooltip: _isPanZoomMode ? 'Zooming Mode (Tap to Brush)' : 'Brush Mode (Tap to Pan/Zoom)',
                  style: IconButton.styleFrom(
                    backgroundColor: _isPanZoomMode ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  ),
                  onPressed: () => setState(() => _isPanZoomMode = !_isPanZoomMode),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.undo, size: 18, color: _strokes.isNotEmpty ? Colors.white : Colors.white24),
                  tooltip: 'Undo',
                  onPressed: _strokes.isNotEmpty ? _undo : null,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.redo, size: 18, color: _redoStrokes.isNotEmpty ? Colors.white : Colors.white24),
                  tooltip: 'Redo',
                  onPressed: _redoStrokes.isNotEmpty ? _redo : null,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Canvas Viewport with Brush cursor
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF181B26),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final displayBytes = _isComparing ? _originalBytes : (_previewBytes ?? _originalBytes);

                      Widget content = Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          else if (displayBytes != null)
                            Center(child: Image.memory(displayBytes, fit: BoxFit.contain)),

                          // Paint gesture layer
                          if (!_isPanZoomMode)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                final w = constraints.maxWidth;
                                final h = constraints.maxHeight;
                                final nx = (details.localPosition.dx / w).clamp(0.0, 1.0);
                                final ny = (details.localPosition.dy / h).clamp(0.0, 1.0);
                                setState(() {
                                  _hoverPoint = details.localPosition;
                                  _currentPoints = [Offset(nx, ny)];
                                });
                              },
                              onPanUpdate: (details) {
                                final w = constraints.maxWidth;
                                final h = constraints.maxHeight;
                                final nx = (details.localPosition.dx / w).clamp(0.0, 1.0);
                                final ny = (details.localPosition.dy / h).clamp(0.0, 1.0);
                                setState(() {
                                  _hoverPoint = details.localPosition;
                                  _currentPoints.add(Offset(nx, ny));
                                });
                              },
                              onPanEnd: (_) {
                                if (_currentPoints.isNotEmpty) {
                                  final normRadius = (_brushSize / constraints.maxWidth).clamp(0.01, 0.25);
                                  setState(() {
                                    _strokes.add(
                                      RetouchStroke(
                                        mode: _activeMode,
                                        points: List.from(_currentPoints),
                                        radius: normRadius,
                                        intensity: _intensity,
                                      ),
                                    );
                                    _redoStrokes.clear();
                                    _currentPoints = [];
                                    _hoverPoint = null;
                                  });
                                  _refreshPreview();
                                }
                              },
                            ),

                          // Live circular brush cursor overlay
                          if (_hoverPoint != null && !_isPanZoomMode)
                            Positioned(
                              left: _hoverPoint!.dx - _brushSize / 2,
                              top: _hoverPoint!.dy - _brushSize / 2,
                              child: IgnorePointer(
                                child: Container(
                                  width: _brushSize,
                                  height: _brushSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _getModeColor(_activeMode),
                                      width: 2,
                                    ),
                                    color: _getModeColor(_activeMode).withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );

                      if (_isPanZoomMode) {
                        return InteractiveViewer(
                          transformationController: _transController,
                          minScale: 1.0,
                          maxScale: 6.0,
                          child: content,
                        );
                      }
                      return content;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Controls & Tool selection
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tool Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildToolTab(RetouchMode.blemish, 'Blemish Heal', Icons.healing),
                          _buildToolTab(RetouchMode.smooth, 'Smooth Skin', Icons.blur_on),
                          _buildToolTab(RetouchMode.brighten, 'Brighten (Dodge)', Icons.wb_sunny_outlined),
                          _buildToolTab(RetouchMode.darken, 'Darken (Burn)', Icons.nightlight_round),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Brush Size Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BRUSH SIZE', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        Text('${_brushSize.round()} px', style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _getModeColor(_activeMode),
                        inactiveTrackColor: const Color(0xFF272B3B),
                        thumbColor: _getModeColor(_activeMode),
                        overlayColor: _getModeColor(_activeMode).withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _brushSize,
                        min: 8.0,
                        max: 65.0,
                        onChanged: (val) => setState(() => _brushSize = val),
                      ),
                    ),

                    // Strength / Intensity Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('INTENSITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        Text('${(_intensity * 100).round()}%', style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _getModeColor(_activeMode),
                        inactiveTrackColor: const Color(0xFF272B3B),
                        thumbColor: _getModeColor(_activeMode),
                        overlayColor: _getModeColor(_activeMode).withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _intensity,
                        min: 0.1,
                        max: 1.0,
                        onChanged: (val) => setState(() => _intensity = val),
                      ),
                    ),

                    Text(
                      _getToolDescription(_activeMode),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
                  _isApplying ? 'Applying Retouch...' : 'Apply Retouch (${_strokes.length} edits)',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _strokes.isEmpty || _isApplying ? null : _applyRetouch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTab(RetouchMode mode, String label, IconData icon) {
    final isSelected = _activeMode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _activeMode = mode),
        selectedColor: _getModeColor(mode),
        backgroundColor: const Color(0xFF1E212E),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Color _getModeColor(RetouchMode mode) {
    switch (mode) {
      case RetouchMode.blemish:
        return const Color(0xFFFF3B5C);
      case RetouchMode.smooth:
        return const Color(0xFF00C2CB);
      case RetouchMode.brighten:
        return const Color(0xFFFFB800);
      case RetouchMode.darken:
        return const Color(0xFF8B5CF6);
    }
  }

  String _getToolDescription(RetouchMode mode) {
    switch (mode) {
      case RetouchMode.blemish:
        return 'Tap or paint over spots, marks, or acne to seamlessly heal with surrounding skin.';
      case RetouchMode.smooth:
        return 'Brush gently over skin to soften pores and wrinkles while preserving facial edges.';
      case RetouchMode.brighten:
        return 'Brush over teeth, eyes, or under-eye circles to naturally brighten and illuminate.';
      case RetouchMode.darken:
        return 'Brush over eyebrows, hair edges, or cheekbones to deepen contrast and contours.';
    }
  }
}
