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
  final bool isEraserMode;
  final String brushType; // 'pen', 'marker', 'neon'
  final Color currentBrushColor;
  final double currentBrushSize;
  final double brushOpacity;
  final bool isComparing; // Before/after preview mode
  final bool isExporting;
  final double zoomScale;

  const PhotoEditorState({
    required this.project,
    this.history = const [],
    this.redoStack = const [],
    this.selectedFrameId,
    this.selectedTextId,
    this.selectedStickerId,
    this.isDrawMode = false,
    this.isEraserMode = false,
    this.brushType = 'pen',
    this.currentBrushColor = const Color(0xFFFF0055),
    this.currentBrushSize = 5.0,
    this.brushOpacity = 1.0,
    this.isComparing = false,
    this.isExporting = false,
    this.zoomScale = 1.0,
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
    bool? isEraserMode,
    String? brushType,
    Color? currentBrushColor,
    double? currentBrushSize,
    double? brushOpacity,
    bool? isComparing,
    bool? isExporting,
    double? zoomScale,
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
      isEraserMode: isEraserMode ?? this.isEraserMode,
      brushType: brushType ?? this.brushType,
      currentBrushColor: currentBrushColor ?? this.currentBrushColor,
      currentBrushSize: currentBrushSize ?? this.currentBrushSize,
      brushOpacity: brushOpacity ?? this.brushOpacity,
      isComparing: isComparing ?? this.isComparing,
      isExporting: isExporting ?? this.isExporting,
      zoomScale: zoomScale ?? this.zoomScale,
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
      : super(PhotoEditorState(
          project: initialProject,
          selectedFrameId: initialProject.frames.isNotEmpty ? initialProject.frames.first.id : null,
        ));

  void _recordHistory() {
    final newHistory = List<PhotoProjectEntity>.from(state.history)..add(state.project);
    if (newHistory.length > 30) {
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

  void toggleEraserMode(bool enabled) {
    state = state.copyWith(isEraserMode: enabled);
  }

  void setBrushType(String type) {
    state = state.copyWith(brushType: type);
  }

  void setBrushColor(Color color) {
    state = state.copyWith(currentBrushColor: color);
  }

  void setBrushSize(double size) {
    state = state.copyWith(currentBrushSize: size);
  }

  void setBrushOpacity(double opacity) {
    state = state.copyWith(brushOpacity: opacity);
  }

  void setComparing(bool isComparing) {
    state = state.copyWith(isComparing: isComparing);
  }

  void setZoomScale(double scale) {
    state = state.copyWith(zoomScale: scale);
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

  void setCanvasStyle({
    double? gapSpacing,
    double? borderRadius,
    int? backgroundColorHex,
    String? backgroundType,
    List<int>? gradientColorsHex,
    double? blurBackgroundRadius,
  }) {
    _recordHistory();
    final updated = state.project.copyWith(
      gapSpacing: gapSpacing ?? state.project.gapSpacing,
      borderRadius: borderRadius ?? state.project.borderRadius,
      backgroundColorHex: backgroundColorHex ?? state.project.backgroundColorHex,
      backgroundType: backgroundType ?? state.project.backgroundType,
      gradientColorsHex: gradientColorsHex ?? state.project.gradientColorsHex,
      blurBackgroundRadius: blurBackgroundRadius ?? state.project.blurBackgroundRadius,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(project: updated);
    _persist();
  }

  void setCustomCanvasDimensions(int width, int height) {
    _recordHistory();
    final updated = state.project.copyWith(
      exportWidth: width,
      exportHeight: height,
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

  void setPhotoFrameAt(int slotIndex, String imagePath) {
    _recordHistory();
    final updatedFrames = List<PhotoFrameEntity>.from(state.project.frames);
    String targetId;
    if (slotIndex < updatedFrames.length) {
      targetId = updatedFrames[slotIndex].id;
      updatedFrames[slotIndex] = updatedFrames[slotIndex].copyWith(imagePath: imagePath);
    } else {
      final newFrame = PhotoFrameEntity(
        id: IdGenerator.generate(),
        imagePath: imagePath,
      );
      targetId = newFrame.id;
      updatedFrames.add(newFrame);
    }
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated, selectedFrameId: targetId);
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

  /// Update Crop rect
  void updateFrameCrop(
    String frameId, {
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
  }) {
    _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        return f.copyWith(
          cropLeft: cropLeft ?? f.cropLeft,
          cropTop: cropTop ?? f.cropTop,
          cropRight: cropRight ?? f.cropRight,
          cropBottom: cropBottom ?? f.cropBottom,
        );
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  /// Update Geometry transforms: 90 deg rotate, flip H/V, straighten, perspective tilt
  void updateFrameTransformGeometry(
    String frameId, {
    double? straighten,
    double? perspectiveX,
    double? perspectiveY,
    bool? flipHorizontal,
    bool? flipVertical,
    double? rotationDelta,
  }) {
    _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        return f.copyWith(
          straighten: straighten ?? f.straighten,
          perspectiveX: perspectiveX ?? f.perspectiveX,
          perspectiveY: perspectiveY ?? f.perspectiveY,
          flipHorizontal: flipHorizontal ?? f.flipHorizontal,
          flipVertical: flipVertical ?? f.flipVertical,
          rotation: rotationDelta != null ? (f.rotation + rotationDelta) : f.rotation,
        );
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  /// Update Light & Color Tone adjustments (continuous, real-time)
  void updateFrameAdjustments(
    String frameId, {
    double? brightness,
    double? contrast,
    double? exposure,
    double? highlights,
    double? shadows,
    double? saturation,
    double? vibrance,
    double? temperature,
    double? tint,
    double? sharpness,
    bool recordHistory = false,
  }) {
    if (recordHistory) _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        return f.copyWith(
          brightness: brightness ?? f.brightness,
          contrast: contrast ?? f.contrast,
          exposure: exposure ?? f.exposure,
          highlights: highlights ?? f.highlights,
          shadows: shadows ?? f.shadows,
          saturation: saturation ?? f.saturation,
          vibrance: vibrance ?? f.vibrance,
          temperature: temperature ?? f.temperature,
          tint: tint ?? f.tint,
          sharpness: sharpness ?? f.sharpness,
        );
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  /// Apply all Auto Enhance computed adjustments with history recording for Undo/Redo
  void applyAutoEnhanceAdjustments(
    String frameId, {
    required double brightness,
    required double contrast,
    required double exposure,
    required double highlights,
    required double shadows,
    required double saturation,
    required double vibrance,
    required double temperature,
    required double tint,
    required double sharpness,
  }) {
    _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        return f.copyWith(
          brightness: brightness,
          contrast: contrast,
          exposure: exposure,
          highlights: highlights,
          shadows: shadows,
          saturation: saturation,
          vibrance: vibrance,
          temperature: temperature,
          tint: tint,
          sharpness: sharpness,
        );
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  /// Update Blur, Vignette, Grain, Fade effects
  void updateFrameEffects(
    String frameId, {
    double? blur,
    double? vignette,
    double? grain,
    double? fade,
    bool recordHistory = false,
  }) {
    if (recordHistory) _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        return f.copyWith(
          blur: blur ?? f.blur,
          vignette: vignette ?? f.vignette,
          grain: grain ?? f.grain,
          fade: fade ?? f.fade,
        );
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  /// Update HSL adjustments for a specific color channel
  void updateFrameHsl(
    String frameId,
    String channel, {
    double? hue,
    double? sat,
    double? lum,
    bool recordHistory = false,
  }) {
    if (recordHistory) _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        final currentHsl = Map<String, Map<String, double>>.from(f.hslAdjustments);
        final channelMap = Map<String, double>.from(currentHsl[channel] ?? {'hue': 0.0, 'sat': 0.0, 'lum': 0.0});
        if (hue != null) channelMap['hue'] = hue;
        if (sat != null) channelMap['sat'] = sat;
        if (lum != null) channelMap['lum'] = lum;
        currentHsl[channel] = channelMap;
        return f.copyWith(hslAdjustments: currentHsl);
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  /// Update Tone Curves for a channel (RGB, Red, Green, Blue)
  void updateFrameCurves(
    String frameId,
    String channel, {
    double? blacks,
    double? shadows,
    double? midtones,
    double? highlights,
    double? whites,
    bool recordHistory = false,
  }) {
    if (recordHistory) _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        final currentCurves = Map<String, List<double>>.from(f.toneCurves);
        final list = List<double>.from(currentCurves[channel] ?? [0.0, 0.0, 0.0, 0.0, 0.0]);
        if (blacks != null) list[0] = blacks;
        if (shadows != null) list[1] = shadows;
        if (midtones != null) list[2] = midtones;
        if (highlights != null) list[3] = highlights;
        if (whites != null) list[4] = whites;
        currentCurves[channel] = list;
        return f.copyWith(toneCurves: currentCurves);
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  /// Reset all Light & Tone adjustments on a frame
  void resetFrameAdjustments(String frameId) {
    _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        return f.copyWith(
          brightness: 0.0,
          contrast: 1.0,
          exposure: 0.0,
          highlights: 0.0,
          shadows: 0.0,
          saturation: 1.0,
          vibrance: 0.0,
          temperature: 0.0,
          tint: 0.0,
          sharpness: 0.0,
          blur: 0.0,
          vignette: 0.0,
          grain: 0.0,
          fade: 0.0,
          hslAdjustments: const {},
          toneCurves: const {},
        );
      }
      return f;
    }).toList();
    final updated = state.project.copyWith(frames: updatedFrames, updatedAt: DateTime.now());
    state = state.copyWith(project: updated);
    _persist();
  }

  /// Reset everything (crop, transforms, adjustments, filters) on a frame
  void resetAll(String frameId) {
    _recordHistory();
    final updatedFrames = state.project.frames.map((f) {
      if (f.id == frameId) {
        return PhotoFrameEntity(
          id: f.id,
          imagePath: f.imagePath,
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

  void removeDrawingStrokeAt(int index) {
    if (index < 0 || index >= state.project.drawingStrokes.length) return;
    _recordHistory();
    final updated = List<DrawingStrokeEntity>.from(state.project.drawingStrokes)..removeAt(index);
    final proj = state.project.copyWith(drawingStrokes: updated, updatedAt: DateTime.now());
    state = state.copyWith(project: proj);
    _persist();
  }

  void eraseStrokesNear(Offset point, double radius) {
    final strokes = state.project.drawingStrokes;
    final remaining = <DrawingStrokeEntity>[];
    bool erasedAny = false;

    for (final stroke in strokes) {
      bool hit = false;
      for (final p in stroke.points) {
        if ((p - point).distance <= radius) {
          hit = true;
          break;
        }
      }
      if (hit) {
        erasedAny = true;
      } else {
        remaining.add(stroke);
      }
    }

    if (erasedAny) {
      final proj = state.project.copyWith(drawingStrokes: remaining, updatedAt: DateTime.now());
      state = state.copyWith(project: proj);
      _persist();
    }
  }

  void clearDrawingStrokes() {
    _recordHistory();
    final proj = state.project.copyWith(drawingStrokes: [], updatedAt: DateTime.now());
    state = state.copyWith(project: proj);
    _persist();
  }

  Future<void> saveProject() async {
    await _persist();
  }

  Future<void> _persist() async {
    await _repository?.savePhotoProject(state.project);
  }
}
