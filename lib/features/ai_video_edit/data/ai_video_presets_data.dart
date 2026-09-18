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
              negativePrompt: p['negative_prompt'] as String? ?? 'blurry, low resolution, artifacts, distorted, watermark',
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
      cameraMovement: 'Continuous Tracking Dolly Forward with Anamorphic Flares',
      lighting: 'Volumetric Neon Magenta, Cyan Prismatic Glow & Wet Asphalt Bounce',
      seed: '78420194',
      tags: ['Cyberpunk', 'Neon', 'Sci-Fi', 'Arcade', 'Tokyo', '60fps', 'Blade Runner'],
      prompt:
          'Cinematic 8k photorealistic continuous tracking dolly shot gliding through a rain-drenched Neo-Tokyo retro-arcade alleyway in the year 2088. Volumetric neon magenta and electric cyan signage refracting through steam rising from pavement vents. Holographic CRT arcade cabinets flickering with 16-bit space combat visuals, casting dynamic geometric light onto passing cyborg pedestrians with chrome accents. Rain droplets beading and trickling across anamorphic camera lens. Masterwork shallow depth of field, ARRI Alexa 65 cinema camera, Cooke Anamorphic/i 40mm T2.3 lens, 60fps silky smooth motion, Blade Runner 2049 color science, hyper-detailed cyberpunk masterpiece.',
      negativePrompt:
          'cartoonish, blurry, low resolution, flickering artifacts, distorted anatomy, jittery motion, watermark, plastic textures',
    ),
    AiVideoPresetEntity(
      id: 'video_alps_drone',
      title: 'Alpine Peak FPV Swoop',
      category: 'Nature & Travel',
      videoAssetPath: 'assets/demo/alps_drone.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora',
      style: 'Cinematic Landscape FPV',
      cameraMovement: 'High-Speed Aerobatic FPV Drone Ridge Dive',
      lighting: 'Golden Dawn Rim Light, Mountain Alpenglow & Cloud Inversion Rays',
      seed: '91823746',
      tags: ['Alps', 'Drone', 'Mountains', 'Nature', 'Cinematic', 'FPV', 'Sunrise'],
      prompt:
          'Breathtaking high-speed acrobatic FPV drone dive swooping down the sheer vertical granite faces and jagged crevasses of the Swiss Bernese Alps at dawn. First golden rays of the morning alpenglow piercing through swirling glacial valley mist, throwing radiant amber and violet rim lighting across untouched virgin powder snow. Billowing powder avalanches cascading in slow motion off mountain spines. Captured on RED V-Raptor 8K VV cinema sensor with 14mm ultra-wide cine prime, gyro-stabilized horizon lock, natural atmospheric haze, National Geographic IMAX nature documentary grade, 120fps high frame rate masterwork.',
      negativePrompt:
          'overexposed, CGI look, pixelated, jitter, stuttering motion, washed out, watermark, cartoon render, blurred peaks',
    ),
    AiVideoPresetEntity(
      id: 'video_ramen_bar',
      title: 'Midnight Ramen Counter',
      category: 'Trending',
      videoAssetPath: 'assets/demo/ramen_bar.mp4',
      durationText: '5s',
      modelName: 'Luma Dream Machine',
      style: 'Warm Cinematic Documentary',
      cameraMovement: 'Slow Steadicam Push-In with Ultra-Shallow Macro Depth of Field',
      lighting: 'Warm 2700K Tungsten, Paper Chochin Lanterns & Sizzling Broth Glint',
      seed: '33490218',
      tags: ['Ramen', 'Tokyo', 'Food', 'Cozy', 'Atmospheric', 'Slow Mo', 'Culinary'],
      prompt:
          'Intimate, atmospheric cinematic slow push-in shot across the dark lacquered wooden counter of a legendary midnight ramen-ya in a narrow Shinjuku yokocho. Rich swirling clouds of fragrant tonkotsu broth steam curling upward into the warm glow of swaying red paper chochin lanterns. A master noodle chef in traditional indigo tenugui headband skillfully slicing crisp scallions with razor precision in the soft creamy bokeh background. Droplets of golden chili oil and glistening pork chashu resting in an artisan ceramic bowl in razor-sharp focus. Shot on Hasselblad medium format cine rig, Zeiss Supreme Prime 65mm T1.5, warm Kodachrome 64 nostalgic palette, 8K hyper-detailed photorealism.',
      negativePrompt:
          'flat lighting, noise, artifacts, static camera, synthetic CGI sheen, bad anatomy, deformed hands, cold lighting',
    ),
    AiVideoPresetEntity(
      id: 'video_tokyo_shinjuku',
      title: 'Rainy Shinjuku Hyperlapse',
      category: 'Sci-Fi & Cyberpunk',
      videoAssetPath: 'assets/demo/tokyo_shinjuku.mp4',
      durationText: '5s',
      modelName: 'Kling AI 1.5',
      style: 'Urban Cyberpunk Hyperlapse',
      cameraMovement: 'Dynamic Robotic Slider Forward Hyperlapse at Eye Level',
      lighting: 'Vibrant Rain-Wet Asphalt Reflections & Animated LED Billboards',
      seed: '62719403',
      tags: ['Rain', 'Shinjuku', 'Tokyo', 'Hyperlapse', 'Reflections', 'Urban Noir'],
      prompt:
          'Dynamic cinematic hyperlapse moving forward at eye level through the drenched neon labyrinth of Kabukicho, Shinjuku during a torrential midnight summer downpour. Thousands of translucent vinyl umbrellas reflecting shimmering ruby red, cobalt blue, and electric violet LED billboard glow. Fast-forward stream of pedestrians and black taxis creating luminous light-streak trails. Pristine mirror puddles rippling with heavy raindrops on asphalt, casting kaleidoscopic multi-colored reflections of giant animated holographic displays above. Shot on Sony Venice 2 camera with 24mm G Master lens on robotic slider, 8K resolution, Wong Kar-wai romantic urban noir aesthetic.',
      negativePrompt:
          'shaky camera, jump cuts, digital noise, muddy shadows, low resolution, compression artifacts, blurred umbrellas',
    ),
    AiVideoPresetEntity(
      id: 'video_urban_skate',
      title: 'Golden Hour Urban Skater',
      category: 'Popular',
      videoAssetPath: 'assets/demo/urban_skate.mp4',
      durationText: '5s',
      modelName: 'Pika 2.0 Pro',
      style: 'Action Sports 120fps Slow-Mo',
      cameraMovement: 'Ultra-Low Ground-Skimming Tracking Cam with Sunburst Flare',
      lighting: 'Backlit Golden Hour Sunburst & Beach Concrete Ambient Bounce',
      seed: '45028194',
      tags: ['Skate', 'Golden Hour', 'Slow Motion', 'Urban', 'Action', 'Venice Beach'],
      prompt:
          'Dynamic ultra-low ground-skimming follow camera tracking a street skateboarder executing a flawless 360-flip down a concrete stair set along Venice Beach promenade at peak golden hour. Camera glides millimeters above the sun-warmed concrete, catching radiant anamorphic golden sun flares bursting through palm frond silhouettes. Board spins in crystalline 120fps ultra-slow motion — urethane wheels kicking up micro-dust particles backlit by warm amber sunset light, grip tape texture and lace details razor sharp. Masterwork motion blur and shutter cadence, ARRI Alexa Mini LF with Panavision C-Series anamorphic prime, 8K resolution, Nike SB skate film aesthetic.',
      negativePrompt:
          'jerky camera, unnatural physics, broken motion, cartoon render, watermark, blurriness, deformed shoes, flat shadows',
    ),
    AiVideoPresetEntity(
      id: 'video_alps_sunrise',
      title: 'Ocean of Clouds Sunrise',
      category: 'Cinematic',
      videoAssetPath: 'assets/demo/alps_sunrise.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora',
      style: 'Majestic Time-Lapse',
      cameraMovement: 'Wide Panoramic Steadicam Sweep Across Sea of Clouds',
      lighting: 'Radiant Crepuscular God Rays & Tangerine Dawn Sunburst',
      seed: '19283740',
      tags: ['Sunrise', 'Clouds', 'Nature', 'Time-lapse', 'Ethereal', 'Dolomites'],
      prompt:
          'Majestic, transcendental high-altitude cinematic time-lapse gazing out from the pinnacle of a jagged Dolomite peak above a vast rolling ocean of low-lying cloud inversion. First rays of brilliant blinding sunrise bursting through volcanic cloud crests, throwing long crepuscular God rays across endless white fog waves that swell and flow like an ethereal sea. Sky transitioning through a gradient of deep indigo, flaming apricot, and soft rose quartz. Shot on Phase One IQ4 150MP camera with Rodenstock HR Digaron 28mm lens at interval capture, pristine clarity, Planet Earth III visual scale, 8K ultra-detailed masterwork.',
      negativePrompt:
          'banding, noisy sky, flickering light, unnatural clouds, low frame rate, watermark, washed out sun, digital compression',
    ),
    AiVideoPresetEntity(
      id: 'video_tokyo_street',
      title: 'Neon Izakaya Alleyway',
      category: 'Popular',
      videoAssetPath: 'assets/demo/tokyo_street.mp4',
      durationText: '5s',
      modelName: 'Runway Gen-3 Alpha',
      style: '35mm Film Cinematic Street',
      cameraMovement: 'Slow Steadicam Glide Down Atmospheric Pedestrian Alley',
      lighting: 'Glowing Paper Lanterns, Charcoal Grill Smoke & Distant Neon',
      seed: '81726354',
      tags: ['Street', 'Tokyo', 'Izakaya', 'Atmospheric', 'Cinematic', '35mm Film'],
      prompt:
          'Atmospheric 35mm cinematic slow-glide tracking shot drifting through Omoide Yokocho memory lane in Tokyo at dusk. Dense canopy of glowing amber and vermilion kanji paper lanterns hanging overhead, billowing charcoal yakitori grill smoke catching warm lantern backlight. Locals and salarymen laughing and clinking cold beer glasses inside open-air wooden stalls, steam whispering from iron exhaust flues into rain-chilled air. Shot on vintage 35mm Kodak Vision3 500T 5219 motion picture film stock with Leica Summilux-C 35mm prime, authentic organic film grain, rich halation around light sources, 8K cine scan.',
      negativePrompt:
          'deformed faces, static mannequins, muddy blacks, oversaturation, blur, modern cars, anachronistic objects, flat lighting',
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
      lighting: 'Tachyonic Azure & Ultraviolet Light Streaks with Cockpit HUD Glint',
      seed: '59201948',
      tags: ['Cosmic', 'Space', 'Warp Speed', 'Sci-Fi', 'Galaxy', 'Interstellar'],
      prompt:
          'First-person POV cinematic sequence from inside an advanced carbon-composite starfighter cockpit executing a faster-than-light hyperdrive jump. Throttle engages as twin fusion engines rumble, camera shakes with rising G-force vibrations. Outside the polarized glass canopy, surrounding asteroid belt and distant spiral galaxy warp and stretch into blinding azure and ultraviolet tachyonic light tunnels. Curved cockpit displays and Heads-Up Display HUD graphics cast electric cyan and magenta data readouts across the pilot visor. Shot with virtual IMAX 70mm anamorphic camera, Interstellar and Star Wars visual fidelity, 8K photorealism.',
      negativePrompt:
          'low-poly, flat lighting, jittery stars, blurry cockpit, amateur CGI, watermark, video game look, bad textures',
    ),
    AiVideoPresetEntity(
      id: 'video_neon_puddle_reflection',
      title: 'Cyberpunk Puddle Reflections',
      category: 'Sci-Fi & Cyberpunk',
      videoAssetPath: 'assets/demo/tokyo_shinjuku.mp4',
      durationText: '5s',
      modelName: 'Kling AI 1.5',
      style: 'Dark Atmospheric Cyberpunk',
      cameraMovement: 'Probe Lens Millimeter Skim with Seamless Tilt-Up',
      lighting: 'Reflective Neon Magenta, Emerald, Gold & Liquid Puddle Bounce',
      seed: '30491823',
      tags: ['Cyberpunk', 'Rain', 'Reflections', 'Tokyo', 'Atmosphere', 'Macro Probe'],
      prompt:
          'Breathtaking macro probe-lens sequence skimming 5 millimeters above a rain puddle on drenched asphalt in a cyberpunk megacity. Surface ripples form mesmerizing circular harmonic waves with every falling droplet, reflecting colossal 200-meter animated holographic anime advertisements above in shimmering neon turquoise, ultraviolet, and hot coral pink. Camera smoothly tilts up in one seamless unbroken motion to reveal towering mega-skyscrapers piercing storm clouds, flying sky-car hover traffic lanes streaking overhead. Shot on Laowa 24mm T14 2X Periprobe lens on robotic motion-control arm, 8K 60fps cinematic masterwork.',
      negativePrompt:
          'dirty camera lens, digital grain noise, poor motion physics, distorted reflections, watermark, blurry ripples',
    ),
    AiVideoPresetEntity(
      id: 'video_alpine_helicopter_orbit',
      title: 'Matterhorn Helicopter Orbit',
      category: 'Nature & Travel',
      videoAssetPath: 'assets/demo/alps_drone.mp4',
      durationText: '5s',
      modelName: 'Runway Gen-3 Alpha',
      style: 'National Geographic Aerial 8K',
      cameraMovement: '360-Degree Gyro-Stabilized Helicopter Circling Orbit',
      lighting: 'Glacial Sun Glint, Crystalline Snow Scintillation & Deep Blue Shadow',
      seed: '44819203',
      tags: ['Matterhorn', 'Alps', 'Snow', 'Aerial', 'Travel', 'Helicopter'],
      prompt:
          'Sweeping, epic gyro-stabilized helicopter aerial 360-degree orbit gliding around the pyramidal razor-sharp summit ridge of the Matterhorn in Switzerland. Violent high-altitude winds shearing off billowing plumes of powder snow into the deep abyss below, ice crystals scintillating like diamond dust in the piercing high-altitude sunlight. Vast blue glacial icefalls and snow couloirs stretching thousands of meters down into the Zermatt valley below. Captured on Shotover F1 gimbal with RED Monstro 8K VV and Angenieux Optimo 28-76mm cinema zoom lens, pristine clarity, Top Gun Maverick aerial cinematography grade.',
      negativePrompt:
          'choppy frame rate, compression artifacts, flat mountains, unnatural snow color, oversaturated sky, camera shudder',
    ),
    AiVideoPresetEntity(
      id: 'video_sunset_boulevard_cruise',
      title: 'Sunset Boulevard Lowrider',
      category: 'Popular',
      videoAssetPath: 'assets/demo/urban_skate.mp4',
      durationText: '5s',
      modelName: 'Luma Dream Machine',
      style: 'West Coast Nostalgic 70mm',
      cameraMovement: 'Parallel Wheel-Level Rolling Shot with Horizon Breathing',
      lighting: 'California Sunset Orange Flare, Chrome Specular & Palm Silhouettes',
      seed: '71930284',
      tags: ['Sunset', 'California', 'Golden Hour', 'Vintage', 'Cinematic', 'Lowrider'],
      prompt:
          'Low-slung pursuit vehicle camera tracking parallel to a candy-apple red 1964 Impala lowrider cruising down palm-lined Sunset Boulevard at golden hour. Mirror-polished chrome wire wheels spinning and throwing dazzling sunburst lens flares directly into the camera. Silhouette of towering California royal palm trees framing a sky glowing with deep tangerine, blush pink, and lavender smog-haze gradients. Warm summer evening wind rustling hair, soft vintage 70mm anamorphic lens breathing, Quentin Tarantino Once Upon a Time in Hollywood cinematic look, Kodak Vision3 250D color science, 8K resolution.',
      negativePrompt:
          'blown out highlights, muddy shadows, stuttering car wheels, digital artifacts, blur, modern vehicles, cheap CGI',
    ),
    AiVideoPresetEntity(
      id: 'video_quantum_portal_chamber',
      title: 'Quantum Portal Chamber',
      category: 'Sci-Fi & Cyberpunk',
      videoAssetPath: 'assets/demo/cyberpunk_arcade.mp4',
      durationText: '5s',
      modelName: 'Pika 2.0 Pro',
      style: 'Futuristic Quantum Physics Lab',
      cameraMovement: 'Sweeping Crane Descent Circling Particle Accelerator Ring',
      lighting: 'Pulsing Violet & Teal Plasma Arcs with Volumetric Floor Fog',
      seed: '18492034',
      tags: ['Portal', 'Sci-Fi', 'Quantum', 'VFX', 'Futuristic', 'Particle Physics'],
      prompt:
          'Grand slow Steadicam crane shot descending through a massive subterranean particle physics research collider facility. In the center, a colossal 50-meter magnetic ring supercharges, tearing open a swirling quantum wormhole portal of blinding violet plasma and luminous teal tachyon lightning arcs. Arcs of living static electricity leap across heavy cooling pipes and steel catwalks where silhouetted researchers in pressurized hazard suits monitor humming holographic terminals. Volumetric nitrogen fog hugging grated steel floor. Shot on Panavision DXL2 8K with Primo 70 optics, Christopher Nolan Tenet scale, 8K visual effects masterpiece.',
      negativePrompt:
          'flat textures, broken lightning geometry, poor smoke simulation, cartoon look, low frame rate, videogame graphics',
    ),
    AiVideoPresetEntity(
      id: 'video_tokyo_night_walk',
      title: 'Sakura Petals Night Drift',
      category: 'Trending',
      videoAssetPath: 'assets/demo/tokyo_street.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora',
      style: 'Ethereal Japanese Cinematic Poetry',
      cameraMovement: 'Gentle Dolly Drift Down Canal Walkway with Water Reflections',
      lighting: 'Soft Pink Paper Lanterns, Deep Ink-Black Canal & River Mist',
      seed: '88392019',
      tags: ['Sakura', 'Tokyo', 'Cherry Blossom', 'Night', 'Aesthetic', 'Meguro River'],
      prompt:
          'Poetic, hauntingly beautiful cinematic dolly shot drifting along the stone canal promenade of the Meguro River in Tokyo at 1:00 AM under full cherry blossom bloom. Endless strings of glowing pink and white paper bonbori lanterns casting soft pastel pools of light across the ink-black canal waters. Thousands of delicate sakura petals gently drifting from overarching branches, swirling in slow currents across the water surface like a pink galaxy. Atmospheric night air with faint river mist, reflections of distant quiet city lights shimmering in emerald and amber. ARRI Alexa 35 with Cooke S4/i 50mm, 8K photorealistic masterpiece.',
      negativePrompt:
          'synthetic flowers, unnatural petal physics, bad lighting, blur, artifacts, glitch, daylight bleed, pixelated blossoms',
    ),
    AiVideoPresetEntity(
      id: 'video_cyber_biker_highway',
      title: 'Neo-Tokyo Midnight Superbike',
      category: 'Sci-Fi & Cyberpunk',
      videoAssetPath: 'assets/demo/cyberpunk_arcade.mp4',
      durationText: '5s',
      modelName: 'Runway Gen-3 Alpha',
      style: 'High-Octane Cyberpunk Chase',
      cameraMovement: 'Low Ground Chase Cam Tracking Exhaust at 200 km/h',
      lighting: 'Neon Blue Hubless Wheel Glow & Crimson Taillight Trails',
      seed: '94820138',
      tags: ['Superbike', 'Cyberpunk', 'Highway', 'Tokyo', 'Speed', 'Akira'],
      prompt:
          'High-octane tracking shot racing inches above the asphalt behind a sleek aerodynamic matte-black superbike with glowing cyan hubless wheels speeding down an elevated Tokyo expressway at 2:00 AM. Glowing crimson taillights streak long continuous photon ribbons through the rainy night air. Cyber-pilot wearing articulated carbon-fiber riding armor with helmet HUD reflecting digital speedometers and exit markers. Distant hyper-dense skyscrapers and holographic ads passing in extreme velocity motion blur. Shot on ARRI Alexa Mini LF on pursuit motorcycle rig, Panavision 35mm anamorphic, Akira live-action film aesthetic, 8K photorealism.',
      negativePrompt:
          'static vehicle, bad wheel physics, cartoon textures, muddy night shadows, jittery tracking, low frame rate',
    ),
    AiVideoPresetEntity(
      id: 'video_underwater_whale_dive',
      title: 'Pacific Blue Whale Descent',
      category: 'Nature & Travel',
      videoAssetPath: 'assets/demo/alps_drone.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora 2.0',
      style: 'National Geographic Deep Ocean',
      cameraMovement: 'Slow Orbit Gliding Alongside Colossal Leviathan',
      lighting: 'Piercing Ocean Sunbeams & Deep Indigo Bioluminescence',
      seed: '73910284',
      tags: ['Whale', 'Ocean', 'Underwater', 'Nature', 'Marine', 'Blue Whale'],
      prompt:
          'Awe-inspiring wide-angle underwater cinematic sequence gliding gracefully alongside a colossal 30-meter blue whale descending into the crystalline sapphire depths of the South Pacific. Shimmering volumetric sunlight rays pierce down from the rippling ocean surface 40 meters above, illuminating the intricate white-mottled slate-gray skin texture, tiny barnacles, and powerful slow tail flukes undulating with immense weightless grace. A school of silver jacks glimmers in synchronized formation around the pectoral fins. Shot with RED Helium 8K S35 inside Gates underwater cinema housing, ultra-crisp caustics, BBC Blue Planet II documentary masterwork.',
      negativePrompt:
          'murky muddy water, CGI plastic skin, distorted anatomy, aquarium walls, floating debris, artificial look, washed out colors',
    ),
    AiVideoPresetEntity(
      id: 'video_samurai_bamboo_duel',
      title: 'Ghost Bamboo Forest Stance',
      category: 'Cinematic',
      videoAssetPath: 'assets/demo/tokyo_street.mp4',
      durationText: '5s',
      modelName: 'Kling AI 1.5',
      style: 'Feudal Japanese Kurosawa Epic',
      cameraMovement: 'Slow 360 Steadicam Arc Around Ready Katana Guard',
      lighting: 'Foggy Forest Sunbeams Piercing Bamboo Stalks & Blade Glint',
      seed: '61928374',
      tags: ['Samurai', 'Bamboo', 'Katana', 'Cinematic', 'Japan', 'Feudal'],
      prompt:
          'Breathtaking 360-degree cinematic arc shot rotating slowly around a legendary ronin samurai standing in ready kenjutsu guard in the heart of a misty Kyoto bamboo grove. Morning sunlight shafts pierce through towering emerald bamboo stalks, illuminating millions of floating dew particles suspended in the cool morning air. Wind softly rustles the tattered black straw woven jinbaori vest and silk cords. The mirror-polished hand-forged tamahagane katana blade catches a sliver of bright sunlight along its undulating hamon line. Exhaled breath mists in quiet concentration. Panavision DXL2 with Primo Anamorphic 50mm, Akira Kurosawa Ran color palette, 8K resolution.',
      negativePrompt:
          'modern clothing, bad katana geometry, plastic armor, western swords, jittery camera, blurry bamboo, anime look',
    ),
    AiVideoPresetEntity(
      id: 'video_norway_aurora_fjord',
      title: 'Arctic Aurora Fjord Cruise',
      category: 'Nature & Travel',
      videoAssetPath: 'assets/demo/alps_sunrise.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora',
      style: 'Nordic Midnight Expedition',
      cameraMovement: 'Prow Camera Drifting Across Mirrored Glacial Fjord',
      lighting: 'Dancing Green & Violet Aurora Borealis & Arctic Twilight',
      seed: '51928473',
      tags: ['Aurora', 'Norway', 'Fjord', 'Northern Lights', 'Arctic', 'Midnight'],
      prompt:
          'Hypnotic continuous tracking shot mounted on the wooden prow of a quiet expedition boat gliding across the mirror-still black waters of a majestic Norwegian fjord at midnight. Towering snow-capped fjord cliffs reflect in glassy perfection below. Overhead, a colossal vibrant aurora borealis curtain in electric emerald green and glowing violet dances and ripples across the starry Arctic heavens like celestial silk. Delicate floating ice sheets gently part before the boat bow with quiet crystalline chimes. Sony FX9 with 16mm T2.0 wide cine lens at ISO 12800, extreme dynamic range, National Geographic night expedition film masterwork.',
      negativePrompt:
          'grainy noisy sky, static aurora, overexposed stars, choppy water, flat lighting, artificial CGI glow, digital compression',
    ),
    AiVideoPresetEntity(
      id: 'video_retro_synth_drive',
      title: 'Outrun Synthwave Testarossa',
      category: 'Popular',
      videoAssetPath: 'assets/demo/urban_skate.mp4',
      durationText: '5s',
      modelName: 'Pika 2.0 Pro',
      style: '1980s Retro Synthwave Cinema',
      cameraMovement: 'Rear 3/4 Tracking Shot Following Chrome Exhaust and Spoiler',
      lighting: 'Electric Magenta Grid Glow, Violet Horizon & Giant Retro Sun',
      seed: '82910394',
      tags: ['Synthwave', 'Outrun', '80s', 'Ferrari', 'Retro', 'Neon Grid'],
      prompt:
          'Iconic 1980s retro synthwave tracking shot following a white sports car with sharp pop-up headlights cruising down an endless digital neon highway toward a giant glowing purple and orange horizontal-striped wireframe sun. Reflections of neon grid lines sweep across the glossy hood and rear louvers in rhythmic sequence. Volumetric purple fog drifts across the asphalt while palm tree wireframe silhouettes line the horizon. Subtle VHS tape tracking distortion, chromatic aberration around edges, 1986 Miami Vice aesthetic, Kavinsky Outrun album art come to life in photorealistic 8K 60fps.',
      negativePrompt:
          'modern cars, realistic daytime, washed out colors, low contrast, pixelated car model, blurry grid, cartoon render',
    ),
    AiVideoPresetEntity(
      id: 'video_steampunk_airship_flight',
      title: 'Victorian Steampunk Leviathan',
      category: 'Sci-Fi & Cyberpunk',
      videoAssetPath: 'assets/demo/overlay_vid.mp4',
      durationText: '5s',
      modelName: 'Runway Gen-3 Alpha',
      style: 'Victorian Steampunk Fantasy',
      cameraMovement: 'Majestic Side-Tracking Flyby Along Massive Brass Hull',
      lighting: 'Sunset Amber Glow, Furnace Fire Reflections & Escaping Steam',
      seed: '42918402',
      tags: ['Steampunk', 'Airship', 'Victorian', 'Clouds', 'Brass', 'Gears'],
      prompt:
          'Majestic aerial flyby tracking alongside a colossal Victorian steampunk airship navigating through towering billowing sunset thunderheads. Massive riveted brass and burnished copper hull plates gleaming in the warm amber twilight. Enormous multi-bladed wooden and steel propellor engines churning clouds, brass pressure release valves discharging rhythmic plumes of white steam. Captain in leather coat and brass goggles standing on the exterior iron observation deck holding brass nautical binoculars. Industrial Revolution aesthetic, Hayao Miyazaki Castle in the Sky realism, 8K ultra-detailed masterwork.',
      negativePrompt:
          'modern airplanes, flat textures, bad steam physics, clean CGI surfaces, broken gears, blurry clouds, plastic shine',
    ),
    AiVideoPresetEntity(
      id: 'video_desert_sandstorm_caravan',
      title: 'Sahara Sandstorm Nomad',
      category: 'Cinematic',
      videoAssetPath: 'assets/demo/alps_drone.mp4',
      durationText: '5s',
      modelName: 'OpenAI Sora 2.0',
      style: 'Lawrence of Arabia Epic Cinema',
      cameraMovement: 'Slow Sweeping Crane Pull-Back Amidst Swirling Dust',
      lighting: 'Blinding Crimson Sunset Piercing Churning Ochre Sand Clouds',
      seed: '31948201',
      tags: ['Desert', 'Sandstorm', 'Dune', 'Cinematic', 'Sahara', 'Nomad'],
      prompt:
          'Epic wide cinematic crane shot slowly pulling back from a solitary nomadic desert traveler in indigo Berber robes leading a camel through a rising ochre sandstorm across towering Saharan sand dunes. Massive churning dust storm wall building on the horizon, catching the dying blood-orange and terracotta rays of a massive desert sun. Millions of individual sand grains streaming across the dune ridge like molten gold. Robes whip violently in the gale force wind, footprints erased by drifting sand in real time. Captured on ARRI Alexa 65 with 70mm anamorphic lens, Denis Villeneuve Dune visual mastery, 8K photorealism.',
      negativePrompt:
          'greenery, modern buildings, static dust, fake CGI sand, cartoon look, flat lighting, digital noise, blurry dunes',
    ),
  ];
}
