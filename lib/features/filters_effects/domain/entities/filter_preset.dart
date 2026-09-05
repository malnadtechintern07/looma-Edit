import 'package:flutter/material.dart';

/// Categories for filtering and grouping filters in the editor UI
enum FilterCategory {
  all('All', Icons.auto_awesome),
  cinematic('Cinematic & Film', Icons.movie_filter_outlined),
  vintage('Vintage & Retro', Icons.history_edu),
  warm('Warm & Sun', Icons.wb_sunny_outlined),
  cool('Cool & Frost', Icons.ac_unit),
  monochrome('B&W & Noir', Icons.filter_b_and_w),
  artistic('Artistic & Pop', Icons.palette_outlined);

  final String label;
  final IconData icon;

  const FilterCategory(this.label, this.icon);
}

/// 25 Professional Color Filter & LUT Presets with 4x5 Color Matrix definitions
enum FilterType {
  none(
    'Original',
    'Unfiltered Clean',
    FilterCategory.all,
    [],
  ),

  cinematic(
    'Cinematic',
    'Teal & Orange Hollywood',
    FilterCategory.cinematic,
    [
      1.15, 0.05, -0.05, 0.0, 10.0,
      0.00, 1.05,  0.00, 0.0,  5.0,
     -0.05, 0.05,  1.20, 0.0, 20.0,
      0.00, 0.00,  0.00, 1.0,  0.0,
    ],
  ),

  vintage(
    'Vintage',
    '70s Kodachrome',
    FilterCategory.vintage,
    [
      0.95, 0.05, 0.05, 0.0, 25.0,
      0.05, 0.85, 0.05, 0.0, 20.0,
      0.00, 0.10, 0.65, 0.0, 30.0,
      0.00, 0.00, 0.00, 1.0,  0.0,
    ],
  ),

  warm(
    'Warm',
    'Sunlit Amber',
    FilterCategory.warm,
    [
      1.20, 0.00,  0.00, 0.0,  18.0,
      0.00, 1.05,  0.00, 0.0,   8.0,
      0.00, 0.00,  0.80, 0.0, -15.0,
      0.00, 0.00,  0.00, 1.0,   0.0,
    ],
  ),

  cool(
    'Cool',
    'Nordic Breeze',
    FilterCategory.cool,
    [
      0.82, 0.00, 0.00, 0.0, -10.0,
      0.00, 0.95, 0.00, 0.0,   5.0,
      0.00, 0.00, 1.25, 0.0,  25.0,
      0.00, 0.00, 0.00, 1.0,   0.0,
    ],
  ),

  retro(
    'Retro',
    '80s Analog VHS',
    FilterCategory.vintage,
    [
      1.10, 0.00, 0.15, 0.0, 15.0,
      0.00, 0.90, 0.00, 0.0, -5.0,
      0.10, 0.00, 1.15, 0.0, 20.0,
      0.00, 0.00, 0.00, 1.0,  0.0,
    ],
  ),

  film(
    'Film',
    '35mm Fuji Stock',
    FilterCategory.cinematic,
    [
      1.05, -0.02, 0.00, 0.0, 12.0,
      0.00,  1.08, 0.02, 0.0,  8.0,
     -0.03,  0.02, 0.95, 0.0, 18.0,
      0.00,  0.00, 0.00, 1.0,  0.0,
    ],
  ),

  moody(
    'Moody',
    'Low-Key Atmosphere',
    FilterCategory.cinematic,
    [
      0.85, 0.00, 0.00, 0.0, -15.0,
      0.00, 0.88, 0.00, 0.0, -10.0,
      0.00, 0.00, 0.92, 0.0,  10.0,
      0.00, 0.00, 0.00, 1.0,   0.0,
    ],
  ),

  fade(
    'Fade',
    'Matte Wash',
    FilterCategory.vintage,
    [
      0.85, 0.00, 0.00, 0.0, 35.0,
      0.00, 0.85, 0.00, 0.0, 35.0,
      0.00, 0.00, 0.85, 0.0, 35.0,
      0.00, 0.00, 0.00, 1.0,  0.0,
    ],
  ),

