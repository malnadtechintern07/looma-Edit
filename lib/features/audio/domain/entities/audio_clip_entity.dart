import 'package:flutter/foundation.dart';

enum AudioCategory { music, voiceover, soundEffect, extracted }

@immutable
class AudioClipEntity {
  final String id;
  final String mediaPath;
  final String title;
  final AudioCategory category;
  final int timelineStartMs;
  final int timelineEndMs;
  final int trimStartMs;
  final int trimEndMs;
  final double volume; // 0.0 to 2.0
  final bool isMuted;
  final int fadeInMs;
  final int fadeOutMs;
  final List<double> waveformSamples;

  const AudioClipEntity({
    required this.id,
    required this.mediaPath,
    required this.title,
    required this.category,
    required this.timelineStartMs,
    required this.timelineEndMs,
    this.trimStartMs = 0,
    required this.trimEndMs,
    this.volume = 1.0,
    this.isMuted = false,
    this.fadeInMs = 0,
    this.fadeOutMs = 0,
    this.waveformSamples = const [],
  });

  int get effectiveDurationMs => timelineEndMs - timelineStartMs;

  AudioClipEntity copyWith({
    String? id,
    String? mediaPath,
    String? title,
    AudioCategory? category,
    int? timelineStartMs,
    int? timelineEndMs,
    int? trimStartMs,
    int? trimEndMs,
    double? volume,
    bool? isMuted,
    int? fadeInMs,
    int? fadeOutMs,
    List<double>? waveformSamples,
  }) {
    return AudioClipEntity(
      id: id ?? this.id,
      mediaPath: mediaPath ?? this.mediaPath,
      title: title ?? this.title,
      category: category ?? this.category,
      timelineStartMs: timelineStartMs ?? this.timelineStartMs,
      timelineEndMs: timelineEndMs ?? this.timelineEndMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      fadeInMs: fadeInMs ?? this.fadeInMs,
      fadeOutMs: fadeOutMs ?? this.fadeOutMs,
      waveformSamples: waveformSamples ?? this.waveformSamples,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioClipEntity &&
          id == other.id &&
          timelineStartMs == other.timelineStartMs &&
          timelineEndMs == other.timelineEndMs &&
          volume == other.volume &&
          isMuted == other.isMuted;

  @override
  int get hashCode => Object.hash(id, timelineStartMs, timelineEndMs, volume, isMuted);
}
