import 'package:flutter/foundation.dart';
import 'overlay_animation_type.dart';

@immutable
class TextOverlayEntity {
  final String id;
  final String text;
  final String fontFamily;
  final double fontSize;
  final int colorHex;
  final int? backgroundColorHex;
  final int? outlineColorHex;
  final double outlineWidth;
  final double posX; // Normalized 0.0 to 1.0 (center based)
  final double posY; // Normalized 0.0 to 1.0
  final double scale;
  final double rotation; // In radians
  final int timelineStartMs;
  final int timelineEndMs;
  final OverlayAnimationType animationType;

  const TextOverlayEntity({
    required this.id,
    required this.text,
    this.fontFamily = 'Inter',
    this.fontSize = 24.0,
    this.colorHex = 0xFFFFFFFF,
    this.backgroundColorHex,
    this.outlineColorHex,
    this.outlineWidth = 0.0,
    this.posX = 0.5,
    this.posY = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    required this.timelineStartMs,
    required this.timelineEndMs,
    this.animationType = OverlayAnimationType.none,
  });

  int get effectiveDurationMs => timelineEndMs - timelineStartMs;

  TextOverlayEntity copyWith({
    String? id,
    String? text,
    String? fontFamily,
    double? fontSize,
    int? colorHex,
    int? backgroundColorHex,
    int? outlineColorHex,
    double? outlineWidth,
    double? posX,
    double? posY,
    double? scale,
    double? rotation,
    int? timelineStartMs,
    int? timelineEndMs,
    OverlayAnimationType? animationType,
  }) {
    return TextOverlayEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      colorHex: colorHex ?? this.colorHex,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      outlineColorHex: outlineColorHex ?? this.outlineColorHex,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      timelineStartMs: timelineStartMs ?? this.timelineStartMs,
      timelineEndMs: timelineEndMs ?? this.timelineEndMs,
      animationType: animationType ?? this.animationType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextOverlayEntity &&
          id == other.id &&
          text == other.text &&
          fontSize == other.fontSize &&
          colorHex == other.colorHex &&
          posX == other.posX &&
          posY == other.posY &&
          scale == other.scale &&
          timelineStartMs == other.timelineStartMs &&
          timelineEndMs == other.timelineEndMs;

  @override
  int get hashCode => Object.hash(id, text, fontSize, colorHex, posX, posY, timelineStartMs);
}
