import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/subtitle_entity.dart';

class SubtitleTrackItem extends StatelessWidget {
  final SubtitleEntity item;
  final double pixelsPerSecond;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double deltaPixels, bool isLeftHandle)? onHandleDragUpdate;
  final Function(double deltaPixels)? onBodyDragUpdate;

  const SubtitleTrackItem({
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
    final rawWidth = (item.durationMs / 1000) * pixelsPerSecond;
    final minWidth = isSelected ? 52.0 : 24.0;
    final width = max(minWidth, rawWidth);

    final horizontalPadding = isSelected ? 14.0 : 6.0;
    final innerContentWidth = max(0.0, width - (horizontalPadding * 2));

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragUpdate: isSelected && onBodyDragUpdate != null
          ? (details) => onBodyDragUpdate!(details.delta.dx)
          : null,
      child: Container(
        width: width,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF9F43).withValues(alpha: 0.35)
              : const Color(0xFFFF9F43).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFFFF9F43),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF9F43).withValues(alpha: 0.4),
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
                  ? const Center(
                      child: Icon(Icons.subtitles, size: 12, color: Color(0xFFFF9F43)),
                    )
                  : Row(
                      children: [
                        const Icon(Icons.subtitles, size: 12, color: Color(0xFFFF9F43)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.text,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9.5,
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
                      color: Color(0xFFFF9F43),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_left, size: 12, color: Colors.white),
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
                      color: Color(0xFFFF9F43),
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_right, size: 12, color: Colors.white),
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
