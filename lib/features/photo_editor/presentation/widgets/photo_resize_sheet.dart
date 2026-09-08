import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoResizeSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final PhotoEditorController controller;

  const PhotoResizeSheet({
    super.key,
    required this.project,
    required this.controller,
  });

  @override
  State<PhotoResizeSheet> createState() => _PhotoResizeSheetState();
}

class _PhotoResizeSheetState extends State<PhotoResizeSheet> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  bool _lockAspectRatio = true;
  double _aspectRatioValue = 1.0;

  @override
  void initState() {
    super.initState();
    final initialW = widget.project.exportWidth ?? 1920;
    final initialH = widget.project.exportHeight ?? 1080;
    _aspectRatioValue = initialW / initialH;

    _widthController = TextEditingController(text: initialW.toString());
    _heightController = TextEditingController(text: initialH.toString());
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onWidthChanged(String val) {
    if (!_lockAspectRatio) return;
    final w = int.tryParse(val);
    if (w != null && w > 0 && _aspectRatioValue > 0) {
      final h = (w / _aspectRatioValue).round();
      _heightController.text = h.toString();
    }
  }

  void _onHeightChanged(String val) {
    if (!_lockAspectRatio) return;
    final h = int.tryParse(val);
    if (h != null && h > 0 && _aspectRatioValue > 0) {
      final w = (h * _aspectRatioValue).round();
      _widthController.text = w.toString();
    }
  }

  void _applyPreset(int w, int h) {
    setState(() {
      _widthController.text = w.toString();
      _heightController.text = h.toString();
      _aspectRatioValue = w / h;
    });
  }

  void _submit() {
    final w = int.tryParse(_widthController.text) ?? 1920;
    final h = int.tryParse(_heightController.text) ?? 1080;
    widget.controller.setCustomCanvasDimensions(w, h);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Canvas resolution set to ${w}x$h px')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.aspect_ratio, color: AppColors.primaryLight, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Resize Dimensions',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dimension Input Fields
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WIDTH (PX)', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _widthController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        onChanged: _onWidthChanged,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E212E),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2C3042))),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _lockAspectRatio = !_lockAspectRatio;
                        final w = int.tryParse(_widthController.text) ?? 1920;
                        final h = int.tryParse(_heightController.text) ?? 1080;
                        if (h > 0) _aspectRatioValue = w / h;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _lockAspectRatio ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFF1E212E),
                        shape: BoxShape.circle,
                        border: Border.all(color: _lockAspectRatio ? AppColors.primary : const Color(0xFF2C3042)),
                      ),
                      child: Icon(
                        _lockAspectRatio ? Icons.lock : Icons.lock_open,
                        size: 18,
                        color: _lockAspectRatio ? AppColors.primaryLight : Colors.white54,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HEIGHT (PX)', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        onChanged: _onHeightChanged,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E212E),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2C3042))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Resolution Presets
            Text('STANDARD RESOLUTION PRESETS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildPresetChip('4K UHD', 3840, 2160),
                  _buildPresetChip('2K QHD', 2560, 1440),
                  _buildPresetChip('1080p FHD', 1920, 1080),
                  _buildPresetChip('720p HD', 1280, 720),
                  _buildPresetChip('1:1 Square', 1080, 1080),
                  _buildPresetChip('4:5 Portrait', 1080, 1350),
                  _buildPresetChip('9:16 Story', 1080, 1920),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Resize Dimensions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int w, int h) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text('$label (${w}x$h)'),
        backgroundColor: const Color(0xFF1E212E),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF2C3042)),
        ),
        onPressed: () => _applyPreset(w, h),
      ),
    );
  }
}
