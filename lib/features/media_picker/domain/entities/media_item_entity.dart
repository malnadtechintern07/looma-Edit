enum MediaType { video, photo, audio }

class MediaItemEntity {
  final String path;
  final String name;
  final MediaType type;
  final int durationMs; // For photos, default duration (e.g. 4000ms)
  final String? thumbnailPath;
  final int? fileSizeBytes;
  final DateTime? addedAt;

  const MediaItemEntity({
    required this.path,
    required this.name,
    required this.type,
    this.durationMs = 5000,
    this.thumbnailPath,
    this.fileSizeBytes,
    this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'type': type.name,
    'durationMs': durationMs,
    if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
    if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
    if (addedAt != null) 'addedAt': addedAt!.toIso8601String(),
  };

  factory MediaItemEntity.fromJson(Map<String, dynamic> json) => MediaItemEntity(
    path: json['path'] as String,
    name: json['name'] as String,
    type: MediaType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MediaType.video,
    ),
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 5000,
    thumbnailPath: json['thumbnailPath'] as String?,
    fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
    addedAt: json['addedAt'] != null ? DateTime.tryParse(json['addedAt'] as String) : null,
  );
}

