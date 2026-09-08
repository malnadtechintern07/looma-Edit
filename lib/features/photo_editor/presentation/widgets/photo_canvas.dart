import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
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
  final void Function(int slotIndex)? onImportSlot;
  final void Function(PhotoTextOverlayEntity text)? onEditText;

  const PhotoCanvas({
    super.key,
    required this.boundaryKey,
    required this.project,
    required this.state,
    required this.controller,
    this.onImportSlot,
    this.onEditText,
  });

  @override
  State<PhotoCanvas> createState() => _PhotoCanvasState();
}

class _PhotoCanvasState extends State<PhotoCanvas> {
  final TransformationController _transController = TransformationController();
  List<Offset> _currentStrokePoints = [];
  double _currentZoom = 1.0;

  // Gesture tracking for multi-touch scale, rotate and single-finger drag
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;
  Offset _baseFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transController.removeListener(_onTransformChanged);
    _transController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transController.value.getMaxScaleOnAxis();
    if ((scale - _currentZoom).abs() > 0.05) {
      setState(() {
        _currentZoom = scale;
      });
      widget.controller.setZoomScale(scale);
    }
  }

  void _resetZoom() {
    setState(() {
      _transController.value = Matrix4.identity();
      _currentZoom = 1.0;
    });
    widget.controller.setZoomScale(1.0);
  }

  /// Calculates a comprehensive ColorFilter matrix incorporating all light & tone adjustments
  List<double> _buildColorMatrix(PhotoFrameEntity frame) {
    if (widget.state.isComparing) {
      // Unedited identity matrix for Before/After compare
      return const <double>[
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ];
    }

    // 1. Exposure factor: 2^exposure
    final expFactor = pow(2.0, frame.exposure).toDouble();

    // 2. Contrast: c in [0.5, 2.0]
    final c = frame.contrast * expFactor;
    final cOffset = 128.0 * (1.0 - frame.contrast);

    // 3. Brightness offset: -255 to +255
    final bOffset = frame.brightness * 255.0;

    // 4. Saturation & Vibrance
    final totalSat = (frame.saturation * (1.0 + frame.vibrance * 0.5)).clamp(0.0, 3.0);
    final rw = 0.2126 * (1.0 - totalSat);
    final gw = 0.7152 * (1.0 - totalSat);
    final bw = 0.0722 * (1.0 - totalSat);

    // 5. Temperature (warm = +R, -B) and Tint (green/magenta = +G vs +R/B)
    final tempR = frame.temperature > 0 ? (frame.temperature * 30.0) : 0.0;
    final tempB = frame.temperature < 0 ? (-frame.temperature * 30.0) : 0.0;
    final tintG = frame.tint > 0 ? (frame.tint * 25.0) : 0.0;
    final tintM = frame.tint < 0 ? (-frame.tint * 25.0) : 0.0;

    // 6. Fade (matte lift on black levels)
    final fadeOffset = frame.fade * 45.0;

    final rOffset = bOffset + cOffset + tempR + tintM + fadeOffset;
    final gOffset = bOffset + cOffset + tintG + fadeOffset;
    final bOffsetFinal = bOffset + cOffset + tempB + tintM + fadeOffset;

    return <double>[
      (rw + totalSat) * c, gw * c, bw * c, 0, rOffset,
      rw * c, (gw + totalSat) * c, bw * c, 0, gOffset,
      rw * c, gw * c, (bw + totalSat) * c, 0, bOffsetFinal,
      0, 0, 0, 1, 0,
    ];
  }

  Widget _buildPhotoSlot(PhotoFrameEntity? frame, int slotIndex) {
    if (frame == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onImportSlot?.call(slotIndex),
          borderRadius: BorderRadius.circular(widget.project.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(widget.project.borderRadius),
              border: Border.all(color: Colors.white30, width: 1.5),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_photo_alternate, color: Colors.white70, size: 30),
                  SizedBox(height: 6),
                  Text(
                    'Tap to add',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isSelected = widget.state.selectedFrameId == frame.id;
    final isComparing = widget.state.isComparing;

    Widget imageWidget;
    final path = frame.imagePath;

    if (path.startsWith('assets/')) {
      imageWidget = Image.asset(path, fit: BoxFit.cover);
    } else if (File(path).existsSync()) {
      imageWidget = Image.file(File(path), fit: BoxFit.cover, cacheWidth: 1440);
    } else {
      imageWidget = Container(
        color: AppColors.surfaceElevated,
        child: const Center(child: Icon(Icons.broken_image, color: Colors.white38)),
      );
    }

    // 1. Apply Light & Color Grading Matrix
    imageWidget = ColorFiltered(
      colorFilter: ColorFilter.matrix(_buildColorMatrix(frame)),
      child: imageWidget,
    );

    // 2. Apply Preset Color Filter (if active and not in compare mode)
    if (!isComparing && frame.filterType != FilterType.none) {
      final colorFilter = frame.filterType.getColorFilter(frame.filterIntensity);
      if (colorFilter != null) {
        imageWidget = ColorFiltered(
          colorFilter: colorFilter,
          child: imageWidget,
        );
      }
    }

    // 3. Apply Gaussian Blur effect (if active and not comparing)
    if (!isComparing && frame.blur > 0.1) {
      imageWidget = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: frame.blur, sigmaY: frame.blur),
        child: imageWidget,
      );
    }

    // 4. Apply Vignette shader mask (if active and not comparing)
    if (!isComparing && frame.vignette > 0.05) {
      imageWidget = ShaderMask(
        shaderCallback: (bounds) {
          return RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: frame.vignette.clamp(0.0, 0.95)),
            ],
            stops: const [0.4, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcOver,
        child: imageWidget,
      );
    }

    // 5. Apply Film Grain noise overlay (if active and not comparing)
    if (!isComparing && frame.grain > 0.05) {
      imageWidget = Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          CustomPaint(
            painter: FilmGrainPainter(intensity: frame.grain),
          ),
        ],
      );
    }

    // 6. Build 3D Transform Matrix (scale, translation, 90 deg rotation, straighten, perspective tilt, flip H/V)
    final radiansStraighten = frame.straighten * (pi / 180.0);
    final radiansPerspX = frame.perspectiveX * (pi / 180.0);
    final radiansPerspY = frame.perspectiveY * (pi / 180.0);

    final transformMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective depth
      ..rotateX(radiansPerspY)
      ..rotateY(radiansPerspX)
      ..rotateZ(frame.rotation + radiansStraighten)
      ..multiply(
        Matrix4.diagonal3Values(
          frame.flipHorizontal ? -frame.scale : frame.scale,
          frame.flipVertical ? -frame.scale : frame.scale,
          1.0,
        ),
      );

    Widget transformedChild = Transform(
      transform: transformMatrix,
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(frame.offsetX, frame.offsetY),
        child: imageWidget,
      ),
    );

    // 7. Apply Crop rect (if cropped)
    final isCropped = frame.cropLeft > 0.001 ||
        frame.cropTop > 0.001 ||
        frame.cropRight < 0.999 ||
        frame.cropBottom < 0.999;

    if (isCropped && !isComparing) {
      transformedChild = ClipRect(
        clipper: _CropRectClipper(
          cropLeft: frame.cropLeft,
          cropTop: frame.cropTop,
          cropRight: frame.cropRight,
          cropBottom: frame.cropBottom,
        ),
        child: transformedChild,
      );
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
        child: transformedChild,
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

  Widget _buildBackground() {
    final bgType = widget.project.backgroundType;

    if (bgType == 'gradient') {
      final colors = widget.project.gradientColorsHex.map(Color.new).toList();
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors.length >= 2 ? colors : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    } else if (bgType == 'blur' && widget.project.frames.isNotEmpty) {
      final path = widget.project.frames.first.imagePath;
      Widget blurImg;
      if (path.startsWith('assets/')) {
        blurImg = Image.asset(path, fit: BoxFit.cover);
      } else if (File(path).existsSync()) {
        blurImg = Image.file(File(path), fit: BoxFit.cover);
      } else {
        blurImg = Container(color: Color(widget.project.backgroundColorHex));
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: widget.project.blurBackgroundRadius,
              sigmaY: widget.project.blurBackgroundRadius,
            ),
            child: Transform.scale(scale: 1.3, child: blurImg),
          ),
          Container(color: Colors.black.withValues(alpha: 0.3)),
        ],
      );
    } else if (bgType == 'transparent') {
      return const CustomPaint(painter: CheckerboardBackgroundPainter());
    }

    return Container(color: Color(widget.project.backgroundColorHex));
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

    TextAlign align;
    switch (item.textAlign) {
      case 'left':
        align = TextAlign.left;
        break;
      case 'right':
        align = TextAlign.right;
        break;
      default:
        align = TextAlign.center;
    }

    TextStyle baseStyle = FontHelper.getTextStyle(
      item.fontFamily,
      fontSize: item.fontSize,
      color: Color(item.colorHex).withValues(alpha: item.opacity),
      letterSpacing: item.letterSpacing,
      height: item.lineHeight,
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
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.controller.selectText(item.id),
        onDoubleTap: () => widget.onEditText?.call(item),
        onScaleStart: (details) {
          _baseScale = item.scale;
          _baseRotation = item.rotation;
          _basePosition = Offset(item.positionX, item.positionY);
          _baseFocalPoint = details.focalPoint;
        },
        onScaleUpdate: (details) {
          if (details.pointerCount >= 2) {
            // Multi-touch pinch-to-zoom & two-finger rotate!
            final newScale = (_baseScale * details.scale).clamp(0.2, 5.0);
            final newRotation = _baseRotation + details.rotation;
            final delta = details.focalPoint - _baseFocalPoint;
            widget.controller.updateTextOverlay(
              item.copyWith(
                scale: newScale,
                rotation: newRotation,
                positionX: _basePosition.dx + delta.dx,
                positionY: _basePosition.dy + delta.dy,
              ),
            );
          } else {
            // Single-finger drag to reposition
            final delta = details.focalPoint - _baseFocalPoint;
            widget.controller.updateTextOverlay(
              item.copyWith(
                positionX: _basePosition.dx + delta.dx,
                positionY: _basePosition.dy + delta.dy,
              ),
            );
          }
        },
        child: Transform.scale(
          scale: item.scale,
          child: Transform.rotate(
            angle: item.rotation,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.backgroundColorHex != null ? Color(item.backgroundColorHex!) : null,
                    border: Border.all(
                      color: isSelected ? AppColors.primaryLight : Colors.transparent,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.text, style: baseStyle, textAlign: align),
                ),
                if (isSelected) ...[
                  // Top-Left: Edit Handle
                  Positioned(
                    top: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: () => widget.onEditText?.call(item),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  // Top-Right: Delete Handle
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => widget.controller.removeTextOverlay(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accentRose,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  // Bottom-Right: Rotate & Scale Handle (Single finger drag)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final scaleDelta = (details.delta.dx + details.delta.dy) * 0.01;
                        final newScale = (item.scale + scaleDelta).clamp(0.25, 5.0);
                        final newRotation = item.rotation + (details.delta.dx - details.delta.dy) * 0.015;
                        widget.controller.updateTextOverlay(
                          item.copyWith(
                            scale: newScale,
                            rotation: newRotation,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.crop_rotate, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickerOverlayItem(PhotoStickerOverlayEntity item) {
    final isSelected = widget.state.selectedStickerId == item.id;

    Widget stickerChild;
    if (item.isShape) {
      stickerChild = _buildShapeWidget(item);
    } else if (item.assetPath.startsWith('assets/')) {
      stickerChild = Image.asset(item.assetPath, width: 52, height: 52);
    } else {
      stickerChild = Text(item.assetPath, style: const TextStyle(fontSize: 44));
    }

    return Positioned(
      left: item.positionX,
      top: item.positionY,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.controller.selectSticker(item.id),
        onScaleStart: (details) {
          _baseScale = item.scale;
          _baseRotation = item.rotation;
          _basePosition = Offset(item.positionX, item.positionY);
          _baseFocalPoint = details.focalPoint;
        },
        onScaleUpdate: (details) {
          if (details.pointerCount >= 2) {
            // Multi-touch pinch-to-zoom & two-finger rotate!
            final newScale = (_baseScale * details.scale).clamp(0.2, 5.0);
            final newRotation = _baseRotation + details.rotation;
            final delta = details.focalPoint - _baseFocalPoint;
            widget.controller.updateStickerOverlay(
              item.copyWith(
                scale: newScale,
                rotation: newRotation,
                positionX: _basePosition.dx + delta.dx,
                positionY: _basePosition.dy + delta.dy,
              ),
            );
          } else {
            // Single-finger drag to reposition
            final delta = details.focalPoint - _baseFocalPoint;
            widget.controller.updateStickerOverlay(
              item.copyWith(
                positionX: _basePosition.dx + delta.dx,
                positionY: _basePosition.dy + delta.dy,
              ),
            );
          }
        },
        child: Opacity(
          opacity: item.opacity,
          child: Transform.scale(
            scale: item.scale,
            child: Transform.rotate(
              angle: item.rotation,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primaryLight : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: stickerChild,
                  ),
                  if (isSelected) ...[
                    // Top-Right: Delete Handle
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => widget.controller.removeStickerOverlay(item.id),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.accentRose,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    // Bottom-Right: Rotate & Scale Handle
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          final scaleDelta = (details.delta.dx + details.delta.dy) * 0.01;
                          final newScale = (item.scale + scaleDelta).clamp(0.25, 5.0);
                          final newRotation = item.rotation + (details.delta.dx - details.delta.dy) * 0.015;
                          widget.controller.updateStickerOverlay(
                            item.copyWith(
                              scale: newScale,
                              rotation: newRotation,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.crop_rotate, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeWidget(PhotoStickerOverlayEntity item) {
    final color = Color(item.colorHex);
    final size = 56.0;

    switch (item.shapeType) {
      case 'circle':
        return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
      case 'rect':
        return Container(width: size, height: size * 0.7, color: color);
      case 'roundedRect':
        return Container(width: size, height: size * 0.7, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)));
      case 'star':
        return Icon(Icons.star, color: color, size: size);
      case 'heart':
        return Icon(Icons.favorite, color: color, size: size);
      case 'arrow':
        return Icon(Icons.arrow_forward_rounded, color: color, size: size);
      case 'speechBubble':
        return Icon(Icons.chat_bubble_rounded, color: color, size: size);
      default:
        return Container(width: size, height: size, color: color);
    }
  }

  Widget? _buildSelectedTextToolbar() {
    final textId = widget.state.selectedTextId;
    if (textId == null) return null;
    final overlays = widget.project.textOverlays.where((t) => t.id == textId);
    if (overlays.isEmpty) return null;
    final item = overlays.first;

    const colors = [
      0xFFFFFFFF, // White
      0xFF111827, // Charcoal
      0xFFFF3B5C, // Neon Rose
      0xFF00C2CB, // Cyan
      0xFFFFB800, // Gold
      0xFF8B5CF6, // Purple
      0xFF10B981, // Emerald
      0xFF3B82F6, // Blue
      0xFFEF4444, // Red
    ];

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1E2B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.palette, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                ...colors.map((c) {
                  final isCurrent = item.colorHex == c;
                  return GestureDetector(
                    onTap: () {
                      widget.controller.updateTextOverlay(item.copyWith(colorHex: c));
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : (c == 0xFFFFFFFF ? Colors.grey : Colors.black45),
                          width: isCurrent ? 2.5 : 1,
                        ),
                      ),
                      child: isCurrent
                          ? Icon(Icons.check, size: 12, color: c == 0xFFFFFFFF || c == 0xFFFFB800 ? Colors.black : Colors.white)
                          : null,
                    ),
                  );
                }),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => widget.onEditText?.call(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Edit', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.project.aspectRatio.ratio;

    Widget canvasStack = AspectRatio(
      aspectRatio: ratio,
      child: RepaintBoundary(
        key: widget.boundaryKey,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.project.borderRadius),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _buildBackground()),
              Positioned.fill(child: _buildGridLayout()),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: FreehandPainter(
                      savedStrokes: widget.project.drawingStrokes,
                      activePoints: _currentStrokePoints,
                      activeColor: widget.state.currentBrushColor,
                      activeWidth: widget.state.currentBrushSize,
                      brushType: widget.state.brushType,
                      brushOpacity: widget.state.brushOpacity,
                    ),
                  ),
                ),
              ),
              if (widget.state.isDrawMode)
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: (details) {
                      if (widget.state.isEraserMode) {
                        widget.controller.eraseStrokesNear(details.localPosition, 20.0);
                      } else {
                        setState(() {
                          _currentStrokePoints = [details.localPosition];
                        });
                      }
                    },
                    onPanUpdate: (details) {
                      if (widget.state.isEraserMode) {
                        widget.controller.eraseStrokesNear(details.localPosition, 20.0);
                      } else {
                        setState(() {
                          _currentStrokePoints.add(details.localPosition);
                        });
                      }
                    },
                    onPanEnd: (_) {
                      if (!widget.state.isEraserMode && _currentStrokePoints.isNotEmpty) {
                        widget.controller.addDrawingStroke(
                          DrawingStrokeEntity(
                            points: List.from(_currentStrokePoints),
                            colorHex: widget.state.currentBrushColor.toARGB32(),
                            strokeWidth: widget.state.currentBrushSize,
                            brushType: widget.state.brushType,
                            opacity: widget.state.brushOpacity,
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
    );

    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            transformationController: _transController,
            panEnabled: !widget.state.isDrawMode && widget.state.selectedTextId == null && widget.state.selectedStickerId == null,
            scaleEnabled: !widget.state.isDrawMode && widget.state.selectedTextId == null && widget.state.selectedStickerId == null,
            minScale: 1.0,
            maxScale: 5.0,
            child: canvasStack,
          ),
        ),
        // Floating "Reset Zoom" indicator when canvas is zoomed in
        if (_currentZoom > 1.05)
          Positioned(
            top: 12,
            right: 12,
            child: InkWell(
              onTap: _resetZoom,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.zoom_out_map, size: 14, color: AppColors.primaryLight),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentZoom.toStringAsFixed(1)}x Reset',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Before/After comparison indicator pill
        if (widget.state.isComparing)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'BEFORE (Original)',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        // Quick Font Color and Edit Toolbar for selected text overlay
        if (_buildSelectedTextToolbar() != null)
          _buildSelectedTextToolbar()!,
      ],
    );
  }
}

/// Custom clipper for non-destructive, precision crop boundaries
class _CropRectClipper extends CustomClipper<Rect> {
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  _CropRectClipper({
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
  });

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      size.width * cropLeft.clamp(0.0, 1.0),
      size.height * cropTop.clamp(0.0, 1.0),
      size.width * cropRight.clamp(0.0, 1.0),
      size.height * cropBottom.clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldReclip(covariant _CropRectClipper oldClipper) {
    return oldClipper.cropLeft != cropLeft ||
        oldClipper.cropTop != cropTop ||
        oldClipper.cropRight != cropRight ||
        oldClipper.cropBottom != cropBottom;
  }
}

/// Film grain noise custom painter
class FilmGrainPainter extends CustomPainter {
  final double intensity;

  FilmGrainPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..strokeWidth = 1.2;
    final dotCount = (size.width * size.height * 0.002 * intensity).toInt();

    for (int i = 0; i < dotCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final alpha = (random.nextDouble() * 0.3 * intensity).clamp(0.0, 1.0);
      final isWhite = random.nextBool();
      paint.color = (isWhite ? Colors.white : Colors.black).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FilmGrainPainter oldDelegate) => oldDelegate.intensity != intensity;
}

/// Checkerboard pattern for transparent PNG canvas
class CheckerboardBackgroundPainter extends CustomPainter {
  const CheckerboardBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 14.0;
    final paintLight = Paint()..color = const Color(0xFF1E293B);
    final paintDark = Paint()..color = const Color(0xFF0F172A);

    for (double x = 0; x < size.width; x += squareSize) {
      for (double y = 0; y < size.height; y += squareSize) {
        final isEven = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paintLight : paintDark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Freehand Vector Brush Painter supporting Pen, Marker, Neon Glow, and Eraser
class FreehandPainter extends CustomPainter {
  final List<DrawingStrokeEntity> savedStrokes;
  final List<Offset> activePoints;
  final Color activeColor;
  final double activeWidth;
  final String brushType;
  final double brushOpacity;

  FreehandPainter({
    required this.savedStrokes,
    required this.activePoints,
    required this.activeColor,
    required this.activeWidth,
    this.brushType = 'pen',
    this.brushOpacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw saved strokes
    for (final stroke in savedStrokes) {
      if (stroke.isEraser) continue;
      _drawSingleStroke(canvas, stroke.points, Color(stroke.colorHex), stroke.strokeWidth, stroke.brushType, stroke.opacity);
    }

    // 2. Draw active points
    if (activePoints.isNotEmpty) {
      _drawSingleStroke(canvas, activePoints, activeColor, activeWidth, brushType, brushOpacity);
    }
  }

  void _drawSingleStroke(Canvas canvas, List<Offset> points, Color color, double width, String type, double opacity) {
    if (points.length < 2) return;

    if (type == 'neon') {
      // Glow under-layer
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.45 * opacity)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * 2.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], glowPaint);
      }
    }

    final paint = Paint()
      ..color = type == 'marker'
          ? color.withValues(alpha: 0.55 * opacity)
          : color.withValues(alpha: opacity)
      ..strokeCap = type == 'marker' ? StrokeCap.square : StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant FreehandPainter oldDelegate) => true;
}
