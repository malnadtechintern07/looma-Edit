import '../../../filters_effects/domain/entities/filter_preset.dart';

class PhotoFrameEntity {
  final String id;
  final String imagePath;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final FilterType filterType;
  final double brightness;
  final double contrast;
  final double saturation;

  const PhotoFrameEntity({
    required this.id,
    required this.imagePath,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.rotation = 0.0,
    this.filterType = FilterType.none,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
  });

  PhotoFrameEntity copyWith({
    String? id,
    String? imagePath,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    FilterType? filterType,
    double? brightness,
    double? contrast,
    double? saturation,
  }) {
    return PhotoFrameEntity(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotation: rotation ?? this.rotation,
      filterType: filterType ?? this.filterType,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'rotation': rotation,
      'filterType': filterType.name,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
    };
  }

  factory PhotoFrameEntity.fromJson(Map<String, dynamic> json) {
    return PhotoFrameEntity(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      filterType: FilterType.values.firstWhere(
        (f) => f.name == json['filterType'],
        orElse: () => FilterType.none,
      ),
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
