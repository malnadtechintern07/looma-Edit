import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/gallery_saver_service.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../domain/entities/store_template_entity.dart';
import '../providers/asset_store_provider.dart';
import '../widgets/template_media_picker_dialog.dart';

class TemplateFeedScreen extends ConsumerStatefulWidget {
  const TemplateFeedScreen({super.key});

  @override
  ConsumerState<TemplateFeedScreen> createState() => _TemplateFeedScreenState();
}

class _TemplateFeedScreenState extends ConsumerState<TemplateFeedScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _searchController =
      TextEditingController(text: 'slow motion template');
  late AnimationController _discAnimationController;

  // Like & Save interaction states
  final Map<String, bool> _likedTemplates = {};
  final Map<String, bool> _savedTemplates = {};
  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _discAnimationController.dispose();
    super.dispose();
  }

  Future<void> _downloadTemplateToGallery(StoreTemplateEntity tmpl, String previewPath) async {
    setState(() => _isDownloading[tmpl.id] = true);

    final fileName = 'looma_template_${tmpl.id.replaceAll('-', '_')}';
    final savedPath = await GallerySaverService.saveVideoToDeviceGallery(
      sourceFilePath: previewPath,
      fileName: fileName,
    );

    if (mounted) {
      setState(() => _isDownloading[tmpl.id] = false);

      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Template Video Saved to Gallery!\n$savedPath',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to save template video to Gallery'),
          ),
        );
      }
    }
  }

  void _onUseTemplate(StoreTemplateEntity tmpl) {
    showDialog(
      context: context,
      builder: (dialogCtx) => TemplateMediaPickerDialog(
        template: tmpl,
        onConfirm: (userPaths) async {
          final notifier = ref.read(projectsNotifierProvider.notifier);
          final proj = await notifier.createProjectFromTemplate(
            title: tmpl.title,
            aspectRatio: tmpl.aspectRatio,
            durationMs: tmpl.durationMs,
            clipsCount: tmpl.clipsCount,
            audioTrackTitle: tmpl.audioTrackTitle,
            audioPath: tmpl.audioPath,
            userMediaPaths: userPaths,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Created video from "${tmpl.title}"!')),
            );
            await context.push(RoutePaths.editorPath(proj.id));
            if (mounted) {
              ref.read(projectsNotifierProvider.notifier).loadProjects();
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(storeTemplatesFutureProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(
              child: Text('No templates available', style: TextStyle(color: Colors.white)),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full-Screen Vertical Swipe Feed PageView
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final tmpl = templates[index];
                  return _buildTemplateFeedPage(tmpl);
                },
              ),

              // 2. Top Header Search & AutoCut Overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    if (context.canPop()) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // AutoCut Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.video_camera_back, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'AutoCut',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.bolt, color: Colors.amber, size: 14),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Top Search Bar
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'Search templates...',
                                  hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ),
                            const Icon(Icons.search, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D2D3)),
        ),
        error: (err, _) => Center(
          child: Text('Error loading templates: $err', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildTemplateFeedPage(StoreTemplateEntity tmpl) {
    final startColorInt = int.tryParse(tmpl.previewGradientStart) ?? 0xFF8B5CF6;
    final endColorInt = int.tryParse(tmpl.previewGradientEnd) ?? 0xFF06B6D4;
    final isLiked = _likedTemplates[tmpl.id] ?? false;
    final isSaved = _savedTemplates[tmpl.id] ?? false;
    final likesCount = _likeCounts[tmpl.id] ?? (tmpl.downloadsCount ~/ 1.4);
    final isDownloading = _isDownloading[tmpl.id] ?? false;

    final demoSampleAssets = [
      'assets/demo/alps_sunrise.mp4',
      'assets/demo/tokyo_shinjuku.mp4',
      'assets/demo/cyberpunk_arcade.mp4',
      'assets/demo/sunset_beach.jpg',
      'assets/demo/urban_skate.mp4',
    ];
    final previewPath = demoSampleAssets[tmpl.id.hashCode.abs() % demoSampleAssets.length];

    return Stack(
      fit: StackFit.expand,
      children: [
        // 9:16 Full Screen Vertical Video Canvas
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(startColorInt), Color(endColorInt)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (previewPath.startsWith('assets/'))
                  Image.asset(
                    previewPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildCanvasFallback(tmpl),
                  )
                else if (File(previewPath).existsSync())
                  Image.file(
                    File(previewPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildCanvasFallback(tmpl),
                  )
                else
                  _buildCanvasFallback(tmpl),

                // Dark Vignette Gradient Overlays for Text Contrast
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Vertical Interaction Action Bar (Avatar, Heart, Comment, Bookmark, Download, Music Disc)
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              // Author Avatar with + Badge
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B4DFB), Color(0xFF00D2D3)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 26),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D2D3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Like Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _likedTemplates[tmpl.id] = !isLiked;
                    _likeCounts[tmpl.id] = isLiked ? likesCount - 1 : likesCount + 1;
                  });
                },
                child: Column(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? const Color(0xFFFF3B5C) : Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(likesCount / 1000).toStringAsFixed(1)}K',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Comment Button
              Column(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30),
                  const SizedBox(height: 4),
                  Text(
                    '105',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Bookmark / Save Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _savedTemplates[tmpl.id] = !isSaved;
                  });
                },
                child: Column(
                  children: [
                    Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? const Color(0xFFFFB800) : Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '33.9K',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Direct Download to Gallery Button 📥
              GestureDetector(
                onTap: isDownloading ? null : () => _downloadTemplateToGallery(tmpl, previewPath),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00D2D3), width: 1.5),
                      ),
                      child: isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00D2D3),
                              ),
                            )
                          : const Icon(
                              Icons.download_rounded,
                              color: Color(0xFF00D2D3),
                              size: 22,
                            ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Animated Rotating Music Vinyl Disc Icon 🎵
              RotationTransition(
                turns: _discAnimationController,
                child: Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.8),
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1E293B),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Left Overlay (Edit template label, Author, Metadata) & Floating "Use template" CTA Button
        Positioned(
          left: 16,
          right: 16,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit template tag
              Text(
                'Edit template',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),

              // Author handle with emoji
              Row(
                children: [
                  Text(
                    '@${tmpl.author.replaceAll(' ', '')}🎀',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Metadata Row: 🕒 00:12 | 🎞️ 5 | ✔ Commercial use for TikTok
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '00:${(tmpl.durationMs ~/ 1000).toString().padLeft(2, '0')}',
                      style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.grid_view, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${tmpl.clipsCount}',
                      style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF00D2D3), size: 11),
                          SizedBox(width: 4),
                          Text(
                            'Commercial use for TikTok',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Prominent Cyan/Teal "Use template" CTA Button + Camera Record Badge
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _onUseTemplate(tmpl),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D2D3),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D2D3).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Use template',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Direct Gallery Download Button
                  InkWell(
                    onTap: isDownloading ? null : () => _downloadTemplateToGallery(tmpl, previewPath),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Center(
                        child: isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download_for_offline, color: Color(0xFF00D2D3), size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCanvasFallback(StoreTemplateEntity tmpl) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF020617)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D2D3).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFF00D2D3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D2D3).withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.movie_filter, color: Color(0xFF00D2D3), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              tmpl.title,
              style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note, color: Color(0xFF00D2D3), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    tmpl.audioTrackTitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
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
