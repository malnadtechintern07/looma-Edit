import 'drawing_stroke_entity.dart';
import 'photo_frame_entity.dart';
import 'photo_sticker_overlay_entity.dart';
import 'photo_text_overlay_entity.dart';
import 'watermark_entity.dart';

enum PhotoAspectRatio {
  square('1:1 Square', 1.0),
  portrait9x16('9:16 Story', 9 / 16),
  landscape16x9('16:9 Cinema', 16 / 9),
  portrait4x5('4:5 Feed', 4 / 5),
  portrait2x3('2:3 Poster', 2 / 3),
  portrait3x4('3:4 Classic', 3 / 4);

  final String label;
  final double ratio;
  const PhotoAspectRatio(this.label, this.ratio);
}

enum CollageLayoutType {
  single('Single Photo', 1),
  grid2Vertical('2 Split Vertical', 2),
  grid2Horizontal('2 Split Horizontal', 2),
  grid3Hero('3 Photo Hero', 3),
  grid4Quad('4 Photo Quad', 4),
  grid6Grid('6 Photo Gallery', 6),
  grid9Grid('9 Photo Grid', 9);

  final String title;
  final int maxSlots;
  const CollageLayoutType(this.title, this.maxSlots);
}

class PhotoProjectEntity {
  final String id;
  final String title;
  final PhotoAspectRatio aspectRatio;
  final CollageLayoutType collageLayout;
  final List<PhotoFrameEntity> frames;
  final double gapSpacing;
  final double borderRadius;
  final int backgroundColorHex;
  final String backgroundType; // 'color', 'gradient', 'blur', 'transparent'
  final List<int> gradientColorsHex;
  final double blurBackgroundRadius;
  final int? exportWidth;
  final int? exportHeight;
  final WatermarkEntity watermark;
  final List<PhotoTextOverlayEntity> textOverlays;
  final List<PhotoStickerOverlayEntity> stickerOverlays;
  final List<DrawingStrokeEntity> drawingStrokes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PhotoProjectEntity({
    required this.id,
    required this.title,
    this.aspectRatio = PhotoAspectRatio.square,
    this.collageLayout = CollageLayoutType.single,
    required this.frames,
    this.gapSpacing = 4.0,
    this.borderRadius = 8.0,
    this.backgroundColorHex = 0xFF0F172A,
    this.backgroundType = 'color',
    this.gradientColorsHex = const [0xFF0F172A, 0xFF1E293B],
    this.blurBackgroundRadius = 20.0,
    this.exportWidth,
    this.exportHeight,
    this.watermark = const WatermarkEntity(),
    this.textOverlays = const [],
    this.stickerOverlays = const [],
    this.drawingStrokes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  PhotoProjectEntity copyWith({
    String? id,
    String? title,
    PhotoAspectRatio? aspectRatio,
    CollageLayoutType? collageLayout,
    List<PhotoFrameEntity>? frames,
    double? gapSpacing,
    double? borderRadius,
    int? backgroundColorHex,
    String? backgroundType,
    List<int>? gradientColorsHex,
    double? blurBackgroundRadius,
    int? exportWidth,
    int? exportHeight,
    WatermarkEntity? watermark,
    List<PhotoTextOverlayEntity>? textOverlays,
    List<PhotoStickerOverlayEntity>? stickerOverlays,
    List<DrawingStrokeEntity>? drawingStrokes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhotoProjectEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      collageLayout: collageLayout ?? this.collageLayout,
      frames: frames ?? this.frames,
      gapSpacing: gapSpacing ?? this.gapSpacing,
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      backgroundType: backgroundType ?? this.backgroundType,
      gradientColorsHex: gradientColorsHex ?? this.gradientColorsHex,
      blurBackgroundRadius: blurBackgroundRadius ?? this.blurBackgroundRadius,
      exportWidth: exportWidth ?? this.exportWidth,
      exportHeight: exportHeight ?? this.exportHeight,
      watermark: watermark ?? this.watermark,
      textOverlays: textOverlays ?? this.textOverlays,
      stickerOverlays: stickerOverlays ?? this.stickerOverlays,
      drawingStrokes: drawingStrokes ?? this.drawingStrokes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'aspectRatio': aspectRatio.name,
      'collageLayout': collageLayout.name,
      'frames': frames.map((f) => f.toJson()).toList(),
      'gapSpacing': gapSpacing,
      'borderRadius': borderRadius,
      'backgroundColorHex': backgroundColorHex,
      'backgroundType': backgroundType,
      'gradientColorsHex': gradientColorsHex,
      'blurBackgroundRadius': blurBackgroundRadius,
      'exportWidth': exportWidth,
      'exportHeight': exportHeight,
      'watermark': watermark.toJson(),
      'textOverlays': textOverlays.map((t) => t.toJson()).toList(),
      'stickerOverlays': stickerOverlays.map((s) => s.toJson()).toList(),
      'drawingStrokes': drawingStrokes.map((d) => d.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PhotoProjectEntity.fromJson(Map<String, dynamic> json) {
    final rawGradients = json['gradientColorsHex'] as List<dynamic>?;
    final parsedGradients = rawGradients != null
        ? rawGradients.map((c) => (c as num).toInt()).toList()
        : const [0xFF0F172A, 0xFF1E293B];

    return PhotoProjectEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      aspectRatio: PhotoAspectRatio.values.firstWhere(
        (a) => a.name == json['aspectRatio'],
        orElse: () => PhotoAspectRatio.square,
      ),
      collageLayout: CollageLayoutType.values.firstWhere(
        (c) => c.name == json['collageLayout'],
        orElse: () => CollageLayoutType.single,
      ),
      frames: (json['frames'] as List<dynamic>?)
              ?.map((f) => PhotoFrameEntity.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      gapSpacing: (json['gapSpacing'] as num?)?.toDouble() ?? 4.0,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 8.0,
      backgroundColorHex: json['backgroundColorHex'] as int? ?? 0xFF0F172A,
      backgroundType: json['backgroundType'] as String? ?? 'color',
      gradientColorsHex: parsedGradients,
      blurBackgroundRadius: (json['blurBackgroundRadius'] as num?)?.toDouble() ?? 20.0,
      exportWidth: json['exportWidth'] as int?,
      exportHeight: json['exportHeight'] as int?,
      watermark: json['watermark'] != null
          ? WatermarkEntity.fromJson(json['watermark'] as Map<String, dynamic>)
          : const WatermarkEntity(),
      textOverlays: (json['textOverlays'] as List<dynamic>?)
              ?.map((t) => PhotoTextOverlayEntity.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      stickerOverlays: (json['stickerOverlays'] as List<dynamic>?)
              ?.map((s) => PhotoStickerOverlayEntity.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      drawingStrokes: (json['drawingStrokes'] as List<dynamic>?)
              ?.map((d) => DrawingStrokeEntity.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
