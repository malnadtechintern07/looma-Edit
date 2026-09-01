import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../core/widgets/looma_button.dart';
import '../../../../core/widgets/waveform_painter.dart';
import '../../domain/entities/royalty_free_music_entity.dart';

class MusicPreviewTile extends StatefulWidget {
  final RoyaltyFreeMusicEntity music;
  final VoidCallback onAddToProject;

  const MusicPreviewTile({
    super.key,
    required this.music,
    required this.onAddToProject,
  });

  @override
  State<MusicPreviewTile> createState() => _MusicPreviewTileState();
}

class _MusicPreviewTileState extends State<MusicPreviewTile> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final music = widget.music;
    final durationStr = TimecodeFormatter.formatHumanDuration(music.durationMs);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: () => setState(() => _isPlaying = !_isPlaying),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isPlaying ? AppColors.primary : AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isPlaying ? AppColors.primaryLight : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 20,
                    color: _isPlaying ? Colors.white : AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      music.title,
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${music.artist} • ${music.genre} • ${music.bpm} BPM',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),

              Text(durationStr, style: AppTypography.labelSmall),
              const SizedBox(width: 12),

              LoomaButton(
                label: 'Add',
                icon: Icons.add,
                height: 32,
                type: LoomaButtonType.secondary,
                onPressed: widget.onAddToProject,
              ),
            ],
          ),

          // Waveform Graphic
          if (_isPlaying) ...[
            const SizedBox(height: 12),
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CustomPaint(
                painter: WaveformPainter(
                  samples: music.waveformSamples,
                  waveColor: AppColors.audioTrack,
                  progress: 0.45,
                ),
                size: Size.infinite,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
