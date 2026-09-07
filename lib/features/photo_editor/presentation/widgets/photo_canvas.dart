import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/font_helper.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../domain/entities/drawing_stroke_entity.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../../domain/entities/photo_sticker_overlay_entity.dart';
import '../../domain/entities/photo_text_overlay_entity.dart';
import '../../domain/entities/watermark_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoCanvas extends StatefulWidget {
  final GlobalKey boundaryKey;
  final PhotoProjectEntity project;
  final PhotoEditorState state;
  final PhotoEditorController controller;

  const PhotoCanvas({
    super.key,
    required this.boundaryKey,
    required this.project,
    required this.state,
    required this.controller,
  });

  @override
  State<PhotoCanvas> createState() => _PhotoCanvasState();
}

class _PhotoCanvasState extends State<PhotoCanvas> {
  List<Offset> _currentStrokePoints = [];

  Widget _buildPhotoSlot(PhotoFrameEntity? frame, int slotIndex) {
    if (frame == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(widget.project.borderRadius),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate, color: Colors.white54, size: 28),
              SizedBox(height: 4),
              Text('Tap to add', style: TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
      );
    }

    final isSelected = widget.state.selectedFrameId == frame.id;

    Widget imageWidget;
    final path = frame.imagePath;

    if (path.startsWith('assets/')) {
      imageWidget = Image.asset(path, fit: BoxFit.cover);
    } else if (File(path).existsSync()) {
      imageWidget = Image.file(File(path), fit: BoxFit.cover, cacheWidth: 1080);
    } else {
      imageWidget = Container(
        color: AppColors.surfaceElevated,
        child: const Center(child: Icon(Icons.broken_image, color: Colors.white38)),
      );
    }

    final b = frame.brightness;
    final c = frame.contrast;
    final s = frame.saturation;
    final colorMatrix = <double>[
      c * s, 0, 0, 0, b * 255,
      0, c * s, 0, 0, b * 255,
      0, 0, c * s, 0, b * 255,
      0, 0, 0, 1, 0,
    ];

    imageWidget = ColorFiltered(
      colorFilter: ColorFilter.matrix(colorMatrix),
      child: imageWidget,
    );

    if (frame.filterType != FilterType.none) {
      final colorFilter = frame.filterType.getColorFilter(frame.filterIntensity);
      if (colorFilter != null) {
        imageWidget = ColorFiltered(
          colorFilter: colorFilter,
          child: imageWidget,
        );
      }
    }

