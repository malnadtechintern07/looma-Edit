class PhotoTextOverlayEntity {
  final String id;
  final String text;
  final String fontFamily;
  final double fontSize;
  final int colorHex;
  final String presetStyle;
  final double positionX;
  final double positionY;
  final double scale;
  final double rotation;

  const PhotoTextOverlayEntity({
    required this.id,
    required this.text,
    this.fontFamily = 'Roboto',
    this.fontSize = 28.0,
    this.colorHex = 0xFFFFFFFF,
    this.presetStyle = 'Neon',
    this.positionX = 40.0,
    this.positionY = 100.0,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  PhotoTextOverlayEntity copyWith({
    String? id,
    String? text,
    String? fontFamily,
    double? fontSize,
    int? colorHex,
    String? presetStyle,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
  }) {
    return PhotoTextOverlayEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      colorHex: colorHex ?? this.colorHex,
      presetStyle: presetStyle ?? this.presetStyle,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'colorHex': colorHex,
      'presetStyle': presetStyle,
      'positionX': positionX,
      'positionY': positionY,
      'scale': scale,
      'rotation': rotation,
    };
  }

  factory PhotoTextOverlayEntity.fromJson(Map<String, dynamic> json) {
    return PhotoTextOverlayEntity(
      id: json['id'] as String,
      text: json['text'] as String,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 28.0,
      colorHex: json['colorHex'] as int? ?? 0xFFFFFFFF,
      presetStyle: json['presetStyle'] as String? ?? 'Neon',
      positionX: (json['positionX'] as num?)?.toDouble() ?? 40.0,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 100.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
