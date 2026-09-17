import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/asset_store/domain/entities/store_template_entity.dart';
import 'package:procut/features/asset_store/data/datasources/asset_store_datasource.dart';
import 'package:procut/features/editor/domain/entities/transition_type.dart';
import 'package:procut/features/filters_effects/domain/entities/filter_preset.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';

void main() {
  group('25 Templates & Category System Tests', () {
    final expectedCategories = [
      'Birthday',
      'Wedding',
      'Travel',
      'Love Story',
      'Family',
      'Friends',
      'Birthday Slideshow',
      'Cinematic',
      'Beat Sync',
      'Reels',
      'Festival',
      'Graduation',
      'Before & After',
      '80s Retro',
      'Trending',
      'Photo Memories',
      'Fashion',
      'Celebration',
      'Business',
      'Motivation',
      'Nature',
      'Food',
      'Fitness',
      'Fast Transitions',
      'Viral/Short Video',
    ];

    test('All 25 distinct template categories are defined and covered in offline defaults', () async {
      final dataSource = AssetStoreDataSourceImpl();
      final templates = await dataSource.getTemplates();

      expect(templates.length, greaterThanOrEqualTo(25));

      final templateCategories = templates.map((t) => t.category).toSet();
      for (final cat in expectedCategories) {
        expect(
          templateCategories.contains(cat),
          isTrue,
          reason: 'Expected category "$cat" to be present in template dataset',
        );
      }
    });

    test('StoreTemplateEntity correctly holds category, badge, projectJson and flags', () {
      final sampleJson = jsonEncode({
        'id': 'tmpl-wedding',
        'title': '💍 Eternal Vows Wedding Film',
        'aspectRatio': 'ratio9_16',
        'durationMs': 15000,
        'videoClips': [
          {
            'id': 'c1',
            'mediaPath': 'assets/demo/alps_drone.mp4',
            'sourceDurationMs': 5000,
            'timelineStartMs': 0,
            'timelineEndMs': 5000,
            'filterType': 'vintage',
            'transitionIn': 'crossFade',
          }
        ],
        'audioClips': [],
        'textOverlays': [
          {
            'id': 't1',
            'text': 'Forever & Always 💍',
            'fontFamily': 'Inter',
            'fontSize': 26,
            'colorHex': 0xFFFFFFFF,
            'timelineStartMs': 0,
            'timelineEndMs': 7500,
            'animationType': 'fade',
          }
        ],
      });

      final tmpl = StoreTemplateEntity(
        id: 'tmpl-wedding',
        title: '💍 Eternal Vows Wedding Film',
        category: 'Wedding',
        badge: 'Romantic',
        description: 'Romantic wedding film',
        prompt: 'Luxury cinematic wedding teaser',
        author: 'Elegance Films',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 15000,
        clipsCount: 4,
        previewGradientStart: '0xFFD4AF37',
        previewGradientEnd: '0xFFF3E5AB',
        projectJson: sampleJson,
        isTrending: true,
        isNew: false,
        isPopular: true,
        isPro: true,
      );

      expect(tmpl.category, equals('Wedding'));
      expect(tmpl.badge, equals('Romantic'));
      expect(tmpl.isTrending, isTrue);
      expect(tmpl.isPopular, isTrue);
      expect(tmpl.isPro, isTrue);
      expect(tmpl.projectJson, isNotNull);

      // Verify deserialization from projectJson
      final decoded = jsonDecode(tmpl.projectJson!) as Map<String, dynamic>;
      final project = ProjectModel.fromJson(decoded);
      expect(project.title, equals('💍 Eternal Vows Wedding Film'));
      expect(project.videoClips.length, equals(1));
      expect(project.videoClips.first.filterType, equals(FilterType.vintage));
      expect(project.videoClips.first.transitionIn, equals(TransitionType.crossFade));
      expect(project.textOverlays.length, equals(1));
      expect(project.textOverlays.first.text, equals('Forever & Always 💍'));
    });

    test('Project creation from template JSON replaces media placeholders while preserving timings & transitions', () {
      final rawProjectJson = jsonEncode({
        'id': 'tmpl-beat-sync',
        'title': '⚡ Ultra Beat Drop Sync',
        'aspectRatio': 'ratio9_16',
        'durationMs': 8000,
        'videoClips': [
          {
            'id': 'c1',
            'mediaPath': 'placeholder_1.mp4',
            'name': 'Slot #1',
            'sourceDurationMs': 4000,
            'timelineStartMs': 0,
            'timelineEndMs': 4000,
            'filterType': 'cinematic',
            'transitionIn': 'zoomIn',
            'transitionDurationMs': 600,
            'speed': 1.25,
          },
          {
            'id': 'c2',
            'mediaPath': 'placeholder_2.mp4',
            'name': 'Slot #2',
            'sourceDurationMs': 4000,
            'timelineStartMs': 4000,
            'timelineEndMs': 8000,
            'filterType': 'vivid',
            'transitionIn': 'glitch',
            'transitionDurationMs': 500,
            'speed': 1.0,
          }
        ],
        'audioClips': [
          {
            'id': 'a1',
            'mediaPath': 'assets/demo/phonk_beat.wav',
            'title': 'Hardcore 808 Beat Drop',
            'timelineStartMs': 0,
            'timelineEndMs': 8000,
          }
        ],
        'textOverlays': [
          {
            'id': 't1',
            'text': 'DROP THE BASS ⚡',
            'fontFamily': 'Inter',
            'fontSize': 30,
            'colorHex': 0xFFFFFFFF,
            'timelineStartMs': 0,
            'timelineEndMs': 4000,
            'animationType': 'scale',
          }
        ]
      });

      final userFiles = ['/user/storage/clip_a.mp4', '/user/storage/clip_b.mp4'];

      // Simulate createProjectFromTemplate replacement logic
      final decoded = jsonDecode(rawProjectJson) as Map<String, dynamic>;
      final parsedProject = ProjectModel.fromJson(decoded);

      final updatedClips = <dynamic>[];
      for (int i = 0; i < parsedProject.videoClips.length; i++) {
        final base = parsedProject.videoClips[i];
        final userPath = userFiles[i];
        updatedClips.add(base.copyWith(
          id: 'new_id_$i',
          mediaPath: userPath,
          name: 'Slot #${i + 1} (${userPath.split('/').last})',
        ));
      }

      final resultProject = parsedProject.copyWith(
        id: 'new_project_uuid',
        title: 'My Beat Drop Video',
        videoClips: updatedClips.cast(),
        syncStatus: SyncStatusType.localOnly,
      );

      // Verify replaced media
      expect(resultProject.videoClips[0].mediaPath, equals('/user/storage/clip_a.mp4'));
      expect(resultProject.videoClips[1].mediaPath, equals('/user/storage/clip_b.mp4'));

      // Verify preserved timing and effects
      expect(resultProject.videoClips[0].timelineStartMs, equals(0));
      expect(resultProject.videoClips[0].timelineEndMs, equals(4000));
      expect(resultProject.videoClips[0].filterType, equals(FilterType.cinematic));
      expect(resultProject.videoClips[0].transitionIn, equals(TransitionType.zoomIn));
      expect(resultProject.videoClips[0].speed, equals(1.25));

      expect(resultProject.videoClips[1].timelineStartMs, equals(4000));
      expect(resultProject.videoClips[1].timelineEndMs, equals(8000));
      expect(resultProject.videoClips[1].filterType, equals(FilterType.vivid));
      expect(resultProject.videoClips[1].transitionIn, equals(TransitionType.glitch));

      // Verify preserved audio and text overlay
      expect(resultProject.audioClips.length, equals(1));
      expect(resultProject.audioClips.first.title, equals('Hardcore 808 Beat Drop'));
      expect(resultProject.textOverlays.length, equals(1));
      expect(resultProject.textOverlays.first.text, equals('DROP THE BASS ⚡'));
    });
  });
}
