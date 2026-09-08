import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../../domain/entities/photo_text_overlay_entity.dart';
import '../providers/photo_editor_controller.dart';
import '../widgets/photo_adjust_sheet.dart';
import '../widgets/photo_canvas.dart';
import '../widgets/photo_collage_sheet.dart';
import '../widgets/photo_crop_sheet.dart';
import '../widgets/photo_curves_sheet.dart';
import '../widgets/photo_draw_sheet.dart';
import '../widgets/photo_export_dialog.dart';
import '../widgets/photo_filter_sheet.dart';
import '../widgets/photo_hsl_sheet.dart';
import '../widgets/photo_layout_sheet.dart';
import '../widgets/photo_resize_sheet.dart';
import '../widgets/photo_sticker_sheet.dart';
import '../widgets/photo_text_sheet.dart';
import '../widgets/watermark_sheet.dart';
import '../widgets/photo_auto_enhance_sheet.dart';
import '../widgets/photo_autocut_sheet.dart';
import '../widgets/photo_remove_bg_sheet.dart';
import '../widgets/photo_retouch_sheet.dart';

class PhotoEditorScreen extends ConsumerStatefulWidget {
  final PhotoProjectEntity project;

  const PhotoEditorScreen({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends ConsumerState<PhotoEditorScreen> {
  final GlobalKey _canvasBoundaryKey = GlobalKey();

  Future<void> _openMediaPicker(PhotoEditorController controller, {int? slotIndex}) async {
    final mediaList = await DeviceMediaService().pickPhotosFromDevice();
    for (int i = 0; i < mediaList.length; i++) {
      final item = mediaList[i];
      if (slotIndex != null && i == 0) {
        controller.setPhotoFrameAt(slotIndex, item.path);
      } else {
        controller.addPhotoFrame(item.path);
      }
    }
  }

  void _openAutoEnhanceSheet(PhotoProjectEntity proj, PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoAutoEnhanceSheet(
        project: proj,
        selectedFrameId: state.selectedFrameId,
        controller: controller,
      ),
    );
  }

  void _openRemoveBgSheet(PhotoProjectEntity proj, PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoRemoveBgSheet(
        project: proj,
        selectedFrameId: state.selectedFrameId,
        controller: controller,
      ),
    );
  }

  void _openAutoCutSheet(PhotoProjectEntity proj, PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoAutoCutSheet(
        project: proj,
        selectedFrameId: state.selectedFrameId,
        controller: controller,
      ),
    );
  }

