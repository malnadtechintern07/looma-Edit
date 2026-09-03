import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/subtitle_entity.dart';

class CaptionEditorSheet extends StatefulWidget {
  final SubtitleEntity? initialSubtitle;
  final ValueChanged<String> onSaveSubtitle;
  final VoidCallback? onDeleteSubtitle;

  const CaptionEditorSheet({
    super.key,
    this.initialSubtitle,
    required this.onSaveSubtitle,
    this.onDeleteSubtitle,
  });

  @override
  State<CaptionEditorSheet> createState() => _CaptionEditorSheetState();
}

class _CaptionEditorSheetState extends State<CaptionEditorSheet> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialSubtitle?.text ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.subtitles, color: AppColors.textTrack, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.initialSubtitle != null ? 'Edit Subtitle' : 'Add Subtitle / Caption',
                      style: AppTypography.titleMedium,
                    ),
                  ],
                ),
                if (widget.onDeleteSubtitle != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () {
                      widget.onDeleteSubtitle!();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _textController,
              autofocus: true,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Type subtitle text here...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.textTrack, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textTrack,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final text = _textController.text.trim();
                    if (text.isNotEmpty) {
                      widget.onSaveSubtitle(text);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save Subtitle', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
