import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/procut_button.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../../media_picker/presentation/widgets/media_picker_modal.dart';
import '../../domain/entities/store_template_entity.dart';

class TemplateMediaPickerDialog extends StatefulWidget {
  final StoreTemplateEntity template;
  final Function(List<String> userSelectedMediaPaths) onConfirm;

  const TemplateMediaPickerDialog({
    super.key,
    required this.template,
    required this.onConfirm,
  });

  @override
  State<TemplateMediaPickerDialog> createState() => _TemplateMediaPickerDialogState();
}

class _TemplateMediaPickerDialogState extends State<TemplateMediaPickerDialog> {
  final DeviceMediaService _mediaService = DeviceMediaService();
  late List<String?> _selectedSlotPaths;

  @override
  void initState() {
    super.initState();
    _selectedSlotPaths = List<String?>.filled(widget.template.clipsCount, null);
    _fillWithDefaults();
  }

  void _fillWithDefaults() {
    final samples = _mediaService.getSampleStockClips();
    for (int i = 0; i < widget.template.clipsCount; i++) {
      if (_selectedSlotPaths[i] == null) {
        _selectedSlotPaths[i] = samples[i % samples.length].path;
      }
    }
  }

  Future<void> _pickSingleSlotMedia(int slotIndex) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0C0D12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => MediaPickerModal(
        title: 'Select for Slot #${slotIndex + 1}',
        actionLabel: 'Use for Slot #${slotIndex + 1}',
        onMediaSelected: (selectedList) {
          if (selectedList.isNotEmpty) {
            setState(() {
              _selectedSlotPaths[slotIndex] = selectedList.first.path;
            });
          }
        },
      ),
    );
  }

  Future<void> _pickBulkDeviceMedia() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0C0D12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => MediaPickerModal(
        title: 'Select ${widget.template.clipsCount} Media Items',
        actionLabel: 'Apply Selected Media',
        onMediaSelected: (selectedList) {
          if (selectedList.isNotEmpty) {
            setState(() {
              for (int i = 0; i < widget.template.clipsCount; i++) {
                if (i < selectedList.length) {
                  _selectedSlotPaths[i] = selectedList[i].path;
                }
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildSlotThumbnail(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    } else if (File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(child: Icon(Icons.video_library, color: Colors.white54)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startColorInt = int.tryParse(widget.template.previewGradientStart) ?? 0xFF8B5CF6;
    final endColorInt = int.tryParse(widget.template.previewGradientEnd) ?? 0xFF06B6D4;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Header Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [Color(startColorInt), Color(endColorInt)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.template.title,
                          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.template.clipsCount} Media Slots • ${widget.template.aspectRatio.label}',
                          style: AppTypography.labelSmall.copyWith(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bulk Pick Action CTA - Overflow-safe Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Template Slots (${widget.template.clipsCount})',
                    style: AppTypography.titleSmall.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _pickBulkDeviceMedia,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library, size: 14, color: AppColors.primaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'Pick Gallery Media',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Slots Grid - Flexible viewport prevents 127px overflow
            Expanded(
              child: GridView.builder(
                itemCount: widget.template.clipsCount,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final path = _selectedSlotPaths[index] ?? '';
                  final isCustom = !path.startsWith('assets/');

                  return InkWell(
                    onTap: () => _pickSingleSlotMedia(index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCustom ? AppColors.primary : AppColors.surfaceBorder,
                          width: isCustom ? 2.0 : 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildSlotThumbnail(path),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.1),
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Slot #${index + 1}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    path.split('/').last,
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 8,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 9),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Submit CTA
            ProCutButton(
              label: 'Create Video with Template',
              icon: Icons.movie_creation,
              isFullWidth: true,
              onPressed: () {
                final validPaths = _selectedSlotPaths.whereType<String>().toList();
                widget.onConfirm(validPaths);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
