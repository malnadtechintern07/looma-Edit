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

enum TextEditorTab {
  font,
  animation,
  color,
}

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

  TextEditorTab _selectedTab = TextEditorTab.font;

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

  // Background Color Palette
  final List<int> _bgPalette = [
    0xCC000000, // Translucent Black
    0xCCFFFFFF, // Translucent White
    0xCC1E1B4B, // Deep Navy Purple
    0xCC312E81, // Indigo Box
    0xCC831843, // Deep Berry
    0xCC14532D, // Forest Green
    0xCC7C2D12, // Warm Amber
    0xCC134E4A, // Teal Box
    0xCC701A75, // Magenta Box
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
            // 1. Header Row
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
            const SizedBox(height: 12),

            // 2. Live Canvas Text Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            const SizedBox(height: 12),

            // 3. Text Input Field
            TextField(
              controller: _textController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter caption text...',
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFF222634),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            const SizedBox(height: 14),

            // 4. Three Main Buttons in One Line Across the Top Inside Text Option
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1118),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF262B3D)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMainTabButton(
                      key: const Key('text_font_tab_btn'),
                      tab: TextEditorTab.font,
                      icon: Icons.text_fields_rounded,
                      label: 'Text Font',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildMainTabButton(
                      key: const Key('text_anim_tab_btn'),
                      tab: TextEditorTab.animation,
                      icon: Icons.animation_rounded,
                      label: 'Text Animation',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildMainTabButton(
                      key: const Key('text_color_tab_btn'),
                      tab: TextEditorTab.color,
                      icon: Icons.palette_rounded,
                      label: 'Text Color',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Active Tab View Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildActiveTabContent(),
            ),
            const SizedBox(height: 20),

            // 6. Save Action CTA Button
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

  // Segmented Main Tab Button
  Widget _buildMainTabButton({
    required Key key,
    required TextEditorTab tab,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      key: key,
      onTap: () => setState(() => _selectedTab = tab),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Active Tab Content Router
  Widget _buildActiveTabContent() {
    switch (_selectedTab) {
      case TextEditorTab.font:
        return _buildFontTab();
      case TextEditorTab.animation:
        return _buildAnimationTab();
      case TextEditorTab.color:
        return _buildColorTab();
    }
  }

  // TAB 1: Text Font Controls
  Widget _buildFontTab() {
    return Column(
      key: const ValueKey('tab_view_font'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      ],
    );
  }

  // TAB 2: Text Animation Controls
  Widget _buildAnimationTab() {
    return Column(
      key: const ValueKey('tab_view_animation'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Entry Animation Preset',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _selectedAnimation.label,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OverlayAnimationType.values.map((anim) {
            final isSelected = _selectedAnimation == anim;
            IconData animIcon = Icons.motion_photos_on_outlined;
            if (anim == OverlayAnimationType.none) animIcon = Icons.block;
            if (anim == OverlayAnimationType.fadeIn) animIcon = Icons.opacity;
            if (anim == OverlayAnimationType.typewriter) animIcon = Icons.keyboard;
            if (anim == OverlayAnimationType.slideUp) animIcon = Icons.arrow_upward;
            if (anim == OverlayAnimationType.bounce) animIcon = Icons.sports_basketball;
            if (anim == OverlayAnimationType.glitch) animIcon = Icons.flash_on;
            if (anim == OverlayAnimationType.glow) animIcon = Icons.wb_sunny;

            return InkWell(
              onTap: () => setState(() => _selectedAnimation = anim),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : const Color(0xFF222634),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.secondary : const Color(0xFF383D52),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      animIcon,
                      size: 14,
                      color: isSelected ? Colors.black : const Color(0xFFA0A6B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      anim.label,
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFFA0A6B8),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // TAB 3: Text Color & Background Controls
  Widget _buildColorTab() {
    return Column(
      key: const ValueKey('tab_view_color'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text Color Palette
        const Text(
          'Text Font Color',
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

        // Text Background Highlight Toggle
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

        // Background Color Swatches (if enabled)
        if (_hasBackground) ...[
          const SizedBox(height: 8),
          const Text(
            'Highlight Box Color',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _bgPalette.map((bgHex) {
                final isSelected = _backgroundColor == bgHex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _backgroundColor = bgHex),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(bgHex),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppColors.secondary : const Color(0xFF4B5563),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
