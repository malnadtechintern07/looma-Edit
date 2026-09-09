import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/rendering/chroma_key_filter.dart';
import '../../../../core/utils/font_helper.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../core/widgets/procut_watermark.dart';
import '../../../../core/widgets/responsive_tap_button.dart';
import '../../../editor/domain/entities/transition_type.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../../filters_effects/domain/entities/video_effect_type.dart';
import '../../../text_stickers/domain/entities/overlay_animation_type.dart';
import '../../../text_stickers/domain/entities/sticker_overlay_entity.dart';
import '../../../text_stickers/domain/entities/text_overlay_entity.dart';
import '../../../text_stickers/presentation/widgets/text_editor_sheet.dart';
import '../../domain/entities/clip_animation_type.dart';
import '../../domain/entities/chroma_key_config_entity.dart';
import '../../domain/entities/keyframe_entity.dart';
import '../../domain/entities/mask_config_entity.dart';
import '../../domain/entities/speed_curve_type.dart';
import '../../domain/entities/subtitle_entity.dart';
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
  final GlobalKey _chromaPreviewBoundaryKey = GlobalKey();
  Color? _liveSampledColor;

  // Single Active Video Player Controller & Preload Cache (max 2 entries to prevent GPU exhaustion)
  final Map<String, VideoPlayerController> _videoControllers = {};
  String? _currentPlayingPath;
  bool _wasPlaying = false;

  // Unified Continuous Gesture State for All Elements (Video, Photo, Overlay PIP, Text, Sticker)
  bool _isGestureActive = false;
  Offset _lastFocal = Offset.zero;
  double _lastScale = 1.0;
  double _lastRotation = 0.0;
  int _activePointers = 0;

  // Live in-memory accumulated transforms for currently selected item
  double _livePosX = 0.0;
  double _livePosY = 0.0;
  double _liveZoom = 1.0;
  double _liveRotation = 0.0;

  double _liveTextPosX = 0.5;
  double _liveTextPosY = 0.5;
  double _liveTextScale = 1.0;
  double _liveTextRotation = 0.0;

  double _liveStickerPosX = 0.5;
  double _liveStickerPosY = 0.5;
  double _liveStickerScale = 1.0;
  double _liveStickerRotation = 0.0;

  void _initClipLiveTransform(VideoClipEntity clip) {
    if (clip.keyframes.isNotEmpty) {
      final offsetInClip = (widget.timelineState.playheadPositionMs - clip.timelineStartMs).clamp(0, clip.effectiveDurationMs);
      final base = KeyframeValues(
        posX: clip.positionX,
        posY: clip.positionY,
        scale: clip.zoomScale,
        rotation: clip.rotationDegrees,
        opacity: clip.opacity,
      );
      final interpolated = KeyframeInterpolator.interpolate(
        keyframes: clip.keyframes,
        currentOffsetMs: offsetInClip,
        baseValues: base,
      );
      _livePosX = interpolated.posX;
      _livePosY = interpolated.posY;
      _liveZoom = interpolated.scale;
      _liveRotation = interpolated.rotation;
    } else {
      _livePosX = clip.positionX;
      _livePosY = clip.positionY;
      _liveZoom = clip.zoomScale;
      _liveRotation = clip.rotationDegrees;
    }
  }

  void _handleScaleStart(ScaleStartDetails details, VideoClipEntity? activeClip) {
    _lastFocal = details.focalPoint;
    _lastScale = 1.0;
    _lastRotation = 0.0;
    _activePointers = details.pointerCount;
    _isGestureActive = false;

    final state = widget.timelineState;

    // Auto-select activeClip if nothing is selected
    if (state.selectionType == SelectionType.none && activeClip != null) {
      widget.controller.setSelection(SelectionType.videoClip, activeClip.id);
      _initClipLiveTransform(activeClip);
      _isGestureActive = true;
      return;
    }

    if (state.selectionType == SelectionType.videoClip) {
      final clip = activeClip ??
          state.project.videoClips.where((c) => c.id == state.selectedItemId).firstOrNull;
      if (clip != null) {
        _initClipLiveTransform(clip);
        _isGestureActive = true;
      }
    } else if (state.selectionType == SelectionType.overlayClip) {
      final clip = state.project.videoClips.where((c) => c.id == state.selectedItemId).firstOrNull;
      if (clip != null) {
        _initClipLiveTransform(clip);
        _isGestureActive = true;
      }
    } else if (state.selectionType == SelectionType.textOverlay) {
      final text = state.project.textOverlays.where((t) => t.id == state.selectedItemId).firstOrNull;
      if (text != null) {
        _liveTextPosX = text.posX;
        _liveTextPosY = text.posY;
        _liveTextScale = text.scale;
        _liveTextRotation = text.rotation;
        _isGestureActive = true;
      }
    } else if (state.selectionType == SelectionType.stickerOverlay) {
      final sticker = state.project.stickerOverlays.where((s) => s.id == state.selectedItemId).firstOrNull;
      if (sticker != null) {
        _liveStickerPosX = sticker.posX;
        _liveStickerPosY = sticker.posY;
        _liveStickerScale = sticker.scale;
        _liveStickerRotation = sticker.rotation;
        _isGestureActive = true;
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, double canvasWidth, double canvasHeight) {
    if (!_isGestureActive) return;

    // When number of fingers changes (1 finger <-> 2 fingers), re-anchor smoothly without jumping
    if (details.pointerCount != _activePointers) {
      _activePointers = details.pointerCount;
      _lastFocal = details.focalPoint;
      _lastScale = details.scale;
      _lastRotation = details.rotation;
      return;
    }

    final dx = details.focalPoint.dx - _lastFocal.dx;
    final dy = details.focalPoint.dy - _lastFocal.dy;
    _lastFocal = details.focalPoint;

    double scaleRatio = 1.0;
    if (_lastScale > 0.001 && details.scale > 0.001) {
      scaleRatio = details.scale / _lastScale;
    }
    _lastScale = details.scale;

    final rotDelta = (details.rotation - _lastRotation) * (180.0 / 3.141592653589793);
    _lastRotation = details.rotation;

    final state = widget.timelineState;

    if (state.selectionType == SelectionType.videoClip || state.selectionType == SelectionType.overlayClip) {
      _livePosX += dx;
      _livePosY += dy;
      _liveZoom = (_liveZoom * scaleRatio).clamp(0.1, 5.0);
      _liveRotation = (_liveRotation + rotDelta) % 360.0;
    } else if (state.selectionType == SelectionType.textOverlay) {
      final w = canvasWidth > 0 ? canvasWidth : 300.0;
      final h = canvasHeight > 0 ? canvasHeight : 500.0;

      _liveTextPosX = (_liveTextPosX + (dx / w)).clamp(0.02, 0.98);
      _liveTextPosY = (_liveTextPosY + (dy / h)).clamp(0.02, 0.98);
      _liveTextScale = (_liveTextScale * scaleRatio).clamp(0.2, 5.0);
      _liveTextRotation = _liveTextRotation + (rotDelta * (3.141592653589793 / 180.0));
    } else if (state.selectionType == SelectionType.stickerOverlay) {
      final w = canvasWidth > 0 ? canvasWidth : 300.0;
      final h = canvasHeight > 0 ? canvasHeight : 500.0;

      _liveStickerPosX = (_liveStickerPosX + (dx / w)).clamp(0.02, 0.98);
      _liveStickerPosY = (_liveStickerPosY + (dy / h)).clamp(0.02, 0.98);
      _liveStickerScale = (_liveStickerScale * scaleRatio).clamp(0.2, 5.0);
      _liveStickerRotation = _liveStickerRotation + (rotDelta * (3.141592653589793 / 180.0));
    }

    // Trigger silky 60 FPS local redraw of transformed element & bounding box
    setState(() {});
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!_isGestureActive) return;
    _isGestureActive = false;
    _activePointers = 0;

    final state = widget.timelineState;
    if (state.selectionType == SelectionType.videoClip || state.selectionType == SelectionType.overlayClip) {
      final clipId = state.selectedItemId;
      if (clipId != null) {
        widget.controller.updateClipTransform(
          clipId: clipId,
          positionX: _livePosX,
          positionY: _livePosY,
          zoomScale: _liveZoom,
          rotationDegrees: _liveRotation,
          persist: true,
        );
      }
    } else if (state.selectionType == SelectionType.textOverlay) {
      final textId = state.selectedItemId;
      if (textId != null) {
        widget.controller.updateTextTransform(
          textId: textId,
          posX: _liveTextPosX,
          posY: _liveTextPosY,
          scale: _liveTextScale,
          rotation: _liveTextRotation,
          persist: true,
        );
      }
    } else if (state.selectionType == SelectionType.stickerOverlay) {
      final stickerId = state.selectedItemId;
      if (stickerId != null) {
        widget.controller.updateStickerTransform(
          stickerId: stickerId,
          posX: _liveStickerPosX,
          posY: _liveStickerPosY,
          scale: _liveStickerScale,
          rotation: _liveStickerRotation,
          persist: true,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _syncActiveVideoController();
  }

  @override
  void didUpdateWidget(covariant CanvasPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isGestureActive) {
      _syncActiveVideoController();
    }
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      try {
        controller.pause();
        controller.dispose();
      } catch (_) {}
    }
    _videoControllers.clear();
    super.dispose();
  }

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp')) {
      return false;
    }
    return true;
  }

  VideoPlayerController? _getVideoController(String path, {String? clipId}) {
    if (!_isVideoFile(path)) return null;

    final cacheKey = clipId ?? path;
    if (_videoControllers.containsKey(cacheKey)) {
      return _videoControllers[cacheKey];
    }

    // Keep cache size comfortable to avoid re-init overhead on multi-clip projects
    if (_videoControllers.length >= 8) {
      final keyToRemove = _videoControllers.keys.firstWhere(
        (k) => k != _currentPlayingPath,
        orElse: () => _videoControllers.keys.first,
      );
      final old = _videoControllers.remove(keyToRemove);
      try {
        old?.pause();
        old?.dispose();
      } catch (_) {}
    }

    try {
      VideoPlayerController controller;
      final cleanPath = path.startsWith('file://') ? path.substring(7) : path;

      if (path.startsWith('assets/')) {
        controller = VideoPlayerController.asset(path);
      } else if (path.startsWith('content://') || path.startsWith('http://') || path.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else if (File(cleanPath).existsSync()) {
        controller = VideoPlayerController.file(File(cleanPath));
      } else {
        try {
          controller = VideoPlayerController.networkUrl(Uri.parse(path));
        } catch (_) {
          return null;
        }
      }

      _videoControllers[cacheKey] = controller;
      controller.initialize().then((_) {
        controller.setLooping(false);
        final realDurMs = controller.value.duration.inMilliseconds;
        if (clipId != null && realDurMs > 0) {
          widget.controller.syncClipRealDuration(clipId, realDurMs);
        }
        final curPos = widget.timelineState.playheadPositionMs;
        final matchingClip = clipId != null
            ? widget.timelineState.project.videoClips.where((c) => c.id == clipId).firstOrNull
            : widget.timelineState.activeVideoClip;
        final startMs = matchingClip?.timelineStartMs ?? 0;
        final trimStart = matchingClip?.trimStartMs ?? 0;
        final offsetMs = (curPos - startMs + trimStart)
            .clamp(0, realDurMs > 0 ? realDurMs : 100000);
        controller.seekTo(Duration(milliseconds: offsetMs));
        if (widget.timelineState.isPlaying) {
          controller.play();
        }
        if (mounted) {
          setState(() {});
          _syncActiveVideoController();
        }
      }).catchError((e) {
        debugPrint('CanvasPreview: failed to initialize VideoPlayerController for $path: $e');
      });
      return controller;
    } catch (_) {
      return null;
    }
  }

  void _syncActiveVideoController([TimelineState? stateOverride]) {
    final state = stateOverride ?? widget.controller.currentState;
    final isPlaying = state.isPlaying;
    final currentPosMs = state.playheadPositionMs;
    final hasPlayStateChanged = _wasPlaying != isPlaying;
    _wasPlaying = isPlaying;

    // 1. Gather all video clips that are active at the current playhead:
    // Both the main track clip AND any active Picture-in-Picture (PIP) overlay clips
    final activeVideoClips = <VideoClipEntity>[];
    final mainClip = state.activeVideoClip;
    if (mainClip != null && _isVideoFile(mainClip.mediaPath)) {
      activeVideoClips.add(mainClip);
    }
    for (final overlayClip in state.activeOverlayClips) {
      if (_isVideoFile(overlayClip.mediaPath)) {
        activeVideoClips.add(overlayClip);
      }
    }

    final activeKeys = activeVideoClips.map((c) => c.id).toSet();

    // 2. Pause any controllers that are no longer on active tracks or not at the current playhead
    for (final entry in _videoControllers.entries) {
      if (!activeKeys.contains(entry.key) && entry.value.value.isPlaying) {
        entry.value.pause();
      }
    }

    if (activeVideoClips.isEmpty) {
      _currentPlayingPath = null;
      return;
    }

    // 3. Synchronize playback, position seeking, speed curves, and volume for all active clips
    for (final clip in activeVideoClips) {
      final path = clip.mediaPath;
      final controller = _getVideoController(path, clipId: clip.id);
      if (controller == null || !controller.value.isInitialized) {
        continue;
      }

      final maxDur = (clip.sourceDurationMs > 0)
          ? clip.sourceDurationMs
          : (controller.value.duration.inMilliseconds > 0 ? controller.value.duration.inMilliseconds : 10000000);

      final effectiveDur = clip.effectiveDurationMs;
      final timelineOffsetMs = (currentPosMs - clip.timelineStartMs).clamp(0, effectiveDur);
      final timelineProgress = effectiveDur > 0 ? (timelineOffsetMs / effectiveDur).clamp(0.0, 1.0) : 0.0;

      // Exact mapping from timeline timestamp to source video timestamp taking speed & speed curves into account
      final sourceProgress = clip.speedCurve != SpeedCurveType.none
          ? clip.speedCurve.getSourceProgressAtTimelineProgress(timelineProgress)
          : timelineProgress;

      final trimmedDuration = clip.trimmedSourceDurationMs;
      final offsetInClipMs = (clip.trimStartMs + (sourceProgress * trimmedDuration).round())
          .clamp(0, maxDur)
          .toInt();
      final targetDuration = Duration(milliseconds: offsetInClipMs);
      final currentVideoMs = controller.value.position.inMilliseconds;

      final curveSpeed = clip.speedCurve.getSpeedAtProgress(timelineProgress);
      final targetSpeed = (clip.speed * curveSpeed).clamp(0.25, 4.0);
      final targetVolume = clip.isMuted ? 0.0 : clip.volume.clamp(0.0, 1.0);

      if (isPlaying) {
        // Set playback speed
        controller.setPlaybackSpeed(targetSpeed);

        // Set volume / mute
        controller.setVolume(targetVolume);

        // Resync drift
        final isDislocated = (currentVideoMs - offsetInClipMs).abs() > 500;
        if (hasPlayStateChanged || isDislocated) {
          controller.seekTo(targetDuration);
        }

        if (!controller.value.isPlaying) {
          controller.play();
        }
      } else {
        // When paused or scrubbing playhead, pause video and seek to exact current frame
        if (controller.value.isPlaying) {
          controller.pause();
        }
        if ((currentVideoMs - offsetInClipMs).abs() > 30) {
          controller.seekTo(targetDuration);
        }
      }
    }
  }

  void _openTextEditor(TextOverlayEntity textItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
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
              padding: const EdgeInsets.fromLTRB(16, 36, 16, 64),
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
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (state.selectionType == SelectionType.none) {
                            if (activeClip != null) {
                              widget.controller.setSelection(SelectionType.videoClip, activeClip.id);
                            }
                          } else {
                            widget.controller.clearSelection();
                          }
                        },
                        onScaleStart: (details) => _handleScaleStart(details, activeClip),
                        onScaleUpdate: (details) => _handleScaleUpdate(details, canvasWidth, canvasHeight),
                        onScaleEnd: _handleScaleEnd,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Video Frame / Media Rendering Layer (wrapped in RepaintBoundary for accurate pixel sampling across all tracks)
                            RepaintBoundary(
                              key: _chromaPreviewBoundaryKey,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (activeClip != null)
                                    _buildVideoClipFrame(activeClip, currentPosMs, isClipSelected)
                                  else
                                    _buildEmptyCanvasPlaceholder(),

                                  // Picture-in-Picture (PIP) Overlays Track Layer
                                  ...state.activeOverlayClips.map((overlayClip) {
                                    final isOverlaySelected = state.selectionType == SelectionType.overlayClip &&
                                        state.selectedItemId == overlayClip.id;
                                    return GestureDetector(
                                      behavior: HitTestBehavior.deferToChild,
                                      onTap: () {
                                        widget.controller.setSelection(SelectionType.overlayClip, overlayClip.id);
                                      },
                                      child: _buildVideoClipFrame(overlayClip, currentPosMs, isOverlaySelected),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            // Transform Selection Bounding Box & Corner Handles for Video Clip
                            if (isClipSelected && activeClip != null) ...[
                              _buildSelectionTransformHandles(activeClip),
                              _buildClipQuickToolbar(activeClip),
                            ],

                            // Picture-in-Picture (PIP) Overlays Transform Handles Layer
                            ...state.activeOverlayClips.map((overlayClip) {
                              final isOverlaySelected = state.selectionType == SelectionType.overlayClip &&
                                  state.selectedItemId == overlayClip.id;
                              if (!isOverlaySelected) return const SizedBox.shrink();
                              return Stack(
                                children: [
                                  _buildSelectionTransformHandles(overlayClip),
                                  _buildClipQuickToolbar(overlayClip),
                                ],
                              );
                            }),

                            // Active Timeline Effect Clips Layer (Compositing all independent effect clips)
                            ...project.effectClips
                                .where((e) => currentPosMs >= e.timelineStartMs && currentPosMs <= e.timelineEndMs)
                                .map((effClip) {
                              final offsetInEffect = currentPosMs - effClip.timelineStartMs;
                              return Positioned.fill(
                                child: IgnorePointer(
                                  child: _applyVideoEffect(
                                    content: const SizedBox.expand(),
                                    effect: effClip.effectType,
                                    intensity: effClip.intensity,
                                    offsetInClipMs: offsetInEffect,
                                  ),
                                ),
                              );
                            }),

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

                            // Subtitles & Captions Track Layer
                            ...project.subtitles.where((s) => currentPosMs >= s.timelineStartMs && currentPosMs <= s.timelineEndMs).map((sub) {
                              final isSubSelected = state.selectionType == SelectionType.subtitle && state.selectedItemId == sub.id;
                              return _buildSubtitleOverlay(sub, isSubSelected);
                            }),

                            // Sticker Overlays Layer with Interactive Positioning & Gestures
                            ...activeStickers.map((stickerEntity) {
                              final isThisStickerSelected = state.selectionType == SelectionType.stickerOverlay &&
                                  state.selectedItemId == stickerEntity.id;
                              return _buildStickerOverlay(
                                sticker: stickerEntity,
                                isSelected: isThisStickerSelected,
                                canvasWidth: canvasWidth,
                                canvasHeight: canvasHeight,
                              );
                            }),

                            // 7. Interactive Chroma Key Crosshair Overlay & Color Picker
                            if (state.isChromaKeyPickingMode) ...[
                              _buildChromaKeyCrosshairOverlay(
                                canvasWidth,
                                canvasHeight,
                                state.project.videoClips.where((c) => c.id == state.chromaKeyTargetClipId).firstOrNull ??
                                    state.selectedVideoClip ??
                                    activeClip,
                              ),
                            ],

                            // 8. Subtle ProCut Watermark in Bottom-Right Corner
                            const Positioned(
                              right: 10,
                              bottom: 10,
                              child: IgnorePointer(
                                child: ProCutWatermark(opacity: 0.65, scale: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Top Info Bar (Timecode, Safe Margin Toggle, & Full Screen Button)
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live SMPTE Timecode
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Container(
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
                  ),
                ),
                const SizedBox(width: 8),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
              ],
            ),
          ),

          // CapCut-Style Playback & Control Options Toolbar (Matching Reference UI)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFF14151B),
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: [ ⛶ Fullscreen ] -------- [ ▷ Play/Pause ] (Centered) -------- [ ⧉ ON Magnet ] [ ↶ Undo ] [ ↷ Redo ]
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left: Fullscreen Icon Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ResponsiveTapButton(
                              onTap: _openFullScreenPreview,
                              child: Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.fullscreen,
                                  size: 26,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // EXACT Center: Clean White Play/Pause Button
                          Align(
                            alignment: Alignment.center,
                            child: ResponsiveTapButton(
                              onTap: widget.controller.togglePlayPause,
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                child: Icon(
                                  state.isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // Right: Magnet / Snapping Toggle, Undo, Redo
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Auto-Snapping / Magnet Toggle [ ⧉ ON ]
                                _buildSnappingButton(state.isSnappingEnabled),
                                const SizedBox(width: 4),

                                // Undo Button ↶
                                ResponsiveTapButton(
                                  onTap: widget.controller.canUndo ? widget.controller.undo : null,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.undo,
                                      size: 22,
                                      color: widget.controller.canUndo
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),

                                // Redo Button ↷
                                ResponsiveTapButton(
                                  onTap: widget.controller.canRedo ? widget.controller.redo : null,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.redo,
                                      size: 22,
                                      color: widget.controller.canRedo
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Row 2: Timecodes [ 00:00 / 00:04 ] -------- [ 00:00 ] (Directly over playhead needle)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left: Current / Total Timecode (e.g. 00:00 / 00:04)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${TimecodeFormatter.formatMmSs(currentPosMs)} / ${TimecodeFormatter.formatMmSs(totalDurationMs)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Center: Exact Playhead Position (Aligned with Timeline Needle)
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            TimecodeFormatter.formatMmSs(currentPosMs),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnappingButton(bool isEnabled) {
    return Tooltip(
      message: isEnabled ? 'Timeline Magnet / Auto-Snapping: ON' : 'Timeline Magnet / Auto-Snapping: OFF',
      child: ResponsiveTapButton(
        onTap: widget.controller.toggleSnapping,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: SizedBox(
            width: 28,
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Back rectangle
                Positioned(
                  top: 1,
                  left: 1,
                  child: Container(
                    width: 17,
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: isEnabled ? Colors.white70 : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Front rectangle with ON/OFF label
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 18,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14151B),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: isEnabled ? Colors.white : Colors.white38,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isEnabled ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isEnabled ? const Color(0xFF00C2CB) : Colors.white38,
                      ),
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

  Widget _buildVideoClipFrame(VideoClipEntity clip, int currentPosMs, bool isSelected) {
    Widget frameContent;
    final path = clip.mediaPath;

    // 1. Real Video Player or Image Renderer
    final videoController = _getVideoController(path, clipId: clip.id);
    if (videoController != null && videoController.value.isInitialized) {
      final videoSize = videoController.value.size;
      frameContent = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: videoSize.width > 0 ? videoSize.width : 1280,
          height: videoSize.height > 0 ? videoSize.height : 720,
          child: VideoPlayer(videoController),
        ),
      );
    } else if (videoController != null && !videoController.value.isInitialized) {
      // Sleek loading preview while video buffer initializes
      frameContent = Stack(
        fit: StackFit.expand,
        children: [
          _buildFallbackFrame(clip),
          const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      );
    } else if (path.startsWith('assets/')) {
      frameContent = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackFrame(clip),
      );
    } else if (File(path).existsSync() && !_isVideoFile(path)) {
      frameContent = Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: 1080,
        errorBuilder: (_, _, _) => _buildFallbackFrame(clip),
      );
    } else {
      frameContent = _buildFallbackFrame(clip);
    }

    // 2. Preset LUT Color Filter with Intensity Control (0-100%)
    if (clip.filterType != FilterType.none) {
      final colorFilter = clip.filterType.getColorFilter(clip.filterIntensity);
      if (colorFilter != null) {
        frameContent = ColorFiltered(
          colorFilter: colorFilter,
          child: frameContent,
        );
      }
    }

    // 3. Custom Brightness & Contrast
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

    // 4. Blur Effect
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

    // 5. Flip Horizontal & Vertical
    if (clip.isFlippedHorizontally || clip.isFlippedVertically) {
      frameContent = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          clip.isFlippedHorizontally ? -1.0 : 1.0,
          clip.isFlippedVertically ? -1.0 : 1.0,
          1.0,
        ),
        child: frameContent,
      );
    }

    // 6. Framing & Aspect Ratio Crop
    if (clip.crop != null) {
      final crop = clip.crop!;
      frameContent = ClipRect(
        child: Align(
          alignment: Alignment(
            (crop.left + crop.right - 1.0),
            (crop.top + crop.bottom - 1.0),
          ),
          widthFactor: (crop.right - crop.left).clamp(0.1, 1.0),
          heightFactor: (crop.bottom - crop.top).clamp(0.1, 1.0),
          child: frameContent,
        ),
      );
    }

    // 7. Chroma Key / Green Screen Filter
    // In interactive color picking mode on this clip, bypass keying so the user can accurately sample the raw green color
    final isPickingThisClip = widget.timelineState.isChromaKeyPickingMode &&
        widget.timelineState.chromaKeyTargetClipId == clip.id;
    if (clip.chromaKey != null && clip.chromaKey!.isEnabled && !isPickingThisClip) {
      frameContent = _applyChromaKey(frameContent, clip.chromaKey!);
    }

    // 8. Masking (Rectangle, Circle, Linear, Filmstrip)
    if (clip.mask != null && clip.mask!.shape != MaskShape.none) {
      frameContent = _applyClipMask(frameContent, clip.mask!);
    }

    // 9. Evaluate Dynamic Keyframe Interpolation vs Base Transform
    final offsetInClip = currentPosMs - clip.timelineStartMs;
    final baseValues = KeyframeValues(
      posX: clip.positionX,
      posY: clip.positionY,
      scale: clip.zoomScale,
      rotation: clip.rotationDegrees,
      opacity: clip.opacity,
    );

    final keyValues = KeyframeInterpolator.interpolate(
      keyframes: clip.keyframes,
      currentOffsetMs: offsetInClip,
      baseValues: baseValues,
    );

    // Apply active Keyframed / Base Position (Drag/Pan Offset), Rotation & Zoom Scale
    final isTransformingThisClip = _isGestureActive &&
        ((widget.timelineState.selectionType == SelectionType.videoClip && widget.timelineState.selectedItemId == clip.id) ||
         (widget.timelineState.selectionType == SelectionType.overlayClip && widget.timelineState.selectedItemId == clip.id));

    final effectivePosX = isTransformingThisClip ? _livePosX : keyValues.posX;
    final effectivePosY = isTransformingThisClip ? _livePosY : keyValues.posY;
    final effectiveScale = isTransformingThisClip ? _liveZoom : keyValues.scale;
    final effectiveRot = isTransformingThisClip ? _liveRotation : keyValues.rotation;

    frameContent = Transform.translate(
      offset: Offset(effectivePosX, effectivePosY),
      child: Transform.rotate(
        angle: effectiveRot * (3.14159 / 180),
        child: Transform.scale(
          scale: effectiveScale,
          child: frameContent,
        ),
      ),
    );

    // 10. Calculate Entrance (IN), Exit (OUT), and COMBO Animations
    frameContent = _applyClipAnimations(
      content: frameContent,
      clip: clip,
      offsetInClipMs: offsetInClip,
    );

    // 10b. Apply Active Independent Timeline Animation Clips
    for (final animClip in widget.timelineState.project.animationClips) {
      if (currentPosMs >= animClip.timelineStartMs && currentPosMs <= animClip.timelineEndMs) {
        final offsetInAnim = currentPosMs - animClip.timelineStartMs;
        frameContent = _applyTimelineAnimation(
          content: frameContent,
          combo: animClip.animationType,
          offsetInAnimMs: offsetInAnim,
          intensity: animClip.intensity,
        );
      }
    }

    // 11. Calculate Fade In / Fade Out Progress
    double fadeOpacity = keyValues.opacity;

    if (clip.fadeInDurationMs > 0 && offsetInClip < clip.fadeInDurationMs) {
      fadeOpacity *= (offsetInClip / clip.fadeInDurationMs).clamp(0.0, 1.0);
    }

    final remainingMs = clip.effectiveDurationMs - offsetInClip;
    if (clip.fadeOutDurationMs > 0 && remainingMs < clip.fadeOutDurationMs) {
      fadeOpacity *= (remainingMs / clip.fadeOutDurationMs).clamp(0.0, 1.0);
    }

    // 12. Transition Entrance Effect
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

    // 13. Real CapCut-style Visual Video Effects
    if (clip.effectType != VideoEffectType.none) {
      frameContent = _applyVideoEffect(
        content: frameContent,
        effect: clip.effectType,
        intensity: clip.effectIntensity,
        offsetInClipMs: offsetInClip,
      );
    }

    return frameContent;
  }

  Widget _applyChromaKey(Widget content, ChromaKeyConfigEntity config) {
    return ChromaKeyFilter.apply(
      child: content,
      config: config,
    );
  }

  Widget _buildChromaKeyCrosshairOverlay(double canvasWidth, double canvasHeight, VideoClipEntity? targetClip) {
    if (targetClip == null) return const SizedBox.shrink();
    final state = widget.timelineState;
    final markerX = (state.chromaKeyCrosshairX * canvasWidth).clamp(0.0, canvasWidth);
    final markerY = (state.chromaKeyCrosshairY * canvasHeight).clamp(0.0, canvasHeight);

    final keyHex = targetClip.chromaKey?.keyColorHex ?? 0xFF00FF00;
    final sampledColor = _liveSampledColor ?? Color(keyHex);
    final hexString = '#${keyHex.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Interactive touch detector for sampling color across canvas
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _handleChromaPointer(details.localPosition, canvasWidth, canvasHeight, targetClip),
              onPanUpdate: (details) => _handleChromaPointer(details.localPosition, canvasWidth, canvasHeight, targetClip),
            ),
          ),

          // 2. High-Contrast Crosshair Target Marker
          Positioned(
            left: markerX - 28,
            top: markerY - 28,
            child: IgnorePointer(
              child: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glowing Ring
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00FF88), width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x9900FF88),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    // Horizontal Crosshair Line
                    Positioned(
                      left: 2,
                      right: 2,
                      height: 2,
                      child: Container(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    // Vertical Crosshair Line
                    Positioned(
                      top: 2,
                      bottom: 2,
                      width: 2,
                      child: Container(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    // Inner Target Core Dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sampledColor,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Attached Live Sampled Color Loupe Badge
          Positioned(
            left: (markerX + 32).clamp(10.0, (canvasWidth - 110.0).clamp(10.0, canvasWidth)),
            top: (markerY - 42).clamp(10.0, (canvasHeight - 42.0).clamp(10.0, canvasHeight)),
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2130),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.5)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sampledColor,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hexString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Semi-transparent guide hint banner with Done button
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.6)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.colorize, color: Color(0xFF00FF88), size: 12),
                      const SizedBox(width: 5),
                      const Text(
                        'Tap to pick color',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        key: const ValueKey('chroma_banner_done_btn'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.controller.toggleChromaKeyPickingMode(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF88),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.black, size: 12),
                              SizedBox(width: 2),
                              Text(
                                'Done',
                                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleChromaPointer(Offset localPos, double canvasWidth, double canvasHeight, VideoClipEntity targetClip) {
    final normX = (localPos.dx / canvasWidth).clamp(0.0, 1.0);
    final normY = (localPos.dy / canvasHeight).clamp(0.0, 1.0);
    widget.controller.setChromaKeyCrosshair(normX, normY);
    _sampleChromaKeyColorAt(localPos, canvasWidth, canvasHeight, targetClip);
  }

  Future<void> _sampleChromaKeyColorAt(Offset localOffset, double width, double height, VideoClipEntity targetClip) async {
    try {
      final boundary = _chromaPreviewBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData != null) {
          final scaleX = image.width / width;
          final scaleY = image.height / height;
          final px = (localOffset.dx * scaleX).clamp(0, image.width - 1).toInt();
          final py = (localOffset.dy * scaleY).clamp(0, image.height - 1).toInt();
          final index = (py * image.width + px) * 4;
          final r = byteData.getUint8(index);
          final g = byteData.getUint8(index + 1);
          final b = byteData.getUint8(index + 2);
          final color = Color.fromARGB(255, r, g, b);
          final colorHex = (0xFF << 24) | (r << 16) | (g << 8) | b;
          if (mounted) {
            setState(() => _liveSampledColor = color);
            widget.controller.sampleChromaKeyColor(targetClip.id, colorHex);
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      final defaultHex = targetClip.chromaKey?.keyColorHex ?? 0xFF00FF00;
      setState(() => _liveSampledColor = Color(defaultHex));
      widget.controller.sampleChromaKeyColor(targetClip.id, defaultHex);
    }
  }

  Widget _applyClipMask(Widget content, MaskConfigEntity mask) {
    switch (mask.shape) {
      case MaskShape.rectangle:
        return ClipRRect(
          borderRadius: BorderRadius.circular(mask.feather * 40.0),
          child: Align(
            alignment: Alignment(mask.centerX * 2 - 1, mask.centerY * 2 - 1),
            widthFactor: mask.widthFactor,
            heightFactor: mask.heightFactor,
            child: content,
          ),
        );
      case MaskShape.circle:
        return ClipOval(
          child: Align(
            alignment: Alignment(mask.centerX * 2 - 1, mask.centerY * 2 - 1),
            widthFactor: mask.widthFactor,
            heightFactor: mask.heightFactor,
            child: content,
          ),
        );
      case MaskShape.linear:
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: mask.widthFactor,
            child: content,
          ),
        );
      case MaskShape.filmstrip:
      case MaskShape.none:
        return content;
    }
  }

  Widget _applyClipAnimations({
    required Widget content,
    required VideoClipEntity clip,
    required int offsetInClipMs,
  }) {
    Widget animated = content;

    // 1. Entrance (IN) Animation
    if (clip.animationIn != ClipAnimationIn.none && offsetInClipMs < clip.animationInDurationMs) {
      final t = (offsetInClipMs / clip.animationInDurationMs).clamp(0.0, 1.0);
      switch (clip.animationIn) {
        case ClipAnimationIn.fadeIn:
          animated = Opacity(opacity: t, child: animated);
          break;
        case ClipAnimationIn.slideInLeft:
          animated = Transform.translate(offset: Offset(-300 * (1.0 - t), 0), child: animated);
          break;
        case ClipAnimationIn.slideInRight:
          animated = Transform.translate(offset: Offset(300 * (1.0 - t), 0), child: animated);
          break;
        case ClipAnimationIn.slideInUp:
          animated = Transform.translate(offset: Offset(0, 300 * (1.0 - t)), child: animated);
          break;
        case ClipAnimationIn.slideInDown:
          animated = Transform.translate(offset: Offset(0, -300 * (1.0 - t)), child: animated);
          break;
        case ClipAnimationIn.zoomIn:
          animated = Transform.scale(scale: 0.2 + (0.8 * t), child: animated);
          break;
        case ClipAnimationIn.popIn:
          final bounce = sin(t * 3.14159 / 2) * 1.05;
          animated = Transform.scale(scale: bounce.clamp(0.0, 1.1), child: animated);
          break;
        case ClipAnimationIn.bounceIn:
          final bounce = (1.0 - pow(1.0 - t, 2)) * 1.0;
          animated = Transform.scale(scale: bounce, child: animated);
          break;
        case ClipAnimationIn.rotateIn:
          animated = Transform.rotate(angle: (1.0 - t) * 3.14159, child: animated);
          break;
        case ClipAnimationIn.blurIn:
          animated = Opacity(opacity: t, child: animated);
          break;
        case ClipAnimationIn.flipInX:
          final rotX = (1.0 - t) * 1.5708;
          animated = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateX(rotX),
            child: animated,
          );
          break;
        case ClipAnimationIn.flipInY:
          final rotY = (1.0 - t) * 1.5708;
          animated = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(rotY),
            child: animated,
          );
          break;
        case ClipAnimationIn.spinIn:
          animated = Transform.rotate(
            angle: (1.0 - t) * 6.28318,
            child: Transform.scale(scale: t, child: animated),
          );
          break;
        case ClipAnimationIn.swingIn:
          final swing = sin((1.0 - t) * 3.14159) * 0.25;
          animated = Transform.rotate(alignment: Alignment.topCenter, angle: swing, child: animated);
          break;
        case ClipAnimationIn.dropIn:
          final dropY = -350 * pow(1.0 - t, 2);
          animated = Transform.translate(offset: Offset(0, dropY.toDouble()), child: animated);
          break;
        case ClipAnimationIn.none:
          break;
      }
    }

    // 2. Exit (OUT) Animation
    final remainingMs = clip.effectiveDurationMs - offsetInClipMs;
    if (clip.animationOut != ClipAnimationOut.none && remainingMs < clip.animationOutDurationMs) {
      final t = (remainingMs / clip.animationOutDurationMs).clamp(0.0, 1.0);
      switch (clip.animationOut) {
        case ClipAnimationOut.fadeOut:
          animated = Opacity(opacity: t, child: animated);
          break;
        case ClipAnimationOut.slideOutLeft:
          animated = Transform.translate(offset: Offset(-300 * (1.0 - t), 0), child: animated);
          break;
        case ClipAnimationOut.slideOutRight:
          animated = Transform.translate(offset: Offset(300 * (1.0 - t), 0), child: animated);
          break;
        case ClipAnimationOut.slideOutUp:
          animated = Transform.translate(offset: Offset(0, -300 * (1.0 - t)), child: animated);
          break;
        case ClipAnimationOut.slideOutDown:
          animated = Transform.translate(offset: Offset(0, 300 * (1.0 - t)), child: animated);
          break;
        case ClipAnimationOut.zoomOut:
          animated = Transform.scale(scale: t.clamp(0.0, 1.0), child: animated);
          break;
        case ClipAnimationOut.popOut:
          animated = Transform.scale(scale: (t * 0.9).clamp(0.0, 1.0), child: animated);
          break;
        case ClipAnimationOut.rotateOut:
          animated = Transform.rotate(angle: (1.0 - t) * 3.14159, child: animated);
          break;
        case ClipAnimationOut.blurOut:
          animated = Opacity(opacity: t, child: animated);
          break;
        case ClipAnimationOut.flipOutX:
          final rotX = (1.0 - t) * 1.5708;
          animated = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateX(rotX),
            child: animated,
          );
          break;
        case ClipAnimationOut.flipOutY:
          final rotY = (1.0 - t) * 1.5708;
          animated = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(rotY),
            child: animated,
          );
          break;
        case ClipAnimationOut.spinOut:
          animated = Transform.rotate(
            angle: (1.0 - t) * -6.28318,
            child: Transform.scale(scale: t, child: animated),
          );
          break;
        case ClipAnimationOut.swingOut:
          final swing = sin((1.0 - t) * 3.14159) * -0.25;
          animated = Transform.rotate(alignment: Alignment.topCenter, angle: swing, child: animated);
          break;
        case ClipAnimationOut.shrinkOut:
          animated = Transform.scale(scale: t * t, child: animated);
          break;
        case ClipAnimationOut.none:
          break;
      }
    }

    // 3. COMBO Animation
    if (clip.animationCombo != ClipAnimationCombo.none) {
      final cycle = (offsetInClipMs % 1200) / 1200.0;
      switch (clip.animationCombo) {
        case ClipAnimationCombo.pulse:
          final p = 1.0 + (0.08 * sin(cycle * 6.28318));
          animated = Transform.scale(scale: p, child: animated);
          break;
        case ClipAnimationCombo.zoomRotate:
          final rot = 0.05 * sin(cycle * 6.28318);
          final sc = 1.0 + (0.06 * cos(cycle * 6.28318));
          animated = Transform.rotate(angle: rot, child: Transform.scale(scale: sc, child: animated));
          break;
        case ClipAnimationCombo.shake:
          final sx = 4.0 * sin(cycle * 25.0);
          animated = Transform.translate(offset: Offset(sx, 0), child: animated);
          break;
        case ClipAnimationCombo.bounce:
          final sy = (sin(cycle * 6.28318).abs()) * -12.0;
          animated = Transform.translate(offset: Offset(0, sy), child: animated);
          break;
        case ClipAnimationCombo.floating:
          final fy = sin(cycle * 6.28318) * 8.0;
          animated = Transform.translate(offset: Offset(0, fy), child: animated);
          break;
        case ClipAnimationCombo.heartbeat:
          final hb = cycle < 0.3 ? (1.0 + 0.12 * sin(cycle * 10.0)) : 1.0;
          animated = Transform.scale(scale: hb, child: animated);
          break;
        case ClipAnimationCombo.sway:
          final swayRot = 0.04 * sin(cycle * 6.28318);
          animated = Transform.rotate(angle: swayRot, child: animated);
          break;
        case ClipAnimationCombo.pendulum:
          final pend = 0.08 * sin(cycle * 6.28318);
          animated = Transform.rotate(alignment: Alignment.topCenter, angle: pend, child: animated);
          break;
        case ClipAnimationCombo.wobble:
          final wob = 0.06 * sin(cycle * 12.0);
          animated = Transform.rotate(angle: wob, child: animated);
          break;
        case ClipAnimationCombo.flashBeat:
          final fbScale = cycle < 0.2 ? (1.0 + 0.15 * sin(cycle * 15.0)) : 1.0;
          animated = Transform.scale(scale: fbScale, child: animated);
          break;
        case ClipAnimationCombo.spin360:
          animated = Transform.rotate(angle: cycle * 6.28318, child: animated);
          break;
        case ClipAnimationCombo.rubberBand:
          final rb = 1.0 + 0.1 * sin(cycle * 6.28318);
          animated = Transform.scale(scaleX: rb, scaleY: 1.0 / rb, child: animated);
          break;
        case ClipAnimationCombo.jiggle:
          final jx = 3.0 * sin(cycle * 30.0);
          final jy = 3.0 * cos(cycle * 30.0);
          animated = Transform.translate(offset: Offset(jx, jy), child: animated);
          break;
        case ClipAnimationCombo.none:
          break;
      }
    }

    return animated;
  }

  Widget _applyTimelineAnimation({
    required Widget content,
    required ClipAnimationCombo combo,
    required int offsetInAnimMs,
    required double intensity,
  }) {
    Widget animated = content;
    final cycle = (offsetInAnimMs % 1000) / 1000.0;

    switch (combo) {
      case ClipAnimationCombo.pulse:
        final pulse = 1.0 + (0.08 * sin(cycle * 6.28318) * intensity);
        animated = Transform.scale(scale: pulse, child: animated);
        break;
      case ClipAnimationCombo.zoomRotate:
        final zrScale = 1.0 + (0.06 * sin(cycle * 6.28318) * intensity);
        final zrRot = 0.05 * sin(cycle * 6.28318) * intensity;
        animated = Transform.rotate(
          angle: zrRot,
          child: Transform.scale(scale: zrScale, child: animated),
        );
        break;
      case ClipAnimationCombo.shake:
        final sx = 5.0 * sin(cycle * 25.0) * intensity;
        animated = Transform.translate(offset: Offset(sx, 0), child: animated);
        break;
      case ClipAnimationCombo.bounce:
        final sy = (sin(cycle * 6.28318).abs()) * -14.0 * intensity;
        animated = Transform.translate(offset: Offset(0, sy), child: animated);
        break;
      case ClipAnimationCombo.floating:
        final fy = sin(cycle * 6.28318) * 10.0 * intensity;
        animated = Transform.translate(offset: Offset(0, fy), child: animated);
        break;
      case ClipAnimationCombo.heartbeat:
        final hb = cycle < 0.3 ? (1.0 + 0.14 * sin(cycle * 10.0) * intensity) : 1.0;
        animated = Transform.scale(scale: hb, child: animated);
        break;
      case ClipAnimationCombo.sway:
        final swayRot = 0.05 * sin(cycle * 6.28318) * intensity;
        animated = Transform.rotate(angle: swayRot, child: animated);
        break;
      case ClipAnimationCombo.pendulum:
        final pend = 0.09 * sin(cycle * 6.28318) * intensity;
        animated = Transform.rotate(alignment: Alignment.topCenter, angle: pend, child: animated);
        break;
      case ClipAnimationCombo.wobble:
        final wob = 0.07 * sin(cycle * 12.0) * intensity;
        animated = Transform.rotate(angle: wob, child: animated);
        break;
      case ClipAnimationCombo.flashBeat:
        final fbScale = cycle < 0.2 ? (1.0 + 0.16 * sin(cycle * 15.0) * intensity) : 1.0;
        animated = Transform.scale(scale: fbScale, child: animated);
        break;
      case ClipAnimationCombo.spin360:
        animated = Transform.rotate(angle: cycle * 6.28318 * intensity, child: animated);
        break;
      case ClipAnimationCombo.rubberBand:
        final rb = 1.0 + 0.12 * sin(cycle * 6.28318) * intensity;
        animated = Transform.scale(scaleX: rb, scaleY: 1.0 / rb, child: animated);
        break;
      case ClipAnimationCombo.jiggle:
        final jx = 3.5 * sin(cycle * 30.0) * intensity;
        final jy = 3.5 * cos(cycle * 30.0) * intensity;
        animated = Transform.translate(offset: Offset(jx, jy), child: animated);
        break;
      case ClipAnimationCombo.none:
        break;
    }

    return animated;
  }

  Widget _applyVideoEffect({
    required Widget content,
    required VideoEffectType effect,
    required double intensity,
    required int offsetInClipMs,
  }) {
    switch (effect) {
      case VideoEffectType.flash:
        // High-speed bright luminous white strobe
        final flashCycle = offsetInClipMs % 350;
        final isFlashing = flashCycle < 120;
        final flashAlpha = isFlashing ? (1.0 - (flashCycle / 120.0)) * 0.9 * intensity : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (flashAlpha > 0.01)
              Container(color: Colors.white.withValues(alpha: flashAlpha.clamp(0.0, 1.0))),
          ],
        );

      case VideoEffectType.blackFlash2:
        // Rhythmic dark beat strobe flash
        final bCycle = offsetInClipMs % 450;
        final isBFlashing = bCycle < 150;
        final bAlpha = isBFlashing ? (1.0 - (bCycle / 150.0)) * 0.95 * intensity : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (bAlpha > 0.01)
              Container(color: Colors.black.withValues(alpha: bAlpha.clamp(0.0, 1.0))),
          ],
        );

      case VideoEffectType.shake:
        // Dynamic jitter camera shake
        final t = offsetInClipMs / 50.0;
        final dx = sin(t * 8.3) * 9.0 * intensity;
        final dy = cos(t * 11.7) * 7.0 * intensity;
        final rot = sin(t * 6.1) * 0.035 * intensity;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rot,
            child: content,
          ),
        );

      case VideoEffectType.superLarge:
        // Cinematic breathing zoom with pulse
        final pulse = 1.0 + (0.22 * (sin(offsetInClipMs / 300.0).abs()) * intensity);
        return Transform.scale(
          scale: pulse,
          child: content,
        );

      case VideoEffectType.rollingFilm:
        // 35mm film border with vertical moving sprockets & vintage tone
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.15, 0.05, 0.0, 0.0, 10,
                0.05, 0.95, 0.0, 0.0, 5,
                0.0, 0.05, 0.75, 0.0, -10,
                0.0, 0.0, 0.0, 1.0, 0,
              ]),
              child: content,
            ),
            CustomPaint(
              painter: _RollingFilmEffectPainter(offsetMs: offsetInClipMs),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.explosion:
        // Fiery expanding golden shockwave particles
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _ExplosionEffectPainter(
                offsetMs: offsetInClipMs,
                intensity: intensity,
              ),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.glitch:
        // Chromatic aberration RGB split & horizontal glitch displacement
        final glitchCycle = (offsetInClipMs ~/ 100) % 5 == 0;
        final glitchShift = glitchCycle ? (sin(offsetInClipMs / 25.0) * 10.0 * intensity) : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (glitchCycle)
              Transform.translate(
                offset: Offset(-glitchShift, 0),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Color(0x8800FFFF), BlendMode.screen),
                  child: content,
                ),
              ),
            Transform.translate(
              offset: Offset(glitchShift * 0.5, 0),
              child: content,
            ),
            if (glitchCycle)
              Transform.translate(
                offset: Offset(glitchShift, 0),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Color(0x88FF0055), BlendMode.screen),
                  child: content,
                ),
              ),
          ],
        );

      case VideoEffectType.neonGlow:
        // Cyberpunk saturated edge neon shine
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.4, 0.0, 0.2, 0.0, 20,
                0.0, 1.3, 0.2, 0.0, 15,
                0.2, 0.0, 1.7, 0.0, 30,
                0.0, 0.0, 0.0, 1.0, 0,
              ]),
              child: content,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.5 * intensity),
                  width: 3.5,
                ),
              ),
            ),
          ],
        );

      case VideoEffectType.retroVhs:
        // Vintage 90s CRT scanlines & VHS timestamp
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _VhsScanlinesPainter(offsetMs: offsetInClipMs),
              size: Size.infinite,
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Text(
                'PLAY ▶ SP 00:${(offsetInClipMs ~/ 1000).toString().padLeft(2, '0')}:${((offsetInClipMs % 1000) ~/ 10).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Color(0xFF38EF7D),
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
          ],
        );

      case VideoEffectType.sparkles:
        // Glittering starlight sparkles
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _SparklesEffectPainter(
                offsetMs: offsetInClipMs,
                intensity: intensity,
              ),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.heartFloat:
        // Floating romantic hearts
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _HeartsEffectPainter(
                offsetMs: offsetInClipMs,
                intensity: intensity,
              ),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.heartbeatZoom:
        // Rhythmic bass pulse
        final beat = 1.0 + (0.15 * pow(sin(offsetInClipMs / 180.0).abs(), 3) * intensity);
        return Transform.scale(scale: beat, child: content);

      case VideoEffectType.kaleidoscope:
        // Multi-angle prism mirror
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Transform.scale(
              scaleX: -1.0,
              child: Opacity(
                opacity: 0.35 * intensity,
                child: content,
              ),
            ),
          ],
        );

      case VideoEffectType.fadeIn:
        final inProgress = (offsetInClipMs / 1500.0).clamp(0.0, 1.0);
        return Opacity(
          opacity: inProgress,
          child: content,
        );

      case VideoEffectType.edgeGlow:
        // Vibrant neon edge glow
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.65 * intensity),
                  width: 4.0 * intensity,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.5 * intensity),
                    blurRadius: 16 * intensity,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );

      case VideoEffectType.filmGrain:
        // Vintage 8mm dust & grain
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.95, 0.05, 0.0, 0.0, 0,
                0.05, 0.90, 0.0, 0.0, 0,
                0.0, 0.05, 0.85, 0.0, 0,
                0.0, 0.0, 0.0, 1.0, 0,
              ]),
              child: content,
            ),
            CustomPaint(
              painter: _FilmGrainEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.lightLeak:
        // Warm golden lens flare
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _LightLeakEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.laserBeams:
        // Futuristic neon laser sweeps
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _LaserBeamsEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.radialBlur:
        // High-speed action zoom burst radial blur
        final blurZoom = 1.0 + (0.15 * sin(offsetInClipMs / 200.0).abs() * intensity);
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(scale: blurZoom * 1.05, child: Opacity(opacity: 0.35 * intensity, child: content)),
            Transform.scale(scale: blurZoom, child: content),
          ],
        );

      case VideoEffectType.motionBlur:
        // Directional horizontal velocity streak
        final mShift = sin(offsetInClipMs / 80.0) * 12.0 * intensity;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(offset: Offset(-mShift, 0), child: Opacity(opacity: 0.3 * intensity, child: content)),
            content,
            Transform.translate(offset: Offset(mShift, 0), child: Opacity(opacity: 0.3 * intensity, child: content)),
          ],
        );

      case VideoEffectType.softDream:
        // Ethereal pastel dreamy glow
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.1, 0.1, 0.1, 0.0, 15,
                0.1, 1.1, 0.1, 0.0, 15,
                0.1, 0.1, 1.2, 0.0, 25,
                0.0, 0.0, 0.0, 1.0, 0,
              ]),
              child: content,
            ),
            Container(color: const Color(0xFFFBC2EB).withValues(alpha: 0.12 * intensity)),
          ],
        );

      case VideoEffectType.waveWarp:
        // Liquid ocean ripple wave displacement
        final wavePhase = offsetInClipMs / 250.0;
        final waveScaleX = 1.0 + (0.08 * sin(wavePhase) * intensity);
        final waveScaleY = 1.0 + (0.08 * cos(wavePhase) * intensity);
        return Transform.scale(
          scaleX: waveScaleX,
          scaleY: waveScaleY,
          child: content,
        );

      case VideoEffectType.pixelate:
        // 8-bit arcade mosaic
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _PixelateEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.vcrDistort:
        // Analog magnetic tape tracking static band
        final vcrY = (offsetInClipMs / 4.0) % 600;
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Positioned(
              top: vcrY,
              left: 0,
              right: 0,
              height: 20,
              child: Container(
                color: Colors.white.withValues(alpha: 0.22 * intensity),
              ),
            ),
          ],
        );

      case VideoEffectType.rgbSplit:
        // Dual red & cyan stereo chromatic shift
        final splitOffset = sin(offsetInClipMs / 120.0) * 10.0 * intensity;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(-splitOffset, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0xFFFF0055), BlendMode.screen),
                child: content,
              ),
            ),
            content,
            Transform.translate(
              offset: Offset(splitOffset, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0xFF00FFFF), BlendMode.screen),
                child: content,
              ),
            ),
          ],
        );

      case VideoEffectType.mirrorQuad:
        // 4-quadrant symmetric mirror
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Transform.scale(scaleX: -1.0, child: Opacity(opacity: 0.3 * intensity, child: content)),
            Transform.scale(scaleY: -1.0, child: Opacity(opacity: 0.3 * intensity, child: content)),
          ],
        );

      case VideoEffectType.discoStrobe:
        // Multicolor dancefloor club strobe pulse
        final discoColors = [
          const Color(0xFFFF007F),
          const Color(0xFF00FFFF),
          const Color(0xFFFFD700),
          const Color(0xFF7B2CBF),
        ];
        final dIndex = (offsetInClipMs ~/ 180) % discoColors.length;
        final dAlpha = (sin(offsetInClipMs / 60.0).abs() * 0.35 * intensity).clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Container(color: discoColors[dIndex].withValues(alpha: dAlpha)),
          ],
        );

      case VideoEffectType.bassRumble:
        // Heavy subwoofer screen rumble
        final rumbleT = offsetInClipMs / 30.0;
        final rX = sin(rumbleT * 15.0) * 8.0 * intensity;
        final rY = cos(rumbleT * 19.0) * 8.0 * intensity;
        return Transform.translate(
          offset: Offset(rX, rY),
          child: content,
        );

      case VideoEffectType.starGlow:
        // 4-point starburst cross-glint flares
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _StarGlowEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.sepiaVintage:
        // 1920s silent cinema sepia
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.393 * 1.2, 0.769 * 1.2, 0.189 * 1.2, 0, 0,
            0.349 * 1.1, 0.686 * 1.1, 0.168 * 1.1, 0, 0,
            0.272 * 0.9, 0.534 * 0.9, 0.131 * 0.9, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: content,
        );

      case VideoEffectType.cinemaScope:
        // 2.39:1 anamorphic cinema widescreen bars with slow push
        final pushScale = 1.0 + (0.05 * (offsetInClipMs / 5000.0).clamp(0.0, 1.0));
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(scale: pushScale, child: content),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 36, color: Colors.black),
                Container(height: 36, color: Colors.black),
              ],
            ),
          ],
        );

      case VideoEffectType.matrixRain:
        // Digital green Matrix code rain
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _MatrixRainEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.cyberGrid:
        // Synthwave 80s 3D perspective grid
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _CyberGridEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.fireEmbers:
        // Rising campfire sparks and embers
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _FireEmbersEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.snowFall:
        // Winter snowfall
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _SnowFallEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.rainStorm:
        // Slanted rain storm
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _RainStormEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.lightningBolt:
        // Electric lightning bolt
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _LightningBoltEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.goldenDust:
        // Luxury golden bokeh dust
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _GoldenDustEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.smokeAtmosphere:
        // Volumetric stage smoke
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _SmokeAtmosphereEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.bubbleFloat:
        // Floating iridescent soap bubbles
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _BubbleFloatEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.fireworks:
        // Celebratory night fireworks
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _FireworksEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.lensZoomBlur:
        // Directional snap zoom blur
        final zCycle = (sin(offsetInClipMs / 250.0).abs()) * 0.25 * intensity;
        return Transform.scale(
          scale: 1.0 + zCycle,
          child: content,
        );

      case VideoEffectType.diamondSparkle:
        // Luxury gemstone sparkles
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _StarGlowEffectPainter(offsetMs: offsetInClipMs, intensity: intensity * 1.5),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.hologramGlitch:
        // Holographic blue scanline flicker
        final hPhase = (offsetInClipMs ~/ 60) % 4 == 0;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(Color(0xFF00E5FF), BlendMode.color),
              child: content,
            ),
            if (hPhase)
              Container(color: const Color(0xFF00E5FF).withValues(alpha: 0.15 * intensity)),
          ],
        );

      case VideoEffectType.vignetteDark:
        // Cinema dark vignette
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.85,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75 * intensity),
                  ],
                ),
              ),
            ),
          ],
        );

      case VideoEffectType.thermalVision:
        // Infrared thermal heat map
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            -1.5, 2.0, -0.5, 0, 50,
            0.5, -1.0, 1.5, 0, 30,
            2.0, -1.0, -1.0, 0, 80,
            0, 0, 0, 1, 0,
          ]),
          child: content,
        );

      case VideoEffectType.nightVision:
        // Green military night vision
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.1, 0.8, 0.1, 0, 20,
                0.1, 1.5, 0.1, 0, 40,
                0.1, 0.8, 0.1, 0, 20,
                0, 0, 0, 1, 0,
              ]),
              child: content,
            ),
            CustomPaint(
              painter: _OldTvStaticEffectPainter(offsetMs: offsetInClipMs, intensity: intensity * 0.4),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.halftoneComic:
        // Pop-art comic screen
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            1.6, 0.0, 0.0, 0, 20,
            0.0, 1.4, 0.0, 0, 15,
            0.0, 0.0, 1.2, 0, 10,
            0, 0, 0, 1, 0,
          ]),
          child: content,
        );

      case VideoEffectType.colorInvert:
        // Solarized inverted film
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            -1, 0, 0, 0, 255,
            0, -1, 0, 0, 255,
            0, 0, -1, 0, 255,
            0, 0, 0, 1, 0,
          ]),
          child: content,
        );

      case VideoEffectType.duotoneNeon:
        // Cyberpunk duotone
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.8, 0.2, 0.5, 0, 40,
            0.1, 0.7, 0.8, 0, 20,
            0.6, 0.1, 1.2, 0, 60,
            0, 0, 0, 1, 0,
          ]),
          child: content,
        );

      case VideoEffectType.oldTvStatic:
        // TV snow static
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _OldTvStaticEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.dizzySpin:
        // Hypnotic vortex rotation
        final spin = sin(offsetInClipMs / 300.0) * 0.08 * intensity;
        return Transform.rotate(
          angle: spin,
          child: Transform.scale(scale: 1.0 + (spin.abs() * 2), child: content),
        );

      case VideoEffectType.ghostTrail:
        // Slow-mo motion ghost echo
        final gShift = sin(offsetInClipMs / 150.0) * 16.0 * intensity;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(-gShift, -gShift * 0.5),
              child: Opacity(opacity: 0.3 * intensity, child: content),
            ),
            content,
            Transform.translate(
              offset: Offset(gShift, gShift * 0.5),
              child: Opacity(opacity: 0.3 * intensity, child: content),
            ),
          ],
        );

      case VideoEffectType.butterflySwarm:
        // Fluttering butterflies
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _ButterflyEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.speedLines:
        // Anime manga speed burst lines
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _SpeedLinesEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.glowRings:
        // Pulsing energy halo rings
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _GlowRingsEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.colorPulse:
        // Rhythmic RGB saturation wave
        final cpPhase = (offsetInClipMs / 400.0) * 2 * pi;
        final redBoost = (sin(cpPhase).abs() * 0.5 * intensity) + 1.0;
        final blueBoost = (cos(cpPhase).abs() * 0.5 * intensity) + 1.0;
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(<double>[
            redBoost, 0, 0, 0, 10,
            0, 1.0, 0, 0, 10,
            0, 0, blueBoost, 0, 20,
            0, 0, 0, 1, 0,
          ]),
          child: content,
        );

      case VideoEffectType.confettiParty:
        // Multicolored falling confetti
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _ConfettiEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.filmBurn:
        // 35mm film burn edge flare
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _FilmBurnEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.waterRipples:
        // Refractive water ripples
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _WaterRipplesEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.iceFrost:
        // Freezing ice crystal frosty borders
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _IceFrostEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.heartGlow:
        // Glowing heart aura
        final hPulse = (sin(offsetInClipMs / 200.0).abs() * 0.4 + 0.6) * intensity;
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFF007A).withValues(alpha: 0.5 * hPulse),
                  width: 8,
                ),
              ),
            ),
          ],
        );

      case VideoEffectType.fireAura:
        // Blazing dragon fire aura
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _FireEmbersEffectPainter(offsetMs: offsetInClipMs, intensity: intensity * 1.5),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.comicBoom:
        // Pop-Art comic boom
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.5, 0, 0, 0, 30,
                0, 1.3, 0, 0, 20,
                0, 0, 1.1, 0, 10,
                0, 0, 0, 1, 0,
              ]),
              child: content,
            ),
            CustomPaint(
              painter: _SpeedLinesEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.vhsPause:
        // VHS tape pause tracking error
        final jitter = sin(offsetInClipMs / 20.0) * 6.0 * intensity;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(jitter, 0),
              child: content,
            ),
            CustomPaint(
              painter: _OldTvStaticEffectPainter(offsetMs: offsetInClipMs, intensity: intensity * 0.6),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.mirrorTunnel:
        // Infinite reflection tunnel
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Transform.scale(scale: 0.75, child: Opacity(opacity: 0.5 * intensity, child: content)),
            Transform.scale(scale: 0.5, child: Opacity(opacity: 0.25 * intensity, child: content)),
          ],
        );

      case VideoEffectType.bloomGlow:
        // Dreamy soft bloom
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            1.25, 0.05, 0.05, 0, 20,
            0.05, 1.25, 0.05, 0, 20,
            0.05, 0.05, 1.25, 0, 20,
            0, 0, 0, 1, 0,
          ]),
          child: content,
        );

      case VideoEffectType.polaroidFrame:
        // Vintage polaroid photo frame
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5F0),
            border: Border.all(color: const Color(0xFFE8E4D9), width: 12),
          ),
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              1.1, 0, 0, 0, 15,
              0, 1.05, 0, 0, 10,
              0, 0, 0.9, 0, 5,
              0, 0, 0, 1, 0,
            ]),
            child: content,
          ),
        );

      case VideoEffectType.cyberScan:
        // Biometric target HUD scanner
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _CyberScanEffectPainter(offsetMs: offsetInClipMs, intensity: intensity),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.videoCam:
        // Vintage camcorder viewfinder HUD: [● REC], battery, crosshairs, timecode, corner brackets
        final recBlink = (offsetInClipMs ~/ 600) % 2 == 0;
        final sec = offsetInClipMs ~/ 1000;
        final frame = ((offsetInClipMs % 1000) ~/ 33);
        final timecodeStr = '00:${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}:${frame.toString().padLeft(2, '0')}';
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.08, 0.02, 0.0, 0, 8,
                0.0, 1.05, 0.02, 0, 6,
                0.02, 0.0, 0.95, 0, -4,
                0, 0, 0, 1, 0,
              ]),
              child: content,
            ),
            CustomPaint(
              painter: _VideoCamHudPainter(
                isRecBlinking: recBlink,
                timecode: timecodeStr,
                intensity: intensity,
              ),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.phoneDrift:
        // Floating handheld camera drift with dynamic inertia, subtle Dutch angle, and drift momentum
        final tDrift = offsetInClipMs / 1000.0;
        final driftDx = (sin(tDrift * 1.6) * 14.0 + cos(tDrift * 0.7) * 8.0) * intensity;
        final driftDy = (cos(tDrift * 1.3) * 10.0 + sin(tDrift * 0.9) * 6.0) * intensity;
        final driftRot = (sin(tDrift * 1.1) * 0.032 + cos(tDrift * 0.5) * 0.018) * intensity;
        final driftScale = 1.06 + (sin(tDrift * 0.8).abs() * 0.04 * intensity);
        return Transform.translate(
          offset: Offset(driftDx, driftDy),
          child: Transform.rotate(
            angle: driftRot,
            child: Transform.scale(
              scale: driftScale,
              child: content,
            ),
          ),
        );

      case VideoEffectType.lightningCloud:
        // Thunderstorm dark clouds with intense branching electric lightning strikes and illumination flashes
        final lCycle = offsetInClipMs % 2200;
        final isLightningStrike = lCycle < 140 || (lCycle > 260 && lCycle < 360);
        final flashAlpha = isLightningStrike
            ? ((sin(offsetInClipMs / 15.0).abs() * 0.5 + 0.5) * 0.85 * intensity)
            : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.matrix(<double>[
                0.82 + (flashAlpha * 0.4), 0, 0, 0, flashAlpha * 40,
                0, 0.84 + (flashAlpha * 0.4), 0, 0, flashAlpha * 45,
                0, 0, 0.92 + (flashAlpha * 0.4), 0, flashAlpha * 65,
                0, 0, 0, 1, 0,
              ]),
              child: content,
            ),
            if (flashAlpha > 0.02)
              Container(color: const Color(0xFFE0F7FA).withValues(alpha: flashAlpha * 0.4)),
            CustomPaint(
              painter: _LightningCloudEffectPainter(
                offsetMs: offsetInClipMs,
                isStriking: isLightningStrike,
                intensity: intensity,
              ),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.crossSplit:
        // 4-panel cross split screen with quad mirrors and dynamic panels
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            CustomPaint(
              painter: _CrossSplitEffectPainter(
                offsetMs: offsetInClipMs,
                intensity: intensity,
              ),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.obliqueBlur:
        // 45-degree diagonal action prism blur with chromatic aberration
        final oShift = (sin(offsetInClipMs / 120.0).abs() * 12.0 + 2.0) * intensity;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(-oShift, -oShift),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0x7700FFFF), BlendMode.screen),
                child: content,
              ),
            ),
            Transform.translate(
              offset: Offset(oShift, oShift),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0x77FF0055), BlendMode.screen),
                child: content,
              ),
            ),
            content,
          ],
        );

      case VideoEffectType.edgeSilhouette:
        // Luminous neon contour detection tracing the subject with glowing aura
        final ePulse = (sin(offsetInClipMs / 250.0).abs() * 0.4 + 0.6) * intensity;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.4, 0.0, 0.3, 0, 30,
                0.0, 1.2, 0.3, 0, 15,
                0.3, 0.0, 1.6, 0, 45,
                0, 0, 0, 1, 0,
              ]),
              child: content,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFF007A).withValues(alpha: 0.6 * ePulse),
                  width: 6.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.5 * ePulse),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );

      case VideoEffectType.citySunset:
        // Golden hour warm skyline haze with atmospheric sun flare and bloom
        final sBreath = 1.0 + (sin(offsetInClipMs / 400.0).abs() * 0.04 * intensity);
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: sBreath,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  1.25, 0.1, 0.0, 0, 25,
                  0.05, 1.05, 0.0, 0, 15,
                  0.0, 0.05, 0.85, 0, -10,
                  0, 0, 0, 1, 0,
                ]),
                child: content,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF8008).withValues(alpha: 0.35 * intensity),
                    const Color(0xFFFFC837).withValues(alpha: 0.15 * intensity),
                    Colors.transparent,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ],
        );

      case VideoEffectType.verticalFilm:
        // Continuous vertical rolling 8mm/16mm film reel with sprocket margins
        return Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.1, 0.05, 0.0, 0, 10,
                0.05, 0.95, 0.05, 0, 5,
                0.0, 0.05, 0.75, 0, -10,
                0, 0, 0, 1, 0,
              ]),
              child: content,
            ),
            CustomPaint(
              painter: _RollingFilmEffectPainter(offsetMs: (offsetInClipMs * 1.5).round()),
              size: Size.infinite,
            ),
          ],
        );

      case VideoEffectType.prismRainbow:
        // Prismatic rainbow crystal light refraction and holographic glints
        final rShift = (sin(offsetInClipMs / 300.0) * 0.5 + 0.5);
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF0055).withValues(alpha: 0.25 * intensity),
                    const Color(0xFFFF9900).withValues(alpha: 0.20 * intensity),
                    const Color(0xFF00FFCC).withValues(alpha: 0.25 * intensity),
                    const Color(0xFF0066FF).withValues(alpha: 0.25 * intensity),
                    const Color(0xFFFF00CC).withValues(alpha: 0.20 * intensity),
                  ],
                  stops: [
                    0.0,
                    (0.25 + rShift * 0.1).clamp(0.0, 1.0),
                    (0.50 + rShift * 0.1).clamp(0.0, 1.0),
                    (0.75 + rShift * 0.1).clamp(0.0, 1.0),
                    1.0,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ],
        );

      case VideoEffectType.none:
        return content;
    }
  }

  Widget _buildSelectionTransformHandles(VideoClipEntity clip) {
    final isTransformingThisClip = _isGestureActive &&
        ((widget.timelineState.selectionType == SelectionType.videoClip && widget.timelineState.selectedItemId == clip.id) ||
         (widget.timelineState.selectionType == SelectionType.overlayClip && widget.timelineState.selectedItemId == clip.id));

    final offsetInClip = (widget.timelineState.playheadPositionMs - clip.timelineStartMs).clamp(0, clip.effectiveDurationMs);
    final baseValues = KeyframeValues(
      posX: clip.positionX,
      posY: clip.positionY,
      scale: clip.zoomScale,
      rotation: clip.rotationDegrees,
      opacity: clip.opacity,
    );
    final keyValues = KeyframeInterpolator.interpolate(
      keyframes: clip.keyframes,
      currentOffsetMs: offsetInClip,
      baseValues: baseValues,
    );

    final effectivePosX = isTransformingThisClip ? _livePosX : keyValues.posX;
    final effectivePosY = isTransformingThisClip ? _livePosY : keyValues.posY;
    final effectiveScale = isTransformingThisClip ? _liveZoom : keyValues.scale;
    final effectiveRot = isTransformingThisClip ? _liveRotation : keyValues.rotation;

    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(effectivePosX, effectivePosY),
        child: Transform.rotate(
          angle: effectiveRot * (3.14159 / 180),
          child: Transform.scale(
            scale: effectiveScale,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryLight, width: 2.0),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildCornerHandle(Alignment.topLeft, AppColors.primary),
                  _buildCornerHandle(Alignment.topRight, AppColors.primary),
                  _buildCornerHandle(Alignment.bottomLeft, AppColors.primary),
                  _buildCornerHandle(Alignment.bottomRight, AppColors.primary),
                  // Top Rotate Pin Anchor
                  Align(
                    alignment: Alignment.topCenter,
                    child: FractionalTranslation(
                      translation: const Offset(0, -1.3),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.rotate_right, color: Colors.white, size: 14),
                      ),
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

  Widget _buildClipQuickToolbar(VideoClipEntity clip) {
    final hasPrev = widget.controller.hasPrevKeyframe(clip.id);
    final hasNext = widget.controller.hasNextKeyframe(clip.id);
    final isAtKf = widget.controller.isAtKeyframe(clip.id);

    return Positioned(
      top: 12,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2028).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isAtKf ? AppColors.accentRose : AppColors.primaryLight, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Keyframe Jump Prev
              InkWell(
                onTap: hasPrev ? () => widget.controller.jumpToPrevKeyframe(clip.id) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Icon(Icons.arrow_left, size: 18, color: hasPrev ? Colors.white : Colors.white24),
                ),
              ),
              // Dynamic Keyframe Add/Remove Diamond (CapCut Style)
              InkWell(
                onTap: () => widget.controller.toggleKeyframeAtPlayhead(clip.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAtKf
                        ? AppColors.accentRose.withValues(alpha: 0.25)
                        : (clip.keyframes.isNotEmpty ? AppColors.accent.withValues(alpha: 0.25) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAtKf ? AppColors.accentRose : (clip.keyframes.isNotEmpty ? AppColors.accent : Colors.white24),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAtKf
                            ? Icons.diamond
                            : (clip.keyframes.isNotEmpty ? Icons.diamond_outlined : Icons.add_circle_outline),
                        size: 13,
                        color: isAtKf ? AppColors.accentRose : AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAtKf
                            ? 'Remove KF'
                            : (clip.keyframes.isEmpty ? 'Add Keyframe' : 'Add KF (${clip.keyframes.length})'),
                        style: TextStyle(
                          color: isAtKf ? AppColors.accentRose : AppColors.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Keyframe Jump Next
              InkWell(
                onTap: hasNext ? () => widget.controller.jumpToNextKeyframe(clip.id) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Icon(Icons.arrow_right, size: 18, color: hasNext ? Colors.white : Colors.white24),
                ),
              ),
              const SizedBox(width: 4),
              const Text('|', style: TextStyle(color: Colors.white24)),
              const SizedBox(width: 4),

              // Zoom Out
              InkWell(
                onTap: () => widget.controller.zoomClipOut(clip.id),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.zoom_out, size: 14, color: Colors.white),
                      SizedBox(width: 2),
                      Text('Zoom -', style: TextStyle(color: Colors.white, fontSize: 10.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Zoom Level Label
              Text(
                '${(clip.zoomScale * 100).toInt()}%',
                style: const TextStyle(color: AppColors.primaryLight, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 2),
              // Zoom In
              InkWell(
                onTap: () => widget.controller.zoomClipIn(clip.id),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.zoom_in, size: 14, color: Colors.white),
                      SizedBox(width: 2),
                      Text('Zoom +', style: TextStyle(color: Colors.white, fontSize: 10.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text('|', style: TextStyle(color: Colors.white24)),
              const SizedBox(width: 4),
              // Rotate 90
              InkWell(
                onTap: () => widget.controller.rotateClip90(clip.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.rotate_90_degrees_ccw, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 2),
                      Text('${clip.rotationDegrees.toInt()}°', style: const TextStyle(color: Colors.white, fontSize: 10.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Reset
              InkWell(
                onTap: () => widget.controller.resetClipTransform(clip.id),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Icon(Icons.restart_alt, size: 15, color: Colors.amber),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleOverlay(SubtitleEntity sub, bool isSelected) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: GestureDetector(
        onTap: () => widget.controller.setSelection(SelectionType.subtitle, sub.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: sub.backgroundColorHex != null ? Color(sub.backgroundColorHex!) : const Color(0x99000000),
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: AppColors.secondary, width: 1.5) : null,
          ),
          child: Text(
            sub.text,
            textAlign: TextAlign.center,
            style: FontHelper.getTextStyle(
              sub.fontFamily,
              fontSize: sub.fontSize,
              fontWeight: FontWeight.w600,
              color: Color(sub.colorHex),
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveTextOverlay({
    required TextOverlayEntity textEntity,
    required int currentPosMs,
    required bool isSelected,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final offsetInText = currentPosMs - textEntity.timelineStartMs;

    double opacity = 1.0;
    double translateY = 0.0;
    double translateX = 0.0;
    double scaleMultiplier = 1.0;
    double rotationAngle = 0.0;
    const animDurationMs = 500;

    if (offsetInText < animDurationMs) {
      final progress = (offsetInText / animDurationMs).clamp(0.0, 1.0);
      switch (textEntity.animationType) {
        case OverlayAnimationType.fadeIn:
          opacity = progress;
          break;
        case OverlayAnimationType.slideUp:
          translateY = (1.0 - progress) * 40.0;
          opacity = progress;
          break;
        case OverlayAnimationType.slideDown:
          translateY = -(1.0 - progress) * 40.0;
          opacity = progress;
          break;
        case OverlayAnimationType.slideLeft:
          translateX = (1.0 - progress) * 60.0;
          opacity = progress;
          break;
        case OverlayAnimationType.slideRight:
          translateX = -(1.0 - progress) * 60.0;
          opacity = progress;
          break;
        case OverlayAnimationType.zoomIn:
          scaleMultiplier = (progress * 1.15).clamp(0.0, 1.15);
          if (progress > 0.8) scaleMultiplier = 1.0 + (1.0 - progress) * 0.75;
          opacity = progress;
          break;
        case OverlayAnimationType.zoomOut:
          scaleMultiplier = 1.0 + (1.0 - progress) * 1.2;
          opacity = progress;
          break;
        case OverlayAnimationType.bounce:
          final bounceT = Curves.bounceOut.transform(progress);
          translateY = (1.0 - bounceT) * 35.0;
          opacity = progress;
          break;
        case OverlayAnimationType.spin:
          rotationAngle = (1.0 - progress) * pi * 2;
          scaleMultiplier = progress;
          opacity = progress;
          break;
        case OverlayAnimationType.flip:
          scaleMultiplier = progress.clamp(0.05, 1.0);
          opacity = progress;
          break;
        case OverlayAnimationType.drop:
          final dropT = Curves.bounceOut.transform(progress);
          translateY = -(1.0 - dropT) * 60.0;
          opacity = progress;
          break;
        case OverlayAnimationType.flash:
          opacity = ((offsetInText ~/ 70) % 2 == 0) ? 1.0 : 0.2;
          break;
        case OverlayAnimationType.swing:
          final swingT = sin(progress * pi * 4) * (1.0 - progress);
          rotationAngle = swingT * 0.25;
          opacity = progress;
          break;
        case OverlayAnimationType.blur:
          opacity = progress;
          scaleMultiplier = 1.15 - (0.15 * progress);
          break;
        case OverlayAnimationType.shake:
          translateX = sin(progress * pi * 8) * 8.0 * (1.0 - progress);
          opacity = progress;
          break;
        default:
          break;
      }
    }

    // Continuous & loop animations
    switch (textEntity.animationType) {
      case OverlayAnimationType.pulse:
        scaleMultiplier = 1.0 + sin(offsetInText * 0.008).abs() * 0.12;
        break;
      case OverlayAnimationType.glitch:
        if ((offsetInText ~/ 140) % 3 == 0) {
          translateX = sin(offsetInText * 0.05) * 6.0;
          opacity = 0.85;
        }
        break;
      case OverlayAnimationType.glow:
        scaleMultiplier = 1.0 + sin(offsetInText * 0.005) * 0.05;
        break;
      case OverlayAnimationType.wave:
        translateY += sin(offsetInText * 0.005) * 6.0;
        break;
      default:
        break;
    }

    String displayText = textEntity.text;
    if (textEntity.animationType == OverlayAnimationType.typewriter) {
      final totalChars = textEntity.text.length;
      final charProgress = (offsetInText / (animDurationMs * 2)).clamp(0.0, 1.0);
      final visibleChars = (totalChars * charProgress).toInt();
      displayText = textEntity.text.substring(0, visibleChars.clamp(0, totalChars));
    }

    final isTransformingThisText = _isGestureActive &&
        widget.timelineState.selectionType == SelectionType.textOverlay &&
        widget.timelineState.selectedItemId == textEntity.id;

    final effectivePosX = isTransformingThisText ? _liveTextPosX : textEntity.posX;
    final effectivePosY = isTransformingThisText ? _liveTextPosY : textEntity.posY;
    final effectiveScale = isTransformingThisText ? _liveTextScale : textEntity.scale;
    final effectiveRotation = isTransformingThisText ? _liveTextRotation : textEntity.rotation;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment(
          (effectivePosX - 0.5) * 2,
          (effectivePosY - 0.5) * 2,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.controller.setSelection(SelectionType.textOverlay, textEntity.id);
          },
          onDoubleTap: () => _openTextEditor(textEntity),
          child: Transform.translate(
            offset: Offset(translateX, translateY),
            child: Transform.rotate(
              angle: effectiveRotation + rotationAngle,
              child: Transform.scale(
                scale: effectiveScale * scaleMultiplier,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Text Container Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: textEntity.backgroundColorHex != null
                              ? Color(textEntity.backgroundColorHex!)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: AppColors.secondary, width: 2)
                              : null,
                        ),
                        child: Text(
                          displayText,
                          textAlign: TextAlign.center,
                          style: FontHelper.getTextStyle(
                            textEntity.fontFamily,
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

                      // Interactive Selection Corner Badges & Quick Action Floating Bar
                      if (isSelected) ...[
                        // Top-Left: ✏️ Edit Font & Style Button
                        Positioned(
                          left: -14,
                          top: -14,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openTextEditor(textEntity),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.edit, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                        // Top-Right: ✕ Delete Button
                        Positioned(
                          right: -14,
                          top: -14,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.controller.deleteSelected(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                        // Bottom-Left: 📋 Duplicate Button
                        Positioned(
                          left: -14,
                          bottom: -14,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.controller.duplicateTextOverlay(textEntity.id),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E3240),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.copy, size: 13, color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                        // Bottom-Right: 🔄 Dedicated Drag-To-Scale & Rotate Handle
                        Positioned(
                          right: -14,
                          bottom: -14,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              // Drag outward/downward to zoom in, drag inward/upward to zoom out
                              final scaleDelta = (details.delta.dx + details.delta.dy) * 0.015;
                              final newScale = (textEntity.scale + scaleDelta).clamp(0.2, 5.0);
                              final rotDelta = (details.delta.dx - details.delta.dy) * 0.018;
                              final newRotation = textEntity.rotation + rotDelta;

                              widget.controller.updateTextTransform(
                                textId: textEntity.id,
                                posX: textEntity.posX,
                                posY: textEntity.posY,
                                scale: newScale,
                                rotation: newRotation,
                                persist: false,
                              );
                            },
                            onPanEnd: (_) => widget.controller.saveDraft(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.sync_rounded, size: 16, color: Colors.black),
                              ),
                            ),
                          ),
                        ),

                        // Top Floating Action Quick Bar (Edit | Duplicate | Delete)
                        Positioned(
                          top: -42,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161822),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.secondary, width: 1),
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
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 13, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Edit', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(width: 1, height: 12, color: Colors.white24),
                                InkWell(
                                  onTap: () => widget.controller.duplicateTextOverlay(textEntity.id),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.copy, size: 13, color: AppColors.secondary),
                                        SizedBox(width: 4),
                                        Text('Copy', style: TextStyle(color: AppColors.secondary, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(width: 1, height: 12, color: Colors.white24),
                                InkWell(
                                  onTap: () => widget.controller.deleteSelected(),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 13, color: AppColors.error),
                                        SizedBox(width: 4),
                                        Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 11)),
                                      ],
                                    ),
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

  Widget _buildStickerOverlay({
    required StickerOverlayEntity sticker,
    required bool isSelected,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final isTransformingThisSticker = _isGestureActive &&
        widget.timelineState.selectionType == SelectionType.stickerOverlay &&
        widget.timelineState.selectedItemId == sticker.id;

    final effectivePosX = isTransformingThisSticker ? _liveStickerPosX : sticker.posX;
    final effectivePosY = isTransformingThisSticker ? _liveStickerPosY : sticker.posY;
    final effectiveScale = isTransformingThisSticker ? _liveStickerScale : sticker.scale;
    final effectiveRotation = isTransformingThisSticker ? _liveStickerRotation : sticker.rotation;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment(
          (effectivePosX - 0.5) * 2,
          (effectivePosY - 0.5) * 2,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.controller.setSelection(SelectionType.stickerOverlay, sticker.id);
          },
          child: Transform.rotate(
            angle: effectiveRotation,
            child: Transform.scale(
              scale: effectiveScale,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: isSelected
                        ? BoxDecoration(
                            border: Border.all(color: AppColors.stickerTrack, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.stickerTrack.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          )
                        : null,
                    child: Text(
                      sticker.assetEmojiOrPath,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),

                  if (isSelected) ...[
                    // Corner handles
                    _buildCornerHandle(Alignment.topLeft, AppColors.stickerTrack),
                    _buildCornerHandle(Alignment.topRight, AppColors.stickerTrack),
                    _buildCornerHandle(Alignment.bottomLeft, AppColors.stickerTrack),

                    // Dedicated bottom-right resize/rotate handle
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          final scaleDelta = (details.delta.dx + details.delta.dy) * 0.015;
                          final newScale = (sticker.scale + scaleDelta).clamp(0.2, 5.0);
                          final rotDelta = (details.delta.dx - details.delta.dy) * 0.018;
                          final newRotation = sticker.rotation + rotDelta;
                          widget.controller.updateStickerTransform(
                            stickerId: sticker.id,
                            scale: newScale,
                            rotation: newRotation,
                            persist: false,
                          );
                        },
                        onPanEnd: (_) => widget.controller.saveDraft(),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.stickerTrack,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.open_in_full, size: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                    // Top Floating Quick Toolbar (Rotate 90 | Duplicate | Delete)
                    Positioned(
                      top: -40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161822),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.stickerTrack, width: 1),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                widget.controller.updateStickerTransform(
                                  stickerId: sticker.id,
                                  rotation: sticker.rotation + (3.14159 / 2),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.rotate_right, size: 13, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Rotate', style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                            Container(width: 1, height: 12, color: Colors.white24),
                            InkWell(
                              onTap: () => widget.controller.duplicateStickerOverlay(sticker.id),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.copy, size: 13, color: AppColors.stickerTrack),
                                    SizedBox(width: 4),
                                    Text('Copy', style: TextStyle(color: AppColors.stickerTrack, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                            Container(width: 1, height: 12, color: Colors.white24),
                            InkWell(
                              onTap: () => widget.controller.deleteStickerOverlay(sticker.id),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 13, color: AppColors.error),
                                    SizedBox(width: 4),
                                    Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 11)),
                                  ],
                                ),
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

  void _openFullScreenPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _FullScreenEditorPreviewDialog(
          timelineState: widget.timelineState,
          controller: widget.controller,
          buildVideoFrame: (clip, pos, isSel) => _buildVideoClipFrame(clip, pos, isSel),
          applyVideoEffect: ({
            required Widget content,
            required VideoEffectType effect,
            required double intensity,
            required int offsetInClipMs,
          }) => _applyVideoEffect(
            content: content,
            effect: effect,
            intensity: intensity,
            offsetInClipMs: offsetInClipMs,
          ),
          onSyncVideo: (st) => _syncActiveVideoController(st),
        ),
      ),
    );
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

/// Camcorder vintage viewfinder HUD with REC, battery, crosshairs & timecode
class _VideoCamHudPainter extends CustomPainter {
  final bool isRecBlinking;
  final String timecode;
  final double intensity;

  _VideoCamHudPainter({
    required this.isRecBlinking,
    required this.timecode,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * intensity)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final redPaint = Paint()
      ..color = const Color(0xFFFF2222).withValues(alpha: isRecBlinking ? 0.95 * intensity : 0.15)
      ..style = PaintingStyle.fill;

    // Viewfinder corner brackets
    const bracketLen = 22.0;
    const pad = 18.0;

    // Top-Left
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + bracketLen, pad), whitePaint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad, pad + bracketLen), whitePaint);

    // Top-Right
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad - bracketLen, pad), whitePaint);
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad, pad + bracketLen), whitePaint);

    // Bottom-Left
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad + bracketLen, size.height - pad), whitePaint);
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad, size.height - pad - bracketLen), whitePaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - pad, size.height - pad), Offset(size.width - pad - bracketLen, size.height - pad), whitePaint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad), Offset(size.width - pad, size.height - pad - bracketLen), whitePaint);

    // Center Crosshair
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx - 3, cy), whitePaint);
    canvas.drawLine(Offset(cx + 3, cy), Offset(cx + 10, cy), whitePaint);
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx, cy - 3), whitePaint);
    canvas.drawLine(Offset(cx, cy + 3), Offset(cx, cy + 10), whitePaint);

    // [● REC] Indicator Top-Left
    canvas.drawCircle(const Offset(pad + 12, pad + 18), 5, redPaint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'REC',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9 * intensity),
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(pad + 22, pad + 12));

    // Battery Icon Top-Right
    final battRect = Rect.fromLTWH(size.width - pad - 36, pad + 12, 24, 12);
    canvas.drawRRect(RRect.fromRectAndRadius(battRect, const Radius.circular(2)), whitePaint);
    final knobRect = Rect.fromLTWH(size.width - pad - 12, pad + 15, 2.5, 6);
    canvas.drawRect(knobRect, Paint()..color = Colors.white.withValues(alpha: 0.85 * intensity));
    // Battery level bars
    final barPaint = Paint()
      ..color = const Color(0xFF38EF7D).withValues(alpha: 0.9 * intensity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width - pad - 34, pad + 14, 5, 8), barPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - pad - 27, pad + 14, 5, 8), barPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - pad - 20, pad + 14, 5, 8), barPaint);

    // Timecode Bottom-Left
    final tcPainter = TextPainter(
      text: TextSpan(
        text: 'SP $timecode',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95 * intensity),
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.0,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tcPainter.paint(canvas, Offset(pad + 8, size.height - pad - 24));

    // Format & Date Bottom-Right
    final dtPainter = TextPainter(
      text: TextSpan(
        text: '4:3 AUTO',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8 * intensity),
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 10,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    dtPainter.paint(canvas, Offset(size.width - pad - 60, size.height - pad - 24));
  }

  @override
  bool shouldRepaint(covariant _VideoCamHudPainter oldDelegate) =>
      oldDelegate.isRecBlinking != isRecBlinking ||
      oldDelegate.timecode != timecode ||
      oldDelegate.intensity != intensity;
}

