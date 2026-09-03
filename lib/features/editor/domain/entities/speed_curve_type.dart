enum SpeedCurveType {
  none,
  montage,
  hero,
  bullet,
  jumpCut,
  flashIn,
  flashOut,
}

extension SpeedCurveTypeExt on SpeedCurveType {
  String get label {
    switch (this) {
      case SpeedCurveType.none:
        return 'Standard';
      case SpeedCurveType.montage:
        return 'Montage (Fast-Slow-Fast)';
      case SpeedCurveType.hero:
        return 'Hero (Slow Mo Climax)';
      case SpeedCurveType.bullet:
        return 'Bullet Time';
      case SpeedCurveType.jumpCut:
        return 'Jump Cut';
      case SpeedCurveType.flashIn:
        return 'Flash In';
      case SpeedCurveType.flashOut:
        return 'Flash Out';
    }
  }

  /// Calculates dynamic speed multiplier at a given progress (0.0 to 1.0) along the clip
  double getSpeedAtProgress(double progress) {
    final t = progress.clamp(0.0, 1.0);
    switch (this) {
      case SpeedCurveType.none:
        return 1.0;
      case SpeedCurveType.montage:
        // 2.5x -> 0.4x -> 2.5x
        if (t < 0.3) return 2.5;
        if (t > 0.7) return 2.5;
        return 0.4;
      case SpeedCurveType.hero:
        // 1.2x -> 0.25x -> 1.2x
        if (t >= 0.35 && t <= 0.65) return 0.25;
        return 1.2;
      case SpeedCurveType.bullet:
        // 3.5x -> 0.2x -> 3.5x
        if (t >= 0.4 && t <= 0.6) return 0.2;
        return 3.5;
      case SpeedCurveType.jumpCut:
        return (t * 10).toInt() % 2 == 0 ? 2.0 : 0.8;
      case SpeedCurveType.flashIn:
        return t < 0.3 ? 3.0 : 1.0;
      case SpeedCurveType.flashOut:
        return t > 0.7 ? 3.0 : 1.0;
    }
  }

  /// Average effective speed multiplier across the whole duration
  double get averageSpeedMultiplier {
    switch (this) {
      case SpeedCurveType.none:
        return 1.0;
      case SpeedCurveType.montage:
        return 1.66; // 0.3*2.5 + 0.4*0.4 + 0.3*2.5
      case SpeedCurveType.hero:
        return 0.915; // 0.35*1.2 + 0.30*0.25 + 0.35*1.2
      case SpeedCurveType.bullet:
        return 2.84; // 0.4*3.5 + 0.2*0.2 + 0.4*3.5
      case SpeedCurveType.jumpCut:
        return 1.4; // 0.5*2.0 + 0.5*0.8
      case SpeedCurveType.flashIn:
        return 1.6; // 0.3*3.0 + 0.7*1.0
      case SpeedCurveType.flashOut:
        return 1.6; // 0.7*1.0 + 0.3*3.0
    }
  }

  /// Maps timeline progress (0.0 to 1.0) to raw source video progress (0.0 to 1.0)
  /// by integrating the speed curve.
  double getSourceProgressAtTimelineProgress(double timelineProgress) {
    final t = timelineProgress.clamp(0.0, 1.0);
    switch (this) {
      case SpeedCurveType.none:
        return t;
      case SpeedCurveType.montage:
        if (t <= 0.3) {
          return (2.5 * t) / 1.66;
        } else if (t <= 0.7) {
          return (0.75 + 0.4 * (t - 0.3)) / 1.66;
        } else {
          return (0.91 + 2.5 * (t - 0.7)) / 1.66;
        }
      case SpeedCurveType.hero:
        if (t <= 0.35) {
          return (1.2 * t) / 0.915;
        } else if (t <= 0.65) {
          return (0.42 + 0.25 * (t - 0.35)) / 0.915;
        } else {
          return (0.495 + 1.2 * (t - 0.65)) / 0.915;
        }
      case SpeedCurveType.bullet:
        if (t <= 0.4) {
          return (3.5 * t) / 2.84;
        } else if (t <= 0.6) {
          return (1.4 + 0.2 * (t - 0.4)) / 2.84;
        } else {
          return (1.44 + 3.5 * (t - 0.6)) / 2.84;
        }
      case SpeedCurveType.jumpCut:
        final segmentIndex = (t * 10).floor().clamp(0, 9);
        final segmentRemainder = t - (segmentIndex * 0.1);
        final evenCount = ((segmentIndex + 1) / 2).floor();
        final oddCount = (segmentIndex / 2).floor();
        final completedSum = (evenCount * 0.2) + (oddCount * 0.08);
        final currentRate = (segmentIndex % 2 == 0) ? 2.0 : 0.8;
        return ((completedSum + segmentRemainder * currentRate) / 1.4).clamp(0.0, 1.0);
      case SpeedCurveType.flashIn:
        if (t <= 0.3) {
          return (3.0 * t) / 1.6;
        } else {
          return (0.9 + 1.0 * (t - 0.3)) / 1.6;
        }
      case SpeedCurveType.flashOut:
        if (t <= 0.7) {
          return (1.0 * t) / 1.6;
        } else {
          return (0.7 + 3.0 * (t - 0.7)) / 1.6;
        }
    }
  }
}
