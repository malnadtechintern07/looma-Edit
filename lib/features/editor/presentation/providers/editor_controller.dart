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

  void setClipFilter(String clipId, FilterType filter) {
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(filterType: filter);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
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
        return c.copyWith(
          zoomScale: zoomScale?.clamp(0.1, 5.0),
          positionX: positionX,
          positionY: positionY,
          rotationDegrees: rotationDegrees,
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
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(opacity: opacity.clamp(0.0, 1.0));
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
    _recordHistory();
    final clips = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(chromaKey: chromaKey);
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: clips);
    state = state.copyWith(project: updated);
    _persistChanges();
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
  void addKeyframeAtPlayhead(String clipId) {
    final clip = state.project.videoClips.firstWhere((c) => c.id == clipId, orElse: () => state.project.videoClips.first);
    final offsetInClip = (state.playheadPositionMs - clip.timelineStartMs).clamp(0, clip.effectiveDurationMs);

    _recordHistory();
    final newKeyframe = KeyframeEntity(
      id: IdGenerator.generate(),
      timestampMs: offsetInClip,
      posX: clip.positionX,
      posY: clip.positionY,
      scale: clip.zoomScale,
      rotation: clip.rotationDegrees,
      opacity: clip.opacity,
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
    final clip = state.project.videoClips.firstWhere((c) => c.id == clipId, orElse: () => state.project.videoClips.first);
    if (clip.keyframes.isEmpty) return;
    final currentOffset = state.playheadPositionMs - clip.timelineStartMs;
    final next = clip.keyframes.firstWhere(
      (k) => k.timestampMs > currentOffset + 30,
      orElse: () => clip.keyframes.last,
    );
    seekTo(clip.timelineStartMs + next.timestampMs);
  }

  void jumpToPrevKeyframe(String clipId) {
    final clip = state.project.videoClips.firstWhere((c) => c.id == clipId, orElse: () => state.project.videoClips.first);
    if (clip.keyframes.isEmpty) return;
    final currentOffset = state.playheadPositionMs - clip.timelineStartMs;
    final prevList = clip.keyframes.where((k) => k.timestampMs < currentOffset - 30).toList();
    if (prevList.isNotEmpty) {
      seekTo(clip.timelineStartMs + prevList.last.timestampMs);
    } else {
      seekTo(clip.timelineStartMs + clip.keyframes.first.timestampMs);
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

  // --- Duplicate Video Clip ---
  void duplicateVideoClip(String clipId) {
    final clip = state.project.videoClips.firstWhere((c) => c.id == clipId, orElse: () => state.project.videoClips.first);
    _recordHistory();

    final duplicated = clip.copyWith(
      id: IdGenerator.generate(),
      name: '${clip.name} (Copy)',
      timelineStartMs: clip.timelineEndMs,
      timelineEndMs: clip.timelineEndMs + clip.effectiveDurationMs,
    );

    final index = state.project.videoClips.indexWhere((c) => c.id == clipId);
    final clips = List<VideoClipEntity>.from(state.project.videoClips);
    clips.insert(index + 1, duplicated);

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
    final startMs = state.playheadPositionMs;
    final effectiveDuration = durationMs > 0 ? durationMs : 4000;

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
    );

    final updated = state.project.copyWith(
      videoClips: [...state.project.videoClips, overlayClip],
    );

    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.overlayClip,
      selectedItemId: overlayClip.id,
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
    final startMs = state.playheadPositionMs;
    final endMs = startMs + durationMs;

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
    );

    state = state.copyWith(project: updated, selectionType: SelectionType.subtitle, selectedItemId: sub.id);
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
    final deltaMs = ((_dragAccumulatorPixels / pixelsPerSecond) * 1000).truncate();
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
      // --- Video: Non-destructive trim within original video bounds ---
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
        // Trimming right edge cannot exceed the physical video's source duration
        final maxDur = max(clip.sourceDurationMs, clip.trimEndMs);
        final newTrimEnd = (clip.trimEndMs + sourceDeltaMs).clamp(clip.trimStartMs + minDurationMs, maxDur);
        final newTrimmedSource = newTrimEnd - clip.trimStartMs;
        final newEffectiveDur = (newTrimmedSource / clip.speed).round();

        // Left edge stays anchored, right edge moves with user's finger
        final newTimelineStart = clip.timelineStartMs;
        final newTimelineEnd = clip.timelineStartMs + newEffectiveDur;

        updatedClips[clipIndex] = clip.copyWith(
          trimEndMs: newTrimEnd,
          timelineStartMs: newTimelineStart,
          timelineEndMs: newTimelineEnd,
        );
      }
    }

    final targetClip = updatedClips[clipIndex];
    final activeTrimPosMs = isLeftHandle ? targetClip.timelineStartMs : targetClip.timelineEndMs;

    if (clip.isOverlay) {
      // Overlay clips are completely independent floating clips
      final updatedProject = state.project.copyWith(videoClips: updatedClips);
      state = state.copyWith(
        project: updatedProject,
        playheadPositionMs: activeTrimPosMs,
      );
    } else {
      // Main track clips: when dragging right handle, subsequent clips ripple smoothly
      if (!isLeftHandle) {
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
      final newStart = max(0, clip.timelineStartMs + deltaMs);
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

  void syncClipRealDuration(String clipId, int realDurationMs) {
    if (realDurationMs <= 0) return;
    final clipIndex = state.project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return;

    final clip = state.project.videoClips[clipIndex];
    if (clip.isPhoto) return;
    // If real duration differs from the recorded source duration
    if (clip.sourceDurationMs != realDurationMs) {
      final wasFullClip = clip.trimEndMs >= clip.sourceDurationMs || clip.trimEndMs == 5000 || clip.trimEndMs == 6000;
      final newTrimEnd = wasFullClip ? realDurationMs : min(clip.trimEndMs, realDurationMs);

      final List<VideoClipEntity> updatedClips = List.from(state.project.videoClips);
      updatedClips[clipIndex] = clip.copyWith(
        sourceDurationMs: realDurationMs,
        trimEndMs: newTrimEnd,
      );

      // Re-align all clips sequentially along timeline
      int currentOffset = 0;
      final alignedClips = <VideoClipEntity>[];
      for (final c in updatedClips) {
        final dur = c.effectiveDurationMs;
        alignedClips.add(c.copyWith(
          timelineStartMs: currentOffset,
          timelineEndMs: currentOffset + dur,
        ));
        currentOffset += dur;
      }

      final updatedProject = state.project.copyWith(
        videoClips: alignedClips,
        durationMs: currentOffset,
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
    int startOffset = 0;
    if (state.project.videoClips.isNotEmpty) {
      startOffset = state.project.videoClips.last.timelineEndMs;
    }

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
    final updated = state.project.copyWith(
      audioClips: [...state.project.audioClips, clip],
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

    final duplicated = clip.copyWith(
      id: IdGenerator.generate(),
      title: '${clip.title} (Copy)',
      timelineStartMs: clip.timelineEndMs,
      timelineEndMs: clip.timelineEndMs + clip.effectiveDurationMs,
    );

    final updated = state.project.copyWith(audioClips: [...state.project.audioClips, duplicated]);
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

    final List<AudioClipEntity> updatedList = List.from(state.project.audioClips);

    if (isLeftHandle) {
      final newTrimStart = (clip.trimStartMs + deltaMs).clamp(0, clip.trimEndMs - 500);
      final shift = newTrimStart - clip.trimStartMs;
      final newTimelineStart = clip.timelineStartMs + shift;
      updatedList[index] = clip.copyWith(
        trimStartMs: newTrimStart,
        timelineStartMs: newTimelineStart,
      );
    } else {
      final newTrimEnd = max(clip.trimStartMs + 500, clip.trimEndMs + deltaMs);
      final newTimelineEnd = clip.timelineStartMs + (newTrimEnd - clip.trimStartMs);
      updatedList[index] = clip.copyWith(
        trimEndMs: newTrimEnd,
        timelineEndMs: newTimelineEnd,
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
    final newStart = max(0, clip.timelineStartMs + deltaMs);
    final newEnd = newStart + dur;

    final List<AudioClipEntity> updatedList = List.from(state.project.audioClips);
    updatedList[index] = clip.copyWith(
      timelineStartMs: newStart,
      timelineEndMs: newEnd,
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
    final startMs = state.playheadPositionMs;
    final endMs = (startMs + 4000).clamp(0, state.project.calculatedDurationMs);

    final newText = TextOverlayEntity(
      id: IdGenerator.generate(),
      text: text,
      fontFamily: fontFamily,
      fontSize: fontSize,
      colorHex: colorHex,
      backgroundColorHex: backgroundColorHex,
      outlineColorHex: outlineColorHex,
      timelineStartMs: startMs,
      timelineEndMs: endMs > startMs ? endMs : startMs + 3000,
      animationType: animationType,
    );

    final updated = state.project.copyWith(
      textOverlays: [...state.project.textOverlays, newText],
    );
    state = state.copyWith(project: updated, selectionType: SelectionType.textOverlay, selectedItemId: newText.id);
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
    final List<TextOverlayEntity> updatedList = List.from(state.project.textOverlays);

    if (isLeftHandle) {
      final newStart = (item.timelineStartMs + deltaMs).clamp(0, item.timelineEndMs - 500);
      updatedList[textIndex] = item.copyWith(timelineStartMs: newStart);
    } else {
      final newEnd = (item.timelineEndMs + deltaMs).clamp(item.timelineStartMs + 500, totalDuration + 5000);
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
    final int newStart = (item.timelineStartMs + deltaMs).clamp(0, max(0, totalDuration - 500)).toInt();
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

    final duplicated = text.copyWith(
      id: IdGenerator.generate(),
      text: '${text.text} (Copy)',
      posY: (text.posY + 0.08).clamp(0.1, 0.9),
      timelineStartMs: text.timelineStartMs + 500,
      timelineEndMs: text.timelineEndMs + 500,
    );

    final updated = state.project.copyWith(textOverlays: [...state.project.textOverlays, duplicated]);
    state = state.copyWith(project: updated, selectionType: SelectionType.textOverlay, selectedItemId: duplicated.id);
    _persistChanges();
  }

  // --- Sticker Overlay Actions ---
  void addStickerOverlay({
    required String stickerKey,
    required String stickerName,
    required String assetEmojiOrPath,
  }) {
    _recordHistory();
    final startMs = state.playheadPositionMs;
    final endMs = (startMs + 3500).clamp(0, state.project.calculatedDurationMs);

    final sticker = StickerOverlayEntity(
      id: IdGenerator.generate(),
      stickerKey: stickerKey,
      stickerName: stickerName,
      assetEmojiOrPath: assetEmojiOrPath,
      timelineStartMs: startMs,
      timelineEndMs: endMs > startMs ? endMs : startMs + 3000,
    );

    final updated = state.project.copyWith(
      stickerOverlays: [...state.project.stickerOverlays, sticker],
    );
    state = state.copyWith(project: updated, selectionType: SelectionType.stickerOverlay, selectedItemId: sticker.id);
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

    final List<StickerOverlayEntity> updatedList = List.from(state.project.stickerOverlays);
    if (isLeftHandle) {
      final newStart = (item.timelineStartMs + deltaMs).clamp(0, item.timelineEndMs - 500);
      updatedList[index] = item.copyWith(timelineStartMs: newStart);
    } else {
      final newEnd = max(item.timelineStartMs + 500, item.timelineEndMs + deltaMs);
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
    final newStart = max(0, item.timelineStartMs + deltaMs);
    final newEnd = newStart + dur;

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

    final duplicated = sticker.copyWith(
      id: IdGenerator.generate(),
      stickerName: '${sticker.stickerName} (Copy)',
      posY: (sticker.posY + 0.08).clamp(0.1, 0.9),
      timelineStartMs: sticker.timelineStartMs + 500,
      timelineEndMs: sticker.timelineEndMs + 500,
    );

    final updated = state.project.copyWith(stickerOverlays: [...state.project.stickerOverlays, duplicated]);
    state = state.copyWith(project: updated, selectionType: SelectionType.stickerOverlay, selectedItemId: duplicated.id);
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

    final List<SubtitleEntity> updatedList = List.from(state.project.subtitles);
    if (isLeftHandle) {
      final newStart = (item.timelineStartMs + deltaMs).clamp(0, item.timelineEndMs - 500);
      updatedList[index] = item.copyWith(timelineStartMs: newStart);
    } else {
      final newEnd = max(item.timelineStartMs + 500, item.timelineEndMs + deltaMs);
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
    final newStart = max(0, item.timelineStartMs + deltaMs);
    final newEnd = newStart + dur;

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
    final start = startMs ?? state.playheadPositionMs;
    final newClip = EffectClipEntity(
      id: IdGenerator.generate(),
      effectType: effectType,
      timelineStartMs: start,
      durationMs: durationMs > 0 ? durationMs : 3000,
      intensity: intensity,
    );

    final updated = state.project.copyWith(
      effectClips: [...state.project.effectClips, newClip],
    );

    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.effectClip,
      selectedItemId: newClip.id,
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

    EffectClipEntity updatedClip;
    if (isLeftHandle) {
      final newStart = max(0, clip.timelineStartMs + deltaMs);
      final newDur = max(500, clip.durationMs - deltaMs);
      updatedClip = clip.copyWith(
        timelineStartMs: newStart,
        durationMs: newDur,
      );
    } else {
      final newDur = max(500, clip.durationMs + deltaMs);
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
    final newStart = max(0, clip.timelineStartMs + deltaMs);

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

    final duplicated = clip.copyWith(
      id: IdGenerator.generate(),
      timelineStartMs: clip.timelineEndMs,
    );

    final updated = state.project.copyWith(effectClips: [...state.project.effectClips, duplicated]);
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.effectClip,
      selectedItemId: duplicated.id,
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
    final startMs = state.playheadPositionMs;
    final dur = durationMs > 0 ? durationMs : 2000;

    final newClip = AnimationClipEntity(
      id: IdGenerator.generate(),
      name: name ?? animationType.label,
      animationType: animationType,
      timelineStartMs: startMs,
      durationMs: dur,
    );

    final updated = state.project.copyWith(
      animationClips: [...state.project.animationClips, newClip],
    );

    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.animationClip,
      selectedItemId: newClip.id,
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

    AnimationClipEntity updatedClip;
    if (isLeftHandle) {
      final newStart = max(0, clip.timelineStartMs + deltaMs);
      final newDur = max(500, clip.durationMs - deltaMs);
      updatedClip = clip.copyWith(
        timelineStartMs: newStart,
        durationMs: newDur,
      );
    } else {
      final newDur = max(500, clip.durationMs + deltaMs);
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
    final newStart = max(0, clip.timelineStartMs + deltaMs);

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

    final duplicated = clip.copyWith(
      id: IdGenerator.generate(),
      timelineStartMs: clip.timelineEndMs,
    );

    final updated = state.project.copyWith(animationClips: [...state.project.animationClips, duplicated]);
    state = state.copyWith(
      project: updated,
      selectionType: SelectionType.animationClip,
      selectedItemId: duplicated.id,
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
    final startMs = isOverlay ? state.playheadPositionMs : state.project.calculatedDurationMs;
    final dur = durationMs > 0 ? durationMs : 4000;

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
    );

    final updated = state.project.copyWith(
      videoClips: [...state.project.videoClips, photoClip],
    );

    state = state.copyWith(
      project: updated,
      selectionType: isOverlay ? SelectionType.overlayClip : SelectionType.videoClip,
      selectedItemId: photoClip.id,
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
    final projectWithPlayhead = state.project.copyWith(
      lastPlayheadPositionMs: state.playheadPositionMs,
      updatedAt: DateTime.now(),
    );
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
