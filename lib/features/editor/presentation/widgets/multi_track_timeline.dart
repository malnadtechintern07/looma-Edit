import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../audio/presentation/widgets/audio_track_item.dart';
import '../../../text_stickers/presentation/widgets/overlay_track_item.dart';
import '../../domain/entities/timeline_state.dart';
import '../providers/editor_controller.dart';
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

  @override
  void didUpdateWidget(covariant MultiTrackTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isPlaying && !_isUserScrubbing && _scrollController.hasClients) {
      final pps = widget.state.pixelsPerSecond;
      final playheadX = (widget.state.playheadPositionMs / 1000) * pps;
      final viewportWidth = _scrollController.position.viewportDimension;
      final currentScroll = _scrollController.offset;

      // Keep playhead comfortably visible during playback
      if (playheadX > currentScroll + viewportWidth * 0.75 || playheadX < currentScroll) {
        _scrollController.jumpTo(max(0, playheadX - viewportWidth * 0.25));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onRulerTapOrDrag(double localX) {
    final pps = widget.state.pixelsPerSecond;
    final totalMs = widget.state.project.calculatedDurationMs;
    final targetMs = ((localX / pps) * 1000).round().clamp(0, totalMs);
    widget.controller.seekTo(targetMs);
  }

  void _onPlayheadDelta(double deltaDx) {
    final pps = widget.state.pixelsPerSecond;
    final totalMs = widget.state.project.calculatedDurationMs;
    final deltaMs = ((deltaDx / pps) * 1000).round();
    final newPosMs = (widget.state.playheadPositionMs + deltaMs).clamp(0, totalMs);
    widget.controller.seekTo(newPosMs);

    // Auto-scroll when dragging near viewport boundaries
    if (_scrollController.hasClients) {
      final playheadX = (newPosMs / 1000) * pps;
      final currentScroll = _scrollController.offset;
      final viewportWidth = _scrollController.position.viewportDimension;

      if (playheadX > currentScroll + viewportWidth - 40) {
        _scrollController.jumpTo(min(
          _scrollController.position.maxScrollExtent,
          currentScroll + 12,
        ));
      } else if (playheadX < currentScroll + 40 && currentScroll > 0) {
        _scrollController.jumpTo(max(0, currentScroll - 12));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final project = state.project;
    final pps = state.pixelsPerSecond;
    final totalDurationMs = project.calculatedDurationMs;
    final playheadX = (state.playheadPositionMs / 1000) * pps;
    final contentWidth = max(
      MediaQuery.of(context).size.width,
      ((totalDurationMs / 1000) + 4) * pps,
    );

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Timeline Toolbar (Zoom control & track summary)
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.layers_outlined, size: 14, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      '${project.videoClips.length} Clips • ${project.audioClips.length} Audio • ${project.textOverlays.length} Text',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // Timeline Zoom Controls
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_out, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () => widget.controller.setTimelineZoom(pps - 15),
                    ),
                    SizedBox(
                      width: 80,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surfaceBorder,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: pps,
                          min: 20,
                          max: 150,
                          onChanged: (v) => widget.controller.setTimelineZoom(v),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () => widget.controller.setTimelineZoom(pps + 15),
                    ),
                  ],
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
                  width: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(right: BorderSide(color: AppColors.surfaceBorder, width: 1)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: AppConstants.timelineRulerHeight,
                        color: AppColors.surfaceElevated,
                        alignment: Alignment.center,
                        child: const Icon(Icons.av_timer, size: 14, color: AppColors.primaryLight),
                      ),
                      if (project.textOverlays.isNotEmpty)
                        Container(
                          height: 32,
                          alignment: Alignment.center,
                          child: const Icon(Icons.title, size: 14, color: AppColors.textTrack),
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
                      if (project.audioClips.isNotEmpty)
                        Container(
                          height: 42,
                          alignment: Alignment.center,
                          child: const Icon(Icons.audiotrack, size: 14, color: AppColors.audioTrack),
                        ),
                    ],
                  ),
                ),

                // Scrollable Tracks Canvas & Ultra-Smooth Drag Playhead
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: contentWidth,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Tracks Content Column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Interactive Timeline Ruler with Scrub Support
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) {
                                  _isUserScrubbing = true;
                                  _onRulerTapOrDrag(details.localPosition.dx);
                                },
                                onHorizontalDragStart: (_) => _isUserScrubbing = true,
                                onHorizontalDragUpdate: (details) {
                                  _onRulerTapOrDrag(details.localPosition.dx);
                                },
                                onHorizontalDragEnd: (_) => _isUserScrubbing = false,
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
                                      final left = (textItem.timelineStartMs / 1000) * pps;
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

                              // 3. Sticker Overlays Track
                              if (project.stickerOverlays.isNotEmpty)
                                Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Stack(
                                    children: project.stickerOverlays.map((sticker) {
                                      final left = (sticker.timelineStartMs / 1000) * pps;
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
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                              // 4. Main Video Clips Track (Interactive Drag & Drop Reordering & Duration Extension)
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
                                          const SizedBox(width: 12),
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
                                          const SizedBox(width: 12),
                                          const Text(
                                            '↔ Drag handle (▶) to extend clip',
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
                                  children: List.generate(project.videoClips.length, (index) {
                                    final clip = project.videoClips[index];
                                    final left = (clip.timelineStartMs / 1000) * pps;
                                    final isSelected =
                                        state.selectionType == SelectionType.videoClip &&
                                            state.selectedItemId == clip.id;

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
                                                  child: VideoTrackItem(
                                                    clip: clip,
                                                    pixelsPerSecond: pps,
                                                    isSelected: isSelected,
                                                    onTap: () => widget.controller.setSelection(
                                                      SelectionType.videoClip,
                                                      clip.id,
                                                    ),
                                                  ),
                                                ),
                                                child: VideoTrackItem(
                                                  clip: clip,
                                                  pixelsPerSecond: pps,
                                                  isSelected: isSelected,
                                                  onTap: () => widget.controller.setSelection(
                                                    SelectionType.videoClip,
                                                    clip.id,
                                                  ),
                                                  onHandleDragUpdate: (deltaPixels, isLeftHandle) {
                                                    widget.controller.updateClipDurationByDrag(
                                                      clipId: clip.id,
                                                      deltaPixels: deltaPixels,
                                                      pixelsPerSecond: pps,
                                                      isLeftHandle: isLeftHandle,
                                                    );
                                                  },
                                                ),
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

                              // 5. Audio Tracks
                              if (project.audioClips.isNotEmpty)
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Stack(
                                    children: project.audioClips.map((audio) {
                                      final left = (audio.timelineStartMs / 1000) * pps;
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
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),

                          // 6. Dedicated Interactive Playhead Scrubber (Smooth Drag Hitbox & Cap)
                          Positioned(
                            left: playheadX - 22,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragStart: (_) {
                                _isUserScrubbing = true;
                              },
                              onHorizontalDragUpdate: (details) {
                                _onPlayheadDelta(details.delta.dx);
                              },
                              onHorizontalDragEnd: (_) {
                                _isUserScrubbing = false;
                              },
                              child: SizedBox(
                                width: 44,
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Vertical Laser Needle
                                    Positioned(
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 2.0,
                                        decoration: BoxDecoration(
                                          color: AppColors.playhead,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.playhead.withValues(alpha: 0.8),
                                              blurRadius: 8,
                                              spreadRadius: 1.5,
                                            ),
                                            const BoxShadow(
                                              color: Colors.white,
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Top Playhead Scrubber Handle (CapCut Pro Diamond/Badge)
                                    Positioned(
                                      top: 0,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: AppColors.playhead,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.playhead.withValues(alpha: 0.6),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Bottom Drag Pill for easy thumb grabbing
                                    Positioned(
                                      bottom: 2,
                                      child: Container(
                                        width: 14,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.playhead,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.white70, width: 1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
