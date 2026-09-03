import 'dart:convert';
import 'package:looma/core/constants/app_constants.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/core/utils/id_generator.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/transition_type.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/filters_effects/domain/entities/filter_preset.dart';
import 'package:looma/features/projects/data/models/project_model.dart';
import 'package:looma/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/entities/sync_status_type.dart';
import 'package:looma/features/text_stickers/domain/entities/overlay_animation_type.dart';
import 'package:looma/features/text_stickers/domain/entities/sticker_overlay_entity.dart';
import 'package:looma/features/text_stickers/domain/entities/text_overlay_entity.dart';

abstract class ProjectLocalDataSource {
  Future<List<ProjectEntity>> getProjects();
  Future<ProjectEntity?> getProjectById(String id);
  Future<void> saveProject(ProjectEntity project);
  Future<void> updateProject(ProjectEntity project);
  Future<ProjectEntity> duplicateProject(String id);
  Future<void> deleteProject(String id);
}

class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  final LocalStorageService storageService;

  ProjectLocalDataSourceImpl({required this.storageService});

  String _getProjectPath(String id) => '${AppConstants.projectsDirectory}/project_$id.json';

  @override
  Future<List<ProjectEntity>> getProjects() async {
    final catalogRaw = await storageService.readString(AppConstants.projectsCatalogFile);
    final Set<String> projectIds = {};

    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        for (final item in decoded) {
          if (item != null && item.toString().trim().isNotEmpty) {
            projectIds.add(item.toString().trim());
          }
        }
      } catch (_) {}
    }

    // Auto-discover all project files stored in the projects directory on disk
    final diskFiles = await storageService.listProjectFiles();
    for (final filePath in diskFiles) {
      final fileName = filePath.split('/').last;
      if (fileName.startsWith('project_') && fileName.endsWith('.json')) {
        final id = fileName.substring('project_'.length, fileName.length - '.json'.length);
        if (id.isNotEmpty) {
          projectIds.add(id);
        }
      }
    }

    // Seed default starter projects ONLY on very first install when nothing exists
    final seededFlag = await storageService.readString('app_seeded.flag');
    if (projectIds.isEmpty && seededFlag == null) {
      await storageService.writeString('app_seeded.flag', 'true');
      final initialProjects = _getSampleInitialProjects();
      for (final p in initialProjects) {
        await saveProject(p);
      }
      return initialProjects;
    }

    if (seededFlag == null) {
      await storageService.writeString('app_seeded.flag', 'true');
    }

    final List<ProjectEntity> results = [];
    final List<String> validIds = [];

    for (final id in projectIds) {
      final p = await getProjectById(id);
      if (p != null) {
        results.add(p);
        validIds.add(id);
      }
    }

    // Keep catalog in sync with valid project files
    if (validIds.length != projectIds.length) {
      await storageService.writeString(AppConstants.projectsCatalogFile, jsonEncode(validIds));
    }

    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  @override
  Future<ProjectEntity?> getProjectById(String id) async {
    final jsonMap = await storageService.readJson(_getProjectPath(id));
    if (jsonMap == null) return null;
    return ProjectModel.fromJson(jsonMap);
  }

  @override
  Future<void> saveProject(ProjectEntity project) async {
    final path = _getProjectPath(project.id);
    await storageService.writeJson(path, ProjectModel.toJson(project));

    // Update catalog
    final catalogRaw = await storageService.readString(AppConstants.projectsCatalogFile);
    List<String> projectIds = [];
    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        projectIds = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      } catch (_) {}
    }
    projectIds.remove(project.id);
    projectIds.insert(0, project.id);
    await storageService.writeString(AppConstants.projectsCatalogFile, jsonEncode(projectIds));
    await storageService.writeString('app_seeded.flag', 'true');
  }

  @override
  Future<void> updateProject(ProjectEntity project) async {
    final updated = project.copyWith(updatedAt: DateTime.now());
    await saveProject(updated);
  }

  @override
  Future<ProjectEntity> duplicateProject(String id) async {
    final original = await getProjectById(id);
    if (original == null) {
      throw Exception('Cannot duplicate non-existent project $id');
    }

    final newId = IdGenerator.generate();
    final duplicated = original.copyWith(
      id: newId,
      title: '${original.title} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatusType.localOnly,
    );

    await saveProject(duplicated);
    return duplicated;
  }

  @override
  Future<void> deleteProject(String id) async {
    await storageService.deleteFile(_getProjectPath(id));

    final catalogRaw = await storageService.readString(AppConstants.projectsCatalogFile);
    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        final projectIds = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        projectIds.remove(id);
        await storageService.writeString(AppConstants.projectsCatalogFile, jsonEncode(projectIds));
      } catch (_) {}
    }
  }

  List<ProjectEntity> _getSampleInitialProjects() {
    final now = DateTime.now();
    return [
      ProjectEntity(
        id: 'sample-tokyo-vlog',
        title: 'Tokyo Night Cyberpunk Reel',
        aspectRatio: AspectRatioType.ratio9_16,
        fps: 60,
        resolutionWidth: 1080,
        resolutionHeight: 1920,
        durationMs: 12000,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
        syncStatus: SyncStatusType.synced,
        videoClips: [
          const VideoClipEntity(
            id: 'vclip-1',
            mediaPath: 'assets/demo/tokyo_street.mp4',
            name: 'Neon Shinjuku Crossing',
            sourceDurationMs: 6000,
            timelineStartMs: 0,
            timelineEndMs: 5000,
            trimStartMs: 0,
            trimEndMs: 5000,
            speed: 1.0,
            filterType: FilterType.cyberpunk,
            contrast: 1.15,
            saturation: 1.25,
            transitionIn: TransitionType.none,
          ),
          const VideoClipEntity(
            id: 'vclip-2',
            mediaPath: 'assets/demo/ramen_bar.mp4',
            name: 'Late Night Ramen Steam',
            sourceDurationMs: 8000,
            timelineStartMs: 5000,
            timelineEndMs: 12000,
            trimStartMs: 1000,
            trimEndMs: 8000,
            speed: 1.0,
            filterType: FilterType.cyberpunk,
            contrast: 1.1,
            saturation: 1.2,
            transitionIn: TransitionType.glitch,
            transitionDurationMs: 400,
          ),
        ],
        audioClips: [
          const AudioClipEntity(
            id: 'aclip-1',
            mediaPath: 'assets/audio/synthwave_beat.mp3',
            title: 'Midnight Synth Wave',
            category: AudioCategory.music,
            timelineStartMs: 0,
            timelineEndMs: 12000,
            trimStartMs: 0,
            trimEndMs: 12000,
            volume: 0.8,
            fadeInMs: 500,
            fadeOutMs: 1000,
            waveformSamples: [
              0.2, 0.4, 0.7, 0.9, 0.6, 0.8, 0.95, 0.7, 0.5, 0.85, 0.9, 0.4, 0.6, 0.8, 0.75,
              0.3, 0.5, 0.8, 0.9, 0.65, 0.7, 0.85, 0.6, 0.4, 0.7, 0.8, 0.3, 0.2
            ],
          ),
        ],
        textOverlays: [
          const TextOverlayEntity(
            id: 'text-1',
            text: 'TOKYO VLOG // 01',
            fontFamily: 'Inter',
            fontSize: 28.0,
            colorHex: 0xFF00FFFF,
            outlineColorHex: 0xFF000000,
            outlineWidth: 2.0,
            posX: 0.5,
            posY: 0.25,
            timelineStartMs: 500,
            timelineEndMs: 4500,
            animationType: OverlayAnimationType.typewriter,
          ),
        ],
        stickerOverlays: [
          const StickerOverlayEntity(
            id: 'sticker-1',
            stickerKey: 'neon_fire',
            stickerName: 'Fire Flame',
            assetEmojiOrPath: '🔥',
            posX: 0.8,
            posY: 0.25,
            scale: 1.3,
            timelineStartMs: 1000,
            timelineEndMs: 4500,
          ),
        ],
      ),
      ProjectEntity(
        id: 'sample-cinematic-trailer',
        title: 'Cinematic Mountain Drone',
        aspectRatio: AspectRatioType.ratio16_9,
        fps: 24,
        resolutionWidth: 1920,
        resolutionHeight: 1080,
        durationMs: 15000,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 18)),
        syncStatus: SyncStatusType.localOnly,
        videoClips: [
          const VideoClipEntity(
            id: 'vclip-drone',
            mediaPath: 'assets/demo/alps_drone.mp4',
            name: 'Alps Sunrise Fog',
            sourceDurationMs: 15000,
            timelineStartMs: 0,
            timelineEndMs: 15000,
            trimStartMs: 0,
            trimEndMs: 15000,
            speed: 1.0,
            filterType: FilterType.cinematic,
            contrast: 1.2,
            saturation: 1.1,
          ),
        ],
        audioClips: [
          const AudioClipEntity(
            id: 'aclip-ambient',
            mediaPath: 'assets/audio/epic_orchestral.mp3',
            title: 'Epic Awakening Orchestral',
            category: AudioCategory.music,
            timelineStartMs: 0,
            timelineEndMs: 15000,
            trimStartMs: 0,
            trimEndMs: 15000,
            volume: 1.0,
            waveformSamples: [
              0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.85, 0.95, 0.8, 0.85, 0.9, 0.7, 0.5, 0.3, 0.1
            ],
          ),
        ],
        textOverlays: [
          const TextOverlayEntity(
            id: 'text-cinematic',
            text: 'THE ASCENT',
            fontFamily: 'Inter',
            fontSize: 36.0,
            colorHex: 0xFFFFFFFF,
            posX: 0.5,
            posY: 0.5,
            timelineStartMs: 2000,
            timelineEndMs: 8000,
            animationType: OverlayAnimationType.fadeIn,
          ),
        ],
      ),
    ];
  }
}
