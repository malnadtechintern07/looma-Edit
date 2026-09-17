import 'package:flutter/foundation.dart';
import '../../../projects/domain/entities/aspect_ratio_type.dart';

@immutable
class StoreTemplateEntity {
  final String id;
  final String title;
  final String category;
  final String? badge;
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
  final String? previewVideoUrl;
  final String? previewImageUrl;
  final String? projectJson;
  final String? prompt;
  final bool isPro;
  final bool isTrending;
  final bool isNew;
  final bool isPopular;
  final bool isDownloaded;

  const StoreTemplateEntity({
    required this.id,
    required this.title,
    this.category = 'Trending',
    this.badge,
    required this.description,
    this.prompt,
    required this.author,
    required this.aspectRatio,
    required this.durationMs,
    required this.clipsCount,
    this.downloadsCount = 1200,
    required this.previewGradientStart,
    required this.previewGradientEnd,
    this.previewVideoUrl,
    this.previewImageUrl,
    this.projectJson,
    this.isPro = false,
    this.isTrending = false,
    this.isNew = false,
    this.isPopular = false,
    this.tags = const [],
    this.audioTrackTitle = 'Trending LoFi Beats',
    this.audioPath = 'assets/demo/lofi_beat.wav',
    this.isDownloaded = false,
  });

  StoreTemplateEntity copyWith({
    String? id,
    String? title,
    String? category,
    String? badge,
    String? description,
    String? prompt,
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
    String? previewVideoUrl,
    String? previewImageUrl,
    String? projectJson,
    bool? isPro,
    bool? isTrending,
    bool? isNew,
    bool? isPopular,
    bool? isDownloaded,
  }) {
    return StoreTemplateEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      badge: badge ?? this.badge,
      description: description ?? this.description,
      prompt: prompt ?? this.prompt,
      author: author ?? this.author,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      durationMs: durationMs ?? this.durationMs,
      clipsCount: clipsCount ?? this.clipsCount,
      downloadsCount: downloadsCount ?? this.downloadsCount,
      previewGradientStart: previewGradientStart ?? this.previewGradientStart,
      previewGradientEnd: previewGradientEnd ?? this.previewGradientEnd,
      previewVideoUrl: previewVideoUrl ?? this.previewVideoUrl,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      projectJson: projectJson ?? this.projectJson,
      isPro: isPro ?? this.isPro,
      isTrending: isTrending ?? this.isTrending,
      isNew: isNew ?? this.isNew,
      isPopular: isPopular ?? this.isPopular,
      tags: tags ?? this.tags,
      audioTrackTitle: audioTrackTitle ?? this.audioTrackTitle,
      audioPath: audioPath ?? this.audioPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
