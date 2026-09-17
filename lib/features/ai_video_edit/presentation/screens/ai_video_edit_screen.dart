import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/services/app_actions_service.dart';
import '../../../projects/domain/entities/aspect_ratio_type.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../data/ai_video_presets_data.dart';
import '../../domain/entities/ai_video_preset_entity.dart';

class AiVideoEditScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const AiVideoEditScreen({super.key, this.embedded = false});

  @override
  ConsumerState<AiVideoEditScreen> createState() => _AiVideoEditScreenState();
}

class _AiVideoEditScreenState extends ConsumerState<AiVideoEditScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AiVideoPresetsData.fetchServerPresets().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AiVideoPresetEntity> get _filteredPresets {
    return AiVideoPresetsData.currentPresets.where((item) {
      final matchesCategory = _selectedCategory == 'All' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.prompt.toLowerCase().contains(q) ||
          item.modelName.toLowerCase().contains(q) ||
          item.tags.any((t) => t.toLowerCase().contains(q));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _copyPrompt(BuildContext context, AiVideoPresetEntity preset) {
    Clipboard.setData(ClipboardData(text: preset.prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Copied prompt for "${preset.title}"!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E2E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sharePrompt(BuildContext context, AiVideoPresetEntity preset) {
    AppActionsService.shareAiPrompt(
      prompt: preset.prompt,
      title: preset.title,
      category: preset.category,
    );
  }

  Future<void> _createProjectFromPreset(
    BuildContext context,
    AiVideoPresetEntity preset,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
        ),
      );

      final notifier = ref.read(projectsNotifierProvider.notifier);
      final newProj = await notifier.createProjectFromTemplate(
        title: preset.title,
        aspectRatio: AspectRatioType.ratio9_16,
        durationMs: 5000,
        clipsCount: 1,
        audioTrackTitle: 'AI Cinematic Mix',
        audioPath: 'assets/demo/cinematic_audio.wav',
        userMediaPaths: [preset.videoAssetPath],
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created video project "${preset.title}"!'),
            backgroundColor: const Color(0xFF6C5CE7),
          ),
        );
        await context.push(RoutePaths.editorPath(newProj.id));
        if (mounted) {
          ref.read(projectsNotifierProvider.notifier).loadProjects();
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create project: $e')),
        );
      }
    }
  }

  void _openDetailModal(BuildContext context, AiVideoPresetEntity preset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AiVideoDetailSheet(
        preset: preset,
        onCopy: () => _copyPrompt(context, preset),
        onShare: () => _sharePrompt(context, preset),
        onCreate: () {
          Navigator.pop(ctx);
          _createProjectFromPreset(context, preset);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredPresets;

    final content = Column(
      children: [
        // Search & Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search prompts, models (Sora, Runway...), styles...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF161824),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Categories horizontal bar
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: AiVideoPresetsData.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = AiVideoPresetsData.categories[index];
                final isSel = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSel
                          ? const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                            )
                          : null,
                      color: isSel ? null : const Color(0xFF1B1D2C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? Colors.transparent : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSel ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Presets list
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF6C5CE7),
              onRefresh: () async {
                await AiVideoPresetsData.fetchServerPresets();
                if (mounted) setState(() {});
              },
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        const Center(
                          child: Text(
                            'No AI video presets found',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return _AiVideoCard(
                          preset: item,
                          onTap: () => _openDetailModal(context, item),
                          onCopyPrompt: () => _copyPrompt(context, item),
                          onSharePrompt: () => _sharePrompt(context, item),
                          onCreate: () => _createProjectFromPreset(context, item),
                        );
                      },
                    ),
            ),
          ),
        ],
      );

