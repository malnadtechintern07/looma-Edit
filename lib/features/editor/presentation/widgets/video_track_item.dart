import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../domain/entities/video_clip_entity.dart';

class VideoTrackItem extends StatelessWidget {
  final VideoClipEntity clip;
  final double pixelsPerSecond;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double deltaPixels, bool isLeftHandle)? onHandleDragUpdate;

  const VideoTrackItem({
    super.key,
    required this.clip,
    required this.pixelsPerSecond,
    required this.isSelected,
    required this.onTap,
    this.onHandleDragUpdate,
  });

  Widget _buildFilmstripBackground(double width) {
    Widget singleFrame;
    final path = clip.mediaPath;

    if (path.startsWith('assets/')) {
      singleFrame = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: AppColors.videoTrack),
      );
    } else if (File(path).existsSync()) {
      singleFrame = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: AppColors.videoTrack),
      );
    } else {
      singleFrame = Container(color: AppColors.videoTrack);
    }

    final frameCount = max(1, (width / 44).ceil());

    return ClipRect(
      child: Opacity(
        opacity: 0.5,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: frameCount,
          itemBuilder: (context, i) {
            return SizedBox(
              width: 44,
              height: AppConstants.timelineTrackHeight,
              child: Padding(
                padding: const EdgeInsets.only(right: 1),
                child: singleFrame,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = max(44.0, (clip.effectiveDurationMs / 1000) * pixelsPerSecond);
    final durationStr = TimecodeFormatter.formatMmSsMs(clip.effectiveDurationMs);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: AppConstants.timelineTrackHeight,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Filmstrip real media preview background
            Positioned.fill(
              child: _buildFilmstripBackground(width),
            ),

            // 2. Dark contrast tint for text readability
            Positioned.fill(
              child: Container(
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
            ),

            // 3. Content Overlay (Title, Speed, Duration) - Overflow-safe
            Positioned.fill(
              child: ClipRect(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isSelected ? 20 : 6,
                    right: isSelected ? 20 : 6,
                    top: 2,
                    bottom: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          Icon(
                            clip.mediaPath.endsWith('.jpg') || clip.mediaPath.endsWith('.png')
                                ? Icons.photo
                                : Icons.videocam,
                            size: 11,
                            color: AppColors.videoTrack,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              clip.name,
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (clip.speed != 1.0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${clip.speed}x',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 8,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            durationStr,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 8,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (clip.filterType != FilterType.none)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(3),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Selection Trim & Extend Handles
            if (isSelected) ...[
              // Left Crop Trim Handle
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    onHandleDragUpdate?.call(details.delta.dx, true);
                  },
                  child: Container(
                    width: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_left, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Right Extend & Crop Handle (Drag right to extend duration)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    onHandleDragUpdate?.call(details.delta.dx, false);
                  },
                  child: Container(
                    width: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_right, size: 14, color: Colors.white),
                    ),
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
