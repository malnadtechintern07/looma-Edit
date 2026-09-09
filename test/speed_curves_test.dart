import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/editor/domain/entities/speed_curve_type.dart';

void main() {
  group('Speed Curve Types Tests', () {
    test('Standard curve returns 1.0 speed everywhere', () {
      expect(SpeedCurveType.none.getSpeedAtProgress(0.0), 1.0);
      expect(SpeedCurveType.none.getSpeedAtProgress(0.5), 1.0);
      expect(SpeedCurveType.none.getSpeedAtProgress(1.0), 1.0);
      expect(SpeedCurveType.none.getSourceProgressAtTimelineProgress(0.0), 0.0);
      expect(SpeedCurveType.none.getSourceProgressAtTimelineProgress(0.5), 0.5);
      expect(SpeedCurveType.none.getSourceProgressAtTimelineProgress(1.0), 1.0);
      expect(SpeedCurveType.none.averageSpeedMultiplier, 1.0);
    });

    test('Montage curve produces fast-slow-fast ramping and valid source progress', () {
      expect(SpeedCurveType.montage.getSpeedAtProgress(0.1), 2.5);
      expect(SpeedCurveType.montage.getSpeedAtProgress(0.5), 0.4);
      expect(SpeedCurveType.montage.getSpeedAtProgress(0.9), 2.5);
      expect(SpeedCurveType.montage.getSourceProgressAtTimelineProgress(0.0), 0.0);
      expect(SpeedCurveType.montage.getSourceProgressAtTimelineProgress(1.0), closeTo(1.0, 0.01));
      expect(SpeedCurveType.montage.averageSpeedMultiplier, greaterThan(1.0));
    });

    test('Hero curve produces slow motion climax at midpoint and valid source progress', () {
      expect(SpeedCurveType.hero.getSpeedAtProgress(0.1), 1.2);
      expect(SpeedCurveType.hero.getSpeedAtProgress(0.5), 0.25);
      expect(SpeedCurveType.hero.getSpeedAtProgress(0.9), 1.2);
      expect(SpeedCurveType.hero.getSourceProgressAtTimelineProgress(0.0), 0.0);
      expect(SpeedCurveType.hero.getSourceProgressAtTimelineProgress(1.0), closeTo(1.0, 0.01));
    });

    test('Bullet curve accelerates before and after slow middle and valid source progress', () {
      expect(SpeedCurveType.bullet.getSpeedAtProgress(0.2), 3.5);
      expect(SpeedCurveType.bullet.getSpeedAtProgress(0.5), 0.2);
      expect(SpeedCurveType.bullet.getSpeedAtProgress(0.8), 3.5);
      expect(SpeedCurveType.bullet.getSourceProgressAtTimelineProgress(0.0), 0.0);
      expect(SpeedCurveType.bullet.getSourceProgressAtTimelineProgress(1.0), closeTo(1.0, 0.01));
    });
  });
}