    return GestureDetector(
      onTap: () => widget.controller.selectFrame(frame.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.project.borderRadius),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Transform.scale(
          scale: frame.scale,
          child: Transform.translate(
            offset: Offset(frame.offsetX, frame.offsetY),
            child: Transform.rotate(
              angle: frame.rotation,
              child: imageWidget,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridLayout() {
    final frames = widget.project.frames;
    final gap = widget.project.gapSpacing;

    switch (widget.project.collageLayout) {
      case CollageLayoutType.single:
        return Padding(
          padding: EdgeInsets.all(gap),
          child: _buildPhotoSlot(frames.isNotEmpty ? frames[0] : null, 0),
        );

      case CollageLayoutType.grid2Vertical:
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: _buildPhotoSlot(frames.isNotEmpty ? frames[0] : null, 0),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: _buildPhotoSlot(frames.length > 1 ? frames[1] : null, 1),
              ),
            ),
          ],
        );

      case CollageLayoutType.grid2Horizontal:
        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: _buildPhotoSlot(frames.isNotEmpty ? frames[0] : null, 0),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: _buildPhotoSlot(frames.length > 1 ? frames[1] : null, 1),
              ),
            ),
          ],
        );

      case CollageLayoutType.grid3Hero:
        return Column(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: _buildPhotoSlot(frames.isNotEmpty ? frames[0] : null, 0),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(gap),
                      child: _buildPhotoSlot(frames.length > 1 ? frames[1] : null, 1),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(gap),
                      child: _buildPhotoSlot(frames.length > 2 ? frames[2] : null, 2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case CollageLayoutType.grid4Quad:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(gap),
                      child: _buildPhotoSlot(frames.isNotEmpty ? frames[0] : null, 0),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(gap),
                      child: _buildPhotoSlot(frames.length > 1 ? frames[1] : null, 1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(gap),
                      child: _buildPhotoSlot(frames.length > 2 ? frames[2] : null, 2),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(gap),
                      child: _buildPhotoSlot(frames.length > 3 ? frames[3] : null, 3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case CollageLayoutType.grid6Grid:
        return Column(
          children: List.generate(2, (r) {
            return Expanded(
              child: Row(
                children: List.generate(3, (c) {
                  final idx = r * 3 + c;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(gap),
                      child: _buildPhotoSlot(frames.length > idx ? frames[idx] : null, idx),
                    ),
                  );
                }),
              ),
            );
          }),
        );

      case CollageLayoutType.grid9Grid:
        return Column(
          children: List.generate(3, (r) {
            return Expanded(
              child: Row(
                children: List.generate(3, (c) {
                  final idx = r * 3 + c;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(gap),
                      child: _buildPhotoSlot(frames.length > idx ? frames[idx] : null, idx),
                    ),
                  );
                }),
              ),
            );
          }),
        );
    }
  }

  Widget _buildWatermarkOverlay() {
    final wm = widget.project.watermark;
    if (!wm.isEnabled) return const SizedBox.shrink();

    Alignment align;
    switch (wm.position) {
      case WatermarkPosition.topLeft:
        align = Alignment.topLeft;
        break;
      case WatermarkPosition.topRight:
        align = Alignment.topRight;
        break;
      case WatermarkPosition.bottomLeft:
        align = Alignment.bottomLeft;
        break;
      case WatermarkPosition.bottomRight:
        align = Alignment.bottomRight;
        break;
      case WatermarkPosition.center:
        align = Alignment.center;
        break;
    }

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Opacity(
          opacity: wm.opacity,
          child: Transform.scale(
            scale: wm.scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: AppColors.accent, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    wm.text,
                    style: FontHelper.getTextStyle(
                      wm.fontFamily,
                      color: Color(wm.colorHex),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextOverlayItem(PhotoTextOverlayEntity item) {
    final isSelected = widget.state.selectedTextId == item.id;

    TextStyle baseStyle = FontHelper.getTextStyle(
      item.fontFamily,
      fontSize: item.fontSize,
      color: Color(item.colorHex),
      fontWeight: item.presetStyle == 'Bold' ? FontWeight.bold : FontWeight.normal,
    );
    if (item.presetStyle == 'Italic') {
      baseStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
    }

    if (item.presetStyle == 'Glow' || item.presetStyle == 'Neon') {
      baseStyle = baseStyle.copyWith(
        shadows: [
          Shadow(color: Color(item.colorHex), blurRadius: 15),
          Shadow(color: Color(item.colorHex), blurRadius: 30),
        ],
      );
    } else if (item.presetStyle == 'Shadow' || item.presetStyle == '3D') {
      baseStyle = baseStyle.copyWith(
        shadows: const [
          Shadow(color: Colors.black87, offset: Offset(3, 3), blurRadius: 6),
        ],
      );
    }

    return Positioned(
      left: item.positionX,
      top: item.positionY,
      child: GestureDetector(
        onTap: () => widget.controller.selectText(item.id),
        onPanUpdate: (details) {
          widget.controller.updateTextOverlay(
            item.copyWith(
              positionX: item.positionX + details.delta.dx,
              positionY: item.positionY + details.delta.dy,
            ),
          );
        },
        child: Transform.rotate(
          angle: item.rotation,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(item.text, style: baseStyle),
          ),
        ),
      ),
    );
  }

  Widget _buildStickerOverlayItem(PhotoStickerOverlayEntity item) {
    final isSelected = widget.state.selectedStickerId == item.id;

    Widget stickerChild;
    if (item.assetPath.startsWith('assets/')) {
      stickerChild = Image.asset(item.assetPath, width: 48, height: 48);
    } else {
      stickerChild = Text(item.assetPath, style: const TextStyle(fontSize: 42));
    }

    return Positioned(
      left: item.positionX,
      top: item.positionY,
      child: GestureDetector(
        onTap: () => widget.controller.selectSticker(item.id),
        onPanUpdate: (details) {
          widget.controller.updateStickerOverlay(
            item.copyWith(
              positionX: item.positionX + details.delta.dx,
              positionY: item.positionY + details.delta.dy,
            ),
          );
        },
        child: Transform.scale(
          scale: item.scale,
          child: Transform.rotate(
            angle: item.rotation,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primaryLight : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: stickerChild,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.project.aspectRatio.ratio;

    return Center(
      child: AspectRatio(
        aspectRatio: ratio,
        child: RepaintBoundary(
          key: widget.boundaryKey,
          child: Container(
            color: Color(widget.project.backgroundColorHex),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildGridLayout(),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: FreehandPainter(
                      savedStrokes: widget.project.drawingStrokes,
                      activePoints: _currentStrokePoints,
                      activeColor: widget.state.currentBrushColor,
                      activeWidth: widget.state.currentBrushSize,
                    ),
                  ),
                ),
                if (widget.state.isDrawMode)
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _currentStrokePoints = [details.localPosition];
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _currentStrokePoints.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        if (_currentStrokePoints.isNotEmpty) {
                          widget.controller.addDrawingStroke(
                            DrawingStrokeEntity(
                              points: List.from(_currentStrokePoints),
                              colorHex: widget.state.currentBrushColor.toARGB32(),
                              strokeWidth: widget.state.currentBrushSize,
                            ),
                          );
                          setState(() {
                            _currentStrokePoints = [];
                          });
                        }
                      },
                    ),
                  ),
                ...widget.project.stickerOverlays.map(_buildStickerOverlayItem),
                ...widget.project.textOverlays.map(_buildTextOverlayItem),
                _buildWatermarkOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FreehandPainter extends CustomPainter {
  final List<DrawingStrokeEntity> savedStrokes;
  final List<Offset> activePoints;
  final Color activeColor;
  final double activeWidth;

  FreehandPainter({
    required this.savedStrokes,
    required this.activePoints,
    required this.activeColor,
    required this.activeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in savedStrokes) {
      final paint = Paint()
        ..color = Color(stroke.colorHex)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    if (activePoints.isNotEmpty) {
      final paint = Paint()
        ..color = activeColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = activeWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < activePoints.length - 1; i++) {
        canvas.drawLine(activePoints[i], activePoints[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FreehandPainter oldDelegate) => true;
}
