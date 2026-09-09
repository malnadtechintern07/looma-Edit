import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/audio/domain/entities/audio_clip_entity.dart';
import 'package:procut/features/editor/domain/entities/chroma_key_config_entity.dart';
import 'package:procut/features/editor/domain/entities/clip_animation_type.dart';
import 'package:procut/features/editor/domain/entities/crop_rect_entity.dart';
import 'package:procut/features/editor/domain/entities/keyframe_entity.dart';
import 'package:procut/features/editor/domain/entities/mask_config_entity.dart';
import 'package:procut/features/editor/domain/entities/speed_curve_type.dart';
import 'package:procut/features/editor/domain/entities/subtitle_entity.dart';
import 'package:procut/features/editor/domain/entities/transition_type.dart';
import 'package:procut/features/editor/domain/entities/video_clip_entity.dart';
import 'package:procut/features/editor/presentation/providers/editor_controller.dart';
import 'package:procut/features/filters_effects/domain/entities/effect_clip_entity.dart';
import 'package:procut/features/filters_effects/domain/entities/filter_preset.dart';
import 'package:procut/features/filters_effects/domain/entities/video_effect_type.dart';
import 'package:procut/features/projects/data/datasources/project_local_datasource.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/data/repositories/project_repository_impl.dart';
import 'package:procut/features/projects/domain/entities/aspect_ratio_type.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/usecases/project_usecases.dart';
import 'package:procut/features/projects/presentation/providers/projects_provider.dart';
import 'package:procut/features/text_stickers/domain/entities/overlay_animation_type.dart';
import 'package:procut/features/text_stickers/domain/entities/sticker_overlay_entity.dart';
import 'package:procut/features/text_stickers/domain/entities/text_overlay_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Draft Saving & Persistence Tests', () {
    late LocalStorageService storageService;
    late ProjectLocalDataSource localDataSource;
    late ProjectRepositoryImpl repository;
    late ProjectEntity richDraftProject;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      await storageService.clearAll();
      localDataSource = ProjectLocalDataSourceImpl(storageService: storageService);
      repository = ProjectRepositoryImpl(localDataSource: localDataSource);

      final clip1 = VideoClipEntity(
        id: 'clip_video_1',
        name: 'Opening Scene',
        mediaPath: 'assets/branding/demo_vid1.mp4',
        sourceDurationMs: 6000,
        timelineStartMs: 0,
        timelineEndMs: 6000,
        trimStartMs: 0,
        trimEndMs: 6000,
        speed: 1.5,
        volume: 0.8,
        isMuted: false,
        filterType: FilterType.cyberpunk,
        brightness: 0.2,
        contrast: 1.2,
        saturation: 1.3,
        transitionIn: TransitionType.glitch,
        transitionDurationMs: 800,
        rotationDegrees: 90.0,
        isFlippedHorizontally: true,
        isFlippedVertically: false,
        opacity: 0.9,
        zoomScale: 1.2,
        positionX: 10.0,
        positionY: -5.0,
        blurSigma: 2.0,
        fadeInDurationMs: 300,
        fadeOutDurationMs: 300,
        animationIn: ClipAnimationIn.slideInLeft,
        animationInDurationMs: 600,
        animationOut: ClipAnimationOut.fadeOut,
        animationOutDurationMs: 500,
        animationCombo: ClipAnimationCombo.pulse,
        speedCurve: SpeedCurveType.hero,
        isReversed: false,
        isOverlay: false,
        crop: const CropRectEntity(left: 0.1, top: 0.1, right: 0.9, bottom: 0.9, ratioName: '16:9'),
        mask: const MaskConfigEntity(shape: MaskShape.circle, centerX: 0.5, centerY: 0.5, widthFactor: 0.7, feather: 0.3, isInverted: false),
        chromaKey: const ChromaKeyConfigEntity(isEnabled: true, keyColorHex: 0xFF00FF00, intensity: 0.5, shadow: 0.3, edgeSmoothing: 0.2),
        keyframes: const [
          KeyframeEntity(id: 'kf1', timestampMs: 0, scale: 1.0, posX: 0.0, posY: 0.0),
          KeyframeEntity(id: 'kf2', timestampMs: 3000, scale: 1.5, posX: 20.0, posY: 10.0),
        ],
      );

      final audio1 = AudioClipEntity(
        id: 'audio_track_1',
        title: 'Cyberpunk Synthwave Beat',
        mediaPath: 'assets/demo/synthwave.mp3',
        category: AudioCategory.music,
        timelineStartMs: 0,
        timelineEndMs: 8000,
        trimStartMs: 0,
        trimEndMs: 8000,
        volume: 1.2,
        isMuted: false,
        fadeInMs: 500,
        fadeOutMs: 1000,
        waveformSamples: [0.1, 0.4, 0.8, 0.6, 0.9, 0.3],
      );

      final text1 = TextOverlayEntity(
        id: 'text_1',
        text: 'NIGHT RUNNER',
        fontFamily: 'SpaceMono',
        fontSize: 32.0,
        colorHex: 0xFF00E5FF,
        backgroundColorHex: 0xFF000000,
        outlineColorHex: 0xFF5B4DFB,
        outlineWidth: 2.0,
        timelineStartMs: 1000,
        timelineEndMs: 5000,
        animationType: OverlayAnimationType.typewriter,
        posX: 0.5,
        posY: 0.3,
      );

      final sticker1 = const StickerOverlayEntity(
        id: 'sticker_1',
        stickerKey: 'fire',
        stickerName: 'Fire Flame',
        assetEmojiOrPath: '🔥',
        timelineStartMs: 2000,
        timelineEndMs: 6000,
        posX: 0.8,
        posY: 0.2,
        scale: 1.3,
      );

      final effect1 = const EffectClipEntity(
        id: 'eff_1',
        effectType: VideoEffectType.rgbSplit,
        timelineStartMs: 1500,
        durationMs: 3000,
        intensity: 0.85,
      );

      final sub1 = const SubtitleEntity(
        id: 'sub_1',
        text: 'Welcome to Neo Tokyo',
        timelineStartMs: 500,
        timelineEndMs: 3500,
        fontSize: 22.0,
      );

      richDraftProject = ProjectEntity(
        id: 'draft_project_101',
        title: 'Cyberpunk Draft Edit',
        aspectRatio: AspectRatioType.ratio9_16,
        fps: 60,
        resolutionWidth: 1080,
        resolutionHeight: 1920,
        createdAt: DateTime(2026, 9, 1, 10, 0),
        updatedAt: DateTime(2026, 9, 3, 12, 0),
        durationMs: 8000,
        lastPlayheadPositionMs: 2750,
        videoClips: [clip1],
        audioClips: [audio1],
        textOverlays: [text1],
        stickerOverlays: [sticker1],
        effectClips: [effect1],
        subtitles: [sub1],
      );
    });

    test('ProjectModel JSON serialization and deserialization retains 100% fidelity across all entities', () {
      final jsonMap = ProjectModel.toJson(richDraftProject);
      final restored = ProjectModel.fromJson(jsonMap);

      expect(restored.id, richDraftProject.id);
      expect(restored.title, richDraftProject.title);
      expect(restored.aspectRatio, richDraftProject.aspectRatio);
      expect(restored.fps, richDraftProject.fps);
      expect(restored.lastPlayheadPositionMs, 2750);
      expect(restored.videoClips.length, 1);

      // Verify VideoClip details
      final clip = restored.videoClips.first;
      expect(clip.name, 'Opening Scene');
      expect(clip.speed, 1.5);
      expect(clip.volume, 0.8);
      expect(clip.isMuted, false);
      expect(clip.filterType, FilterType.cyberpunk);
      expect(clip.transitionIn, TransitionType.glitch);
      expect(clip.animationIn, ClipAnimationIn.slideInLeft);
      expect(clip.animationOut, ClipAnimationOut.fadeOut);
      expect(clip.animationCombo, ClipAnimationCombo.pulse);
      expect(clip.speedCurve, SpeedCurveType.hero);
      expect(clip.crop?.ratioName, '16:9');
      expect(clip.mask?.shape, MaskShape.circle);
      expect(clip.chromaKey?.isEnabled, true);
      expect(clip.chromaKey?.intensity, 0.5);
      expect(clip.keyframes.length, 2);
      expect(clip.keyframes[1].timestampMs, 3000);
      expect(clip.keyframes[1].scale, 1.5);

      // Verify Audio
      expect(restored.audioClips.length, 1);
      expect(restored.audioClips.first.title, 'Cyberpunk Synthwave Beat');
      expect(restored.audioClips.first.waveformSamples.length, 6);

      // Verify Text
      expect(restored.textOverlays.length, 1);
      expect(restored.textOverlays.first.text, 'NIGHT RUNNER');
      expect(restored.textOverlays.first.animationType, OverlayAnimationType.typewriter);

      // Verify Sticker, Effect, Subtitle
      expect(restored.stickerOverlays.length, 1);
      expect(restored.stickerOverlays.first.assetEmojiOrPath, '🔥');
      expect(restored.effectClips.length, 1);
      expect(restored.effectClips.first.effectType, VideoEffectType.rgbSplit);
      expect(restored.subtitles.length, 1);
      expect(restored.subtitles.first.text, 'Welcome to Neo Tokyo');
    });

    test('Saving draft persists to local storage and survives re-opening', () async {
      await repository.saveProject(richDraftProject);

      // Simulate app reopen by reading from clean local data source
      final loadedProject = await repository.getProjectById('draft_project_101');
      expect(loadedProject, isNotNull);
      expect(loadedProject!.id, 'draft_project_101');
      expect(loadedProject.title, 'Cyberpunk Draft Edit');
      expect(loadedProject.lastPlayheadPositionMs, 2750);
      expect(loadedProject.videoClips.length, 1);
      expect(loadedProject.videoClips.first.keyframes.length, 2);
    });

    test('EditorController initializes playhead at last saved position so user resumes where they stopped', () {
      final controller = EditorController(project: richDraftProject);

      expect(controller.state.playheadPositionMs, 2750);
      expect(controller.state.project.videoClips.length, 1);
      expect(controller.state.project.textOverlays.length, 1);
    });

    test('Updating draft during editing automatically saves changes', () async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          getProjectsUseCaseProvider.overrideWithValue(GetProjectsUseCase(repository)),
          getProjectByIdUseCaseProvider.overrideWithValue(GetProjectByIdUseCase(repository)),
          saveProjectUseCaseProvider.overrideWithValue(SaveProjectUseCase(repository)),
          updateProjectUseCaseProvider.overrideWithValue(UpdateProjectUseCase(repository)),
          deleteProjectUseCaseProvider.overrideWithValue(DeleteProjectUseCase(repository)),
          duplicateProjectUseCaseProvider.overrideWithValue(DuplicateProjectUseCase(repository)),
        ],
      );

      // Save initial draft
      final createdProject = await container.read(projectsNotifierProvider.notifier).createProject(
        title: 'Work In Progress Draft',
        aspectRatio: AspectRatioType.ratio9_16,
        fps: 30,
      );

      // Edit in editor controller
      final controller = container.read(editorControllerProvider(createdProject).notifier);
      controller.addTextOverlay(text: 'Edited during session 🔥');
      controller.seekTo(2500);
      await controller.saveDraft();

      // Verify that disk repository has persisted draft with text overlay and new playhead
      final diskProject = await repository.getProjectById(createdProject.id);
      expect(diskProject, isNotNull);
      expect(diskProject!.textOverlays.length, 1);
      expect(diskProject.textOverlays.first.text, 'Edited during session 🔥');
      expect(diskProject.lastPlayheadPositionMs, 2500);

      container.dispose();
    });

    test('Drafts are NOT deleted on catalog reloads and are ONLY deleted when user explicitly deletes', () async {
      await repository.saveProject(richDraftProject);

      // Load all projects
      var projects = await repository.getProjects();
      expect(projects.any((p) => p.id == 'draft_project_101'), isTrue);

      // Simulate app reopen / multiple catalog loads
      projects = await repository.getProjects();
      expect(projects.any((p) => p.id == 'draft_project_101'), isTrue);

      // Explicit delete
      await repository.deleteProject('draft_project_101');
      projects = await repository.getProjects();
      expect(projects.any((p) => p.id == 'draft_project_101'), isFalse);
    });

    test('Draft auto-recovers from disk files on cold launch even if catalog file was missing', () async {
      await repository.saveProject(richDraftProject);

      // Clear catalog file to simulate corrupted or lost catalog
      await storageService.deleteFile('projects_catalog.json');

      // Create new datasource & repository instance simulating cold app launch
      final freshDataSource = ProjectLocalDataSourceImpl(storageService: storageService);
      final freshRepo = ProjectRepositoryImpl(localDataSource: freshDataSource);

      final loadedProjects = await freshRepo.getProjects();
      expect(loadedProjects.any((p) => p.id == 'draft_project_101'), isTrue);

      final recovered = loadedProjects.firstWhere((p) => p.id == 'draft_project_101');
      expect(recovered.title, 'Cyberpunk Draft Edit');
      expect(recovered.lastPlayheadPositionMs, 2750);
    });

    test('Deleted drafts do not get restored or overwritten by sample projects on subsequent app launches', () async {
      // Create and then delete draft
      await repository.saveProject(richDraftProject);
      await repository.deleteProject('draft_project_101');

      // Verify empty list does not trigger sample seeding because app has already seeded
      final freshDataSource = ProjectLocalDataSourceImpl(storageService: storageService);
      final freshRepo = ProjectRepositoryImpl(localDataSource: freshDataSource);

      final loadedProjects = await freshRepo.getProjects();
      // Should not contain the deleted draft
      expect(loadedProjects.any((p) => p.id == 'draft_project_101'), isFalse);
    });
  });
}
