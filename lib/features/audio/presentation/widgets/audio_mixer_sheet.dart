import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../core/widgets/looma_slider.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../domain/entities/audio_clip_entity.dart';
import '../../domain/services/audio_extraction_service.dart';

class AudioMixerSheet extends StatefulWidget {
  final List<AudioClipEntity> audioClips;
  final Function(AudioClipEntity newAudio) onAddAudioTrack;
  final Function(AudioClipEntity updatedAudio) onUpdateAudioTrack;
  final Function(String clipId) onDeleteAudioTrack;
  final VoidCallback onAddVoiceover;

  const AudioMixerSheet({
    super.key,
    required this.audioClips,
    required this.onAddAudioTrack,
    required this.onUpdateAudioTrack,
    required this.onDeleteAudioTrack,
    required this.onAddVoiceover,
  });

  @override
  State<AudioMixerSheet> createState() => _AudioMixerSheetState();
}

class _AudioMixerSheetState extends State<AudioMixerSheet> {
  final DeviceMediaService _mediaService = DeviceMediaService();
  bool _isLoading = false;

  // Choice 1: Select from Local Device Audio
  Future<void> _selectFromLocal() async {
    setState(() => _isLoading = true);
    try {
      final audios = await _mediaService.pickAudioFromDevice();
      if (audios.isNotEmpty) {
        final audioItem = audios.first;
        final newAudio = AudioClipEntity(
          id: IdGenerator.generate(),
          mediaPath: audioItem.path,
          title: audioItem.name,
          category: AudioCategory.music,
          timelineStartMs: 0,
          timelineEndMs: audioItem.durationMs,
          trimStartMs: 0,
          trimEndMs: audioItem.durationMs,
          volume: 1.0,
          isMuted: false,
        );

        widget.onAddAudioTrack(newAudio);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported local audio "${audioItem.name}"!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load audio file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Choice 2: Extract from Video
  Future<void> _extractFromVideo() async {
    setState(() => _isLoading = true);
    try {
      final videos = await _mediaService.pickVideosFromDevice();
      if (videos.isNotEmpty) {
        final video = videos.first;

        final extractedAudio = await AudioExtractionService.extractAudioFromVideo(
          videoPath: video.path,
          videoTitle: video.name,
          timelineStartMs: 0,
          durationMs: video.durationMs > 0 ? video.durationMs : 10000,
        );

        widget.onAddAudioTrack(extractedAudio);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Extracted original audio from "${video.name}"!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video audio extraction error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.audioTrack.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: AppColors.audioTrack, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Audio Studio & Mix Controls', style: AppTypography.titleMedium),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // TWO WORKING CHOICES: 1. Select from Local | 2. Extract from Video
          Row(
            children: [
              Expanded(
                child: _buildChoiceCard(
                  icon: Icons.folder_open,
                  title: 'Select from Local',
                  subtitle: 'Pick MP3/WAV/M4A',
                  color: AppColors.primary,
                  onTap: _selectFromLocal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceCard(
                  icon: Icons.movie_filter,
                  title: 'Extract from Video',
                  subtitle: 'Original video audio',
                  color: AppColors.secondary,
                  onTap: _extractFromVideo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Audio Tracks List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline Audio Tracks (${widget.audioClips.length})',
                style: AppTypography.titleSmall,
              ),
              TextButton.icon(
                icon: const Icon(Icons.mic, size: 14, color: AppColors.voiceoverTrack),
                label: const Text('Record Voiceover', style: TextStyle(fontSize: 11, color: AppColors.voiceoverTrack)),
                onPressed: widget.onAddVoiceover,
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : widget.audioClips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_off, size: 36, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            Text('No audio tracks added yet', style: AppTypography.bodySmall),
                            Text(
                              'Tap "Select from Local" or "Extract from Video" above',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.audioClips.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final audio = widget.audioClips[index];
                          return _buildTrackControlCard(audio);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackControlCard(AudioClipEntity audio) {
    final isVoice = audio.category == AudioCategory.voiceover;
    final isExtracted = audio.category == AudioCategory.extracted;
    final trackColor = isVoice
        ? AppColors.voiceoverTrack
        : (isExtracted ? AppColors.secondary : AppColors.audioTrack);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track Header with Mute & Delete Actions
          Row(
            children: [
              Icon(
                isVoice
                    ? Icons.mic
                    : (isExtracted ? Icons.movie_filter : Icons.music_note),
                size: 18,
                color: trackColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.title,
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${isExtracted ? "Video Audio" : (isVoice ? "Voiceover" : "Local Audio")} • ${TimecodeFormatter.formatMmSsMs(audio.effectiveDurationMs)}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Mute Toggle Switch
              IconButton(
                icon: Icon(
                  audio.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: audio.isMuted ? AppColors.error : AppColors.success,
                  size: 20,
                ),
                tooltip: audio.isMuted ? 'Unmute' : 'Mute',
                onPressed: () {
                  widget.onUpdateAudioTrack(
                    audio.copyWith(isMuted: !audio.isMuted),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                tooltip: 'Delete Track',
                onPressed: () => widget.onDeleteAudioTrack(audio.id),
              ),
            ],
          ),
          const Divider(height: 16),

          // 1. Volume Gain Slider (0% to 200%)
          LoomaSlider(
            label: 'Track Volume',
            value: audio.volume,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            valueFormatter: (v) => audio.isMuted ? 'MUTED' : '${(v * 100).toInt()}%',
            onChanged: (v) {
              widget.onUpdateAudioTrack(
                audio.copyWith(volume: v, isMuted: false),
              );
            },
          ),
          const SizedBox(height: 10),

          // 2. Fade In & Fade Out Sliders
          Row(
            children: [
              Expanded(
                child: LoomaSlider(
                  label: 'Fade In',
                  value: (audio.fadeInMs / 1000).toDouble(),
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  valueFormatter: (v) => '${v.toStringAsFixed(1)}s',
                  onChanged: (v) {
                    widget.onUpdateAudioTrack(
                      audio.copyWith(fadeInMs: (v * 1000).toInt()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoomaSlider(
                  label: 'Fade Out',
                  value: (audio.fadeOutMs / 1000).toDouble(),
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  valueFormatter: (v) => '${v.toStringAsFixed(1)}s',
                  onChanged: (v) {
                    widget.onUpdateAudioTrack(
                      audio.copyWith(fadeOutMs: (v * 1000).toInt()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