  noir(
    'Noir',
    'High Contrast Dramatic',
    FilterCategory.monochrome,
    [
      0.35, 0.55, 0.15, 0.0, -20.0,
      0.35, 0.55, 0.15, 0.0, -20.0,
      0.35, 0.55, 0.15, 0.0, -20.0,
      0.00, 0.00, 0.00, 1.0,   0.0,
    ],
  ),

  bw(
    'B&W',
    'Studio Monochrome',
    FilterCategory.monochrome,
    [
      0.299, 0.587, 0.114, 0.0, 0.0,
      0.299, 0.587, 0.114, 0.0, 0.0,
      0.299, 0.587, 0.114, 0.0, 0.0,
      0.000, 0.000, 0.000, 1.0, 0.0,
    ],
  ),

  sepia(
    'Sepia',
    'Antique Warmth',
    FilterCategory.vintage,
    [
      0.393, 0.769, 0.189, 0.0,  15.0,
      0.349, 0.686, 0.168, 0.0,   5.0,
      0.272, 0.534, 0.131, 0.0, -20.0,
      0.000, 0.000, 0.000, 1.0,   0.0,
    ],
  ),

  sunset(
    'Sunset',
    'Crimson Twilight',
    FilterCategory.warm,
    [
      1.35, 0.00, 0.00, 0.0, 25.0,
      0.00, 0.85, 0.00, 0.0,  5.0,
      0.10, 0.00, 1.10, 0.0, 15.0,
      0.00, 0.00, 0.00, 1.0,  0.0,
    ],
  ),

  golden(
    'Golden',
    'Golden Hour Sun',
    FilterCategory.warm,
    [
      1.25, 0.05,  0.00, 0.0,  22.0,
      0.05, 1.12,  0.00, 0.0,  16.0,
      0.00, 0.00,  0.75, 0.0, -18.0,
      0.00, 0.00,  0.00, 1.0,   0.0,
    ],
  ),

  dreamy(
    'Dreamy',
    'Soft Pastel Glow',
    FilterCategory.artistic,
    [
      1.08, 0.05, 0.05, 0.0, 20.0,
      0.05, 1.05, 0.05, 0.0, 18.0,
      0.05, 0.05, 1.10, 0.0, 25.0,
      0.00, 0.00, 0.00, 1.0,  0.0,
    ],
  ),

  vivid(
    'Vivid',
    'Color Pop Punch',
    FilterCategory.artistic,
    [
      1.30, -0.10, -0.05, 0.0, 0.0,
     -0.05,  1.25, -0.05, 0.0, 0.0,
     -0.05, -0.05,  1.30, 0.0, 0.0,
      0.00,  0.00,  0.00, 1.0, 0.0,
    ],
  ),

  matte(
    'Matte',
    'Velvet Editorial',
    FilterCategory.vintage,
    [
      0.90, 0.05, 0.05, 0.0, 30.0,
      0.05, 0.90, 0.05, 0.0, 25.0,
      0.05, 0.05, 0.88, 0.0, 25.0,
      0.00, 0.00, 0.00, 1.0,  0.0,
    ],
  ),

  urban(
    'Urban',
    'Street Neo Dark',
    FilterCategory.cool,
    [
      1.05, 0.00, 0.00, 0.0, -5.0,
      0.00, 0.92, 0.00, 0.0, -8.0,
      0.05, 0.05, 1.20, 0.0, 12.0,
      0.00, 0.00, 0.00, 1.0,  0.0,
    ],
  ),

  arctic(
    'Arctic',
    'Glacier Frost',
    FilterCategory.cool,
    [
      0.75, 0.00, 0.05, 0.0, -10.0,
      0.00, 0.98, 0.10, 0.0,  10.0,
      0.00, 0.05, 1.35, 0.0,  35.0,
      0.00, 0.00, 0.00, 1.0,   0.0,
    ],
  ),

