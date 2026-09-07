import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../../filters_effects/domain/entities/video_effect_type.dart';
import '../../domain/entities/clip_animation_type.dart';
import '../../domain/entities/mask_config_entity.dart';
import '../../domain/entities/video_clip_entity.dart';

/// Alias for VideoTrackItem matching standard timeline clip nomenclature
typedef TimelineClipWidget = VideoTrackItem;

class _BadgeItem {
  final Widget widget;
  final double estimatedWidth;

  const _BadgeItem({
    required this.widget,
    required this.estimatedWidth,
  });
}

class VideoTrackItem extends StatefulWidget {
  final VideoClipEntity clip;
  final double pixelsPerSecond;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double deltaPixels, bool isLeftHandle)? onHandleDragUpdate;
  final Function(double deltaPixels)? onBodyDragUpdate;
  final Function(double deltaPixels)? onVerticalDragUpdate;
  final VoidCallback? onVerticalDragEnd;
  final VoidCallback? onHandleDragStart;
  final VoidCallback? onHandleDragEnd;
  final Function(int timestampMs)? onKeyframeTap;
  final int? currentPlayheadMs;

  const VideoTrackItem({
    super.key,
    required this.clip,
    required this.pixelsPerSecond,
    required this.isSelected,
    required this.onTap,
    this.onHandleDragUpdate,
    this.onBodyDragUpdate,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onHandleDragStart,
    this.onHandleDragEnd,
    this.onKeyframeTap,
    this.currentPlayheadMs,
  });

  @override
  State<VideoTrackItem> createState() => _VideoTrackItemState();
}

class _VideoTrackItemState extends State<VideoTrackItem> {
  bool _isDraggingLeft = false;
  bool _isDraggingRight = false;

  VideoClipEntity get clip => widget.clip;
  bool get isSelected => widget.isSelected;
  double get pixelsPerSecond => widget.pixelsPerSecond;
  VoidCallback get onTap => widget.onTap;
  Function(double deltaPixels, bool isLeftHandle)? get onHandleDragUpdate => widget.onHandleDragUpdate;
  Function(double deltaPixels)? get onBodyDragUpdate => widget.onBodyDragUpdate;
  Function(double deltaPixels)? get onVerticalDragUpdate => widget.onVerticalDragUpdate;
  VoidCallback? get onVerticalDragEnd => widget.onVerticalDragEnd;

  bool _isImageFile(String path) {
    return widget.clip.isPhoto;
  }

