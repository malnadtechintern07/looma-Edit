import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../audio/presentation/widgets/audio_track_item.dart';
import '../../../text_stickers/presentation/widgets/overlay_track_item.dart';
import '../../domain/entities/timeline_state.dart';
import '../providers/editor_controller.dart';
import 'subtitle_track_item.dart';
import 'timeline_ruler.dart';
import 'video_track_item.dart';

class MultiTrackTimeline extends StatefulWidget {
  final TimelineState state;
  final EditorController controller;

  const MultiTrackTimeline({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  State<MultiTrackTimeline> createState() => _MultiTrackTimelineState();
}

class _MultiTrackTimelineState extends State<MultiTrackTimeline> {
  final ScrollController _scrollController = ScrollController();
  bool _isUserScrubbing = false;
  bool _isProgrammaticScroll = false;
  double _lastPps = AppConstants.defaultPixelsPerSecond;

  // Pinch-to-zoom & Focal Point Anchoring State
  double _pinchBasePps = AppConstants.defaultPixelsPerSecond;
  double _pinchAnchorTimeSec = 0.0;
  double _dampedPps = AppConstants.defaultPixelsPerSecond;
  double _currentViewportWidth = 360.0;
  bool _isScaling = false;
  bool _isDraggingClipHandle = false;

  // Floating Zoom Indicator HUD State
  bool _showZoomIndicator = false;
  Timer? _zoomIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _lastPps = widget.state.pixelsPerSecond;
    _pinchBasePps = widget.state.pixelsPerSecond;
    _dampedPps = widget.state.pixelsPerSecond;
  }

  @override
  void didUpdateWidget(covariant MultiTrackTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scrollController.hasClients && !_isScaling && !_isDraggingClipHandle) {
      final pps = widget.state.pixelsPerSecond;
      final targetScroll = (widget.state.playheadPositionMs / 1000.0) * pps;

      if (widget.state.isPlaying) {
        _isProgrammaticScroll = true;
        _scrollController.jumpTo(targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent));
        _isProgrammaticScroll = false;
      } else if (!_isUserScrubbing) {
        final currentOffset = _scrollController.offset;
        if ((currentOffset - targetScroll).abs() > 1.5 || _lastPps != pps) {
          _isProgrammaticScroll = true;
          _scrollController.jumpTo(targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent));
          _isProgrammaticScroll = false;
        }
      }
    }
    _lastPps = widget.state.pixelsPerSecond;
  }

  @override
  void dispose() {
    _zoomIndicatorTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerZoomIndicator() {
    _zoomIndicatorTimer?.cancel();
    if (!_showZoomIndicator) {
      setState(() {
        _showZoomIndicator = true;
      });
    }
  }

  void _scheduleZoomIndicatorHide() {
    _zoomIndicatorTimer?.cancel();
    _zoomIndicatorTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showZoomIndicator = false;
        });
      }
    });
  }

  /// Exponential moving average filter for responsive, silky-smooth pinch zoom
  double _smoothPps(double rawPps) {
    const double alpha = 0.82;
    _dampedPps = _dampedPps * (1.0 - alpha) + rawPps * alpha;
    return _dampedPps;
  }

  void _onRulerTapOrDrag(double localX) {
    final pps = widget.state.pixelsPerSecond;
    final totalMs = widget.state.project.calculatedDurationMs;
    final targetMs = ((localX / pps) * 1000).round().clamp(0, totalMs);
    widget.controller.seekTo(targetMs);
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_isDraggingClipHandle) return;
    _pinchBasePps = widget.state.pixelsPerSecond;
    _dampedPps = widget.state.pixelsPerSecond;
    _isScaling = details.pointerCount >= 2;

    final focalX = details.localFocalPoint.dx;
    final halfWidth = _currentViewportWidth / 2.0;
    final currentScrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;

    // Capture exact timeline time in seconds directly under user's fingers
    _pinchAnchorTimeSec = (currentScrollOffset + focalX - halfWidth) / _pinchBasePps;

    if (_isScaling) {
      _triggerZoomIndicator();
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_isDraggingClipHandle) return;
    if (details.pointerCount >= 2 || (details.scale - 1.0).abs() > 0.01) {
      final focalX = details.localFocalPoint.dx;
      final halfWidth = _currentViewportWidth / 2.0;

      if (!_isScaling) {
        _isScaling = true;
        _pinchBasePps = widget.state.pixelsPerSecond;
        _dampedPps = widget.state.pixelsPerSecond;
        final currentScrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
        _pinchAnchorTimeSec = (currentScrollOffset + focalX - halfWidth) / _pinchBasePps;
      }

      // Multiply baseline pixelsPerSecond by the gesture's scale factor
      final rawPps = (_pinchBasePps * details.scale).clamp(
        AppConstants.minTimelinePixelsPerSecond,
        AppConstants.maxTimelinePixelsPerSecond,
      );

      // Smooth zoom with damping so it doesn't jump on fast pinches
      final targetPps = _smoothPps(rawPps);

      if ((targetPps - widget.state.pixelsPerSecond).abs() > 0.01) {
        widget.controller.setTimelineZoom(targetPps);

        // Focal-point anchoring: keep the clip under user's fingers stationary
        if (_scrollController.hasClients) {
          final desiredScrollOffset = (_pinchAnchorTimeSec * targetPps) - focalX + halfWidth;
          final maxScroll = _scrollController.position.maxScrollExtent;
          final targetOffset = desiredScrollOffset.clamp(0.0, max(0.0, maxScroll));

          _isProgrammaticScroll = true;
          _scrollController.jumpTo(targetOffset.toDouble());
          _isProgrammaticScroll = false;
        }
      }

      _triggerZoomIndicator();
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isScaling = false;
    _scheduleZoomIndicatorHide();
  }

  Widget _buildFloatingZoomIndicator(double pps) {
    final zoomPercent = ((pps / AppConstants.defaultPixelsPerSecond) * 100).round();

    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _showZoomIndicator ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xE6141620),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pinch_outlined,
                    size: 13,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$zoomPercent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${pps.toStringAsFixed(0)} px/s',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final project = state.project;
    final pps = state.pixelsPerSecond;
    final totalDurationMs = project.calculatedDurationMs;

    return Container(
      color: const Color(0xFF0D0E12),
      child: Column(
        children: [
          // Timeline Toolbar (Zoom control, Fit button & track summary)
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF161822),
              border: Border(
                top: BorderSide(color: Color(0xFF2E3240), width: 1),
                bottom: BorderSide(color: Color(0xFF2E3240), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.layers_outlined, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${project.videoClips.length} Clips • ${project.audioClips.length} Audio • ${project.textOverlays.length} Text',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Fit Timeline to Screen Button
                InkWell(
                  onTap: () {
                    final viewportWidth = _scrollController.hasClients
                        ? _scrollController.position.viewportDimension
                        : 360.0;
                    widget.controller.fitTimelineToScreen(viewportWidth);
                    _triggerZoomIndicator();
                    _scheduleZoomIndicatorHide();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.secondary, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fit_screen, size: 13, color: AppColors.secondary),
                        SizedBox(width: 4),
                        Text(
                          'Fit',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Zoom Out Button
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 16, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'Zoom Out (or pinch timeline)',
                  onPressed: () {
                    widget.controller.setTimelineZoom(pps * 0.75);
                    _triggerZoomIndicator();
                    _scheduleZoomIndicatorHide();
                  },
                ),

                // Mini Zoom Level indicator / slider
                SizedBox(
                  width: 56,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: const Color(0xFF2E3240),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: pps.clamp(
                        AppConstants.minTimelinePixelsPerSecond,
                        AppConstants.maxTimelinePixelsPerSecond,
                      ),
                      min: AppConstants.minTimelinePixelsPerSecond,
                      max: AppConstants.maxTimelinePixelsPerSecond,
                      onChanged: (v) {
                        widget.controller.setTimelineZoom(v);
                        _triggerZoomIndicator();
                        _scheduleZoomIndicatorHide();
                      },
                    ),
                  ),
                ),

                // Zoom In Button
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 16, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'Zoom In (or spread timeline)',
                  onPressed: () {
                    widget.controller.setTimelineZoom(pps * 1.35);
                    _triggerZoomIndicator();
                    _scheduleZoomIndicatorHide();
                  },
                ),
              ],
            ),
          ),

          // Multi-Track Scroll Area
          Expanded(
            child: Row(
              children: [
                // Fixed Left Track Header Icons
                Container(
                  width: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF161822),
                    border: Border(right: BorderSide(color: Color(0xFF2E3240), width: 1)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: AppConstants.timelineRulerHeight,
                        color: const Color(0xFF1B1E2B),
                        alignment: Alignment.center,
                        child: const Icon(Icons.av_timer, size: 14, color: AppColors.secondary),
                      ),
                      if (project.textOverlays.isNotEmpty)
                        Container(
                          height: 32,
                          alignment: Alignment.center,
                          child: const Icon(Icons.title, size: 14, color: AppColors.textTrack),
                        ),
                      if (project.subtitles.isNotEmpty)
                        Container(
                          height: 28,
                          alignment: Alignment.center,
                          child: const Icon(Icons.subtitles, size: 14, color: Color(0xFFFF9F43)),
                        ),
                      if (project.stickerOverlays.isNotEmpty)
                        Container(
                          height: 32,
                          alignment: Alignment.center,
                          child: const Icon(Icons.emoji_emotions, size: 14, color: AppColors.stickerTrack),
                        ),
                      Container(
                        height: AppConstants.timelineTrackHeight,
                        alignment: Alignment.center,
                        child: const Icon(Icons.movie, size: 16, color: AppColors.videoTrack),
                      ),
                      if (project.videoClips.any((c) => c.isOverlay))
                        Container(
                          height: AppConstants.timelineTrackHeight,
                          alignment: Alignment.center,
                          child: const Icon(Icons.layers, size: 14, color: AppColors.accentRose),
                        ),
                      if (project.audioClips.isNotEmpty)
                        Container(
                          height: 42,
                          alignment: Alignment.center,
                          child: const Icon(Icons.audiotrack, size: 14, color: AppColors.audioTrack),
                        ),
                    ],
                  ),
                ),

                // Center-Fixed Playhead Viewport & Scrollable Tracks with 2-Finger Pinch Zoom
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _currentViewportWidth = constraints.maxWidth;
                      final viewportWidth = constraints.maxWidth;
                      final halfWidth = viewportWidth / 2;
                      final totalTracksWidth = max(
                        200.0,
                        ((totalDurationMs / 1000.0) * pps),
                      );

                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onScaleEnd: _onScaleEnd,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Scrollable Tracks Canvas
                            NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (_isProgrammaticScroll) return false;

                                if (notification is ScrollStartNotification) {
                                  _isUserScrubbing = true;
                                  if (widget.state.isPlaying) {
                                    widget.controller.pause();
                                  }
                                } else if (notification is ScrollUpdateNotification) {
                                  if (_isUserScrubbing && _scrollController.hasClients) {
                                    final scrollOffset = _scrollController.offset;
                                    final targetMs = ((scrollOffset / pps) * 1000).round().clamp(0, totalDurationMs);
                                    if (targetMs != widget.state.playheadPositionMs) {
                                      widget.controller.seekTo(targetMs);
                                    }
                                  }
                                } else if (notification is ScrollEndNotification) {
                                  _isUserScrubbing = false;
                                }
                                return false;
                              },
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                physics: _isDraggingClipHandle
                                    ? const NeverScrollableScrollPhysics()
                                    : const ClampingScrollPhysics(),
                                padding: EdgeInsets.only(
                                  left: halfWidth,
                                  right: halfWidth,
                                ),
                                child: SizedBox(
                                  width: totalTracksWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 1. Interactive Timeline Ruler with Scrub Support
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapDown: (details) {
                                          _onRulerTapOrDrag(details.localPosition.dx);
                                        },
                                        child: TimelineRuler(
                                          totalDurationMs: totalDurationMs,
                                          pixelsPerSecond: pps,
                                          fps: project.fps,
                                        ),
                                      ),

                                      // 2. Text Overlays Track & Interactive Controls
                                      if (state.selectionType == SelectionType.textOverlay && state.selectedItemId != null) ...[
                                        Builder(builder: (ctx) {
                                          final selIdx = project.textOverlays.indexWhere((t) => t.id == state.selectedItemId);
                                          if (selIdx == -1) return const SizedBox.shrink();
                                          final selText = project.textOverlays[selIdx];

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            margin: const EdgeInsets.only(bottom: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceElevated,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.textTrack.withValues(alpha: 0.5)),
                                            ),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.title, size: 14, color: AppColors.textTrack),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Text: "${selText.text}"',
                                                    style: AppTypography.labelSmall.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  InkWell(
                                                    onTap: selIdx > 0
                                                        ? () => widget.controller.reorderTextOverlays(selIdx, selIdx - 1)
                                                        : null,
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: selIdx > 0 ? AppColors.textTrack : Colors.white10,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.arrow_back, size: 12, color: Colors.white),
                                                          SizedBox(width: 4),
                                                          Text('Layer Down', style: TextStyle(fontSize: 10, color: Colors.white)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  InkWell(
                                                    onTap: selIdx < project.textOverlays.length - 1
                                                        ? () => widget.controller.reorderTextOverlays(selIdx, selIdx + 1)
                                                        : null,
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: selIdx < project.textOverlays.length - 1 ? AppColors.textTrack : Colors.white10,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Text('Layer Up', style: TextStyle(fontSize: 10, color: Colors.white)),
                                                          SizedBox(width: 4),
                                                          Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  InkWell(
                                                    onTap: () => widget.controller.duplicateTextOverlay(selText.id),
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.secondary.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: AppColors.secondary, width: 1),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.copy, size: 12, color: AppColors.secondary),
                                                          SizedBox(width: 4),
                                                          Text('Duplicate', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    '↔ Drag handles (◀/▶) to extend duration • Drag text to slide',
                                                    style: TextStyle(fontSize: 10, color: AppColors.accent),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ],

                                      if (project.textOverlays.isNotEmpty)
                                        Container(
                                          height: 34,
                                          margin: const EdgeInsets.symmetric(vertical: 2),
                                          child: Stack(
                                            children: project.textOverlays.map((textItem) {
                                              final left = (textItem.timelineStartMs / 1000.0) * pps;
                                              final isSelected =
                                                  state.selectionType == SelectionType.textOverlay &&
                                                      state.selectedItemId == textItem.id;
                                              return Positioned(
                                                left: left,
                                                child: TextOverlayTrackItem(
                                                  item: textItem,
                                                  pixelsPerSecond: pps,
                                                  isSelected: isSelected,
                                                  onTap: () => widget.controller.setSelection(
                                                    SelectionType.textOverlay,
                                                    textItem.id,
                                                  ),
                                                  onHandleDragUpdate: (deltaPixels, isLeftHandle) {
                                                    widget.controller.updateTextDurationByDrag(
                                                      textId: textItem.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                      isLeftHandle: isLeftHandle,
                                                    );
                                                  },
                                                  onBodyDragUpdate: (deltaPixels) {
                                                    widget.controller.moveTextTimelinePosition(
                                                      textId: textItem.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),

                                      // 3. Subtitles Track
                                      if (project.subtitles.isNotEmpty)
                                        Container(
                                          height: 28,
                                          margin: const EdgeInsets.symmetric(vertical: 2),
                                          child: Stack(
                                            children: project.subtitles.map((sub) {
                                              final left = (sub.timelineStartMs / 1000.0) * pps;
                                              final isSelected = state.selectionType == SelectionType.subtitle &&
                                                  state.selectedItemId == sub.id;
                                              return Positioned(
                                                left: left,
                                                child: SubtitleTrackItem(
                                                  item: sub,
                                                  pixelsPerSecond: pps,
                                                  isSelected: isSelected,
                                                  onTap: () => widget.controller.setSelection(
                                                    SelectionType.subtitle,
                                                    sub.id,
                                                  ),
                                                  onHandleDragUpdate: (deltaPixels, isLeftHandle) {
                                                    widget.controller.updateSubtitleDurationByDrag(
                                                      subtitleId: sub.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                      isLeftHandle: isLeftHandle,
                                                    );
                                                  },
                                                  onBodyDragUpdate: (deltaPixels) {
                                                    widget.controller.moveSubtitleTimelinePosition(
                                                      subtitleId: sub.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),

                                      // 4. Sticker Overlays Track
                                      if (project.stickerOverlays.isNotEmpty)
                                        Container(
                                          height: 32,
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Stack(
                                            children: project.stickerOverlays.map((sticker) {
                                              final left = (sticker.timelineStartMs / 1000.0) * pps;
                                              final isSelected =
                                                  state.selectionType == SelectionType.stickerOverlay &&
                                                      state.selectedItemId == sticker.id;
                                              return Positioned(
                                                left: left,
                                                child: StickerOverlayTrackItem(
                                                  item: sticker,
                                                  pixelsPerSecond: pps,
                                                  isSelected: isSelected,
                                                  onTap: () => widget.controller.setSelection(
                                                    SelectionType.stickerOverlay,
                                                    sticker.id,
                                                  ),
                                                  onHandleDragUpdate: (deltaPixels, isLeftHandle) {
                                                    widget.controller.updateStickerDurationByDrag(
                                                      stickerId: sticker.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                      isLeftHandle: isLeftHandle,
                                                    );
                                                  },
                                                  onBodyDragUpdate: (deltaPixels) {
                                                    widget.controller.moveStickerTimelinePosition(
                                                      stickerId: sticker.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),

                                      // 5. Main Video Clips Track (Interactive Drag & Drop Reordering & Duration Extension)
                                      if (state.selectionType == SelectionType.videoClip && state.selectedItemId != null) ...[
                                        Builder(builder: (ctx) {
                                          final selIdx = project.videoClips.indexWhere((c) => c.id == state.selectedItemId);
                                          if (selIdx == -1) return const SizedBox.shrink();
                                          final selClip = project.videoClips[selIdx];

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceElevated,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                                            ),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Clip: ${selClip.name}',
                                                    style: AppTypography.labelSmall.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Split at Playhead button
                                                  InkWell(
                                                    onTap: () => widget.controller.splitActiveClip(),
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withValues(alpha: 0.3),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: AppColors.primary, width: 1),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.splitscreen, size: 12, color: AppColors.primaryLight),
                                                          SizedBox(width: 4),
                                                          Text('Split', style: TextStyle(fontSize: 10, color: Colors.white)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  // Move Left button
                                                  InkWell(
                                                    onTap: selIdx > 0
                                                        ? () => widget.controller.reorderVideoClips(selIdx, selIdx - 1)
                                                        : null,
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: selIdx > 0 ? AppColors.primary : Colors.white10,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.arrow_back, size: 12, color: Colors.white),
                                                          SizedBox(width: 4),
                                                          Text('Move Left', style: TextStyle(fontSize: 10, color: Colors.white)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  // Move Right button
                                                  InkWell(
                                                    onTap: selIdx < project.videoClips.length - 1
                                                        ? () => widget.controller.reorderVideoClips(selIdx, selIdx + 1)
                                                        : null,
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: selIdx < project.videoClips.length - 1 ? AppColors.primary : Colors.white10,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Text('Move Right', style: TextStyle(fontSize: 10, color: Colors.white)),
                                                          SizedBox(width: 4),
                                                          Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  // Duplicate button
                                                  InkWell(
                                                    onTap: () => widget.controller.duplicateVideoClip(selClip.id),
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.secondary.withValues(alpha: 0.25),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: AppColors.secondary, width: 1),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.copy, size: 12, color: AppColors.secondary),
                                                          SizedBox(width: 4),
                                                          Text('Duplicate', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  // Delete button
                                                  InkWell(
                                                    onTap: () => widget.controller.deleteSelected(),
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.error.withValues(alpha: 0.25),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: AppColors.error, width: 1),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.delete_outline, size: 12, color: AppColors.error),
                                                          SizedBox(width: 4),
                                                          Text('Delete', style: TextStyle(fontSize: 10, color: AppColors.error)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Quick -1s duration button
                                                  InkWell(
                                                    onTap: () => widget.controller.updateClipDurationByDrag(
                                                      clipId: selClip.id,
                                                      deltaPixels: -pps,
                                                      pixelsPerSecond: pps,
                                                      isLeftHandle: false,
                                                    ),
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.accentRose.withValues(alpha: 0.25),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: AppColors.accentRose, width: 1),
                                                      ),
                                                      child: const Text('-1s', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  // Quick +1s duration button
                                                  InkWell(
                                                    onTap: () => widget.controller.updateClipDurationByDrag(
                                                      clipId: selClip.id,
                                                      deltaPixels: pps,
                                                      pixelsPerSecond: pps,
                                                      isLeftHandle: false,
                                                    ),
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.success.withValues(alpha: 0.25),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: AppColors.success, width: 1),
                                                      ),
                                                      child: const Text('+1s', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    '↔ Drag handles (◀/▶) to trim • Drag clip body to reorder',
                                                    style: TextStyle(fontSize: 10, color: AppColors.accent),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                        const SizedBox(height: 4),
                                      ],

                                      Container(
                                        height: AppConstants.timelineTrackHeight,
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: List.generate(project.videoClips.where((c) => !c.isOverlay).length, (index) {
                                            final mainClips = project.videoClips.where((c) => !c.isOverlay).toList();
                                            final clip = mainClips[index];
                                            final left = (clip.timelineStartMs / 1000.0) * pps;
                                            final isSelected =
                                                state.selectionType == SelectionType.videoClip &&
                                                    state.selectedItemId == clip.id;

                                            final trackItem = VideoTrackItem(
                                              clip: clip,
                                              pixelsPerSecond: pps,
                                              isSelected: isSelected,
                                              onTap: () => widget.controller.setSelection(
                                                SelectionType.videoClip,
                                                clip.id,
                                              ),
                                              onHandleDragStart: () {
                                                setState(() {
                                                  _isDraggingClipHandle = true;
                                                });
                                              },
                                              onHandleDragUpdate: (deltaPixels, isLeftHandle) {
                                                widget.controller.updateClipDurationByDrag(
                                                  clipId: clip.id,
                                                  deltaPixels: deltaPixels,
                                                  pixelsPerSecond: pps,
                                                  isLeftHandle: isLeftHandle,
                                                );
                                              },
                                              onHandleDragEnd: () {
                                                setState(() {
                                                  _isDraggingClipHandle = false;
                                                });
                                                widget.controller.finishClipDurationDrag();
                                              },
                                              onBodyDragUpdate: (deltaPixels) {
                                                widget.controller.moveVideoClipPosition(
                                                  clipId: clip.id,
                                                  deltaPixels: deltaPixels,
                                                  pixelsPerSecond: pps,
                                                );
                                              },
                                            );

                                            if (isSelected) {
                                              return Positioned(
                                                left: left,
                                                child: trackItem,
                                              );
                                            }

                                            return Positioned(
                                              left: left,
                                              child: DragTarget<int>(
                                                onWillAcceptWithDetails: (details) => details.data != index,
                                                onAcceptWithDetails: (details) {
                                                  widget.controller.reorderVideoClips(details.data, index);
                                                },
                                                builder: (context, candidateData, rejectedData) {
                                                  final isTargeting = candidateData.isNotEmpty;
                                                  return Stack(
                                                    children: [
                                                      Draggable<int>(
                                                        data: index,
                                                        axis: Axis.horizontal,
                                                        feedback: Material(
                                                          color: Colors.transparent,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.primary.withValues(alpha: 0.95),
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: Colors.white, width: 1.5),
                                                              boxShadow: const [
                                                                BoxShadow(
                                                                  color: Colors.black54,
                                                                  blurRadius: 12,
                                                                  spreadRadius: 2,
                                                                ),
                                                              ],
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                const Icon(Icons.drag_indicator, color: Colors.white, size: 16),
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                  clip.name,
                                                                  style: AppTypography.labelSmall.copyWith(
                                                                    color: Colors.white,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        childWhenDragging: Opacity(
                                                          opacity: 0.3,
                                                          child: trackItem,
                                                        ),
                                                        child: trackItem,
                                                      ),
                                                      if (isTargeting)
                                                        Positioned.fill(
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: AppColors.primary.withValues(alpha: 0.3),
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: AppColors.secondary, width: 2),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            );
                                          }),
                                        ),
                                      ),

                                      // 6. PIP Overlay Track
                                      if (project.videoClips.any((c) => c.isOverlay))
                                        Container(
                                          height: AppConstants.timelineTrackHeight,
                                          margin: const EdgeInsets.symmetric(vertical: 2),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: project.videoClips.where((c) => c.isOverlay).map((overlayClip) {
                                              final left = (overlayClip.timelineStartMs / 1000.0) * pps;
                                              final isSelected = state.selectionType == SelectionType.overlayClip &&
                                                  state.selectedItemId == overlayClip.id;
                                              return Positioned(
                                                left: left,
                                                child: VideoTrackItem(
                                                  clip: overlayClip,
                                                  pixelsPerSecond: pps,
                                                  isSelected: isSelected,
                                                  onTap: () => widget.controller.setSelection(
                                                    SelectionType.overlayClip,
                                                    overlayClip.id,
                                                  ),
                                                  onHandleDragStart: () {
                                                    setState(() {
                                                      _isDraggingClipHandle = true;
                                                    });
                                                  },
                                                  onHandleDragUpdate: (deltaPixels, isLeftHandle) {
                                                    widget.controller.updateClipDurationByDrag(
                                                      clipId: overlayClip.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                      isLeftHandle: isLeftHandle,
                                                    );
                                                  },
                                                  onHandleDragEnd: () {
                                                    setState(() {
                                                      _isDraggingClipHandle = false;
                                                    });
                                                    widget.controller.finishClipDurationDrag();
                                                  },
                                                  onBodyDragUpdate: (deltaPixels) {
                                                    widget.controller.moveVideoClipPosition(
                                                      clipId: overlayClip.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),

                                      // 7. Audio Tracks
                                      if (project.audioClips.isNotEmpty)
                                        Container(
                                          height: 42,
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Stack(
                                            children: project.audioClips.map((audio) {
                                              final left = (audio.timelineStartMs / 1000.0) * pps;
                                              final isSelected =
                                                  state.selectionType == SelectionType.audioClip &&
                                                      state.selectedItemId == audio.id;
                                              return Positioned(
                                                left: left,
                                                child: AudioTrackItem(
                                                  clip: audio,
                                                  pixelsPerSecond: pps,
                                                  isSelected: isSelected,
                                                  onTap: () => widget.controller.setSelection(
                                                    SelectionType.audioClip,
                                                    audio.id,
                                                  ),
                                                  onHandleDragUpdate: (deltaPixels, isLeftHandle) {
                                                    widget.controller.updateAudioDurationByDrag(
                                                      clipId: audio.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                      isLeftHandle: isLeftHandle,
                                                    );
                                                  },
                                                  onBodyDragUpdate: (deltaPixels) {
                                                    widget.controller.moveAudioTimelinePosition(
                                                      clipId: audio.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Fixed Center Playhead Needle (Stationary at exact viewport center)
                            Positioned(
                              left: halfWidth - 11,
                              top: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: SizedBox(
                                  width: 22,
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Vertical White Laser Needle
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 2.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.6),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Top Triangular Playhead Cap (CapCut Pro style)
                                      Positioned(
                                        top: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(3),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black54,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 4,
                                              height: 4,
                                              decoration: const BoxDecoration(
                                                color: Colors.black,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Bottom Drag Accent Indicator
                                      Positioned(
                                        bottom: 2,
                                        child: Container(
                                          width: 10,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 8. CapCut Floating Zoom-Level Indicator HUD
                            _buildFloatingZoomIndicator(pps),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