/// Thunderstorm dark clouds with branching white/cyan electric lightning bolts
class _LightningCloudEffectPainter extends CustomPainter {
  final int offsetMs;
  final bool isStriking;
  final double intensity;

  _LightningCloudEffectPainter({
    required this.offsetMs,
    required this.isStriking,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isStriking) return;

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6 * intensity)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95 * intensity)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Generate branching lightning bolts from top cloud to center/bottom
    final startX = size.width * (0.35 + ((offsetMs ~/ 200) % 4) * 0.1);
    final path = Path()..moveTo(startX, 0);

    double curX = startX;
    double curY = 0;
    final r = Random(offsetMs ~/ 80);

    while (curY < size.height * 0.85) {
      curX += (r.nextDouble() - 0.48) * 35;
      curY += r.nextDouble() * 28 + 14;
      path.lineTo(curX, curY);

      // Branching side bolt
      if (r.nextDouble() > 0.65) {
        final bPath = Path()..moveTo(curX, curY);
        double bx = curX;
        double by = curY;
        for (int i = 0; i < 3; i++) {
          bx += (r.nextDouble() - 0.3) * 25;
          by += r.nextDouble() * 20 + 10;
          bPath.lineTo(bx, by);
        }
        canvas.drawPath(bPath, glowPaint);
        canvas.drawPath(bPath, corePaint);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _LightningCloudEffectPainter oldDelegate) =>
      oldDelegate.offsetMs != offsetMs ||
      oldDelegate.isStriking != isStriking ||
      oldDelegate.intensity != intensity;
}