  summer(
    'Summer',
    'Sunlit Ocean',
    FilterCategory.warm,
    [
      1.18, 0.05, 0.00, 0.0,  15.0,
      0.00, 1.10, 0.00, 0.0,  12.0,
      0.00, 0.00, 1.05, 0.0,  -5.0,
      0.00, 0.00, 0.00, 1.0,   0.0,
    ],
  ),

  dramatic(
    'Dramatic',
    'High Impact Contrast',
    FilterCategory.cinematic,
    [
      1.35, -0.05, -0.05, 0.0, -25.0,
     -0.05,  1.30, -0.05, 0.0, -25.0,
     -0.05, -0.05,  1.25, 0.0, -20.0,
      0.00,  0.00,  0.00, 1.0,   0.0,
    ],
  ),

  cyberpunk(
    'Cyberpunk',
    'Neon Future Synth',
    FilterCategory.artistic,
    [
      1.25, 0.00, 0.10, 0.0,  20.0,
      0.00, 0.75, 0.00, 0.0, -20.0,
      0.10, 0.00, 1.45, 0.0,  35.0,
      0.00, 0.00, 0.00, 1.0,   0.0,
    ],
  ),

  emerald(
    'Emerald',
    'Lush Jade Forest',
    FilterCategory.artistic,
    [
      0.85, 0.00, 0.00, 0.0, -10.0,
      0.05, 1.25, 0.05, 0.0,  20.0,
      0.00, 0.05, 0.95, 0.0,   5.0,
      0.00, 0.00, 0.00, 1.0,   0.0,
    ],
  ),

  amber(
    'Amber',
    'Honey Radiance',
    FilterCategory.warm,
    [
      1.22, 0.08,  0.00, 0.0,  25.0,
      0.02, 1.08,  0.00, 0.0,  14.0,
      0.00, 0.00,  0.68, 0.0, -25.0,
      0.00, 0.00,  0.00, 1.0,   0.0,
    ],
  ),

  pastel(
    'Pastel',
    'Soft Candy Hues',
    FilterCategory.artistic,
    [
      1.05, 0.08, 0.08, 0.0, 30.0,
      0.08, 1.05, 0.08, 0.0, 30.0,
      0.08, 0.08, 1.08, 0.0, 35.0,
      0.00, 0.00, 0.00, 1.0,  0.0,
    ],
  );

  final String label;
  final String subtitle;
  final FilterCategory category;
  final List<double> matrix;

  const FilterType(this.label, this.subtitle, this.category, this.matrix);

  /// Identity color matrix (neutral 1:1 color pass-through)
  static const List<double> identityMatrix = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  /// Interpolate between the identity matrix (intensity 0.0) and the preset matrix (intensity 1.0)
  List<double> getInterpolatedMatrix(double intensity) {
    if (matrix.isEmpty) return identityMatrix;
    final t = intensity.clamp(0.0, 1.0);
    if (t >= 0.999) return matrix;
    if (t <= 0.001) return identityMatrix;

    final result = List<double>.filled(20, 0.0);
    for (int i = 0; i < 20; i++) {
      final isDiag = (i == 0 || i == 6 || i == 12 || i == 18);
      final identityVal = isDiag ? 1.0 : 0.0;
      result[i] = identityVal + (matrix[i] - identityVal) * t;
    }
    return result;
  }

  /// Get ColorFilter scaled by intensity (0.0 = original, 1.0 = 100% full effect)
  ColorFilter? getColorFilter([double intensity = 1.0]) {
    if (this == FilterType.none || matrix.isEmpty) return null;
    final t = intensity.clamp(0.0, 1.0);
    if (t <= 0.001) return null;
    return ColorFilter.matrix(getInterpolatedMatrix(t));
  }

  /// Full 100% color filter for backward compatibility
  ColorFilter? get colorFilter => getColorFilter(1.0);

  /// Safe lookup from serialized string
  static FilterType fromString(String? val) {
    if (val == null || val.isEmpty) return FilterType.none;
    // Backward compatibility mappings
    if (val == 'monochrome') return FilterType.bw;
    if (val == 'warmSunset') return FilterType.sunset;
    if (val == 'vibrant') return FilterType.vivid;

    return FilterType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => FilterType.none,
    );
  }
}
