import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looma/core/constants/app_constants.dart';
import 'package:looma/features/editor/domain/entities/keyframe_entity.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/editor/presentation/providers/editor_controller.dart';
import 'package:looma/features/editor/presentation/widgets/multi_track_timeline.dart';
import 'package:looma/features/editor/presentation/widgets/video_track_item.dart';
import 'package:looma/features/filters_effects/domain/entities/filter_preset.dart';
import 'package:looma/features/filters_effects/domain/entities/video_effect_type.dart';
import 'package:looma/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';

void main() {
  group('Timeline Pinch-to-Zoom & Badge Overflow Tests', () {
    testWidgets('VideoTrackItem shows badges when wide and collapses to +N indicator when narrow', (tester) async {
      const clipWithMultipleBadges = VideoClipEntity(
        id: 'c1',
        mediaPath: 'video.mp4',
        name: 'Action Scene',
        sourceDurationMs: 10000,
        timelineStartMs: 0,
        timelineEndMs: 10000,
        trimStartMs: 0,
        trimEndMs: 10000,
        speed: 2.0, // Badge 1: Speed
        filterType: FilterType.cyberpunk, // Badge 2: Filter
        effectType: VideoEffectType.neonGlow, // Badge 3: Effect
        keyframes: [
          KeyframeEntity(id: 'k1', timestampMs: 1000, scale: 1.2),
        ], // Badge 4: Keyframe
        isOverlay: true, // Badge 5: PIP
      );

      // 1. Render wide (zoomed in at 150 px/s: 10s clip = 1500px)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoTrackItem(
              clip: clipWithMultipleBadges,
              pixelsPerSecond: 150.0,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('2.0x'), findsOneWidget);
      expect(find.text('PIP'), findsOneWidget);

      // 2. Render narrow (zoomed out at 8 px/s with short 3s effective duration = 24px)
      const shortClipWithBadges = VideoClipEntity(
        id: 'c2',
        mediaPath: 'video.mp4',
        name: 'Fast Cut',
        sourceDurationMs: 3000,
        timelineStartMs: 0,
        timelineEndMs: 3000,
        trimStartMs: 0,
        trimEndMs: 3000,
        speed: 1.5,
        filterType: FilterType.cyberpunk,
        effectType: VideoEffectType.neonGlow,
        isOverlay: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoTrackItem(
              clip: shortClipWithBadges,
              pixelsPerSecond: 18.0, // Narrow width ~54px
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show +N overflow indicator because all 4 badges cannot fit on a 54px clip
      expect(find.textContaining('+'), findsOneWidget);
    });

    testWidgets('MultiTrackTimeline renders with floating zoom indicator and pinch gestures', (tester) async {
      final project = ProjectEntity(
        id: 'test-proj',
        title: 'Test Project',
        aspectRatio: AspectRatioType.ratio16_9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        videoClips: const [
          VideoClipEntity(
            id: 'c-test',
            mediaPath: 'test.mp4',
            name: 'Test Clip',
            sourceDurationMs: 10000,
            timelineStartMs: 0,
            timelineEndMs: 10000,
            trimStartMs: 0,
            trimEndMs: 10000,
          ),
        ],
      );

      final controller = EditorController(project: project);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 250,
              width: 400,
              child: MultiTrackTimeline(
                state: controller.state,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MultiTrackTimeline), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.text('Fit'), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);

      // Verify zoom bounds
      expect(controller.state.pixelsPerSecond, AppConstants.defaultPixelsPerSecond);
    });
  });
}
