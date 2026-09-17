import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/app_actions_service.dart';

class AiPromptStudioSheet extends StatefulWidget {
  const AiPromptStudioSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AiPromptStudioSheet(),
    );
  }

  @override
  State<AiPromptStudioSheet> createState() => _AiPromptStudioSheetState();
}

class _AiPromptStudioSheetState extends State<AiPromptStudioSheet> {
  String _selectedSubject = 'Cyber Samurai';
  String _selectedStyle = 'Cyberpunk Neon';
  String _selectedLighting = 'Neon Volumetric Rain';
  String _selectedCamera = '85mm f/1.4 Cine Prime';
  String _selectedAspectRatio = '3:4 Portrait';
  String _selectedEngine = 'Flux.1 Pro';

  final TextEditingController _customSubjectController = TextEditingController();
  bool _useCustomSubject = false;
  bool _isCopied = false;

  final List<String> _subjects = [
    'Cyber Samurai',
    'Anime Hero',
    'Vogue High Fashion Model',
    'Nordic Shieldmaiden',
    'Deep Space Astronaut',
    '80s Synthwave Rocker',
    'Steampunk Inventor',
    'Underwater Siren',
    'Velvet Gothic Vampire',
    'Cute 3D Pixar Mascot',
    'Ancient Sun Pharaoh',
    'K-Pop Stage Idol',
  ];

  final List<String> _styles = [
    'Cyberpunk Neon',
    '80s Synthwave',
    'Makoto Shinkai Anime',
    'Vogue Editorial',
    'Kodak 35mm Analog Film',
    'Dark Academia',
    'Prismatic Crystal Rainbow',
    'Nordic Mythological',
    'Stop-Motion Claymation',
    'Film Noir 1940s',
    'Imperial Sakura Watercolor',
    'Dune Desert Mirage',
  ];

  final List<String> _lightings = [
    'Neon Volumetric Rain',
    'Golden Hour Sunbeams',
    'Prismatic Rainbow Caustics',
    'Chiaroscuro Candlelight',
    'Studio Beauty Dish Softbox',
    'Underwater Godrays & Bioluminescence',
    'Stadium Concert Spotlights',
    'Slatted Venetian Blind Shadows',
    'CRT Phosphor Glow & Scanlines',
  ];

  final List<String> _cameras = [
    '85mm f/1.4 Cine Prime',
    '35mm Leica Summicron Prime',
    'Hasselblad 100MP Medium Format',
    'Panavision Anamorphic 2x Squeeze',
    'Polaroid 600 Instant Camera',
    '70mm IMAX Widescreen',
    '100mm Macro Beauty Lens',
  ];

  final List<String> _aspectRatios = [
    '3:4 Portrait',
    '9:16 Reel / Story',
    '1:1 Square',
    '16:9 Cinema',
  ];

  final List<String> _engines = [
    'Flux.1 Pro',
    'Midjourney v6.1',
    'SDXL Turbo',
    'DALL-E 3',
    'NijiJourney v6',
  ];

  @override
  void dispose() {
    _customSubjectController.dispose();
    super.dispose();
  }

  String get _currentSubject {
    if (_useCustomSubject && _customSubjectController.text.trim().isNotEmpty) {
      return _customSubjectController.text.trim();
    }
    return _selectedSubject;
  }

  String get _generatedPrompt {
    final s = _currentSubject;
    final style = _selectedStyle;
    final light = _selectedLighting;
    final cam = _selectedCamera;

    return 'Masterpiece cinematic 8k portrait of a $s, executed in exquisite $style aesthetic, '
        'illuminated by dramatic $light, captured with $cam, photorealistic skin texture, intricate detail, '
        'rich color grading, award winning artistic composition.';
  }

  String get _negativePrompt {
    return 'blurry, low resolution, bad anatomy, deformed limbs, extra fingers, oversaturated, '
        'watermark, text signature, artificial plastic skin, cartoonish artifacts';
  }

