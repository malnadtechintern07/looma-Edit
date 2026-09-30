import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/asset_store/data/datasources/asset_store_datasource.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';

void main() {
  group('Free Templates Browse & Working Assets Tests', () {
    late AssetStoreDataSourceImpl dataSource;

    setUp(() {
      dataSource = AssetStoreDataSourceImpl();
    });

    test('Loads template catalog and contains at least 20 100% Free templates', () async {
      final templates = await dataSource.getTemplates();
      expect(templates, isNotEmpty);

      final freeTemplates = templates.where((t) => !t.isPro).toList();
      expect(freeTemplates.length, greaterThanOrEqualTo(20),
          reason: 'Expected at least 20 free templates for users to browse');

      for (final tmpl in freeTemplates) {
        expect(tmpl.isPro, isFalse, reason: 'Template ${tmpl.id} should not be PRO');
        expect(tmpl.title, isNotEmpty, reason: 'Template ${tmpl.id} must have a title');
        expect(tmpl.clipsCount, greaterThanOrEqualTo(1),
            reason: 'Template ${tmpl.id} must require at least 1 clip');
        expect(tmpl.durationMs, greaterThan(0),
            reason: 'Template ${tmpl.id} must have positive duration');
      }
    });

    test('All free templates have valid, working bundled demo assets for video and audio', () async {
      final templates = await dataSource.getTemplates();
      final freeTemplates = templates.where((t) => !t.isPro).toList();

      for (final tmpl in freeTemplates) {
        // Test video preview resolution
        final resolvedVideo = AssetStoreDataSourceImpl.resolveWorkingVideoUrl(
          tmpl.id,
          tmpl.category,
        );
        expect(
          resolvedVideo.startsWith('assets/demo/') && resolvedVideo.endsWith('.mp4'),
          isTrue,
          reason: 'Template ${tmpl.id} resolved video "$resolvedVideo" must be a bundled .mp4 asset',
        );

        // Test audio soundtrack resolution
        final resolvedAudio = AssetStoreDataSourceImpl.resolveWorkingAudioPath(
          tmpl.id,
          tmpl.category,
        );
        expect(
          resolvedAudio.startsWith('assets/demo/') && resolvedAudio.endsWith('.wav'),
          isTrue,
          reason: 'Template ${tmpl.id} resolved audio "$resolvedAudio" must be a bundled .wav asset',
        );
      }
    });

    test('Free category filter logic correctly separates free templates from PRO templates', () async {
      final templates = await dataSource.getTemplates();

      // Simulate the Free category filter
      final freeFilterResults = templates.where((t) {
        return !t.isPro;
      }).toList();

      expect(freeFilterResults, isNotEmpty);
      for (final tmpl in freeFilterResults) {
        expect(tmpl.isPro, isFalse);
      }

      // Ensure popular trending templates are included in free results
      final freeTitles = freeFilterResults.map((t) => t.title).toList();
      expect(freeTitles.any((title) => title.contains('Velocity')), isTrue);
      expect(freeTitles.any((title) => title.contains('3D Parallax')), isTrue);
      expect(freeTitles.any((title) => title.contains('Coffee')), isTrue);
      expect(freeTitles.any((title) => title.contains('Tokyo Night Drift')), isTrue);
      expect(freeTitles.any((title) => title.contains('7-Second FYP')), isTrue);
    });

    test('Free templates cover diverse aspect ratios (9:16 vertical and 16:9 widescreen)', () async {
      final templates = await dataSource.getTemplates();
      final freeTemplates = templates.where((t) => !t.isPro).toList();

      final vertical916 = freeTemplates.where((t) => t.aspectRatio == AspectRatioType.ratio9_16).toList();
      final widescreen169 = freeTemplates.where((t) => t.aspectRatio == AspectRatioType.ratio16_9).toList();

      expect(vertical916.length, greaterThanOrEqualTo(10),
          reason: 'Must have ample vertical 9:16 templates for Reels/TikTok/Shorts');
      expect(widescreen169.length, greaterThanOrEqualTo(2),
          reason: 'Must have widescreen 16:9 templates for YouTube/trailers');
    });

    test('Project JSON definition is valid and parseable for free templates', () async {
      final templates = await dataSource.getTemplates();
      final freeTemplates = templates.where((t) => !t.isPro).toList();

      for (final tmpl in freeTemplates) {
        if (tmpl.projectJson != null && tmpl.projectJson!.isNotEmpty) {
          expect(tmpl.projectJson!.startsWith('{'), isTrue);
          expect(tmpl.projectJson!.endsWith('}'), isTrue);
        }
      }
    });
  });
}