/// 4-panel cross split screen with quad divider lines and center node
class _CrossSplitEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _CrossSplitEffectPainter({
    required this.offsetMs,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * intensity)
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4 * intensity)
      ..strokeWidth = 6.0;

    // Vertical partition line
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), glowPaint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), linePaint);

    // Horizontal partition line
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), glowPaint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), linePaint);

    // Center quad intersection node
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.8 * intensity));
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CrossSplitEffectPainter oldDelegate) =>
      oldDelegate.offsetMs != offsetMs || oldDelegate.intensity != intensity;
}

/// Rolling 35mm film border with vertical moving sprockets
class _RollingFilmEffectPainter extends CustomPainter {
  final int offsetMs;
  _RollingFilmEffectPainter({required this.offsetMs});

  @override
  void paint(Canvas canvas, Size size) {
    const sprocketWidth = 16.0;
    const sprocketHeight = 12.0;
    const sprocketGap = 16.0;
    final totalH = sprocketHeight + sprocketGap;
    final scrollY = (offsetMs / 40.0) % totalH;

    final borderPaint = Paint()..color = const Color(0xCC000000);
    final holePaint = Paint()..color = const Color(0x99FFFFFF);

    // Left & Right film black borders
    canvas.drawRect(Rect.fromLTWH(0, 0, sprocketWidth + 8, size.height), borderPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - sprocketWidth - 8, 0, sprocketWidth + 8, size.height), borderPaint);