  void _copyPrompt() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: _generatedPrompt));
    setState(() => _isCopied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00C2CB), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI Prompt Copied! Ready for ChatGPT, Midjourney or Gemini ✨',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _copyFullBundle() {
    HapticFeedback.mediumImpact();
    final bundle = StringBuffer()
      ..writeln('PROMPT:')
      ..writeln(_generatedPrompt)
      ..writeln('\nNEGATIVE PROMPT:')
      ..writeln(_negativePrompt)
      ..writeln('\nSPECS:')
      ..writeln('• Model: $_selectedEngine')
      ..writeln('• Lighting: $_selectedLighting')
      ..writeln('• Camera/Lens: $_selectedCamera')
      ..writeln('• Aspect Ratio: $_selectedAspectRatio');

    Clipboard.setData(ClipboardData(text: bundle.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF00C2CB), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Full AI Bundle Copied (Prompt + Negatives + Settings)! ✨',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sharePrompt() async {
    HapticFeedback.lightImpact();
    await AppActionsService.shareAiPrompt(
      prompt: _generatedPrompt,
      title: '$_currentSubject in $_selectedStyle Style',
      category: _selectedStyle,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChips({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
    Color activeColor = const Color(0xFF0D6EFD),
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((opt) {
          final isSel = opt == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(opt),
              selected: isSel,
              onSelected: (_) => onSelected(opt),
              labelStyle: TextStyle(
                color: isSel ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              ),
              selectedColor: activeColor,
              backgroundColor: const Color(0xFF1E293B),
              side: BorderSide(
                color: isSel ? activeColor : const Color(0xFF334155),
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomPad = media.viewInsets.bottom + media.padding.bottom + 20;

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.90),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C2CB), Color(0xFF0D6EFD)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Prompt Studio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Generate infinite pro prompts for Midjourney, Flux & Gemini',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF1E293B)),

          // Scrollable Builder Controls
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Subject Selector
                  _buildSectionHeader('1. Choose Subject or Enter Custom', Icons.person_rounded, const Color(0xFF38BDF8)),
                  _buildChoiceChips(
                    options: _subjects,
                    selected: _useCustomSubject ? '' : _selectedSubject,
                    onSelected: (val) {
                      setState(() {
                        _selectedSubject = val;
                        _useCustomSubject = false;
                      });
                    },
                    activeColor: const Color(0xFF0284C7),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customSubjectController,
                    onChanged: (val) {
                      if (val.isNotEmpty && !_useCustomSubject) {
                        setState(() => _useCustomSubject = true);
                      } else if (val.isEmpty && _useCustomSubject) {
                        setState(() => _useCustomSubject = false);
                      } else {
                        setState(() {});
                      }
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      hintText: 'Or type custom subject (e.g. "Steampunk Victorian cat captain")...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                  ),

                  // 2. Art Style Selector
                  _buildSectionHeader('2. Visual Art Style', Icons.palette_rounded, const Color(0xFFA855F7)),
                  _buildChoiceChips(
                    options: _styles,
                    selected: _selectedStyle,
                    onSelected: (val) => setState(() => _selectedStyle = val),
                    activeColor: const Color(0xFF9333EA),
                  ),

                  // 3. Lighting Setup
                  _buildSectionHeader('3. Lighting & Atmosphere', Icons.lightbulb_rounded, const Color(0xFFFBBF24)),
                  _buildChoiceChips(
                    options: _lightings,
                    selected: _selectedLighting,
                    onSelected: (val) => setState(() => _selectedLighting = val),
                    activeColor: const Color(0xFFD97706),
                  ),

                  // 4. Camera & Lens
                  _buildSectionHeader('4. Camera, Lens & Depth of Field', Icons.camera_alt_rounded, const Color(0xFF34D399)),
                  _buildChoiceChips(
                    options: _cameras,
                    selected: _selectedCamera,
                    onSelected: (val) => setState(() => _selectedCamera = val),
                    activeColor: const Color(0xFF059669),
                  ),

                  // 5. Engine & Target Model
                  const SizedBox(height: 6),
                  _buildSectionHeader('5. AI Engine & Target Model', Icons.memory_rounded, const Color(0xFF00C2CB)),
                  _buildChoiceChips(
                    options: _engines,
                    selected: _selectedEngine,
                    onSelected: (val) => setState(() => _selectedEngine = val),
                    activeColor: const Color(0xFF00838F),
                  ),

                  // 6. Aspect Ratio
                  _buildSectionHeader('6. Aspect Ratio', Icons.aspect_ratio_rounded, const Color(0xFFF43F5E)),
                  _buildChoiceChips(
                    options: _aspectRatios,
                    selected: _selectedAspectRatio,
                    onSelected: (val) => setState(() => _selectedAspectRatio = val),
                    activeColor: const Color(0xFFE11D48),
                  ),

                  const SizedBox(height: 20),

                  // Live Generated Prompt Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Generated AI Prompt',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF475569)),
                              ),
                              child: Text(
                                '$_selectedEngine • 8K',
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _generatedPrompt,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(
                            _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                            size: 17,
                          ),
                          label: Text(
                            _isCopied ? 'Copied!' : 'Copy Prompt',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          onPressed: _copyPrompt,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF38BDF8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.copy_all_rounded, size: 16),
                          label: const Text(
                            '+ Specs',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                          onPressed: _copyFullBundle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00C2CB),
                            side: const BorderSide(color: Color(0xFF00C2CB)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text(
                            'Share',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                          onPressed: _sharePrompt,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
