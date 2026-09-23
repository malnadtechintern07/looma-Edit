import 'package:procut/core/config/server_config.dart';
import 'package:procut/core/network/api_client.dart';
import '../../../projects/domain/entities/aspect_ratio_type.dart';
import '../../domain/entities/royalty_free_music_entity.dart';
import '../../domain/entities/store_template_entity.dart';

abstract class AssetStoreDataSource {
  Future<List<StoreTemplateEntity>> getTemplates();
  Future<List<RoyaltyFreeMusicEntity>> getMusicList();
  Future<void> markDownloaded(String id);
}

class AssetStoreDataSourceImpl implements AssetStoreDataSource {
  final Set<String> _downloadedIds = {};

  @override
  Future<List<StoreTemplateEntity>> getTemplates() async {
    try {
      final baseUrl = await ServerConfig.getBaseUrl();
      List<dynamic> templatesRaw = [];
      
      // Attempt 1: Fetch directly from /api/templates
      try {
        final res = await ApiClient.get(Uri.parse('$baseUrl/api/templates'));
        if (res.isOk && res.json is Map) {
          final json = res.json as Map<String, dynamic>;
          templatesRaw = json['templates'] as List<dynamic>? ?? [];
        }
      } catch (_) {}

      // Attempt 2: Fall back to /api/app/content if empty
      if (templatesRaw.isEmpty) {
        try {
          final res = await ApiClient.get(Uri.parse('$baseUrl/api/app/content'));
          if (res.isOk && res.json is Map) {
            final json = res.json as Map<String, dynamic>;
            templatesRaw = json['templates'] as List<dynamic>? ?? [];
          }
        } catch (_) {}
      }

      if (templatesRaw.isNotEmpty) {
        final serverTemplates = templatesRaw.map((t) {
          final tagsRaw = t['tags'] as String? ?? '';
          final tagsList = tagsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          
          final tmplId = t['id']?.toString() ?? 'tmpl_unknown';
          final tmplCategory = t['category'] as String? ?? 'Trending';

          var videoUrl = t['preview_video_url'] as String? ?? '';
          if (videoUrl.isNotEmpty && videoUrl.startsWith('/')) {
            videoUrl = '$baseUrl$videoUrl';
          }
          if (videoUrl.contains('free.nf') || videoUrl.startsWith('/') || videoUrl.isEmpty) {
            videoUrl = resolveWorkingVideoUrl(tmplId, tmplCategory);
          }

          var imageUrl = t['preview_image_url'] as String? ?? '';
          if (imageUrl.isNotEmpty && imageUrl.startsWith('/')) {
            imageUrl = '$baseUrl$imageUrl';
          }
          if (imageUrl.contains('free.nf') || imageUrl.isEmpty) {
            final imgFileName = imageUrl.split('/').last.split('?').first.trim();
            imageUrl = imgFileName.isNotEmpty ? 'assets/demo/$imgFileName' : 'assets/demo/tmpl-golden-hour.jpg';
          }

          var audioUrl = t['audio_url'] as String? ?? '';
          if (audioUrl.isNotEmpty && audioUrl.startsWith('/')) {
            audioUrl = '$baseUrl$audioUrl';
          }
          if (audioUrl.contains('free.nf') || audioUrl.isEmpty) {
            audioUrl = resolveWorkingAudioPath(tmplId, tmplCategory);
          }

          final isProVal = t['is_pro'] == 1 || t['is_pro'] == true || t['is_pro'] == '1';
          final isTrendingVal = t['is_trending'] == 1 || t['is_trending'] == true || t['is_trending'] == '1';
          final isNewVal = t['is_new'] == 1 || t['is_new'] == true || t['is_new'] == '1';
          final isPopularVal = t['is_popular'] == 1 || t['is_popular'] == true || t['is_popular'] == '1';

          return StoreTemplateEntity(
            id: tmplId,
            title: t['title'] as String? ?? 'ProCut Template',
            category: tmplCategory,
            badge: t['badge'] as String?,
            description: t['description'] as String? ?? '',
            prompt: t['prompt'] as String? ?? '',
            author: t['author'] as String? ?? 'ProCut Originals',
            aspectRatio: t['aspect_ratio'] == 'ratio16_9' ? AspectRatioType.ratio16_9 : AspectRatioType.ratio9_16,
            durationMs: t['duration_ms'] is int ? t['duration_ms'] : int.tryParse(t['duration_ms'].toString()) ?? 10000,
            clipsCount: t['clips_count'] is int ? t['clips_count'] : int.tryParse(t['clips_count'].toString()) ?? 4,
            downloadsCount: t['downloads_count'] is int ? t['downloads_count'] : int.tryParse(t['downloads_count'].toString()) ?? 1000,
            previewGradientStart: t['preview_gradient_start'] as String? ?? '0xFF7C3AED',
            previewGradientEnd: t['preview_gradient_end'] as String? ?? '0xFFEC4899',
            previewVideoUrl: videoUrl,
            previewImageUrl: imageUrl,
            projectJson: t['project_json'] as String?,
            isPro: isProVal,
            isTrending: isTrendingVal,
            isNew: isNewVal,
            isPopular: isPopularVal,
            tags: tagsList.isNotEmpty ? tagsList : const ['Trending', 'Reels'],
            audioTrackTitle: t['audio_title'] as String? ?? 'Soundtrack',
            audioPath: audioUrl,
            isDownloaded: _downloadedIds.contains(tmplId),
          );
        }).toList();

        // Always merge with full default templates so all templates across all categories are always available!
        final defaults = _buildDefault25Templates();
        final serverIds = serverTemplates.map((s) => s.id).toSet();
        final missingDefaults = defaults.where((d) => !serverIds.contains(d.id)).toList();
        return [...serverTemplates, ...missingDefaults];
      }
    } catch (_) {}

    // Complete Offline Fallback: 35 real templates matching all categories
    return _buildDefault25Templates();
  }