    // Vertical sprocket holes
    for (double y = -totalH + scrollY; y < size.height + totalH; y += totalH) {
      // Left hole
      final leftRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, y, sprocketWidth, sprocketHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(leftRRect, holePaint);

      // Right hole
      final rightRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - sprocketWidth - 4, y, sprocketWidth, sprocketHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(rightRRect, holePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RollingFilmEffectPainter oldDelegate) => true;
}

/// Fiery golden explosion particle blast
class _ExplosionEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _ExplosionEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final cycle = (offsetMs % 1200) / 1200.0;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) * 1.2;

    // Expanding shockwave ring
    final shockRadius = maxRadius * cycle;
    final ringPaint = Paint()
      ..color = const Color(0xFFFF9900).withValues(alpha: (1.0 - cycle) * 0.7 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * (1.0 - cycle);
    canvas.drawCircle(center, shockRadius, ringPaint);

    // Blast particle rays
    const particleCount = 20;
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * (2 * pi / particleCount)) + (cycle * 0.5);
      final dist = shockRadius * (0.6 + 0.4 * sin(i * 1.5).abs());
      final px = center.dx + cos(angle) * dist;
      final py = center.dy + sin(angle) * dist;
      final pRadius = (1.0 - cycle) * (5.0 + (i % 4) * 2) * intensity;

      particlePaint.color = i % 2 == 0
          ? const Color(0xFFFFD200).withValues(alpha: (1.0 - cycle) * 0.85)
          : const Color(0xFFFF3300).withValues(alpha: (1.0 - cycle) * 0.75);

      canvas.drawCircle(Offset(px, py), pRadius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExplosionEffectPainter oldDelegate) => true;
}

