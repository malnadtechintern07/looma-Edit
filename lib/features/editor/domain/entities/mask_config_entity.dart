import 'package:flutter/foundation.dart';

enum MaskShape { none, rectangle, circle, linear, filmstrip }

@immutable
class MaskConfigEntity {
  final MaskShape shape;
  final double centerX; // 0.0 to 1.0
  final double centerY; // 0.0 to 1.0
  final double widthFactor; // 0.1 to 1.0
  final double heightFactor; // 0.1 to 1.0
  final double rotationDegrees;
  final double feather; // 0.0 to 1.0 (blur/smooth edge)
  final bool isInverted;

  const MaskConfigEntity({
    this.shape = MaskShape.none,
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.widthFactor = 0.8,
    this.heightFactor = 0.8,
    this.rotationDegrees = 0.0,
    this.feather = 0.0,
    this.isInverted = false,
  });

  MaskConfigEntity copyWith({
    MaskShape? shape,
    double? centerX,
    double? centerY,
    double? widthFactor,
    double? heightFactor,
    double? rotationDegrees,
    double? feather,
    bool? isInverted,
  }) {
    return MaskConfigEntity(
      shape: shape ?? this.shape,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      widthFactor: widthFactor ?? this.widthFactor,
      heightFactor: heightFactor ?? this.heightFactor,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      feather: feather ?? this.feather,
      isInverted: isInverted ?? this.isInverted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaskConfigEntity &&
          shape == other.shape &&
          centerX == other.centerX &&
          centerY == other.centerY &&
          widthFactor == other.widthFactor &&
          heightFactor == other.heightFactor &&
          rotationDegrees == other.rotationDegrees &&
          feather == other.feather &&
          isInverted == other.isInverted;

  @override
  int get hashCode => Object.hash(
        shape,
        centerX,
        centerY,
        widthFactor,
        heightFactor,
        rotationDegrees,
        feather,
        isInverted,
      );
}