    if (widget.embedded) {
      return Container(
        color: const Color(0xFF0D0E15),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0E15),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.movie_filter_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Video Edit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'Playable AI Video Generation & Prompts',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Video Card with Real Playable Video & Controls
// ---------------------------------------------------------------------------
class _AiVideoCard extends StatefulWidget {
  final AiVideoPresetEntity preset;
  final VoidCallback onTap;
  final VoidCallback onCopyPrompt;
  final VoidCallback onSharePrompt;
  final VoidCallback onCreate;

  const _AiVideoCard({
    required this.preset,
    required this.onTap,
    required this.onCopyPrompt,
    required this.onSharePrompt,
    required this.onCreate,
  });

  @override
  State<_AiVideoCard> createState() => _AiVideoCardState();
}

class _AiVideoCardState extends State<_AiVideoCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    final path = widget.preset.videoAssetPath;
    _controller = (path.startsWith('http://') || path.startsWith('https://'))
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.asset(path);
    _controller.initialize().then((_) {
      if (mounted) {
        _controller.setLooping(true);
        _controller.setVolume(_isMuted ? 0.0 : 1.0);
        _controller.play().catchError((_) {});
        setState(() => _isInitialized = true);
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playable Video Player Header
          GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _isInitialized
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            VideoPlayer(_controller),
                            // Gradient shadow on top and bottom for readability
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black54,
                                    Colors.transparent,
                                    Colors.black87,
                                  ],
                                  stops: [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: const Color(0xFF222538),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                ),

                // Top Chips (Model + Duration)
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              preset.modelName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              preset.durationText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Play/Pause and Mute Controls
                if (_isInitialized)
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            shape: const CircleBorder(),
                          ),
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed: _toggleMute,
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            shape: const CircleBorder(),
                          ),
                          icon: Icon(
                            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _togglePlay,
                        ),
                      ],
                    ),
                  ),

                // Tap to preview indicator
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fullscreen, color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Full Preview',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Body
          Padding(
            padding: const EdgeInsets.all(14),
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
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        preset.category,
                        style: const TextStyle(
                          color: Color(0xFFA29BFE),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Complete Generation Prompt box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1018),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF00CEC9), size: 13),
                          SizedBox(width: 5),
                          Text(
                            'PROMPT',
                            style: TextStyle(
                              color: Color(0xFF00CEC9),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Functional Action Buttons
                Row(
                  children: [
                    // Copy Prompt Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onCopyPrompt,
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('Copy Prompt', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Native Share Prompt Button (for ChatGPT, Sora, Gemini, Runway)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onSharePrompt,
                        icon: const Icon(Icons.share_rounded, size: 14, color: Color(0xFF00CEC9)),
                        label: const Text(
                          'Share Prompt',
                          style: TextStyle(fontSize: 11, color: Color(0xFF00CEC9)),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00CEC9),
                          side: BorderSide(color: const Color(0xFF00CEC9).withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Use/Create Button
                    ElevatedButton(
                      onPressed: widget.onCreate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.video_call_rounded, size: 16),
                          SizedBox(width: 4),
                          Text('Use', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet for Full Playback Preview, Scrubbing, & Full Prompt Inspector
// ---------------------------------------------------------------------------
class _AiVideoDetailSheet extends StatefulWidget {
  final AiVideoPresetEntity preset;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onCreate;

  const _AiVideoDetailSheet({
    required this.preset,
    required this.onCopy,
    required this.onShare,
    required this.onCreate,
  });

  @override
  State<_AiVideoDetailSheet> createState() => _AiVideoDetailSheetState();
}

class _AiVideoDetailSheetState extends State<_AiVideoDetailSheet> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    final path = widget.preset.videoAssetPath;
    _controller = (path.startsWith('http://') || path.startsWith('https://'))
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.asset(path);
    _controller.initialize().then((_) {
      if (mounted) {
        _controller.setLooping(true);
        _controller.setVolume(1.0);
        _controller.play().catchError((_) {});
        setState(() => _isInitialized = true);
      }
    }).catchError((_) {});
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF131520),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Playable Video Player with Scrubber
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isInitialized)
                      VideoPlayer(_controller)
                    else
                      const Center(
                        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                      ),

                    // Controls overlay
                    if (_isInitialized)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          color: Colors.black54,
                          child: Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {
                                  if (_controller.value.isPlaying) {
                                    _controller.pause();
                                  } else {
                                    _controller.play();
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.replay, color: Colors.white70, size: 20),
                                onPressed: () {
                                  _controller.seekTo(Duration.zero);
                                  _controller.play();
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Color(0xFF6C5CE7),
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _isMuted ? Icons.volume_off : Icons.volume_up,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isMuted = !_isMuted;
                                    _controller.setVolume(_isMuted ? 0.0 : 1.0);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Title & Model Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preset.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6C5CE7)),
                      ),
                      child: Text(
                        preset.modelName,
                        style: const TextStyle(
                          color: Color(0xFFA29BFE),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Prompt Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D2C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF00CEC9), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'AI GENERATION PROMPT',
                                style: TextStyle(
                                  color: Color(0xFF00CEC9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                                onPressed: widget.onCopy,
                                tooltip: 'Copy Prompt',
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                icon: const Icon(Icons.share, size: 16, color: Color(0xFF00CEC9)),
                                onPressed: widget.onShare,
                                tooltip: 'Share to ChatGPT, Sora, Gemini...',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        preset.prompt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Parameters Table
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D2C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CAMERA & RENDER SPECS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSpecRow('Camera Shot', preset.cameraMovement),
                      _buildSpecRow('Lighting', preset.lighting),
                      _buildSpecRow('Style Engine', preset.style),
                      _buildSpecRow('Seed', preset.seed),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Negative Prompt
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D2C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEGATIVE PROMPT',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.negativePrompt,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF131520),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share to AI Apps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00CEC9),
                      side: const BorderSide(color: Color(0xFF00CEC9)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.video_call_rounded),
                    label: const Text(
                      'Use / Create Project',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
