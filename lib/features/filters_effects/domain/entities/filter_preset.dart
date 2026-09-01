import 'package:flutter/material.dart';

enum FilterType {
  none('Original', []),
  cinematic('Cinematic', [
    1.1, 0.0, 0.0, 0.0, 5.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.2, 0.0, 15.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]),
  vintage('Vintage 90s', [
    0.9, 0.0, 0.0, 0.0, 20.0,
    0.0, 0.8, 0.0, 0.0, 10.0,
    0.0, 0.0, 0.6, 0.0, -10.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]),
  cyberpunk('Cyberpunk', [
    1.2, 0.0, 0.0, 0.0, 10.0,
    0.0, 0.7, 0.0, 0.0, -20.0,
    0.0, 0.0, 1.4, 0.0, 30.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]),
  monochrome('Noir B&W', [
    0.33, 0.33, 0.33, 0.0, 0.0,
    0.33, 0.33, 0.33, 0.0, 0.0,
    0.33, 0.33, 0.33, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]),
  warmSunset('Warm Sunset', [
    1.3, 0.0, 0.0, 0.0, 25.0,
    0.0, 1.0, 0.0, 0.0, 10.0,
    0.0, 0.0, 0.8, 0.0, -15.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]),
  vibrant('Vibrant Pop', [
    1.2, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.2, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.2, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]);

  final String label;
  final List<double> matrix;

  const FilterType(this.label, this.matrix);

  ColorFilter? get colorFilter {
    if (matrix.isEmpty) return null;
    return ColorFilter.matrix(matrix);
  }

  static FilterType fromString(String? val) {
    return FilterType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => FilterType.none,
    );
  }
}
