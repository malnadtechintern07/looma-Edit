import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../audio/domain/entities/audio_clip_entity.dart';
import '../../../audio/domain/services/audio_playback_service.dart';
import '../../../filters_effects/domain/entities/effect_clip_entity.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../../filters_effects/domain/entities/video_effect_type.dart';
import '../../../projects/domain/entities/project_entity.dart';
import '../../../projects/domain/entities/aspect_ratio_type.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../text_stickers/domain/entities/overlay_animation_type.dart';
import '../../../text_stickers/domain/entities/sticker_overlay_entity.dart';
import '../../../text_stickers/domain/entities/text_overlay_entity.dart';
import '../../domain/entities/animation_clip_entity.dart';
import '../../domain/entities/keyframe_entity.dart';
import '../../domain/entities/clip_animation_type.dart';
import '../../domain/entities/crop_rect_entity.dart';
import '../../domain/entities/mask_config_entity.dart';
import '../../domain/entities/chroma_key_config_entity.dart';
import '../../domain/entities/speed_curve_type.dart';
import '../../domain/entities/subtitle_entity.dart';
import '../../../audio/domain/services/audio_extraction_service.dart';
import '../../domain/entities/timeline_state.dart';
import '../../domain/entities/transition_type.dart';
import '../../domain/entities/video_clip_entity.dart';
import '../../domain/usecases/editor_usecases.dart';
import '../utils/timeline_layout_helper.dart';

class EditorController extends StateNotifier<TimelineState> {
  final Ref? ref;
  final SplitClipUseCase _splitClipUseCase = SplitClipUseCase();
  final TrimClipUseCase _trimClipUseCase = TrimClipUseCase();
  final UpdateClipSpeedUseCase _updateSpeedUseCase = UpdateClipSpeedUseCase();
  final DeleteClipUseCase _deleteClipUseCase = DeleteClipUseCase();

  Timer? _playbackTimer;
  DateTime? _lastPlaybackTime;
  int _lastAudioSyncMs = 0;

  // Undo / Redo history
  final List<ProjectEntity> _undoStack = [];
  final List<ProjectEntity> _redoStack = [];

  EditorController({
    this.ref,
    required ProjectEntity project,
  }) : super(TimelineState(
          project: project,
          playheadPositionMs: project.lastPlayheadPositionMs,
        ));

