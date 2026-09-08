import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../../domain/services/photo_autocut_service.dart';
import '../providers/photo_editor_controller.dart';

class PhotoAutoCutSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final String? selectedFrameId;
  final PhotoEditorController controller;

  const PhotoAutoCutSheet({
    super.key,
    required this.project,
    this.selectedFrameId,
    required this.controller,
  });

  @override
  State<PhotoAutoCutSheet> createState() => _PhotoAutoCutSheetState();
}

class _PhotoAutoCutSheetState extends State<PhotoAutoCutSheet> {
  final PhotoAutoCutService _service = PhotoAutoCutService();

  late PhotoFrameEntity? _targetFrame;
  img.Image? _loadedImage;
  Uint8List? _previewBytes;
  bool _isLoading = true;
  bool _isApplying = false;

  // Refinement brush state
  bool _isEraseMode = true; // true = Erase, false = Restore
  bool _isInverted = false;
  double _brushSize = 25.0; // in px
  final List<CutoutStroke> _strokes = [];
  final List<CutoutStroke> _redoStrokes = [];
  List<Offset> _currentPoints = [];

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

    final bytes = _service.generatePreviewBytes(
      original: _loadedImage!,
      strokes: _strokes,
      invert: _isInverted,
      featherRadius: 2,
      maxDimension: 480,
    );

    if (mounted) {
      setState(() => _previewBytes = bytes);
    }
  }

  void _undoStroke() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStrokes.add(_strokes.removeLast());
    });
    _refreshPreview();
  }

  void _redoStroke() {
    if (_redoStrokes.isEmpty) return;
    setState(() {
      _strokes.add(_redoStrokes.removeLast());
    });
    _refreshPreview();
  }

  void _toggleInvert() {
    setState(() {
      _isInverted = !_isInverted;
    });
    _refreshPreview();
  }

  Future<void> _applyCutout() async {
    if (_targetFrame == null || _isApplying) return;

    setState(() => _isApplying = true);
    try {
      final result = await _service.renderCutout(
        imagePath: _targetFrame!.imagePath,
        strokes: _strokes,
        invert: _isInverted,
        featherRadius: 2,
      );

      if (result != null && mounted) {
        widget.controller.replacePhotoFrame(_targetFrame!.id, result.outputPath);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject cutout applied successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AutoCut failed: $e')),
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
              'Add a photo to perform automatic cutout',
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
        height: MediaQuery.of(context).size.height * 0.85,
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
            // Header with Undo / Redo & Invert
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.content_cut, color: AppColors.primaryLight, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AutoCut & Refine',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.undo, size: 20, color: _strokes.isNotEmpty ? Colors.white : Colors.white24),
                  tooltip: 'Undo Stroke',
                  onPressed: _strokes.isNotEmpty ? _undoStroke : null,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.redo, size: 20, color: _redoStrokes.isNotEmpty ? Colors.white : Colors.white24),
                  tooltip: 'Redo Stroke',
                  onPressed: _redoStrokes.isNotEmpty ? _redoStroke : null,
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

            // Interactive Cutout Canvas Viewport
            Expanded(
              flex: 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF181B26),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          else if (_previewBytes != null)
                            Center(child: Image.memory(_previewBytes!, fit: BoxFit.contain)),

                          // Interactive Gesture Layer for Erase/Restore brush strokes
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              final w = constraints.maxWidth;
                              final h = constraints.maxHeight;
                              final nx = (details.localPosition.dx / w).clamp(0.0, 1.0);
                              final ny = (details.localPosition.dy / h).clamp(0.0, 1.0);
                              setState(() {
                                _currentPoints = [Offset(nx, ny)];
                              });
                            },
                            onPanUpdate: (details) {
                              final w = constraints.maxWidth;
                              final h = constraints.maxHeight;
                              final nx = (details.localPosition.dx / w).clamp(0.0, 1.0);
                              final ny = (details.localPosition.dy / h).clamp(0.0, 1.0);
                              setState(() {
                                _currentPoints.add(Offset(nx, ny));
                              });
                            },
                            onPanEnd: (_) {
                              if (_currentPoints.isNotEmpty) {
                                final normRadius = (_brushSize / constraints.maxWidth).clamp(0.01, 0.25);
                                setState(() {
                                  _strokes.add(
                                    CutoutStroke(
                                      points: List.from(_currentPoints),
                                      isErase: _isEraseMode,
                                      radius: normRadius,
                                    ),
                                  );
                                  _redoStrokes.clear();
                                  _currentPoints = [];
                                });
                                _refreshPreview();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Refinement Controls & Mode Toggle
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Selector: Erase vs Restore vs Invert
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cleaning_services, size: 16),
                            label: const Text('Erase BG'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEraseMode ? AppColors.accentRose : const Color(0xFF1E212E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => setState(() => _isEraseMode = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.brush, size: 16),
                            label: const Text('Restore Subject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isEraseMode ? AppColors.success : const Color(0xFF1E212E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => setState(() => _isEraseMode = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.swap_horiz, color: _isInverted ? AppColors.primary : Colors.white70),
                          tooltip: 'Invert Cutout',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1E212E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _toggleInvert,
                        ),
                      ],
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
                        activeTrackColor: _isEraseMode ? AppColors.accentRose : AppColors.success,
                        inactiveTrackColor: const Color(0xFF272B3B),
                        thumbColor: _isEraseMode ? AppColors.accentRose : AppColors.success,
                        overlayColor: (_isEraseMode ? AppColors.accentRose : AppColors.success).withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _brushSize,
                        min: 8.0,
                        max: 70.0,
                        onChanged: (val) => setState(() => _brushSize = val),
                      ),
                    ),

                    Text(
                      _isEraseMode
                          ? 'Tip: Paint over background areas to erase unwanted remnants.'
                          : 'Tip: Paint over subject areas to restore clipped details.',
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
                  _isApplying ? 'Finalizing Cutout...' : 'Apply Cutout',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isApplying ? null : _applyCutout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
