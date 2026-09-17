import 'package:procut/core/config/server_config.dart';
import 'package:procut/core/network/api_client.dart';
import '../domain/entities/ai_video_preset_entity.dart';

class AiVideoPresetsData {
  static List<String> get categories {
    final set = <String>{'All', 'Trending', 'Cinematic', 'Sci-Fi & Cyberpunk', 'Popular', 'Nature & Travel'};
    for (final p in _cachedPresets) {
      if (p.category.trim().isNotEmpty) {
        set.add(p.category.trim());
      }
    }
    return set.toList();
  }

  static List<AiVideoPresetEntity> _cachedPresets = presets;

  static List<AiVideoPresetEntity> get currentPresets => _cachedPresets;

  static Future<List<AiVideoPresetEntity>> fetchServerPresets() async {
    try {
      final baseUrl = await ServerConfig.getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/ai/presets?type=video');
      final res = await ApiClient.get(uri);
      if (res.isOk && res.json is Map) {
        final json = res.json as Map<String, dynamic>;
        final listRaw = json['presets'] as List<dynamic>? ?? [];
        if (listRaw.isNotEmpty) {
          final fetched = listRaw.map((p) {
            var videoUrl = p['preview_video_url'] as String? ?? '';
            if (videoUrl.isNotEmpty) {
              if (videoUrl.startsWith('/')) {
                videoUrl = '$baseUrl$videoUrl';
              } else if (videoUrl.contains('localhost:5050') || videoUrl.contains('127.0.0.1:5050')) {
                videoUrl = videoUrl.replaceAll(RegExp(r'http://(localhost|127\.0\.0\.1):5050'), baseUrl);
              }
            }
            final tagsRaw = p['tags'] as String? ?? '';
            final tags = tagsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            return AiVideoPresetEntity(
              id: p['id']?.toString() ?? '',
              title: p['title'] as String? ?? 'AI Video Preset',
              category: p['category'] as String? ?? 'Trending',
              videoAssetPath: videoUrl.isNotEmpty ? videoUrl : 'assets/demo/cyberpunk_arcade.mp4',
              prompt: p['prompt'] as String? ?? '',
              negativePrompt: p['negative_prompt'] as String? ?? 'blurry, low resolution, artifacts',
              durationText: p['duration_text'] as String? ?? '5s',
              style: p['style'] as String? ?? 'Cinematic Photorealism',
              modelName: p['model_name'] as String? ?? 'OpenAI Sora',
              cameraMovement: p['camera_movement'] as String? ?? 'Smooth Cinematic Dolly',
              lighting: p['lighting'] as String? ?? 'Volumetric Atmospheric',
              seed: p['seed'] as String? ?? '8492019',
              tags: tags.isNotEmpty ? tags : ['AI Video', 'Cinematic', '4K'],
            );
          }).toList();
          _cachedPresets = fetched;
          return fetched;
        }
      }
    } catch (_) {}
    return _cachedPresets;
  }