  Widget _buildFilmstripBackground(double width) {
    final path = clip.mediaPath;
    final cleanPath = path.startsWith('file://') ? path.substring(7) : path;

    if (_isImageFile(path)) {
      Widget singleFrame;
      if (path.startsWith('assets/')) {
        singleFrame = Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: AppColors.videoTrack),
        );
      } else if (File(cleanPath).existsSync()) {
        singleFrame = Image.file(
          File(cleanPath),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: AppColors.videoTrack),
        );
      } else {
        singleFrame = Container(color: AppColors.videoTrack);
      }

      final frameCount = max(1, (width / 44).ceil());

      return ClipRect(
        child: Opacity(
          opacity: 0.55,
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                frameCount,
                (i) => SizedBox(
                  width: 44,
                  height: AppConstants.timelineTrackHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 1),
                    child: singleFrame,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // High-performance video clip filmstrip with 0 hardware decoder overhead
    final frameCount = max(1, (width / 40).ceil());
    return ClipRect(
      child: Container(
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF273147),
              Color(0xFF181F30),
            ],
          ),
        ),
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: max(width, frameCount * 40.0),
          minWidth: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              frameCount,
              (i) => Container(
                width: 40,
                height: AppConstants.timelineTrackHeight,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.movie_filter_outlined,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds adaptive badges with "+N" overflow fallback when zoomed out narrow
  List<Widget> _buildBadgesWithOverflow(double availableSpace) {
    if (availableSpace < 16.0) return const [];

    final List<_BadgeItem> allBadges = [];

    // 1. Speed Badge
    if (clip.speed != 1.0) {
      allBadges.add(
        _BadgeItem(
          estimatedWidth: 26.0,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '${clip.speed}x',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 7.5,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // 2. PIP Overlay Badge
    if (clip.isOverlay) {
      allBadges.add(
        _BadgeItem(
          estimatedWidth: 22.0,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: AppColors.accentRose,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'PIP',
              style: TextStyle(
                fontSize: 6.5,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // 3. Filter Badge
    if (clip.filterType != FilterType.none) {
      allBadges.add(
        _BadgeItem(
          estimatedWidth: 44.0,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              clip.filterType.label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 7,
                color: AppColors.secondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    // 4. Effect Badge
    if (clip.effectType != VideoEffectType.none) {
      allBadges.add(
        _BadgeItem(
          estimatedWidth: 40.0,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF9B51E0).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              clip.effectType.label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 7,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    // 5. Keyframes Marker Badge
    if (clip.keyframes.isNotEmpty) {
      allBadges.add(
        const _BadgeItem(
          estimatedWidth: 14.0,
          widget: Icon(Icons.diamond, size: 9, color: AppColors.accent),
        ),
      );
    }

    // 6. Animation Badge
    if (clip.animationIn != ClipAnimationIn.none ||
        clip.animationOut != ClipAnimationOut.none ||
        clip.animationCombo != ClipAnimationCombo.none) {
      allBadges.add(
        _BadgeItem(
          estimatedWidth: 30.0,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'Anim',
              style: TextStyle(
                fontSize: 6.5,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // 7. Mask Badge
    if (clip.mask != null && clip.mask!.shape != MaskShape.none) {
      allBadges.add(
        _BadgeItem(
          estimatedWidth: 28.0,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'Mask',
              style: TextStyle(
                fontSize: 6.5,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // 8. Chroma Key Badge
    if (clip.chromaKey != null && clip.chromaKey!.isEnabled) {
      allBadges.add(
        _BadgeItem(
          estimatedWidth: 36.0,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'Chroma',
              style: TextStyle(
                fontSize: 6.5,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // 9. Volume / Mute Badge
    if (clip.isMuted || clip.volume != 1.0) {
      allBadges.add(
        _BadgeItem(
          estimatedWidth: clip.isMuted ? 24.0 : 34.0,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: clip.isMuted
                  ? AppColors.error.withValues(alpha: 0.7)
                  : const Color(0xFF00E5FF).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  clip.isMuted ? Icons.volume_off : Icons.volume_up,
                  size: 8,
                  color: Colors.white,
                ),
                if (!clip.isMuted) ...[
                  const SizedBox(width: 1),
                  Text(
                    '${(clip.volume * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 6.5,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (allBadges.isEmpty) return const [];

    final List<Widget> visibleBadges = [];
    double remainingSpace = availableSpace;
    const double overflowIndicatorWidth = 16.0;

    for (int i = 0; i < allBadges.length; i++) {
      final badge = allBadges[i];
      final isLastBadge = (i == allBadges.length - 1);
      final spaceNeeded = badge.estimatedWidth + (isLastBadge ? 0.0 : overflowIndicatorWidth + 2.0);

      if (remainingSpace >= badge.estimatedWidth && (isLastBadge || remainingSpace >= spaceNeeded)) {
        visibleBadges.add(
          Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: badge.widget,
          ),
        );
        remainingSpace -= (badge.estimatedWidth + 2.0);
      } else {
        // Fall back to "+N" overflow indicator for remaining badges if space permits
        if (remainingSpace >= overflowIndicatorWidth) {
          final overflowCount = allBadges.length - i;
          visibleBadges.add(
            Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2.5),
                  border: Border.all(color: Colors.white30, width: 0.5),
                ),
                child: Text(
                  '+$overflowCount',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 7.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }
        break;
      }
    }

    return visibleBadges;
  }
@override
  Widget build(BuildContext context) {
    // Dynamic clip width based on current timeline zoom pixelsPerSecond
    final rawWidth = (clip.effectiveDurationMs / 1000.0) * pixelsPerSecond;
    final minWidth = isSelected ? 56.0 : 18.0;
    final width = max(minWidth, rawWidth);
    final durationStr = TimecodeFormatter.formatMmSsHundredths(clip.effectiveDurationMs);

    final horizontalPadding = isSelected ? min(18.0, width / 4) : 6.0;
    final innerContentWidth = max(0.0, width - (horizontalPadding * 2));
    final availableBadgeSpace = max(0.0, innerContentWidth - 26.0);

    return SizedBox(
      width: width,
      height: AppConstants.timelineTrackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          // 1. Clip Box (Filmstrip, Dark Tint, Text, Duration, Badges)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.white : const Color(0xFF3B4252),
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      const BoxShadow(
                        color: Color(0x6600E5FF),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                      const BoxShadow(
                        color: Color(0x4D5B4DFB),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Filmstrip real media preview background
                _buildFilmstripBackground(width),

                // Dark contrast tint for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // Center Clickable Content Overlay (Title, Speed, Badges, Duration)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  onHorizontalDragUpdate: isSelected && onBodyDragUpdate != null
                      ? (details) => onBodyDragUpdate!(details.delta.dx)
                      : null,
                  onVerticalDragUpdate: isSelected && onVerticalDragUpdate != null
                      ? (details) => onVerticalDragUpdate!(details.delta.dy)
                      : null,
                  onVerticalDragEnd: isSelected && onVerticalDragEnd != null
                      ? (_) => onVerticalDragEnd!()
                      : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 2,
                    ),
                    child: ClipRect(
                      child: SizedBox(
                        width: innerContentWidth,
                        child: innerContentWidth < 18.0
                            ? Center(
                                child: Icon(
                                  clip.isPhoto ? Icons.photo : Icons.videocam,
                                  size: 11,
                                  color: Colors.white70,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Top Row: Media Icon & Clip Name
                                  Row(
                                    children: [
                                      if (innerContentWidth >= 30.0) ...[
                                        Icon(
                                          clip.isPhoto ? Icons.photo : Icons.videocam,
                                          size: 11,
                                          color: AppColors.videoTrack,
                                        ),
                                        const SizedBox(width: 3),
                                      ],
                                      Expanded(
                                        child: Text(
                                          clip.name,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  // Bottom Row: Duration String & Adaptive Overflow Badges
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          durationStr,
                                          style: AppTypography.labelSmall.copyWith(
                                            fontSize: 8.5,
                                            color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (availableBadgeSpace >= 16.0)
                                        ..._buildBadgesWithOverflow(availableBadgeSpace),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Keyframe Diamond Markers placed on timeline clip at exact timestamps
          ...clip.keyframes.map((kf) {
            final kfX = ((kf.timestampMs / 1000.0) * pixelsPerSecond).clamp(4.0, max(4.0, width - 12.0)).toDouble();
            final clipPlayheadOffset = (widget.currentPlayheadMs != null)
                ? (widget.currentPlayheadMs! - clip.timelineStartMs)
                : null;
            final isNearPlayhead = clipPlayheadOffset != null && (clipPlayheadOffset - kf.timestampMs).abs() <= 40;

            return Positioned(
              left: kfX - 8,
              bottom: 0,
              child: GestureDetector(
                key: ValueKey('keyframe-marker-${kf.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (widget.onKeyframeTap != null) {
                    widget.onKeyframeTap!(kf.timestampMs);
                  }
                },
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isNearPlayhead
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Transform.rotate(
                      angle: 0.785398, // 45 degrees
                      child: Container(
                        width: isNearPlayhead ? 9 : 7,
                        height: isNearPlayhead ? 9 : 7,
                        decoration: BoxDecoration(
                          color: isNearPlayhead ? const Color(0xFFFF4757) : AppColors.accent,
                          border: Border.all(
                            color: Colors.white,
                            width: isNearPlayhead ? 1.5 : 0.8,
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          // 3. Selection Trim & Duration Drag Handles (CapCut Style: Left & Right)
          if (isSelected) ...[
            _buildCapCutHandle(isLeft: true, clipWidth: width),
            _buildCapCutHandle(isLeft: false, clipWidth: width),
          ],

          // 4. Floating Live Duration Tooltip while dragging handles
          if (_isDraggingLeft)
            _buildFloatingDurationTooltip(isLeft: true),
          if (_isDraggingRight)
            _buildFloatingDurationTooltip(isLeft: false),
        ],
      ),
    );
  }

  /// CapCut-style dual-side drag handle with ergonomic grip lines
  Widget _buildCapCutHandle({required bool isLeft, required double clipWidth}) {
    final isDragging = isLeft ? _isDraggingLeft : _isDraggingRight;
    final handleW = min(16.0, clipWidth / 3.0);
    final hitW = handleW + 4.0;

    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          setState(() {
            if (isLeft) {
              _isDraggingLeft = true;
            } else {
              _isDraggingRight = true;
            }
          });
          widget.onHandleDragStart?.call();
        },
        onHorizontalDragUpdate: (details) {
          widget.onHandleDragUpdate?.call(details.delta.dx, isLeft);
        },
        onHorizontalDragEnd: (_) {
          setState(() {
            _isDraggingLeft = false;
            _isDraggingRight = false;
          });
          widget.onHandleDragEnd?.call();
        },
        onHorizontalDragCancel: () {
          setState(() {
            _isDraggingLeft = false;
            _isDraggingRight = false;
          });
          widget.onHandleDragEnd?.call();
        },
        child: Container(
          width: hitW,
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: handleW,
            height: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            decoration: BoxDecoration(
              color: isDragging ? const Color(0xFF00E5FF) : Colors.white,
              borderRadius: BorderRadius.horizontal(
                left: isLeft ? const Radius.circular(6) : Radius.zero,
                right: isLeft ? Radius.zero : const Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDragging ? const Color(0x9900E5FF) : const Color(0x40000000),
                  blurRadius: isDragging ? 8 : 4,
                  spreadRadius: isDragging ? 1 : 0,
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 1.5,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDragging ? const Color(0xFF0F172A) : const Color(0xFF475569),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 2.0),
                  Container(
                    width: 1.5,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDragging ? const Color(0xFF0F172A) : const Color(0xFF475569),
                      borderRadius: BorderRadius.circular(1),
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

  /// Live floating duration tooltip displaying exact time while dragging
  Widget _buildFloatingDurationTooltip({required bool isLeft}) {
    final durText = TimecodeFormatter.formatSecondsDetailed(clip.effectiveDurationMs);
    final isPhoto = clip.isPhoto;
    final label = isPhoto ? 'Duration' : (isLeft ? 'Trim In' : 'Trim Out');

    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: -36,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Color(0x4D00E5FF),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPhoto ? Icons.photo_size_select_small : Icons.content_cut,
                    size: 11,
                    color: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$label: $durText',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: isLeft ? 8.0 : 0.0, right: isLeft ? 0.0 : 8.0),
              child: CustomPaint(
                size: const Size(8, 4),
                painter: const _TrianglePainter(color: Color(0xFF00E5FF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
