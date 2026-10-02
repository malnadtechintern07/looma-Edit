import 'drawing_stroke_entity.dart';
import 'photo_frame_entity.dart';
import 'photo_sticker_overlay_entity.dart';
import 'photo_text_overlay_entity.dart';
import 'watermark_entity.dart';

enum PhotoAspectRatio {
  square('1:1 Square', 1.0),
  portrait4x5('4:5 Feed', 4 / 5),
  portrait9x16('9:16 Story', 9 / 16),
  landscape16x9('16:9 Cinema', 16 / 9),
  portrait3x4('3:4 Classic', 3 / 4),
  landscape4x3('4:3 Standard', 4 / 3),
  portrait2x3('2:3 Poster', 2 / 3),
  landscape3x2('3:2 Photo', 3 / 2),
  cinematic21x9('21:9 Ultrawide', 21 / 9),
  portrait5x4('5:4 Frame', 5 / 4);

  final String label;
  final double ratio;
  const PhotoAspectRatio(this.label, this.ratio);

  String get ratioText {
    switch (this) {
      case PhotoAspectRatio.square:
        return '1:1';
      case PhotoAspectRatio.portrait4x5:
        return '4:5';
      case PhotoAspectRatio.portrait9x16:
        return '9:16';
      case PhotoAspectRatio.landscape16x9:
        return '16:9';
      case PhotoAspectRatio.portrait3x4:
        return '3:4';
      case PhotoAspectRatio.landscape4x3:
        return '4:3';
      case PhotoAspectRatio.portrait2x3:
        return '2:3';
      case PhotoAspectRatio.landscape3x2:
        return '3:2';
      case PhotoAspectRatio.cinematic21x9:
        return '21:9';
      case PhotoAspectRatio.portrait5x4:
        return '5:4';
    }
  }

  String get platform {
    switch (this) {
      case PhotoAspectRatio.square:
        return 'Instagram';
      case PhotoAspectRatio.portrait4x5:
        return 'IG / Facebook';
      case PhotoAspectRatio.portrait9x16:
        return 'TikTok / Reels';
      case PhotoAspectRatio.landscape16x9:
        return 'YouTube';
      case PhotoAspectRatio.portrait3x4:
        return 'Portrait';
      case PhotoAspectRatio.landscape4x3:
        return 'Tablet / PC';
      case PhotoAspectRatio.portrait2x3:
        return 'Pinterest';
      case PhotoAspectRatio.landscape3x2:
        return 'DSLR Camera';
      case PhotoAspectRatio.cinematic21x9:
        return 'Cinema';
      case PhotoAspectRatio.portrait5x4:
        return 'Print Frame';
    }
  }

  String get category {
    switch (this) {
      case PhotoAspectRatio.square:
      case PhotoAspectRatio.portrait4x5:
      case PhotoAspectRatio.portrait9x16:
      case PhotoAspectRatio.landscape16x9:
      case PhotoAspectRatio.portrait2x3:
        return 'Social';
      case PhotoAspectRatio.portrait3x4:
      case PhotoAspectRatio.portrait5x4:
        return 'Portrait';
      case PhotoAspectRatio.landscape4x3:
      case PhotoAspectRatio.landscape3x2:
      case PhotoAspectRatio.cinematic21x9:
        return 'Landscape';
    }
  }

  String get resolutionEstimate {
    switch (this) {
      case PhotoAspectRatio.square:
        return '1080 × 1080 px';
      case PhotoAspectRatio.portrait4x5:
        return '1080 × 1350 px';
      case PhotoAspectRatio.portrait9x16:
        return '1080 × 1920 px';
      case PhotoAspectRatio.landscape16x9:
        return '1920 × 1080 px';
      case PhotoAspectRatio.portrait3x4:
        return '1500 × 2000 px';
      case PhotoAspectRatio.landscape4x3:
        return '2000 × 1500 px';
      case PhotoAspectRatio.portrait2x3:
        return '1000 × 1500 px';
      case PhotoAspectRatio.landscape3x2:
        return '1500 × 1000 px';
      case PhotoAspectRatio.cinematic21x9:
        return '2560 × 1080 px';
      case PhotoAspectRatio.portrait5x4:
        return '1250 × 1000 px';
    }
  }

  String get description {
    switch (this) {
      case PhotoAspectRatio.square:
        return 'Standard 1:1 square canvas, ideal for Instagram feed & profile photos.';
      case PhotoAspectRatio.portrait4x5:
        return 'Vertical 4:5 format maximizing screen coverage on Instagram & Facebook feeds.';
      case PhotoAspectRatio.portrait9x16:
        return 'Full vertical 9:16 layout, best for TikTok, IG Reels, YouTube Shorts & Stories.';
      case PhotoAspectRatio.landscape16x9:
        return 'Standard 16:9 widescreen canvas, perfect for YouTube videos & landscape shots.';
      case PhotoAspectRatio.portrait3x4:
        return 'Classic 3:4 portrait photo standard, common in smartphone cameras & prints.';
      case PhotoAspectRatio.landscape4x3:
        return 'Classic 4:3 landscape ratio, matching tablet screens & traditional monitors.';
      case PhotoAspectRatio.portrait2x3:
        return 'Traditional 2:3 35mm film portrait ratio, ideal for Pinterest pins & posters.';
      case PhotoAspectRatio.landscape3x2:
        return 'Standard 3:2 landscape format, the native aspect ratio of DSLR cameras.';
      case PhotoAspectRatio.cinematic21x9:
        return 'Ultra-wide 21:9 cinematic ratio for epic panoramic and cinematic edits.';
      case PhotoAspectRatio.portrait5x4:
        return 'Classic 5:4 large-format photo portrait ratio, great for artistic prints.';
    }
  }
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
