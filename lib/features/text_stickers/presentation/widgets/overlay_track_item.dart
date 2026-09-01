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
    final width = (item.effectiveDurationMs / 1000) * pixelsPerSecond;

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragUpdate: onBodyDragUpdate != null
          ? (details) => onBodyDragUpdate!(details.delta.dx)
          : null,
      child: Container(
        width: width < 40 ? 40 : width,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center content label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
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
            if (isSelected && onHandleDragUpdate != null)
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
            if (isSelected && onHandleDragUpdate != null)
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

  const StickerOverlayTrackItem({
    super.key,
    required this.item,
    required this.pixelsPerSecond,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (item.effectiveDurationMs / 1000) * pixelsPerSecond;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width < 40 ? 40 : width,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.stickerTrack.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.stickerTrack,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(item.assetEmojiOrPath, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                item.stickerName,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
