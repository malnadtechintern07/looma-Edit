import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/sticker_overlay_entity.dart';
import '../../domain/entities/text_overlay_entity.dart';

class TextOverlayTrackItem extends StatelessWidget {
  final TextOverlayEntity item;
  final double pixelsPerSecond;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double deltaPixels, bool isLeftHandle)? onHandleDragUpdate;
  final Function(double deltaPixels)? onBodyDragUpdate;

  const TextOverlayTrackItem({
    super.key,
    required this.item,
    required this.pixelsPerSecond,
    required this.isSelected,
    required this.onTap,
    this.onHandleDragUpdate,
    this.onBodyDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final rawWidth = (item.effectiveDurationMs / 1000) * pixelsPerSecond;
    final minWidth = isSelected ? 52.0 : 24.0;
    final width = max(minWidth, rawWidth);

    final horizontalPadding = isSelected ? 14.0 : 6.0;
    final innerContentWidth = max(0.0, width - (horizontalPadding * 2));

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragUpdate: onBodyDragUpdate != null
          ? (details) => onBodyDragUpdate!(details.delta.dx)
          : null,
      child: Container(
        width: width,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textTrack.withValues(alpha: 0.35)
              : AppColors.textTrack.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.textTrack,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.textTrack.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center content label
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: innerContentWidth < 28.0
                  ? const Center(
                      child: Icon(Icons.title, size: 12, color: AppColors.textTrack),
                    )
                  : Row(
                      children: [
                        const Icon(Icons.title, size: 12, color: AppColors.textTrack),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.text,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),

            // Left Duration Trim / Extend Handle
            if (isSelected && onHandleDragUpdate != null && width >= 40.0)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    onHandleDragUpdate!(details.delta.dx, true);
                  },
                  child: Container(
                    width: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.chevron_left, size: 10, color: Colors.black),
                    ),
                  ),
                ),
              ),

            // Right Duration Trim / Extend Handle
            if (isSelected && onHandleDragUpdate != null && width >= 40.0)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    onHandleDragUpdate!(details.delta.dx, false);
                  },
                  child: Container(
                    width: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.chevron_right, size: 10, color: Colors.black),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StickerOverlayTrackItem extends StatelessWidget {
  final StickerOverlayEntity item;
  final double pixelsPerSecond;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double deltaPixels, bool isLeftHandle)? onHandleDragUpdate;
  final Function(double deltaPixels)? onBodyDragUpdate;

  const StickerOverlayTrackItem({
    super.key,
    required this.item,
    required this.pixelsPerSecond,
    required this.isSelected,
    required this.onTap,
    this.onHandleDragUpdate,
    this.onBodyDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final rawWidth = (item.effectiveDurationMs / 1000) * pixelsPerSecond;
    final minWidth = isSelected ? 52.0 : 24.0;
    final width = max(minWidth, rawWidth);

    final horizontalPadding = isSelected ? 14.0 : 6.0;
    final innerContentWidth = max(0.0, width - (horizontalPadding * 2));

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragUpdate: onBodyDragUpdate != null
          ? (details) => onBodyDragUpdate!(details.delta.dx)
          : null,
      child: Container(
        width: width,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.stickerTrack.withValues(alpha: 0.35)
              : AppColors.stickerTrack.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.stickerTrack,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.stickerTrack.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: innerContentWidth < 28.0
                  ? Center(
                      child: Text(item.assetEmojiOrPath, style: const TextStyle(fontSize: 12)),
                    )
                  : Row(
                      children: [
                        Text(item.assetEmojiOrPath, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.stickerName,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),

            if (isSelected && onHandleDragUpdate != null && width >= 40.0) ...[
              // Left Handle
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    onHandleDragUpdate!(details.delta.dx, true);
                  },
                  child: Container(
                    width: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.stickerTrack,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_left, size: 10, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // Right Handle
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    onHandleDragUpdate!(details.delta.dx, false);
                  },
                  child: Container(
                    width: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.stickerTrack,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_right, size: 10, color: Colors.white),
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
