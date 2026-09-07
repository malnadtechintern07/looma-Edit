import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/effect_clip_entity.dart';

class EffectTrackItem extends StatelessWidget {
  final EffectClipEntity item;
  final double pixelsPerSecond;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double deltaPixels, bool isLeftHandle)? onHandleDragUpdate;
  final Function(double deltaPixels)? onSlideDragUpdate;

  const EffectTrackItem({
    super.key,
    required this.item,
    required this.pixelsPerSecond,
    required this.isSelected,
    required this.onTap,
    this.onHandleDragUpdate,
    this.onSlideDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final width = max(36.0, (item.durationMs / 1000.0) * pixelsPerSecond);
    const height = 32.0;
    final effect = item.effectType;

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragUpdate: isSelected && onSlideDragUpdate != null
          ? (details) => onSlideDragUpdate!(details.delta.dx)
          : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effect.color1.withValues(alpha: 0.85),
              effect.color2.withValues(alpha: 0.85),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
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
            // Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 6),
              child: Row(
                children: [
                  Icon(effect.icon, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  if (width > 60)
                    Expanded(
                      child: Text(
                        effect.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (width > 90) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${(item.durationMs / 1000).toStringAsFixed(1)}s',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Left Drag Handle
            if (isSelected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    onHandleDragUpdate?.call(details.delta.dx, true);
                  },
                  child: Container(
                    width: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.chevron_left, size: 10, color: Colors.black),
                    ),
                  ),
                ),
              ),

            // Right Drag Handle
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    onHandleDragUpdate?.call(details.delta.dx, false);
                  },
                  child: Container(
                    width: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF),
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
