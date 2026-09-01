import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looma/core/storage/storage_providers.dart';
import 'package:looma/core/utils/id_generator.dart';
import 'package:looma/features/projects/data/datasources/project_local_datasource.dart';
import 'package:looma/features/projects/data/repositories/project_repository_impl.dart';
import 'package:looma/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:looma/features/editor/domain/entities/transition_type.dart';
import 'package:looma/features/editor/domain/entities/video_clip_entity.dart';
import 'package:looma/features/filters_effects/domain/entities/filter_preset.dart';
import 'package:looma/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/repositories/project_repository.dart';
import 'package:looma/features/projects/domain/usecases/project_usecases.dart';
import 'package:looma/features/text_stickers/domain/entities/overlay_animation_type.dart';
import 'package:looma/features/text_stickers/domain/entities/text_overlay_entity.dart';

// --- Data Sources & Repositories ---
final projectLocalDataSourceProvider = Provider<ProjectLocalDataSource>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ProjectLocalDataSourceImpl(storageService: storage);
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dataSource = ref.watch(projectLocalDataSourceProvider);
  return ProjectRepositoryImpl(localDataSource: dataSource);
});

// --- Use Cases ---
final getProjectsUseCaseProvider = Provider<GetProjectsUseCase>((ref) {
  return GetProjectsUseCase(ref.watch(projectRepositoryProvider));
});

final getProjectByIdUseCaseProvider = Provider<GetProjectByIdUseCase>((ref) {
  return GetProjectByIdUseCase(ref.watch(projectRepositoryProvider));
});

final saveProjectUseCaseProvider = Provider<SaveProjectUseCase>((ref) {
  return SaveProjectUseCase(ref.watch(projectRepositoryProvider));
});

final updateProjectUseCaseProvider = Provider<UpdateProjectUseCase>((ref) {
  return UpdateProjectUseCase(ref.watch(projectRepositoryProvider));
});

final duplicateProjectUseCaseProvider = Provider<DuplicateProjectUseCase>((ref) {
  return DuplicateProjectUseCase(ref.watch(projectRepositoryProvider));
});

final deleteProjectUseCaseProvider = Provider<DeleteProjectUseCase>((ref) {
  return DeleteProjectUseCase(ref.watch(projectRepositoryProvider));
});

// --- Filters & Search State ---
final projectSearchQueryProvider = StateProvider<String>((ref) => '');
final projectFilterRatioProvider = StateProvider<AspectRatioType?>((ref) => null);

// --- Projects List State Notifier ---
class ProjectsState {
  final bool isLoading;
  final List<ProjectEntity> projects;
  final String? errorMessage;

  const ProjectsState({
    this.isLoading = false,
    this.projects = const [],
    this.errorMessage,
  });

