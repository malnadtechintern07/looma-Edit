import 'package:flutter/foundation.dart';
import '../../../projects/domain/entities/aspect_ratio_type.dart';

@immutable
class StoreTemplateEntity {
  final String id;
  final String title;
  final String description;
  final String author;
  final AspectRatioType aspectRatio;
  final int durationMs;
  final int clipsCount;
  final int downloadsCount;
  final String previewGradientStart;
  final String previewGradientEnd;
  final List<String> tags;
  final String audioTrackTitle;
  final String audioPath;
  final bool isDownloaded;

  const StoreTemplateEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.aspectRatio,
    required this.durationMs,
    required this.clipsCount,
    this.downloadsCount = 1200,
    required this.previewGradientStart,
    required this.previewGradientEnd,
    this.tags = const [],
    this.audioTrackTitle = 'Trending LoFi Beats',
    this.audioPath = 'assets/demo/lofi_beat.mp3',
    this.isDownloaded = false,
  });

  StoreTemplateEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? author,
    AspectRatioType? aspectRatio,
    int? durationMs,
    int? clipsCount,
    int? downloadsCount,
    String? previewGradientStart,
    String? previewGradientEnd,
    List<String>? tags,
    String? audioTrackTitle,
    String? audioPath,
    bool? isDownloaded,
  }) {
    return StoreTemplateEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      durationMs: durationMs ?? this.durationMs,
      clipsCount: clipsCount ?? this.clipsCount,
      downloadsCount: downloadsCount ?? this.downloadsCount,
      previewGradientStart: previewGradientStart ?? this.previewGradientStart,
      previewGradientEnd: previewGradientEnd ?? this.previewGradientEnd,
      tags: tags ?? this.tags,
      audioTrackTitle: audioTrackTitle ?? this.audioTrackTitle,
      audioPath: audioPath ?? this.audioPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
