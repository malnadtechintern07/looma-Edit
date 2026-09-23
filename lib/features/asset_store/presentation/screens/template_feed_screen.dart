import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_actions_service.dart';
import '../../../../core/services/gallery_saver_service.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../domain/entities/store_template_entity.dart';
import 'package:procut/features/ai_video_edit/data/ai_video_presets_data.dart';
import 'package:procut/features/ai_video_edit/presentation/screens/ai_video_edit_screen.dart';
import '../providers/asset_store_provider.dart';
import '../widgets/template_media_picker_dialog.dart';

class TemplateFeedScreen extends ConsumerStatefulWidget {
  const TemplateFeedScreen({super.key});

  /// Public helper to resolve server or local media paths to bundled demo assets
  static String? resolveDemoAsset(String? path) => _TemplateVideoPlayerState.resolveDemoAsset(path);

  @override
  ConsumerState<TemplateFeedScreen> createState() => _TemplateFeedScreenState();
}

class _TemplateFeedScreenState extends ConsumerState<TemplateFeedScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _discAnimationController;
  Timer? _autoSyncTimer;
  int _currentPage = 0;
  int _selectedFeedType = 0; // 0: Video Templates, 1: AI Video
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSearchExpanded = false;

  // 25 Standard Categories + All + Saved + AI Video
  static const List<String> _categories = [
    'All',
    '✨ AI Video',
    '🔖 Saved',
    'Birthday',
    'Wedding',
    'Travel',
    'Love Story',
    'Family',
    'Friends',
    'Birthday Slideshow',
    'Cinematic',
    'Beat Sync',
    'Reels',
    'Festival',
    'Graduation',
    'Before & After',
    '80s Retro',
    'Trending',
    'Photo Memories',
    'Fashion',
    'Celebration',
    'Business',
    'Motivation',
    'Nature',
    'Food',
    'Fitness',
    'Fast Transitions',
    'Viral/Short Video',
  ];

  // Like & Save interaction states
  final Map<String, bool> _likedTemplates = {};
  final Map<String, bool> _savedTemplates = {};
  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _isDownloading = {};

  List<String> get _activeCategories {
    final templates = ref.watch(storeTemplatesFutureProvider).valueOrNull ?? [];
    final set = <String>{..._categories};
    for (final t in templates) {
      if (t.category.trim().isNotEmpty) {
        set.add(t.category.trim());
      }
    }
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Auto-sync with Admin Panel every 15 seconds
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        ref.invalidate(storeTemplatesFutureProvider);
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _discAnimationController.dispose();
    super.dispose();
  }

  Future<void> _downloadTemplateToGallery(StoreTemplateEntity tmpl) async {
    final rawVideoPath = (tmpl.previewVideoUrl != null && tmpl.previewVideoUrl!.isNotEmpty)
        ? tmpl.previewVideoUrl!
        : 'assets/demo/urban_skate.mp4';
    final videoPath = _TemplateVideoPlayerState.resolveDemoAsset(rawVideoPath) ?? rawVideoPath;

    setState(() => _isDownloading[tmpl.id] = true);

    final fileName = 'procut_template_${tmpl.id.replaceAll('-', '_')}';
    final savedPath = await GallerySaverService.saveVideoToDeviceGallery(
      sourceFilePath: videoPath,
      fileName: fileName,
    );

    if (savedPath != null) {
      ref.read(assetStoreRepositoryProvider).downloadAsset(tmpl.id).catchError((_) {});
    }

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

  void _copyTemplatePrompt(String prompt) {
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF00D2D3),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.black),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Video editing prompt copied! Ready for Sora, Kling or Runway ✨',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareTemplatePrompt(StoreTemplateEntity tmpl) async {
    await AppActionsService.shareAiPrompt(
      prompt: tmpl.prompt ?? tmpl.description,
      title: tmpl.title,
      category: 'Video Edit Template',
    );
  }

  void _onUseTemplate(StoreTemplateEntity tmpl) {
    ref.read(assetStoreRepositoryProvider).downloadAsset(tmpl.id).catchError((_) {});
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
            projectJson: tmpl.projectJson,
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 1. Top App Bar: Title, Search, Sync & Settings
          SafeArea(
            bottom: false,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 2),
                  ],
                  // Title & Badge
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D2D3).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.movie_creation_rounded, color: Color(0xFF00D2D3), size: 17),
                        ),
                        const SizedBox(width: 5),
                        const Flexible(
                          child: Text(
                            'Templates',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF084298), Color(0xFF0D6EFD)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '25 Categories',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Toggle Button
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Search',
                    icon: Icon(
                      _isSearchExpanded ? Icons.close : Icons.search,
                      color: _isSearchExpanded ? const Color(0xFF00D2D3) : Colors.white70,
                      size: 21,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearchExpanded = !_isSearchExpanded;
                        if (!_isSearchExpanded) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                  ),

                  // Manual Sync with Server Button
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Sync Server Templates',
                    icon: const Icon(Icons.sync, color: Colors.white70, size: 20),
                    onPressed: () {
                      ref.invalidate(storeTemplatesFutureProvider);
                      AiVideoPresetsData.fetchServerPresets();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF00D2D3),
                          content: Text(
                            'Synced online templates & AI presets ✨',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  // Settings Button
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                    onPressed: () {
                      try {
                        context.push(RoutePaths.settings);
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),
          ),

          // 1.5 Mode Switcher: [ 🎬 Video Templates ] vs [ ✨ AI Video Prompts ]
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF161824),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedFeedType != 0) {
                          setState(() => _selectedFeedType = 0);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: _selectedFeedType == 0
                              ? const LinearGradient(
                                  colors: [Color(0xFF00D2D3), Color(0xFF0891B2)],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie_filter_rounded,
                              size: 15,
                              color: _selectedFeedType == 0 ? Colors.black : Colors.white60,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Video Templates',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _selectedFeedType == 0 ? Colors.black : Colors.white70,
                                  fontWeight: _selectedFeedType == 0 ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedFeedType != 1) {
                          setState(() => _selectedFeedType = 1);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: _selectedFeedType == 1
                              ? const LinearGradient(
                                  colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: _selectedFeedType == 1 ? Colors.white : Colors.amberAccent,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'AI Video Prompts',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _selectedFeedType == 1 ? Colors.white : Colors.white70,
                                  fontWeight: _selectedFeedType == 1 ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Expandable Search Input (Only for Video Templates)
          if (_selectedFeedType == 0 && _isSearchExpanded)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2433),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00D2D3).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF00D2D3), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Search by title, category, tags or mood...',
                          hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close, color: Colors.white60, size: 16),
                      ),
                  ],
                ),
              ),
            ),

          // 3. Horizontal Scrollable Category Filter Bar (Only for Video Templates)
          if (_selectedFeedType == 0)
            Builder(builder: (context) {
              final activeCategories = _activeCategories;
              return Container(
                height: 44,
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: activeCategories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final cat = activeCategories[index];
                    final isSelected = _selectedCategory == cat;
                    final isAiVideoChip = cat == '✨ AI Video';

                    return GestureDetector(
                      onTap: () {
                        if (isAiVideoChip) {
                          setState(() => _selectedFeedType = 1);
                          return;
                        }
                        if (_selectedCategory != cat) {
                          setState(() {
                            _selectedCategory = cat;
                            _currentPage = 0;
                          });
                          if (_pageController.hasClients) {
                            _pageController.jumpToPage(0);
                          }
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF00D2D3), Color(0xFF0891B2)],
                                )
                              : (isAiVideoChip
                                  ? const LinearGradient(
                                      colors: [Color(0xFF8A2387), Color(0xFFE94057)],
                                    )
                                  : null),
                          color: isSelected ? null : (isAiVideoChip ? null : const Color(0xFF1E2433)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isAiVideoChip ? const Color(0xFFE94057) : Colors.white12),
                            width: 1,
                          ),
                          boxShadow: isSelected || isAiVideoChip
                              ? [
                                  BoxShadow(
                                    color: (isAiVideoChip
                                            ? const Color(0xFFE94057)
                                            : const Color(0xFF00D2D3))
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected || isAiVideoChip
                                  ? FontWeight.w900
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

          const SizedBox(height: 2),

          // 4. Main Template Vertical Feed OR AI Video Edit Screen
          Expanded(
            child: _selectedFeedType == 0
                ? _buildTemplatesVideoFeed()
                : const AiVideoEditScreen(embedded: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesVideoFeed() {
    final templatesAsync = ref.watch(storeTemplatesFutureProvider);

    return RefreshIndicator(
      color: const Color(0xFF00D2D3),
      backgroundColor: const Color(0xFF1E2433),
      onRefresh: () async {
        ref.invalidate(storeTemplatesFutureProvider);
        await ref.read(storeTemplatesFutureProvider.future);
      },
      child: templatesAsync.when(
        data: (allTemplates) {
          if (allTemplates.isEmpty) {
            return const Center(
              child: Text('No templates available', style: TextStyle(color: Colors.white)),
            );
          }

        // Apply Category & Search Filter
        final templates = allTemplates.where((t) {
          // 0. Saved templates special filter
          if (_selectedCategory == '🔖 Saved') {
            return _savedTemplates[t.id] == true;
          }
          // 1. Category check
          final matchesCategory = _selectedCategory == 'All' ||
              t.category.toLowerCase() == _selectedCategory.toLowerCase() ||
              t.tags.any((tag) => tag.toLowerCase() == _selectedCategory.toLowerCase());
          if (!matchesCategory) return false;

          // 2. Search check
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.author.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q) ||
              t.tags.any((tag) => tag.toLowerCase().contains(q));
        }).toList();

        if (templates.isEmpty) {
          // Special empty state for Saved templates
          if (_selectedCategory == '🔖 Saved') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2433),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00D2D3).withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.bookmark_border_rounded, size: 48, color: Color(0xFF00D2D3)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Saved Templates Yet',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the bookmark icon on any template\nto save it here for quick access.',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _selectedCategory = 'All');
                    },
                    icon: const Icon(Icons.explore_outlined, color: Color(0xFF00D2D3)),
                    label: const Text('Browse Templates', style: TextStyle(color: Color(0xFF00D2D3))),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.white38),
                const SizedBox(height: 12),
                Text(
                  'No templates in "$_selectedCategory"${_searchQuery.isNotEmpty ? ' matching "$_searchQuery"' : ''}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedCategory = 'All';
                      _searchQuery = '';
                    });
                  },
                  child: const Text('Show All Templates', style: TextStyle(color: Color(0xFF00D2D3))),
                ),
              ],
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-Screen Vertical Swipe Feed PageView
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: templates.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final tmpl = templates[index];
                return _buildTemplateFeedPage(
                  tmpl,
                  isCurrent: index == _currentPage,
                );
              },
            ),

            // 2. Floating Category Indicator on Top Left
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.category_outlined, size: 12, color: Color(0xFF00D2D3)),
                    const SizedBox(width: 5),
                    Text(
                      _selectedCategory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2D3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${templates.length}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildTemplateFeedPage(StoreTemplateEntity tmpl, {required bool isCurrent}) {
    final isLiked = _likedTemplates[tmpl.id] ?? false;
    final isSaved = _savedTemplates[tmpl.id] ?? false;
    final likesCount = _likeCounts[tmpl.id] ?? (tmpl.downloadsCount ~/ 1.4);
    final isDownloading = _isDownloading[tmpl.id] ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 9:16 Full Screen Live Video & Audio Player
        Positioned.fill(
          child: _TemplateVideoPlayer(
            key: ValueKey(tmpl.id),
            template: tmpl,
            isCurrent: isCurrent,
          ),
        ),

        // Dark Vignette Gradient Overlays for Text Contrast
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
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
          ),
        ),

        // Right Vertical Interaction Action Bar
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
                        colors: [AppColors.primary, Color(0xFF00D2D3)],
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

              // Direct Download to Gallery Button
              GestureDetector(
                onTap: isDownloading ? null : () => _downloadTemplateToGallery(tmpl),
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

              // Animated Rotating Music Vinyl Disc Icon
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

        // Bottom Left Overlay & Floating "Use template" CTA Button
        Positioned(
          left: 16,
          right: 16,
          bottom: 36,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Pill + Badge + PRO Tag
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Category Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2D3).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00D2D3)),
                    ),
                    child: Text(
                      tmpl.category,
                      style: const TextStyle(
                        color: Color(0xFF00D2D3),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  // Custom Badge if present
                  if (tmpl.badge != null && tmpl.badge!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        tmpl.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Trending flag
                  if (tmpl.isTrending)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Text(
                        '🔥 Trending',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),

                  // PRO Badge
                  if (tmpl.isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.black, size: 10),
                          SizedBox(width: 2),
                          Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Template Title
              Text(
                tmpl.title,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),

              // Description
              if (tmpl.description.isNotEmpty)
                Text(
                  tmpl.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              const SizedBox(height: 6),

              // Metadata Row: 🕒 Duration | 🎞️ Clips | Audio Title
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
                      '${tmpl.clipsCount} clips',
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
                      child: Row(
                        children: [
                          const Icon(Icons.music_note, color: Color(0xFF00D2D3), size: 11),
                          const SizedBox(width: 4),
                          Text(
                            tmpl.audioTrackTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Video Editing Prompt Banner
              if (tmpl.prompt != null && tmpl.prompt!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00D2D3).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFF00D2D3), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'VIDEO EDITING PROMPT',
                                style: AppTypography.labelSmall.copyWith(
                                   color: const Color(0xFF00D2D3),
                                   fontWeight: FontWeight.w900,
                                   fontSize: 10,
                                   letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _copyTemplatePrompt(tmpl.prompt!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.copy, color: Colors.white, size: 10),
                                      SizedBox(width: 3),
                                      Text('Copy', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _shareTemplatePrompt(tmpl),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.share, color: Colors.white, size: 10),
                                      SizedBox(width: 3),
                                      Text('Share', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tmpl.prompt!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.3,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Prominent Cyan/Teal "Use template" CTA Button
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
                  // Direct Download to Phone Gallery Icon Button
                  InkWell(
                    onTap: isDownloading ? null : () => _downloadTemplateToGallery(tmpl),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Center(
                        child: isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00D2D3),
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 24,
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
    );
  }
}

/// Helper full-screen vertical swipe video player widget
class _TemplateVideoPlayer extends StatefulWidget {
  final StoreTemplateEntity template;
  final bool isCurrent;

  const _TemplateVideoPlayer({
    super.key,
    required this.template,
    required this.isCurrent,
  });

  @override
  State<_TemplateVideoPlayer> createState() => _TemplateVideoPlayerState();
}

class _TemplateVideoPlayerState extends State<_TemplateVideoPlayer> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _showIndicator = false;
  bool _isBuffering = false;
  bool _networkFailed = false;

  /// Resolves any server/local path to the bundled asset file if it exists.
  /// Resolves any server/local path to the bundled asset file if it exists.
  static String? resolveDemoAsset(String? path) {
    if (path == null || path.isEmpty) return null;
    final normalized = path.replaceAll('\\', '/');
    final filename = normalized.split('/').last.split('?').first.trim();
    if (filename.isEmpty) return null;

    const demoAssets = {
      // ── Audio only (real .wav files, valid for playback) ──────────────
      'tropical_beat.wav': 'assets/demo/tropical_beat.wav',
      'phonk_beat.wav': 'assets/demo/phonk_beat.wav',
      'synthwave_beat.wav': 'assets/demo/synthwave_beat.wav',
      'urban_trap.wav': 'assets/demo/urban_trap.wav',
      'lofi_beat.wav': 'assets/demo/lofi_beat.wav',
      'cinematic_audio.wav': 'assets/demo/cinematic_audio.wav',
      // ── Videos (real .mp4 files, valid for playback) ──────────────────
      'urban_skate.mp4': 'assets/demo/urban_skate.mp4',
      'alps_sunrise.mp4': 'assets/demo/alps_sunrise.mp4',
      'alps_drone.mp4': 'assets/demo/alps_drone.mp4',
      'cyberpunk_arcade.mp4': 'assets/demo/cyberpunk_arcade.mp4',
      'ramen_bar.mp4': 'assets/demo/ramen_bar.mp4',
      'tokyo_shinjuku.mp4': 'assets/demo/tokyo_shinjuku.mp4',
      'tokyo_street.mp4': 'assets/demo/tokyo_street.mp4',
      'overlay_vid.mp4': 'assets/demo/overlay_vid.mp4',
      // ── Images only (real .jpg files, valid for display) ──────────────
      'tmpl-cinematic-youtube.jpg': 'assets/demo/tmpl-cinematic-youtube.jpg',
      'tmpl-golden-hour.jpg': 'assets/demo/tmpl-golden-hour.jpg',
      'tmpl-hype-reel.jpg': 'assets/demo/tmpl-hype-reel.jpg',
      'tmpl-retro-90s.jpg': 'assets/demo/tmpl-retro-90s.jpg',
      'tmpl-summer-tropical.jpg': 'assets/demo/tmpl-summer-tropical.jpg',
      'tmpl-urban-street.jpg': 'assets/demo/tmpl-urban-street.jpg',
      'tmpl-viral-phonk.jpg': 'assets/demo/tmpl-viral-phonk.jpg',
      'tmpl-vlog-minimal.jpg': 'assets/demo/tmpl-vlog-minimal.jpg',
      'sunset_beach.jpg': 'assets/demo/sunset_beach.jpg',
      'ai_3d_render.jpg': 'assets/demo/ai_3d_render.jpg',
      'ai_80s_synthwave.jpg': 'assets/demo/ai_80s_synthwave.jpg',
      'ai_anime_art.jpg': 'assets/demo/ai_anime_art.jpg',
      'ai_cyberpunk_neon.jpg': 'assets/demo/ai_cyberpunk_neon.jpg',
    };

    return demoAssets[filename];
  }

  /// Returns a category-specific and theme-specific video asset so every template is unique!
  static String getDefaultAssetForTemplate(StoreTemplateEntity template) {
    final cat = template.category.toLowerCase();
    final id = template.id.toLowerCase();

    // Specific template IDs mapping to unique videos
    if (id == 'tmpl-birthday' || id == 'tmpl-birthday-slideshow') {
      return 'assets/demo/overlay_vid.mp4';
    }
    if (id == 'tmpl-wedding' || id == 'tmpl-love-story' || id == 'tmpl-photo-memories' || id == 'tmpl-sunset-acoustic' || id == 'tmpl-sample-3') {
      return 'assets/demo/alps_sunrise.mp4';
    }
    if (id == 'tmpl-travel' || id == 'tmpl-nature' || id == 'tmpl-ocean-dive') {
      return 'assets/demo/alps_drone.mp4';
    }
    if (id == 'tmpl-cinematic' || id == 'tmpl-80s-retro' || id == 'tmpl-sample-5' || id == 'tmpl-gaming-stream') {
      return 'assets/demo/cyberpunk_arcade.mp4';
    }
    if (id == 'tmpl-family' || id == 'tmpl-food' || id == 'tmpl-sample-1' || id == 'tmpl-vlog-daily') {
      return 'assets/demo/ramen_bar.mp4';
    }
    if (id == 'tmpl-friends' || id == 'tmpl-festival' || id == 'tmpl-celebration' || id == 'tmpl-sample-4') {
      return 'assets/demo/tokyo_shinjuku.mp4';
    }
    if (id == 'tmpl-before-after' || id == 'tmpl-motivation' || id == 'tmpl-fast-transitions' || id == 'tmpl-sample-2' || id == 'tmpl-cyber-neon') {
      return 'assets/demo/tokyo_street.mp4';
    }
    if (id == 'tmpl-reels' || id == 'tmpl-fashion') {
      return 'assets/demo/alps_sunrise.mp4';
    }
    if (id == 'tmpl-business' || id == 'tmpl-graduation') {
      return 'assets/demo/cyberpunk_arcade.mp4';
    }
    if (id == 'tmpl-fitness' || id == 'tmpl-beat-sync' || id == 'tmpl-trending' || id == 'tmpl-viral-short') {
      return 'assets/demo/urban_skate.mp4';
    }

    // Category based mapping
    if (cat.contains('wedding') || cat.contains('love') || cat.contains('photo') || cat.contains('acoustic')) {
      return 'assets/demo/alps_sunrise.mp4'; // Flower blooming / romance
    }
    if (cat.contains('cinematic') || cat.contains('retro') || cat.contains('tech') || cat.contains('80s') || cat.contains('gaming')) {
      return 'assets/demo/cyberpunk_arcade.mp4'; // Sintel 1080p Action
    }
    if (cat.contains('travel') || cat.contains('nature') || cat.contains('ocean')) {
      return 'assets/demo/alps_drone.mp4'; // Underwater Jellyfish / Nature
    }
    if (cat.contains('music') || cat.contains('party') || cat.contains('dance') || cat.contains('festival') || cat.contains('celebration')) {
      return 'assets/demo/tokyo_shinjuku.mp4'; // Concert stage performance
    }
    if (cat.contains('car') || cat.contains('drive') || cat.contains('transition') || cat.contains('motivation') || cat.contains('speed')) {
      return 'assets/demo/tokyo_street.mp4'; // Highway speed car drive
    }
    if (cat.contains('food') || cat.contains('family') || cat.contains('sweet') || cat.contains('vlog') || cat.contains('pet')) {
      return 'assets/demo/ramen_bar.mp4'; // Playful corgi / pet lifestyle
    }
    if (cat.contains('birthday') || cat.contains('slideshow')) {
      return 'assets/demo/overlay_vid.mp4'; // Friday celebration animation
    }
    if (cat.contains('fashion') || cat.contains('runway') || cat.contains('lookbook')) {
      return 'assets/demo/alps_sunrise.mp4';
    }
    return 'assets/demo/urban_skate.mp4'; // Big Buck Bunny / Viral
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final rawPath = widget.template.previewVideoUrl ?? '';
    final filename = rawPath.replaceAll('\\', '/').split('/').last.split('?').first.trim();
    final demoAsset = resolveDemoAsset(filename) ?? resolveDemoAsset(rawPath);

    // If local demo asset is found, play it immediately
    if (demoAsset != null) {
      await _initLocalVideo(demoAsset);
    } else if (rawPath.contains('free.nf')) {
      await _initLocalVideo(getDefaultAssetForTemplate(widget.template));
    } else if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      await _initNetworkVideo(rawPath);
    } else {
      await _initLocalVideo(getDefaultAssetForTemplate(widget.template));
    }

    _initAudio();
  }

  /// Plays a real network/CDN video with buffering indicator and graceful fallback.
  Future<void> _initNetworkVideo(String url) async {
    if (mounted) setState(() => _isBuffering = true);
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      // Listen for buffering state changes
      _videoController!.addListener(_onVideoUpdate);

      // 8 second timeout — enough for CDN videos
      await _videoController!.initialize().timeout(const Duration(seconds: 8));
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(1.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isBuffering = false;
          _networkFailed = false;
        });
      }

      if (widget.isCurrent && mounted && _isPlaying) {
        await _videoController!.play();
      }
    } catch (e) {
      debugPrint('Network video init failed ($url): $e — falling back to template-specific asset');
      _videoController?.removeListener(_onVideoUpdate);
      await _videoController?.dispose();
      _videoController = null;
      // Fallback immediately to this template's category-matching video
      await _initLocalVideo(getDefaultAssetForTemplate(widget.template));
    }
  }

  /// Plays a local/bundled demo asset video.
  Future<void> _initLocalVideo(String rawPath) async {
    final String effectivePath = rawPath.isEmpty ? '' : rawPath;
    final demoAsset = resolveDemoAsset(effectivePath);

    String targetAsset;
    if (demoAsset != null) {
      targetAsset = demoAsset;
    } else if (effectivePath.startsWith('assets/')) {
      targetAsset = effectivePath;
    } else {
      targetAsset = getDefaultAssetForTemplate(widget.template);
    }

    try {
      _videoController = VideoPlayerController.asset(targetAsset);
      await _videoController!.initialize().timeout(const Duration(seconds: 6));
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(1.0);
      _videoController!.addListener(_onVideoUpdate);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isBuffering = false;
          _networkFailed = false;
        });
      }

      if (widget.isCurrent && mounted && _isPlaying) {
        await _videoController!.play();
      }
    } catch (e) {
      debugPrint('Local video init error ($targetAsset): $e');
      _videoController?.removeListener(_onVideoUpdate);
      await _videoController?.dispose();
      _videoController = null;
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _networkFailed = true;
        });
      }
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _initAudio() async {
    final rawAudio = widget.template.audioPath;
    if (rawAudio.isEmpty) return;

    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);

      final filename = rawAudio.replaceAll('\\', '/').split('/').last.split('?').first.trim();
      final demoAudio = resolveDemoAsset(filename) ?? resolveDemoAsset(rawAudio);
      Source source;
      if (demoAudio != null) {
        source = AssetSource(demoAudio.replaceFirst('assets/', ''));
      } else if (rawAudio.startsWith('assets/')) {
        source = AssetSource(rawAudio.replaceFirst('assets/', ''));
      } else if (rawAudio.contains('free.nf')) {
        source = AssetSource('demo/tropical_beat.wav');
      } else if (rawAudio.startsWith('http://') || rawAudio.startsWith('https://')) {
        source = UrlSource(rawAudio);
      } else if (File(rawAudio).existsSync()) {
        source = DeviceFileSource(rawAudio);
      } else {
        source = AssetSource('demo/tropical_beat.wav');
      }

      if (widget.isCurrent && mounted && _isPlaying) {
        await _audioPlayer!.play(source);
      }
    } catch (e) {
      debugPrint('Template audio init error ($rawAudio): $e');
    }
  }

  @override
  void didUpdateWidget(_TemplateVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent != oldWidget.isCurrent) {
      if (widget.isCurrent) {
        if (_isPlaying) {
          _videoController?.play();
          _audioPlayer?.resume();
        }
      } else {
        _videoController?.pause();
        _audioPlayer?.pause();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.pause();
    _videoController?.dispose();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      _showIndicator = true;
    });

    if (_isPlaying) {
      _videoController?.play();
      _audioPlayer?.resume();
    } else {
      _videoController?.pause();
      _audioPlayer?.pause();
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _showIndicator = false);
      }
    });
  }

  Widget _buildPosterFallback() {
    final posterUrl = widget.template.previewImageUrl;
    final demoImg = resolveDemoAsset(posterUrl);
    final startColorInt = int.tryParse(widget.template.previewGradientStart) ?? 0xFF1E1B4B;
    final endColorInt = int.tryParse(widget.template.previewGradientEnd) ?? 0xFF0F172A;

    Widget imageWidget;
    if (demoImg != null) {
      imageWidget = Image.asset(
        demoImg,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderGraphic(),
      );
    } else if (posterUrl != null && (posterUrl.startsWith('http://') || posterUrl.startsWith('https://'))) {
      imageWidget = Image.network(
        posterUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderGraphic(),
      );
    } else if (posterUrl != null && posterUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        posterUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderGraphic(),
      );
    } else {
      imageWidget = Image.asset(
        'assets/demo/tmpl-golden-hour.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderGraphic(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(startColorInt), Color(endColorInt)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: imageWidget,
    );
  }

  Widget _buildPlaceholderGraphic() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00D2D3).withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFF00D2D3), width: 2),
            ),
            child: const Icon(Icons.movie_filter, color: Color(0xFF00D2D3), size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            widget.template.title,
            style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _isInitialized &&
        _videoController != null &&
        _videoController!.value.isInitialized;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _networkFailed ? null : _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base poster image (always present while buffering or as network-fail fallback)
          Positioned.fill(child: _buildPosterFallback()),

          // Live video canvas fitted full cover 9:16
          if (isReady)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _videoController!.value.size.width > 0
                      ? _videoController!.value.size.width
                      : 1080,
                  height: _videoController!.value.size.height > 0
                      ? _videoController!.value.size.height
                      : 1920,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),

          // Buffering spinner shown while network video loads
          if (_isBuffering && !isReady)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF00D2D3),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Loading video…',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Central animated Play / Pause pulse indicator
          if (!_isBuffering && (_showIndicator || !_isPlaying))
            Center(
              child: AnimatedOpacity(
                opacity: (!_isPlaying || _showIndicator) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
