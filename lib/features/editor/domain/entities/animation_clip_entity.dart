import 'package:flutter/foundation.dart';
import 'clip_animation_type.dart';

@immutable
class AnimationClipEntity {
  final String id;
  final String name;
  final ClipAnimationCombo animationType;
  final int timelineStartMs;
  final int durationMs;
  final double intensity;

  const AnimationClipEntity({
    required this.id,
    required this.name,
    required this.animationType,
    required this.timelineStartMs,
    this.durationMs = 2000,
    this.intensity = 1.0,
  });

  int get timelineEndMs => timelineStartMs + durationMs;

  AnimationClipEntity copyWith({
    String? id,
    String? name,
    ClipAnimationCombo? animationType,
    int? timelineStartMs,
    int? durationMs,
    double? intensity,
  }) {
    return AnimationClipEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      animationType: animationType ?? this.animationType,
      timelineStartMs: timelineStartMs ?? this.timelineStartMs,
      durationMs: durationMs ?? this.durationMs,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'animationType': animationType.name,
      'timelineStartMs': timelineStartMs,
      'durationMs': durationMs,
      'intensity': intensity,
    };
  }

  factory AnimationClipEntity.fromJson(Map<String, dynamic> json) {
    return AnimationClipEntity(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Animation',
      animationType: ClipAnimationCombo.values.firstWhere(
        (c) => c.name == json['animationType'],
        orElse: () => ClipAnimationCombo.pulse,
      ),
      timelineStartMs: (json['timelineStartMs'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 2000,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimationClipEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          animationType == other.animationType &&
          timelineStartMs == other.timelineStartMs &&
          durationMs == other.durationMs &&
          intensity == other.intensity;

  @override
  int get hashCode =>
      id.hashCode ^
      animationType.hashCode ^
      timelineStartMs.hashCode ^
      durationMs.hashCode ^
      intensity.hashCode;
}
