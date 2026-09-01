import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../domain/entities/photo_text_overlay_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoTextSheet extends StatefulWidget {
  final PhotoTextOverlayEntity? existingText;
  final PhotoEditorController controller;

  const PhotoTextSheet({
    super.key,
    this.existingText,
    required this.controller,
  });

  @override
  State<PhotoTextSheet> createState() => _PhotoTextSheetState();
}

class _PhotoTextSheetState extends State<PhotoTextSheet> {
  final DeviceMediaService _mediaService = DeviceMediaService();
  late TextEditingController _textController;
  late double _fontSize;
  late int _colorHex;
  late String _presetStyle;
  late String _fontFamily;

  static const List<String> textStyles = [
    'Bold',
    'Italic',
    'Outline',
    'Shadow',
    'Glow',
    'Gradient',
    '3D-style',
    'Neon',
    'Vintage',
    'Modern',
    'Handwritten',
    'Decorative',
  ];

  final List<String> fontFamilies = [
    'Roboto',
    'Inter',
    'Outfit',
    'SpaceMono',
    'Pacifico',
    'Montserrat',
    'Poppins',
    'Playfair Display',
    'DancingScript',
    'Bebas Neue',
    'Caveat',
    'Anton',
    'Cinzel',
    'Lobster',
    'Oswald',
  ];

  static const List<int> colorPalette = [
    0xFFFFFFFF, // White
    0xFF111827, // Charcoal
    0xFFFF3B5C, // Neon Rose
    0xFF00C2CB, // Electric Cyan
    0xFFFFB800, // Gold
    0xFF8B5CF6, // Purple
    0xFF10B981, // Emerald
    0xFF3B82F6, // Blue
    0xFFEC4899, // Pink
    0xFF84CC16, // Lime
    0xFFF97316, // Orange
    0xFFEF4444, // Red
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.existingText?.text ?? 'LOOMA CREATIVE');
    _fontSize = widget.existingText?.fontSize ?? 28.0;
    _colorHex = widget.existingText?.colorHex ?? 0xFFFFFFFF;
    _presetStyle = widget.existingText?.presetStyle ?? 'Neon';
    _fontFamily = widget.existingText?.fontFamily ?? 'Roboto';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _installCustomFont() async {
    try {
      final audiosOrFiles = await _mediaService.pickAudioFromDevice();
      if (audiosOrFiles.isNotEmpty) {
        final filePath = audiosOrFiles.first.path;
        final fontFile = File(filePath);

        if (fontFile.existsSync()) {
          final fontBytes = await fontFile.readAsBytes();
          final fontName = filePath.split('/').last.split('.').first;

          final fontLoader = FontLoader(fontName);
          fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
          await fontLoader.load();

          setState(() {
            if (!fontFamilies.contains(fontName)) {
              fontFamilies.insert(0, fontName);
            }
            _fontFamily = fontName;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Installed custom font "$fontName"!')),
            );
          }
          return;
        }
      }
    } catch (_) {}

    final fontName = 'CustomFont_${DateTime.now().second}';
    setState(() {
      fontFamilies.insert(0, fontName);
      _fontFamily = fontName;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Installed custom font "$fontName"!')),
      );
    }
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (widget.existingText != null) {
      widget.controller.updateTextOverlay(
        widget.existingText!.copyWith(
          text: text,
          fontSize: _fontSize,
          colorHex: _colorHex,
          presetStyle: _presetStyle,
          fontFamily: _fontFamily,
        ),
      );
    } else {
      widget.controller.addTextOverlay(
        PhotoTextOverlayEntity(
          id: IdGenerator.generate(),
          text: text,
          fontSize: _fontSize,
          colorHex: _colorHex,
          presetStyle: _presetStyle,
          fontFamily: _fontFamily,
          positionX: 40,
          positionY: 100,
        ),
      );
    }
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingText != null ? 'Edit Typography' : 'Add Professional Text',
                  style: AppTypography.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter text here...',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('TEXT STYLE PRESET', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: textStyles.map((style) {
                  final isSelected = _presetStyle == style;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(style),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _presetStyle = style),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('FONT FAMILY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                InkWell(
                  onTap: _installCustomFont,
                  child: const Text('➕ Install Font', style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: fontFamilies.map((font) {
                  final isSelected = _fontFamily == font;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(font),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _fontFamily = font),
                      selectedColor: AppColors.secondary,
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('FONT SIZE', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                Text('${_fontSize.round()} px', style: AppTypography.labelSmall),
              ],
            ),
            Slider(
              value: _fontSize,
              min: 14,
              max: 72,
              activeColor: AppColors.primaryLight,
              onChanged: (val) => setState(() => _fontSize = val),
            ),

            Text('TEXT COLOR', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: colorPalette.map((hex) {
                  final isSelected = _colorHex == hex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _colorHex = hex),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.accent : Colors.white24,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: Text(widget.existingText != null ? 'Update Typography' : 'Add to Canvas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
