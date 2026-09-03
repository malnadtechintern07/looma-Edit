import 'dart:math';
import 'package:flutter/foundation.dart';

@immutable
class KeyframeEntity {
  final String id;
  /// Timestamp in milliseconds relative to the clip's start (0 = clip start)
  final int timestampMs;
  final double? posX;
  final double? posY;
  final double? scale;
  final double? rotation;
  final double? opacity;

  const KeyframeEntity({
    required this.id,
    required this.timestampMs,
    this.posX,
    this.posY,
    this.scale,
    this.rotation,
    this.opacity,
  });

  KeyframeEntity copyWith({
    String? id,
    int? timestampMs,
    double? posX,
    double? posY,
    double? scale,
    double? rotation,
    double? opacity,
  }) {
    return KeyframeEntity(
      id: id ?? this.id,
      timestampMs: timestampMs ?? this.timestampMs,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyframeEntity &&
          id == other.id &&
          timestampMs == other.timestampMs &&
          posX == other.posX &&
          posY == other.posY &&
          scale == other.scale &&
          rotation == other.rotation &&
          opacity == other.opacity;

  @override
  int get hashCode => Object.hash(id, timestampMs, posX, posY, scale, rotation, opacity);
}

/// Evaluates interpolated transform values across keyframes for any given clip offset
class KeyframeInterpolator {
  static KeyframeValues interpolate({
    required List<KeyframeEntity> keyframes,
    required int currentOffsetMs,
    required KeyframeValues baseValues,
  }) {
    if (keyframes.isEmpty) return baseValues;

    final sorted = List<KeyframeEntity>.from(keyframes)
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    // If current time is before first keyframe
    if (currentOffsetMs <= sorted.first.timestampMs) {
      final first = sorted.first;
      return KeyframeValues(
        posX: first.posX ?? baseValues.posX,
        posY: first.posY ?? baseValues.posY,
        scale: first.scale ?? baseValues.scale,
        rotation: first.rotation ?? baseValues.rotation,
        opacity: first.opacity ?? baseValues.opacity,
      );
    }

    // If current time is after last keyframe
    if (currentOffsetMs >= sorted.last.timestampMs) {
      final last = sorted.last;
      return KeyframeValues(
        posX: last.posX ?? baseValues.posX,
        posY: last.posY ?? baseValues.posY,
        scale: last.scale ?? baseValues.scale,
        rotation: last.rotation ?? baseValues.rotation,
        opacity: last.opacity ?? baseValues.opacity,
      );
    }

    // Find bounding keyframes [k1, k2]
    KeyframeEntity k1 = sorted.first;
    KeyframeEntity k2 = sorted.last;

    for (int i = 0; i < sorted.length - 1; i++) {
      if (currentOffsetMs >= sorted[i].timestampMs &&
          currentOffsetMs <= sorted[i + 1].timestampMs) {
        k1 = sorted[i];
        k2 = sorted[i + 1];
        break;
      }
    }

    final duration = k2.timestampMs - k1.timestampMs;
    final t = duration > 0 ? (currentOffsetMs - k1.timestampMs) / duration.toDouble() : 0.0;
    // Smooth cosine ease interpolation
    final smoothT = (1.0 - cos(t * pi)) / 2.0;

    return KeyframeValues(
      posX: _lerp(k1.posX ?? baseValues.posX, k2.posX ?? baseValues.posX, smoothT),
      posY: _lerp(k1.posY ?? baseValues.posY, k2.posY ?? baseValues.posY, smoothT),
      scale: _lerp(k1.scale ?? baseValues.scale, k2.scale ?? baseValues.scale, smoothT),
      rotation: _lerp(k1.rotation ?? baseValues.rotation, k2.rotation ?? baseValues.rotation, smoothT),
      opacity: _lerp(k1.opacity ?? baseValues.opacity, k2.opacity ?? baseValues.opacity, smoothT),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

@immutable
class KeyframeValues {
  final double posX;
  final double posY;
  final double scale;
  final double rotation;
  final double opacity;

  const KeyframeValues({
    required this.posX,
    required this.posY,
    required this.scale,
    required this.rotation,
    required this.opacity,
  });
}
