import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/procut_button.dart';
import '../../../media_picker/domain/entities/media_item_entity.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../domain/entities/aspect_ratio_type.dart';

class CreateProjectDialog extends StatefulWidget {
  final Function(String title, AspectRatioType aspectRatio, int fps, List<MediaItemEntity> media) onCreate;

  const CreateProjectDialog({super.key, required this.onCreate});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final TextEditingController _titleController = TextEditingController();
  AspectRatioType _selectedRatio = AspectRatioType.ratio9_16;
  int _selectedFps = 30;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _onStartEditing() async {
    final title = _titleController.text.trim();
    Navigator.of(context).pop();

    final selectedMedia = await DeviceMediaService().pickVideosFromDevice();
    if (selectedMedia.isNotEmpty) {
      widget.onCreate(title, _selectedRatio, _selectedFps, selectedMedia);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.movie_creation_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'New Project',
                        style: AppTypography.titleLarge.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title input
              Text(
                'Project Name',
                style: AppTypography.titleSmall.copyWith(color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: AppTypography.bodyLarge.copyWith(color: const Color(0xFF111827)),
                decoration: InputDecoration(
                  hintText: 'e.g. Summer Vacation Vlog',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: const Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FE),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFECEEF5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFECEEF5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Aspect Ratio Selection
              Text(
                'Canvas Aspect Ratio',
                style: AppTypography.titleSmall.copyWith(color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AspectRatioType.values.map((ratio) {
                  final isSelected = _selectedRatio == ratio;
                  return InkWell(
                    onTap: () => setState(() => _selectedRatio = ratio),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFECEEF5),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ratio.label,
                            style: AppTypography.labelLarge.copyWith(
                              color: isSelected ? Colors.white : const Color(0xFF111827),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ratio.description.split(' ').first,
                            style: AppTypography.labelSmall.copyWith(
                              color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Frame Rate
              Text(
                'Frame Rate (FPS)',
                style: AppTypography.titleSmall.copyWith(color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [24, 30, 60].map((fps) {
                  final isSelected = _selectedFps == fps;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedFps = fps),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00C2CB) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00C2CB) : const Color(0xFFECEEF5),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Text(
                            '$fps FPS',
                            style: AppTypography.labelLarge.copyWith(
                              color: isSelected ? Colors.white : const Color(0xFF111827),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF6B7280))),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ProCutButton(
                      label: 'Select Media',
                      icon: Icons.perm_media_outlined,
                      onPressed: _onStartEditing,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
