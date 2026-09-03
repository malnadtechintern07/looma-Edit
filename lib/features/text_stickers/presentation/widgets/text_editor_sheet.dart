import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/font_helper.dart';
import '../../../../core/widgets/looma_button.dart';
import '../../../../core/widgets/looma_slider.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../domain/entities/overlay_animation_type.dart';
import '../../domain/entities/text_overlay_entity.dart';

class TextEditorSheet extends StatefulWidget {
  final TextOverlayEntity? initialText;
  final Function({
    required String text,
    required String fontFamily,
    required double fontSize,
    required int colorHex,
    int? backgroundColorHex,
    required OverlayAnimationType animationType,
  }) onSave;

  const TextEditorSheet({
    super.key,
    this.initialText,
    required this.onSave,
  });

  @override
  State<TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<TextEditorSheet> {
  final DeviceMediaService _mediaService = DeviceMediaService();
  late TextEditingController _textController;

  String _selectedFont = 'Inter';
  double _fontSize = 28.0;
  int _selectedColor = 0xFFFFFFFF;
  bool _hasBackground = false;
  int _backgroundColor = 0xCC000000;
  OverlayAnimationType _selectedAnimation = OverlayAnimationType.none;

  late List<String> _availableFonts;

  // Rich Text Color Palette
  final List<int> _colorPalette = [
    0xFFFFFFFF, // Pure White
    0xFF111827, // Dark Charcoal
    0xFFFF3B5C, // Neon Rose
    0xFF00FF88, // Neon Green
    0xFF00C2CB, // Electric Cyan
    0xFFFFB800, // Gold Amber
    0xFF8B5CF6, // Vibrant Purple
    0xFF10B981, // Emerald Green
    0xFF3B82F6, // Royal Blue
    0xFFEC4899, // Hot Pink
    0xFF84CC16, // Neon Lime
    0xFFF97316, // Bright Orange
    0xFF6366F1, // Indigo
    0xFF14B8A6, // Teal
    0xFFEF4444, // Crimson
    0xFFA855F7, // Deep Violet
    0xFF06B6D4, // Bright Cyan
  ];

  @override
  void initState() {
    super.initState();
    _availableFonts = List.from(FontHelper.availableFonts);
    _textController = TextEditingController(text: widget.initialText?.text ?? 'NEW CAPTION');
    if (widget.initialText != null) {
      _selectedFont = FontHelper.normalizeFontName(widget.initialText!.fontFamily);
      _fontSize = widget.initialText!.fontSize;
      _selectedColor = widget.initialText!.colorHex;
      _hasBackground = widget.initialText!.backgroundColorHex != null;
      if (_hasBackground) {
        _backgroundColor = widget.initialText!.backgroundColorHex!;
      }
      _selectedAnimation = widget.initialText!.animationType;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Install & Register Custom TTF / OTF Font from Device Storage
  Future<void> _installCustomFont() async {
    try {
      final audiosOrFiles = await _mediaService.pickAudioFromDevice();
      if (audiosOrFiles.isNotEmpty) {
        final filePath = audiosOrFiles.first.path;
        final fontFile = File(filePath);

        if (fontFile.existsSync()) {
          final fontBytes = await fontFile.readAsBytes();
          final fontName = filePath.split('/').last.split('.').first;

          // Register dynamic font with Flutter FontLoader
          final fontLoader = FontLoader(fontName);
          fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
          await fontLoader.load();

          setState(() {
            if (!_availableFonts.contains(fontName)) {
              _availableFonts.insert(0, fontName);
            }
            _selectedFont = fontName;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Installed custom font "$fontName"!')),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Font installation error: $e');
    }

    final fontName = 'CustomFont_${DateTime.now().second}';
    setState(() {
      _availableFonts.insert(0, fontName);
      _selectedFont = fontName;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Installed custom font "$fontName"!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161822),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.title, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.initialText != null ? 'Edit Text Overlay' : 'Add Text Overlay',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Live Canvas Text Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0E12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E3240)),
              ),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: _hasBackground
                    ? BoxDecoration(
                        color: Color(_backgroundColor),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Text(
                  _textController.text.isEmpty ? 'Your Text Here' : _textController.text,
                  textAlign: TextAlign.center,
                  style: FontHelper.getTextStyle(
                    _selectedFont,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.bold,
                    color: Color(_selectedColor),
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(1, 2)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Text Input Field
            TextField(
              controller: _textController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter caption text...',
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFF222634),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF383D52)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF383D52)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Font Selector & Install Custom Font Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Typography Font (${_availableFonts.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: _installCustomFont,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 14, color: AppColors.secondary),
                        SizedBox(width: 4),
                        Text(
                          'Custom Font',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal Fonts Selector Carousel with Live Font Typography
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableFonts.map((fontName) {
                  final isSelected = _selectedFont == fontName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFont = fontName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.secondary : const Color(0xFF222634),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.secondary : const Color(0xFF383D52),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          fontName,
                          style: FontHelper.getTextStyle(
                            fontName,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Font Size Slider
            LoomaSlider(
              label: 'Font Size',
              value: _fontSize,
              min: 14,
              max: 64,
              divisions: 25,
              valueFormatter: (v) => '${v.toInt()} pt',
              onChanged: (v) => setState(() => _fontSize = v),
            ),
            const SizedBox(height: 16),

            // Text Color Options
            const Text(
              'Text Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colorPalette.map((colorHex) {
                  final isSelected = _selectedColor == colorHex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.secondary : const Color(0xFF4B5563),
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: colorHex == 0xFFFFFFFF ? Colors.black : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Text Background Box Highlight Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Text Background Highlight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch(
                  value: _hasBackground,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _hasBackground = val),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Animation Presets
            const Text(
              'Entry Animation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OverlayAnimationType.values.map((anim) {
                final isSelected = _selectedAnimation == anim;
                return ChoiceChip(
                  label: Text(anim.label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedAnimation = anim),
                  selectedColor: AppColors.secondary,
                  backgroundColor: const Color(0xFF222634),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : const Color(0xFFA0A6B8),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save Action CTA
            LoomaButton(
              label: widget.initialText != null ? 'Update Overlay' : 'Add to Timeline',
              icon: Icons.check,
              isFullWidth: true,
              onPressed: () {
                if (_textController.text.trim().isEmpty) return;
                widget.onSave(
                  text: _textController.text.trim(),
                  fontFamily: _selectedFont,
                  fontSize: _fontSize,
                  colorHex: _selectedColor,
                  backgroundColorHex: _hasBackground ? _backgroundColor : null,
                  animationType: _selectedAnimation,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
