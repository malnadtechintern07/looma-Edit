import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/waveform_painter.dart';
import '../../domain/entities/audio_clip_entity.dart';

class AudioTrackItem extends StatelessWidget {
  final AudioClipEntity clip;
  final double pixelsPerSecond;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double deltaPixels, bool isLeftHandle)? onHandleDragUpdate;
  final Function(double deltaPixels)? onBodyDragUpdate;

  const AudioTrackItem({
    super.key,
    required this.clip,
    required this.pixelsPerSecond,
    required this.isSelected,
    required this.onTap,
    this.onHandleDragUpdate,
    this.onBodyDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final rawWidth = (clip.effectiveDurationMs / 1000) * pixelsPerSecond;
    final minWidth = isSelected ? 52.0 : 24.0;
    final width = max(minWidth, rawWidth);
    final isVoiceover = clip.category == AudioCategory.voiceover;
    final trackColor = isVoiceover ? AppColors.voiceoverTrack : AppColors.audioTrack;

    final horizontalPadding = isSelected ? 16.0 : 6.0;
    final innerContentWidth = max(0.0, width - (horizontalPadding * 2));

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragUpdate: onBodyDragUpdate != null
          ? (details) => onBodyDragUpdate!(details.delta.dx)
          : null,
      child: Container(
        width: width,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: trackColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : trackColor.withValues(alpha: 0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: trackColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Waveform Graphic
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: CustomPaint(
                  painter: WaveformPainter(
                    samples: clip.waveformSamples.isNotEmpty
                        ? clip.waveformSamples
                        : [0.3, 0.6, 0.8, 0.4, 0.7, 0.9, 0.5, 0.8, 0.6, 0.3],
                    waveColor: trackColor,
                  ),
                ),
              ),
            ),

            // Track info
            Positioned(
              left: horizontalPadding,
              top: 4,
              right: horizontalPadding,
              child: innerContentWidth < 30.0
                  ? Center(
                      child: Icon(
                        isVoiceover ? Icons.mic : Icons.music_note,
                        size: 12,
                        color: trackColor,
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          isVoiceover ? Icons.mic : Icons.music_note,
                          size: 12,
                          color: trackColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            clip.title,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (innerContentWidth >= 60.0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${(clip.volume * 100).toInt()}%',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),

            // Selection Trim Handles
            if (isSelected && onHandleDragUpdate != null && width >= 40.0) ...[
              // Left Trim Handle (◀)
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
                    width: 14,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_left, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // Right Trim Handle (▶)
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
                    width: 14,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
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
