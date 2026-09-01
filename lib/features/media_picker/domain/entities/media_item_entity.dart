enum MediaType { video, photo, audio }

class MediaItemEntity {
  final String path;
  final String name;
  final MediaType type;
  final int durationMs; // For photos, default duration (e.g. 4000ms)
  final String? thumbnailPath;
  final int? fileSizeBytes;

  const MediaItemEntity({
    required this.path,
    required this.name,
    required this.type,
    this.durationMs = 5000,
    this.thumbnailPath,
    this.fileSizeBytes,
  });
}
