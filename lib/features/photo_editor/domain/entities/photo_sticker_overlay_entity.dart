class PhotoStickerOverlayEntity {
  final String id;
  final String assetPath;
  final double positionX;
  final double positionY;
  final double scale;
  final double rotation;
  final bool isShape;
  final String? shapeType;
  final int colorHex;
  final double opacity;

  const PhotoStickerOverlayEntity({
    required this.id,
    required this.assetPath,
    this.positionX = 100.0,
    this.positionY = 120.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isShape = false,
    this.shapeType,
    this.colorHex = 0xFFFFFFFF,
    this.opacity = 1.0,
  });

  PhotoStickerOverlayEntity copyWith({
    String? id,
    String? assetPath,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    bool? isShape,
    String? shapeType,
    int? colorHex,
    double? opacity,
  }) {
    return PhotoStickerOverlayEntity(
      id: id ?? this.id,
      assetPath: assetPath ?? this.assetPath,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isShape: isShape ?? this.isShape,
      shapeType: shapeType ?? this.shapeType,
      colorHex: colorHex ?? this.colorHex,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetPath': assetPath,
      'positionX': positionX,
      'positionY': positionY,
      'scale': scale,
      'rotation': rotation,
      'isShape': isShape,
      'shapeType': shapeType,
      'colorHex': colorHex,
      'opacity': opacity,
    };
  }

  factory PhotoStickerOverlayEntity.fromJson(Map<String, dynamic> json) {
    return PhotoStickerOverlayEntity(
      id: json['id'] as String,
      assetPath: json['assetPath'] as String,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 100.0,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 120.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      isShape: json['isShape'] as bool? ?? false,
      shapeType: json['shapeType'] as String?,
      colorHex: json['colorHex'] as int? ?? 0xFFFFFFFF,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
