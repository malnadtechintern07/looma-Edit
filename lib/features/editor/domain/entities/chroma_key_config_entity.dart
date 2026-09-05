import 'package:flutter/foundation.dart';

@immutable
class ChromaKeyConfigEntity {
  final bool isEnabled;
  final int keyColorHex; // E.g. 0xFF00FF00 (Green), 0xFF0000FF (Blue), or any sampled color
  final double intensity; // 0.0 to 1.0 (Strength / Tolerance: 0-100)
  final double edgeSoftness; // 0.0 to 1.0 (Edge Softness / Feather: 0-100)
  final double spillSuppression; // 0.0 to 1.0 (Spill Suppression: 0-100)
  final double shadow; // Backward compatibility
  final double edgeSmoothing; // Backward compatibility

  const ChromaKeyConfigEntity({
    this.isEnabled = false,
    this.keyColorHex = 0xFF00FF00,
    this.intensity = 0.50,
    this.edgeSoftness = 0.15,
    this.spillSuppression = 0.30,
    double? shadow,
    double? edgeSmoothing,
  })  : shadow = shadow ?? edgeSoftness,
        edgeSmoothing = edgeSmoothing ?? edgeSoftness;

  ChromaKeyConfigEntity copyWith({
    bool? isEnabled,
    int? keyColorHex,
    double? intensity,
    double? edgeSoftness,
    double? spillSuppression,
    double? shadow,
    double? edgeSmoothing,
  }) {
    final newEdgeSoftness = edgeSoftness ?? this.edgeSoftness;
    return ChromaKeyConfigEntity(
      isEnabled: isEnabled ?? this.isEnabled,
      keyColorHex: keyColorHex ?? this.keyColorHex,
      intensity: intensity ?? this.intensity,
      edgeSoftness: newEdgeSoftness,
      spillSuppression: spillSuppression ?? this.spillSuppression,
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
          edgeSoftness == other.edgeSoftness &&
          spillSuppression == other.spillSuppression &&
          shadow == other.shadow &&
          edgeSmoothing == other.edgeSmoothing;

  @override
  int get hashCode => Object.hash(
        isEnabled,
        keyColorHex,
        intensity,
        edgeSoftness,
        spillSuppression,
        shadow,
        edgeSmoothing,
      );
}
