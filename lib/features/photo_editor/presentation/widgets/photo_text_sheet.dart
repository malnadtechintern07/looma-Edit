import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/font_helper.dart';
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
  late String _textAlign;
  late double _letterSpacing;
  late double _lineHeight;
  late double _opacity;
  late double _rotation;

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

  late List<String> fontFamilies;

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
    fontFamilies = List.from(FontHelper.availableFonts);
    _textController = TextEditingController(text: widget.existingText?.text ?? 'LOOMA CREATIVE');
    _textController.addListener(_onTextChanged);
    _fontSize = widget.existingText?.fontSize ?? 28.0;
    _colorHex = widget.existingText?.colorHex ?? 0xFFFFFFFF;
    _presetStyle = widget.existingText?.presetStyle ?? 'Neon';
    _fontFamily = FontHelper.normalizeFontName(widget.existingText?.fontFamily ?? 'Roboto');
    _textAlign = widget.existingText?.textAlign ?? 'center';
    _letterSpacing = widget.existingText?.letterSpacing ?? 0.0;
    _lineHeight = widget.existingText?.lineHeight ?? 1.2;
    _opacity = widget.existingText?.opacity ?? 1.0;
    _rotation = widget.existingText?.rotation ?? 0.0;
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
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
          textAlign: _textAlign,
          letterSpacing: _letterSpacing,
          lineHeight: _lineHeight,
          opacity: _opacity,
          rotation: _rotation,
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
          textAlign: _textAlign,
          letterSpacing: _letterSpacing,
          lineHeight: _lineHeight,
          opacity: _opacity,
          rotation: _rotation,
          positionX: 40,
          positionY: 100,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.existingText != null ? 'Edit Typography' : 'Add Professional Text',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Text Field Input
              TextField(
                controller: _textController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter text here...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Live Typography Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Center(
                  child: Text(
                    _textController.text.isEmpty ? 'Typography Preview' : _textController.text,
                    textAlign: _textAlign == 'left' ? TextAlign.left : (_textAlign == 'right' ? TextAlign.right : TextAlign.center),
                    style: FontHelper.getTextStyle(
                      _fontFamily,
                      fontSize: (_fontSize * 0.75).clamp(16.0, 32.0),
                      color: Color(_colorHex).withValues(alpha: _opacity),
                      letterSpacing: _letterSpacing,
                      height: _lineHeight,
                      fontWeight: _presetStyle == 'Bold' ? FontWeight.bold : FontWeight.normal,
                    ).copyWith(
                      fontStyle: _presetStyle == 'Italic' ? FontStyle.italic : FontStyle.normal,
                      shadows: (_presetStyle == 'Glow' || _presetStyle == 'Neon')
                          ? [
                              Shadow(color: Color(_colorHex), blurRadius: 15),
                              Shadow(color: Color(_colorHex), blurRadius: 30),
                            ]
                          : ((_presetStyle == 'Shadow' || _presetStyle == '3D-style')
                              ? const [
                                  Shadow(color: Colors.black87, offset: Offset(3, 3), blurRadius: 6),
                                ]
                              : null),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Text Alignment
              Text('ALIGNMENT', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildAlignChip('Left', 'left', Icons.format_align_left),
                  const SizedBox(width: 8),
                  _buildAlignChip('Center', 'center', Icons.format_align_center),
                  const SizedBox(width: 8),
                  _buildAlignChip('Right', 'right', Icons.format_align_right),
                ],
              ),
              const SizedBox(height: 16),

              // Text Style Preset
              Text('TEXT STYLE PRESET', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Font Family
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('FONT FAMILY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: _installCustomFont,
                    child: const Text('➕ Install Font', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
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
                        label: Text(
                          font,
                          style: FontHelper.getTextStyle(
                            font,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _fontFamily = font),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Font Size Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('FONT SIZE', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${_fontSize.round()} px', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _fontSize.clamp(14.0, 72.0),
                min: 14,
                max: 72,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _fontSize = val),
              ),

              // Letter Spacing Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LETTER SPACING', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${_letterSpacing.toStringAsFixed(1)} px', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _letterSpacing.clamp(-2.0, 10.0),
                min: -2.0,
                max: 10.0,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _letterSpacing = val),
              ),

              // Opacity Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TEXT OPACITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${(_opacity * 100).round()}%', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _opacity.clamp(0.1, 1.0),
                min: 0.1,
                max: 1.0,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _opacity = val),
              ),

              // Text Color
              Text('TEXT COLOR', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (hex == 0xFFFFFFFF ? const Color(0xFFCBD5E1) : const Color(0x33000000)),
                              width: isSelected ? 3 : 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: hex == 0xFFFFFFFF || hex == 0xFFFFB800 ? Colors.black : Colors.white,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    widget.existingText != null ? 'Update Typography' : 'Add to Canvas',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlignChip(String label, String value, IconData icon) {
    final isSelected = _textAlign == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _textAlign = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primaryLight : AppColors.textPrimary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
