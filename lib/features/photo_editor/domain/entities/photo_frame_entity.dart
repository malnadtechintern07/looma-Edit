import '../../../filters_effects/domain/entities/filter_preset.dart';

class PhotoFrameEntity {
  final String id;
  final String imagePath;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final FilterType filterType;
  final double filterIntensity; // 0.0 to 1.0 (default 1.0 = full strength)

  // Crop & Geometric Transforms
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final bool flipHorizontal;
  final bool flipVertical;
  final double straighten; // In degrees (-45° to +45°)
  final double perspectiveX; // In degrees (-30° to +30°)
  final double perspectiveY; // In degrees (-30° to +30°)

  // Light & Tone Adjustments
  final double brightness; // -1.0 to 1.0 (default 0.0)
  final double contrast; // 0.5 to 2.0 (default 1.0)
  final double exposure; // -1.0 to 1.0 (default 0.0)
  final double highlights; // -1.0 to 1.0 (default 0.0)
  final double shadows; // -1.0 to 1.0 (default 0.0)

  // Color & White Balance
  final double saturation; // 0.0 to 2.0 (default 1.0)
  final double vibrance; // -1.0 to 1.0 (default 0.0)
  final double temperature; // -1.0 to 1.0 (default 0.0, warm/cool)
  final double tint; // -1.0 to 1.0 (default 0.0, green/magenta)

  // Detail & Atmosphere Effects
  final double sharpness; // 0.0 to 1.0 (default 0.0)
  final double blur; // 0.0 to 25.0 px (default 0.0)
  final double vignette; // 0.0 to 1.0 (default 0.0)
  final double grain; // 0.0 to 1.0 (default 0.0)
  final double fade; // 0.0 to 1.0 (default 0.0)

  // Advanced HSL and Tone Curves
  final Map<String, Map<String, double>> hslAdjustments;
  final Map<String, List<double>> toneCurves;

  const PhotoFrameEntity({
    required this.id,
    required this.imagePath,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.rotation = 0.0,
    this.filterType = FilterType.none,
    this.filterIntensity = 1.0,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 1.0,
    this.cropBottom = 1.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.straighten = 0.0,
    this.perspectiveX = 0.0,
    this.perspectiveY = 0.0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.exposure = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.saturation = 1.0,
    this.vibrance = 0.0,
    this.temperature = 0.0,
    this.tint = 0.0,
    this.sharpness = 0.0,
    this.blur = 0.0,
    this.vignette = 0.0,
    this.grain = 0.0,
    this.fade = 0.0,
    this.hslAdjustments = const {},
    this.toneCurves = const {},
  });

  PhotoFrameEntity copyWith({
    String? id,
    String? imagePath,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    FilterType? filterType,
    double? filterIntensity,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
    bool? flipHorizontal,
    bool? flipVertical,
    double? straighten,
    double? perspectiveX,
    double? perspectiveY,
    double? brightness,
    double? contrast,
    double? exposure,
    double? highlights,
    double? shadows,
    double? saturation,
    double? vibrance,
    double? temperature,
    double? tint,
    double? sharpness,
    double? blur,
    double? vignette,
    double? grain,
    double? fade,
    Map<String, Map<String, double>>? hslAdjustments,
    Map<String, List<double>>? toneCurves,
  }) {
    return PhotoFrameEntity(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotation: rotation ?? this.rotation,
      filterType: filterType ?? this.filterType,
      filterIntensity: filterIntensity ?? this.filterIntensity,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      straighten: straighten ?? this.straighten,
      perspectiveX: perspectiveX ?? this.perspectiveX,
      perspectiveY: perspectiveY ?? this.perspectiveY,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      exposure: exposure ?? this.exposure,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      saturation: saturation ?? this.saturation,
      vibrance: vibrance ?? this.vibrance,
      temperature: temperature ?? this.temperature,
      tint: tint ?? this.tint,
      sharpness: sharpness ?? this.sharpness,
      blur: blur ?? this.blur,
      vignette: vignette ?? this.vignette,
      grain: grain ?? this.grain,
      fade: fade ?? this.fade,
      hslAdjustments: hslAdjustments ?? this.hslAdjustments,
      toneCurves: toneCurves ?? this.toneCurves,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'rotation': rotation,
      'filterType': filterType.name,
      'filterIntensity': filterIntensity,
      'cropLeft': cropLeft,
      'cropTop': cropTop,
      'cropRight': cropRight,
      'cropBottom': cropBottom,
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'straighten': straighten,
      'perspectiveX': perspectiveX,
      'perspectiveY': perspectiveY,
      'brightness': brightness,
      'contrast': contrast,
      'exposure': exposure,
      'highlights': highlights,
      'shadows': shadows,
      'saturation': saturation,
      'vibrance': vibrance,
      'temperature': temperature,
      'tint': tint,
      'sharpness': sharpness,
      'blur': blur,
      'vignette': vignette,
      'grain': grain,
      'fade': fade,
      'hslAdjustments': hslAdjustments,
      'toneCurves': toneCurves,
    };
  }

  factory PhotoFrameEntity.fromJson(Map<String, dynamic> json) {
    // Parse HSL adjustments safely
    final rawHsl = json['hslAdjustments'];
    final Map<String, Map<String, double>> parsedHsl = {};
    if (rawHsl is Map) {
      rawHsl.forEach((k, v) {
        if (v is Map) {
          final Map<String, double> channelMap = {};
          v.forEach((ck, cv) {
            if (cv is num) channelMap[ck.toString()] = cv.toDouble();
          });
          parsedHsl[k.toString()] = channelMap;
        }
      });
    }

    // Parse Tone curves safely
    final rawCurves = json['toneCurves'];
    final Map<String, List<double>> parsedCurves = {};
    if (rawCurves is Map) {
      rawCurves.forEach((k, v) {
        if (v is List) {
          parsedCurves[k.toString()] = v.map((e) => (e as num).toDouble()).toList();
        }
      });
    }

    return PhotoFrameEntity(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      filterType: FilterType.fromString(json['filterType'] as String?),
      filterIntensity: (json['filterIntensity'] as num?)?.toDouble() ?? 1.0,
      cropLeft: (json['cropLeft'] as num?)?.toDouble() ?? 0.0,
      cropTop: (json['cropTop'] as num?)?.toDouble() ?? 0.0,
      cropRight: (json['cropRight'] as num?)?.toDouble() ?? 1.0,
      cropBottom: (json['cropBottom'] as num?)?.toDouble() ?? 1.0,
      flipHorizontal: json['flipHorizontal'] as bool? ?? false,
      flipVertical: json['flipVertical'] as bool? ?? false,
      straighten: (json['straighten'] as num?)?.toDouble() ?? 0.0,
      perspectiveX: (json['perspectiveX'] as num?)?.toDouble() ?? 0.0,
      perspectiveY: (json['perspectiveY'] as num?)?.toDouble() ?? 0.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      exposure: (json['exposure'] as num?)?.toDouble() ?? 0.0,
      highlights: (json['highlights'] as num?)?.toDouble() ?? 0.0,
      shadows: (json['shadows'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
      vibrance: (json['vibrance'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      tint: (json['tint'] as num?)?.toDouble() ?? 0.0,
      sharpness: (json['sharpness'] as num?)?.toDouble() ?? 0.0,
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      vignette: (json['vignette'] as num?)?.toDouble() ?? 0.0,
      grain: (json['grain'] as num?)?.toDouble() ?? 0.0,
      fade: (json['fade'] as num?)?.toDouble() ?? 0.0,
      hslAdjustments: parsedHsl,
      toneCurves: parsedCurves,
    );
  }
}
