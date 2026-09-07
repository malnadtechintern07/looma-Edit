import 'dart:math';

/// Helper utility for dynamic multi-lane timeline layout calculation.
///
/// Ensures clips on the same track that overlap in time are rendered on separate
/// vertical lanes (rows) so they NEVER render on top of or obscure each other.
class TimelineLayoutHelper {
  /// Computes a non-overlapping vertical lane assignment (0, 1, 2...) for each clip in [items].
  ///
  /// Two clips in the same lane are guaranteed to never overlap in time:
  /// `max(startA, startB) >= min(endA, endB)`.
  ///
  /// [manualLanes] allows individual clips to prefer a specific lane (e.g. user moved to lane 1).
  static Map<String, int> computeClipLanes<T>({
    required List<T> items,
    required int Function(T) getStart,
    required int Function(T) getEnd,
    required String Function(T) getId,
    Map<String, int> manualLanes = const {},
  }) {
    if (items.isEmpty) return {};

    final result = <String, int>{};
    final lanes = <int, List<({int start, int end, String id})>>{};

    // Sort items by timelineStartMs
    final sorted = List<T>.from(items)
      ..sort((a, b) => getStart(a).compareTo(getStart(b)));

    for (final item in sorted) {
      final id = getId(item);
      final start = getStart(item);
      final end = getEnd(item);
      final preferredLane = max(0, manualLanes[id] ?? 0);

      int targetLane = preferredLane;
      while (true) {
        final existingInLane = lanes[targetLane] ?? [];
        final hasOverlap = existingInLane.any((other) {
          // Range [start, end) overlaps [other.start, other.end) if max(start, other.start) < min(end, other.end)
          return max(start, other.start) < min(end, other.end);
        });

        if (!hasOverlap) {
          lanes.putIfAbsent(targetLane, () => []).add((start: start, end: end, id: id));
          result[id] = targetLane;
          break;
        }
        targetLane++;
      }
    }

    return result;
  }

  /// Calculates total track height from lane assignments.
  static double calculateTrackHeight({
    required Map<String, int> lanes,
    required double laneHeight,
    double laneGap = 4.0,
  }) {
    if (lanes.isEmpty) return laneHeight;
    final maxLane = lanes.values.reduce(max);
    final totalLanes = maxLane + 1;
    return totalLanes * laneHeight + (totalLanes - 1) * laneGap;
  }

  /// Computes the horizontal left and right movement bounds for a clip on its lane.
  /// Stops cleanly at adjacent clip edges to prevent overlapping or pushing clips to lower lanes.
  static ({int minStartMs, int? maxStartMs}) computeLaneBounds<T>({
    required String clipId,
    required int currentStartMs,
    required int currentDurationMs,
    required List<T> items,
    required int Function(T) getStart,
    required int Function(T) getEnd,
    required String Function(T) getId,
    Map<String, int> manualLanes = const {},
  }) {
    final lanes = computeClipLanes(
      items: items,
      getStart: getStart,
      getEnd: getEnd,
      getId: getId,
      manualLanes: manualLanes,
    );
    final clipLane = lanes[clipId] ?? (manualLanes[clipId] ?? 0);
    final currentEndMs = currentStartMs + currentDurationMs;

    int minStart = 0;
    int? maxStart;

    for (final other in items) {
      final otherId = getId(other);
      if (otherId == clipId) continue;
      final otherLane = lanes[otherId] ?? (manualLanes[otherId] ?? 0);
      if (otherLane != clipLane) continue;

      final otherStart = getStart(other);
      final otherEnd = getEnd(other);

      if (otherEnd <= currentStartMs) {
        if (otherEnd > minStart) {
          minStart = otherEnd;
        }
      } else if (otherStart >= currentEndMs) {
        final candidateMax = max(minStart, otherStart - currentDurationMs);
        if (maxStart == null || candidateMax < maxStart) {
          maxStart = candidateMax;
        }
      }
    }

    return (minStartMs: minStart, maxStartMs: maxStart);
  }

  /// Computes left and right handle trimming bounds for a clip on its lane.
  static ({int minTrimStartMs, int? maxTrimEndMs}) computeTrimBounds<T>({
    required String clipId,
    required int currentStartMs,
    required int currentEndMs,
    required List<T> items,
    required int Function(T) getStart,
    required int Function(T) getEnd,
    required String Function(T) getId,
    Map<String, int> manualLanes = const {},
  }) {
    final lanes = computeClipLanes(
      items: items,
      getStart: getStart,
      getEnd: getEnd,
      getId: getId,
      manualLanes: manualLanes,
    );
    final clipLane = lanes[clipId] ?? (manualLanes[clipId] ?? 0);

    int minTrimStart = 0;
    int? maxTrimEnd;

    for (final other in items) {
      final otherId = getId(other);
      if (otherId == clipId) continue;
      final otherLane = lanes[otherId] ?? (manualLanes[otherId] ?? 0);
      if (otherLane != clipLane) continue;

      final otherStart = getStart(other);
      final otherEnd = getEnd(other);

      if (otherEnd <= currentStartMs) {
        if (otherEnd > minTrimStart) {
          minTrimStart = otherEnd;
        }
      } else if (otherStart >= currentEndMs) {
        if (maxTrimEnd == null || otherStart < maxTrimEnd) {
          maxTrimEnd = otherStart;
        }
      }
    }

    return (minTrimStartMs: minTrimStart, maxTrimEndMs: maxTrimEnd);
  }
}