  /// Maps every template ID and category to its matching unique theme video
  static String resolveWorkingVideoUrl(String id, String category) {
    final cat = category.toLowerCase();
    final idLower = id.toLowerCase();

    // Specific template IDs mapping to unique videos
    if (idLower == 'tmpl-birthday' || idLower == 'tmpl-birthday-slideshow') {
      return 'assets/demo/overlay_vid.mp4';
    }
    if (idLower == 'tmpl-wedding' || idLower == 'tmpl-love-story' || idLower == 'tmpl-photo-memories' || idLower == 'tmpl-sunset-acoustic' || idLower == 'tmpl-sample-3') {
      return 'assets/demo/alps_sunrise.mp4';
    }
    if (idLower == 'tmpl-travel' || idLower == 'tmpl-nature' || idLower == 'tmpl-ocean-dive') {
      return 'assets/demo/alps_drone.mp4';
    }
    if (idLower == 'tmpl-cinematic' || idLower == 'tmpl-80s-retro' || idLower == 'tmpl-sample-5' || idLower == 'tmpl-gaming-stream') {
      return 'assets/demo/cyberpunk_arcade.mp4';
    }
    if (idLower == 'tmpl-family' || idLower == 'tmpl-food' || idLower == 'tmpl-sample-1' || idLower == 'tmpl-vlog-daily') {
      return 'assets/demo/ramen_bar.mp4';
    }
    if (idLower == 'tmpl-friends' || idLower == 'tmpl-festival' || idLower == 'tmpl-celebration' || idLower == 'tmpl-sample-4') {
      return 'assets/demo/tokyo_shinjuku.mp4';
    }
    if (idLower == 'tmpl-before-after' || idLower == 'tmpl-motivation' || idLower == 'tmpl-fast-transitions' || idLower == 'tmpl-sample-2' || idLower == 'tmpl-cyber-neon') {
      return 'assets/demo/tokyo_street.mp4';
    }
    if (idLower == 'tmpl-reels' || idLower == 'tmpl-fashion') {
      return 'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/face-demographics-walking.mp4';
    }
    if (idLower == 'tmpl-business') {
      return 'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/store-aisle-detection.mp4';
    }
    if (idLower == 'tmpl-graduation') {
      return 'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/classroom.mp4';
    }
    if (idLower == 'tmpl-fitness') {
      return 'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/person-bicycle-car-detection.mp4';
    }

    // Category based mapping
    if (cat.contains('wedding') || cat.contains('love') || cat.contains('photo') || cat.contains('acoustic')) {
      return 'assets/demo/alps_sunrise.mp4'; // Flower blooming / romance
    }
    if (cat.contains('cinematic') || cat.contains('retro') || cat.contains('tech') || cat.contains('80s') || cat.contains('gaming')) {
      return 'assets/demo/cyberpunk_arcade.mp4'; // Sintel 1080p Action
    }
    if (cat.contains('travel') || cat.contains('nature') || cat.contains('ocean')) {
      return 'assets/demo/alps_drone.mp4'; // Underwater Jellyfish / Nature
    }
    if (cat.contains('music') || cat.contains('party') || cat.contains('dance') || cat.contains('festival') || cat.contains('celebration')) {
      return 'assets/demo/tokyo_shinjuku.mp4'; // Concert stage performance
    }
    if (cat.contains('car') || cat.contains('drive') || cat.contains('transition') || cat.contains('motivation') || cat.contains('speed')) {
      return 'assets/demo/tokyo_street.mp4'; // Highway speed car drive
    }
    if (cat.contains('food') || cat.contains('family') || cat.contains('sweet') || cat.contains('vlog') || cat.contains('pet')) {
      return 'assets/demo/ramen_bar.mp4'; // Playful corgi / pet lifestyle
    }
    if (cat.contains('birthday') || cat.contains('slideshow')) {
      return 'assets/demo/overlay_vid.mp4'; // Friday celebration animation
    }
    if (cat.contains('fashion') || cat.contains('runway') || cat.contains('lookbook')) {
      return 'assets/demo/alps_sunrise.mp4';
    }
    return 'assets/demo/urban_skate.mp4'; // Big Buck Bunny / Viral
  }

  /// Maps every template ID and category to its matching unique audio soundtrack
  static String resolveWorkingAudioPath(String id, String category) {
    final cat = category.toLowerCase();
    final idLower = id.toLowerCase();
    if (cat.contains('wedding') || cat.contains('cinematic') || cat.contains('graduation') || cat.contains('business')) {
      return 'assets/demo/cinematic_audio.wav';
    }
    if (cat.contains('retro') || cat.contains('80s') || cat.contains('tech') || idLower.contains('cyber') || idLower.contains('synth')) {
      return 'assets/demo/synthwave_beat.wav';
    }
    if (cat.contains('beat') || cat.contains('viral') || cat.contains('fitness') || idLower.contains('beat')) {
      return 'assets/demo/phonk_beat.wav';
    }
    if (cat.contains('love') || cat.contains('family') || cat.contains('nature') || cat.contains('photo')) {
      return 'assets/demo/lofi_beat.wav';
    }
    if (cat.contains('friends') || cat.contains('reels') || cat.contains('transition')) {
      return 'assets/demo/urban_trap.wav';
    }
    return 'assets/demo/tropical_beat.wav';
  }

