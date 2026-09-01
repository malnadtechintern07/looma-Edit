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

  const AudioTrackItem({
    super.key,
    required this.clip,
    required this.pixelsPerSecond,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (clip.effectiveDurationMs / 1000) * pixelsPerSecond;
    final isVoiceover = clip.category == AudioCategory.voiceover;
    final trackColor = isVoiceover ? AppColors.voiceoverTrack : AppColors.audioTrack;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: trackColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : trackColor.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
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
              left: 6,
              top: 4,
              right: 6,
              child: Row(
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
                  const SizedBox(width: 6),
                  Text(
                    '${(clip.volume * 100).toInt()}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white70,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
