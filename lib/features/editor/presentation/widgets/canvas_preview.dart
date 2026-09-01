import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../editor/domain/entities/transition_type.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../../text_stickers/domain/entities/overlay_animation_type.dart';
import '../../../text_stickers/domain/entities/sticker_overlay_entity.dart';
import '../../../text_stickers/domain/entities/text_overlay_entity.dart';
import '../../../text_stickers/presentation/widgets/text_editor_sheet.dart';
import '../../domain/entities/timeline_state.dart';
import '../../domain/entities/video_clip_entity.dart';
import '../providers/editor_controller.dart';

class CanvasPreview extends StatefulWidget {
  final TimelineState timelineState;
  final EditorController controller;

  const CanvasPreview({
    super.key,
    required this.timelineState,
    required this.controller,
  });

  @override
  State<CanvasPreview> createState() => _CanvasPreviewState();
}

class _CanvasPreviewState extends State<CanvasPreview> {
  bool _showSafeMargins = false;

  // Interactive Gesture State for Manual Video Clip Manipulation
  double _baseZoomScale = 1.0;
  double _basePositionX = 0.0;
  double _basePositionY = 0.0;

  // Interactive Gesture State for Manual Text Overlay Manipulation
  double _baseTextPosX = 0.5;
  double _baseTextPosY = 0.5;
  double _baseTextScale = 1.0;
  double _baseTextRotation = 0.0;

