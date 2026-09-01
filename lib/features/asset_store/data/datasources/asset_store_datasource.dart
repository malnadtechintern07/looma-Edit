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
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      StoreTemplateEntity(
        id: 'tmpl-viral-phonk',
        title: '🔥 Viral Phonk Drift Reel',
        description: 'Fast rhythmic cuts, heavy bass drop transitions, and neon cyberpunk subtitle styling.',
        author: 'Looma Originals',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 10000,
        clipsCount: 6,
        downloadsCount: 38400,
        previewGradientStart: '0xFF7C3AED',
        previewGradientEnd: '0xFFEC4899',
        tags: const ['Trending', 'Phonk', 'Reels', 'TikTok', 'Viral'],
        audioTrackTitle: 'Phonk Bass Boosted (130 BPM)',
        audioPath: 'assets/demo/phonk_beat.mp3',
        isDownloaded: _downloadedIds.contains('tmpl-viral-phonk'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-summer-tropical',
        title: '🌴 Summer Tropical Vlog',
        description: 'Warm film grain, upbeat tropical rhythm, and smooth cross-fade slide transitions.',
        author: 'Nordic Visuals',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 14000,
        clipsCount: 7,
        downloadsCount: 29800,
        previewGradientStart: '0xFFF59E0B',
        previewGradientEnd: '0xFF10B981',
        tags: const ['Vlog', 'Summer', 'Travel', 'Aesthetic'],
        audioTrackTitle: 'Sunset Tropical House Beats',
        audioPath: 'assets/demo/tropical_beat.mp3',
        isDownloaded: _downloadedIds.contains('tmpl-summer-tropical'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-hype-reel',
        title: '⚡ Fast Cuts Cyberpunk Reel',
        description: 'High-energy glitch cuts with neon subtitle animations and beat drops.',
        author: 'Cyber Studio',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 9000,
        clipsCount: 6,
        downloadsCount: 14200,
        previewGradientStart: '0xFF8B5CF6',
        previewGradientEnd: '0xFF06B6D4',
        tags: const ['Cyberpunk', 'Glitch', 'Edits', 'FastCuts'],
        audioTrackTitle: 'Neon Synthwave Drive',
        audioPath: 'assets/demo/synthwave_beat.mp3',
        isDownloaded: _downloadedIds.contains('tmpl-hype-reel'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-vlog-minimal',
        title: '✨ Minimalist Day-in-the-Life',
        description: 'Aesthetic typography, subtle film texture, and relaxing lofi rhythm.',
        author: 'Minimal Co',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 15000,
        clipsCount: 5,
        downloadsCount: 19800,
        previewGradientStart: '0xFFD97706',
        previewGradientEnd: '0xFFB45309',
        tags: const ['Minimalist', 'DailyVlog', 'LoFi', 'Aesthetic'],
        audioTrackTitle: 'Midnight LoFi Chillout',
        audioPath: 'assets/demo/lofi_beat.mp3',
        isDownloaded: _downloadedIds.contains('tmpl-vlog-minimal'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-cinematic-youtube',
        title: '🎬 Cinematic Widescreen Intro',
        description: 'Epic letterbox 16:9 presentation with orchestral crescendo and bold lower-third title.',
        author: 'Studio Horizon',
        aspectRatio: AspectRatioType.ratio16_9,
        durationMs: 12000,
        clipsCount: 4,
        downloadsCount: 22100,
        previewGradientStart: '0xFF1E3A8A',
        previewGradientEnd: '0xFF065F46',
        tags: const ['YouTube', '16:9', 'Cinematic', 'Intro'],
        audioTrackTitle: 'Orchestral Cinematic Crescendo',
        audioPath: 'assets/demo/cinematic_audio.mp3',
        isDownloaded: _downloadedIds.contains('tmpl-cinematic-youtube'),
      ),
      StoreTemplateEntity(
        id: 'tmpl-fitness-workout',
        title: '💪 High-Tempo Workout Montage',
        description: 'BPM-synced beat drops with speed ramping and vibrant contrast boost.',
        author: 'Pulse Media',
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 10000,
        clipsCount: 8,
        downloadsCount: 17400,
        previewGradientStart: '0xFFEF4444',
        previewGradientEnd: '0xFF7C2D12',
        tags: const ['Fitness', 'Workout', 'BPM', 'Montage'],
        audioTrackTitle: 'Workout EDM Pump Beat',
        audioPath: 'assets/demo/edm_workout.mp3',
        isDownloaded: _downloadedIds.contains('tmpl-fitness-workout'),
      ),
    ];
  }

  @override
  Future<List<RoyaltyFreeMusicEntity>> getMusicList() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return [
      RoyaltyFreeMusicEntity(
        id: 'music-future-chill',
        title: 'Midnight Lofi Chill',
        artist: 'Aether Beats',
        genre: 'Lofi / Chillout',
        durationMs: 45000,
        bpm: 82,
        mood: 'Relaxing',
        audioUrl: 'https://cdn.looma.app/audio/midnight_lofi.mp3',
        waveformSamples: [
          0.3, 0.4, 0.6, 0.7, 0.5, 0.65, 0.8, 0.75, 0.4, 0.5, 0.7, 0.85, 0.9, 0.6, 0.4, 0.2
        ],
        isDownloaded: _downloadedIds.contains('music-future-chill'),
      ),
      RoyaltyFreeMusicEntity(
        id: 'music-synthwave-ride',
        title: 'Neon Highway Drive',
        artist: 'Retrowave Collective',
        genre: 'Synthwave / Electronic',
        durationMs: 38000,
        bpm: 124,
        mood: 'Energetic',
        audioUrl: 'https://cdn.looma.app/audio/neon_highway.mp3',
        waveformSamples: [
          0.5, 0.7, 0.9, 0.85, 0.95, 0.8, 0.85, 0.9, 0.7, 0.8, 0.95, 1.0, 0.75, 0.6, 0.4
        ],
        isDownloaded: _downloadedIds.contains('music-synthwave-ride'),
      ),
      RoyaltyFreeMusicEntity(
        id: 'music-ambient-peace',
        title: 'Dawn Over Horizon',
        artist: 'Serenity Audio',
        genre: 'Cinematic Ambient',
        durationMs: 60000,
        bpm: 68,
        mood: 'Inspirational',
        audioUrl: 'https://cdn.looma.app/audio/dawn_horizon.mp3',
        waveformSamples: [
          0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.85, 0.75, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1
        ],
        isDownloaded: _downloadedIds.contains('music-ambient-peace'),
      ),
    ];
  }

  @override
  Future<void> markDownloaded(String id) async {
    _downloadedIds.add(id);
  }
}
