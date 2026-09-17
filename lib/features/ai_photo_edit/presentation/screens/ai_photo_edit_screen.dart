import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_actions_service.dart';
import '../../data/ai_photo_presets_data.dart';
import '../../domain/entities/ai_photo_preset_entity.dart';
import '../widgets/ai_prompt_studio_sheet.dart';
import 'ai_photo_detail_screen.dart';

class AiPhotoEditScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const AiPhotoEditScreen({super.key, this.embedded = false});

  @override
  ConsumerState<AiPhotoEditScreen> createState() => _AiPhotoEditScreenState();
}

class _AiPhotoEditScreenState extends ConsumerState<AiPhotoEditScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    AiPhotoPresetsData.fetchServerPresets().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPresetImage(String path, {BoxFit fit = BoxFit.cover, double iconSize = 36}) {
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

  List<AiPhotoPresetEntity> get _filteredPresets {
    return AiPhotoPresetsData.currentPresets.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.styleKeywords.any((k) => k.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _copyPrompt(AiPhotoPresetEntity preset) {
    Clipboard.setData(ClipboardData(text: preset.prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00C2CB), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI Prompt copied! Ready for ChatGPT or Gemini ✨',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sharePrompt(AiPhotoPresetEntity preset) async {
    await AppActionsService.shareAiPromptLink(
      title: preset.title,
      presetId: preset.id,
      category: preset.category,
      prompt: preset.prompt,
      referenceImageUrl: preset.referenceImagePath,
    );
  }

  void _openFullPage(AiPhotoPresetEntity preset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AiPhotoDetailScreen(preset: preset),
      ),
    );
  }

  void _showPreviewDialog(AiPhotoPresetEntity preset) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2A000000),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Header with Badge, Expand & Close
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(dialogCtx).pop();
                          _openFullPage(preset);
                        },
                        child: SizedBox(
                          height: 240,
                          width: double.infinity,
                          child: _buildPresetImage(preset.referenceImagePath, fit: BoxFit.cover, iconSize: 48),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            preset.badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 50,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(dialogCtx).pop();
                            _openFullPage(preset);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogCtx).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),

              // Content Details
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            preset.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${preset.likesCount}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Prompt Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF0D6EFD), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'AI Prompt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF0D6EFD),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset.prompt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                              height: 1.45,
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
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF334155)),
                            label: const Text(
                              'Copy Prompt',
                              style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: () => _copyPrompt(preset),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF00C2CB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF00C2CB)),
                            label: const Text(
                              'Share Prompt',
                              style: TextStyle(color: Color(0xFF00838F), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: () => _sharePrompt(preset),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 15, color: Color(0xFF00838F)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Copy or share this prompt to ChatGPT, Gemini, or Midjourney to generate.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
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
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final items = _filteredPresets;
    final mediaQuery = MediaQuery.of(context);
    // Account for bottom nav bar (72px) + system nav bar inset
    final bottomPad = mediaQuery.padding.bottom + 72 + 16;
    // Top padding only when not embedded (standalone screen)
    final topPad = widget.embedded ? 0.0 : mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          // Top safe area spacer (only when not embedded)
          if (!widget.embedded) SizedBox(height: topPad),

          // Top App Bar Area (shown if not embedded)
          if (!widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF084298), Color(0xFF0D6EFD)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Photo Edit',
                          style: AppTypography.titleLarge.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const Text(
                          'Real Styles, Prompts & One-Tap Creation',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'AI Video Edit',
                    icon: const Icon(Icons.video_camera_back_outlined, color: Color(0xFF0D6EFD)),
                    onPressed: () => context.push(RoutePaths.aiVideoEdit),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings_outlined, color: Color(0xFF0F172A)),
                    onPressed: () => context.push(RoutePaths.settings),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        hintText: 'Search 80s, Cyberpunk, Anime, Vintage styles...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                    ),
                ],
              ),
            ),
          ),

          // AI Prompt Studio Quick Launch Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GestureDetector(
              onTap: () => AiPromptStudioSheet.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00C2CB).withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C2CB).withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C2CB), Color(0xFF0D6EFD)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'AI Prompt Studio & Generator',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              SizedBox(width: 6),
                              Text('✨', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Craft custom 8k prompts with subject, lighting & camera',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C2CB).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Open',
                            style: TextStyle(color: Color(0xFF00C2CB), fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, color: Color(0xFF00C2CB), size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Filter Bar
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: AiPhotoPresetsData.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = AiPhotoPresetsData.categories[i];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Masonry Grid View of AI Photo Presets — Expanded takes remaining space
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await AiPhotoPresetsData.fetchServerPresets();
                if (mounted) setState(() {});
              },
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      children: [
                        SizedBox(height: mediaQuery.size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 10),
                              Text(
                                'No styles found for "$_searchQuery"',
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, idx) {
                        final preset = items[idx];
                        return _buildPhotoPresetCard(preset);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPhotoPresetCard(AiPhotoPresetEntity preset) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reference Image with Badge & Tap to Open Full Page
            Expanded(
              child: GestureDetector(
                onTap: () => _openFullPage(preset),
                onLongPress: () => _showPreviewDialog(preset),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'ai_photo_${preset.id}',
                      child: _buildPresetImage(preset.referenceImagePath, fit: BoxFit.cover, iconSize: 36),
                    ),

                    // Gradient scrim at bottom of image
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Category Badge (Top Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          preset.badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Open Full Page Button (Top Right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _openFullPage(preset),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),

                    // Title on Image Bottom
                    Positioned(
                      bottom: 8,
                      left: 10,
                      right: 10,
                      child: Text(
                        preset.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card Bottom Actions Area
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prompt preview snippet - Tap also opens full page
                  GestureDetector(
                    onTap: () => _openFullPage(preset),
                    child: Text(
                      preset.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Row: Copy Prompt & Share Prompt
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _copyPrompt(preset),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.copy_rounded, size: 13, color: Color(0xFF475569)),
                                SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => _sharePrompt(preset),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C2CB).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.share_rounded, size: 13, color: Color(0xFF00838F)),
                                SizedBox(width: 4),
                                Text(
                                  'Share',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF00838F)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