  ProjectsState copyWith({
    bool? isLoading,
    List<ProjectEntity>? projects,
    String? errorMessage,
  }) {
    return ProjectsState(
      isLoading: isLoading ?? this.isLoading,
      projects: projects ?? this.projects,
      errorMessage: errorMessage,
    );
  }
}

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final GetProjectsUseCase getProjectsUseCase;
  final SaveProjectUseCase saveProjectUseCase;
  final DuplicateProjectUseCase duplicateProjectUseCase;
  final DeleteProjectUseCase deleteProjectUseCase;

  ProjectsNotifier({
    required this.getProjectsUseCase,
    required this.saveProjectUseCase,
    required this.duplicateProjectUseCase,
    required this.deleteProjectUseCase,
  }) : super(const ProjectsState(isLoading: true)) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await getProjectsUseCase();
      state = state.copyWith(isLoading: false, projects: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<ProjectEntity> createProject({
    required String title,
    required AspectRatioType aspectRatio,
    int fps = 30,
    List<VideoClipEntity>? initialClips,
  }) async {
    final clips = initialClips ?? [];
    int totalDur = 0;
    if (clips.isNotEmpty) {
      totalDur = clips.last.timelineEndMs;
    } else {
      totalDur = 10000;
    }

    final newProject = ProjectEntity(
      id: IdGenerator.generate(),
      title: title.trim().isEmpty ? 'Untitled Project' : title.trim(),
      aspectRatio: aspectRatio,
      fps: fps,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      durationMs: totalDur,
      videoClips: clips,
    );

    await saveProjectUseCase(newProject);
    await loadProjects();
    return newProject;
  }

  Future<ProjectEntity> createProjectFromTemplate({
    required String title,
    required AspectRatioType aspectRatio,
    required int durationMs,
    required int clipsCount,
    String? audioTrackTitle,
    String? audioPath,
    List<String>? userMediaPaths,
  }) async {
    final List<VideoClipEntity> templateClips = [];
    final int clipDuration = (durationMs / clipsCount).round();
    int currentOffset = 0;

    final sampleAssets = [
      'assets/demo/tokyo_shinjuku.mp4',
      'assets/demo/alps_sunrise.mp4',
      'assets/demo/cyberpunk_arcade.mp4',
      'assets/demo/sunset_beach.jpg',
      'assets/demo/coffee_art.jpg',
      'assets/demo/urban_skate.mp4',
    ];

    final filters = FilterType.values;
    final transitions = TransitionType.values;

    for (int i = 0; i < clipsCount; i++) {
      String assetPath;
      if (userMediaPaths != null && i < userMediaPaths.length && userMediaPaths[i].isNotEmpty) {
        assetPath = userMediaPaths[i];
      } else {
        assetPath = sampleAssets[i % sampleAssets.length];
      }

      final filter = filters[(i + 1) % filters.length];
      final transition = transitions[(i + 1) % transitions.length];

      templateClips.add(
        VideoClipEntity(
          id: IdGenerator.generate(),
          mediaPath: assetPath,
          name: 'Slot #${i + 1} (${assetPath.split('/').last.split('.').first})',
          sourceDurationMs: clipDuration,
          timelineStartMs: currentOffset,
          timelineEndMs: currentOffset + clipDuration,
          trimStartMs: 0,
          trimEndMs: clipDuration,
          filterType: filter,
          transitionIn: transition,
        ),
      );
      currentOffset += clipDuration;
    }

    final templateTexts = [
      TextOverlayEntity(
        id: IdGenerator.generate(),
        text: title,
        fontFamily: 'Inter',
        fontSize: 24,
        colorHex: 0xFFFFFFFF,
        backgroundColorHex: 0xFF8B5CF6,
        timelineStartMs: 0,
        timelineEndMs: (durationMs * 0.4).round(),
        animationType: OverlayAnimationType.slideUp,
        posX: 0.5,
        posY: 0.75,
      ),
      TextOverlayEntity(
        id: IdGenerator.generate(),
        text: 'Template Synced ✨',
        fontFamily: 'SpaceMono',
        fontSize: 20,
        colorHex: 0xFF06B6D4,
        timelineStartMs: (durationMs * 0.4).round(),
        timelineEndMs: durationMs,
        animationType: OverlayAnimationType.typewriter,
        posX: 0.5,
        posY: 0.85,
      ),
    ];

    final templateAudio = [
      AudioClipEntity(
        id: IdGenerator.generate(),
        mediaPath: audioPath ?? 'assets/demo/lofi_beat.mp3',
        title: audioTrackTitle ?? 'Template Beat Mix',
        timelineStartMs: 0,
        timelineEndMs: durationMs,
        trimEndMs: durationMs,
        category: AudioCategory.music,
        volume: 0.95,
      ),
    ];

    final newProject = ProjectEntity(
      id: IdGenerator.generate(),
      title: title.trim().isEmpty ? 'Template Project' : title.trim(),
      aspectRatio: aspectRatio,
      fps: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      durationMs: durationMs,
      videoClips: templateClips,
      textOverlays: templateTexts,
      audioClips: templateAudio,
    );

    await saveProjectUseCase(newProject);
    await loadProjects();
    return newProject;
  }

  Future<void> duplicateProject(String id) async {
    try {
      await duplicateProjectUseCase(id);
      await loadProjects();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to duplicate project: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await deleteProjectUseCase(id);
      await loadProjects();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete project: $e');
    }
  }
}

final projectsNotifierProvider =
    StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  return ProjectsNotifier(
    getProjectsUseCase: ref.watch(getProjectsUseCaseProvider),
    saveProjectUseCase: ref.watch(saveProjectUseCaseProvider),
    duplicateProjectUseCase: ref.watch(duplicateProjectUseCaseProvider),
    deleteProjectUseCase: ref.watch(deleteProjectUseCaseProvider),
  );
});

/// Filtered projects selector provider
final filteredProjectsProvider = Provider<List<ProjectEntity>>((ref) {
  final state = ref.watch(projectsNotifierProvider);
  final query = ref.watch(projectSearchQueryProvider).toLowerCase();
  final ratioFilter = ref.watch(projectFilterRatioProvider);

  return state.projects.where((p) {
    final matchesQuery = query.isEmpty || p.title.toLowerCase().contains(query);
    final matchesRatio = ratioFilter == null || p.aspectRatio == ratioFilter;
    return matchesQuery && matchesRatio;
  }).toList();
});