/// CRT Scanlines and horizontal scanline noise
class _VhsScanlinesPainter extends CustomPainter {
  final int offsetMs;
  _VhsScanlinesPainter({required this.offsetMs});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Moving tracking horizontal noise bar
    final barY = (offsetMs / 5.0) % size.height;
    final noisePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 12.0;
    canvas.drawLine(Offset(0, barY), Offset(size.width, barY), noisePaint);
  }

  @override
  bool shouldRepaint(covariant _VhsScanlinesPainter oldDelegate) => true;
}

/// Glittering starlight sparkles
class _SparklesEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _SparklesEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final t = offsetMs / 1000.0;
    const count = 12;
    final paint = Paint()
      ..color = const Color(0xFFFFE066)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final randX = ((i * 73 + 17) % 100) / 100.0 * size.width;
      final randY = ((i * 47 + 31) % 100) / 100.0 * size.height;
      final sparklePhase = sin(t * 5.0 + i * 1.3).abs();
      final radius = sparklePhase * 6.0 * intensity;

      if (radius > 0.5) {
        paint.color = Color.lerp(const Color(0xFFFFD700), Colors.white, sparklePhase)!
            .withValues(alpha: sparklePhase * 0.85);

        // 4-point star
        final path = Path();
        path.moveTo(randX, randY - radius * 2);
        path.lineTo(randX + radius * 0.5, randY - radius * 0.5);
        path.lineTo(randX + radius * 2, randY);
        path.lineTo(randX + radius * 0.5, randY + radius * 0.5);
        path.lineTo(randX, randY + radius * 2);
        path.lineTo(randX - radius * 0.5, randY + radius * 0.5);
        path.lineTo(randX - radius * 2, randY);
        path.lineTo(randX - radius * 0.5, randY - radius * 0.5);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesEffectPainter oldDelegate) => true;
}

