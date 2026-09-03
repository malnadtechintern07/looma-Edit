import 'package:flutter/foundation.dart';

@immutable
class SubtitleEntity {
  final String id;
  final String text;
  final int timelineStartMs;
  final int timelineEndMs;
  final String fontFamily;
  final double fontSize;
  final int colorHex;
  final int? backgroundColorHex;
  final double posY; // 0.0 to 1.0 (defaults to 0.85 near bottom)

  const SubtitleEntity({
    required this.id,
    required this.text,
    required this.timelineStartMs,
    required this.timelineEndMs,
    this.fontFamily = 'Inter',
    this.fontSize = 20.0,
    this.colorHex = 0xFFFFFFFF,
    this.backgroundColorHex = 0x88000000,
    this.posY = 0.85,
  });

  int get durationMs => timelineEndMs - timelineStartMs;

  SubtitleEntity copyWith({
    String? id,
    String? text,
    int? timelineStartMs,
    int? timelineEndMs,
    String? fontFamily,
    double? fontSize,
    int? colorHex,
    int? backgroundColorHex,
    double? posY,
  }) {
    return SubtitleEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      timelineStartMs: timelineStartMs ?? this.timelineStartMs,
      timelineEndMs: timelineEndMs ?? this.timelineEndMs,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      colorHex: colorHex ?? this.colorHex,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      posY: posY ?? this.posY,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtitleEntity &&
          id == other.id &&
          text == other.text &&
          timelineStartMs == other.timelineStartMs &&
          timelineEndMs == other.timelineEndMs;

  @override
  int get hashCode => Object.hash(id, text, timelineStartMs, timelineEndMs);
}
