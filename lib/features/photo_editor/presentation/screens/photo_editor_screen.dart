import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../media_picker/presentation/widgets/media_picker_modal.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';
import '../widgets/photo_adjust_sheet.dart';
import '../widgets/photo_canvas.dart';
import '../widgets/photo_collage_sheet.dart';
import '../widgets/photo_draw_sheet.dart';
import '../widgets/photo_export_dialog.dart';
import '../widgets/photo_filter_sheet.dart';
import '../widgets/photo_layout_sheet.dart';
import '../widgets/photo_sticker_sheet.dart';
import '../widgets/photo_text_sheet.dart';
import '../widgets/watermark_sheet.dart';

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

  void _openMediaPicker(PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0C0D12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MediaPickerModal(
        title: 'Select Photos for Collage',
        actionLabel: 'Add to Photo Editor',
        onMediaSelected: (mediaList) {
          for (final item in mediaList) {
            controller.addPhotoFrame(item.path);
          }
        },
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

  void _openTextSheet(PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PhotoTextSheet(controller: controller),
    );
  }

  void _openStickerSheet(PhotoEditorController controller) {
    showModalBottomSheet(
      context: context,
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
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(proj.title, style: AppTypography.titleMedium),
        actions: [
          IconButton(
            icon: Icon(Icons.undo, color: state.canUndo ? Colors.white : Colors.white24),
            onPressed: state.canUndo ? () => controller.undo() : null,
          ),
          IconButton(
            icon: Icon(Icons.redo, color: state.canRedo ? Colors.white : Colors.white24),
            onPressed: state.canRedo ? () => controller.redo() : null,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _openExportDialog(proj),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Interactive Canvas Viewport
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PhotoCanvas(
                boundaryKey: _canvasBoundaryKey,
                project: proj,
                state: state,
                controller: controller,
              ),
            ),
          ),

          // Bottom Action Toolbar (Import, Layout, Collage, Adjust, Filters, Text, Stickers, Watermark, Draw)
          Container(
            height: 75,
            color: AppColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildActionButton(
                  icon: Icons.add_a_photo,
                  label: 'Import',
                  onTap: () => _openMediaPicker(controller),
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
                  icon: Icons.text_fields,
                  label: 'Text',
                  onTap: () => _openTextSheet(controller),
                ),
                _buildActionButton(
                  icon: Icons.emoji_emotions,
                  label: 'Stickers',
                  onTap: () => _openStickerSheet(controller),
                ),
                _buildActionButton(
                  icon: Icons.verified,
                  label: 'Watermark',
                  onTap: () => _openWatermarkSheet(proj, controller),
                ),
                _buildActionButton(
                  icon: Icons.brush,
                  label: 'Draw',
                  isActive: state.isDrawMode,
                  onTap: () => _openDrawSheet(state, controller),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 62,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.primaryLight : AppColors.surfaceBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? AppColors.accent : Colors.white70, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 9,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
