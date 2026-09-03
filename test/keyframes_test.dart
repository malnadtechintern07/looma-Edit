import 'package:flutter_test/flutter_test.dart';
import 'package:looma/features/editor/domain/entities/keyframe_entity.dart';

void main() {
  group('Keyframe Interpolation Tests', () {
    const baseValues = KeyframeValues(
      posX: 0.0,
      posY: 0.0,
      scale: 1.0,
      rotation: 0.0,
      opacity: 1.0,
    );

    test('Returns base values when keyframes list is empty', () {
      final result = KeyframeInterpolator.interpolate(
        keyframes: const [],
        currentOffsetMs: 1500,
        baseValues: baseValues,
      );

      expect(result.posX, 0.0);
      expect(result.scale, 1.0);
      expect(result.opacity, 1.0);
    });

    test('Returns first keyframe values when current time is before first keyframe', () {
      final keyframes = [
        const KeyframeEntity(
          id: 'k1',
          timestampMs: 1000,
          posX: 50.0,
          scale: 1.5,
          opacity: 0.8,
        ),
        const KeyframeEntity(
          id: 'k2',
          timestampMs: 3000,
          posX: 150.0,
          scale: 2.0,
          opacity: 0.5,
        ),
      ];

      final result = KeyframeInterpolator.interpolate(
        keyframes: keyframes,
        currentOffsetMs: 500,
        baseValues: baseValues,
      );

      expect(result.posX, 50.0);
      expect(result.scale, 1.5);
      expect(result.opacity, 0.8);
    });

    test('Returns last keyframe values when current time is after last keyframe', () {
      final keyframes = [
        const KeyframeEntity(
          id: 'k1',
          timestampMs: 1000,
          posX: 50.0,
          scale: 1.5,
        ),
        const KeyframeEntity(
          id: 'k2',
          timestampMs: 3000,
          posX: 150.0,
          scale: 2.0,
        ),
      ];

      final result = KeyframeInterpolator.interpolate(
        keyframes: keyframes,
        currentOffsetMs: 4000,
        baseValues: baseValues,
      );

      expect(result.posX, 150.0);
      expect(result.scale, 2.0);
    });

    test('Interpolates smoothly between two keyframes at midpoint', () {
      final keyframes = [
        const KeyframeEntity(
          id: 'k1',
          timestampMs: 1000,
          posX: 0.0,
          scale: 1.0,
          opacity: 1.0,
        ),
        const KeyframeEntity(
          id: 'k2',
          timestampMs: 3000,
          posX: 100.0,
          scale: 2.0,
          opacity: 0.0,
        ),
      ];

      final result = KeyframeInterpolator.interpolate(
        keyframes: keyframes,
        currentOffsetMs: 2000, // exact midpoint
        baseValues: baseValues,
      );

      // Smooth cosine ease reaches 50% at midpoint
      expect(result.posX, closeTo(50.0, 0.1));
      expect(result.scale, closeTo(1.5, 0.1));
      expect(result.opacity, closeTo(0.5, 0.1));
    });
  });
}
