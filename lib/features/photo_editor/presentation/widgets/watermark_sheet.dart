import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../../domain/entities/watermark_entity.dart';
import '../providers/photo_editor_controller.dart';

class WatermarkSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final PhotoEditorController controller;

  const WatermarkSheet({
    super.key,
    required this.project,
    required this.controller,
  });

  @override
  State<WatermarkSheet> createState() => _WatermarkSheetState();
}

class _WatermarkSheetState extends State<WatermarkSheet> {
  late bool _isEnabled;
  late TextEditingController _textController;
  late WatermarkPosition _position;
  late double _opacity;
  late double _scale;

  @override
  void initState() {
    super.initState();
    final wm = widget.project.watermark;
    _isEnabled = wm.isEnabled;
    _textController = TextEditingController(text: wm.text);
    _position = wm.position;
    _opacity = wm.opacity;
    _scale = wm.scale;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _apply() {
    widget.controller.updateWatermark(
      widget.project.watermark.copyWith(
        isEnabled: _isEnabled,
        text: _textController.text.trim().isEmpty ? 'LOOMA' : _textController.text.trim(),
        position: _position,
        opacity: _opacity,
        scale: _scale,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Watermark & Branding', style: AppTypography.titleMedium),
              Switch(
                value: _isEnabled,
                activeThumbColor: AppColors.accent,
                onChanged: (val) => setState(() => _isEnabled = val),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isEnabled) ...[
            // Text Input
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter brand watermark text...',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Position Selectors
            Text('POSITION', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: WatermarkPosition.values.map((pos) {
                  final isSelected = _position == pos;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(pos.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _position = pos),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Opacity Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('OPACITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                Text('${(_opacity * 100).round()}%', style: AppTypography.labelSmall),
              ],
            ),
            Slider(
              value: _opacity,
              min: 0.2,
              max: 1.0,
              activeColor: AppColors.primaryLight,
              onChanged: (val) => setState(() => _opacity = val),
            ),

            // Scale Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SCALE', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                Text('${(_scale * 100).round()}%', style: AppTypography.labelSmall),
              ],
            ),
            Slider(
              value: _scale,
              min: 0.5,
              max: 2.0,
              activeColor: AppColors.primaryLight,
              onChanged: (val) => setState(() => _scale = val),
            ),
            const SizedBox(height: 16),
          ],

          // Save Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(_isEnabled ? 'Save Watermark' : 'Disable Watermark'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _apply,
            ),
          ),
        ],
      ),
    );
  }
}
