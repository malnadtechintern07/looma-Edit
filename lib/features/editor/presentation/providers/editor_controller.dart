import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../audio/domain/entities/audio_clip_entity.dart';
import '../../../audio/domain/services/audio_playback_service.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../../projects/domain/entities/project_entity.dart';
import '../../../projects/domain/entities/aspect_ratio_type.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../text_stickers/domain/entities/overlay_animation_type.dart';
import '../../../text_stickers/domain/entities/sticker_overlay_entity.dart';
import '../../../text_stickers/domain/entities/text_overlay_entity.dart';
import '../../domain/entities/timeline_state.dart';
import '../../domain/entities/transition_type.dart';
import '../../domain/entities/video_clip_entity.dart';
import '../../domain/usecases/editor_usecases.dart';

class EditorController extends StateNotifier<TimelineState> {
  final Ref ref;
  final SplitClipUseCase _splitClipUseCase = SplitClipUseCase();
  final TrimClipUseCase _trimClipUseCase = TrimClipUseCase();
  final UpdateClipSpeedUseCase _updateSpeedUseCase = UpdateClipSpeedUseCase();
  final DeleteClipUseCase _deleteClipUseCase = DeleteClipUseCase();

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  // Undo / Redo history
  final List<ProjectEntity> _undoStack = [];
  final List<ProjectEntity> _redoStack = [];

  EditorController({
    required this.ref,
    required ProjectEntity project,
  }) : super(TimelineState(project: project)) {
    _initTicker();
  }

  void _initTicker() {
    _ticker = Ticker((elapsed) {
      if (!state.isPlaying) {
        _lastTick = elapsed;
        return;
      }
      final deltaMs = (elapsed - _lastTick).inMilliseconds;
      _lastTick = elapsed;
      if (deltaMs > 0) {
        _advancePlayback(deltaMs);
      }
    });
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
      _lastTick = Duration.zero;
      _ticker?.start();
    } else {
      _ticker?.stop();
    }
    state = state.copyWith(isPlaying: nextPlaying);
    _syncAudio();
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
    final clamped = pixelsPerSec.clamp(20.0, 200.0);
    state = state.copyWith(pixelsPerSecond: clamped);
  }

  void setSelection(SelectionType type, String? id) {
    state = state.copyWith(selectionType: type, selectedItemId: id);
  }

  void _advancePlayback(int deltaMs) {
    final newPos = state.playheadPositionMs + deltaMs;
    final totalDuration = state.project.calculatedDurationMs;

    if (newPos >= totalDuration) {
      if (state.isLooping) {
        state = state.copyWith(playheadPositionMs: 0);
      } else {
        _ticker?.stop();
        state = state.copyWith(playheadPositionMs: totalDuration, isPlaying: false);
      }
    } else {
      state = state.copyWith(playheadPositionMs: newPos);
    }
    _syncAudio();
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
    final active = state.activeVideoClip;
    if (active == null) return;
    _recordHistory();

    final updatedProject = _splitClipUseCase(
      project: state.project,
      clipId: active.id,
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
  }) {
    final list = state.project.videoClips.map((c) {
      if (c.id == clipId) {
        return c.copyWith(
          zoomScale: zoomScale?.clamp(0.5, 5.0),
          positionX: positionX,
          positionY: positionY,
          rotationDegrees: rotationDegrees,
        );
      }
      return c;
    }).toList();

    final updated = state.project.copyWith(videoClips: list);
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
    if (oldIndex < 0 || oldIndex >= state.project.videoClips.length) return;
    if (newIndex < 0 || newIndex >= state.project.videoClips.length) return;
    if (oldIndex == newIndex) return;

    _recordHistory();
    final clips = List<VideoClipEntity>.from(state.project.videoClips);
    final movedClip = clips.removeAt(oldIndex);
    clips.insert(newIndex, movedClip);

    // Recalculate timelineStartMs and timelineEndMs sequentially for all clips while retaining all properties
    int currentOffset = 0;
    final updatedClips = <VideoClipEntity>[];
    for (final clip in clips) {
      final dur = clip.effectiveDurationMs;
      updatedClips.add(
        clip.copyWith(
          timelineStartMs: currentOffset,
          timelineEndMs: currentOffset + dur,
        ),
      );
      currentOffset += dur;
    }

    final updatedProject = state.project.copyWith(
      videoClips: updatedClips,
      durationMs: currentOffset,
    );

    state = state.copyWith(project: updatedProject);
    _persistChanges();
  }

  void updateClipDurationByDrag({
    required String clipId,
    required double deltaPixels,
    required double pixelsPerSecond,
    required bool isLeftHandle,
  }) {
    final clipIndex = state.project.videoClips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return;

    final clip = state.project.videoClips[clipIndex];
    final deltaMs = ((deltaPixels / pixelsPerSecond) * 1000).round();
    if (deltaMs == 0) return;

    final List<VideoClipEntity> updatedClips = List.from(state.project.videoClips);

    if (isLeftHandle) {
      final newTrimStart = (clip.trimStartMs + deltaMs).clamp(0, clip.trimEndMs - 500);
      final actualShiftMs = newTrimStart - clip.trimStartMs;
      final newTimelineStart = clip.timelineStartMs + actualShiftMs;

      updatedClips[clipIndex] = clip.copyWith(
        trimStartMs: newTrimStart,
        timelineStartMs: newTimelineStart,
      );
    } else {
      const maxSourceDur = 3600000; // Allow full duration extension up to 1 hour
      final newTrimEnd = (clip.trimEndMs + deltaMs).clamp(clip.trimStartMs + 500, maxSourceDur);
      final newTimelineEnd = clip.timelineStartMs + (newTrimEnd - clip.trimStartMs);

      updatedClips[clipIndex] = clip.copyWith(
        trimEndMs: newTrimEnd,
        timelineEndMs: newTimelineEnd,
        sourceDurationMs: max(clip.sourceDurationMs, newTrimEnd),
      );
    }

    int currentOffset = 0;
    final finalClips = <VideoClipEntity>[];
    for (final c in updatedClips) {
      final dur = c.effectiveDurationMs;
      finalClips.add(c.copyWith(
        timelineStartMs: currentOffset,
        timelineEndMs: currentOffset + dur,
      ));
      currentOffset += dur;
    }

    final updatedProject = state.project.copyWith(
      videoClips: finalClips,
      durationMs: currentOffset,
    );

    state = state.copyWith(project: updatedProject);
    _persistChanges();
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

    final newClip = VideoClipEntity(
      id: IdGenerator.generate(),
      mediaPath: mediaPath,
      name: name,
      sourceDurationMs: durationMs,
      timelineStartMs: startOffset,
      timelineEndMs: startOffset + durationMs,
      trimStartMs: 0,
      trimEndMs: durationMs,
    );

    final updated = state.project.copyWith(
      videoClips: [...state.project.videoClips, newClip],
      durationMs: startOffset + durationMs,
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
    _persistChanges();
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

  void _persistChanges() {
    ref.read(updateProjectUseCaseProvider)(state.project);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

final editorControllerProvider =
    StateNotifierProvider.autoDispose.family<EditorController, TimelineState, ProjectEntity>(
  (ref, project) => EditorController(ref: ref, project: project),
);
