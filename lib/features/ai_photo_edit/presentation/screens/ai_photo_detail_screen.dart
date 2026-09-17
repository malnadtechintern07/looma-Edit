import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_actions_service.dart';
import '../../data/ai_photo_presets_data.dart';
import '../../domain/entities/ai_photo_preset_entity.dart';

class AiPhotoDetailScreen extends StatefulWidget {
  final AiPhotoPresetEntity preset;

  const AiPhotoDetailScreen({
    super.key,
    required this.preset,
  });

  @override
  State<AiPhotoDetailScreen> createState() => _AiPhotoDetailScreenState();
}

class _AiPhotoDetailScreenState extends State<AiPhotoDetailScreen> {
  late AiPhotoPresetEntity _currentPreset;
  late int _likesCount;
  bool _isLiked = false;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _currentPreset = widget.preset;
    _likesCount = widget.preset.likesCount;
  }

  void _selectPreset(AiPhotoPresetEntity preset) {
    setState(() {
      _currentPreset = preset;
      _likesCount = preset.likesCount;
      _isLiked = false;
      _isCopied = false;
    });
  }

  Widget _buildPresetImage(String path, {BoxFit fit = BoxFit.cover, double iconSize = 48}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1E293B),
          child: Icon(Icons.image, color: Colors.white38, size: iconSize),
        ),
      );
    }
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF1E293B),
        child: Icon(Icons.image, color: Colors.white38, size: iconSize),
      ),
    );
  }

  void _copyPrompt() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: _currentPreset.prompt));
    setState(() => _isCopied = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF00C2CB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Prompt Copied!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Ready to paste in ChatGPT, Gemini or Midjourney ✨',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
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

  Future<void> _sharePrompt() async {
    HapticFeedback.lightImpact();
    await AppActionsService.shareAiPromptLink(
      title: _currentPreset.title,
      presetId: _currentPreset.id,
      category: _currentPreset.category,
      prompt: _currentPreset.prompt,
      referenceImageUrl: _currentPreset.referenceImagePath,
    );
  }

  void _copyNegativePrompt() {
    if (_currentPreset.negativePrompt == null) return;
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: _currentPreset.negativePrompt!));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00C2CB), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Negative Prompt Copied! (Ready to exclude artifacts)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyFullBundle() {
    final buffer = StringBuffer();
    buffer.writeln('PROMPT:');
    buffer.writeln(_currentPreset.prompt);
    if (_currentPreset.negativePrompt != null && _currentPreset.negativePrompt!.isNotEmpty) {
      buffer.writeln('\nNEGATIVE PROMPT:');
      buffer.writeln(_currentPreset.negativePrompt);
    }
    if (_currentPreset.modelRecommendation != null && _currentPreset.modelRecommendation!.isNotEmpty) {
      buffer.writeln('\nRECOMMENDED MODEL: ${_currentPreset.modelRecommendation}');
    }
    if (_currentPreset.lightingStyle != null && _currentPreset.lightingStyle!.isNotEmpty) {
      buffer.writeln('LIGHTING: ${_currentPreset.lightingStyle}');
    }
    if (_currentPreset.cameraLens != null && _currentPreset.cameraLens!.isNotEmpty) {
      buffer.writeln('CAMERA/LENS: ${_currentPreset.cameraLens}');
    }
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF00C2CB), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Full AI Bundle Copied (Prompt + Negative + Settings)! ✨',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleLike() {
    HapticFeedback.selectionClick();
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
  }

  List<AiPhotoPresetEntity> get _relatedPresets {
    return AiPhotoPresetsData.currentPresets
        .where((p) => p.id != _currentPreset.id)
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;
    final bottomPadding = media.padding.bottom + 20;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Collapsible/Floating Hero Image App Bar
          SliverAppBar(
            expandedHeight: media.size.height * 0.52,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0F172A),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _toggleLike,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                          color: _isLiked ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$_likesCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: _sharePrompt,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Full interactive zoomable hero photo
                  InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: Hero(
                      tag: 'ai_photo_${_currentPreset.id}',
                      child: _buildPresetImage(
                        _currentPreset.referenceImagePath,
                        fit: BoxFit.cover,
                        iconSize: 64,
                      ),
                    ),
                  ),

                  // Gradient scrim at the top for app bar buttons
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topPadding + 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Bottom gradient blend into dark container
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0F172A).withValues(alpha: 0.85),
                            const Color(0xFF0F172A),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Badge & Aspect Ratio on Image
                  Positioned(
                    bottom: 18,
                    left: 18,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white30, width: 0.8),
                          ),
                          child: Text(
                            _currentPreset.badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C2CB).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF00C2CB), width: 0.8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.aspect_ratio_rounded, color: Color(0xFF00C2CB), size: 14),
                              const SizedBox(width: 5),
                              Text(
                                _currentPreset.aspectRatio,
                                style: const TextStyle(
                                  color: Color(0xFF00C2CB),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content Body
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF0F172A),
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Category Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPreset.title,
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Category: ${_currentPreset.category} Style',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Keyword / Tag Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _currentPreset.styleKeywords.map((keyword) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Text(
                          '#$keyword',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Full AI Prompt Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D6EFD).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Generation Prompt',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Optimized for Midjourney v6, ChatGPT DALL-E & Flux',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copy Prompt',
                              icon: Icon(
                                _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                color: _isCopied ? const Color(0xFF00C2CB) : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: _copyPrompt,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SelectableText(
                          _currentPreset.prompt,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 13.5,
                            height: 1.55,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Color(0xFF38BDF8)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap "Copy Prompt" below, then paste into your AI generator of choice.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pro Generation Parameters & Negative Prompt Card
                  if (_currentPreset.modelRecommendation != null ||
                      _currentPreset.negativePrompt != null ||
                      _currentPreset.lightingStyle != null ||
                      _currentPreset.cameraLens != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C2CB).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.tune_rounded, color: Color(0xFF00C2CB), size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Pro Generation Specs',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.copy_all_rounded, size: 14, color: Color(0xFF38BDF8)),
                                label: const Text(
                                  'Copy All Specs',
                                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                                onPressed: _copyFullBundle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Recommended Model & Lighting chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_currentPreset.modelRecommendation != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF475569)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.memory, size: 13, color: Color(0xFF38BDF8)),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Model: ${_currentPreset.modelRecommendation}',
                                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11.5, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_currentPreset.lightingStyle != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF475569)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.light_mode_outlined, size: 13, color: Color(0xFFFBBF24)),
                                      const SizedBox(width: 5),
                                      Text(
                                        _currentPreset.lightingStyle!,
                                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11.5, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_currentPreset.cameraLens != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF475569)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.camera_alt_outlined, size: 13, color: Color(0xFF34D399)),
                                      const SizedBox(width: 5),
                                      Text(
                                        _currentPreset.cameraLens!,
                                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11.5, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          // Negative prompt
                          if (_currentPreset.negativePrompt != null && _currentPreset.negativePrompt!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.block_rounded, size: 13, color: Color(0xFFF87171)),
                                          SizedBox(width: 5),
                                          Text(
                                            'Negative Prompt (Anti-Artifacts)',
                                            style: TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: _copyNegativePrompt,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          child: Text(
                                            'Copy Negative',
                                            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  SelectableText(
                                    _currentPreset.negativePrompt!,
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          icon: Icon(
                            _isCopied ? Icons.check_circle : Icons.copy_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isCopied ? 'Copied to Clipboard!' : 'Copy Prompt',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: _copyPrompt,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00C2CB),
                            side: const BorderSide(color: Color(0xFF00C2CB), width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 17, color: Color(0xFF00C2CB)),
                          label: const Text(
                            'Share',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _sharePrompt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // More Related AI Styles
                  const Row(
                    children: [
                      Icon(Icons.auto_fix_high_rounded, color: Color(0xFF38BDF8), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Explore More AI Styles',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Related presets horizontal carousel
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _relatedPresets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final rel = _relatedPresets[idx];
                        return GestureDetector(
                          onTap: () => _selectPreset(rel),
                          child: Container(
                            width: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildPresetImage(rel.referenceImagePath, fit: BoxFit.cover, iconSize: 32),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.8),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    right: 8,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          rel.badgeText,
                                          style: const TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          rel.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