  static const List<AiVideoPresetEntity> presets = [
    AiVideoPresetEntity(
      id: 'video_cyberpunk_arcade',
      title: 'Neo-Tokyo Arcade 2088',
      category: 'Trending',
      videoAssetPath: 'assets/demo/cyberpunk_arcade.mp4',
      durationText: '5s',
      modelName: 'Runway Gen-3 Alpha',
      style: 'Cyberpunk Photorealism',
      cameraMovement: 'Tracking Dolly Forward, Anamorphic Flare',
      lighting: 'Volumetric Neon Magenta & Electric Cyan',
      seed: '78420194',
      tags: ['Cyberpunk', 'Neon', 'Sci-Fi', 'Arcade', 'Tokyo'],
      prompt:
          'Cinematic 8k hyperrealistic tracking shot gliding through a futuristic Tokyo retro arcade bathed in neon magenta and cyan lighting, rain drops dripping from neon signs, holographic displays flickering, reflective wet pavement, anamorphic lens flare, 60fps photorealism.',
      negativePrompt:
          'cartoonish, blurry, low resolution, flickering artifacts, distorted anatomy, jittery motion, watermark',
    ),
    AiVideoPresetEntity(
      id: 'video_alps_drone',
      title: 'Alpine Peak FPV Swoop',
      category: 'Nature & Travel',
      videoAssetPath: 'assets/demo/alps_drone.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora',
      style: 'Cinematic Landscape FPV',
      cameraMovement: 'Ultra-wide High-Speed FPV Drone Dive',
      lighting: 'Golden Dawn Rim Light, Alpenglow',
      seed: '91823746',
      tags: ['Alps', 'Drone', 'Mountains', 'Nature', 'Cinematic'],
      prompt:
          'Breathtaking ultra-wide FPV drone swoop over snow-capped Swiss Alpine jagged mountain peaks at sunrise, crisp morning mist swirling in valleys, golden warm rim lighting on fresh powder, 8k resolution, cinematic National Geographic color grading.',
      negativePrompt:
          'overexposed, CGI look, pixelated, jitter, stuttering motion, washed out, watermark',
    ),
    AiVideoPresetEntity(
      id: 'video_ramen_bar',
      title: 'Midnight Ramen Counter',
      category: 'Trending',
      videoAssetPath: 'assets/demo/ramen_bar.mp4',
      durationText: '5s',
      modelName: 'Luma Dream Machine',
      style: 'Warm Cinematic Documentary',
      cameraMovement: 'Slow Cinematic Push-In with Shallow DOF',
      lighting: 'Warm Tungsten & Paper Lantern Glow',
      seed: '33490218',
      tags: ['Ramen', 'Tokyo', 'Food', 'Cozy', 'Atmospheric'],
      prompt:
          'Cozy Japanese midnight noodle bar in Shinjuku, steam gently rising from rich tonkotsu ramen bowls, warm paper lantern illumination, soft depth of field bokeh, chef slicing scallions in background, highly detailed 4k cinematic footage.',
      negativePrompt:
          'flat lighting, noise, artifacts, static camera, synthetic CGI sheen, bad anatomy',
    ),
    AiVideoPresetEntity(
      id: 'video_tokyo_shinjuku',
      title: 'Rainy Shinjuku Hyperlapse',
      category: 'Sci-Fi & Cyberpunk',
      videoAssetPath: 'assets/demo/tokyo_shinjuku.mp4',
      durationText: '5s',
      modelName: 'Kling AI 1.5',
      style: 'Urban Cyberpunk Hyperlapse',
      cameraMovement: 'Dynamic Gimbal Forward Hyperlapse',
      lighting: 'Vibrant Neon Reflections on Wet Asphalt',
      seed: '62719403',
      tags: ['Rain', 'Shinjuku', 'Tokyo', 'Hyperlapse', 'Reflections'],
      prompt:
          'Nighttime hyperlapse walking through dense Shinjuku neon corridor under heavy rain, umbrellas reflecting neon billboards in puddles, vibrant purple and turquoise color cast, smooth gimbal motion, photorealistic reflections.',
      negativePrompt:
          'shaky camera, jump cuts, digital noise, muddy shadows, low resolution, compression artifacts',
    ),
    AiVideoPresetEntity(
      id: 'video_urban_skate',
      title: 'Golden Hour Urban Skater',
      category: 'Popular',
      videoAssetPath: 'assets/demo/urban_skate.mp4',
      durationText: '5s',
      modelName: 'Pika 2.0 Pro',
      style: 'Action Sports 120fps Slow-Mo',
      cameraMovement: 'Low-Angle Follow Cam, Smooth Tracking',
      lighting: 'Warm Golden Hour Sunburst Flare',
      seed: '45028194',
      tags: ['Skate', 'Golden Hour', 'Slow Motion', 'Urban', 'Action'],
      prompt:
          'Dynamic low-angle follow cam tracking a skater doing a kickflip on sunlit concrete promenade during golden hour, cinematic motion blur, sun flare passing through trees, high frame rate slow-motion 120fps.',
      negativePrompt:
          'jerky camera, unnatural physics, broken motion, cartoon render, watermark, blurriness',
    ),
    AiVideoPresetEntity(
      id: 'video_alps_sunrise',
      title: 'Ocean of Clouds Sunrise',
      category: 'Cinematic',
      videoAssetPath: 'assets/demo/alps_sunrise.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora',
      style: 'Majestic Time-Lapse',
      cameraMovement: 'Slow Pan Across Cloud Inversion',
      lighting: 'Radiant Amber Sunrise Piercing Clouds',
      seed: '19283740',
      tags: ['Sunrise', 'Clouds', 'Nature', 'Time-lapse', 'Ethereal'],
      prompt:
          'Time-lapse of golden dawn breaking over an ocean of fluffy stratocumulus clouds seen from mountain summit, radiant amber sun rays piercing through clouds, serene heavenly atmosphere, crystal clear 8k.',
      negativePrompt:
          'banding, noisy sky, flickering light, unnatural clouds, low frame rate, watermark',
    ),
    AiVideoPresetEntity(
      id: 'video_tokyo_street',
      title: 'Neon Izakaya Alleyway',
      category: 'Popular',
      videoAssetPath: 'assets/demo/tokyo_street.mp4',
      durationText: '5s',
      modelName: 'Runway Gen-3 Alpha',
      style: '35mm Film Cinematic Street',
      cameraMovement: 'Wide Angle Slow Drift Through Alley',
      lighting: 'Paper Lantern Warmth & Distant Street Neon',
      seed: '81726354',
      tags: ['Street', 'Tokyo', 'Izakaya', 'Atmospheric', 'Cinematic'],
      prompt:
          'Street level wide shot of bustling pedestrian alley lined with izakayas, illuminated paper lanterns, pedestrians walking past steam vents, rich vibrant Tokyo street life, cinematic 35mm film grain.',
      negativePrompt:
          'deformed faces, static mannequins, muddy blacks, oversaturation, blur',
    ),
    AiVideoPresetEntity(
      id: 'video_cosmic_hyperdrive',
      title: 'Cosmic Hyperdrive Jump',
      category: 'Sci-Fi & Cyberpunk',
      videoAssetPath: 'assets/demo/overlay_vid.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora 2.0',
      style: 'Interstellar Hard Sci-Fi',
      cameraMovement: 'Accelerating Cockpit Push-In to Light Speed Warp',
      lighting: 'Neon Blue Tachyon Glow & Starlight Streaks',
      seed: '59201948',
      tags: ['Cosmic', 'Space', 'Warp Speed', 'Sci-Fi', 'Galaxy'],
      prompt:
          'POV camera inside a sleek futuristic starship cockpit accelerating through an asteroid field into a vibrant hyperdrive warp jump, cyan starlight streaks warping past the canopy, reflections dancing across holographic pilot gauges, 8k IMAX cinematic fidelity.',
      negativePrompt:
          'low-poly, flat lighting, jittery stars, blurry cockpit, amateur CGI, watermark',
    ),
    AiVideoPresetEntity(
      id: 'video_neon_puddle_reflection',
      title: 'Cyberpunk Puddle Reflections',
      category: 'Sci-Fi & Cyberpunk',
      videoAssetPath: 'assets/demo/tokyo_shinjuku.mp4',
      durationText: '5s',
      modelName: 'Kling AI 1.5',
      style: 'Dark Atmospheric Cyberpunk',
      cameraMovement: 'Extreme Macro Low-Angle Tilt-Up',
      lighting: 'Reflective Neon Magenta, Emerald, and Gold',
      seed: '30491823',
      tags: ['Cyberpunk', 'Rain', 'Reflections', 'Tokyo', 'Atmosphere'],
      prompt:
          'Extreme macro cinematic camera skimming just millimeters above a rain puddle on wet Tokyo asphalt, reflecting towering holographic billboards in pink and cyan, raindrops creating concentric shockwave ripples, seamless tilt-up to futuristic skyline, 60fps.',
      negativePrompt:
          'dirty camera lens, digital grain noise, poor motion physics, distorted reflections, watermark',
    ),
    AiVideoPresetEntity(
      id: 'video_alpine_helicopter_orbit',
      title: 'Matterhorn Helicopter Orbit',
      category: 'Nature & Travel',
      videoAssetPath: 'assets/demo/alps_drone.mp4',
      durationText: '5s',
      modelName: 'Runway Gen-3 Alpha',
      style: 'National Geographic Aerial 8K',
      cameraMovement: '360-Degree Helicopter Gyro-Stabilized Orbit',
      lighting: 'Crisp Glacial Sunlight & Powder Snow Glint',
      seed: '44819203',
      tags: ['Matterhorn', 'Alps', 'Snow', 'Aerial', 'Travel'],
      prompt:
          'Sweeping gyro-stabilized aerial orbit around the knife-edge jagged ridge of the Matterhorn summit, billowing snow powder blowing off crests in high altitude wind, dazzling sunlight catching ice crystal glints, ultra photorealistic 8k landscape cinematography.',
      negativePrompt:
          'choppy frame rate, compression artifacts, flat mountains, unnatural snow color, oversaturated sky',
    ),
    AiVideoPresetEntity(
      id: 'video_sunset_boulevard_cruise',
      title: 'Sunset Boulevard Lowrider',
      category: 'Popular',
      videoAssetPath: 'assets/demo/urban_skate.mp4',
      durationText: '5s',
      modelName: 'Luma Dream Machine',
      style: 'West Coast Nostalgic 70mm',
      cameraMovement: 'Parallel Wheel-Level Tracking Shot',
      lighting: 'Golden Hour Palm Tree Silhouettes & Lens Flares',
      seed: '71930284',
      tags: ['Sunset', 'California', 'Golden Hour', 'Vintage', 'Cinematic'],
      prompt:
          'Low-angle tracking camera cruising alongside a vintage chrome car down palm tree-lined boulevard in Los Angeles during vivid golden hour sunset, warm orange sunlight flaring through spoke wheels, warm breeze blowing, Kodak Portra 400 film aesthetic.',
      negativePrompt:
          'blown out highlights, muddy shadows, stuttering car wheels, digital artifacts, blur',
    ),
    AiVideoPresetEntity(
      id: 'video_quantum_portal_chamber',
      title: 'Quantum Portal Chamber',
      category: 'Sci-Fi & Cyberpunk',
      videoAssetPath: 'assets/demo/cyberpunk_arcade.mp4',
      durationText: '5s',
      modelName: 'Pika 2.0 Pro',
      style: 'Futuristic Quantum Physics Lab',
      cameraMovement: 'Slow Steadicam Orbit Around Energy Ring',
      lighting: 'Pulsing Violet Plasma & Volumetric Smoke',
      seed: '18492034',
      tags: ['Portal', 'Sci-Fi', 'Quantum', 'VFX', 'Futuristic'],
      prompt:
          'Cinematic camera orbiting a massive electromagnetic circular ring activating a quantum portal, swirling vortex of violet and turquoise plasma energy crackling with electric arcs, scientists in hazard suits watching from steel catwalks, Unreal Engine 5 render style.',
      negativePrompt:
          'flat textures, broken lightning geometry, poor smoke simulation, cartoon look, low frame rate',
    ),
    AiVideoPresetEntity(
      id: 'video_tokyo_night_walk',
      title: 'Sakura Petals Night Drift',
      category: 'Trending',
      videoAssetPath: 'assets/demo/tokyo_street.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora',
      style: 'Ethereal Japanese Cinematic Poetry',
      cameraMovement: 'Gentle Dolly Drift Down Canal Walkway',
      lighting: 'Soft Pink Paper Lanterns & Canal Reflections',
      seed: '88392019',
      tags: ['Sakura', 'Tokyo', 'Cherry Blossom', 'Night', 'Aesthetic'],
      prompt:
          'Ethereal night shot gliding along Meguro River canal in Tokyo during cherry blossom season, glowing pink paper lanterns hanging over water, illuminated sakura petals softly fluttering down like snow, deep emerald canal reflections, masterwork cinematic mood.',
      negativePrompt:
          'synthetic flowers, unnatural petal physics, bad lighting, blur, artifacts, glitch',
    ),
  ];
}
