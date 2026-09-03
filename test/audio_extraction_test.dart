import 'package:flutter_test/flutter_test.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/audio/domain/services/audio_extraction_service.dart';

void main() {
  group('Audio Extraction & Waveform Tests', () {
    test('generateWaveformSamples creates specified sample count within bounds', () {
      final samples = AudioExtractionService.generateWaveformSamples(seed: 12345, count: 50);

      expect(samples.length, 50);
      for (final sample in samples) {
        expect(sample, greaterThanOrEqualTo(0.1));
        expect(sample, lessThanOrEqualTo(1.0));
      }
    });

    test('extractAudioFromVideo returns valid AudioClipEntity with waveform', () async {
      final audioClip = await AudioExtractionService.extractAudioFromVideo(
        videoPath: 'assets/demo/video.mp4',
        videoTitle: 'Test Video',
        timelineStartMs: 2000,
        durationMs: 8000,
      );

      expect(audioClip.title, contains('Test Video'));
      expect(audioClip.category, AudioCategory.extracted);
      expect(audioClip.timelineStartMs, 2000);
      expect(audioClip.timelineEndMs, 10000);
      expect(audioClip.waveformSamples.isNotEmpty, true);
    });
  });
}