  void _openRetouchSheet(PhotoProjectEntity proj, PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoRetouchSheet(
        project: proj,
        selectedFrameId: state.selectedFrameId,
        controller: controller,
      ),
    );
  }

  void _openCropSheet(PhotoProjectEntity proj, PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoCropSheet(
        project: proj,
        selectedFrameId: state.selectedFrameId,
        controller: controller,
      ),
    );
  }

  void _openResizeSheet(PhotoProjectEntity proj, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoResizeSheet(
        project: proj,
        controller: controller,
      ),
    );
  }

  void _openHslSheet(PhotoProjectEntity proj, PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoHslSheet(
        project: proj,
        selectedFrameId: state.selectedFrameId,
        controller: controller,
      ),
    );
  }

  void _openCurvesSheet(PhotoProjectEntity proj, PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoCurvesSheet(
        project: proj,
        selectedFrameId: state.selectedFrameId,
        controller: controller,
      ),
    );
  }

  void _openLayoutSheet(PhotoProjectEntity proj, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PhotoLayoutSheet(project: proj, controller: controller),
    );
  }

  void _openCollageSheet(PhotoProjectEntity proj, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PhotoCollageSheet(project: proj, controller: controller),
    );
  }

  void _openAdjustSheet(PhotoProjectEntity proj, PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoAdjustSheet(
        project: proj,
        selectedFrameId: state.selectedFrameId,
        controller: controller,
      ),
    );
  }

  void _openFilterSheet(PhotoProjectEntity proj, PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoFilterSheet(
        project: proj,
        selectedFrameId: state.selectedFrameId,
        controller: controller,
      ),
    );
  }

  void _openTextSheet(
    PhotoEditorController controller,
    PhotoEditorState state, {
    PhotoTextOverlayEntity? existingText,
  }) {
    final text = existingText ??
        (state.selectedTextId != null
            ? state.project.textOverlays
                .where((t) => t.id == state.selectedTextId)
                .firstOrNull
            : null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PhotoTextSheet(controller: controller, existingText: text),
    );
  }

  void _openStickerSheet(PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PhotoStickerSheet(controller: controller),
    );
  }

  void _openWatermarkSheet(PhotoProjectEntity proj, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WatermarkSheet(project: proj, controller: controller),
    );
  }

  void _openDrawSheet(PhotoEditorState state, PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PhotoDrawSheet(state: state, controller: controller),
    );
  }

  void _openExportDialog(PhotoProjectEntity proj) {
    showDialog(
      context: context,
      builder: (_) => PhotoExportDialog(
        boundaryKey: _canvasBoundaryKey,
        projectTitle: proj.title,
        targetWidth: proj.exportWidth,
        targetHeight: proj.exportHeight,
      ),
    );
  }

  Future<void> _saveProject(PhotoEditorController controller) async {
    await controller.saveProject();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo project saved successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photoEditorControllerProvider(widget.project));
    final controller = ref.read(photoEditorControllerProvider(widget.project).notifier);
    final proj = state.project;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          proj.title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Hold to Compare Button
          GestureDetector(
            onTapDown: (_) => controller.setComparing(true),
            onTapUp: (_) => controller.setComparing(false),
            onTapCancel: () => controller.setComparing(false),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isComparing ? AppColors.primary : const Color(0xFF1E212E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: state.isComparing ? AppColors.primaryLight : const Color(0xFF2C3042)),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isComparing ? Icons.visibility : Icons.visibility_outlined,
                    size: 14,
                    color: state.isComparing ? Colors.white : Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.isComparing ? 'Original' : 'Compare',
                    style: TextStyle(
                      color: state.isComparing ? Colors.white : Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.undo,
              color: state.canUndo ? AppColors.textPrimary : AppColors.textDisabled,
            ),
            tooltip: 'Undo',
            onPressed: state.canUndo ? () => controller.undo() : null,
          ),
          IconButton(
            icon: Icon(
              Icons.redo,
              color: state.canRedo ? AppColors.textPrimary : AppColors.textDisabled,
            ),
            tooltip: 'Redo',
            onPressed: state.canRedo ? () => controller.redo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined, color: AppColors.textPrimary),
            tooltip: 'Save Project',
            onPressed: () => _saveProject(controller),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 16, color: Colors.white),
              label: const Text(
                'Export',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _openExportDialog(proj),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Interactive Canvas Viewport (Supports Zoom & Pan)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PhotoCanvas(
                boundaryKey: _canvasBoundaryKey,
                project: proj,
                state: state,
                controller: controller,
                onImportSlot: (slotIndex) => _openMediaPicker(controller, slotIndex: slotIndex),
                onEditText: (text) => _openTextSheet(controller, state, existingText: text),
              ),
            ),
          ),

          // Categorized Bottom Action Toolbar with all professional tools
          SafeArea(
            top: false,
            bottom: true,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.surfaceBorder, width: 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.auto_awesome,
                      label: 'Enhance',
                      onTap: () => _openAutoEnhanceSheet(proj, state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.layers_clear,
                      label: 'Remove BG',
                      onTap: () => _openRemoveBgSheet(proj, state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.content_cut,
                      label: 'AutoCut',
                      onTap: () => _openAutoCutSheet(proj, state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.face_retouching_natural,
                      label: 'Retouch',
                      onTap: () => _openRetouchSheet(proj, state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.crop,
                      label: 'Crop',
                      onTap: () => _openCropSheet(proj, state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.tune,
                      label: 'Adjust',
                      onTap: () => _openAdjustSheet(proj, state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.filter_hdr,
                      label: 'Filters',
                      onTap: () => _openFilterSheet(proj, state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.brush,
                      label: 'Draw',
                      isActive: state.isDrawMode,
                      onTap: () => _openDrawSheet(state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.text_fields,
                      label: 'Text',
                      onTap: () => _openTextSheet(controller, state),
                    ),
                    _buildActionButton(
                      icon: Icons.emoji_emotions,
                      label: 'Stickers',
                      onTap: () => _openStickerSheet(controller),
                    ),
                    _buildActionButton(
                      icon: Icons.aspect_ratio,
                      label: 'Resize',
                      onTap: () => _openResizeSheet(proj, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.colorize,
                      label: 'HSL',
                      onTap: () => _openHslSheet(proj, state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.show_chart,
                      label: 'Curves',
                      onTap: () => _openCurvesSheet(proj, state, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.grid_goldenratio,
                      label: 'Layout',
                      onTap: () => _openLayoutSheet(proj, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.dashboard,
                      label: 'Collage',
                      onTap: () => _openCollageSheet(proj, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.verified,
                      label: 'Watermark',
                      onTap: () => _openWatermarkSheet(proj, controller),
                    ),
                    _buildActionButton(
                      icon: Icons.add_a_photo,
                      label: 'Import',
                      onTap: () => _openMediaPicker(controller),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 66,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.surfaceBorder,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