/// Floating romantic heart particles
class _HeartsEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _HeartsEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 8;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final speed = 0.0008 + (i % 3) * 0.0003;
      final yProgress = (1.0 - ((offsetMs * speed + (i / count.toDouble())) % 1.0));
      final py = yProgress * size.height;
      final px = (0.2 + 0.6 * ((i * 37) % 100 / 100.0) + sin(offsetMs / 300.0 + i) * 0.06) * size.width;
      final scale = (0.8 + 0.4 * sin(i.toDouble())) * intensity;
      final alpha = (yProgress < 0.2 ? yProgress / 0.2 : (yProgress > 0.8 ? (1.0 - yProgress) / 0.2 : 1.0)) * 0.85;

      paint.color = const Color(0xFFFF416C).withValues(alpha: alpha.clamp(0.0, 1.0));

      final path = Path();
      final w = 14.0 * scale;
      final h = 14.0 * scale;
      path.moveTo(px, py + h * 0.3);
      path.cubicTo(px, py, px - w * 0.5, py, px - w * 0.5, py + h * 0.3);
      path.cubicTo(px - w * 0.5, py + h * 0.6, px, py + h * 0.85, px, py + h);
      path.cubicTo(px, py + h * 0.85, px + w * 0.5, py + h * 0.6, px + w * 0.5, py + h * 0.3);
      path.cubicTo(px + w * 0.5, py, px, py, px, py + h * 0.3);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartsEffectPainter oldDelegate) => true;
}