  List<StoreTemplateEntity> _buildDefault25Templates() {
    return [
      // ── Verified 200-OK video URLs (tested live, no auth required) ───────
      // Sources: test-videos.co.uk, media.w3.org, vjs.zencdn.net
      // Sizes kept ≤ 5MB for fast mobile buffering
      StoreTemplateEntity(
        id: 'tmpl-birthday',
        title: '🎉 Birthday Celebration Highlights',
        category: 'Birthday',
        badge: 'Celebration',
        description: 'Fun confetti pops, celebration typography, warm party filters and upbeat pop background music.',
        author: 'PartyLab Studio',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 12000,
        clipsCount: 3,
        downloadsCount: 34200,
        previewGradientStart: '0xFFFF5E3A',
        previewGradientEnd: '0xFFFF2A68',
        previewVideoUrl: 'assets/demo/overlay_vid.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Birthday', 'Party', 'Celebration', 'Balloons', 'Cake'],
        audioTrackTitle: 'Birthday Party Pop Beats',
        audioPath: 'assets/demo/tropical_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-birthday'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-wedding',
        title: '💍 Eternal Vows Wedding Film',
        category: 'Wedding',
        badge: 'Romantic',
        description: 'Romantic slow-motion dissolves, elegant golden bokeh lighting, and emotional cinematic orchestra.',
        author: 'Elegance Films',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 15000,
        clipsCount: 4,
        downloadsCount: 52100,
        previewGradientStart: '0xFFD4AF37',
        previewGradientEnd: '0xFFF3E5AB',
        previewVideoUrl: 'assets/demo/alps_sunrise.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        isPro: true,
        tags: const ['Wedding', 'Bride', 'Groom', 'Love', 'Ceremony', 'Romance'],
        audioTrackTitle: 'Eternal Romance Strings',
        audioPath: 'assets/demo/cinematic_audio.wav',
        isDownloaded: _downloadedIds.contains('tmpl-wedding'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-travel',
        title: '✈️ Wanderlust Adventure Recap',
        category: 'Travel',
        badge: 'Adventure',
        description: 'Dynamic whip transitions, GPS coordinate titles, vibrant saturation, and tropical travel vibes.',
        author: 'Global Roamer',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 14000,
        clipsCount: 4,
        downloadsCount: 61000,
        previewGradientStart: '0xFF00B4DB',
        previewGradientEnd: '0xFF0083B0',
        previewVideoUrl: 'assets/demo/alps_drone.mp4',
        previewImageUrl: 'assets/demo/tmpl-summer-tropical.jpg',
        tags: const ['Travel', 'Adventure', 'Vacation', 'Wanderlust', 'Summer'],
        audioTrackTitle: 'Tropical Horizon Beats',
        audioPath: 'assets/demo/tropical_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-travel'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-love-story',
        title: '❤️ Our Love Story Moments',
        category: 'Love Story',
        badge: 'Sweet',
        description: 'Soft pastel tones, heart stickers, dreamy blur transitions, and acoustic lo-fi vibes.',
        author: 'Sweet Memories',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 12000,
        clipsCount: 3,
        downloadsCount: 41800,
        previewGradientStart: '0xFFFF758C',
        previewGradientEnd: '0xFFFF7EB3',
        previewVideoUrl: 'assets/demo/alps_sunrise.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Love', 'Couple', 'Romantic', 'Relationship', 'Heart'],
        audioTrackTitle: 'Lo-Fi Romance Dream',
        audioPath: 'assets/demo/lofi_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-love-story'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-family',
        title: '🏡 Home & Family Memories',
        category: 'Family',
        badge: 'Warm',
        description: 'Warm home-video vibes, gentle fades, nostalgic warmth, and joyful acoustic rhythms.',
        author: 'Kinfolk Media',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 12000,
        clipsCount: 4,
        downloadsCount: 29500,
        previewGradientStart: '0xFFF7971E',
        previewGradientEnd: '0xFFFFD200',
        previewVideoUrl: 'assets/demo/ramen_bar.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Family', 'Home', 'Kids', 'Parents', 'Memories', 'Love'],
        audioTrackTitle: 'Cozy Family Acoustic',
        audioPath: 'assets/demo/lofi_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-family'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-friends',
        title: '👯 Best Friends Forever Vibe',
        category: 'Friends',
        badge: 'Squad',
        description: 'High-energy snap cuts, retro film grain, quirky stickers, and punchy trap bounce.',
        author: 'Crew Visuals',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 10000,
        clipsCount: 4,
        downloadsCount: 38700,
        previewGradientStart: '0xFFFF0844',
        previewGradientEnd: '0xFFFFB199',
        previewVideoUrl: 'assets/demo/tokyo_shinjuku.mp4',
        previewImageUrl: 'assets/demo/tmpl-urban-street.jpg',
        tags: const ['Friends', 'Squad', 'Party', 'Vlog', 'Youth'],
        audioTrackTitle: 'Upbeat Squad Trap',
        audioPath: 'assets/demo/urban_trap.wav',
        isDownloaded: _downloadedIds.contains('tmpl-friends'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-birthday-slideshow',
        title: '🎂 Memory Lane Birthday Slideshow',
        category: 'Birthday Slideshow',
        badge: 'Memories',
        description: 'Elegant polaroid photo slides, memory year badges, smooth cross-fades, and uplifting pop.',
        author: 'MemoryBox',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 15000,
        clipsCount: 5,
        downloadsCount: 26300,
        previewGradientStart: '0xFF667EEA',
        previewGradientEnd: '0xFF764BA2',
        previewVideoUrl: 'assets/demo/overlay_vid.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Birthday', 'Slideshow', 'Photos', 'Memories', 'Celebration'],
        audioTrackTitle: 'Celebration Melody',
        audioPath: 'assets/demo/tropical_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-birthday-slideshow'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-cinematic',
        title: '🎬 Hollywood 4K Cinematic Trailer',
        category: 'Cinematic',
        badge: 'Masterpiece',
        description: 'Wide 2.35:1 letterbox bars, teal & orange color grade, slow dramatic push-ins, and epic orchestral hits.',
        author: 'ProCut Studios',
        aspectRatio: AspectRatioType.ratio16_9,
        durationMs: 16000,
        clipsCount: 4,
        downloadsCount: 74200,
        previewGradientStart: '0xFF0F2027',
        previewGradientEnd: '0xFF2C5364',
        previewVideoUrl: 'assets/demo/cyberpunk_arcade.mp4',
        previewImageUrl: 'assets/demo/tmpl-cinematic-youtube.jpg',
        isPro: true,
        tags: const ['Cinematic', 'Film', 'Trailer', 'Hollywood', 'Epic'],
        audioTrackTitle: 'Epic Cinematic Horizon',
        audioPath: 'assets/demo/cinematic_audio.wav',
        isDownloaded: _downloadedIds.contains('tmpl-cinematic'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-beat-sync',
        title: '⚡ Ultra Beat Drop Sync',
        category: 'Beat Sync',
        badge: 'Bass Drop',
        description: 'Clips snap to drum kick transients, shake on impact, strobe flash frames, and heavy 808 bass.',
        author: 'BassDrop FX',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 8000,
        clipsCount: 5,
        downloadsCount: 68900,
        previewGradientStart: '0xFF8E2DE2',
        previewGradientEnd: '0xFF4A00E0',
        previewVideoUrl: 'assets/demo/urban_skate.mp4',
        previewImageUrl: 'assets/demo/tmpl-viral-phonk.jpg',
        tags: const ['BeatSync', 'Phonk', 'Bass', 'Drift', 'Rhythm'],
        audioTrackTitle: 'Hardcore 808 Beat Drop',
        audioPath: 'assets/demo/phonk_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-beat-sync'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-reels',
        title: '📱 Trending Instagram Reel Edit',
        category: 'Reels',
        badge: 'Viral',
        description: 'Punchy 3-second hook, auto-caption typography, snappy zoom-cuts, and viral audio.',
        author: 'GrowthLab',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 9000,
        clipsCount: 3,
        downloadsCount: 59100,
        previewGradientStart: '0xFFE1306C',
        previewGradientEnd: '0xFFF77737',
        previewVideoUrl: 'https://github.com/intel-iot-devkit/sample-videos/raw/master/face-demographics-walking.mp4',
        previewImageUrl: 'assets/demo/tmpl-hype-reel.jpg',
        tags: const ['Reels', 'Instagram', 'TikTok', 'Viral', 'Hook'],
        audioTrackTitle: 'Viral Reels Hit',
        audioPath: 'assets/demo/urban_trap.wav',
        isDownloaded: _downloadedIds.contains('tmpl-reels'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-festival',
        title: '🎆 Festival & Holiday Spark',
        category: 'Festival',
        badge: 'Celebration',
        description: 'Golden sparkles, firework overlays, rich celebratory colors, and festive orchestral bells.',
        author: 'Festive Sparks',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 12000,
        clipsCount: 4,
        downloadsCount: 31200,
        previewGradientStart: '0xFFFF512F',
        previewGradientEnd: '0xFFDD2476',
        previewVideoUrl: 'assets/demo/tokyo_shinjuku.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Festival', 'Celebration', 'Holidays', 'Fireworks', 'Lights'],
        audioTrackTitle: 'Festival Joy Beats',
        audioPath: 'assets/demo/tropical_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-festival'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-graduation',
        title: '🎓 Class of Success Graduation Film',
        category: 'Graduation',
        badge: 'Achievement',
        description: 'Inspiring journey timeline, diploma cap throw keyframes, proud typography, and triumphant brass.',
        author: 'Campus Moments',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 14000,
        clipsCount: 4,
        downloadsCount: 24800,
        previewGradientStart: '0xFF1D976C',
        previewGradientEnd: '0xFF93F9B9',
        previewVideoUrl: 'https://github.com/intel-iot-devkit/sample-videos/raw/master/classroom.mp4',
        previewImageUrl: 'assets/demo/tmpl-summer-tropical.jpg',
        tags: const ['Graduation', 'College', 'School', 'Diploma', 'Success'],
        audioTrackTitle: 'Triumphant March Score',
        audioPath: 'assets/demo/cinematic_audio.wav',
        isDownloaded: _downloadedIds.contains('tmpl-graduation'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-before-after',
        title: '🔄 Before & After Split Transformation',
        category: 'Before & After',
        badge: 'Transformation',
        description: 'Wipe transition comparing original raw state to finished transformation, with split title badges.',
        author: 'TransformLab',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 10000,
        clipsCount: 2,
        downloadsCount: 45600,
        previewGradientStart: '0xFF11998E',
        previewGradientEnd: '0xFF38EF7D',
        previewVideoUrl: 'assets/demo/tokyo_street.mp4',
        previewImageUrl: 'assets/demo/tmpl-urban-street.jpg',
        tags: const ['BeforeAfter', 'Transformation', 'Makeover', 'Reveal'],
        audioTrackTitle: 'Bass Hit Reveal',
        audioPath: 'assets/demo/urban_trap.wav',
        isDownloaded: _downloadedIds.contains('tmpl-before-after'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-80s-retro',
        title: '📼 1985 Synthwave Retro VHS',
        category: '80s Retro',
        badge: 'Synthwave',
        description: 'CRT scanlines, tape glitch, neon grid title typography, and pulsing analog synthesizer chords.',
        author: 'Radical 80s',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 12000,
        clipsCount: 4,
        downloadsCount: 53400,
        previewGradientStart: '0xFFFF007F',
        previewGradientEnd: '0xFF7928CA',
        previewVideoUrl: 'assets/demo/cyberpunk_arcade.mp4',
        previewImageUrl: 'assets/demo/tmpl-retro-90s.jpg',
        tags: const ['80s', 'Retro', 'Synthwave', 'VHS', 'Neon', 'Glitch'],
        audioTrackTitle: 'Analog Synth Neon Drive',
        audioPath: 'assets/demo/synthwave_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-80s-retro'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-trending',
        title: '🔥 Global Trending FYP Sensation',
        category: 'Trending',
        badge: 'Top #1',
        description: 'The #1 trending sound with synchronized micro-shakes, speed ramps, and bold kinetic text.',
        author: 'Viral King',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 11000,
        clipsCount: 4,
        downloadsCount: 89300,
        previewGradientStart: '0xFFFF416C',
        previewGradientEnd: '0xFFFF4B2B',
        previewVideoUrl: 'assets/demo/urban_skate.mp4',
        previewImageUrl: 'assets/demo/tmpl-viral-phonk.jpg',
        tags: const ['Trending', 'Viral', 'FYP', 'Explore', 'Popular'],
        audioTrackTitle: 'FYP Anthem Beats',
        audioPath: 'assets/demo/phonk_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-trending'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-photo-memories',
        title: '📷 Polaroid Photo Memories Scrapbook',
        category: 'Photo Memories',
        badge: 'Polaroid',
        description: 'Camera flash impacts, polaroid frame borders, handwritten font titles, and warm memories.',
        author: 'Scrapbook Arts',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 15000,
        clipsCount: 5,
        downloadsCount: 37400,
        previewGradientStart: '0xFF834D9B',
        previewGradientEnd: '0xFFD04ED6',
        previewVideoUrl: 'assets/demo/alps_sunrise.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Photo', 'Memories', 'Polaroid', 'Scrapbook', 'Nostalgia'],
        audioTrackTitle: 'Lo-Fi Polaroid Nostalgia',
        audioPath: 'assets/demo/lofi_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-photo-memories'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-fashion',
        title: '👠 High Fashion Runway Lookbook',
        category: 'Fashion',
        badge: 'Editorial',
        description: 'Editorial magazine split grids, strobe flash frames, clean serif typography, and deep house runway bass.',
        author: 'Atelier Visuals',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 11000,
        clipsCount: 4,
        downloadsCount: 42900,
        previewGradientStart: '0xFF232526',
        previewGradientEnd: '0xFF414345',
        previewVideoUrl: 'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/face-demographics-walking.mp4',
        previewImageUrl: 'assets/demo/tmpl-urban-street.jpg',
        isPro: true,
        tags: const ['Fashion', 'Lookbook', 'OOTD', 'Runway', 'Vogue'],
        audioTrackTitle: 'Deep House Runway Groove',
        audioPath: 'assets/demo/urban_trap.wav',
        isDownloaded: _downloadedIds.contains('tmpl-fashion'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-celebration',
        title: '🥂 Grand Celebration & Victory Party',
        category: 'Celebration',
        badge: 'Party',
        description: 'Champagne pop sound triggers, golden ribbon overlays, celebratory badges, and energetic party house.',
        author: 'Fiesta Media',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 12000,
        clipsCount: 4,
        downloadsCount: 33100,
        previewGradientStart: '0xFFF12711',
        previewGradientEnd: '0xFFF5AF19',
        previewVideoUrl: 'assets/demo/tokyo_shinjuku.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Celebration', 'Party', 'Cheers', 'Victory', 'Champagne'],
        audioTrackTitle: 'Celebration Anthem Beat',
        audioPath: 'assets/demo/tropical_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-celebration'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-business',
        title: '💼 Corporate Startup Pitch & Showcase',
        category: 'Business',
        badge: 'Corporate',
        description: 'Clean professional lower-thirds, corporate blue grading, minimal kinetic typography, and inspiring piano.',
        author: 'Venture Media',
        aspectRatio: AspectRatioType.ratio16_9,
        durationMs: 15000,
        clipsCount: 4,
        downloadsCount: 27800,
        previewGradientStart: '0xFF1E3C72',
        previewGradientEnd: '0xFF2A5298',
        previewVideoUrl: 'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/store-aisle-detection.mp4',
        previewImageUrl: 'assets/demo/tmpl-cinematic-youtube.jpg',
        isPro: true,
        tags: const ['Business', 'Corporate', 'Startup', 'Enterprise', 'Tech'],
        audioTrackTitle: 'Corporate Inspiration Piano',
        audioPath: 'assets/demo/cinematic_audio.wav',
        isDownloaded: _downloadedIds.contains('tmpl-business'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-motivation',
        title: '🦁 Daily Motivation & Mindset Grind',
        category: 'Motivation',
        badge: 'Grind',
        description: 'Deep voiceover cadence pauses, intense contrast grading, gritty camera shakes, and relentless build-up.',
        author: 'Mindset Pro',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 13000,
        clipsCount: 4,
        downloadsCount: 54100,
        previewGradientStart: '0xFF283048',
        previewGradientEnd: '0xFF859398',
        previewVideoUrl: 'assets/demo/tokyo_street.mp4',
        previewImageUrl: 'assets/demo/tmpl-hype-reel.jpg',
        tags: const ['Motivation', 'Mindset', 'Grind', 'Focus', 'Discipline'],
        audioTrackTitle: 'Relentless Grind Score',
        audioPath: 'assets/demo/cinematic_audio.wav',
        isDownloaded: _downloadedIds.contains('tmpl-motivation'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-nature',
        title: '🌿 Earth & Nature Wild Sanctuary',
        category: 'Nature',
        badge: 'Serenity',
        description: 'Lush emerald green saturation, slow cinematic pan & zoom keyframes, tranquil bird ambience, and ambient pads.',
        author: 'Earth Sanctuary',
        aspectRatio: AspectRatioType.ratio16_9,
        durationMs: 16000,
        clipsCount: 4,
        downloadsCount: 41500,
        previewGradientStart: '0xFF134E5E',
        previewGradientEnd: '0xFF71B280',
        previewVideoUrl: 'assets/demo/alps_drone.mp4',
        previewImageUrl: 'assets/demo/tmpl-cinematic-youtube.jpg',
        tags: const ['Nature', 'Wild', 'Mountains', 'Forest', 'Earth'],
        audioTrackTitle: 'Forest Ambient Waves',
        audioPath: 'assets/demo/lofi_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-nature'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-food',
        title: '🍜 Gourmet Food & Culinary Feast',
        category: 'Food',
        badge: 'Delicious',
        description: 'Sizzling sizzle-reel cuts, mouth-watering warm color boosts, recipe step overlays, and cheerful acoustic bounce.',
        author: 'Taste Bites',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 12000,
        clipsCount: 4,
        downloadsCount: 48200,
        previewGradientStart: '0xFFFF8008',
        previewGradientEnd: '0xFFFFC837',
        previewVideoUrl: 'assets/demo/ramen_bar.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Food', 'Recipe', 'Cooking', 'Gourmet', 'Delicious'],
        audioTrackTitle: 'Kitchen Cooking Groove',
        audioPath: 'assets/demo/tropical_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-food'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-fitness',
        title: '💪 High Intensity Gym & Workout Reel',
        category: 'Fitness',
        badge: 'Intensity',
        description: 'Heart-pumping BPM sync, monochrome high-contrast grading, explosive zoom impacts on reps.',
        author: 'Iron Club',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 10000,
        clipsCount: 4,
        downloadsCount: 51200,
        previewGradientStart: '0xFFED213A',
        previewGradientEnd: '0xFF93291E',
        previewVideoUrl: 'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/person-bicycle-car-detection.mp4',
        previewImageUrl: 'assets/demo/tmpl-hype-reel.jpg',
        tags: const ['Fitness', 'Gym', 'Workout', 'Bodybuilding', 'Sweat'],
        audioTrackTitle: 'High BPM Gym Motivation',
        audioPath: 'assets/demo/phonk_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-fitness'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-fast-transitions',
        title: '⚡ Rapid Whip & Zoom Cut Showcase',
        category: 'Fast Transitions',
        badge: 'Turbo',
        description: 'Supercharged 0.5s whip-pans, snap-zooms, warp-cuts, seamless continuous motion.',
        author: 'Motion Warp',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 8000,
        clipsCount: 5,
        downloadsCount: 63700,
        previewGradientStart: '0xFFFC5C7D',
        previewGradientEnd: '0xFF6A82FB',
        previewVideoUrl: 'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/car-detection.mp4',
        previewImageUrl: 'assets/demo/tmpl-urban-street.jpg',
        isPro: true,
        tags: const ['FastTransitions', 'WhipPan', 'ZoomCut', 'Kinetic'],
        audioTrackTitle: 'Rapid Snap Bounce Beat',
        audioPath: 'assets/demo/urban_trap.wav',
        isDownloaded: _downloadedIds.contains('tmpl-fast-transitions'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-viral-short',
        title: '🚀 10-Second Viral Short Video',
        category: 'Viral/Short Video',
        badge: 'Retention',
        description: 'Engineered for 100%+ viewer retention with 0.8s hook, animated captions, looping ending transition.',
        author: 'Shorts Master',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 10000,
        clipsCount: 3,
        downloadsCount: 78200,
        previewGradientStart: '0xFF00C9FF',
        previewGradientEnd: '0xFF92FE9D',
        previewVideoUrl: 'assets/demo/urban_skate.mp4',
        previewImageUrl: 'assets/demo/tmpl-viral-phonk.jpg',
        tags: const ['Viral', 'Shorts', 'Retention', 'Loop', 'Reels'],
        audioTrackTitle: 'Viral Loop Audio Track',
        audioPath: 'assets/demo/phonk_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-viral-short'),
      ),
      // ── Additional Fully Working Templates ────────────────────────────────────────
      StoreTemplateEntity(
        id: 'tmpl-sample-1',
        title: '🧊 Ice Cream Delight',
        category: 'Food',
        badge: 'Sweet',
        description: 'Smooth camera pans over delicious desserts with pastel tones and upbeat pop.',
        author: 'FreeStock',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 12000,
        clipsCount: 3,
        downloadsCount: 15000,
        previewGradientStart: '0xFF00C9FF',
        previewGradientEnd: '0xFF92FE9D',
        previewVideoUrl: 'assets/demo/ramen_bar.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Food', 'Dessert', 'IceCream', 'Pastel'],
        audioTrackTitle: 'Sweet Summer Beat',
        audioPath: 'assets/demo/tropical_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-sample-1'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-sample-2',
        title: '🚗 City Drive Rush',
        category: 'Travel',
        badge: 'Adventure',
        description: 'Fast-paced street shots with motion blur and energetic electronic music.',
        author: 'FreeStock',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 14000,
        clipsCount: 4,
        downloadsCount: 18000,
        previewGradientStart: '0xFF8E2DE2',
        previewGradientEnd: '0xFF4A00E0',
        previewVideoUrl: 'assets/demo/tokyo_street.mp4',
        previewImageUrl: 'assets/demo/tmpl-urban-street.jpg',
        tags: const ['Travel', 'City', 'Drive', 'Motion'],
        audioTrackTitle: 'Urban Pulse',
        audioPath: 'assets/demo/urban_trap.wav',
        isDownloaded: _downloadedIds.contains('tmpl-sample-2'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-sample-3',
        title: '🏔️ Mountain Sunrise',
        category: 'Nature',
        badge: 'Serenity',
        description: 'Time-lapse of sunrise over mountain peaks with calming ambient sounds.',
        author: 'FreeStock',
        aspectRatio: AspectRatioType.ratio16_9,
        durationMs: 16000,
        clipsCount: 5,
        downloadsCount: 22000,
        previewGradientStart: '0xFF134E5E',
        previewGradientEnd: '0xFF71B280',
        previewVideoUrl: 'assets/demo/alps_sunrise.mp4',
        previewImageUrl: 'assets/demo/tmpl-cinematic-youtube.jpg',
        tags: const ['Nature', 'Sunrise', 'Mountain', 'TimeLapse'],
        audioTrackTitle: 'Morning Ambient',
        audioPath: 'assets/demo/lofi_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-sample-3'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-sample-4',
        title: '💃 Dance Party Vibes',
        category: 'Party',
        badge: 'Party',
        description: 'Bright neon lights, crowd shots, and a driving house beat.',
        author: 'FreeStock',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 10000,
        clipsCount: 4,
        downloadsCount: 20000,
        previewGradientStart: '0xFFFF416C',
        previewGradientEnd: '0xFFFF4B2B',
        previewVideoUrl: 'assets/demo/tokyo_shinjuku.mp4',
        previewImageUrl: 'assets/demo/tmpl-viral-phonk.jpg',
        tags: const ['Party', 'Dance', 'Neon', 'House'],
        audioTrackTitle: 'Neon Dance Beat',
        audioPath: 'assets/demo/phonk_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-sample-4'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-sample-5',
        title: '🛸 Futuristic UI Demo',
        category: 'Tech',
        badge: 'Tech',
        description: 'Sleek UI animations with holographic overlays and synthwave soundtrack.',
        author: 'FreeStock',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 13000,
        clipsCount: 3,
        downloadsCount: 25000,
        previewGradientStart: '0xFF7928CA',
        previewGradientEnd: '0xFFF7FF00',
        previewVideoUrl: 'assets/demo/cyberpunk_arcade.mp4',
        previewImageUrl: 'assets/demo/tmpl-urban-street.jpg',
        tags: const ['Tech', 'UI', 'Futuristic', 'Synthwave'],
        audioTrackTitle: 'Synthwave Pulse',
        audioPath: 'assets/demo/synthwave_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-sample-5'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-gaming-stream',
        title: '🎮 Cyberpunk Esports Gaming Stream',
        category: 'Cinematic',
        badge: 'Pro Play',
        description: 'Neon overlays, dynamic killfeed keyframes, CRT glitch transitions, and intense synth bass.',
        author: 'CyberPlay Media',
        aspectRatio: AspectRatioType.ratio16_9,
        durationMs: 14000,
        clipsCount: 4,
        downloadsCount: 39400,
        previewGradientStart: '0xFF8A2387',
        previewGradientEnd: '0xFFE94057',
        previewVideoUrl: 'https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_1MB.mp4',
        previewImageUrl: 'assets/demo/tmpl-retro-90s.jpg',
        isPro: true,
        tags: const ['Gaming', 'Esports', 'Cyberpunk', 'Stream', 'Twitch'],
        audioTrackTitle: 'Synthwave Cyber Drive',
        audioPath: 'assets/demo/synthwave_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-gaming-stream'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-vlog-daily',
        title: '☕ Aesthetic Daily Routine Vlog',
        category: 'Family',
        badge: 'Aesthetic',
        description: 'Cozy morning coffee rituals, soft warm film filters, minimal lower-thirds, and relaxing Lo-Fi beats.',
        author: 'Daily Aesthetic',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 15000,
        clipsCount: 4,
        downloadsCount: 44100,
        previewGradientStart: '0xFFD4A373',
        previewGradientEnd: '0xFFCCD5AE',
        previewVideoUrl: 'assets/demo/ramen_bar.mp4',
        previewImageUrl: 'assets/demo/tmpl-vlog-minimal.jpg',
        tags: const ['Vlog', 'DailyRoutine', 'Aesthetic', 'Coffee', 'Minimal'],
        audioTrackTitle: 'Midnight Coffee LoFi Chill',
        audioPath: 'assets/demo/lofi_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-vlog-daily'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-sunset-acoustic',
        title: '🌅 Golden Sunset Acoustic Melody',
        category: 'Love Story',
        badge: 'Soulful',
        description: 'Dreamy golden hour backlight, soft vignette, romantic slow-motion pan, and warm acoustic guitar resonance.',
        author: 'Sunset Acoustics',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 16000,
        clipsCount: 4,
        downloadsCount: 36800,
        previewGradientStart: '0xFFF3904F',
        previewGradientEnd: '0xFF3B4371',
        previewVideoUrl: 'assets/demo/alps_sunrise.mp4',
        previewImageUrl: 'assets/demo/tmpl-golden-hour.jpg',
        tags: const ['Acoustic', 'Sunset', 'GoldenHour', 'Soulful', 'Guitar'],
        audioTrackTitle: 'Cozy Family Acoustic',
        audioPath: 'assets/demo/lofi_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-sunset-acoustic'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-cyber-neon',
        title: '⚡ Neon Hyper-Drive Glitch',
        category: 'Fast Transitions',
        badge: 'Hyper',
        description: 'Electric RGB chromatic aberration, hyperspeed light trails, bass hits on drop, and high-octane Phonk.',
        author: 'NeonFX Studio',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 9000,
        clipsCount: 5,
        downloadsCount: 58200,
        previewGradientStart: '0xFF00F260',
        previewGradientEnd: '0xFF0575E6',
        previewVideoUrl: 'assets/demo/tokyo_street.mp4',
        previewImageUrl: 'assets/demo/tmpl-urban-street.jpg',
        isPro: true,
        tags: const ['Glitch', 'Neon', 'Speed', 'Phonk', 'Drift'],
        audioTrackTitle: 'Phonk Bass Boosted',
        audioPath: 'assets/demo/phonk_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-cyber-neon'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-ocean-dive',
        title: '🌊 Deep Ocean Coral Discovery',
        category: 'Nature',
        badge: 'Tranquil',
        description: 'Majestic underwater coral reef, glowing deep-sea marine life, cinematic slow-motion drifts, and ambient ocean waves.',
        author: 'Blue Planet Lab',
        aspectRatio: AspectRatioType.ratio16_9,
        durationMs: 15000,
        clipsCount: 4,
        downloadsCount: 47900,
        previewGradientStart: '0xFF2BC0E4',
        previewGradientEnd: '0xFFEAECC6',
        previewVideoUrl: 'assets/demo/alps_drone.mp4',
        previewImageUrl: 'assets/demo/tmpl-summer-tropical.jpg',
        tags: const ['Ocean', 'Coral', 'Nature', 'Undersea', 'Tranquil'],
        audioTrackTitle: 'Forest Ambient Waves',
        audioPath: 'assets/demo/lofi_beat.wav',
        isDownloaded: _downloadedIds.contains('tmpl-ocean-dive'),
      ),
    ];
  }

  @override
  Future<List<RoyaltyFreeMusicEntity>> getMusicList() async {
    try {
      final baseUrl = await ServerConfig.getBaseUrl();
      final res = await ApiClient.get(Uri.parse('$baseUrl/api/app/content'));
      if (res.isOk && res.json is Map) {
        final json = res.json as Map<String, dynamic>;
        final musicRaw = json['music'] as List<dynamic>? ?? [];
        if (musicRaw.isNotEmpty) {
          return musicRaw.map((m) {
            var audioUrl = m['audio_url'] as String? ?? '';
            if (audioUrl.isNotEmpty && audioUrl.startsWith('/')) {
              audioUrl = '$baseUrl$audioUrl';
            }
            return RoyaltyFreeMusicEntity(
              id: m['id']?.toString() ?? 'music_unknown',
              title: m['title'] as String? ?? 'Track',
              artist: m['artist'] as String? ?? 'ProCut Music',
              genre: m['category'] as String? ?? 'Beat',
              durationMs: m['duration_ms'] is int ? m['duration_ms'] : int.tryParse(m['duration_ms'].toString()) ?? 15000,
              bpm: 128,
              mood: 'Energetic',
              audioUrl: audioUrl.isNotEmpty ? audioUrl : 'assets/demo/phonk_beat.wav',
              waveformSamples: const [0.2, 0.4, 0.9, 0.7, 0.5, 0.9, 0.3, 0.8],
            );
          }).toList();
        }
      }
    } catch (_) {}

    return const [
      RoyaltyFreeMusicEntity(
        id: 'music-phonk',
        title: 'Phonk Bass Boosted (130 BPM)',
        artist: 'ProCut Sounds',
        genre: 'Phonk',
        durationMs: 25000,
        bpm: 130,
        mood: 'Aggressive',
        audioUrl: 'assets/demo/phonk_beat.wav',
        waveformSamples: [0.2, 0.4, 0.9, 0.7, 0.5, 0.9, 0.3, 0.8],
      ),
      RoyaltyFreeMusicEntity(
        id: 'music-lofi',
        title: 'Midnight Coffee LoFi Chill',
        artist: 'ChillHop Station',
        genre: 'LoFi',
        durationMs: 30000,
        bpm: 85,
        mood: 'Chill',
        audioUrl: 'assets/demo/lofi_beat.wav',
        waveformSamples: [0.3, 0.5, 0.4, 0.6, 0.5, 0.4, 0.3, 0.2],
      ),
      RoyaltyFreeMusicEntity(
        id: 'music-tropical',
        title: 'Sunset Island Tropical House',
        artist: 'Palma Grooves',
        genre: 'Tropical',
        durationMs: 28000,
        bpm: 120,
        mood: 'Happy',
        audioUrl: 'assets/demo/tropical_beat.wav',
        waveformSamples: [0.4, 0.6, 0.8, 0.7, 0.9, 0.6, 0.5, 0.3],
      ),
      RoyaltyFreeMusicEntity(
        id: 'music-cinematic',
        title: 'Epic Orchestral Horizon',
        artist: 'CinemaLab',
        genre: 'Cinematic',
        durationMs: 24000,
        bpm: 110,
        mood: 'Epic',
        audioUrl: 'assets/demo/cinematic_audio.wav',
        waveformSamples: [0.1, 0.3, 0.5, 0.7, 0.9, 0.8, 0.6, 0.4],
      ),
      RoyaltyFreeMusicEntity(
        id: 'music-urban',
        title: 'Tokyo Street Trap 808',
        artist: 'MetroBeats',
        genre: 'Trap',
        durationMs: 20000,
        bpm: 140,
        mood: 'Hype',
        audioUrl: 'assets/demo/urban_trap.wav',
        waveformSamples: [0.5, 0.8, 0.7, 0.9, 0.6, 0.7, 0.5, 0.4],
      ),
      RoyaltyFreeMusicEntity(
        id: 'music-synthwave',
        title: '1985 Neon Synthwave Drive',
        artist: 'CyberDrive',
        genre: 'Synthwave',
        durationMs: 18000,
        bpm: 125,
        mood: 'Retro',
        audioUrl: 'assets/demo/synthwave_beat.wav',
        waveformSamples: [0.3, 0.6, 0.8, 0.7, 0.9, 0.8, 0.5, 0.3],
      ),
    ];
  }

  @override
  Future<void> markDownloaded(String id) async {
    _downloadedIds.add(id);
    try {
      final baseUrl = await ServerConfig.getBaseUrl();
      await ApiClient.post(
        Uri.parse('$baseUrl/api/templates'),
        body: {'id': id, 'action': 'download'},
      );
    } catch (_) {}
  }
}
