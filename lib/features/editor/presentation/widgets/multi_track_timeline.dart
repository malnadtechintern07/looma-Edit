import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../audio/domain/entities/audio_clip_entity.dart';
import '../../../audio/presentation/widgets/audio_track_item.dart';
import '../../../filters_effects/domain/entities/effect_clip_entity.dart';
import '../../../filters_effects/presentation/widgets/effect_track_item.dart';
import '../../domain/entities/animation_clip_entity.dart';
import '../../../text_stickers/domain/entities/text_overlay_entity.dart';
import '../../../text_stickers/domain/entities/sticker_overlay_entity.dart';
import '../../../text_stickers/presentation/widgets/overlay_track_item.dart';
import '../../../text_stickers/presentation/widgets/text_editor_sheet.dart';
import '../../domain/entities/clip_animation_type.dart';
import '../../domain/entities/subtitle_entity.dart';
import '../../domain/entities/timeline_state.dart';
import '../../domain/entities/video_clip_entity.dart';
import '../providers/editor_controller.dart';
import '../utils/timeline_layout_helper.dart';
import 'animation_track_item.dart';
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
  final ScrollController _verticalScrollController = ScrollController();
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
  double _verticalDragAccumulator = 0.0;

  void _handleVerticalDragUpdate({
    required String clipId,
    required double deltaY,
    required SelectionType type,
  }) {
    _verticalDragAccumulator += deltaY;
    const threshold = 22.0;

    if (_verticalDragAccumulator >= threshold) {
      _verticalDragAccumulator = 0.0;
      if (type == SelectionType.videoClip) {
        // Move from Main Track to Overlay Track (Downward Drag)
        widget.controller.moveClipToTrack(clipId: clipId, toOverlay: true);
      } else {
        // Shift down 1 lane in multi-lane track
        widget.controller.moveClipVerticalLane(clipId, 1);
      }
    } else if (_verticalDragAccumulator <= -threshold) {
      _verticalDragAccumulator = 0.0;
      if (type == SelectionType.overlayClip) {
        // Move from Overlay Track to Main Track (Upward Drag)
        widget.controller.moveClipToTrack(clipId: clipId, toOverlay: false);
      } else {
        // Shift up 1 lane in multi-lane track
        widget.controller.moveClipVerticalLane(clipId, -1);
      }
    }
  }

  void _handleVerticalDragEnd() {
    _verticalDragAccumulator = 0.0;
  }

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
    _verticalScrollController.dispose();
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

  void _hideZoomIndicatorDelayed() {
    _zoomIndicatorTimer?.cancel();
    _zoomIndicatorTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _showZoomIndicator = false;
        });
      }
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _isScaling = true;
    _pinchBasePps = widget.state.pixelsPerSecond;
    _dampedPps = widget.state.pixelsPerSecond;

    // Anchor time at the focal point position
    final halfWidth = _currentViewportWidth / 2;
    final focalPointDx = details.localFocalPoint.dx;
    final currentScroll = _scrollController.hasClients ? _scrollController.offset : 0.0;
    _pinchAnchorTimeSec = (currentScroll + focalPointDx - halfWidth) / _pinchBasePps;

    _triggerZoomIndicator();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;

    // Damped exponential scaling for ultra-smooth zoom feeling
    final rawPps = _pinchBasePps * details.scale;
    _dampedPps = _dampedPps + (rawPps - _dampedPps) * 0.45;

    final targetPps = _dampedPps.clamp(
      AppConstants.minTimelinePixelsPerSecond,
      AppConstants.maxTimelinePixelsPerSecond,
    );

    if (targetPps != widget.state.pixelsPerSecond) {
      widget.controller.setPixelsPerSecond(targetPps);

      // Adjust scroll offset to keep focal point anchored
      if (_scrollController.hasClients) {
        final halfWidth = _currentViewportWidth / 2;
        final focalPointDx = details.localFocalPoint.dx;
        final newScroll = (_pinchAnchorTimeSec * targetPps) - focalPointDx + halfWidth;
        _isProgrammaticScroll = true;
        _scrollController.jumpTo(
          newScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
        _isProgrammaticScroll = false;
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isScaling = false;
    _hideZoomIndicatorDelayed();
  }

  void _onRulerTapOrDrag(double localDx) {
    final halfWidth = _currentViewportWidth / 2;
    final currentScroll = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final targetDx = currentScroll + localDx - halfWidth;
    final pps = widget.state.pixelsPerSecond;
    final totalDurationMs = max(widget.state.project.calculatedDurationMs, max(widget.state.project.durationMs, 1000));
    int targetMs = ((targetDx / pps) * 1000).round().clamp(0, totalDurationMs);

    final selectedClip = widget.state.selectedVideoClip ?? widget.state.activeVideoClip;
    if (selectedClip != null && selectedClip.keyframes.isNotEmpty) {
      for (final kf in selectedClip.keyframes) {
        final kfGlobalMs = selectedClip.timelineStartMs + kf.timestampMs;
        if ((targetMs - kfGlobalMs).abs() <= 35) {
          targetMs = kfGlobalMs;
          break;
        }
      }
    }

    widget.controller.seekTo(targetMs);
  }

  Widget _buildFloatingZoomIndicator(double pps) {
    final zoomFactor = pps / AppConstants.defaultPixelsPerSecond;
    return Positioned(
      top: 36,
      right: 16,
      child: AnimatedOpacity(
        opacity: _showZoomIndicator ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pinch_outlined, size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                '${zoomFactor.toStringAsFixed(1)}x (${pps.toStringAsFixed(0)}px/s)',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
    final totalDurationMs = max(project.calculatedDurationMs, max(project.durationMs, 1000));

    return Container(
      color: const Color(0xFF10121A),
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
                    _hideZoomIndicatorDelayed();
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
                    final newPps = (pps * 0.75).clamp(
                      AppConstants.minTimelinePixelsPerSecond,
                      AppConstants.maxTimelinePixelsPerSecond,
                    );
                    widget.controller.setTimelineZoom(newPps);
                    _triggerZoomIndicator();
                    _hideZoomIndicatorDelayed();
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
                      },
                      onChangeEnd: (v) {
                        _hideZoomIndicatorDelayed();
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
                    final newPps = (pps * 1.35).clamp(
                      AppConstants.minTimelinePixelsPerSecond,
                      AppConstants.maxTimelinePixelsPerSecond,
                    );
                    widget.controller.setTimelineZoom(newPps);
                    _triggerZoomIndicator();
                    _hideZoomIndicatorDelayed();
                  },
                ),
              ],
            ),
          ),

          // Multi-Track Scroll Area (Vertically Scrollable with Bottom Space)
          Expanded(
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                scrollDirection: Axis.vertical,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed Left Track Header Icons
                    Container(
                      width: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF161822),
                        border: Border(right: BorderSide(color: Color(0xFF2E3240), width: 1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: AppConstants.timelineRulerHeight,
                            color: const Color(0xFF1B1E2B),
                            alignment: Alignment.center,
                            child: const Icon(Icons.av_timer, size: 14, color: AppColors.secondary),
                          ),
                          if (state.selectionType == SelectionType.textOverlay && state.selectedItemId != null)
                            const SizedBox(height: 34),
                          if (project.textOverlays.isNotEmpty)
                            Builder(builder: (ctx) {
                              final lanes = TimelineLayoutHelper.computeClipLanes<TextOverlayEntity>(
                                items: project.textOverlays,
                                getStart: (t) => t.timelineStartMs,
                                getEnd: (t) => t.timelineEndMs,
                                getId: (t) => t.id,
                                manualLanes: state.clipLanes,
                              );
                              final trackH = TimelineLayoutHelper.calculateTrackHeight(lanes: lanes, laneHeight: 34, laneGap: 4);
                              return Container(
                                height: trackH,
                                alignment: Alignment.center,
                                child: const Icon(Icons.title, size: 14, color: AppColors.textTrack),
                              );
                            }),
                          if (state.selectionType == SelectionType.subtitle && state.selectedItemId != null)
                            const SizedBox(height: 34),
                          if (project.subtitles.isNotEmpty)
                            Builder(builder: (ctx) {
                              final lanes = TimelineLayoutHelper.computeClipLanes<SubtitleEntity>(
                                items: project.subtitles,
                                getStart: (s) => s.timelineStartMs,
                                getEnd: (s) => s.timelineEndMs,
                                getId: (s) => s.id,
                                manualLanes: state.clipLanes,
                              );
                              final trackH = TimelineLayoutHelper.calculateTrackHeight(lanes: lanes, laneHeight: 28, laneGap: 4);
                              return Container(
                                height: trackH,
                                alignment: Alignment.center,
                                child: const Icon(Icons.subtitles, size: 14, color: Color(0xFFFF9F43)),
                              );
                            }),
                          if (state.selectionType == SelectionType.stickerOverlay && state.selectedItemId != null)
                            const SizedBox(height: 34),
                          if (project.stickerOverlays.isNotEmpty)
                            Builder(builder: (ctx) {
                              final lanes = TimelineLayoutHelper.computeClipLanes<StickerOverlayEntity>(
                                items: project.stickerOverlays,
                                getStart: (s) => s.timelineStartMs,
                                getEnd: (s) => s.timelineEndMs,
                                getId: (s) => s.id,
                                manualLanes: state.clipLanes,
                              );
                              final trackH = TimelineLayoutHelper.calculateTrackHeight(lanes: lanes, laneHeight: 32, laneGap: 4);
                              return Container(
                                height: trackH,
                                alignment: Alignment.center,
                                child: const Icon(Icons.emoji_emotions, size: 14, color: AppColors.stickerTrack),
                              );
                            }),
                          if (state.selectionType == SelectionType.effectClip && state.selectedItemId != null)
                            const SizedBox(height: 34),
                          if (project.effectClips.isNotEmpty)
                            Builder(builder: (ctx) {
                              final lanes = TimelineLayoutHelper.computeClipLanes<EffectClipEntity>(
                                items: project.effectClips,
                                getStart: (e) => e.timelineStartMs,
                                getEnd: (e) => e.timelineEndMs,
                                getId: (e) => e.id,
                                manualLanes: state.clipLanes,
                              );
                              final trackH = TimelineLayoutHelper.calculateTrackHeight(lanes: lanes, laneHeight: 32, laneGap: 4);
                              return Container(
                                height: trackH,
                                alignment: Alignment.center,
                                child: const Icon(Icons.auto_fix_high, size: 14, color: Color(0xFF00E5FF)),
                              );
                            }),
                          if (state.selectionType == SelectionType.animationClip && state.selectedItemId != null)
                            const SizedBox(height: 34),
                          if (project.animationClips.isNotEmpty)
                            Builder(builder: (ctx) {
                              final lanes = TimelineLayoutHelper.computeClipLanes<AnimationClipEntity>(
                                items: project.animationClips,
                                getStart: (a) => a.timelineStartMs,
                                getEnd: (a) => a.timelineEndMs,
                                getId: (a) => a.id,
                                manualLanes: state.clipLanes,
                              );
                              final trackH = TimelineLayoutHelper.calculateTrackHeight(lanes: lanes, laneHeight: 32, laneGap: 4);
                              return Container(
                                height: trackH,
                                alignment: Alignment.center,
                                child: const Icon(Icons.animation, size: 14, color: Color(0xFFFF007A)),
                              );
                            }),
                          if (state.selectionType == SelectionType.videoClip && state.selectedItemId != null)
                            const SizedBox(height: 38),
                          Container(
                            height: AppConstants.timelineTrackHeight,
                            alignment: Alignment.center,
                            child: Icon(
                              project.videoClips.any((c) => !c.isOverlay && c.isPhoto) && !project.videoClips.any((c) => !c.isOverlay && !c.isPhoto)
                                  ? Icons.photo
                                  : Icons.movie,
                              size: 16,
                              color: AppColors.videoTrack,
                            ),
                          ),
                          if (state.selectionType == SelectionType.overlayClip && state.selectedItemId != null)
                            const SizedBox(height: 34),
                          if (project.videoClips.any((c) => c.isOverlay))
                            Builder(builder: (ctx) {
                              final overlayClips = project.videoClips.where((c) => c.isOverlay).toList();
                              final lanes = TimelineLayoutHelper.computeClipLanes<VideoClipEntity>(
                                items: overlayClips,
                                getStart: (c) => c.timelineStartMs,
                                getEnd: (c) => c.timelineEndMs,
                                getId: (c) => c.id,
                                manualLanes: state.clipLanes,
                              );
                              final trackH = TimelineLayoutHelper.calculateTrackHeight(lanes: lanes, laneHeight: AppConstants.timelineTrackHeight, laneGap: 4);
                              return Container(
                                height: trackH,
                                alignment: Alignment.center,
                                child: const Icon(Icons.layers, size: 14, color: AppColors.accentRose),
                              );
                            }),
                          if (state.selectionType == SelectionType.audioClip && state.selectedItemId != null)
                            const SizedBox(height: 34),
                          if (project.audioClips.isNotEmpty)
                            Builder(builder: (ctx) {
                              final lanes = TimelineLayoutHelper.computeClipLanes<AudioClipEntity>(
                                items: project.audioClips,
                                getStart: (a) => a.timelineStartMs,
                                getEnd: (a) => a.timelineEndMs,
                                getId: (a) => a.id,
                                manualLanes: state.clipLanes,
                              );
                              final trackH = TimelineLayoutHelper.calculateTrackHeight(lanes: lanes, laneHeight: 42, laneGap: 4);
                              return Container(
                                height: trackH,
                                alignment: Alignment.center,
                                child: const Icon(Icons.audiotrack, size: 14, color: AppColors.audioTrack),
                              );
                            }),
                          const SizedBox(height: 80),
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
                            300.0,
                            ((totalDurationMs / 1000.0) * pps) + 180.0,
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
                                        int targetMs = ((scrollOffset / pps) * 1000).round().clamp(0, totalDurationMs);

                                        final selectedClip = widget.state.selectedVideoClip ?? widget.state.activeVideoClip;
                                        if (selectedClip != null && selectedClip.keyframes.isNotEmpty) {
                                          for (final kf in selectedClip.keyframes) {
                                            final kfGlobalMs = selectedClip.timelineStartMs + kf.timestampMs;
                                            if ((targetMs - kfGlobalMs).abs() <= 35) {
                                              targetMs = kfGlobalMs;
                                              break;
                                            }
                                          }
                                        }

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
                                      right: halfWidth + 180.0,
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

                                          // 2. Text Overlays Track & Interactive Controls Toolbar
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
                                                      const SizedBox(width: 8),
                                                      // Edit Text
                                                      InkWell(
                                                        onTap: () {
                                                          showModalBottomSheet(
                                                            context: context,
                                                            isScrollControlled: true,
                                                            backgroundColor: const Color(0xFF161822),
                                                            builder: (ctx) => TextEditorSheet(
                                                              initialText: selText,
                                                              onSave: ({
                                                                required text,
                                                                required fontFamily,
                                                                required fontSize,
                                                                required colorHex,
                                                                backgroundColorHex,
                                                                required animationType,
                                                              }) {
                                                                widget.controller.updateTextOverlay(
                                                                  selText.copyWith(
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
                                                        },
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.textTrack.withValues(alpha: 0.25),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: AppColors.textTrack, width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.edit, size: 12, color: AppColors.textTrack),
                                                              SizedBox(width: 4),
                                                              Text('Edit', style: TextStyle(fontSize: 10, color: AppColors.textTrack, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      // Switch to Empty Space
                                                      InkWell(
                                                        onTap: () => widget.controller.switchClipToEmptySpace(selText.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.space_bar, size: 12, color: Color(0xFF00E5FF)),
                                                              SizedBox(width: 4),
                                                              Text('↔ Empty Space', style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      // Row Down
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selText.id, 1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.textTrack.withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: AppColors.textTrack, width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_downward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↓ Row Down', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      // Row Up
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selText.id, -1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.textTrack.withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: AppColors.textTrack, width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↑ Row Up', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      // Duplicate
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
                                                      const SizedBox(width: 8),
                                                      // Delete
                                                      InkWell(
                                                        onTap: () => widget.controller.deleteTextOverlay(selText.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.error.withValues(alpha: 0.2),
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

                                          // 2. Text Overlays Multi-Lane Track (Never overlapping)
                                          if (project.textOverlays.isNotEmpty)
                                            Builder(builder: (ctx) {
                                              final lanes = TimelineLayoutHelper.computeClipLanes<TextOverlayEntity>(
                                                items: project.textOverlays,
                                                getStart: (t) => t.timelineStartMs,
                                                getEnd: (t) => t.timelineEndMs,
                                                getId: (t) => t.id,
                                                manualLanes: state.clipLanes,
                                              );
                                              const laneH = 34.0;
                                              const laneGap = 4.0;
                                              final trackH = TimelineLayoutHelper.calculateTrackHeight(
                                                lanes: lanes,
                                                laneHeight: laneH,
                                                laneGap: laneGap,
                                              );

                                              return Container(
                                                height: trackH,
                                                margin: const EdgeInsets.symmetric(vertical: 2),
                                                child: Stack(
                                                  children: project.textOverlays.map((textItem) {
                                                    final left = (textItem.timelineStartMs / 1000.0) * pps;
                                                    final laneIdx = lanes[textItem.id] ?? 0;
                                                    final top = laneIdx * (laneH + laneGap);
                                                    final isSelected =
                                                        state.selectionType == SelectionType.textOverlay &&
                                                            state.selectedItemId == textItem.id;
                                                    return Positioned(
                                                      left: left,
                                                      top: top,
                                                      height: laneH,
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
                                                        onVerticalDragUpdate: (deltaPixels) {
                                                          _handleVerticalDragUpdate(
                                                            clipId: textItem.id,
                                                            deltaY: deltaPixels,
                                                            type: SelectionType.textOverlay,
                                                          );
                                                        },
                                                        onVerticalDragEnd: _handleVerticalDragEnd,
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              );
                                            }),

                                          // 3. Subtitles Track Toolbar
                                          if (state.selectionType == SelectionType.subtitle && state.selectedItemId != null) ...[
                                            Builder(builder: (ctx) {
                                              final selSub = project.subtitles.where((s) => s.id == state.selectedItemId).firstOrNull;
                                              if (selSub == null) return const SizedBox.shrink();

                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceElevated,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFFF9F43).withValues(alpha: 0.5)),
                                                ),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.subtitles, size: 14, color: Color(0xFFFF9F43)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Subtitle: "${selSub.text}"',
                                                        style: AppTypography.labelSmall.copyWith(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      InkWell(
                                                        onTap: () => widget.controller.switchClipToEmptySpace(selSub.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.space_bar, size: 12, color: Color(0xFF00E5FF)),
                                                              SizedBox(width: 4),
                                                              Text('↔ Empty Space', style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selSub.id, 1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFF9F43).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFFF9F43), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_downward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↓ Row Down', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selSub.id, -1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFF9F43).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFFF9F43), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↑ Row Up', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.duplicateSubtitle(selSub.id),
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
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.deleteSubtitle(selSub.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.error.withValues(alpha: 0.2),
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
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        '↔ Drag handles to trim • Drag subtitle to reposition',
                                                        style: TextStyle(fontSize: 10, color: Color(0xFFFF9F43)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],

                                          // 3. Subtitles Track (Multi-Lane)
                                          if (project.subtitles.isNotEmpty)
                                            Builder(builder: (ctx) {
                                              final lanes = TimelineLayoutHelper.computeClipLanes<SubtitleEntity>(
                                                items: project.subtitles,
                                                getStart: (s) => s.timelineStartMs,
                                                getEnd: (s) => s.timelineEndMs,
                                                getId: (s) => s.id,
                                                manualLanes: state.clipLanes,
                                              );
                                              const laneH = 28.0;
                                              const laneGap = 4.0;
                                              final trackH = TimelineLayoutHelper.calculateTrackHeight(
                                                lanes: lanes,
                                                laneHeight: laneH,
                                                laneGap: laneGap,
                                              );

                                              return Container(
                                                height: trackH,
                                                margin: const EdgeInsets.symmetric(vertical: 2),
                                                child: Stack(
                                                  children: project.subtitles.map((sub) {
                                                    final left = (sub.timelineStartMs / 1000.0) * pps;
                                                    final laneIdx = lanes[sub.id] ?? 0;
                                                    final top = laneIdx * (laneH + laneGap);
                                                    final isSelected = state.selectionType == SelectionType.subtitle &&
                                                        state.selectedItemId == sub.id;
                                                    return Positioned(
                                                      left: left,
                                                      top: top,
                                                      height: laneH,
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
                                              );
                                            }),

                                          // 4. Sticker Overlays Track Toolbar
                                          if (state.selectionType == SelectionType.stickerOverlay && state.selectedItemId != null) ...[
                                            Builder(builder: (ctx) {
                                              final selSticker = project.stickerOverlays.where((s) => s.id == state.selectedItemId).firstOrNull;
                                              if (selSticker == null) return const SizedBox.shrink();

                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceElevated,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFFFD600).withValues(alpha: 0.5)),
                                                ),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.emoji_emotions, size: 14, color: Color(0xFFFFD600)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Sticker: "${selSticker.stickerName}"',
                                                        style: AppTypography.labelSmall.copyWith(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      InkWell(
                                                        onTap: () => widget.controller.switchClipToEmptySpace(selSticker.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.space_bar, size: 12, color: Color(0xFF00E5FF)),
                                                              SizedBox(width: 4),
                                                              Text('↔ Empty Space', style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selSticker.id, 1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFFD600).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFFFD600), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_downward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↓ Row Down', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selSticker.id, -1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFFD600).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFFFD600), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↑ Row Up', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.duplicateStickerOverlay(selSticker.id),
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
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.deleteStickerOverlay(selSticker.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.error.withValues(alpha: 0.2),
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
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        '↔ Drag handles to trim • Drag sticker to reposition',
                                                        style: TextStyle(fontSize: 10, color: Color(0xFFFFD600)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],

                                          // 4. Sticker Overlays Track (Multi-Lane)
                                          if (project.stickerOverlays.isNotEmpty)
                                            Builder(builder: (ctx) {
                                              final lanes = TimelineLayoutHelper.computeClipLanes<StickerOverlayEntity>(
                                                items: project.stickerOverlays,
                                                getStart: (s) => s.timelineStartMs,
                                                getEnd: (s) => s.timelineEndMs,
                                                getId: (s) => s.id,
                                                manualLanes: state.clipLanes,
                                              );
                                              const laneH = 32.0;
                                              const laneGap = 4.0;
                                              final trackH = TimelineLayoutHelper.calculateTrackHeight(
                                                lanes: lanes,
                                                laneHeight: laneH,
                                                laneGap: laneGap,
                                              );

                                              return Container(
                                                height: trackH,
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Stack(
                                                  children: project.stickerOverlays.map((sticker) {
                                                    final left = (sticker.timelineStartMs / 1000.0) * pps;
                                                    final laneIdx = lanes[sticker.id] ?? 0;
                                                    final top = laneIdx * (laneH + laneGap);
                                                    final isSelected =
                                                        state.selectionType == SelectionType.stickerOverlay &&
                                                            state.selectedItemId == sticker.id;
                                                    return Positioned(
                                                      left: left,
                                                      top: top,
                                                      height: laneH,
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
                                                        onVerticalDragUpdate: (deltaPixels) {
                                                          _handleVerticalDragUpdate(
                                                            clipId: sticker.id,
                                                            deltaY: deltaPixels,
                                                            type: SelectionType.stickerOverlay,
                                                          );
                                                        },
                                                        onVerticalDragEnd: _handleVerticalDragEnd,
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              );
                                            }),

                                          // 4b. Effects Track Toolbar
                                          if (state.selectionType == SelectionType.effectClip && state.selectedItemId != null) ...[
                                            Builder(builder: (ctx) {
                                              final selEff = project.effectClips.where((e) => e.id == state.selectedItemId).firstOrNull;
                                              if (selEff == null) return const SizedBox.shrink();

                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceElevated,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                                                ),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.auto_fix_high, size: 14, color: Color(0xFF00E5FF)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Effect: ${selEff.effectType.label}',
                                                        style: AppTypography.labelSmall.copyWith(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      InkWell(
                                                        onTap: () => widget.controller.switchClipToEmptySpace(selEff.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.space_bar, size: 12, color: Color(0xFF00E5FF)),
                                                              SizedBox(width: 4),
                                                              Text('↔ Empty Space', style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selEff.id, 1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_downward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↓ Row Down', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selEff.id, -1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↑ Row Up', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.duplicateEffectClip(selEff.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.copy, size: 12, color: Color(0xFF00E5FF)),
                                                              SizedBox(width: 4),
                                                              Text('Duplicate', style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF))),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.deleteEffectClip(selEff.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.error.withValues(alpha: 0.2),
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
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        '↔ Drag handles to trim • Drag clip to reposition',
                                                        style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],

                                          // 4b. Effects Track (Multi-Lane)
                                          if (project.effectClips.isNotEmpty)
                                            Builder(builder: (ctx) {
                                              final lanes = TimelineLayoutHelper.computeClipLanes<EffectClipEntity>(
                                                items: project.effectClips,
                                                getStart: (e) => e.timelineStartMs,
                                                getEnd: (e) => e.timelineEndMs,
                                                getId: (e) => e.id,
                                                manualLanes: state.clipLanes,
                                              );
                                              const laneH = 32.0;
                                              const laneGap = 4.0;
                                              final trackH = TimelineLayoutHelper.calculateTrackHeight(
                                                lanes: lanes,
                                                laneHeight: laneH,
                                                laneGap: laneGap,
                                              );

                                              return Container(
                                                height: trackH,
                                                margin: const EdgeInsets.symmetric(vertical: 2),
                                                child: Stack(
                                                  children: project.effectClips.map((eff) {
                                                    final left = (eff.timelineStartMs / 1000.0) * pps;
                                                    final laneIdx = lanes[eff.id] ?? 0;
                                                    final top = laneIdx * (laneH + laneGap);
                                                    final isSelected = state.selectionType == SelectionType.effectClip &&
                                                        state.selectedItemId == eff.id;
                                                    return Positioned(
                                                      left: left,
                                                      top: top,
                                                      height: laneH,
                                                      child: EffectTrackItem(
                                                        item: eff,
                                                        pixelsPerSecond: pps,
                                                        isSelected: isSelected,
                                                        onTap: () => widget.controller.setSelection(
                                                          SelectionType.effectClip,
                                                          eff.id,
                                                        ),
                                                        onHandleDragUpdate: (deltaPixels, isLeftHandle) {
                                                          widget.controller.updateEffectDurationByDrag(
                                                            effectId: eff.id,
                                                            deltaPixels: deltaPixels,
                                                            pixelsPerSecond: pps,
                                                            isLeftHandle: isLeftHandle,
                                                          );
                                                        },
                                                        onSlideDragUpdate: (deltaPixels) {
                                                          widget.controller.moveEffectClipPosition(
                                                            effectId: eff.id,
                                                            deltaPixels: deltaPixels,
                                                            pixelsPerSecond: pps,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              );
                                            }),

                                          // 4c. Animations Track Toolbar
                                          if (state.selectionType == SelectionType.animationClip && state.selectedItemId != null) ...[
                                            Builder(builder: (ctx) {
                                              final selAnim = project.animationClips.where((a) => a.id == state.selectedItemId).firstOrNull;
                                              if (selAnim == null) return const SizedBox.shrink();

                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceElevated,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFFF007A).withValues(alpha: 0.5)),
                                                ),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.animation, size: 14, color: Color(0xFFFF007A)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Animation: ${selAnim.animationType.label}',
                                                        style: AppTypography.labelSmall.copyWith(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      InkWell(
                                                        onTap: () => widget.controller.switchClipToEmptySpace(selAnim.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.space_bar, size: 12, color: Color(0xFF00E5FF)),
                                                              SizedBox(width: 4),
                                                              Text('↔ Empty Space', style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selAnim.id, 1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFF007A).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFFF007A), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_downward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↓ Row Down', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selAnim.id, -1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFF007A).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFFF007A), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↑ Row Up', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.duplicateAnimationClip(selAnim.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFF007A).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFFF007A), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.copy, size: 12, color: Color(0xFFFF007A)),
                                                              SizedBox(width: 4),
                                                              Text('Duplicate', style: TextStyle(fontSize: 10, color: Color(0xFFFF007A))),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.deleteAnimationClip(selAnim.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.error.withValues(alpha: 0.2),
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
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        '↔ Drag handles to trim • Drag clip to reposition',
                                                        style: TextStyle(fontSize: 10, color: Color(0xFFFF007A)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],

                                          // 4c. Animations Track (Multi-Lane)
                                          if (project.animationClips.isNotEmpty)
                                            Builder(builder: (ctx) {
                                              final lanes = TimelineLayoutHelper.computeClipLanes<AnimationClipEntity>(
                                                items: project.animationClips,
                                                getStart: (a) => a.timelineStartMs,
                                                getEnd: (a) => a.timelineEndMs,
                                                getId: (a) => a.id,
                                                manualLanes: state.clipLanes,
                                              );
                                              const laneH = 32.0;
                                              const laneGap = 4.0;
                                              final trackH = TimelineLayoutHelper.calculateTrackHeight(
                                                lanes: lanes,
                                                laneHeight: laneH,
                                                laneGap: laneGap,
                                              );

                                              return Container(
                                                height: trackH,
                                                margin: const EdgeInsets.symmetric(vertical: 2),
                                                child: Stack(
                                                  children: project.animationClips.map((anim) {
                                                    final left = (anim.timelineStartMs / 1000.0) * pps;
                                                    final laneIdx = lanes[anim.id] ?? 0;
                                                    final top = laneIdx * (laneH + laneGap);
                                                    final isSelected = state.selectionType == SelectionType.animationClip &&
                                                        state.selectedItemId == anim.id;
                                                    return Positioned(
                                                      left: left,
                                                      top: top,
                                                      height: laneH,
                                                      child: AnimationTrackItem(
                                                        item: anim,
                                                        pixelsPerSecond: pps,
                                                        isSelected: isSelected,
                                                        onTap: () => widget.controller.setSelection(
                                                          SelectionType.animationClip,
                                                          anim.id,
                                                        ),
                                                        onHandleDragUpdate: (deltaPixels, isLeftHandle) {
                                                          widget.controller.updateAnimationDurationByDrag(
                                                            animationId: anim.id,
                                                            deltaPixels: deltaPixels,
                                                            pixelsPerSecond: pps,
                                                            isLeftHandle: isLeftHandle,
                                                          );
                                                        },
                                                        onSlideDragUpdate: (deltaPixels) {
                                                          widget.controller.moveAnimationPositionByDrag(
                                                            animationId: anim.id,
                                                            deltaPixels: deltaPixels,
                                                            pixelsPerSecond: pps,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              );
                                            }),

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
                                                      // Move to Overlay (PIP) track button (Vertical Track Placement)
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipToTrack(
                                                          clipId: selClip.id,
                                                          toOverlay: true,
                                                        ),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.accentRose.withValues(alpha: 0.25),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: AppColors.accentRose, width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_downward, size: 12, color: AppColors.accentRose),
                                                              SizedBox(width: 4),
                                                              Text('↓ To Overlay', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
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
                                                  currentPlayheadMs: state.playheadPositionMs,
                                                  onKeyframeTap: (timestampMs) => widget.controller.seekTo(clip.timelineStartMs + timestampMs),
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
                                                  onVerticalDragUpdate: (deltaPixels) {
                                                    _handleVerticalDragUpdate(
                                                      clipId: clip.id,
                                                      deltaY: deltaPixels,
                                                      type: SelectionType.videoClip,
                                                    );
                                                  },
                                                  onVerticalDragEnd: _handleVerticalDragEnd,
                                                );

                                                return Positioned(
                                                  left: left,
                                                  child: DragTarget<Map<String, dynamic>>(
                                                    onWillAcceptWithDetails: (details) => details.data['id'] != clip.id,
                                                    onAcceptWithDetails: (details) {
                                                      if (details.data['type'] == 'videoClip') {
                                                        final fromIndex = details.data['index'] as int?;
                                                        if (fromIndex != null) {
                                                          widget.controller.reorderVideoClips(fromIndex, index);
                                                        }
                                                      } else if (details.data['type'] == 'overlayClip') {
                                                        final overlayId = details.data['id'] as String?;
                                                        if (overlayId != null) {
                                                          widget.controller.moveClipToTrack(
                                                            clipId: overlayId,
                                                            toOverlay: false,
                                                            targetTimelineStartMs: clip.timelineStartMs,
                                                          );
                                                        }
                                                      }
                                                    },
                                                    builder: (context, candidateData, rejectedData) {
                                                      final isTargeting = candidateData.isNotEmpty;
                                                      return Stack(
                                                        children: [
                                                          LongPressDraggable<Map<String, dynamic>>(
                                                            data: {'type': 'videoClip', 'id': clip.id, 'index': index},
                                                            feedback: Material(
                                                              color: Colors.transparent,
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                                decoration: BoxDecoration(
                                                                  color: AppColors.primary.withValues(alpha: 0.95),
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  border: Border.all(color: Colors.white, width: 2),
                                                                  boxShadow: const [
                                                                    BoxShadow(
                                                                      color: Colors.black87,
                                                                      blurRadius: 16,
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
                                                                  color: AppColors.primary.withValues(alpha: 0.35),
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

                                          // 6. PIP Overlay Track Toolbar
                                          if (project.videoClips.any((c) => c.isOverlay) &&
                                              state.selectionType == SelectionType.overlayClip &&
                                              state.selectedItemId != null) ...[
                                            Builder(builder: (ctx) {
                                              final selOverlay = project.videoClips.where((c) => c.isOverlay && c.id == state.selectedItemId).firstOrNull;
                                              if (selOverlay == null) return const SizedBox.shrink();

                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceElevated,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.5)),
                                                ),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.layers, size: 14, color: AppColors.accentRose),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Overlay: ${selOverlay.name}',
                                                        style: AppTypography.labelSmall.copyWith(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      // Move to Main Track
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipToTrack(
                                                          clipId: selOverlay.id,
                                                          toOverlay: false,
                                                        ),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.primary.withValues(alpha: 0.25),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: AppColors.primary, width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_upward, size: 12, color: AppColors.primaryLight),
                                                              SizedBox(width: 4),
                                                              Text('↑ Main Track', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      // Empty space
                                                      InkWell(
                                                        onTap: () => widget.controller.switchClipToEmptySpace(selOverlay.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.space_bar, size: 12, color: Color(0xFF00E5FF)),
                                                              SizedBox(width: 4),
                                                              Text('↔ Empty Space', style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      // Row down
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selOverlay.id, 1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.accentRose.withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: AppColors.accentRose, width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_downward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↓ Row Down', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      // Row up
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selOverlay.id, -1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.accentRose.withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: AppColors.accentRose, width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↑ Row Up', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      // Split
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
                                                      // Duplicate
                                                      InkWell(
                                                        onTap: () => widget.controller.duplicateVideoClip(selOverlay.id),
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
                                                      // Delete
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
                                                          clipId: selOverlay.id,
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
                                                          clipId: selOverlay.id,
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
                                                        '↔ Drag handles to trim • Drag clip to move • No overlap',
                                                        style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],

                                          if (project.videoClips.any((c) => c.isOverlay))
                                            Builder(builder: (ctx) {
                                              final overlayClips = project.videoClips.where((c) => c.isOverlay).toList();
                                              final lanes = TimelineLayoutHelper.computeClipLanes<VideoClipEntity>(
                                                items: overlayClips,
                                                getStart: (c) => c.timelineStartMs,
                                                getEnd: (c) => c.timelineEndMs,
                                                getId: (c) => c.id,
                                                manualLanes: state.clipLanes,
                                              );
                                              final laneH = AppConstants.timelineTrackHeight;
                                              const laneGap = 4.0;
                                              final trackH = TimelineLayoutHelper.calculateTrackHeight(
                                                lanes: lanes,
                                                laneHeight: laneH,
                                                laneGap: laneGap,
                                              );

                                              return DragTarget<Map<String, dynamic>>(
                                                onWillAcceptWithDetails: (details) => details.data['type'] == 'videoClip',
                                                onAcceptWithDetails: (details) {
                                                  final clipId = details.data['id'] as String?;
                                                  if (clipId != null) {
                                                    widget.controller.moveClipToTrack(
                                                      clipId: clipId,
                                                      toOverlay: true,
                                                    );
                                                  }
                                                },
                                                builder: (context, candidateData, rejectedData) {
                                                  final isTargeting = candidateData.isNotEmpty;
                                                  return Container(
                                                    height: trackH,
                                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                                    decoration: isTargeting
                                                        ? BoxDecoration(
                                                            color: AppColors.accentRose.withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: AppColors.accentRose, width: 1.5),
                                                          )
                                                        : null,
                                                    child: Stack(
                                                      clipBehavior: Clip.none,
                                                      children: overlayClips.map((overlayClip) {
                                                        final left = (overlayClip.timelineStartMs / 1000.0) * pps;
                                                        final laneIdx = lanes[overlayClip.id] ?? 0;
                                                        final top = laneIdx * (laneH + laneGap);
                                                        final isSelected = state.selectionType == SelectionType.overlayClip &&
                                                            state.selectedItemId == overlayClip.id;
                                                        return Positioned(
                                                          left: left,
                                                          top: top,
                                                          height: laneH,
                                                          child: VideoTrackItem(
                                                            clip: overlayClip,
                                                            pixelsPerSecond: pps,
                                                            isSelected: isSelected,
                                                            currentPlayheadMs: state.playheadPositionMs,
                                                            onKeyframeTap: (timestampMs) => widget.controller.seekTo(overlayClip.timelineStartMs + timestampMs),
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
                                                            onVerticalDragUpdate: (deltaPixels) {
                                                              _handleVerticalDragUpdate(
                                                                clipId: overlayClip.id,
                                                                deltaY: deltaPixels,
                                                                type: SelectionType.overlayClip,
                                                              );
                                                            },
                                                            onVerticalDragEnd: _handleVerticalDragEnd,
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  );
                                                },
                                              );
                                            }),

                                          // 7. Audio Tracks Toolbar
                                          if (state.selectionType == SelectionType.audioClip && state.selectedItemId != null) ...[
                                            Builder(builder: (ctx) {
                                              final selAudio = project.audioClips.where((a) => a.id == state.selectedItemId).firstOrNull;
                                              if (selAudio == null) return const SizedBox.shrink();

                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceElevated,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5)),
                                                ),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.music_note, size: 14, color: Color(0xFF00E676)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Audio: ${selAudio.title}',
                                                        style: AppTypography.labelSmall.copyWith(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      InkWell(
                                                        onTap: () => widget.controller.switchClipToEmptySpace(selAudio.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.space_bar, size: 12, color: Color(0xFF00E5FF)),
                                                              SizedBox(width: 4),
                                                              Text('↔ Empty Space', style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selAudio.id, 1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E676).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E676), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_downward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↓ Row Down', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => widget.controller.moveClipVerticalLane(selAudio.id, -1),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E676).withValues(alpha: 0.35),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E676), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                                                              SizedBox(width: 4),
                                                              Text('↑ Row Up', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.duplicateAudioClip(selAudio.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF00E676).withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFF00E676), width: 1),
                                                          ),
                                                          child: const Row(
                                                            children: [
                                                              Icon(Icons.copy, size: 12, color: Color(0xFF00E676)),
                                                              SizedBox(width: 4),
                                                              Text('Duplicate', style: TextStyle(fontSize: 10, color: Color(0xFF00E676))),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => widget.controller.deleteAudioTrack(selAudio.id),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.error.withValues(alpha: 0.2),
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
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        '↔ Drag handles to trim • Drag clip to move',
                                                        style: TextStyle(fontSize: 10, color: Color(0xFF00E676)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],

                                          // 7. Audio Tracks (Multi-Lane)
                                          if (project.audioClips.isNotEmpty)
                                            Builder(builder: (ctx) {
                                              final lanes = TimelineLayoutHelper.computeClipLanes<AudioClipEntity>(
                                                items: project.audioClips,
                                                getStart: (a) => a.timelineStartMs,
                                                getEnd: (a) => a.timelineEndMs,
                                                getId: (a) => a.id,
                                                manualLanes: state.clipLanes,
                                              );
                                              const laneH = 42.0;
                                              const laneGap = 4.0;
                                              final trackH = TimelineLayoutHelper.calculateTrackHeight(
                                                lanes: lanes,
                                                laneHeight: laneH,
                                                laneGap: laneGap,
                                              );

                                              return Container(
                                                height: trackH,
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Stack(
                                                  children: project.audioClips.map((audio) {
                                                    final left = (audio.timelineStartMs / 1000.0) * pps;
                                                    final laneIdx = lanes[audio.id] ?? 0;
                                                    final top = laneIdx * (laneH + laneGap);
                                                    final isSelected =
                                                        state.selectionType == SelectionType.audioClip &&
                                                            state.selectedItemId == audio.id;
                                                    return Positioned(
                                                      left: left,
                                                      top: top,
                                                      height: laneH,
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
                                              );
                                            }),

                                          // 8. Expanded bottom buffer so user can see down when scrolling
                                          const SizedBox(height: 80),
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
            ),
          ),
        ],
      ),
    );
  }
}