/// Vintage 8mm cinematic film dust, scratches and grain
class _FilmGrainEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _FilmGrainEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = (offsetMs ~/ 50);
    final paint = Paint()..style = PaintingStyle.fill;

    // Vertical film scratches
    if (rand % 3 == 0) {
      final scratchX = ((rand * 97) % 100) / 100.0 * size.width;
      final scratchPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15 * intensity)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(scratchX, 0), Offset(scratchX, size.height), scratchPaint);
    }

    // Dust particles
    for (int i = 0; i < 25; i++) {
      final px = (((rand + i) * 61) % 100) / 100.0 * size.width;
      final py = (((rand + i * 3) * 79) % 100) / 100.0 * size.height;
      final r = (1.0 + (i % 3) * 0.8) * intensity;
      paint.color = (i % 2 == 0 ? Colors.white : Colors.black).withValues(alpha: 0.12 * intensity);
      canvas.drawCircle(Offset(px, py), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainEffectPainter oldDelegate) => true;
}

/// Warm golden anamorphic lens flare light leak
class _LightLeakEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _LightLeakEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final phase = (offsetMs / 2000.0) * 2 * pi;
    final cx = size.width * (0.3 + 0.4 * sin(phase).abs());
    final cy = size.height * (0.2 + 0.3 * cos(phase).abs());

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment((cx / size.width) * 2 - 1, (cy / size.height) * 2 - 1),
      radius: 0.85,
      colors: [
        const Color(0xFFFF9900).withValues(alpha: 0.45 * intensity),
        const Color(0xFFFF0055).withValues(alpha: 0.25 * intensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _LightLeakEffectPainter oldDelegate) => true;
}

/// Futuristic neon laser beams
class _LaserBeamsEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _LaserBeamsEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final t = offsetMs / 400.0;
    final count = 4;
    for (int i = 0; i < count; i++) {
      final progress = (t + (i / count.toDouble())) % 1.0;
      final startY = size.height * progress;
      final laserPaint = Paint()
        ..color = (i % 2 == 0 ? const Color(0xFF00FFFF) : const Color(0xFFFF007F))
            .withValues(alpha: (0.75 * sin(progress * pi) * intensity).clamp(0.0, 1.0))
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

      canvas.drawLine(
        Offset(0, startY),
        Offset(size.width, (startY + size.height * 0.2) % size.height),
        laserPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LaserBeamsEffectPainter oldDelegate) => true;
}

/// 8-bit retro arcade pixelation grid
class _PixelateEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _PixelateEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    const blockSize = 14.0;
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += blockSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += blockSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelateEffectPainter oldDelegate) => true;
}

/// 4-point starburst cross-glint flares
class _StarGlowEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _StarGlowEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final t = offsetMs / 600.0;
    final spots = [
      Offset(size.width * 0.25, size.height * 0.3),
      Offset(size.width * 0.75, size.height * 0.4),
      Offset(size.width * 0.5, size.height * 0.7),
    ];

    for (int i = 0; i < spots.length; i++) {
      final pulse = (sin(t + i * 2.0).abs()) * intensity;
      final center = spots[i];
      final r = 18.0 * pulse;

      final paint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.7 * pulse)
        ..strokeWidth = 2.0;

      canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), paint);
      canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarGlowEffectPainter oldDelegate) => true;
}

/// Digital green Matrix code stream falling rain
class _MatrixRainEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _MatrixRainEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final t = offsetMs / 30.0;
    const colCount = 20;
    final colWidth = size.width / colCount;
    final textPainter = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < colCount; i++) {
      final speed = 1.0 + (i % 5) * 0.4;
      final headY = ((t * speed + i * 40) % (size.height + 150)) - 150;
      final x = i * colWidth + colWidth / 2;

      for (int j = 0; j < 8; j++) {
        final charY = headY - (j * 16.0);
        if (charY > 0 && charY < size.height) {
          final alpha = ((1.0 - (j / 8.0)) * intensity).clamp(0.0, 1.0);
          textPainter.color = j == 0
              ? Colors.white.withValues(alpha: alpha)
              : const Color(0xFF00FF66).withValues(alpha: alpha * 0.85);
          canvas.drawRect(Rect.fromLTWH(x - 3, charY, 6, 10), textPainter);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainEffectPainter oldDelegate) => true;
}

/// Retro 80s 3D perspective cyber grid
class _CyberGridEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _CyberGridEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.55;
    final scrollOffset = (offsetMs / 20.0) % 30.0;

    final gridPaint = Paint()
      ..color = const Color(0xFFFF007F).withValues(alpha: 0.55 * intensity)
      ..strokeWidth = 1.5;

    // Horizontal perspective lines
    for (double i = 0; i < 10; i++) {
      final progress = pow((i + scrollOffset / 30.0) / 10.0, 2);
      final y = horizonY + progress * (size.height - horizonY);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Converging vertical perspective lines
    const vLines = 12;
    for (int i = 0; i <= vLines; i++) {
      final xBottom = (i / vLines.toDouble()) * size.width;
      canvas.drawLine(Offset(size.width / 2, horizonY), Offset(xBottom, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberGridEffectPainter oldDelegate) => true;
}

/// Rising hot campfire embers and sparks
class _FireEmbersEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _FireEmbersEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 30;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final speed = 0.0006 + (i % 5) * 0.0002;
      final progress = (1.0 - ((offsetMs * speed + (i / count.toDouble())) % 1.0));
      final py = progress * size.height;
      final sway = sin(offsetMs / 180.0 + i) * 14.0;
      final px = (((i * 43) % 100) / 100.0 * size.width) + sway;
      final r = (1.5 + (i % 3) * 1.2) * intensity;
      final alpha = (progress < 0.2 ? progress / 0.2 : 1.0) * 0.85 * intensity;

      paint.color = (i % 2 == 0 ? const Color(0xFFFF4E50) : const Color(0xFFF9D423))
          .withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireEmbersEffectPainter oldDelegate) => true;
}

/// Winter falling snowflakes
class _SnowFallEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _SnowFallEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 35;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final speed = 0.0003 + (i % 4) * 0.00015;
      final progress = (offsetMs * speed + (i / count.toDouble())) % 1.0;
      final py = progress * size.height;
      final sway = sin(offsetMs / 300.0 + i * 2) * 12.0;
      final px = (((i * 67) % 100) / 100.0 * size.width) + sway;
      final r = (1.5 + (i % 3) * 1.5) * intensity;
      final alpha = (0.4 + 0.4 * sin(i.toDouble())) * intensity;

      paint.color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.9));
      canvas.drawCircle(Offset(px, py), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowFallEffectPainter oldDelegate) => true;
}

/// Cinematic slanted rain storm
class _RainStormEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _RainStormEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 45;
    final paint = Paint()
      ..color = const Color(0xFFB0C4DE).withValues(alpha: 0.45 * intensity)
      ..strokeWidth = 1.2;

    for (int i = 0; i < count; i++) {
      final speed = 0.002 + (i % 3) * 0.0005;
      final progress = (offsetMs * speed + (i / count.toDouble())) % 1.0;
      final px = ((i * 31) % 100) / 100.0 * size.width;
      final py = progress * size.height;
      const len = 24.0;
      canvas.drawLine(Offset(px, py), Offset(px - 6, py + len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainStormEffectPainter oldDelegate) => true;
}

/// High-voltage electric thunderstorm flash strike
class _LightningBoltEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _LightningBoltEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final cycle = (offsetMs ~/ 180) % 6;
    if (cycle != 0) return;

    final path = Path();
    var curX = size.width * 0.55;
    var curY = 0.0;
    path.moveTo(curX, curY);

    while (curY < size.height) {
      curY += 25.0;
      curX += (sin(curY * 4.0) * 22.0);
      path.lineTo(curX, curY);
    }

    final boltPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.9 * intensity)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    canvas.drawPath(path, boltPaint);
  }

  @override
  bool shouldRepaint(covariant _LightningBoltEffectPainter oldDelegate) => true;
}

/// Floating luxury golden bokeh dust particles
class _GoldenDustEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _GoldenDustEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 18;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final phase = offsetMs / 1000.0 + i;
      final px = (((i * 53) % 100) / 100.0 * size.width) + sin(phase * 0.7) * 20;
      final py = (((i * 83) % 100) / 100.0 * size.height) - cos(phase * 0.5) * 25;
      final r = (4.0 + (i % 4) * 3.0) * intensity;
      final alpha = (sin(phase * 1.5).abs() * 0.6 * intensity).clamp(0.0, 1.0);

      paint.color = const Color(0xFFFFD700).withValues(alpha: alpha);
      canvas.drawCircle(Offset(px % size.width, py % size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenDustEffectPainter oldDelegate) => true;
}

/// Volumetric drifting stage smoke clouds
class _SmokeAtmosphereEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _SmokeAtmosphereEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final t = offsetMs / 2500.0;
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35.0);

    for (int i = 0; i < 4; i++) {
      final cx = (size.width * (0.2 + i * 0.25)) + sin(t + i) * 35;
      final cy = (size.height * 0.7) + cos(t * 0.8 + i) * 25;
      paint.color = Colors.white.withValues(alpha: (0.16 * intensity).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(cx, cy), size.width * 0.28, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmokeAtmosphereEffectPainter oldDelegate) => true;
}

/// Iridescent floating soap bubbles
class _BubbleFloatEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _BubbleFloatEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 12;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final fillPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final speed = 0.0005 + (i % 3) * 0.0002;
      final progress = (1.0 - ((offsetMs * speed + (i / count.toDouble())) % 1.0));
      final py = progress * size.height;
      final px = (((i * 41) % 100) / 100.0 * size.width) + sin(offsetMs / 250.0 + i) * 15;
      final r = (8.0 + (i % 4) * 4.0) * intensity;
      final alpha = (progress < 0.15 ? progress / 0.15 : 1.0) * 0.7 * intensity;

      borderPaint.color = const Color(0xFF89F7FE).withValues(alpha: alpha);
      fillPaint.color = const Color(0xFF66A6FF).withValues(alpha: alpha * 0.2);

      canvas.drawCircle(Offset(px, py), r, fillPaint);
      canvas.drawCircle(Offset(px, py), r, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleFloatEffectPainter oldDelegate) => true;
}

