import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../core/widgets/looma_button.dart';
import '../../../../core/widgets/waveform_painter.dart';
import '../../domain/entities/audio_clip_entity.dart';

class VoiceoverModal extends StatefulWidget {
  final int timelineInsertStartMs;
  final Function(AudioClipEntity newVoiceover) onVoiceoverRecorded;

  const VoiceoverModal({
    super.key,
    required this.timelineInsertStartMs,
    required this.onVoiceoverRecorded,
  });

  @override
  State<VoiceoverModal> createState() => _VoiceoverModalState();
}

class _VoiceoverModalState extends State<VoiceoverModal> {
  bool _isRecording = false;
  int _recordedMs = 0;
  Timer? _timer;
  final List<double> _liveSamples = [];
  final Random _random = Random();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordedMs = 0;
      _liveSamples.clear();
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _recordedMs += 100;
        // Generate realistic voice modulation sample
        final sample = 0.2 + _random.nextDouble() * 0.75;
        _liveSamples.add(sample);
        if (_liveSamples.length > 50) {
          _liveSamples.removeAt(0);
        }
      });
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  void _saveVoiceover() {
    if (_recordedMs < 500) return;

    final voiceover = AudioClipEntity(
      id: IdGenerator.generate(),
      mediaPath: 'local/voiceover_${DateTime.now().millisecondsSinceEpoch}.m4a',
      title: 'Voiceover ${TimecodeFormatter.formatHumanDuration(_recordedMs)}',
      category: AudioCategory.voiceover,
      timelineStartMs: widget.timelineInsertStartMs,
      timelineEndMs: widget.timelineInsertStartMs + _recordedMs,
      trimStartMs: 0,
      trimEndMs: _recordedMs,
      volume: 1.0,
      waveformSamples: List<double>.from(_liveSamples),
    );

    widget.onVoiceoverRecorded(voiceover);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic, color: AppColors.voiceoverTrack, size: 22),
                  const SizedBox(width: 8),
                  Text('Voiceover Studio', style: AppTypography.titleMedium),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Waveform Display
          Container(
            height: 90,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRecording ? AppColors.voiceoverTrack : AppColors.surfaceBorder,
                width: _isRecording ? 1.5 : 1.0,
              ),
            ),
            child: _liveSamples.isEmpty
                ? Center(
                    child: Text(
                      'Tap mic button below to record voiceover',
                      style: AppTypography.bodySmall,
                    ),
                  )
                : CustomPaint(
                    painter: WaveformPainter(
                      samples: _liveSamples,
                      waveColor: AppColors.voiceoverTrack,
                    ),
                    size: Size.infinite,
                  ),
          ),
          const SizedBox(height: 16),

          // Recording Time Readout
          Text(
            TimecodeFormatter.formatMmSsMs(_recordedMs),
            style: AppTypography.displayMedium.copyWith(
              color: _isRecording ? AppColors.voiceoverTrack : AppColors.textPrimary,
              fontFamily: 'SpaceMono',
            ),
          ),
          const SizedBox(height: 20),

          // Record / Stop Control Button
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? AppColors.voiceoverTrack : AppColors.surfaceElevated,
                border: Border.all(color: AppColors.voiceoverTrack, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.voiceoverTrack.withValues(alpha: _isRecording ? 0.5 : 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 32,
                color: _isRecording ? Colors.white : AppColors.voiceoverTrack,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          if (_recordedMs >= 500 && !_isRecording)
            Row(
              children: [
                Expanded(
                  child: LoomaButton(
                    label: 'Retake',
                    type: LoomaButtonType.secondary,
                    icon: Icons.refresh,
                    onPressed: _startRecording,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LoomaButton(
                    label: 'Insert Track',
                    type: LoomaButtonType.primary,
                    icon: Icons.check,
                    onPressed: _saveVoiceover,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
