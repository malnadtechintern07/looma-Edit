import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../entities/audio_clip_entity.dart';

class AudioPlaybackService {
  final Map<String, AudioPlayer> _players = {};

  Future<void> syncAudioPlayback({
    required List<AudioClipEntity> audioClips,
    required int currentPlayheadMs,
    required bool isPlaying,
  }) async {
    for (final clip in audioClips) {
      final player = _players.putIfAbsent(clip.id, () => AudioPlayer());

      final isInRange = currentPlayheadMs >= clip.timelineStartMs &&
          currentPlayheadMs <= clip.timelineEndMs;

      if (!isInRange || !isPlaying || clip.isMuted) {
        if (player.state == PlayerState.playing) {
          await player.pause();
        }
        continue;
      }

      final offsetInClip = currentPlayheadMs - clip.timelineStartMs;
      final remainingInClip = clip.effectiveDurationMs - offsetInClip;

      double fadeMultiplier = 1.0;
      if (clip.fadeInMs > 0 && offsetInClip < clip.fadeInMs) {
        fadeMultiplier *= (offsetInClip / clip.fadeInMs).clamp(0.0, 1.0);
      }
      if (clip.fadeOutMs > 0 && remainingInClip < clip.fadeOutMs) {
        fadeMultiplier *= (remainingInClip / clip.fadeOutMs).clamp(0.0, 1.0);
      }

      final effectiveVolume = (clip.volume * fadeMultiplier).clamp(0.0, 2.0);
      await player.setVolume(effectiveVolume);

      final clipOffsetMs = offsetInClip + clip.trimStartMs;
      final targetPosition = Duration(milliseconds: clipOffsetMs);

      if (player.state != PlayerState.playing) {
        final path = clip.mediaPath;
        Source source;

        if (path.startsWith('assets/')) {
          source = AssetSource(path.replaceFirst('assets/', ''));
        } else if (File(path).existsSync()) {
          source = DeviceFileSource(path);
        } else {
          continue;
        }

        try {
          await player.play(source, position: targetPosition);
        } catch (e) {
          debugPrint('AudioPlaybackService play error: $e');
        }
      }
    }
  }

  Future<void> updateVolume(String clipId, double volume) async {
    final player = _players[clipId];
    if (player != null) {
      await player.setVolume(volume.clamp(0.0, 2.0));
    }
  }

  Future<void> stopAll() async {
    for (final player in _players.values) {
      await player.stop();
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
