import 'package:flutter/foundation.dart';

@immutable
class StickerOverlayEntity {
  final String id;
  final String stickerKey;
  final String stickerName;
  final String assetEmojiOrPath;
  final double posX; // Normalized 0.0 to 1.0
  final double posY; // Normalized 0.0 to 1.0
  final double scale;
  final double rotation;
  final int timelineStartMs;
  final int timelineEndMs;

  const StickerOverlayEntity({
    required this.id,
    required this.stickerKey,
    required this.stickerName,
    required this.assetEmojiOrPath,
    this.posX = 0.5,
    this.posY = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    required this.timelineStartMs,
    required this.timelineEndMs,
  });

  int get effectiveDurationMs => timelineEndMs - timelineStartMs;

  StickerOverlayEntity copyWith({
    String? id,
    String? stickerKey,
    String? stickerName,
    String? assetEmojiOrPath,
    double? posX,
    double? posY,
    double? scale,
    double? rotation,
    int? timelineStartMs,
    int? timelineEndMs,
  }) {
    return StickerOverlayEntity(
      id: id ?? this.id,
      stickerKey: stickerKey ?? this.stickerKey,
      stickerName: stickerName ?? this.stickerName,
      assetEmojiOrPath: assetEmojiOrPath ?? this.assetEmojiOrPath,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      timelineStartMs: timelineStartMs ?? this.timelineStartMs,
      timelineEndMs: timelineEndMs ?? this.timelineEndMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StickerOverlayEntity &&
          id == other.id &&
          stickerKey == other.stickerKey &&
          posX == other.posX &&
          posY == other.posY &&
          scale == other.scale &&
          timelineStartMs == other.timelineStartMs &&
          timelineEndMs == other.timelineEndMs;

  @override
  int get hashCode => Object.hash(id, stickerKey, posX, posY, timelineStartMs);
}
