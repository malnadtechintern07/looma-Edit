enum WatermarkPosition {
  topLeft('Top Left'),
  topRight('Top Right'),
  bottomLeft('Bottom Left'),
  bottomRight('Bottom Right'),
  center('Center');

  final String label;
  const WatermarkPosition(this.label);
}

class WatermarkEntity {
  final bool isEnabled;
  final String text;
  final String? imagePath;
  final WatermarkPosition position;
  final double scale;
  final double opacity;
  final int colorHex;
  final String fontFamily;

  const WatermarkEntity({
    this.isEnabled = false,
    this.text = 'PROCUT',
    this.imagePath,
    this.position = WatermarkPosition.bottomRight,
    this.scale = 1.0,
    this.opacity = 0.75,
    this.colorHex = 0xFFFFFFFF,
    this.fontFamily = 'Roboto',
  });

  WatermarkEntity copyWith({
    bool? isEnabled,
    String? text,
    String? imagePath,
    WatermarkPosition? position,
    double? scale,
    double? opacity,
    int? colorHex,
    String? fontFamily,
  }) {
    return WatermarkEntity(
      isEnabled: isEnabled ?? this.isEnabled,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      colorHex: colorHex ?? this.colorHex,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'text': text,
      'imagePath': imagePath,
      'position': position.name,
      'scale': scale,
      'opacity': opacity,
      'colorHex': colorHex,
      'fontFamily': fontFamily,
    };
  }

  factory WatermarkEntity.fromJson(Map<String, dynamic> json) {
    return WatermarkEntity(
      isEnabled: json['isEnabled'] as bool? ?? false,
      text: json['text'] as String? ?? 'PROCUT',
      imagePath: json['imagePath'] as String?,
      position: WatermarkPosition.values.firstWhere(
        (p) => p.name == json['position'],
        orElse: () => WatermarkPosition.bottomRight,
      ),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.75,
      colorHex: json['colorHex'] as int? ?? 0xFFFFFFFF,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
    );
  }
}