/// Vibrant celebratory night sky fireworks
class _FireworksEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _FireworksEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final cycle = (offsetMs % 1400) / 1400.0;
    final centers = [
      Offset(size.width * 0.35, size.height * 0.35),
      Offset(size.width * 0.7, size.height * 0.28),
    ];
    final colors = [const Color(0xFFFF0844), const Color(0xFF00F2FE)];

    for (int c = 0; c < centers.length; c++) {
      final center = centers[c];
      const rays = 14;
      final burstRadius = (size.width * 0.28) * cycle;
      final paint = Paint()
        ..color = colors[c].withValues(alpha: ((1.0 - cycle) * 0.85 * intensity).clamp(0.0, 1.0))
        ..strokeWidth = 2.0;

      for (int i = 0; i < rays; i++) {
        final angle = i * (2 * pi / rays);
        final x = center.dx + cos(angle) * burstRadius;
        final y = center.dy + sin(angle) * burstRadius;
        canvas.drawCircle(Offset(x, y), 2.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksEffectPainter oldDelegate) => true;
}

/// Anime manga action speed lines
class _SpeedLinesEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _SpeedLinesEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.6;
    final minR = size.width * 0.25;
    final t = offsetMs ~/ 50;

    const count = 32;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 * intensity)
      ..strokeWidth = 2.0;

    for (int i = 0; i < count; i++) {
      if ((i + t) % 3 == 0) continue;
      final angle = i * (2 * pi / count);
      final x1 = center.dx + cos(angle) * minR;
      final y1 = center.dy + sin(angle) * minR;
      final x2 = center.dx + cos(angle) * maxR;
      final y2 = center.dy + sin(angle) * maxR;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedLinesEffectPainter oldDelegate) => true;
}

/// Pulsing neon energy aura rings
class _GlowRingsEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _GlowRingsEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cycle = (offsetMs % 1000) / 1000.0;
    final r = (size.width * 0.45) * cycle;

    final ringPaint = Paint()
      ..color = const Color(0xFF00F5D4).withValues(alpha: (1.0 - cycle) * 0.7 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * (1.0 - cycle)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    canvas.drawCircle(center, r, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowRingsEffectPainter oldDelegate) => true;
}

/// Analog black & white television snow static noise
class _OldTvStaticEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _OldTvStaticEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = offsetMs ~/ 30;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 70; i++) {
      final px = (((rand + i * 17) * 73) % 100) / 100.0 * size.width;
      final py = (((rand + i * 31) * 97) % 100) / 100.0 * size.height;
      paint.color = (i % 2 == 0 ? Colors.white : Colors.black)
          .withValues(alpha: 0.18 * intensity);
      canvas.drawRect(Rect.fromLTWH(px, py, 4, 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OldTvStaticEffectPainter oldDelegate) => true;
}

/// Magical fluttering neon butterflies
class _ButterflyEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _ButterflyEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 6;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final t = offsetMs / 600.0 + i * 1.5;
      final flap = sin(offsetMs / 40.0 + i).abs();
      final px = (size.width * 0.5) + sin(t * 0.8) * (size.width * 0.35);
      final py = (size.height * 0.5) + cos(t * 0.6) * (size.height * 0.35);

      paint.color = const Color(0xFFFF758C).withValues(alpha: 0.75 * intensity);

      final w = 10.0 * flap * intensity;
      const h = 8.0;
      canvas.drawOval(Rect.fromCenter(center: Offset(px - w * 0.6, py), width: w, height: h), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(px + w * 0.6, py), width: w, height: h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ButterflyEffectPainter oldDelegate) => true;
}

/// Festive falling multicolored confetti
class _ConfettiEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _ConfettiEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 40;
    final colors = [
      const Color(0xFFFF007F),
      const Color(0xFFFFD700),
      const Color(0xFF00F2FE),
      const Color(0xFF7B2CBF),
      const Color(0xFF00FF66),
    ];
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final speed = 0.0008 + (i % 4) * 0.0003;
      final progress = (offsetMs * speed + (i / count.toDouble())) % 1.0;
      final py = progress * size.height;
      final px = (((i * 47) % 100) / 100.0 * size.width) + sin(offsetMs / 200.0 + i) * 15;
      final rot = (offsetMs / 100.0 + i * 2);

      paint.color = colors[i % colors.length].withValues(alpha: 0.85 * intensity);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      canvas.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiEffectPainter oldDelegate) => true;
}

/// Vintage 35mm golden film burn edge flare
class _FilmBurnEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _FilmBurnEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final t = (offsetMs / 800.0) % 1.0;
    final burnAlpha = (sin(t * pi) * 0.65 * intensity).clamp(0.0, 1.0);
    if (burnAlpha < 0.02) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFFFF9900).withValues(alpha: burnAlpha),
        const Color(0xFFFF3300).withValues(alpha: burnAlpha * 0.6),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.7],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _FilmBurnEffectPainter oldDelegate) => true;
}

/// Refractive clear liquid water drop ripples
class _WaterRipplesEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _WaterRipplesEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.55);
    final cycle = (offsetMs % 1500) / 1500.0;
    final r = (size.width * 0.5) * cycle;

    final ringPaint = Paint()
      ..color = const Color(0xFF80D8FF).withValues(alpha: (1.0 - cycle) * 0.65 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - cycle);

    canvas.drawOval(Rect.fromCenter(center: center, width: r * 2, height: r * 0.9), ringPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterRipplesEffectPainter oldDelegate) => true;
}

/// Freezing winter ice crystal frosty borders
class _IceFrostEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _IceFrostEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final frostGradient = RadialGradient(
      radius: 0.95,
      colors: [
        Colors.transparent,
        const Color(0xFFE0EAFC).withValues(alpha: 0.45 * intensity),
        const Color(0xFF80D8FF).withValues(alpha: 0.75 * intensity),
      ],
      stops: const [0.65, 0.88, 1.0],
    );

    final paint = Paint()
      ..shader = frostGradient.createShader(rect)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _IceFrostEffectPainter oldDelegate) => true;
}

/// Futuristic biometric HUD laser target scanner
class _CyberScanEffectPainter extends CustomPainter {
  final int offsetMs;
  final double intensity;

  _CyberScanEffectPainter({required this.offsetMs, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final scanY = (offsetMs / 3.0) % size.height;
    final scanPaint = Paint()
      ..color = const Color(0xFF00F5D4).withValues(alpha: 0.85 * intensity)
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _CyberScanEffectPainter oldDelegate) => true;
}

/// Immersive, Edge-to-Edge Full Screen Video Editor Preview Modal
class _FullScreenEditorPreviewDialog extends StatefulWidget {
  final TimelineState timelineState;
  final EditorController controller;
  final Widget Function(VideoClipEntity clip, int currentPosMs, bool isSelected) buildVideoFrame;
  final Widget Function({
    required Widget content,
    required VideoEffectType effect,
    required double intensity,
    required int offsetInClipMs,
  }) applyVideoEffect;
  final void Function(TimelineState state) onSyncVideo;

  const _FullScreenEditorPreviewDialog({
    required this.timelineState,
    required this.controller,
    required this.buildVideoFrame,
    required this.applyVideoEffect,
    required this.onSyncVideo,
  });

  @override
  State<_FullScreenEditorPreviewDialog> createState() => _FullScreenEditorPreviewDialogState();
}

class _FullScreenEditorPreviewDialogState extends State<_FullScreenEditorPreviewDialog> {
  bool _showControls = true;
  late TimelineState _currentState;
  void Function()? _removeListener;

  @override
  void initState() {
    super.initState();
    _currentState = widget.controller.currentState;
    _removeListener = widget.controller.addListener((newState) {
      if (mounted) {
        setState(() {
          _currentState = newState;
        });
        widget.onSyncVideo(newState);
      }
    });
    // Immediately sync all active video playback states on opening full screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSyncVideo(_currentState);
      }
    });
  }

  @override
  void dispose() {
    _removeListener?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _currentState;
    final project = state.project;
    final activeClip = state.activeVideoClip;
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Centered True Aspect-Ratio Canvas Layer
            Center(
              child: AspectRatio(
                aspectRatio: project.aspectRatio.ratio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasWidth = constraints.maxWidth;

                    return Container(
                      color: Colors.black,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Base track: Main video/photo clip
                          if (activeClip != null)
                            widget.buildVideoFrame(activeClip, currentPosMs, false)
                          else
                            Container(
                              color: const Color(0xFF16181F),
                              child: const Center(
                                child: Text('No Clip at Playhead', style: TextStyle(color: Colors.white54)),
                              ),
                            ),

                          // Picture-in-Picture (PIP) Overlays Track Layer (Green Screen, Videos, Photos)
                          ...state.activeOverlayClips.map((overlayClip) {
                            return widget.buildVideoFrame(overlayClip, currentPosMs, false);
                          }),

                          // Active Timeline Effect Clips Layer
                          ...project.effectClips
                              .where((e) => currentPosMs >= e.timelineStartMs && currentPosMs <= e.timelineEndMs)
                              .map((effClip) {
                            final offsetInEffect = currentPosMs - effClip.timelineStartMs;
                            return Positioned.fill(
                              child: IgnorePointer(
                                child: widget.applyVideoEffect(
                                  content: const SizedBox.expand(),
                                  effect: effClip.effectType,
                                  intensity: effClip.intensity,
                                  offsetInClipMs: offsetInEffect,
                                ),
                              ),
                            );
                          }),

                          // Subtitles Layer
                          ...project.subtitles
                              .where((s) => currentPosMs >= s.timelineStartMs && currentPosMs <= s.timelineEndMs)
                              .map((sub) {
                            return Positioned(
                              left: 20,
                              right: 20,
                              bottom: 30,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sub.text,
                                    textAlign: TextAlign.center,
                                    style: FontHelper.getTextStyle(
                                      sub.fontFamily,
                                      color: Color(sub.colorHex),
                                      fontSize: sub.fontSize * (canvasWidth / 360.0).clamp(0.8, 2.0),
                                      fontWeight: FontWeight.w600,
                                      shadows: const [
                                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Text Overlays
                          ...activeTexts.map((textEntity) {
                            final offsetInText = currentPosMs - textEntity.timelineStartMs;
                            double opacity = 1.0;
                            double translateY = 0.0;
                            double translateX = 0.0;
                            double scaleMultiplier = 1.0;
                            double rotationAngle = 0.0;
                            const animDurationMs = 500;

                            if (offsetInText < animDurationMs) {
                              final progress = (offsetInText / animDurationMs).clamp(0.0, 1.0);
                              switch (textEntity.animationType) {
                                case OverlayAnimationType.fadeIn:
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.slideUp:
                                  translateY = (1.0 - progress) * 40.0;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.slideDown:
                                  translateY = -(1.0 - progress) * 40.0;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.slideLeft:
                                  translateX = (1.0 - progress) * 60.0;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.slideRight:
                                  translateX = -(1.0 - progress) * 60.0;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.zoomIn:
                                  scaleMultiplier = (progress * 1.15).clamp(0.0, 1.15);
                                  if (progress > 0.8) scaleMultiplier = 1.0 + (1.0 - progress) * 0.75;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.zoomOut:
                                  scaleMultiplier = 1.0 + (1.0 - progress) * 1.2;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.bounce:
                                  final bounceT = Curves.bounceOut.transform(progress);
                                  translateY = (1.0 - bounceT) * 35.0;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.spin:
                                  rotationAngle = (1.0 - progress) * pi * 2;
                                  scaleMultiplier = progress;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.flip:
                                  scaleMultiplier = progress.clamp(0.05, 1.0);
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.drop:
                                  final dropT = Curves.bounceOut.transform(progress);
                                  translateY = -(1.0 - dropT) * 60.0;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.flash:
                                  opacity = ((offsetInText ~/ 70) % 2 == 0) ? 1.0 : 0.2;
                                  break;
                                case OverlayAnimationType.swing:
                                  final swingT = sin(progress * pi * 4) * (1.0 - progress);
                                  rotationAngle = swingT * 0.25;
                                  opacity = progress;
                                  break;
                                case OverlayAnimationType.blur:
                                  opacity = progress;
                                  scaleMultiplier = 1.15 - (0.15 * progress);
                                  break;
                                case OverlayAnimationType.shake:
                                  translateX = sin(progress * pi * 8) * 8.0 * (1.0 - progress);
                                  opacity = progress;
                                  break;
                                default:
                                  break;
                              }
                            }

                            switch (textEntity.animationType) {
                              case OverlayAnimationType.pulse:
                                scaleMultiplier = 1.0 + sin(offsetInText * 0.008).abs() * 0.12;
                                break;
                              case OverlayAnimationType.glitch:
                                if ((offsetInText ~/ 140) % 3 == 0) {
                                  translateX = sin(offsetInText * 0.05) * 6.0;
                                  opacity = 0.85;
                                }
                                break;
                              case OverlayAnimationType.glow:
                                scaleMultiplier = 1.0 + sin(offsetInText * 0.005) * 0.05;
                                break;
                              case OverlayAnimationType.wave:
                                translateY += sin(offsetInText * 0.005) * 6.0;
                                break;
                              default:
                                break;
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
                                child: Transform.translate(
                                  offset: Offset(translateX, translateY),
                                  child: Transform.rotate(
                                    angle: textEntity.rotation + rotationAngle,
                                    child: Transform.scale(
                                      scale: textEntity.scale * scaleMultiplier,
                                      child: Opacity(
                                        opacity: opacity.clamp(0.0, 1.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: textEntity.backgroundColorHex != null
                                                ? Color(textEntity.backgroundColorHex!)
                                                : null,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            textEntity.text,
                                            textAlign: TextAlign.center,
                                            style: FontHelper.getTextStyle(
                                              textEntity.fontFamily,
                                              fontSize: textEntity.fontSize * (canvasWidth / 360.0).clamp(0.8, 2.0),
                                              fontWeight: FontWeight.bold,
                                              color: Color(textEntity.colorHex),
                                              shadows: const [
                                                Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(1, 2)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Sticker Overlays
                          ...activeStickers.map((sticker) {
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
                          }),

                          // Subtle ProCut Watermark in Bottom-Right Corner
                          const Positioned(
                            right: 14,
                            bottom: 14,
                            child: IgnorePointer(
                              child: ProCutWatermark(opacity: 0.7, scale: 1.0),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Animated Overlay Controls (Top minimize bar & Bottom control pill)
            if (_showControls) ...[
              // Top Bar: Project Title, Timecode & Minimize Button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Project Title & Timecode
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            project.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${TimecodeFormatter.formatTimecode(currentPosMs, fps: project.fps)} / ${TimecodeFormatter.formatTimecode(totalDurationMs, fps: project.fps)}',
                            style: const TextStyle(
                              color: Color(0xFF00C2CB),
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Minimize / Exit Full Screen Button
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30, width: 1.2),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen_exit, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Minimize',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Control Bar with Scrubber & Media Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 14, left: 20, right: 20, bottom: 36),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Interactive Precision Timeline Scrubber Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF00C2CB),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 3.5,
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: currentPosMs.toDouble().clamp(0.0, max(1.0, totalDurationMs.toDouble())),
                          min: 0.0,
                          max: max(1.0, totalDurationMs.toDouble()),
                          onChanged: (val) {
                            widget.controller.seekTo(val.toInt());
                          },
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Media Buttons Pill: [ -5s ] [ Skip Prev ] [ ▶ / ⏸ ] [ Skip Next ] [ +5s ]
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_5, color: Colors.white70, size: 26),
                            tooltip: 'Back 5s',
                            onPressed: () => widget.controller.seekTo(currentPosMs - 5000),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                            tooltip: 'Previous Frame',
                            onPressed: () => widget.controller.seekTo(currentPosMs - 33),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: widget.controller.togglePlayPause,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF00C2CB), Color(0xFF00838F)],
                                ),
                              ),
                              child: Icon(
                                state.isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          IconButton(
                            icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                            tooltip: 'Next Frame',
                            onPressed: () => widget.controller.seekTo(currentPosMs + 33),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.forward_5, color: Colors.white70, size: 26),
                            tooltip: 'Forward 5s',
                            onPressed: () => widget.controller.seekTo(currentPosMs + 5000),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
