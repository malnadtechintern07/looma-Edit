import 'package:flutter/material.dart';

class DrawingStrokeEntity {
  final List<Offset> points;
  final int colorHex;
  final double strokeWidth;
  final bool isEraser;
  final String brushType; // 'pen', 'marker', 'neon'
  final double opacity;

  const DrawingStrokeEntity({
    required this.points,
    this.colorHex = 0xFFFF0055,
    this.strokeWidth = 4.0,
    this.isEraser = false,
    this.brushType = 'pen',
    this.opacity = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'colorHex': colorHex,
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
      'brushType': brushType,
      'opacity': opacity,
    };
  }

  factory DrawingStrokeEntity.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List<dynamic>?) ?? [];
    final points = rawPoints.map((p) {
      final map = p as Map<String, dynamic>;
      return Offset(
        (map['x'] as num).toDouble(),
        (map['y'] as num).toDouble(),
      );
    }).toList();

    return DrawingStrokeEntity(
      points: points,
      colorHex: json['colorHex'] as int? ?? 0xFFFF0055,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 4.0,
      isEraser: json['isEraser'] as bool? ?? false,
      brushType: json['brushType'] as String? ?? 'pen',
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