  void _openTextEditor(TextOverlayEntity textItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => TextEditorSheet(
        initialText: textItem,
        onSave: ({
          required text,
          required fontFamily,
          required fontSize,
          required colorHex,
          backgroundColorHex,
          required animationType,
        }) {
          widget.controller.updateTextOverlay(
            textItem.copyWith(
              text: text,
              fontFamily: fontFamily,
              fontSize: fontSize,
              colorHex: colorHex,
              backgroundColorHex: backgroundColorHex,
              animationType: animationType,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.timelineState;
    final project = state.project;
    final activeClip = state.activeVideoClip;
    final isClipSelected = state.selectionType == SelectionType.videoClip &&
        state.selectedItemId == activeClip?.id;
    final isTextSelected = state.selectionType == SelectionType.textOverlay;
    final currentPosMs = state.playheadPositionMs;
    final totalDurationMs = project.calculatedDurationMs;

    // Filter active text overlays
    final activeTexts = project.textOverlays.where((t) {
      return currentPosMs >= t.timelineStartMs && currentPosMs <= t.timelineEndMs;
    }).toList();

    // Filter active sticker overlays
    final activeStickers = project.stickerOverlays.where((s) {
      return currentPosMs >= s.timelineStartMs && currentPosMs <= s.timelineEndMs;
    }).toList();

    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Aspect Ratio Preview Canvas
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: AspectRatio(
                aspectRatio: project.aspectRatio.ratio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasWidth = constraints.maxWidth;
                    final canvasHeight = constraints.maxHeight;

                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111318),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isClipSelected
                              ? AppColors.primary
                              : (isTextSelected ? AppColors.textTrack : AppColors.surfaceBorder),
                          width: (isClipSelected || isTextSelected) ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isClipSelected
                                ? AppColors.primary.withValues(alpha: 0.35)
                                : (isTextSelected
                                    ? AppColors.textTrack.withValues(alpha: 0.35)
                                    : AppColors.primary.withValues(alpha: 0.15)),
                            blurRadius: (isClipSelected || isTextSelected) ? 24 : 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onScaleStart: (details) {
                          if (isClipSelected && activeClip != null) {
                            _baseZoomScale = activeClip.zoomScale;
                            _basePositionX = activeClip.positionX;
                            _basePositionY = activeClip.positionY;
                          }
                        },
                        onScaleUpdate: (details) {
                          if (isClipSelected && activeClip != null) {
                            final newZoom = (_baseZoomScale * details.scale).clamp(0.5, 5.0);
                            final newX = _basePositionX + details.focalPointDelta.dx;
                            final newY = _basePositionY + details.focalPointDelta.dy;

                            widget.controller.updateClipTransform(
                              clipId: activeClip.id,
                              zoomScale: newZoom,
                              positionX: newX,
                              positionY: newY,
                            );
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Video Frame Rendering Layer
                            if (activeClip != null)
                              _buildVideoClipFrame(activeClip, currentPosMs, isClipSelected)
                            else
                              _buildEmptyCanvasPlaceholder(),

                            // Transform Selection Bounding Box & Corner Handles for Video Clip
                            if (isClipSelected && activeClip != null)
                              _buildSelectionTransformHandles(activeClip),

                            // Safe Margins Guide
                            if (_showSafeMargins) _buildSafeMarginsGuide(),

                            // Text Overlays Layer with Interactive Positioning & Gestures
                            ...activeTexts.map((textEntity) {
                              final isThisTextSelected = state.selectionType == SelectionType.textOverlay &&
                                  state.selectedItemId == textEntity.id;
                              return _buildInteractiveTextOverlay(
                                textEntity: textEntity,
                                currentPosMs: currentPosMs,
                                isSelected: isThisTextSelected,
                                canvasWidth: canvasWidth,
                                canvasHeight: canvasHeight,
                              );
                            }),

                            // Sticker Overlays Layer
                            ...activeStickers.map((stickerEntity) {
                              return _buildStickerOverlay(stickerEntity);
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Top Info Bar (Timecode & Safe Margin Toggle)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live SMPTE Timecode
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '${TimecodeFormatter.formatTimecode(currentPosMs, fps: project.fps)} / ${TimecodeFormatter.formatTimecode(totalDurationMs, fps: project.fps)}',
                    style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.primaryLight),
                  ),
                ),

                // Safe Margin Guide Toggle
                InkWell(
                  onTap: () => setState(() => _showSafeMargins = !_showSafeMargins),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _showSafeMargins
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _showSafeMargins ? AppColors.primaryLight : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_3x3,
                          size: 14,
                          color: _showSafeMargins ? Colors.white : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Guides',
                          style: AppTypography.labelSmall.copyWith(
                            color: _showSafeMargins ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Floating Playback Controls
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceBorder),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step Back 5s
                  IconButton(
                    icon: const Icon(Icons.replay_5, size: 20),
                    tooltip: 'Back 5s',
                    onPressed: () => widget.controller.seekTo(currentPosMs - 5000),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  // Frame Back (1 frame)
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 20),
                    tooltip: 'Previous Frame',
                    onPressed: () => widget.controller.seekTo(currentPosMs - 33),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  // Main Play / Pause Button
                  GestureDetector(
                    onTap: widget.controller.togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Frame Forward (1 frame)
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 20),
                    tooltip: 'Next Frame',
                    onPressed: () => widget.controller.seekTo(currentPosMs + 33),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  // Step Forward 5s
                  IconButton(
                    icon: const Icon(Icons.forward_5, size: 20),
                    tooltip: 'Forward 5s',
                    onPressed: () => widget.controller.seekTo(currentPosMs + 5000),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoClipFrame(VideoClipEntity clip, int currentPosMs, bool isSelected) {
    Widget frameContent;
    final path = clip.mediaPath;

    if (path.startsWith('assets/')) {
      frameContent = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackFrame(clip),
      );
    } else if (File(path).existsSync()) {
      frameContent = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackFrame(clip),
      );
    } else {
      frameContent = _buildFallbackFrame(clip);
    }

    // 1. Apply Preset LUT Color Filter
    if (clip.filterType != FilterType.none && clip.filterType.colorFilter != null) {
      frameContent = ColorFiltered(
        colorFilter: clip.filterType.colorFilter!,
        child: frameContent,
      );
    }

    // 2. Apply Custom Brightness & Contrast Shaders
    if (clip.brightness != 0.0 || clip.contrast != 1.0 || clip.saturation != 1.0) {
      final b = clip.brightness;
      final c = clip.contrast;
      final s = clip.saturation;
      final matrix = <double>[
        c * s, 0, 0, 0, b * 255,
        0, c * s, 0, 0, b * 255,
        0, 0, c * s, 0, b * 255,
        0, 0, 0, 1, 0,
      ];
      frameContent = ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: frameContent,
      );
    }

    // 3. Apply Blur Effect
    if (clip.blurSigma > 0.0) {
      frameContent = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: clip.blurSigma,
          sigmaY: clip.blurSigma,
          tileMode: TileMode.clamp,
        ),
        child: frameContent,
      );
    }

    // 4. Apply Manual Clip Position (Drag/Pan Offset) & Zoom Scale
    frameContent = Transform.translate(
      offset: Offset(clip.positionX, clip.positionY),
      child: Transform.rotate(
        angle: clip.rotationDegrees * (3.14159 / 180),
        child: Transform.scale(
          scale: clip.zoomScale,
          child: frameContent,
        ),
      ),
    );

    // 5. Calculate Fade In / Fade Out Progress
    final offsetInClip = currentPosMs - clip.timelineStartMs;
    double fadeOpacity = 1.0;

    if (clip.fadeInDurationMs > 0 && offsetInClip < clip.fadeInDurationMs) {
      fadeOpacity *= (offsetInClip / clip.fadeInDurationMs).clamp(0.0, 1.0);
    }

    final remainingMs = clip.effectiveDurationMs - offsetInClip;
    if (clip.fadeOutDurationMs > 0 && remainingMs < clip.fadeOutDurationMs) {
      fadeOpacity *= (remainingMs / clip.fadeOutDurationMs).clamp(0.0, 1.0);
    }

    // 6. Apply Transition Entrance Effect
    if (clip.transitionIn != TransitionType.none && offsetInClip < clip.transitionDurationMs) {
      final transProgress = (offsetInClip / clip.transitionDurationMs).clamp(0.0, 1.0);
      switch (clip.transitionIn) {
        case TransitionType.crossFade:
          fadeOpacity *= transProgress;
          break;
        case TransitionType.zoomIn:
          final scale = 0.5 + (0.5 * transProgress);
          frameContent = Transform.scale(scale: scale, child: frameContent);
          break;
        case TransitionType.wipeRight:
          frameContent = ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: transProgress,
              child: frameContent,
            ),
          );
          break;
        case TransitionType.glitch:
          fadeOpacity *= (transProgress > 0.5 ? 1.0 : 0.6);
          break;
        default:
          break;
      }
    }

    if (fadeOpacity < 1.0) {
      frameContent = Opacity(
        opacity: fadeOpacity.clamp(0.0, 1.0),
        child: frameContent,
      );
    }

    return frameContent;
  }

  // Interactive Bounding Box with Corner Scale/Drag Handles for Clip
  Widget _buildSelectionTransformHandles(VideoClipEntity clip) {
    return Transform.translate(
      offset: Offset(clip.positionX, clip.positionY),
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryLight, width: 2.0),
          ),
          child: Stack(
            children: [
              _buildCornerHandle(Alignment.topLeft, AppColors.primary),
              _buildCornerHandle(Alignment.topRight, AppColors.primary),
              _buildCornerHandle(Alignment.bottomLeft, AppColors.primary),
              _buildCornerHandle(Alignment.bottomRight, AppColors.primary),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Zoom: ${(clip.zoomScale * 100).toInt()}% • Drag to Move',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Interactive Text Overlay with Canvas Gestures (Drag, Pinch-to-Scale, Rotate & Double-Tap Edit)
  Widget _buildInteractiveTextOverlay({
    required TextOverlayEntity textEntity,
    required int currentPosMs,
    required bool isSelected,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final progressInClip = (currentPosMs - textEntity.timelineStartMs) / textEntity.effectiveDurationMs;

    double opacity = 1.0;
    double translateY = 0.0;
    String displayText = textEntity.text;

    if (textEntity.animationType == OverlayAnimationType.fadeIn) {
      opacity = (progressInClip * 4).clamp(0.0, 1.0);
    } else if (textEntity.animationType == OverlayAnimationType.typewriter) {
      final charCount = (textEntity.text.length * progressInClip * 2).clamp(0, textEntity.text.length).toInt();
      displayText = textEntity.text.substring(0, charCount);
    } else if (textEntity.animationType == OverlayAnimationType.slideUp) {
      translateY = (1.0 - (progressInClip * 3).clamp(0.0, 1.0)) * 20;
      opacity = (progressInClip * 3).clamp(0.0, 1.0);
    }

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment(
          (textEntity.posX - 0.5) * 2,
          (textEntity.posY - 0.5) * 2,
        ),
        child: GestureDetector(
          onTap: () {
            widget.controller.setSelection(SelectionType.textOverlay, textEntity.id);
          },
          onDoubleTap: () => _openTextEditor(textEntity),
          onScaleStart: (details) {
            _baseTextPosX = textEntity.posX;
            _baseTextPosY = textEntity.posY;
            _baseTextScale = textEntity.scale;
            _baseTextRotation = textEntity.rotation;
            widget.controller.setSelection(SelectionType.textOverlay, textEntity.id);
          },
          onScaleUpdate: (details) {
            final deltaNormX = details.focalPointDelta.dx / (canvasWidth > 0 ? canvasWidth : 300);
            final deltaNormY = details.focalPointDelta.dy / (canvasHeight > 0 ? canvasHeight : 500);

            final newX = (_baseTextPosX + deltaNormX).clamp(0.05, 0.95);
            final newY = (_baseTextPosY + deltaNormY).clamp(0.05, 0.95);
            final newScale = (_baseTextScale * details.scale).clamp(0.3, 4.0);
            final newRotation = _baseTextRotation + details.rotation;

            _baseTextPosX = newX;
            _baseTextPosY = newY;

            widget.controller.updateTextTransform(
              textId: textEntity.id,
              posX: newX,
              posY: newY,
              scale: newScale,
              rotation: newRotation,
            );
          },
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.rotate(
              angle: textEntity.rotation,
              child: Transform.scale(
                scale: textEntity.scale,
                child: Opacity(
                  opacity: opacity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Text Container Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: textEntity.backgroundColorHex != null
                              ? Color(textEntity.backgroundColorHex!)
                              : null,
                          borderRadius: BorderRadius.circular(6),
                          border: isSelected
                              ? Border.all(color: AppColors.textTrack, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          displayText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: textEntity.fontFamily,
                            fontSize: textEntity.fontSize,
                            fontWeight: FontWeight.bold,
                            color: Color(textEntity.colorHex),
                            shadows: [
                              if (textEntity.outlineColorHex != null)
                                Shadow(
                                  color: Color(textEntity.outlineColorHex!),
                                  blurRadius: textEntity.outlineWidth * 2,
                                ),
                              const Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(1, 2)),
                            ],
                          ),
                        ),
                      ),

                      // Text Selection Handles & Mini Action Floating Bar
                      if (isSelected) ...[
                        _buildCornerHandle(Alignment.topLeft, AppColors.textTrack),
                        _buildCornerHandle(Alignment.topRight, AppColors.textTrack),
                        _buildCornerHandle(Alignment.bottomLeft, AppColors.textTrack),
                        _buildCornerHandle(Alignment.bottomRight, AppColors.textTrack),

                        // Top Floating Action Quick Bar (Edit | Duplicate | Delete)
                        Positioned(
                          top: -36,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2028),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.textTrack, width: 1),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _openTextEditor(textEntity),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Icon(Icons.edit, size: 14, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => widget.controller.duplicateTextOverlay(textEntity.id),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Icon(Icons.copy, size: 14, color: AppColors.secondary),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => widget.controller.deleteSelected(),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildCornerHandle(Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }

  Widget _buildFallbackFrame(VideoClipEntity clip) {
    final gradientColors = _getClipGradient(clip.name);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _ClipVisualPatternPainter(seed: clip.name.hashCode),
            size: Size.infinite,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.movie_filter_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  clip.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${clip.speed}x • ${clip.filterType.label}',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white70,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCanvasPlaceholder() {
    return Container(
      color: const Color(0xFF16181F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_outlined, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text('No Video Clip at Playhead', style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeMarginsGuide() {
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.6), width: 1),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerOverlay(StickerOverlayEntity sticker) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment(
          (sticker.posX - 0.5) * 2,
          (sticker.posY - 0.5) * 2,
        ),
        child: Transform.rotate(
          angle: sticker.rotation,
          child: Transform.scale(
            scale: sticker.scale,
            child: Text(
              sticker.assetEmojiOrPath,
              style: const TextStyle(fontSize: 48),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getClipGradient(String name) {
    final code = name.hashCode.abs();
    final paletteIndex = code % 5;
    switch (paletteIndex) {
      case 0:
        return const [Color(0xFF1E3A8A), Color(0xFF065F46), Color(0xFF111827)];
      case 1:
        return const [Color(0xFF581C87), Color(0xFF831843), Color(0xFF0F172A)];
      case 2:
        return const [Color(0xFF7C2D12), Color(0xFF78350F), Color(0xFF18181B)];
      case 3:
        return const [Color(0xFF0F766E), Color(0xFF1E40AF), Color(0xFF020617)];
      default:
        return const [Color(0xFF312E81), Color(0xFF4C1D95), Color(0xFF09090B)];
    }
  }
}

class _ClipVisualPatternPainter extends CustomPainter {
  final int seed;
  _ClipVisualPatternPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (int i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClipVisualPatternPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
