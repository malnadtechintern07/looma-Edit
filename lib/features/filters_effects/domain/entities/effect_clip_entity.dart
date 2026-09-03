import 'package:flutter/foundation.dart';
import 'video_effect_type.dart';

@immutable
class EffectClipEntity {
  final String id;
  final VideoEffectType effectType;
  final int timelineStartMs;
  final int durationMs;
  final double intensity;

  const EffectClipEntity({
    required this.id,
    required this.effectType,
    required this.timelineStartMs,
    this.durationMs = 3000,
    this.intensity = 1.0,
  });

  int get timelineEndMs => timelineStartMs + durationMs;

  EffectClipEntity copyWith({
    String? id,
    VideoEffectType? effectType,
    int? timelineStartMs,
    int? durationMs,
    double? intensity,
  }) {
    return EffectClipEntity(
      id: id ?? this.id,
      effectType: effectType ?? this.effectType,
      timelineStartMs: timelineStartMs ?? this.timelineStartMs,
      durationMs: durationMs ?? this.durationMs,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'effectType': effectType.name,
      'timelineStartMs': timelineStartMs,
      'durationMs': durationMs,
      'intensity': intensity,
    };
  }

  factory EffectClipEntity.fromJson(Map<String, dynamic> json) {
    return EffectClipEntity(
      id: json['id'] as String,
      effectType: VideoEffectType.fromString(json['effectType'] as String?),
      timelineStartMs: (json['timelineStartMs'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 3000,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EffectClipEntity &&
          id == other.id &&
          effectType == other.effectType &&
          timelineStartMs == other.timelineStartMs &&
          durationMs == other.durationMs &&
          intensity == other.intensity;

  @override
  int get hashCode => Object.hash(id, effectType, timelineStartMs, durationMs, intensity);
}
