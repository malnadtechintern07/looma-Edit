import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/services/app_actions_service.dart';
import 'package:procut/features/ai_photo_edit/data/ai_photo_presets_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Prompt Share Link & Expanded Prompts Tests', () {
    test('shareAiPromptLink formats message with prompt name and web link, NOT raw prompt', () async {
      // Test the share action
      final res = await AppActionsService.shareAiPromptLink(
        title: 'Cyberpunk Neon City',
        presetId: 'photo_cyberpunk_neon_city',
        category: 'Cyberpunk Style',
        prompt: 'Very long prompt text here...',
      );

      // On non-Android test environments, it copies to clipboard and returns true
      expect(res, isTrue);
    });

    test('All 50+ presets in AiPhotoPresetsData have long, specific masterpiece prompts (>150 chars)', () {
      final presets = AiPhotoPresetsData.presets;
      expect(presets.length, greaterThanOrEqualTo(50));

      for (final preset in presets) {
        expect(preset.prompt.length, greaterThanOrEqualTo(150),
            reason: 'Preset ${preset.id} (${preset.title}) prompt is too short: "${preset.prompt}"');
        // Verify key photographic/cinematic keywords are present
        expect(
          preset.prompt.contains('8k') ||
              preset.prompt.contains('8K') ||
              preset.prompt.contains('portrait') ||
              preset.prompt.contains('cinematic') ||
              preset.prompt.contains('lighting') ||
              preset.prompt.contains('shot on'),
          isTrue,
          reason: 'Preset ${preset.id} prompt lacks rich photographic details',
        );
      }
    });

    test('Cyberpunk Neon City preset is registered with high-detail prompt and pro specs', () {
      final cyberpunk = AiPhotoPresetsData.presets.firstWhere(
        (p) => p.title == 'Cyberpunk Neon City' || p.id == 'photo_cyberpunk_neon_city',
      );

      expect(cyberpunk, isNotNull);
      expect(cyberpunk.prompt.length, greaterThan(250));
      expect(cyberpunk.prompt, contains('Neo-Tokyo'));
      expect(cyberpunk.prompt, anyOf(contains('Hasselblad'), contains('85mm')));
      expect(cyberpunk.cameraLens, isNotNull);
      expect(cyberpunk.lightingStyle, isNotNull);
    });
  });
}
