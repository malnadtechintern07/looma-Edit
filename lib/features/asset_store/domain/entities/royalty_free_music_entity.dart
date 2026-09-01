import 'package:flutter/foundation.dart';

@immutable
class RoyaltyFreeMusicEntity {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final int durationMs;
  final int bpm;
  final String mood;
  final String audioUrl;
  final List<double> waveformSamples;
  final bool isDownloaded;

  const RoyaltyFreeMusicEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.durationMs,
    required this.bpm,
    required this.mood,
    required this.audioUrl,
    required this.waveformSamples,
    this.isDownloaded = false,
  });

  RoyaltyFreeMusicEntity copyWith({
    String? id,
    String? title,
    String? artist,
    String? genre,
    int? durationMs,
    int? bpm,
    String? mood,
    String? audioUrl,
    List<double>? waveformSamples,
    bool? isDownloaded,
  }) {
    return RoyaltyFreeMusicEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      durationMs: durationMs ?? this.durationMs,
      bpm: bpm ?? this.bpm,
      mood: mood ?? this.mood,
      audioUrl: audioUrl ?? this.audioUrl,
      waveformSamples: waveformSamples ?? this.waveformSamples,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
