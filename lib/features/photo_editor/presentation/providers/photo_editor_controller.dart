import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/id_generator.dart';
import '../../data/repositories/photo_project_repository.dart';
import '../../domain/entities/drawing_stroke_entity.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../../domain/entities/photo_sticker_overlay_entity.dart';
import '../../domain/entities/photo_text_overlay_entity.dart';
import '../../domain/entities/watermark_entity.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';

class PhotoEditorState {
  final PhotoProjectEntity project;
  final List<PhotoProjectEntity> history;
  final List<PhotoProjectEntity> redoStack;
  final String? selectedFrameId;
  final String? selectedTextId;
  final String? selectedStickerId;
  final bool isDrawMode;
  final Color currentBrushColor;
  final double currentBrushSize;
  final bool isExporting;

  const PhotoEditorState({
    required this.project,
    this.history = const [],
    this.redoStack = const [],
    this.selectedFrameId,
    this.selectedTextId,
    this.selectedStickerId,
    this.isDrawMode = false,
    this.currentBrushColor = const Color(0xFFFF0055),
    this.currentBrushSize = 5.0,
    this.isExporting = false,
  });

  bool get canUndo => history.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  PhotoEditorState copyWith({
    PhotoProjectEntity? project,
    List<PhotoProjectEntity>? history,
    List<PhotoProjectEntity>? redoStack,
    String? selectedFrameId,
    String? selectedTextId,
    String? selectedStickerId,
    bool? isDrawMode,
    Color? currentBrushColor,
    double? currentBrushSize,
    bool? isExporting,
    bool clearSelection = false,
  }) {
    return PhotoEditorState(
      project: project ?? this.project,
      history: history ?? this.history,
      redoStack: redoStack ?? this.redoStack,
      selectedFrameId: clearSelection ? null : (selectedFrameId ?? this.selectedFrameId),
      selectedTextId: clearSelection ? null : (selectedTextId ?? this.selectedTextId),
      selectedStickerId: clearSelection ? null : (selectedStickerId ?? this.selectedStickerId),
      isDrawMode: isDrawMode ?? this.isDrawMode,
      currentBrushColor: currentBrushColor ?? this.currentBrushColor,
      currentBrushSize: currentBrushSize ?? this.currentBrushSize,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

final photoEditorControllerProvider = StateNotifierProvider.family
    .autoDispose<PhotoEditorController, PhotoEditorState, PhotoProjectEntity>((ref, initialProject) {
  final repo = ref.watch(photoProjectRepositoryProvider);
  return PhotoEditorController(initialProject, repo);
});

class PhotoEditorController extends StateNotifier<PhotoEditorState> {
  final PhotoProjectRepository? _repository;

  PhotoEditorController(PhotoProjectEntity initialProject, [this._repository])
      : super(PhotoEditorState(project: initialProject));

  void _recordHistory() {
    final newHistory = List<PhotoProjectEntity>.from(state.history)..add(state.project);
    if (newHistory.length > 25) {
      newHistory.removeAt(0);
    }
    state = state.copyWith(
      history: newHistory,
      redoStack: [],
    );
  }

  void undo() {
    if (!state.canUndo) return;
    final previous = state.history.last;
    final newHistory = List<PhotoProjectEntity>.from(state.history)..removeLast();
    final newRedo = List<PhotoProjectEntity>.from(state.redoStack)..add(state.project);

    state = state.copyWith(
      project: previous,
      history: newHistory,
      redoStack: newRedo,
    );
    _persist();
  }

  void redo() {
    if (!state.canRedo) return;
    final next = state.redoStack.last;
    final newRedo = List<PhotoProjectEntity>.from(state.redoStack)..removeLast();
    final newHistory = List<PhotoProjectEntity>.from(state.history)..add(state.project);

    state = state.copyWith(
      project: next,
      history: newHistory,
      redoStack: newRedo,
    );
    _persist();
  }

  void selectFrame(String? id) {
    state = state.copyWith(
      selectedFrameId: id,
      selectedTextId: null,
      selectedStickerId: null,
    );
  }

  void selectText(String? id) {
    state = state.copyWith(
      selectedTextId: id,
      selectedFrameId: null,
      selectedStickerId: null,
    );
  }

  void selectSticker(String? id) {
    state = state.copyWith(
      selectedStickerId: id,
      selectedFrameId: null,
      selectedTextId: null,
    );
  }

  void toggleDrawMode(bool enabled) {
    state = state.copyWith(isDrawMode: enabled, clearSelection: true);
  }

  void setBrushColor(Color color) {
    state = state.copyWith(currentBrushColor: color);
  }

  void setBrushSize(double size) {
    state = state.copyWith(currentBrushSize: size);
  }

  void setAspectRatio(PhotoAspectRatio ratio) {
    _recordHistory();
    final updated = state.project.copyWith(aspectRatio: ratio, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  void setCollageLayout(CollageLayoutType layout) {
    _recordHistory();
    final updated = state.project.copyWith(collageLayout: layout, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  void setCanvasStyle({double? gapSpacing, double? borderRadius, int? backgroundColorHex}) {
    _recordHistory();
    final updated = state.project.copyWith(
      gapSpacing: gapSpacing ?? state.project.gapSpacing,
      borderRadius: borderRadius ?? state.project.borderRadius,
      backgroundColorHex: backgroundColorHex ?? state.project.backgroundColorHex,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(project: updated);
    _persist();
  }

  void addPhotoFrame(String imagePath) {
    _recordHistory();
    final newFrame = PhotoFrameEntity(
      id: IdGenerator.generate(),
      imagePath: imagePath,
    );
    final updatedFrames = List<PhotoFrameEntity>.from(state.project.frames)..add(newFrame);
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated, selectedFrameId: newFrame.id);
    _persist();
  }

  void replacePhotoFrame(String frameId, String newImagePath) {
    _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        return f.copyWith(imagePath: newImagePath);
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  void updateFrameTransform(
    String frameId, {
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
  }) {
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        return f.copyWith(
          scale: scale ?? f.scale,
          offsetX: offsetX ?? f.offsetX,
          offsetY: offsetY ?? f.offsetY,
          rotation: rotation ?? f.rotation,
        );
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  void updateFrameColorGrading(
    String frameId, {
    dynamic filterType,
    double? filterIntensity,
    double? brightness,
    double? contrast,
    double? saturation,
  }) {
    _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        final FilterType newFilter = filterType is FilterType
            ? filterType
            : (filterType != null ? FilterType.fromString(filterType.toString()) : f.filterType);
        return f.copyWith(
          filterType: newFilter,
          filterIntensity: filterIntensity ?? (newFilter == FilterType.none ? 1.0 : f.filterIntensity),
          brightness: brightness ?? f.brightness,
          contrast: contrast ?? f.contrast,
          saturation: saturation ?? f.saturation,
        );
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  void applyFilterToAllFrames(dynamic filterType, {double? filterIntensity}) {
    _recordHistory();
    final FilterType newFilter = filterType is FilterType
        ? filterType
        : (filterType != null ? FilterType.fromString(filterType.toString()) : FilterType.none);
    final updatedFrames = state.project.frames.map((f) => f.copyWith(
      filterType: newFilter,
      filterIntensity: filterIntensity ?? (newFilter == FilterType.none ? 1.0 : f.filterIntensity),
    )).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  void removeFilter(String frameId) {
    updateFrameColorGrading(frameId, filterType: FilterType.none, filterIntensity: 1.0);
  }

  void updateWatermark(WatermarkEntity watermark) {
    _recordHistory();
    final updated = state.project.copyWith(watermark: watermark, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  void addTextOverlay(PhotoTextOverlayEntity text) {
    _recordHistory();
    final updated = List<PhotoTextOverlayEntity>.from(state.project.textOverlays)..add(text);
    final proj = state.project.copyWith(textOverlays: updated, updatedAt: DateTime.now());
    state = state.copyWith(project: proj, selectedTextId: text.id);
    _persist();
  }

  void updateTextOverlay(PhotoTextOverlayEntity text) {
    final updated = state.project.textOverlays.map((t) => t.id == text.id ? text : t).toList();
    final proj = state.project.copyWith(textOverlays: updated, updatedAt: DateTime.now());
    state = state.copyWith(project: proj);
    _persist();
  }

  void removeTextOverlay(String id) {
    _recordHistory();
    final updated = state.project.textOverlays.where((t) => t.id != id).toList();
    final proj = state.project.copyWith(textOverlays: updated, updatedAt: DateTime.now());
    state = state.copyWith(project: proj, selectedTextId: null);
    _persist();
  }

  void addStickerOverlay(PhotoStickerOverlayEntity sticker) {
    _recordHistory();
    final updated = List<PhotoStickerOverlayEntity>.from(state.project.stickerOverlays)..add(sticker);
    final proj = state.project.copyWith(stickerOverlays: updated, updatedAt: DateTime.now());
    state = state.copyWith(project: proj, selectedStickerId: sticker.id);
    _persist();
  }

  void updateStickerOverlay(PhotoStickerOverlayEntity sticker) {
    final updated = state.project.stickerOverlays.map((s) => s.id == sticker.id ? sticker : s).toList();
    final proj = state.project.copyWith(stickerOverlays: updated, updatedAt: DateTime.now());
    state = state.copyWith(project: proj);
    _persist();
  }

  void removeStickerOverlay(String id) {
    _recordHistory();
    final updated = state.project.stickerOverlays.where((s) => s.id != id).toList();
    final proj = state.project.copyWith(stickerOverlays: updated, updatedAt: DateTime.now());
    state = state.copyWith(project: proj, selectedStickerId: null);
    _persist();
  }

  void addDrawingStroke(DrawingStrokeEntity stroke) {
    final updated = List<DrawingStrokeEntity>.from(state.project.drawingStrokes)..add(stroke);
    final proj = state.project.copyWith(drawingStrokes: updated, updatedAt: DateTime.now());
    state = state.copyWith(project: proj);
    _persist();
  }

  void clearDrawingStrokes() {
    _recordHistory();
    final proj = state.project.copyWith(drawingStrokes: [], updatedAt: DateTime.now());
    state = state.copyWith(project: proj);
    _persist();
  }

  Future<void> _persist() async {
    await _repository?.savePhotoProject(state.project);
  }
}
