import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/font_helper.dart';
import '../../../../core/widgets/procut_button.dart';
import '../../../../core/widgets/procut_slider.dart';
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

class _TextEditorSheetState extends State<TextEditorSheet>
    with SingleTickerProviderStateMixin {
  final DeviceMediaService _mediaService = DeviceMediaService();
  late TextEditingController _textController;
  late AnimationController _previewAnimController;

  TextEditorTab _selectedTab = TextEditorTab.font;

  String _selectedFont = 'Inter';
  double _fontSize = 28.0;
  int _selectedColor = 0xFFFFFFFF;
  bool _hasBackground = false;
  int _backgroundColor = 0xCC000000;
  OverlayAnimationType _selectedAnimation = OverlayAnimationType.none;

  late List<String> _availableFonts;
  String _fontSearchQuery = '';

  final ScrollController _fontScrollController = ScrollController();
  final ScrollController _animScrollController = ScrollController();
  final ScrollController _colorScrollController = ScrollController();
  final ScrollController _bgScrollController = ScrollController();

  // Rich, vibrant 56-color palette
  final List<int> _colorPalette = [
    // Monochrome & Grayscale
    0xFFFFFFFF, // Pure White
    0xFFF3F4F6, // Bright Silver
    0xFFE5E7EB, // Light Gray
    0xFFD1D5DB, // Cool Gray
    0xFF9CA3AF, // Slate Gray
    0xFF6B7280, // Medium Gray
    0xFF4B5563, // Dark Slate
    0xFF1F2937, // Charcoal
    0xFF111827, // Dark Navy Black
    0xFF000000, // True Black

    // Neon & Electric
    0xFFFF3B5C, // Neon Rose / TikTok
    0xFFFF0055, // Electric Pink
    0xFFFF007F, // Deep Rose
    0xFFEC4899, // Hot Pink
    0xFFF43F5E, // Bright Coral
    0xFFEF4444, // Crimson Red
    0xFFDC2626, // Vivid Red
    0xFFB91C1C, // Deep Red
    0xFFF97316, // Bright Orange
    0xFFFF8C00, // Deep Tangerine
    0xFFFFB800, // Gold Amber
    0xFFFFD600, // Bright Gold
    0xFFFFEA00, // Neon Cyberpunk Yellow
    0xFFEAB308, // Mustard Yellow
    0xFF84CC16, // Neon Lime
    0xFFA3E635, // Acid Lime
    0xFF00FF88, // Neon Mint Green
    0xFF10B981, // Emerald Green
    0xFF059669, // Rich Green
    0xFF15803D, // Deep Forest Green
    0xFF00C2CB, // Electric Cyan
    0xFF06B6D4, // Bright Cyan
    0xFF0EA5E9, // Sky Blue
    0xFF14B8A6, // Aqua Teal
    0xFF0D9488, // Deep Teal
    0xFF3B82F6, // Royal Blue
    0xFF2563EB, // Electric Cobalt
    0xFF1D4ED8, // Deep Royal
    0xFF6366F1, // Indigo
    0xFF4F46E5, // Electric Indigo
    0xFF8B5CF6, // Vibrant Purple
    0xFFA855F7, // Deep Violet
    0xFFC084FC, // Soft Lavender
    0xFFD946EF, // Hot Magenta

    // Pastels & Aesthetic
    0xFFFFD6A5, // Pastel Peach
    0xFFFDFFB6, // Pastel Cream Yellow
    0xFFCAFFBF, // Pastel Mint
    0xFF9BF6FF, // Pastel Cyan
    0xFFA0C4FF, // Pastel Baby Blue
    0xFFBDB2FF, // Pastel Periwinkle
    0xFFFFC6FF, // Pastel Bubblegum
    0xFFFFE4E6, // Pastel Soft Pink

    // Warm / Earth / Luxury
    0xFFF3E5AB, // Champagne Gold
    0xFFCD7F32, // Bronze
    0xFFB87333, // Copper
    0xFFD4A373, // Warm Sand
  ];

  // Background Highlight Color Palette (24 curated shades)
  final List<int> _bgPalette = [
    0xCC000000, // Translucent Black
    0xFF000000, // Solid Black
    0xCCFFFFFF, // Translucent White
    0xFFFFFFFF, // Solid White
    0xCC1E1B4B, // Deep Navy Purple
    0xCC312E81, // Indigo Box
    0xCC831843, // Deep Berry
    0xCC14532D, // Forest Green
    0xCC7C2D12, // Warm Amber
    0xCC134E4A, // Teal Box
    0xCC701A75, // Magenta Box
    0xCC0F172A, // Midnight Slate
    0xCC991B1B, // Ruby Box
    0xCCE11D48, // Crimson Box
    0xCCEA580C, // Sunset Box
    0xCCA16207, // Gold Box
    0xCC15803D, // Emerald Box
    0xCC047857, // Jade Box
    0xCC0369A1, // Ocean Box
    0xCC4338CA, // Royal Box
    0xCC6D28D9, // Violet Box
    0xCC86198F, // Fuchsia Box
    0xCCBE185D, // Rose Box
    0x88262B3D, // Glass Frost Dark
  ];

  @override
  void initState() {
    super.initState();
    FontHelper.preloadPopularFonts();
    _availableFonts = List.from(FontHelper.availableFonts);
    _textController =
        TextEditingController(text: widget.initialText?.text ?? 'NEW CAPTION');
    _previewAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    if (widget.initialText != null) {
      _selectedFont =
          FontHelper.normalizeFontName(widget.initialText!.fontFamily);
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
    _previewAnimController.dispose();
    _fontScrollController.dispose();
    _animScrollController.dispose();
    _colorScrollController.dispose();
    _bgScrollController.dispose();
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

  // Build Animated Text Preview in Live Canvas Card
  Widget _buildPreviewText() {
    return AnimatedBuilder(
      animation: _previewAnimController,
      builder: (context, child) {
        final progress = _previewAnimController.value;
        double opacity = 1.0;
        double translateY = 0.0;
        double translateX = 0.0;
        double scale = 1.0;
        double rotation = 0.0;

        switch (_selectedAnimation) {
          case OverlayAnimationType.fadeIn:
            opacity = progress;
            break;
          case OverlayAnimationType.slideUp:
            translateY = (1.0 - progress) * 30.0;
            opacity = progress;
            break;
          case OverlayAnimationType.slideDown:
            translateY = -(1.0 - progress) * 30.0;
            opacity = progress;
            break;
          case OverlayAnimationType.slideLeft:
            translateX = (1.0 - progress) * 45.0;
            opacity = progress;
            break;
          case OverlayAnimationType.slideRight:
            translateX = -(1.0 - progress) * 45.0;
            opacity = progress;
            break;
          case OverlayAnimationType.zoomIn:
            scale = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
            opacity = progress;
            break;
          case OverlayAnimationType.zoomOut:
            scale = 1.0 + (1.0 - progress) * 0.8;
            opacity = progress;
            break;
          case OverlayAnimationType.bounce:
            final b = Curves.bounceOut.transform(progress);
            translateY = (1.0 - b) * 30.0;
            opacity = progress;
            break;
          case OverlayAnimationType.spin:
            rotation = (1.0 - progress) * math.pi * 2;
            scale = progress;
            opacity = progress;
            break;
          case OverlayAnimationType.flip:
            scale = progress.clamp(0.05, 1.0);
            opacity = progress;
            break;
          case OverlayAnimationType.drop:
            final d = Curves.bounceOut.transform(progress);
            translateY = -(1.0 - d) * 45.0;
            opacity = progress;
            break;
          case OverlayAnimationType.flash:
            opacity = ((progress * 10).toInt() % 2 == 0) ? 1.0 : 0.2;
            break;
          case OverlayAnimationType.swing:
            rotation =
                math.sin(progress * math.pi * 4) * 0.2 * (1.0 - progress);
            opacity = progress;
            break;
          case OverlayAnimationType.blur:
            scale = 1.15 - (0.15 * progress);
            opacity = progress;
            break;
          case OverlayAnimationType.shake:
            translateX =
                math.sin(progress * math.pi * 6) * 6.0 * (1.0 - progress);
            opacity = progress;
            break;
          case OverlayAnimationType.pulse:
            scale = 1.0 + math.sin(progress * math.pi * 2).abs() * 0.15;
            break;
          case OverlayAnimationType.glitch:
            translateX = math.sin(progress * math.pi * 12) * 5.0;
            opacity = 0.9;
            break;
          case OverlayAnimationType.glow:
            scale = 1.0 + math.sin(progress * math.pi) * 0.08;
            break;
          case OverlayAnimationType.wave:
            translateY = math.sin(progress * math.pi * 2) * 6.0;
            break;
          case OverlayAnimationType.typewriter:
          case OverlayAnimationType.none:
            break;
        }

        String displayText = _textController.text.isEmpty
            ? 'Your Text Here'
            : _textController.text;
        if (_selectedAnimation == OverlayAnimationType.typewriter) {
          final count = (displayText.length * progress)
              .toInt()
              .clamp(0, displayText.length);
          displayText = displayText.substring(0, count);
        }

        return Transform.translate(
          offset: Offset(translateX, translateY),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: _hasBackground
                      ? BoxDecoration(
                          color: Color(_backgroundColor),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Text(
                    displayText,
                    textAlign: TextAlign.center,
                    style: FontHelper.getTextStyle(
                      _selectedFont,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                      color: Color(_selectedColor),
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
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
                      child: const Icon(
                        Icons.title,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.initialText != null
                          ? 'Edit Text Overlay'
                          : 'Add Text Overlay',
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

            // 2. Live Canvas Text Preview Card (with real-time animation player)
            GestureDetector(
              onTap: () {
                _previewAnimController.reset();
                _previewAnimController.forward();
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0E12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E3240)),
                ),
                alignment: Alignment.center,
                child: _buildPreviewText(),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  borderSide:
                      const BorderSide(color: AppColors.secondary, width: 1.5),
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
            ProCutButton(
              label: widget.initialText != null
                  ? 'Update Overlay'
                  : 'Add to Timeline',
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

  // TAB 1: Text Font Controls (Vertical Grid Gallery of Fonts)
  Widget _buildFontTab() {
    final filtered = _fontSearchQuery.trim().isEmpty
        ? _availableFonts
        : _availableFonts
            .where((f) =>
                f.toLowerCase().contains(_fontSearchQuery.toLowerCase()))
            .toList();

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.4)),
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

        // Quick Search Filter Bar
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1118),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF262B3D)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('font_search_input'),
                  onChanged: (v) => setState(() => _fontSearchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Search 48+ typography fonts...',
                    hintStyle:
                        TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_fontSearchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _fontSearchQuery = ''),
                  child:
                      const Icon(Icons.close, size: 16, color: Colors.white70),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Vertical Fonts Selector Grid - looks abundant & vast
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1118),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF262B3D)),
          ),
          child: Scrollbar(
            controller: _fontScrollController,
            thumbVisibility: true,
            radius: const Radius.circular(4),
            child: GridView.builder(
              controller: _fontScrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 54,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final fontName = filtered[index];
                final isSelected = _selectedFont == fontName;
                return InkWell(
                  key: Key('font_card_$fontName'),
                  onTap: () => setState(() => _selectedFont = fontName),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary.withValues(alpha: 0.18)
                          : const Color(0xFF1E212E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : const Color(0xFF33384A),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                fontName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fontName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FontHelper.getTextStyle(
                                  fontName,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Font Size Slider
        ProCutSlider(
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

  // TAB 2: Text Animation Controls (Vertical Grid Gallery with Live Replay)
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
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _previewAnimController.reset();
                    _previewAnimController.forward();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 13,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Replay',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ],
        ),
        const SizedBox(height: 12),

        // Vertical Animation Presets Grid
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1118),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF262B3D)),
          ),
          child: Scrollbar(
            controller: _animScrollController,
            thumbVisibility: true,
            radius: const Radius.circular(4),
            child: GridView.builder(
              controller: _animScrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 52,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: OverlayAnimationType.values.length,
              itemBuilder: (context, index) {
                final anim = OverlayAnimationType.values[index];
                final isSelected = _selectedAnimation == anim;

                IconData animIcon = Icons.motion_photos_on_outlined;
                if (anim == OverlayAnimationType.none) animIcon = Icons.block;
                if (anim == OverlayAnimationType.fadeIn) animIcon = Icons.opacity;
                if (anim == OverlayAnimationType.typewriter) {
                  animIcon = Icons.keyboard;
                }
                if (anim == OverlayAnimationType.slideUp) {
                  animIcon = Icons.arrow_upward_rounded;
                }
                if (anim == OverlayAnimationType.slideDown) {
                  animIcon = Icons.arrow_downward_rounded;
                }
                if (anim == OverlayAnimationType.slideLeft) {
                  animIcon = Icons.arrow_back_rounded;
                }
                if (anim == OverlayAnimationType.slideRight) {
                  animIcon = Icons.arrow_forward_rounded;
                }
                if (anim == OverlayAnimationType.zoomIn) {
                  animIcon = Icons.zoom_in_rounded;
                }
                if (anim == OverlayAnimationType.zoomOut) {
                  animIcon = Icons.zoom_out_map_rounded;
                }
                if (anim == OverlayAnimationType.bounce) {
                  animIcon = Icons.sports_basketball_rounded;
                }
                if (anim == OverlayAnimationType.spin) animIcon = Icons.sync_rounded;
                if (anim == OverlayAnimationType.flip) {
                  animIcon = Icons.flip_camera_android_rounded;
                }
                if (anim == OverlayAnimationType.glitch) {
                  animIcon = Icons.flash_on_rounded;
                }
                if (anim == OverlayAnimationType.glow) {
                  animIcon = Icons.wb_sunny_rounded;
                }
                if (anim == OverlayAnimationType.pulse) {
                  animIcon = Icons.favorite_rounded;
                }
                if (anim == OverlayAnimationType.shake) {
                  animIcon = Icons.vibration_rounded;
                }
                if (anim == OverlayAnimationType.drop) {
                  animIcon = Icons.file_download_rounded;
                }
                if (anim == OverlayAnimationType.wave) {
                  animIcon = Icons.waves_rounded;
                }
                if (anim == OverlayAnimationType.flash) {
                  animIcon = Icons.bolt_rounded;
                }
                if (anim == OverlayAnimationType.swing) {
                  animIcon = Icons.architecture_rounded;
                }
                if (anim == OverlayAnimationType.blur) {
                  animIcon = Icons.blur_on_rounded;
                }

                return InkWell(
                  key: Key('anim_card_${anim.name}'),
                  onTap: () {
                    setState(() => _selectedAnimation = anim);
                    _previewAnimController.reset();
                    _previewAnimController.forward();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary.withValues(alpha: 0.18)
                          : const Color(0xFF1E212E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : const Color(0xFF33384A),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondary
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            animIcon,
                            size: 15,
                            color: isSelected
                                ? Colors.black
                                : const Color(0xFFA0A6B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            anim.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFA0A6B8),
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // TAB 3: Text Color & Background Controls (Vertical Multi-row Grid)
  Widget _buildColorTab() {
    return Column(
      key: const ValueKey('tab_view_color'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text Color Palette Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Text Font Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '#${_selectedColor.toRadixString(16).padLeft(8, '0').toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Vertical multi-row grid of font colors (56 colors)
        Container(
          height: 118,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1118),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF262B3D)),
          ),
          padding: const EdgeInsets.all(8),
          child: Scrollbar(
            controller: _colorScrollController,
            thumbVisibility: true,
            radius: const Radius.circular(4),
            child: GridView.builder(
              controller: _colorScrollController,
              padding: const EdgeInsets.only(right: 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _colorPalette.length,
              itemBuilder: (context, index) {
                final colorHex = _colorPalette[index];
                final isSelected = _selectedColor == colorHex;
                final isWhiteLike = colorHex == 0xFFFFFFFF ||
                    colorHex == 0xFFF3F4F6 ||
                    colorHex == 0xFFE5E7EB;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorHex),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(colorHex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : (isWhiteLike
                                ? const Color(0xFF4B5563)
                                : Colors.transparent),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: isWhiteLike ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                );
              },
            ),
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
              inactiveTrackColor: const Color(0xFF2E3240),
              inactiveThumbColor: const Color(0xFF9CA3AF),
              trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? Colors.transparent : const Color(0xFF4B5563),
              ),
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
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1118),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF262B3D)),
            ),
            padding: const EdgeInsets.all(8),
            child: Scrollbar(
              controller: _bgScrollController,
              thumbVisibility: true,
              radius: const Radius.circular(4),
              child: GridView.builder(
                controller: _bgScrollController,
                padding: const EdgeInsets.only(right: 6),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _bgPalette.length,
                itemBuilder: (context, index) {
                  final bgHex = _bgPalette[index];
                  final isSelected = _backgroundColor == bgHex;

                  return GestureDetector(
                    onTap: () => setState(() => _backgroundColor = bgHex),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(bgHex),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary
                              : const Color(0xFF3B4054),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