  /// Synchronous public getter for the current timeline state
  TimelineState get currentState => state;

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _lastPlaybackTime = DateTime.now();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!state.isPlaying) {
        _stopPlaybackTimer();
        return;
      }
      final now = DateTime.now();
      final elapsedMs = now.difference(_lastPlaybackTime ?? now).inMilliseconds;
      _lastPlaybackTime = now;
      if (elapsedMs > 0) {
        _advancePlayback(elapsedMs);
      }
    });
  }

  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _lastPlaybackTime = null;
  }

  final AudioPlaybackService _audioService = AudioPlaybackService();

  void _recordHistory() {
    _undoStack.add(state.project);
    _redoStack.clear();
    if (_undoStack.length > 30) {
      _undoStack.removeAt(0);
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (!canUndo) return;
    _redoStack.add(state.project);
    final previous = _undoStack.removeLast();
    state = state.copyWith(project: previous);
    _syncAudio();
    _persistChanges();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(state.project);
    final next = _redoStack.removeLast();
    state = state.copyWith(project: next);
    _syncAudio();
    _persistChanges();
  }

  void togglePlayPause() {
    final nextPlaying = !state.isPlaying;
    if (nextPlaying) {
      if (state.playheadPositionMs >= state.project.calculatedDurationMs) {
        state = state.copyWith(playheadPositionMs: 0);
      }
      state = state.copyWith(isPlaying: true);
      _startPlaybackTimer();
    } else {
      _stopPlaybackTimer();
      state = state.copyWith(isPlaying: false);
    }
    _syncAudio();
  }

  void play() {
    if (!state.isPlaying) togglePlayPause();
  }

  void pause() {
    if (state.isPlaying) togglePlayPause();
  }

  void toggleSnapping() {
    state = state.copyWith(isSnappingEnabled: !state.isSnappingEnabled);
  }

  void seekTo(int positionMs) {
    final clamped = positionMs.clamp(0, state.project.calculatedDurationMs);
    state = state.copyWith(playheadPositionMs: clamped);
    _syncAudio();
  }

  void _syncAudio() {
    _audioService.syncAudioPlayback(
      audioClips: state.project.audioClips,
      currentPlayheadMs: state.playheadPositionMs,
      isPlaying: state.isPlaying,
    );
  }

  void setTimelineZoom(double pixelsPerSec) {
    // Dynamic timeline zoom range:
    // 8.0 px/s: fully zoomed out, all clips visible in a small space
    // 200.0 px/s: frame-accurate zoomed in for precise trimming and splits
    final clamped = pixelsPerSec.clamp(
      AppConstants.minTimelinePixelsPerSecond,
      AppConstants.maxTimelinePixelsPerSecond,
    );
    state = state.copyWith(pixelsPerSecond: clamped);
  }

  void setPixelsPerSecond(double pixelsPerSec) => setTimelineZoom(pixelsPerSec);

  void fitTimelineToScreen(double viewportWidth) {
    final totalDurationMs = state.project.calculatedDurationMs;
    if (totalDurationMs <= 0 || viewportWidth <= 0) {
      setTimelineZoom(AppConstants.defaultPixelsPerSecond);
      return;
    }
    // Fit the entire project within the visible viewport with comfortable margins
    final totalSeconds = totalDurationMs / 1000.0;
    final fittedPps = (viewportWidth * 0.85) / totalSeconds;
    setTimelineZoom(fittedPps);
  }

  void setSelection(SelectionType type, String? id) {
    state = state.copyWith(selectionType: type, selectedItemId: id);
  }

  void clearSelection() {
    state = state.copyWith(selectionType: SelectionType.none, selectedItemId: null);
  }

  void _advancePlayback(int deltaMs) {
    final newPos = state.playheadPositionMs + deltaMs;
    final totalDuration = state.project.calculatedDurationMs;

    if (newPos >= totalDuration) {
      if (state.isLooping) {
        state = state.copyWith(playheadPositionMs: 0);
      } else {
        _stopPlaybackTimer();
        state = state.copyWith(playheadPositionMs: totalDuration, isPlaying: false);
      }
    } else {
      state = state.copyWith(playheadPositionMs: newPos);
    }
    if ((newPos - _lastAudioSyncMs).abs() > 400) {
      _lastAudioSyncMs = newPos;
      _syncAudio();
    }
  }

  // --- Project Metadata Changes ---
  void updateAspectRatio(AspectRatioType ratio) {
    _recordHistory();
    final updated = state.project.copyWith(aspectRatio: ratio);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void updateProjectTitle(String title) {
    _recordHistory();
    final updated = state.project.copyWith(title: title);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  // --- Video Clip Actions ---
  void splitActiveClip() {
    String? targetId;
    if (state.selectionType == SelectionType.videoClip || state.selectionType == SelectionType.overlayClip) {
      targetId = state.selectedItemId;
    } else {
      targetId = state.activeVideoClip?.id;
    }
    if (targetId == null) return;
    _recordHistory();

    final updatedProject = _splitClipUseCase(
      project: state.project,
      clipId: targetId,
      splitPositionMs: state.playheadPositionMs,
    );

    state = state.copyWith(project: updatedProject);
    _persistChanges();
  }

  void trimClip(String clipId, int trimStartMs, int trimEndMs) {
    _recordHistory();
    final updatedProject = _trimClipUseCase(
      project: state.project,
      clipId: clipId,
      newTrimStartMs: trimStartMs,
      newTrimEndMs: trimEndMs,
    );
    state = state.copyWith(project: updatedProject);
    _persistChanges();
  }

  void setClipSpeed(String clipId, double speed) {
    _recordHistory();
    final updatedProject = _updateSpeedUseCase(
      project: state.project,
      clipId: clipId,
      newSpeed: speed,
    );
    state = state.copyWith(project: updatedProject);
    _persistChanges();
  }

  void setClipFilter(String clipId, FilterType filter, {double? intensity}) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(
          filterType: filter,
          filterIntensity: intensity ?? (filter == FilterType.none ? 1.0 : c.filterIntensity),
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipFilterIntensity(String clipId, double intensity) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(
          filterIntensity: intensity.clamp(0.0, 1.0),
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void removeClipFilter(String clipId) {
    setClipFilter(clipId, FilterType.none, intensity: 1.0);
  }

  void setClipEffect(String clipId, VideoEffectType effect, {double intensity = 1.0}) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(
          effectType: effect,
          effectIntensity: intensity.clamp(0.0, 1.0),
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipColorAdjustments({
    required String clipId,
    required double brightness,
    required double contrast,
    required double saturation,
  }) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(
          brightness: brightness,
          contrast: contrast,
          saturation: saturation,
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipTransition(String clipId, TransitionType transition, {int durationMs = 500}) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(
          transitionIn: transition,
          transitionDurationMs: durationMs,
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipBlur(String clipId, double blurSigma) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(blurSigma: blurSigma);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipZoom(String clipId, double zoomScale) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(zoomScale: zoomScale);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void updateClipTransform({
    required String clipId,
    double? zoomScale,
    double? positionX,
    double? positionY,
    double? rotationDegrees,
    bool persist = true,
  }) {
    final list = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        final newZoom = zoomScale?.clamp(0.1, 5.0) ?? c.zoomScale;
        final newPosX = positionX ?? c.positionX;
        final newPosY = positionY ?? c.positionY;
        final newRot = rotationDegrees ?? c.rotationDegrees;

        if (c.keyframes.isNotEmpty) {
          // CapCut Auto-Keyframing:
          // If the clip has keyframes, updating transform at playhead updates/creates a keyframe!
          final offsetInClip = (state.playheadPositionMs - c.timelineStartMs).clamp(0, c.effectiveDurationMs);
          final baseValues = KeyframeValues(
            posX: c.positionX,
            posY: c.positionY,
            scale: c.zoomScale,
            rotation: c.rotationDegrees,
            opacity: c.opacity,
          );
          final currentInterpolated = KeyframeInterpolator.interpolate(
            keyframes: c.keyframes,
            currentOffsetMs: offsetInClip,
            baseValues: baseValues,
          );

          final existingKf = c.keyframes.where((k) => (k.timestampMs - offsetInClip).abs() <= 50).firstOrNull;

          final updatedKf = KeyframeEntity(
            id: existingKf?.id ?? IdGenerator.generate(),
            timestampMs: existingKf?.timestampMs ?? offsetInClip,
            posX: positionX ?? existingKf?.posX ?? currentInterpolated.posX,
            posY: positionY ?? existingKf?.posY ?? currentInterpolated.posY,
            scale: (zoomScale ?? existingKf?.scale ?? currentInterpolated.scale).clamp(0.1, 5.0),
            rotation: rotationDegrees ?? existingKf?.rotation ?? currentInterpolated.rotation,
            opacity: existingKf?.opacity ?? currentInterpolated.opacity,
          );

          final filtered = c.keyframes.where((k) => (k.timestampMs - offsetInClip).abs() > 50).toList();
          filtered.add(updatedKf);
          filtered.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

          return c.copyWith(
            zoomScale: newZoom,
            positionX: newPosX,
            positionY: newPosY,
            rotationDegrees: newRot,
            keyframes: filtered,
          );
        }

        return c.copyWith(
          zoomScale: newZoom,
          positionX: newPosX,
          positionY: newPosY,
          rotationDegrees: newRot,
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: list);
    state = state.copyWith(project: updated);
    if (persist) {
      _persistChanges();
    }
  }

  void rotateClip90(String clipId) {
    final clip = state.project.videoClips.firstWhere((c) => c.id == clipId, orElse: () => state.project.videoClips.first);
    final newRot = (clip.rotationDegrees + 90.0) % 360.0;
    updateClipTransform(clipId: clip.id, rotationDegrees: newRot);
  }

  void zoomClipIn(String clipId) {
    final clip = state.project.videoClips.firstWhere((c) => c.id == clipId, orElse: () => state.project.videoClips.first);
    final newZoom = (clip.zoomScale + 0.25).clamp(0.1, 5.0);
    updateClipTransform(clipId: clip.id, zoomScale: newZoom);
  }

  void zoomClipOut(String clipId) {
    final clip = state.project.videoClips.firstWhere((c) => c.id == clipId, orElse: () => state.project.videoClips.first);
    final newZoom = (clip.zoomScale - 0.25).clamp(0.1, 5.0);
    updateClipTransform(clipId: clip.id, zoomScale: newZoom);
  }

  void resetClipTransform(String clipId) {
    updateClipTransform(
      clipId: clipId,
      zoomScale: 1.0,
      positionX: 0.0,
      positionY: 0.0,
      rotationDegrees: 0.0,
    );
  }

  void flipClipHorizontal(String clipId) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(isFlippedHorizontally: !c.isFlippedHorizontally);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void flipClipVertical(String clipId) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(isFlippedVertically: !c.isFlippedVertically);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipOpacity(String clipId, double opacity) {
    _recordHistory();
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        if (c.keyframes.isNotEmpty) {
          final offsetInClip = (state.playheadPositionMs - c.timelineStartMs).clamp(0, c.effectiveDurationMs);
          final baseValues = KeyframeValues(
            posX: c.positionX,
            posY: c.positionY,
            scale: c.zoomScale,
            rotation: c.rotationDegrees,
            opacity: c.opacity,
          );
          final currentInterpolated = KeyframeInterpolator.interpolate(
            keyframes: c.keyframes,
            currentOffsetMs: offsetInClip,
            baseValues: baseValues,
          );
          final existingKf = c.keyframes.where((k) => (k.timestampMs - offsetInClip).abs() <= 50).firstOrNull;
          final updatedKf = KeyframeEntity(
            id: existingKf?.id ?? IdGenerator.generate(),
            timestampMs: existingKf?.timestampMs ?? offsetInClip,
            posX: existingKf?.posX ?? currentInterpolated.posX,
            posY: existingKf?.posY ?? currentInterpolated.posY,
            scale: existingKf?.scale ?? currentInterpolated.scale,
            rotation: existingKf?.rotation ?? currentInterpolated.rotation,
            opacity: clampedOpacity,
          );
          final filtered = c.keyframes.where((k) => (k.timestampMs - offsetInClip).abs() > 50).toList();
          filtered.add(updatedKf);
          filtered.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
          return c.copyWith(opacity: clampedOpacity, keyframes: filtered);
        }
        return c.copyWith(opacity: clampedOpacity);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipCrop(String clipId, CropRectEntity? crop) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(crop: crop);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipMask(String clipId, MaskConfigEntity? mask) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(mask: mask);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipChromaKey(String clipId, ChromaKeyConfigEntity? chromaKey) {
    if (!mounted) return;
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(
          chromaKey: chromaKey,
          clearChromaKey: chromaKey == null,
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  /// Activates interactive Chroma Key picking mode on the preview for [clipId]
  void openChromaKeyMode(String clipId) {
    final clip = state.project.videoClips.where((c) => c.id == clipId).firstOrNull;
    if (clip == null) return;

    // If clip doesn't have chroma key or it's disabled, initialize it with enabled = true
    if (clip.chromaKey == null || !clip.chromaKey!.isEnabled) {
      final initialConfig = (clip.chromaKey ?? const ChromaKeyConfigEntity()).copyWith(
        isEnabled: true,
        keyColorHex: clip.chromaKey?.keyColorHex ?? 0xFF00FF00,
      );
      setClipChromaKey(clipId, initialConfig);
    }

    state = state.copyWith(
      isChromaKeyPickingMode: true,
      chromaKeyTargetClipId: clipId,
      chromaKeyCrosshairX: 0.5,
      chromaKeyCrosshairY: 0.5,
    );
  }

  /// Deactivates Chroma Key picking mode
  void closeChromaKeyMode() {
    state = state.copyWith(
      isChromaKeyPickingMode: false,
      clearChromaKeyTarget: true,
    );
  }

  /// Toggles Chroma Key interactive color picking mode on/off
  void toggleChromaKeyPickingMode() {
    state = state.copyWith(
      isChromaKeyPickingMode: !state.isChromaKeyPickingMode,
    );
  }

  /// Updates crosshair coordinates on the preview (normalized 0..1)
  void setChromaKeyCrosshair(double x, double y) {
    state = state.copyWith(
      chromaKeyCrosshairX: x.clamp(0.0, 1.0),
      chromaKeyCrosshairY: y.clamp(0.0, 1.0),
    );
  }

  /// Samples color under crosshair and updates chroma key config
  void sampleChromaKeyColor(String clipId, int colorHex) {
    if (!mounted) return;
    final clip = state.project.videoClips.where((c) => c.id == clipId).firstOrNull;
    final current = clip?.chromaKey ?? const ChromaKeyConfigEntity();
    final updated = current.copyWith(
      isEnabled: true,
      keyColorHex: colorHex,
    );
    setClipChromaKey(clipId, updated);
  }

  /// Resets or removes chroma key for the given clip
  void resetChromaKey(String clipId) {
    setClipChromaKey(clipId, null);
  }

  void setClipSpeedCurve(String clipId, SpeedCurveType curve) {
    _recordHistory();
    final updatedProject = _updateSpeedUseCase(
      project: state.project,
      clipId: clipId,
      newSpeedCurve: curve,
    );
    state = state.copyWith(project: updatedProject);
    _persistChanges();
  }

  void toggleClipReverse(String clipId) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(isReversed: !c.isReversed);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void freezeFrameAtPlayhead(String clipId, {int durationMs = 3000}) {
    final clip = state.project.videoClips.firstWhere((c) => c.id == clipId, orElse: () => state.project.videoClips.first);
    final offsetInClip = state.playheadPositionMs - clip.timelineStartMs;
    if (offsetInClip <= 0 || offsetInClip >= clip.effectiveDurationMs) return;

    _recordHistory();
    // Split clip and insert a freeze still clip at playhead
    final firstPart = clip.copyWith(
      id: IdGenerator.generate(),
      timelineEndMs: state.playheadPositionMs,
      trimEndMs: clip.trimStartMs + (offsetInClip * clip.speed).round(),
    );

    final freezeStill = clip.copyWith(
      id: IdGenerator.generate(),
      name: '${clip.name} (Freeze)',
      timelineStartMs: state.playheadPositionMs,
      timelineEndMs: state.playheadPositionMs + durationMs,
      trimStartMs: firstPart.trimEndMs,
      trimEndMs: firstPart.trimEndMs + 100, // 1 frame still
      speed: 0.05,
    );

    final secondPart = clip.copyWith(
      id: IdGenerator.generate(),
      timelineStartMs: state.playheadPositionMs + durationMs,
      timelineEndMs: clip.timelineEndMs + durationMs,
      trimStartMs: firstPart.trimEndMs,
    );

    final index = state.project.videoClips.indexWhere((c) => c.id == clipId);
    final clips = List<VideoClipEntity>.from(state.project.videoClips);
    clips.removeAt(index);
    clips.insert(index, firstPart);
    clips.insert(index + 1, freezeStill);
    clips.insert(index + 2, secondPart);

    // Re-align subsequent clips
    int currentOffset = 0;
    final aligned = <VideoClipEntity>[];
    for (final c in clips) {
      final dur = c.effectiveDurationMs;
      aligned.add(c.copyWith(
        timelineStartMs: currentOffset,
        timelineEndMs: currentOffset + dur,
      ));
      currentOffset += dur;
    }

    final updated = state.project.copyWith(videoClips: aligned, durationMs: currentOffset);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  // --- Keyframes Actions ---
  bool isAtKeyframe(String clipId, {int toleranceMs = 50}) {
    final clip = state.project.videoClips.where((c) => c.id == clipId).firstOrNull;
    if (clip == null || clip.keyframes.isEmpty) return false;
    final offsetInClip = state.playheadPositionMs - clip.timelineStartMs;
    return clip.keyframes.any((k) => (k.timestampMs - offsetInClip).abs() <= toleranceMs);
  }

  KeyframeEntity? getKeyframeAtPlayhead(String clipId, {int toleranceMs = 50}) {
    final clip = state.project.videoClips.where((c) => c.id == clipId).firstOrNull;
    if (clip == null || clip.keyframes.isEmpty) return null;
    final offsetInClip = state.playheadPositionMs - clip.timelineStartMs;
    final matches = clip.keyframes.where((k) => (k.timestampMs - offsetInClip).abs() <= toleranceMs).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => (a.timestampMs - offsetInClip).abs().compareTo((b.timestampMs - offsetInClip).abs()));
    return matches.first;
  }

  bool hasPrevKeyframe(String clipId) {
    final clip = state.project.videoClips.where((c) => c.id == clipId).firstOrNull;
    if (clip == null || clip.keyframes.isEmpty) return false;
    final offsetInClip = state.playheadPositionMs - clip.timelineStartMs;
    return clip.keyframes.any((k) => k.timestampMs < offsetInClip - 30);
  }

  bool hasNextKeyframe(String clipId) {
    final clip = state.project.videoClips.where((c) => c.id == clipId).firstOrNull;
    if (clip == null || clip.keyframes.isEmpty) return false;
    final offsetInClip = state.playheadPositionMs - clip.timelineStartMs;
    return clip.keyframes.any((k) => k.timestampMs > offsetInClip + 30);
  }

  void toggleKeyframeAtPlayhead(String clipId) {
    if (isAtKeyframe(clipId)) {
      removeKeyframeAtPlayhead(clipId);
    } else {
      addKeyframeAtPlayhead(clipId);
    }
  }

  void addKeyframeAtPlayhead(String clipId, {KeyframeValues? customValues}) {
    final clip = state.project.videoClips.where((c) => c.id == clipId).firstOrNull;
    if (clip == null) return;
    final offsetInClip = (state.playheadPositionMs - clip.timelineStartMs).clamp(0, clip.effectiveDurationMs);

    _recordHistory();

    final KeyframeValues values;
    if (customValues != null) {
      values = customValues;
    } else {
      final base = KeyframeValues(
        posX: clip.positionX,
        posY: clip.positionY,
        scale: clip.zoomScale,
        rotation: clip.rotationDegrees,
        opacity: clip.opacity,
      );
      values = KeyframeInterpolator.interpolate(
        keyframes: clip.keyframes,
        currentOffsetMs: offsetInClip,
        baseValues: base,
      );
    }

    final newKeyframe = KeyframeEntity(
      id: IdGenerator.generate(),
      timestampMs: offsetInClip,
      posX: values.posX,
      posY: values.posY,
      scale: values.scale,
      rotation: values.rotation,
      opacity: values.opacity,
    );

    // Replace if keyframe already exists within 50ms, else insert
    final filtered = clip.keyframes.where((k) => (k.timestampMs - offsetInClip).abs() > 50).toList();
    filtered.add(newKeyframe);
    filtered.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(keyframes: filtered);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void removeKeyframeAtPlayhead(String clipId, {int toleranceMs = 50}) {
    final existing = getKeyframeAtPlayhead(clipId, toleranceMs: toleranceMs);
    if (existing != null) {
      removeKeyframe(clipId, existing.id);
    }
  }

  void removeKeyframe(String clipId, String keyframeId) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        final filtered = c.keyframes.where((k) => k.id != keyframeId).toList();
        return c.copyWith(keyframes: filtered);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void jumpToNextKeyframe(String clipId) {
    final clip = state.project.videoClips.where((c) => c.id == clipId).firstOrNull;
    if (clip == null || clip.keyframes.isEmpty) return;
    final currentOffset = state.playheadPositionMs - clip.timelineStartMs;
    final sorted = List<KeyframeEntity>.from(clip.keyframes)
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    final next = sorted.where((k) => k.timestampMs > currentOffset + 30).firstOrNull;
    if (next != null) {
      seekTo(clip.timelineStartMs + next.timestampMs);
    }
  }

  void jumpToPrevKeyframe(String clipId) {
    final clip = state.project.videoClips.where((c) => c.id == clipId).firstOrNull;
    if (clip == null || clip.keyframes.isEmpty) return;
    final currentOffset = state.playheadPositionMs - clip.timelineStartMs;
    final sorted = List<KeyframeEntity>.from(clip.keyframes)
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    final prev = sorted.reversed.where((k) => k.timestampMs < currentOffset - 30).firstOrNull;
    if (prev != null) {
      seekTo(clip.timelineStartMs + prev.timestampMs);
    }
  }

  // --- Animation Actions ---
  void setClipAnimationIn(String clipId, ClipAnimationIn anim, {int durationMs = 500}) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(animationIn: anim, animationInDurationMs: durationMs);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipAnimationOut(String clipId, ClipAnimationOut anim, {int durationMs = 500}) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(animationOut: anim, animationOutDurationMs: durationMs);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipAnimationCombo(String clipId, ClipAnimationCombo anim) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(animationCombo: anim);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipAnimationInDuration(String clipId, int durationMs) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(animationInDurationMs: durationMs);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipAnimationOutDuration(String clipId, int durationMs) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(animationOutDurationMs: durationMs);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  /// Computes the earliest start time >= [preferredStartMs] such that a clip of [durationMs]
  /// does NOT overlap with any of the intervals in [existingIntervals].
  int findNonOverlappingStartMs({
    required int preferredStartMs,
    required int durationMs,
    required List<({int startMs, int endMs})> existingIntervals,
  }) {
    if (existingIntervals.isEmpty) {
      return max(0, preferredStartMs);
    }

    final sorted = existingIntervals
        .where((interval) => interval.endMs > interval.startMs)
        .toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    int candidate = max(0, preferredStartMs);
    bool hasCollision = true;

    while (hasCollision) {
      hasCollision = false;
      final candidateEnd = candidate + durationMs;

      for (final interval in sorted) {
        // Two ranges [A, B) and [X, Y) overlap if max(A, X) < min(B, Y)
        if (max(candidate, interval.startMs) < min(candidateEnd, interval.endMs)) {
          // Collision detected: advance candidate past the colliding interval
          candidate = interval.endMs;
          hasCollision = true;
          break;
        }
      }
    }

    return candidate;
  }

  // --- Duplicate Video Clip ---
  void duplicateVideoClip(String clipId) {
    final clip = state.project.videoClips.firstWhere((c) => c.id == clipId, orElse: () => state.project.videoClips.first);
    _recordHistory();

    if (clip.isOverlay) {
      final dur = clip.effectiveDurationMs;
      final startMs = clip.timelineStartMs;

      final duplicated = clip.copyWith(
        id: IdGenerator.generate(),
        name: '${clip.name} (Copy)',
        timelineStartMs: startMs,
        timelineEndMs: startMs + dur,
        positionX: clip.positionX + 20.0,
        positionY: clip.positionY + 20.0,
      );

      final updated = state.project.copyWith(
        videoClips: [...state.project.videoClips, duplicated],
        durationMs: max(state.project.durationMs, startMs + dur),
      );
      state = state.copyWith(
        project: updated,
        selectionType: SelectionType.overlayClip,
        selectedItemId: duplicated.id,
        playheadPositionMs: startMs,
      );
      _persistChanges();
      return;
    }

    final duplicated = clip.copyWith(
      id: IdGenerator.generate(),
      name: '${clip.name} (Copy)',
      timelineStartMs: clip.timelineEndMs,
      timelineEndMs: clip.timelineEndMs + clip.effectiveDurationMs,
    );

    final updatedClips = List<VideoClipEntity>.from(state.project.videoClips);
    final insertIndex = state.project.videoClips.indexOf(clip) + 1;
    updatedClips.insert(insertIndex, duplicated);

    // Ripple subsequent main clips
    int offset = duplicated.timelineEndMs;
    for (int i = insertIndex + 1; i < updatedClips.length; i++) {
      if (!updatedClips[i].isOverlay) {
        final d = updatedClips[i].effectiveDurationMs;
        updatedClips[i] = updatedClips[i].copyWith(
          timelineStartMs: offset,
          timelineEndMs: offset + d,
        );
        offset += d;
      }
    }

    final updated = state.project.copyWith(videoClips: updatedClips, durationMs: max(state.project.durationMs, offset));
    state = state.copyWith(project: updated, selectionType: SelectionType.videoClip, selectedItemId: duplicated.id);
    _persistChanges();
  }

  // --- Overlay / PIP Track Actions ---
  void addOverlayClip({
    required String name,
    required String mediaPath,
    int durationMs = 4000,
  }) {
    _recordHistory();
    final effectiveDuration = durationMs > 0 ? durationMs : 4000;
    final startMs = state.playheadPositionMs;
    final activeOverlaysCount = state.activeOverlayClips.length;

    final overlayClip = VideoClipEntity(
      id: IdGenerator.generate(),
      mediaPath: mediaPath,
      name: name,
      sourceDurationMs: effectiveDuration,
      timelineStartMs: startMs,
      timelineEndMs: startMs + effectiveDuration,
      trimStartMs: 0,
      trimEndMs: effectiveDuration,
      zoomScale: 0.6, // Smaller PIP default scale
      isOverlay: true,
      positionX: activeOverlaysCount > 0 ? (activeOverlaysCount * 25.0) : 0.0,
      positionY: activeOverlaysCount > 0 ? (activeOverlaysCount * 25.0) : 0.0,
    );

    final updated = state.project.copyWith(
      videoClips: [...state.project.videoClips, overlayClip],
      durationMs: max(state.project.durationMs, startMs + effectiveDuration),
    );

    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.overlayClip,
      selectedItemId: overlayClip.id,
      playheadPositionMs: startMs,
    );
    _persistChanges();
  }

  // --- Video Clip Audio & Volume Controls ---
  void setClipVolume(String clipId, double volume) {
    _recordHistory();
    final clamped = volume.clamp(0.0, 2.0);
    final list = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(
          volume: clamped,
          isMuted: clamped == 0.0 ? true : (c.isMuted ? false : c.isMuted),
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void setClipMute(String clipId, bool isMuted) {
    _recordHistory();
    final list = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(isMuted: isMuted);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void toggleClipMute(String clipId) {
    _recordHistory();
    final list = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(isMuted: !c.isMuted);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void resetClipVolume(String clipId) {
    _recordHistory();
    final list = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(volume: 1.0, isMuted: false);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  // --- Real Audio Extraction from Video (Preserves Original Audio) ---
  Future<void> extractAudioFromClip(String clipId) async {
    final clip = state.project.videoClips.firstWhere(
      (c) => c.id == clipId,
      orElse: () => state.activeVideoClip ?? state.project.videoClips.first,
    );

    final extractedAudio = await AudioExtractionService.extractAudioFromVideo(
      videoPath: clip.mediaPath,
      videoTitle: '${clip.name} (Extracted Audio)',
      timelineStartMs: clip.timelineStartMs,
      durationMs: clip.effectiveDurationMs,
    );

    // Add extracted audio as separate audio clip track WITHOUT modifying original clip's audio
    addAudioClip(extractedAudio);
  }

  Future<void> extractAudioFromVideo(String videoPath, {String title = 'Video Audio'}) async {
    _recordHistory();
    final active = state.activeVideoClip;
    final duration = active != null ? active.effectiveDurationMs : 10000;

    final extractedAudio = await AudioExtractionService.extractAudioFromVideo(
      videoPath: videoPath,
      videoTitle: title,
      timelineStartMs: active?.timelineStartMs ?? state.playheadPositionMs,
      durationMs: duration,
    );

    addAudioClip(extractedAudio);
  }

  // --- Subtitle / Caption Actions ---
  void addSubtitle({
    required String text,
    int durationMs = 3000,
    String fontFamily = 'Inter',
    double fontSize = 20.0,
    int colorHex = 0xFFFFFFFF,
    int? backgroundColorHex = 0x99000000,
  }) {
    _recordHistory();
    final dur = durationMs > 0 ? durationMs : 3000;
    final startMs = state.playheadPositionMs;
    final endMs = startMs + dur;

    final sub = SubtitleEntity(
      id: IdGenerator.generate(),
      text: text,
      timelineStartMs: startMs,
      timelineEndMs: endMs,
      fontFamily: fontFamily,
      fontSize: fontSize,
      colorHex: colorHex,
      backgroundColorHex: backgroundColorHex,
    );

    final updated = state.project.copyWith(
      subtitles: [...state.project.subtitles, sub],
      durationMs: max(state.project.durationMs, endMs),
    );

    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.subtitle,
      selectedItemId: sub.id,
      playheadPositionMs: startMs,
    );
    _persistChanges();
  }

  void updateSubtitle(SubtitleEntity subtitle) {
    _recordHistory();
    final list = state.project.subtitles.map((s) {
      if (s.id == subtitle.id) return subtitle;
      return s;
    }).toList();

    final updated = state.project.copyWith(subtitles: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void deleteSubtitle(String subtitleId) {
    _recordHistory();
    final list = state.project.subtitles.where((s) => s.id != subtitleId).toList();
    final updated = state.project.copyWith(subtitles: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void duplicateSubtitle(String subtitleId) {
    _recordHistory();
    final sub = state.project.subtitles.firstWhere((s) => s.id == subtitleId, orElse: () => state.project.subtitles.first);
    final newId = IdGenerator.generate();
    final dur = sub.durationMs;
    final cleanStart = _findNextEmptySlot(
      currentStart: sub.timelineStartMs,
      currentEnd: sub.timelineEndMs,
      duration: dur,
      others: state.project.subtitles.map((s) => (start: s.timelineStartMs, end: s.timelineEndMs)).toList(),
    );
    final cloned = sub.copyWith(
      id: newId,
      timelineStartMs: cleanStart,
      timelineEndMs: cleanStart + dur,
    );
    final updated = state.project.copyWith(
      subtitles: [...state.project.subtitles, cloned],
      durationMs: max(state.project.durationMs, cleanStart + dur),
    );
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.subtitle,
      selectedItemId: newId,
    );
    _persistChanges();
  }

  void setClipFade(String clipId, int fadeInMs, int fadeOutMs) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(
          fadeInDurationMs: fadeInMs,
          fadeOutDurationMs: fadeOutMs,
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void reorderVideoClips(int oldIndex, int newIndex) {
    final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
    final overlayClips = state.project.videoClips.where((c) => c.isOverlay).toList();

    if (oldIndex < 0 || oldIndex >= mainClips.length) return;
    if (newIndex < 0 || newIndex >= mainClips.length) return;
    if (oldIndex == newIndex) return;

    _recordHistory();
    final movedClip = mainClips.removeAt(oldIndex);
    mainClips.insert(newIndex, movedClip);

    // Recalculate timelineStartMs and timelineEndMs sequentially for all main clips while retaining all properties
    int currentOffset = 0;
    final updatedMainClips = <VideoClipEntity>[];
    for (final clip in mainClips) {
      final dur = clip.effectiveDurationMs;
      updatedMainClips.add(
        clip.copyWith(
          timelineStartMs: currentOffset,
          timelineEndMs: currentOffset + dur,
        ),
      );
      currentOffset += dur;
    }

    final allClips = [...updatedMainClips, ...overlayClips];
    final updatedProject = state.project.copyWith(
      videoClips: allClips,
      durationMs: currentOffset,
    );

    state = state.copyWith(
      project: updatedProject,
      selectedItemId: movedClip.id,
      selectionType: SelectionType.videoClip,
    );
    _persistChanges();
  }

  void moveClipLeft(String clipId) {
    final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
    final index = mainClips.indexWhere((c) => c.id == clipId);
    if (index > 0) {
      reorderVideoClips(index, index - 1);
    }
  }

  void moveClipRight(String clipId) {
    final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
    final index = mainClips.indexWhere((c) => c.id == clipId);
    if (index >= 0 && index < mainClips.length - 1) {
      reorderVideoClips(index, index + 1);
    }
  }

  void moveClipToStart(String clipId) {
    final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
    final index = mainClips.indexWhere((c) => c.id == clipId);
    if (index > 0) {
      reorderVideoClips(index, 0);
    }
  }

  void moveClipToEnd(String clipId) {
    final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
    final index = mainClips.indexWhere((c) => c.id == clipId);
    if (index >= 0 && index < mainClips.length - 1) {
      reorderVideoClips(index, mainClips.length - 1);
    }
  }

  double _dragAccumulatorPixels = 0.0;

  void updateClipDurationByDrag({
    required String clipId,
    required double deltaPixels,
    required double pixelsPerSecond,
    required bool isLeftHandle,
  }) {
    final clipIndex = state.project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return;

    final clip = state.project.videoClips[clipIndex];
    _dragAccumulatorPixels += deltaPixels;
    final deltaMs = ((_dragAccumulatorPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;
    _dragAccumulatorPixels -= (deltaMs / 1000.0) * pixelsPerSecond;

    final List<VideoClipEntity> updatedClips = List.from(state.project.videoClips);
    const int minDurationMs = 100; // Micro-fine trimming down to 100ms (0.1s)

    if (clip.isPhoto) {
      // --- Photo / Still Image: Extend or reduce display duration dynamically ---
      if (isLeftHandle) {
        final currentDur = clip.effectiveDurationMs;
        final newDur = (currentDur - deltaMs).clamp(minDurationMs, 3600000);
        final actualTimelineShiftMs = currentDur - newDur;

        // Left edge moves with user's finger, right edge stays anchored in place
        final newTimelineStart = clip.timelineStartMs + actualTimelineShiftMs;
        final newTimelineEnd = clip.timelineEndMs;

        updatedClips[clipIndex] = clip.copyWith(
          timelineStartMs: newTimelineStart,
          timelineEndMs: newTimelineEnd,
          trimStartMs: 0,
          trimEndMs: newDur,
          sourceDurationMs: max(clip.sourceDurationMs, newDur),
        );
      } else {
        final currentDur = clip.effectiveDurationMs;
        final newDur = (currentDur + deltaMs).clamp(minDurationMs, 3600000);

        // Left edge stays anchored, right edge moves with user's finger
        final newTimelineStart = clip.timelineStartMs;
        final newTimelineEnd = clip.timelineStartMs + newDur;

        updatedClips[clipIndex] = clip.copyWith(
          timelineStartMs: newTimelineStart,
          timelineEndMs: newTimelineEnd,
          trimStartMs: 0,
          trimEndMs: newDur,
          sourceDurationMs: max(clip.sourceDurationMs, newDur),
        );
      }
    } else {
      // --- Video: Real-time expansion & cropping for video clips ---
      final sourceDeltaMs = (deltaMs * clip.speed).round();
      if (isLeftHandle) {
        final newTrimStart = (clip.trimStartMs + sourceDeltaMs).clamp(0, clip.trimEndMs - minDurationMs);
        final actualSourceShiftMs = newTrimStart - clip.trimStartMs;
        final actualTimelineShiftMs = (actualSourceShiftMs / clip.speed).round();

        // Left edge moves with user's finger, right edge stays anchored in place
        final newTimelineStart = clip.timelineStartMs + actualTimelineShiftMs;
        final newTimelineEnd = clip.timelineEndMs;

        updatedClips[clipIndex] = clip.copyWith(
          trimStartMs: newTrimStart,
          timelineStartMs: newTimelineStart,
          timelineEndMs: newTimelineEnd,
        );
      } else {
        // Trimming inward crops down to minDurationMs; dragging outward expands duration up to sourceDurationMs
        final maxDur = max(clip.sourceDurationMs, clip.trimEndMs);
        final newTrimEnd = (clip.trimEndMs + sourceDeltaMs).clamp(clip.trimStartMs + minDurationMs, maxDur);
        final newTrimmedSource = newTrimEnd - clip.trimStartMs;
        final newEffectiveDur = (newTrimmedSource / clip.speed).round();

        // Left edge stays anchored, right edge moves with user's finger
        final newTimelineStart = clip.timelineStartMs;
        final newTimelineEnd = clip.timelineStartMs + newEffectiveDur;

        updatedClips[clipIndex] = clip.copyWith(
          trimEndMs: newTrimEnd,
          sourceDurationMs: clip.sourceDurationMs,
          timelineStartMs: newTimelineStart,
          timelineEndMs: newTimelineEnd,
        );
      }
    }

    final targetClip = updatedClips[clipIndex];
    final activeTrimPosMs = isLeftHandle ? targetClip.timelineStartMs : targetClip.timelineEndMs;

    if (clip.isOverlay) {
      // Overlay clips collision check: prevent extending over adjacent overlay clips
      final otherOverlays = state.project.videoClips.where((c) => c.isOverlay && c.id != clipId).toList();
      VideoClipEntity? closestPrev;
      VideoClipEntity? closestNext;
      for (final other in otherOverlays) {
        if (other.timelineEndMs <= clip.timelineStartMs) {
          if (closestPrev == null || other.timelineEndMs > closestPrev.timelineEndMs) {
            closestPrev = other;
          }
        }
        if (other.timelineStartMs >= clip.timelineEndMs) {
          if (closestNext == null || other.timelineStartMs < closestNext.timelineStartMs) {
            closestNext = other;
          }
        }
      }

      var candidateClip = updatedClips[clipIndex];
      if (isLeftHandle && closestPrev != null && candidateClip.timelineStartMs < closestPrev.timelineEndMs) {
        final clampedStart = closestPrev.timelineEndMs;
        final durDiff = clampedStart - candidateClip.timelineStartMs;
        if (candidateClip.isPhoto) {
          final newDur = max(minDurationMs, candidateClip.effectiveDurationMs - durDiff);
          candidateClip = candidateClip.copyWith(
            timelineStartMs: clampedStart,
            trimEndMs: newDur,
          );
        } else {
          final sourceShift = (durDiff * candidateClip.speed).round();
          final newTrimStart = (candidateClip.trimStartMs + sourceShift).clamp(0, candidateClip.trimEndMs - minDurationMs);
          candidateClip = candidateClip.copyWith(
            timelineStartMs: clampedStart,
            trimStartMs: newTrimStart,
          );
        }
      } else if (!isLeftHandle && closestNext != null && candidateClip.timelineEndMs > closestNext.timelineStartMs) {
        final clampedEnd = closestNext.timelineStartMs;
        final maxAllowedDur = max(minDurationMs, clampedEnd - candidateClip.timelineStartMs);
        if (candidateClip.isPhoto) {
          candidateClip = candidateClip.copyWith(
            timelineEndMs: clampedEnd,
            trimEndMs: maxAllowedDur,
          );
        } else {
          final maxAllowedSourceDur = (maxAllowedDur * candidateClip.speed).round();
          final newTrimEnd = candidateClip.trimStartMs + maxAllowedSourceDur;
          candidateClip = candidateClip.copyWith(
            timelineEndMs: clampedEnd,
            trimEndMs: newTrimEnd,
          );
        }
      }
      updatedClips[clipIndex] = candidateClip;

      // Overlay clips are completely independent floating clips
      final updatedProject = state.project.copyWith(videoClips: updatedClips);
      state = state.copyWith(
        project: updatedProject,
        playheadPositionMs: candidateClip.timelineStartMs,
      );
    } else {
      // Main track clips: when duration changes, subsequent clips ripple smoothly in real-time
      int offset = targetClip.timelineEndMs;
      for (int i = clipIndex + 1; i < updatedClips.length; i++) {
        if (!updatedClips[i].isOverlay) {
          final dur = updatedClips[i].effectiveDurationMs;
          updatedClips[i] = updatedClips[i].copyWith(
            timelineStartMs: offset,
            timelineEndMs: offset + dur,
          );
          offset += dur;
        }
      }

      final maxEnd = updatedClips.where((c) => !c.isOverlay).fold(0, (maxVal, c) => max(maxVal, c.timelineEndMs));
      final newTotalDur = max(maxEnd, 1000);
      final updatedProject = state.project.copyWith(
        videoClips: updatedClips,
        durationMs: newTotalDur,
      );

      state = state.copyWith(
        project: updatedProject,
        playheadPositionMs: activeTrimPosMs,
      );
    }
  }

  /// Commits in-memory trim/duration changes and ripple-snaps main track flush upon drag completion
  void finishClipDurationDrag() {
    _dragAccumulatorPixels = 0.0;

    int currentOffset = 0;
    final finalClips = <VideoClipEntity>[];
    for (final c in state.project.videoClips) {
      if (c.isOverlay) {
        finalClips.add(c);
      } else {
        final dur = c.effectiveDurationMs;
        finalClips.add(c.copyWith(
          timelineStartMs: currentOffset,
          timelineEndMs: currentOffset + dur,
        ));
        currentOffset += dur;
      }
    }

    final newTotalDur = max(currentOffset, 1000);
    final updatedProject = state.project.copyWith(
      videoClips: finalClips,
      durationMs: newTotalDur,
    );

    final newPlayhead = min(state.playheadPositionMs, newTotalDur);
    state = state.copyWith(
      project: updatedProject,
      playheadPositionMs: newPlayhead,
    );
    _persistChanges();
  }

  void moveVideoClipPosition({
    required String clipId,
    required double deltaPixels,
    required double pixelsPerSecond,
  }) {
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final clipIndex = state.project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return;

    final clip = state.project.videoClips[clipIndex];

    if (clip.isOverlay) {
      final dur = clip.effectiveDurationMs;
      final totalDuration = state.project.calculatedDurationMs;
      final overlayClips = state.project.videoClips.where((c) => c.isOverlay).toList();
      final bounds = TimelineLayoutHelper.computeLaneBounds<VideoClipEntity>(
        clipId: clipId,
        currentStartMs: clip.timelineStartMs,
        currentDurationMs: dur,
        items: overlayClips,
        getStart: (c) => c.timelineStartMs,
        getEnd: (c) => c.timelineEndMs,
        getId: (c) => c.id,
        manualLanes: state.clipLanes,
      );

      final rawStart = clip.timelineStartMs + deltaMs;
      final int newStart = rawStart.clamp(
        bounds.minStartMs,
        bounds.maxStartMs ?? (totalDuration + 10000),
      ).toInt();

      final updatedClips = state.project.videoClips.map((c) {
        if (c.id == clipId) {
          return c.copyWith(
            timelineStartMs: newStart,
            timelineEndMs: newStart + dur,
          );
        }
        return c;
      }).toList();

      final updated = state.project.copyWith(videoClips: updatedClips);
      state = state.copyWith(project: updated);
      _persistChanges();
    } else {
      if (deltaPixels < -25 && clipIndex > 0) {
        reorderVideoClips(clipIndex, clipIndex - 1);
      } else if (deltaPixels > 25 && clipIndex < state.project.videoClips.length - 1) {
        reorderVideoClips(clipIndex, clipIndex + 1);
      }
    }
  }

  /// Places or moves a clip vertically between the Main Video Track and the Overlay Track
  /// without overlapping any existing clip on that track.
  void moveClipToTrack({
    required String clipId,
    required bool toOverlay,
    int? targetTimelineStartMs,
  }) {
    _recordHistory();
    final clipIndex = state.project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return;

    final clip = state.project.videoClips[clipIndex];
    if (clip.isOverlay == toOverlay) return;

    final mainClips = state.project.videoClips.where((c) => !c.isOverlay && c.id != clipId).toList();
    final overlayClips = state.project.videoClips.where((c) => c.isOverlay && c.id != clipId).toList();

    if (toOverlay) {
      // 1. Moving from Main Track to Overlay Track (Vertical Move Down)
      int offset = 0;
      final updatedMain = <VideoClipEntity>[];
      for (final m in mainClips) {
        final dur = m.effectiveDurationMs;
        updatedMain.add(m.copyWith(
          timelineStartMs: offset,
          timelineEndMs: offset + dur,
        ));
        offset += dur;
      }

      // 2. Find clean non-overlapping position on Overlay track
      final dur = clip.effectiveDurationMs;
      int proposedStart = max(0, targetTimelineStartMs ?? clip.timelineStartMs);

      overlayClips.sort((a, b) => a.timelineStartMs.compareTo(b.timelineStartMs));

      bool overlaps = false;
      for (final ov in overlayClips) {
        if (proposedStart < ov.timelineEndMs && (proposedStart + dur) > ov.timelineStartMs) {
          overlaps = true;
          break;
        }
      }

      if (overlaps) {
        // Find first empty gap on overlay track that fits this clip
        int candidate = 0;
        bool foundGap = false;
        for (final ov in overlayClips) {
          if (ov.timelineStartMs - candidate >= dur) {
            proposedStart = candidate;
            foundGap = true;
            break;
          }
          candidate = max(candidate, ov.timelineEndMs);
        }
        if (!foundGap) {
          proposedStart = candidate;
        }
      }

      final updatedClip = clip.copyWith(
        isOverlay: true,
        zoomScale: 0.6,
        timelineStartMs: proposedStart,
        timelineEndMs: proposedStart + dur,
      );

      final allClips = [...updatedMain, ...overlayClips, updatedClip];
      final maxDuration = allClips.fold<int>(0, (m, c) => max(m, c.timelineEndMs));

      final updatedProject = state.project.copyWith(
        videoClips: allClips,
        durationMs: max(maxDuration, 1000),
      );

      state = state.copyWith(
        project: updatedProject,
        selectionType: SelectionType.overlayClip,
        selectedItemId: updatedClip.id,
      );
      _persistChanges();
    } else {
      // 2. Moving from Overlay Track to Main Track (Vertical Move Up)
      final targetTime = targetTimelineStartMs ?? clip.timelineStartMs;

      int insertIndex = mainClips.length;
      for (int i = 0; i < mainClips.length; i++) {
        if (mainClips[i].timelineStartMs >= targetTime) {
          insertIndex = i;
          break;
        }
      }

      final updatedClip = clip.copyWith(
        isOverlay: false,
        zoomScale: 1.0,
      );
      mainClips.insert(insertIndex, updatedClip);

      int offset = 0;
      final updatedMain = <VideoClipEntity>[];
      for (final m in mainClips) {
        final d = m.effectiveDurationMs;
        updatedMain.add(m.copyWith(
          timelineStartMs: offset,
          timelineEndMs: offset + d,
        ));
        offset += d;
      }

      final allClips = [...updatedMain, ...overlayClips];
      final maxDuration = allClips.fold<int>(0, (m, c) => max(m, c.timelineEndMs));

      final updatedProject = state.project.copyWith(
        videoClips: allClips,
        durationMs: max(maxDuration, 1000),
      );

      state = state.copyWith(
        project: updatedProject,
        selectionType: SelectionType.videoClip,
        selectedItemId: updatedClip.id,
      );
      _persistChanges();
    }
  }

  /// Automatically switches or moves a clip into an empty space on its track without overlapping.
  void setClipVerticalLane(String clipId, int lane) {
    final updated = Map<String, int>.from(state.clipLanes);
    updated[clipId] = max(0, lane);
    state = state.copyWith(clipLanes: updated);
  }

  void moveClipVerticalLane(String clipId, int delta) {
    final current = state.clipLanes[clipId] ?? 0;
    final next = max(0, current + delta);
    setClipVerticalLane(clipId, next);
  }

  int _findNextEmptySlot({
    required int currentStart,
    required int currentEnd,
    required int duration,
    required List<({int start, int end})> others,
  }) {
    if (others.isEmpty) return currentStart;

    final sorted = List<({int start, int end})>.from(others)
      ..sort((a, b) => a.start.compareTo(b.start));

    // 1. Search forward from currentEnd
    int searchFrom = currentEnd;
    for (final o in sorted) {
      if (o.start >= searchFrom) {
        if (o.start - searchFrom >= duration) {
          return searchFrom;
        }
        searchFrom = max(searchFrom, o.end);
      }
    }
    if (searchFrom >= sorted.last.end) {
      return searchFrom;
    }

    // 2. Wrap around from 0
    int wrapFrom = 0;
    for (final o in sorted) {
      if (o.start >= wrapFrom) {
        if (o.start - wrapFrom >= duration && (wrapFrom - currentStart).abs() > 200) {
          return wrapFrom;
        }
        wrapFrom = max(wrapFrom, o.end);
      }
    }

    return sorted.last.end;
  }

  void switchClipToEmptySpace(String clipId) {
    _recordHistory();

    // 1. Text Overlay
    final textIdx = state.project.textOverlays.indexWhere((t) => t.id == clipId);
    if (textIdx != -1) {
      final item = state.project.textOverlays[textIdx];
      final others = state.project.textOverlays.where((t) => t.id != clipId).toList();
      final dur = item.effectiveDurationMs;
      final newStart = _findNextEmptySlot(
        currentStart: item.timelineStartMs,
        currentEnd: item.timelineEndMs,
        duration: dur,
        others: others.map((o) => (start: o.timelineStartMs, end: o.timelineEndMs)).toList(),
      );
      final updated = List<TextOverlayEntity>.from(state.project.textOverlays);
      updated[textIdx] = item.copyWith(
        timelineStartMs: newStart,
        timelineEndMs: newStart + dur,
      );
      state = state.copyWith(
        project: state.project.copyWith(
          textOverlays: updated,
          durationMs: max(state.project.durationMs, newStart + dur),
        ),
        playheadPositionMs: newStart,
      );
      _persistChanges();
      return;
    }

    // 2. Sticker Overlay
    final stickerIdx = state.project.stickerOverlays.indexWhere((s) => s.id == clipId);
    if (stickerIdx != -1) {
      final item = state.project.stickerOverlays[stickerIdx];
      final others = state.project.stickerOverlays.where((s) => s.id != clipId).toList();
      final dur = item.effectiveDurationMs;
      final newStart = _findNextEmptySlot(
        currentStart: item.timelineStartMs,
        currentEnd: item.timelineEndMs,
        duration: dur,
        others: others.map((o) => (start: o.timelineStartMs, end: o.timelineEndMs)).toList(),
      );
      final updated = List<StickerOverlayEntity>.from(state.project.stickerOverlays);
      updated[stickerIdx] = item.copyWith(
        timelineStartMs: newStart,
        timelineEndMs: newStart + dur,
      );
      state = state.copyWith(
        project: state.project.copyWith(
          stickerOverlays: updated,
          durationMs: max(state.project.durationMs, newStart + dur),
        ),
        playheadPositionMs: newStart,
      );
      _persistChanges();
      return;
    }

    // 3. Subtitle
    final subIdx = state.project.subtitles.indexWhere((s) => s.id == clipId);
    if (subIdx != -1) {
      final item = state.project.subtitles[subIdx];
      final others = state.project.subtitles.where((s) => s.id != clipId).toList();
      final dur = item.durationMs;
      final newStart = _findNextEmptySlot(
        currentStart: item.timelineStartMs,
        currentEnd: item.timelineEndMs,
        duration: dur,
        others: others.map((o) => (start: o.timelineStartMs, end: o.timelineEndMs)).toList(),
      );
      final updated = List<SubtitleEntity>.from(state.project.subtitles);
      updated[subIdx] = item.copyWith(
        timelineStartMs: newStart,
        timelineEndMs: newStart + dur,
      );
      state = state.copyWith(
        project: state.project.copyWith(
          subtitles: updated,
          durationMs: max(state.project.durationMs, (newStart + dur).toInt()),
        ),
        playheadPositionMs: newStart,
      );
      _persistChanges();
      return;
    }

    // 4. Effect Clip
    final effIdx = state.project.effectClips.indexWhere((e) => e.id == clipId);
    if (effIdx != -1) {
      final item = state.project.effectClips[effIdx];
      final others = state.project.effectClips.where((e) => e.id != clipId).toList();
      final dur = item.durationMs;
      final newStart = _findNextEmptySlot(
        currentStart: item.timelineStartMs,
        currentEnd: item.timelineEndMs,
        duration: dur,
        others: others.map((o) => (start: o.timelineStartMs, end: o.timelineEndMs)).toList(),
      );
      final updated = List<EffectClipEntity>.from(state.project.effectClips);
      updated[effIdx] = item.copyWith(timelineStartMs: newStart);
      state = state.copyWith(
        project: state.project.copyWith(
          effectClips: updated,
          durationMs: max(state.project.durationMs, newStart + dur),
        ),
        playheadPositionMs: newStart,
      );
      _persistChanges();
      return;
    }

    // 5. Animation Clip
    final animIdx = state.project.animationClips.indexWhere((a) => a.id == clipId);
    if (animIdx != -1) {
      final item = state.project.animationClips[animIdx];
      final others = state.project.animationClips.where((a) => a.id != clipId).toList();
      final dur = item.durationMs;
      final newStart = _findNextEmptySlot(
        currentStart: item.timelineStartMs,
        currentEnd: item.timelineEndMs,
        duration: dur,
        others: others.map((o) => (start: o.timelineStartMs, end: o.timelineEndMs)).toList(),
      );
      final updated = List<AnimationClipEntity>.from(state.project.animationClips);
      updated[animIdx] = item.copyWith(timelineStartMs: newStart);
      state = state.copyWith(
        project: state.project.copyWith(
          animationClips: updated,
          durationMs: max(state.project.durationMs, newStart + dur),
        ),
        playheadPositionMs: newStart,
      );
      _persistChanges();
      return;
    }

    // 6. Audio Clip
    final audIdx = state.project.audioClips.indexWhere((a) => a.id == clipId);
    if (audIdx != -1) {
      final item = state.project.audioClips[audIdx];
      final others = state.project.audioClips.where((a) => a.id != clipId).toList();
      final dur = item.effectiveDurationMs;
      final newStart = _findNextEmptySlot(
        currentStart: item.timelineStartMs,
        currentEnd: item.timelineEndMs,
        duration: dur,
        others: others.map((o) => (start: o.timelineStartMs, end: o.timelineEndMs)).toList(),
      );
      final updated = List<AudioClipEntity>.from(state.project.audioClips);
      updated[audIdx] = item.copyWith(
        timelineStartMs: newStart,
        timelineEndMs: newStart + dur,
      );
      state = state.copyWith(
        project: state.project.copyWith(
          audioClips: updated,
          durationMs: max(state.project.durationMs, newStart + dur),
        ),
        playheadPositionMs: newStart,
      );
      _persistChanges();
      return;
    }

    // 7. Video Clip
    final clipIndex = state.project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return;
    final clip = state.project.videoClips[clipIndex];

    if (clip.isOverlay) {
      final otherOverlays = state.project.videoClips
          .where((c) => c.isOverlay && c.id != clipId)
          .toList();
      final dur = clip.effectiveDurationMs;
      final chosenStart = _findNextEmptySlot(
        currentStart: clip.timelineStartMs,
        currentEnd: clip.timelineEndMs,
        duration: dur,
        others: otherOverlays.map((o) => (start: o.timelineStartMs, end: o.timelineEndMs)).toList(),
      );

      final updatedClips = state.project.videoClips.map((c) {
        if (c.id == clipId) {
          return c.copyWith(
            timelineStartMs: chosenStart,
            timelineEndMs: chosenStart + dur,
          );
        }
        return c;
      }).toList();

      final maxDuration = updatedClips.fold<int>(0, (m, c) => max(m, c.timelineEndMs));
      final updatedProject = state.project.copyWith(
        videoClips: updatedClips,
        durationMs: max(maxDuration, 1000),
      );
      state = state.copyWith(project: updatedProject, playheadPositionMs: chosenStart);
      _persistChanges();
    } else {
      final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
      final idx = mainClips.indexWhere((c) => c.id == clipId);
      if (idx != -1 && mainClips.length > 1) {
        final targetIdx = (idx + 1) % mainClips.length;
        reorderVideoClips(idx, targetIdx);
      }
    }
  }

  void syncClipRealDuration(String clipId, int realDurationMs) {
    if (realDurationMs <= 0) return;
    final clipIndex = state.project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return;

    final clip = state.project.videoClips[clipIndex];
    if (clip.isPhoto) return;
    // If real duration differs from the recorded source duration
    if (clip.sourceDurationMs != realDurationMs) {
      final wasFullClip = clip.trimEndMs >= clip.sourceDurationMs ||
          clip.trimEndMs == 4000 ||
          clip.trimEndMs == 5000 ||
          clip.trimEndMs == 6000;
      final newTrimEnd = wasFullClip ? realDurationMs : min(clip.trimEndMs, realDurationMs);

      final List<VideoClipEntity> updatedClips = List.from(state.project.videoClips);

      if (clip.isOverlay) {
        // Overlay clip: maintain user-defined timeline start, update duration
        final effectiveDur = newTrimEnd - clip.trimStartMs;
        updatedClips[clipIndex] = clip.copyWith(
          sourceDurationMs: realDurationMs,
          trimEndMs: newTrimEnd,
          timelineEndMs: clip.timelineStartMs + (effectiveDur > 0 ? effectiveDur : realDurationMs),
        );

        final maxEnd = updatedClips.fold(0, (maxVal, c) => max(maxVal, c.timelineEndMs));
        final updatedProject = state.project.copyWith(
          videoClips: updatedClips,
          durationMs: max(maxEnd, 1000),
        );

        state = state.copyWith(project: updatedProject);
        _persistChanges();
        return;
      }

      updatedClips[clipIndex] = clip.copyWith(
        sourceDurationMs: realDurationMs,
        trimEndMs: newTrimEnd,
      );

      // Re-align only main track clips sequentially along timeline
      int currentOffset = 0;
      final alignedClips = <VideoClipEntity>[];
      for (final c in updatedClips) {
        if (c.isOverlay) {
          alignedClips.add(c);
        } else {
          final dur = c.effectiveDurationMs;
          alignedClips.add(c.copyWith(
            timelineStartMs: currentOffset,
            timelineEndMs: currentOffset + dur,
          ));
          currentOffset += dur;
        }
      }

      final maxEnd = alignedClips.fold(0, (maxVal, c) => max(maxVal, c.timelineEndMs));
      final updatedProject = state.project.copyWith(
        videoClips: alignedClips,
        durationMs: max(maxEnd, 1000),
      );

      state = state.copyWith(project: updatedProject);
      _persistChanges();
    }
  }

  void addVideoClip({
    required String name,
    required String mediaPath,
    int durationMs = 5000,
  }) {
    _recordHistory();
    final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
    final startOffset = mainClips.isEmpty ? 0 : mainClips.last.timelineEndMs;

    final effectiveDuration = durationMs > 0 ? durationMs : 5000;

    final newClip = VideoClipEntity(
      id: IdGenerator.generate(),
      mediaPath: mediaPath,
      name: name,
      sourceDurationMs: effectiveDuration,
      timelineStartMs: startOffset,
      timelineEndMs: startOffset + effectiveDuration,
      trimStartMs: 0,
      trimEndMs: effectiveDuration,
    );

    final updated = state.project.copyWith(
      videoClips: [...state.project.videoClips, newClip],
      durationMs: startOffset + effectiveDuration,
    );

    state = state.copyWith(project: updated);
    _persistChanges();
  }

  // --- Audio Track Actions ---
  void addAudioClip(AudioClipEntity clip) {
    _recordHistory();
    final dur = clip.effectiveDurationMs;
    final startMs = findNonOverlappingStartMs(
      preferredStartMs: clip.timelineStartMs > 0 ? clip.timelineStartMs : state.playheadPositionMs,
      durationMs: dur,
      existingIntervals: state.project.audioClips
          .map((a) => (startMs: a.timelineStartMs, endMs: a.timelineEndMs))
          .toList(),
    );
    final adjustedClip = clip.copyWith(
      timelineStartMs: startMs,
      timelineEndMs: startMs + dur,
    );

    final updated = state.project.copyWith(
      audioClips: [...state.project.audioClips, adjustedClip],
      durationMs: max(state.project.durationMs, startMs + dur),
    );
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void updateAudioVolume(String clipId, double volume) {
    _recordHistory();
    final list = state.project.audioClips.map((a) {
      if (a.id == clipId) {
        return a.copyWith(volume: volume);
      }
      return a;
    }).toList();

    final updated = state.project.copyWith(audioClips: list);
    state = state.copyWith(project: updated);
    _audioService.updateVolume(clipId, volume);
    _persistChanges();
  }

  void updateAudioTrack(AudioClipEntity updatedClip) {
    _recordHistory();
    final list = state.project.audioClips.map((a) {
      if (a.id == updatedClip.id) return updatedClip;
      return a;
    }).toList();

    final updated = state.project.copyWith(audioClips: list);
    state = state.copyWith(project: updated);
    _syncAudio();
    _persistChanges();
  }

  void deleteAudioTrack(String clipId) {
    _recordHistory();
    final list = state.project.audioClips.where((a) => a.id != clipId).toList();
    final updated = state.project.copyWith(audioClips: list);
    state = state.copyWith(project: updated);
    _syncAudio();
    _persistChanges();
  }

  void duplicateAudioClip(String clipId) {
    final clip = state.project.audioClips.firstWhere((a) => a.id == clipId, orElse: () => state.project.audioClips.first);
    _recordHistory();

    final dur = clip.effectiveDurationMs;
    final startMs = findNonOverlappingStartMs(
      preferredStartMs: clip.timelineEndMs,
      durationMs: dur,
      existingIntervals: state.project.audioClips
          .map((a) => (startMs: a.timelineStartMs, endMs: a.timelineEndMs))
          .toList(),
    );

    final duplicated = clip.copyWith(
      id: IdGenerator.generate(),
      title: '${clip.title} (Copy)',
      timelineStartMs: startMs,
      timelineEndMs: startMs + dur,
    );

    final updated = state.project.copyWith(
      audioClips: [...state.project.audioClips, duplicated],
      durationMs: max(state.project.durationMs, startMs + dur),
    );
    state = state.copyWith(project: updated, selectionType: SelectionType.audioClip, selectedItemId: duplicated.id);
    _syncAudio();
    _persistChanges();
  }

  void updateAudioDurationByDrag({
    required String clipId,
    required double deltaPixels,
    required double pixelsPerSecond,
    required bool isLeftHandle,
  }) {
    final index = state.project.audioClips.indexWhere((a) => a.id == clipId);
    if (index == -1) return;

    final clip = state.project.audioClips[index];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeTrimBounds<AudioClipEntity>(
      clipId: clipId,
      currentStartMs: clip.timelineStartMs,
      currentEndMs: clip.timelineEndMs,
      items: state.project.audioClips,
      getStart: (a) => a.timelineStartMs,
      getEnd: (a) => a.timelineEndMs,
      getId: (a) => a.id,
      manualLanes: state.clipLanes,
    );

    final List<AudioClipEntity> updatedList = List.from(state.project.audioClips);

    if (isLeftHandle) {
      final maxTrimShift = clip.trimEndMs - 500;
      final rawTrimStart = (clip.trimStartMs + deltaMs).clamp(0, maxTrimShift);
      final shift = rawTrimStart - clip.trimStartMs;
      final rawTimelineStart = clip.timelineStartMs + shift;
      final clampedTimelineStart = rawTimelineStart.clamp(bounds.minTrimStartMs, clip.timelineEndMs - 500);
      final finalTrimStart = clip.trimStartMs + (clampedTimelineStart - clip.timelineStartMs);
      updatedList[index] = clip.copyWith(
        trimStartMs: finalTrimStart,
        timelineStartMs: clampedTimelineStart,
      );
    } else {
      final maxAllowedEnd = bounds.maxTrimEndMs ?? (totalDuration + 10000);
      final rawTimelineEnd = (clip.timelineEndMs + deltaMs).clamp(clip.timelineStartMs + 500, maxAllowedEnd);
      final newDur = rawTimelineEnd - clip.timelineStartMs;
      final newTrimEnd = clip.trimStartMs + newDur;
      updatedList[index] = clip.copyWith(
        trimEndMs: newTrimEnd,
        timelineEndMs: rawTimelineEnd,
      );
    }

    final updated = state.project.copyWith(audioClips: updatedList);
    state = state.copyWith(project: updated);
    _syncAudio();
    _persistChanges();
  }

  void moveAudioTimelinePosition({
    required String clipId,
    required double deltaPixels,
    required double pixelsPerSecond,
  }) {
    final index = state.project.audioClips.indexWhere((a) => a.id == clipId);
    if (index == -1) return;

    final clip = state.project.audioClips[index];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final dur = clip.effectiveDurationMs;
    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeLaneBounds<AudioClipEntity>(
      clipId: clipId,
      currentStartMs: clip.timelineStartMs,
      currentDurationMs: dur,
      items: state.project.audioClips,
      getStart: (a) => a.timelineStartMs,
      getEnd: (a) => a.timelineEndMs,
      getId: (a) => a.id,
      manualLanes: state.clipLanes,
    );

    final rawStart = clip.timelineStartMs + deltaMs;
    final int newStart = rawStart.clamp(
      bounds.minStartMs,
      bounds.maxStartMs ?? (totalDuration + 10000),
    ).toInt();

    final List<AudioClipEntity> updatedList = List.from(state.project.audioClips);
    updatedList[index] = clip.copyWith(
      timelineStartMs: newStart,
      timelineEndMs: newStart + dur,
    );

    final updated = state.project.copyWith(audioClips: updatedList);
    state = state.copyWith(project: updated);
    _syncAudio();
    _persistChanges();
  }

  // --- Text Overlay Actions ---
  void addTextOverlay({
    required String text,
    String fontFamily = 'Inter',
    double fontSize = 26.0,
    int colorHex = 0xFFFFFFFF,
    int? backgroundColorHex,
    int? outlineColorHex,
    OverlayAnimationType animationType = OverlayAnimationType.none,
  }) {
    _recordHistory();
    const durationMs = 3500;
    final startMs = state.playheadPositionMs;
    final endMs = startMs + durationMs;
    final activeTexts = state.project.textOverlays.where((t) {
      return startMs >= t.timelineStartMs && startMs <= t.timelineEndMs;
    }).toList();

    final newText = TextOverlayEntity(
      id: IdGenerator.generate(),
      text: text,
      fontFamily: fontFamily,
      fontSize: fontSize,
      colorHex: colorHex,
      backgroundColorHex: backgroundColorHex,
      outlineColorHex: outlineColorHex,
      timelineStartMs: startMs,
      timelineEndMs: endMs,
      animationType: animationType,
      posY: activeTexts.isNotEmpty ? (0.5 + (activeTexts.length * 0.08)).clamp(0.1, 0.9) : 0.5,
    );

    final updated = state.project.copyWith(
      textOverlays: [...state.project.textOverlays, newText],
      durationMs: max(state.project.durationMs, endMs),
    );
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.textOverlay,
      selectedItemId: newText.id,
      playheadPositionMs: startMs,
    );
    _persistChanges();
  }

  void updateTextOverlay(TextOverlayEntity textOverlay) {
    _recordHistory();
    final list = state.project.textOverlays.map((t) {
      if (t.id == textOverlay.id) return textOverlay;
      return t;
    }).toList();

    final updated = state.project.copyWith(textOverlays: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void updateTextTransform({
    required String textId,
    double? posX,
    double? posY,
    double? scale,
    double? rotation,
    bool persist = true,
  }) {
    final list = state.project.textOverlays.map((t) {
      if (t.id == textId) {
        return t.copyWith(
          posX: posX != null ? posX.clamp(0.0, 1.0) : t.posX,
          posY: posY != null ? posY.clamp(0.0, 1.0) : t.posY,
          scale: scale != null ? scale.clamp(0.3, 4.0) : t.scale,
          rotation: rotation ?? t.rotation,
        );
      }
      return t;
    }).toList();

    final updated = state.project.copyWith(textOverlays: list);
    state = state.copyWith(project: updated);
    if (persist) {
      _persistChanges();
    }
  }

  void updateTextDurationByDrag({
    required String textId,
    required double deltaPixels,
    required double pixelsPerSecond,
    required bool isLeftHandle,
  }) {
    final textIndex = state.project.textOverlays.indexWhere((t) => t.id == textId);
    if (textIndex == -1) return;

    final item = state.project.textOverlays[textIndex];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeTrimBounds<TextOverlayEntity>(
      clipId: textId,
      currentStartMs: item.timelineStartMs,
      currentEndMs: item.timelineEndMs,
      items: state.project.textOverlays,
      getStart: (t) => t.timelineStartMs,
      getEnd: (t) => t.timelineEndMs,
      getId: (t) => t.id,
      manualLanes: state.clipLanes,
    );

    final List<TextOverlayEntity> updatedList = List.from(state.project.textOverlays);

    if (isLeftHandle) {
      final newStart = (item.timelineStartMs + deltaMs).clamp(bounds.minTrimStartMs, item.timelineEndMs - 500);
      updatedList[textIndex] = item.copyWith(timelineStartMs: newStart);
    } else {
      final maxAllowed = bounds.maxTrimEndMs ?? (totalDuration + 10000);
      final newEnd = (item.timelineEndMs + deltaMs).clamp(item.timelineStartMs + 500, maxAllowed);
      updatedList[textIndex] = item.copyWith(timelineEndMs: newEnd);
    }

    final updated = state.project.copyWith(textOverlays: updatedList);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void moveTextTimelinePosition({
    required String textId,
    required double deltaPixels,
    required double pixelsPerSecond,
  }) {
    final textIndex = state.project.textOverlays.indexWhere((t) => t.id == textId);
    if (textIndex == -1) return;

    final item = state.project.textOverlays[textIndex];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final dur = item.effectiveDurationMs;
    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeLaneBounds<TextOverlayEntity>(
      clipId: textId,
      currentStartMs: item.timelineStartMs,
      currentDurationMs: dur,
      items: state.project.textOverlays,
      getStart: (t) => t.timelineStartMs,
      getEnd: (t) => t.timelineEndMs,
      getId: (t) => t.id,
      manualLanes: state.clipLanes,
    );

    final rawStart = item.timelineStartMs + deltaMs;
    final int newStart = rawStart.clamp(
      bounds.minStartMs,
      bounds.maxStartMs ?? (totalDuration + 10000),
    ).toInt();
    final int newEnd = newStart + dur;

    final List<TextOverlayEntity> updatedList = List.from(state.project.textOverlays);
    updatedList[textIndex] = item.copyWith(
      timelineStartMs: newStart,
      timelineEndMs: newEnd,
    );

    final updated = state.project.copyWith(textOverlays: updatedList);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void reorderTextOverlays(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.project.textOverlays.length) return;
    if (newIndex < 0 || newIndex >= state.project.textOverlays.length) return;
    if (oldIndex == newIndex) return;

    _recordHistory();
    final list = List<TextOverlayEntity>.from(state.project.textOverlays);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    final updated = state.project.copyWith(textOverlays: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void duplicateTextOverlay(String textId) {
    final text = state.project.textOverlays.firstWhere((t) => t.id == textId, orElse: () => state.project.textOverlays.first);
    _recordHistory();

    final dur = text.effectiveDurationMs;
    final startMs = text.timelineStartMs;
    final endMs = startMs + dur;

    final duplicated = text.copyWith(
      id: IdGenerator.generate(),
      text: '${text.text} (Copy)',
      posY: (text.posY + 0.08).clamp(0.1, 0.9),
      timelineStartMs: startMs,
      timelineEndMs: endMs,
    );

    final updated = state.project.copyWith(
      textOverlays: [...state.project.textOverlays, duplicated],
      durationMs: max(state.project.durationMs, endMs),
    );
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.textOverlay,
      selectedItemId: duplicated.id,
      playheadPositionMs: startMs,
    );
    _persistChanges();
  }

  void deleteTextOverlay(String textId) {
    _recordHistory();
    final texts = state.project.textOverlays.where((t) => t.id != textId).toList();
    final updated = state.project.copyWith(textOverlays: texts);
    state = state.copyWith(
      project: updated,
      selectedItemId: state.selectedItemId == textId ? null : state.selectedItemId,
      selectionType: state.selectedItemId == textId ? SelectionType.none : state.selectionType,
    );
    _persistChanges();
  }

  // --- Sticker Overlay Actions ---
  void addStickerOverlay({
    required String stickerKey,
    required String stickerName,
    required String assetEmojiOrPath,
  }) {
    _recordHistory();
    const durationMs = 3000;
    final startMs = state.playheadPositionMs;
    final endMs = startMs + durationMs;

    final sticker = StickerOverlayEntity(
      id: IdGenerator.generate(),
      stickerKey: stickerKey,
      stickerName: stickerName,
      assetEmojiOrPath: assetEmojiOrPath,
      timelineStartMs: startMs,
      timelineEndMs: endMs,
    );

    final updated = state.project.copyWith(
      stickerOverlays: [...state.project.stickerOverlays, sticker],
      durationMs: max(state.project.durationMs, endMs),
    );
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.stickerOverlay,
      selectedItemId: sticker.id,
      playheadPositionMs: startMs,
    );
    _persistChanges();
  }

  void updateStickerDurationByDrag({
    required String stickerId,
    required double deltaPixels,
    required double pixelsPerSecond,
    required bool isLeftHandle,
  }) {
    final index = state.project.stickerOverlays.indexWhere((s) => s.id == stickerId);
    if (index == -1) return;

    final item = state.project.stickerOverlays[index];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeTrimBounds<StickerOverlayEntity>(
      clipId: stickerId,
      currentStartMs: item.timelineStartMs,
      currentEndMs: item.timelineEndMs,
      items: state.project.stickerOverlays,
      getStart: (s) => s.timelineStartMs,
      getEnd: (s) => s.timelineEndMs,
      getId: (s) => s.id,
      manualLanes: state.clipLanes,
    );

    final List<StickerOverlayEntity> updatedList = List.from(state.project.stickerOverlays);
    if (isLeftHandle) {
      final newStart = (item.timelineStartMs + deltaMs).clamp(bounds.minTrimStartMs, item.timelineEndMs - 500);
      updatedList[index] = item.copyWith(timelineStartMs: newStart);
    } else {
      final maxAllowed = bounds.maxTrimEndMs ?? (totalDuration + 10000);
      final newEnd = (item.timelineEndMs + deltaMs).clamp(item.timelineStartMs + 500, maxAllowed);
      updatedList[index] = item.copyWith(timelineEndMs: newEnd);
    }

    final updated = state.project.copyWith(stickerOverlays: updatedList);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void moveStickerTimelinePosition({
    required String stickerId,
    required double deltaPixels,
    required double pixelsPerSecond,
  }) {
    final index = state.project.stickerOverlays.indexWhere((s) => s.id == stickerId);
    if (index == -1) return;

    final item = state.project.stickerOverlays[index];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final dur = item.effectiveDurationMs;
    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeLaneBounds<StickerOverlayEntity>(
      clipId: stickerId,
      currentStartMs: item.timelineStartMs,
      currentDurationMs: dur,
      items: state.project.stickerOverlays,
      getStart: (s) => s.timelineStartMs,
      getEnd: (s) => s.timelineEndMs,
      getId: (s) => s.id,
      manualLanes: state.clipLanes,
    );

    final rawStart = item.timelineStartMs + deltaMs;
    final int newStart = rawStart.clamp(
      bounds.minStartMs,
      bounds.maxStartMs ?? (totalDuration + 10000),
    ).toInt();
    final int newEnd = newStart + dur;

    final List<StickerOverlayEntity> updatedList = List.from(state.project.stickerOverlays);
    updatedList[index] = item.copyWith(
      timelineStartMs: newStart,
      timelineEndMs: newEnd,
    );

    final updated = state.project.copyWith(stickerOverlays: updatedList);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void updateStickerTransform({
    required String stickerId,
    double? posX,
    double? posY,
    double? scale,
    double? rotation,
    bool persist = true,
  }) {
    final list = state.project.stickerOverlays.map((s) {
      if (s.id == stickerId) {
        return s.copyWith(
          posX: posX != null ? posX.clamp(0.0, 1.0) : s.posX,
          posY: posY != null ? posY.clamp(0.0, 1.0) : s.posY,
          scale: scale != null ? scale.clamp(0.3, 5.0) : s.scale,
          rotation: rotation ?? s.rotation,
        );
      }
      return s;
    }).toList();

    final updated = state.project.copyWith(stickerOverlays: list);
    state = state.copyWith(project: updated);
    if (persist) {
      _persistChanges();
    }
  }

  void duplicateStickerOverlay(String stickerId) {
    final sticker = state.project.stickerOverlays.firstWhere((s) => s.id == stickerId, orElse: () => state.project.stickerOverlays.first);
    _recordHistory();

    final dur = sticker.effectiveDurationMs;
    final startMs = findNonOverlappingStartMs(
      preferredStartMs: sticker.timelineEndMs,
      durationMs: dur,
      existingIntervals: state.project.stickerOverlays
          .map((s) => (startMs: s.timelineStartMs, endMs: s.timelineEndMs))
          .toList(),
    );
    final endMs = startMs + dur;

    final duplicated = sticker.copyWith(
      id: IdGenerator.generate(),
      stickerName: '${sticker.stickerName} (Copy)',
      posY: (sticker.posY + 0.08).clamp(0.1, 0.9),
      timelineStartMs: startMs,
      timelineEndMs: endMs,
    );

    final updated = state.project.copyWith(
      stickerOverlays: [...state.project.stickerOverlays, duplicated],
      durationMs: max(state.project.durationMs, endMs),
    );
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.stickerOverlay,
      selectedItemId: duplicated.id,
      playheadPositionMs: startMs,
    );
    _persistChanges();
  }

  void deleteStickerOverlay(String stickerId) {
    _recordHistory();
    final list = state.project.stickerOverlays.where((s) => s.id != stickerId).toList();
    final updated = state.project.copyWith(stickerOverlays: list);
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.none,
      selectedItemId: null,
    );
    _persistChanges();
  }

  // --- Subtitle Actions ---
  void updateSubtitleDurationByDrag({
    required String subtitleId,
    required double deltaPixels,
    required double pixelsPerSecond,
    required bool isLeftHandle,
  }) {
    final index = state.project.subtitles.indexWhere((s) => s.id == subtitleId);
    if (index == -1) return;

    final item = state.project.subtitles[index];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeTrimBounds<SubtitleEntity>(
      clipId: subtitleId,
      currentStartMs: item.timelineStartMs,
      currentEndMs: item.timelineEndMs,
      items: state.project.subtitles,
      getStart: (s) => s.timelineStartMs,
      getEnd: (s) => s.timelineEndMs,
      getId: (s) => s.id,
      manualLanes: state.clipLanes,
    );

    final List<SubtitleEntity> updatedList = List.from(state.project.subtitles);
    if (isLeftHandle) {
      final newStart = (item.timelineStartMs + deltaMs).clamp(bounds.minTrimStartMs, item.timelineEndMs - 500);
      updatedList[index] = item.copyWith(timelineStartMs: newStart);
    } else {
      final maxAllowed = bounds.maxTrimEndMs ?? (totalDuration + 10000);
      final newEnd = (item.timelineEndMs + deltaMs).clamp(item.timelineStartMs + 500, maxAllowed);
      updatedList[index] = item.copyWith(timelineEndMs: newEnd);
    }

    final updated = state.project.copyWith(subtitles: updatedList);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void moveSubtitleTimelinePosition({
    required String subtitleId,
    required double deltaPixels,
    required double pixelsPerSecond,
  }) {
    final index = state.project.subtitles.indexWhere((s) => s.id == subtitleId);
    if (index == -1) return;

    final item = state.project.subtitles[index];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final dur = item.durationMs;
    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeLaneBounds<SubtitleEntity>(
      clipId: subtitleId,
      currentStartMs: item.timelineStartMs,
      currentDurationMs: dur,
      items: state.project.subtitles,
      getStart: (s) => s.timelineStartMs,
      getEnd: (s) => s.timelineEndMs,
      getId: (s) => s.id,
      manualLanes: state.clipLanes,
    );

    final rawStart = item.timelineStartMs + deltaMs;
    final int newStart = rawStart.clamp(
      bounds.minStartMs,
      bounds.maxStartMs ?? (totalDuration + 10000),
    ).toInt();
    final int newEnd = newStart + dur;

    final List<SubtitleEntity> updatedList = List.from(state.project.subtitles);
    updatedList[index] = item.copyWith(
      timelineStartMs: newStart,
      timelineEndMs: newEnd,
    );

    final updated = state.project.copyWith(subtitles: updatedList);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  // --- Duplicate Active Selection ---
  void duplicateSelected() {
    if (state.selectedItemId == null) return;
    _recordHistory();
    final id = state.selectedItemId!;

    switch (state.selectionType) {
      case SelectionType.videoClip:
      case SelectionType.overlayClip:
        duplicateVideoClip(id);
        break;

      case SelectionType.audioClip:
        duplicateAudioClip(id);
        break;

      case SelectionType.textOverlay:
        duplicateTextOverlay(id);
        break;

      case SelectionType.stickerOverlay:
        final sticker = state.project.stickerOverlays.firstWhere((s) => s.id == id, orElse: () => state.project.stickerOverlays.first);
        final newId = IdGenerator.generate();
        final cloned = sticker.copyWith(
          id: newId,
          timelineStartMs: sticker.timelineStartMs + 500,
          timelineEndMs: sticker.timelineEndMs + 500,
          posX: (sticker.posX + 0.05).clamp(0.1, 0.9),
          posY: (sticker.posY + 0.05).clamp(0.1, 0.9),
        );
        final updated = state.project.copyWith(
          stickerOverlays: [...state.project.stickerOverlays, cloned],
        );
        state = state.copyWith(
          project: updated,
          selectedItemId: newId,
        );
        _persistChanges();
        break;

      case SelectionType.effectClip:
        duplicateEffectClip(id);
        break;

      case SelectionType.animationClip:
        duplicateAnimationClip(id);
        break;

      case SelectionType.subtitle:
        final sub = state.project.subtitles.firstWhere((s) => s.id == id, orElse: () => state.project.subtitles.first);
        final newId = IdGenerator.generate();
        final cloned = sub.copyWith(
          id: newId,
          timelineStartMs: sub.timelineStartMs + 1000,
          timelineEndMs: sub.timelineEndMs + 1000,
        );
        final updated = state.project.copyWith(
          subtitles: [...state.project.subtitles, cloned],
        );
        state = state.copyWith(
          project: updated,
          selectedItemId: newId,
        );
        _persistChanges();
        break;

      case SelectionType.none:
        break;
    }
  }

  // --- Delete Video Clip with Ripple Gap Closing ---
  void deleteVideoClip(String clipId) {
    if (state.project.videoClips.length <= 1) return;
    _recordHistory();

    final updated = _deleteClipUseCase(
      project: state.project,
      clipId: clipId,
    );

    final newPlayhead = min(state.playheadPositionMs, updated.calculatedDurationMs);

    state = state.copyWith(
      project: updated,
      playheadPositionMs: newPlayhead,
      selectionType: SelectionType.none,
      selectedItemId: null,
    );
    _syncAudio();
    _persistChanges();
  }

  // --- Delete Active Selection ---
  void deleteSelected() {
    if (state.selectedItemId == null) return;
    _recordHistory();

    final id = state.selectedItemId!;
    var updated = state.project;

    switch (state.selectionType) {
      case SelectionType.videoClip:
        if (updated.videoClips.length > 1) {
          updated = _deleteClipUseCase(
            project: updated,
            clipId: id,
          );
        }
        break;
      case SelectionType.overlayClip:
        final clips = updated.videoClips.where((c) => c.id != id).toList();
        updated = updated.copyWith(videoClips: clips);
        break;
      case SelectionType.audioClip:
        final audios = updated.audioClips.where((a) => a.id != id).toList();
        updated = updated.copyWith(audioClips: audios);
        break;
      case SelectionType.textOverlay:
        final texts = updated.textOverlays.where((t) => t.id != id).toList();
        updated = updated.copyWith(textOverlays: texts);
        break;
      case SelectionType.stickerOverlay:
        final stickers = updated.stickerOverlays.where((s) => s.id != id).toList();
        updated = updated.copyWith(stickerOverlays: stickers);
        break;
      case SelectionType.effectClip:
        final effects = updated.effectClips.where((e) => e.id != id).toList();
        updated = updated.copyWith(effectClips: effects);
        break;
      case SelectionType.animationClip:
        final anims = updated.animationClips.where((a) => a.id != id).toList();
        updated = updated.copyWith(animationClips: anims);
        break;
      case SelectionType.subtitle:
        final subs = updated.subtitles.where((s) => s.id != id).toList();
        updated = updated.copyWith(subtitles: subs);
        break;
      case SelectionType.none:
        break;
    }

    final newPlayhead = min(state.playheadPositionMs, updated.calculatedDurationMs);

    state = state.copyWith(
      project: updated,
      playheadPositionMs: newPlayhead,
      selectionType: SelectionType.none,
      selectedItemId: null,
    );
    _syncAudio();
    _persistChanges();
  }

  // --- Independent Effect Clip Actions ---
  void addEffectClip({
    required VideoEffectType effectType,
    int? startMs,
    int durationMs = 3000,
    double intensity = 1.0,
  }) {
    _recordHistory();
    final dur = durationMs > 0 ? durationMs : 3000;
    final start = startMs ?? state.playheadPositionMs;

    final newClip = EffectClipEntity(
      id: IdGenerator.generate(),
      effectType: effectType,
      timelineStartMs: start,
      durationMs: dur,
      intensity: intensity,
    );

    final updated = state.project.copyWith(
      effectClips: [...state.project.effectClips, newClip],
      durationMs: max(state.project.durationMs, start + dur),
    );

    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.effectClip,
      selectedItemId: newClip.id,
      playheadPositionMs: start,
    );
    _persistChanges();
  }

  void replaceEffectClip(String effectId, VideoEffectType newEffectType) {
    _recordHistory();
    final list = state.project.effectClips.map((e) {
      if (e.id == effectId) {
        return e.copyWith(effectType: newEffectType);
      }
      return e;
    }).toList();

    final updated = state.project.copyWith(effectClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void updateEffectClipIntensity(String effectId, double intensity) {
    _recordHistory();
    final list = state.project.effectClips.map((e) {
      if (e.id == effectId) {
        return e.copyWith(intensity: intensity.clamp(0.0, 1.0));
      }
      return e;
    }).toList();

    final updated = state.project.copyWith(effectClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void updateEffectDurationByDrag({
    required String effectId,
    required double deltaPixels,
    required double pixelsPerSecond,
    required bool isLeftHandle,
  }) {
    final index = state.project.effectClips.indexWhere((e) => e.id == effectId);
    if (index == -1) return;

    final clip = state.project.effectClips[index];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeTrimBounds<EffectClipEntity>(
      clipId: effectId,
      currentStartMs: clip.timelineStartMs,
      currentEndMs: clip.timelineEndMs,
      items: state.project.effectClips,
      getStart: (e) => e.timelineStartMs,
      getEnd: (e) => e.timelineEndMs,
      getId: (e) => e.id,
      manualLanes: state.clipLanes,
    );

    EffectClipEntity updatedClip;
    if (isLeftHandle) {
      final newStart = (clip.timelineStartMs + deltaMs).clamp(bounds.minTrimStartMs, clip.timelineEndMs - 500);
      final newDur = clip.timelineEndMs - newStart;
      updatedClip = clip.copyWith(
        timelineStartMs: newStart,
        durationMs: newDur,
      );
    } else {
      final maxAllowed = bounds.maxTrimEndMs ?? (totalDuration + 10000);
      final newEnd = (clip.timelineEndMs + deltaMs).clamp(clip.timelineStartMs + 500, maxAllowed);
      final newDur = newEnd - clip.timelineStartMs;
      updatedClip = clip.copyWith(durationMs: newDur);
    }

    final list = List<EffectClipEntity>.from(state.project.effectClips);
    list[index] = updatedClip;

    final updated = state.project.copyWith(effectClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void moveEffectClipPosition({
    required String effectId,
    required double deltaPixels,
    required double pixelsPerSecond,
  }) {
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final index = state.project.effectClips.indexWhere((e) => e.id == effectId);
    if (index == -1) return;

    final clip = state.project.effectClips[index];
    final dur = clip.durationMs;
    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeLaneBounds<EffectClipEntity>(
      clipId: effectId,
      currentStartMs: clip.timelineStartMs,
      currentDurationMs: dur,
      items: state.project.effectClips,
      getStart: (e) => e.timelineStartMs,
      getEnd: (e) => e.timelineEndMs,
      getId: (e) => e.id,
      manualLanes: state.clipLanes,
    );

    final rawStart = clip.timelineStartMs + deltaMs;
    final int newStart = rawStart.clamp(
      bounds.minStartMs,
      bounds.maxStartMs ?? (totalDuration + 10000),
    ).toInt();

    final list = List<EffectClipEntity>.from(state.project.effectClips);
    list[index] = clip.copyWith(timelineStartMs: newStart);

    final updated = state.project.copyWith(effectClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void splitEffectClipAtPlayhead(String effectId) {
    final index = state.project.effectClips.indexWhere((e) => e.id == effectId);
    if (index == -1) return;

    final clip = state.project.effectClips[index];
    final pos = state.playheadPositionMs;

    // Only split if playhead is strictly inside the clip bounds
    if (pos <= clip.timelineStartMs + 200 || pos >= clip.timelineEndMs - 200) return;

    _recordHistory();
    final firstPartDur = pos - clip.timelineStartMs;
    final secondPartDur = clip.timelineEndMs - pos;

    final firstPart = clip.copyWith(durationMs: firstPartDur);
    final secondPart = clip.copyWith(
      id: IdGenerator.generate(),
      timelineStartMs: pos,
      durationMs: secondPartDur,
    );

    final list = List<EffectClipEntity>.from(state.project.effectClips);
    list[index] = firstPart;
    list.insert(index + 1, secondPart);

    final updated = state.project.copyWith(effectClips: list);
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.effectClip,
      selectedItemId: secondPart.id,
    );
    _persistChanges();
  }

  void duplicateEffectClip(String effectId) {
    final clip = state.project.effectClips.firstWhere((e) => e.id == effectId, orElse: () => state.project.effectClips.first);
    _recordHistory();
    final dur = clip.durationMs;
    final start = clip.timelineEndMs;

    final duplicated = clip.copyWith(
      id: IdGenerator.generate(),
      timelineStartMs: start,
    );

    final updated = state.project.copyWith(
      effectClips: [...state.project.effectClips, duplicated],
      durationMs: max(state.project.durationMs, start + dur),
    );
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.effectClip,
      selectedItemId: duplicated.id,
      playheadPositionMs: start,
    );
    _persistChanges();
  }

  void deleteEffectClip(String effectId) {
    _recordHistory();
    final list = state.project.effectClips.where((e) => e.id != effectId).toList();
    final updated = state.project.copyWith(effectClips: list);
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.none,
      selectedItemId: null,
    );
    _persistChanges();
  }

  // --- Independent Timeline Animation Clip Actions ---
  void addAnimationClip({
    required ClipAnimationCombo animationType,
    int durationMs = 2000,
    String? name,
  }) {
    _recordHistory();
    final dur = durationMs > 0 ? durationMs : 2000;
    final startMs = state.playheadPositionMs;

    final newClip = AnimationClipEntity(
      id: IdGenerator.generate(),
      name: name ?? animationType.label,
      animationType: animationType,
      timelineStartMs: startMs,
      durationMs: dur,
    );

    final updated = state.project.copyWith(
      animationClips: [...state.project.animationClips, newClip],
      durationMs: max(state.project.durationMs, startMs + dur),
    );

    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.animationClip,
      selectedItemId: newClip.id,
      playheadPositionMs: startMs,
    );
    _persistChanges();
  }

  void replaceAnimationClip(String animationId, ClipAnimationCombo newAnimationType) {
    _recordHistory();
    final list = state.project.animationClips.map((a) {
      if (a.id == animationId) {
        return a.copyWith(
          animationType: newAnimationType,
          name: newAnimationType.label,
        );
      }
      return a;
    }).toList();

    final updated = state.project.copyWith(animationClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void updateAnimationClipDuration(String animationId, int newDurationMs, {bool isTrimStart = false}) {
    final index = state.project.animationClips.indexWhere((a) => a.id == animationId);
    if (index == -1) return;

    final old = state.project.animationClips[index];
    final dur = max(500, newDurationMs);

    AnimationClipEntity updatedClip;
    if (isTrimStart) {
      final oldEnd = old.timelineEndMs;
      final newStart = max(0, oldEnd - dur);
      updatedClip = old.copyWith(
        timelineStartMs: newStart,
        durationMs: oldEnd - newStart,
      );
    } else {
      updatedClip = old.copyWith(durationMs: dur);
    }

    final list = List<AnimationClipEntity>.from(state.project.animationClips);
    list[index] = updatedClip;

    final updated = state.project.copyWith(animationClips: list);
    state = state.copyWith(project: updated);
  }

  void updateAnimationDurationByDrag({
    required String animationId,
    required double deltaPixels,
    required double pixelsPerSecond,
    required bool isLeftHandle,
  }) {
    final index = state.project.animationClips.indexWhere((a) => a.id == animationId);
    if (index == -1) return;

    final clip = state.project.animationClips[index];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeTrimBounds<AnimationClipEntity>(
      clipId: animationId,
      currentStartMs: clip.timelineStartMs,
      currentEndMs: clip.timelineEndMs,
      items: state.project.animationClips,
      getStart: (a) => a.timelineStartMs,
      getEnd: (a) => a.timelineEndMs,
      getId: (a) => a.id,
      manualLanes: state.clipLanes,
    );

    AnimationClipEntity updatedClip;
    if (isLeftHandle) {
      final newStart = (clip.timelineStartMs + deltaMs).clamp(bounds.minTrimStartMs, clip.timelineEndMs - 500);
      final newDur = clip.timelineEndMs - newStart;
      updatedClip = clip.copyWith(
        timelineStartMs: newStart,
        durationMs: newDur,
      );
    } else {
      final maxAllowed = bounds.maxTrimEndMs ?? (totalDuration + 10000);
      final newEnd = (clip.timelineEndMs + deltaMs).clamp(clip.timelineStartMs + 500, maxAllowed);
      final newDur = newEnd - clip.timelineStartMs;
      updatedClip = clip.copyWith(durationMs: newDur);
    }

    final list = List<AnimationClipEntity>.from(state.project.animationClips);
    list[index] = updatedClip;

    final updated = state.project.copyWith(animationClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void moveAnimationPositionByDrag({
    required String animationId,
    required double deltaPixels,
    required double pixelsPerSecond,
  }) {
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final index = state.project.animationClips.indexWhere((a) => a.id == animationId);
    if (index == -1) return;

    final clip = state.project.animationClips[index];
    final dur = clip.durationMs;
    final totalDuration = state.project.calculatedDurationMs;
    final bounds = TimelineLayoutHelper.computeLaneBounds<AnimationClipEntity>(
      clipId: animationId,
      currentStartMs: clip.timelineStartMs,
      currentDurationMs: dur,
      items: state.project.animationClips,
      getStart: (a) => a.timelineStartMs,
      getEnd: (a) => a.timelineEndMs,
      getId: (a) => a.id,
      manualLanes: state.clipLanes,
    );

    final rawStart = clip.timelineStartMs + deltaMs;
    final int newStart = rawStart.clamp(
      bounds.minStartMs,
      bounds.maxStartMs ?? (totalDuration + 10000),
    ).toInt();

    final list = List<AnimationClipEntity>.from(state.project.animationClips);
    list[index] = clip.copyWith(timelineStartMs: newStart);

    final updated = state.project.copyWith(animationClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void splitAnimationClipAtPlayhead(String animationId) {
    final index = state.project.animationClips.indexWhere((a) => a.id == animationId);
    if (index == -1) return;

    final clip = state.project.animationClips[index];
    final splitPos = state.playheadPositionMs;

    if (splitPos <= clip.timelineStartMs + 300 || splitPos >= clip.timelineEndMs - 300) {
      return;
    }

    _recordHistory();
    final firstPartDur = splitPos - clip.timelineStartMs;
    final secondPartDur = clip.timelineEndMs - splitPos;

    final firstPart = clip.copyWith(durationMs: firstPartDur);
    final secondPart = clip.copyWith(
      id: IdGenerator.generate(),
      timelineStartMs: splitPos,
      durationMs: secondPartDur,
    );

    final list = List<AnimationClipEntity>.from(state.project.animationClips);
    list[index] = firstPart;
    list.insert(index + 1, secondPart);

    final updated = state.project.copyWith(animationClips: list);
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.animationClip,
      selectedItemId: secondPart.id,
    );
    _persistChanges();
  }

  void duplicateAnimationClip(String animationId) {
    final clip = state.project.animationClips.firstWhere((a) => a.id == animationId, orElse: () => state.project.animationClips.first);
    _recordHistory();
    final dur = clip.durationMs;
    final start = clip.timelineEndMs;

    final duplicated = clip.copyWith(
      id: IdGenerator.generate(),
      timelineStartMs: start,
    );

    final updated = state.project.copyWith(
      animationClips: [...state.project.animationClips, duplicated],
      durationMs: max(state.project.durationMs, start + dur),
    );
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.animationClip,
      selectedItemId: duplicated.id,
      playheadPositionMs: start,
    );
    _persistChanges();
  }

  void deleteAnimationClip(String animationId) {
    _recordHistory();
    final list = state.project.animationClips.where((a) => a.id != animationId).toList();
    final updated = state.project.copyWith(animationClips: list);
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.none,
      selectedItemId: null,
    );
    _persistChanges();
  }

  // --- Independent Photo Clip Management ---
  void addPhotoClip({
    required String name,
    required String mediaPath,
    int durationMs = 4000,
    bool isOverlay = false,
  }) {
    _recordHistory();
    final dur = durationMs > 0 ? durationMs : 4000;
    int startMs;
    if (isOverlay) {
      startMs = state.playheadPositionMs;
    } else {
      final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
      startMs = mainClips.isEmpty ? 0 : mainClips.last.timelineEndMs;
    }

    final activeOverlaysCount = state.activeOverlayClips.length;
    final photoClip = VideoClipEntity(
      id: IdGenerator.generate(),
      mediaPath: mediaPath,
      name: name,
      sourceDurationMs: dur,
      timelineStartMs: startMs,
      timelineEndMs: startMs + dur,
      trimStartMs: 0,
      trimEndMs: dur,
      isOverlay: isOverlay,
      zoomScale: isOverlay ? 0.6 : 1.0,
      positionX: isOverlay && activeOverlaysCount > 0 ? (activeOverlaysCount * 25.0) : 0.0,
      positionY: isOverlay && activeOverlaysCount > 0 ? (activeOverlaysCount * 25.0) : 0.0,
    );

    final updated = state.project.copyWith(
      videoClips: [...state.project.videoClips, photoClip],
      durationMs: max(state.project.durationMs, startMs + dur),
    );

    state = state.copyWith(
      project: updated,
      selectionType: isOverlay ? SelectionType.overlayClip : SelectionType.videoClip,
      selectedItemId: photoClip.id,
      playheadPositionMs: startMs,
    );
    _persistChanges();
  }

  // --- Independent Clip Replacement Operations ---
  void replaceVideoClip({
    required String clipId,
    required String newMediaPath,
    required String newName,
    int? newSourceDurationMs,
  }) {
    _recordHistory();
    final index = state.project.videoClips.indexWhere((c) => c.id == clipId);
    if (index == -1) return;

    final oldClip = state.project.videoClips[index];
    final srcDur = newSourceDurationMs ?? oldClip.sourceDurationMs;
    final trimEnd = min(oldClip.trimEndMs, srcDur);

    final replacedClip = oldClip.copyWith(
      mediaPath: newMediaPath,
      name: newName,
      sourceDurationMs: srcDur,
      trimEndMs: trimEnd,
    );

    final list = List<VideoClipEntity>.from(state.project.videoClips);
    list[index] = replacedClip;

    final updated = state.project.copyWith(videoClips: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  void replaceAudioClip({
    required String audioId,
    required String newAudioPath,
    required String newTitle,
    int? newDurationMs,
  }) {
    _recordHistory();
    final index = state.project.audioClips.indexWhere((a) => a.id == audioId);
    if (index == -1) return;

    final old = state.project.audioClips[index];
    final dur = newDurationMs ?? old.effectiveDurationMs;

    final replaced = old.copyWith(
      mediaPath: newAudioPath,
      title: newTitle,
      trimEndMs: dur,
    );

    final list = List<AudioClipEntity>.from(state.project.audioClips);
    list[index] = replaced;

    final updated = state.project.copyWith(audioClips: list);
    state = state.copyWith(project: updated);
    _syncAudio();
    _persistChanges();
  }

  void replaceSticker({
    required String stickerId,
    required String newAssetPath,
  }) {
    _recordHistory();
    final list = state.project.stickerOverlays.map((s) {
      if (s.id == stickerId) {
        return s.copyWith(assetEmojiOrPath: newAssetPath);
      }
      return s;
    }).toList();

    final updated = state.project.copyWith(stickerOverlays: list);
    state = state.copyWith(project: updated);
    _persistChanges();
  }

  Future<void> saveDraft() async {
    final now = DateTime.now();
    final projectWithPlayhead = state.project.copyWith(
      lastPlayheadPositionMs: state.playheadPositionMs,
      updatedAt: now,
    );
    state = state.copyWith(project: projectWithPlayhead);
    try {
      if (ref != null) {
        await ref!.read(saveProjectUseCaseProvider)(projectWithPlayhead);
        ref!.read(projectsNotifierProvider.notifier).updateProject(projectWithPlayhead);
      }
    } catch (_) {}
  }

  void _persistChanges() {
    saveDraft();
  }

  @override
  void dispose() {
    _stopPlaybackTimer();
    super.dispose();
  }
}

final editorControllerProvider =
    StateNotifierProvider.autoDispose.family<EditorController, TimelineState, ProjectEntity>(
  (ref, project) => EditorController(ref: ref, project: project),
);
