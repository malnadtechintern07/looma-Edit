import 'package:flutter/foundation.dart';

@immutable
class CropRectEntity {
  final double left; // 0.0 to 1.0
  final double top; // 0.0 to 1.0
  final double right; // 0.0 to 1.0
  final double bottom; // 0.0 to 1.0
  final String ratioName; // 'Free', '16:9', '9:16', '1:1', '4:5', '4:3'

  const CropRectEntity({
    this.left = 0.0,
    this.top = 0.0,
    this.right = 1.0,
    this.bottom = 1.0,
    this.ratioName = 'Free',
  });

  CropRectEntity copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
    String? ratioName,
  }) {
    return CropRectEntity(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      ratioName: ratioName ?? this.ratioName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropRectEntity &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom &&
          ratioName == other.ratioName;

  @override
  int get hashCode => Object.hash(left, top, right, bottom, ratioName);
}
