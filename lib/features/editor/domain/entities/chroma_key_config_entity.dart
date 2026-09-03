import 'package:flutter/foundation.dart';

@immutable
class ChromaKeyConfigEntity {
  final bool isEnabled;
  final int keyColorHex; // Usually 0xFF00FF00 (Green) or 0xFF0000FF (Blue)
  final double intensity; // 0.0 to 1.0 (Similarity threshold)
  final double shadow; // 0.0 to 1.0 (Smoothness / shadow falloff)
  final double edgeSmoothing; // 0.0 to 1.0

  const ChromaKeyConfigEntity({
    this.isEnabled = false,
    this.keyColorHex = 0xFF00FF00,
    this.intensity = 0.45,
    this.shadow = 0.2,
    this.edgeSmoothing = 0.1,
  });

  ChromaKeyConfigEntity copyWith({
    bool? isEnabled,
    int? keyColorHex,
    double? intensity,
    double? shadow,
    double? edgeSmoothing,
  }) {
    return ChromaKeyConfigEntity(
      isEnabled: isEnabled ?? this.isEnabled,
      keyColorHex: keyColorHex ?? this.keyColorHex,
      intensity: intensity ?? this.intensity,
      shadow: shadow ?? this.shadow,
      edgeSmoothing: edgeSmoothing ?? this.edgeSmoothing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChromaKeyConfigEntity &&
          isEnabled == other.isEnabled &&
          keyColorHex == other.keyColorHex &&
          intensity == other.intensity &&
          shadow == other.shadow &&
          edgeSmoothing == other.edgeSmoothing;

  @override
  int get hashCode => Object.hash(isEnabled, keyColorHex, intensity, shadow, edgeSmoothing);
}
