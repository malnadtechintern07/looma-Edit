import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/procut_slider.dart';
import '../../domain/entities/video_effect_type.dart';

class EffectsPickerSheet extends StatefulWidget {
  final VideoEffectType selectedEffect;
  final double effectIntensity;
  final double initialBlur;
  final double initialZoom;
  final int initialFadeInMs;
  final int initialFadeOutMs;
  final double initialBrightness;
  final double initialContrast;
  final double initialSaturation;
  final Function(VideoEffectType effect) onEffectSelected;
  final Function(VideoEffectType effect, double intensity)? onIntensityChanged;
  final Function({
    required double blur,
    required double zoom,
    required int fadeInMs,
    required int fadeOutMs,
    required double brightness,
    required double contrast,
    required double saturation,
  }) onEffectsChanged;

  const EffectsPickerSheet({
    super.key,
    this.selectedEffect = VideoEffectType.none,
    this.effectIntensity = 1.0,
    required this.initialBlur,
    required this.initialZoom,
    required this.initialFadeInMs,
    required this.initialFadeOutMs,
    required this.initialBrightness,
    required this.initialContrast,
    required this.initialSaturation,
    required this.onEffectSelected,
    this.onIntensityChanged,
    required this.onEffectsChanged,
  });

  @override
  State<EffectsPickerSheet> createState() => _EffectsPickerSheetState();
}

class _EffectsPickerSheetState extends State<EffectsPickerSheet> {
  late VideoEffectType _activeEffect;
  late double _intensity;
  VideoEffectCategory _selectedCategory = VideoEffectCategory.trending;
  final TextEditingController _searchController = TextEditingController();
  final Set<VideoEffectType> _downloadedEffects = {
    VideoEffectType.explosion,
    VideoEffectType.videoCam,
    VideoEffectType.rollingFilm,
    VideoEffectType.phoneDrift,
    VideoEffectType.lightningCloud,
    VideoEffectType.crossSplit,
    VideoEffectType.superLarge,
    VideoEffectType.obliqueBlur,
    VideoEffectType.edgeSilhouette,
    VideoEffectType.citySunset,
    VideoEffectType.verticalFilm,
    VideoEffectType.prismRainbow,
    VideoEffectType.flash,
    VideoEffectType.blackFlash2,
    VideoEffectType.fadeIn,
    VideoEffectType.shake,
  };
  final Set<VideoEffectType> _favoriteEffects = {};
  bool _showFavoritesOnly = false;
  bool _showAdvancedTuning = false;

  late double _blur;
  late double _zoom;
  late double _fadeInSec;
  late double _fadeOutSec;
  late double _brightness;
  late double _contrast;
  late double _saturation;

  @override
  void initState() {
    super.initState();
    _activeEffect = widget.selectedEffect;
    _intensity = widget.effectIntensity;
    _blur = widget.initialBlur;
    _zoom = widget.initialZoom;
    _fadeInSec = widget.initialFadeInMs / 1000.0;
    _fadeOutSec = widget.initialFadeOutMs / 1000.0;
    _brightness = widget.initialBrightness;
    _contrast = widget.initialContrast;
    _saturation = widget.initialSaturation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSelectEffect(VideoEffectType effect) {
    setState(() {
      _activeEffect = effect;
      _downloadedEffects.add(effect);
    });
    widget.onEffectSelected(effect);
  }

  void _notifyAdvancedChanges() {
    widget.onEffectsChanged(
      blur: _blur,
      zoom: _zoom,
      fadeInMs: (_fadeInSec * 1000).round(),
      fadeOutMs: (_fadeOutSec * 1000).round(),
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
    );
  }

  List<VideoEffectType> _getFilteredEffects() {
    final query = _searchController.text.trim().toLowerCase();
    return VideoEffectType.values.where((e) {
      if (e == VideoEffectType.none) return false;
      if (query.isNotEmpty) {
        return e.label.toLowerCase().contains(query) || e.description.toLowerCase().contains(query);
      }
      if (_showFavoritesOnly) {
        return _favoriteEffects.contains(e);
      }
      if (_selectedCategory == VideoEffectCategory.all) {
        return true;
      }
      return e.category == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEffects = _getFilteredEffects();
    final query = _searchController.text.trim();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF12131A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 1. CapCut-Style Search Bar & Checkmark Confirm Button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E202B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: Color(0xFF8E92A4)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'People are searching oblique blur, flash...',
                              hintStyle: TextStyle(color: Color(0xFF757C8E), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (query.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _searchController.clear()),
                            child: const Icon(Icons.close, size: 16, color: Color(0xFF8E92A4)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white, size: 24),
                  tooltip: 'Done',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // 2. Category Tabs (Bookmark Saved + Trending, Classic, NEW, Hits, Intro & Outro, etc.)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Bookmark / Saved icon button
                InkWell(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _showFavoritesOnly = !_showFavoritesOnly);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    margin: const EdgeInsets.only(right: 6),
                    child: Icon(
                      _showFavoritesOnly ? Icons.bookmark : Icons.bookmark_border_rounded,
                      size: 20,
                      color: _showFavoritesOnly ? const Color(0xFF00E5FF) : const Color(0xFF8E92A4),
                    ),
                  ),
                ),

                // Category items
                ...VideoEffectCategory.values.map((cat) {
                  final isSelected = !_showFavoritesOnly && _selectedCategory == cat && query.isEmpty;
                  return GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _showFavoritesOnly = false;
                        _selectedCategory = cat;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF8E92A4),
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Cyan active indicator line
                          Container(
                            height: 2.5,
                            width: isSelected ? 22 : 0,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E202B), height: 1),

          // 3. Live Intensity / Parameter Tuning Bar if effect is active
          if (_activeEffect != VideoEffectType.none)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFF181A24),
              child: Row(
                children: [
                  Icon(_activeEffect.icon, size: 16, color: const Color(0xFF00E5FF)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _activeEffect.label,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: const Color(0xFF00E5FF),
                        inactiveTrackColor: const Color(0xFF2C2F38),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: _intensity.clamp(0.0, 1.0),
                        min: 0.0,
                        max: 1.0,
                        onChanged: (v) {
                          setState(() => _intensity = v);
                          widget.onIntensityChanged?.call(_activeEffect, v);
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${(_intensity * 100).round()}%',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(
                      _showAdvancedTuning ? Icons.tune : Icons.tune_outlined,
                      size: 16,
                      color: _showAdvancedTuning ? const Color(0xFF00E5FF) : Colors.white70,
                    ),
                    tooltip: 'Fine Adjustments',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    onPressed: () => setState(() => _showAdvancedTuning = !_showAdvancedTuning),
                  ),
                ],
              ),
            ),

          // 4. Effects 4-Column Grid
          Expanded(
            child: _showAdvancedTuning
                ? _buildAdvancedTuningView()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: filteredEffects.length + 1,
                    itemBuilder: (context, index) {
                      // First item is always "None"
                      if (index == 0) {
                        final isNoneSelected = _activeEffect == VideoEffectType.none;
                        return _buildEffectCard(
                          effect: VideoEffectType.none,
                          isSelected: isNoneSelected,
                          onTap: () => _onSelectEffect(VideoEffectType.none),
                        );
                      }

                      final effect = filteredEffects[index - 1];
                      final isSelected = _activeEffect == effect;

                      return _buildEffectCard(
                        effect: effect,
                        isSelected: isSelected,
                        onTap: () => _onSelectEffect(effect),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectCard({
    required VideoEffectType effect,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isNone = effect == VideoEffectType.none;
    final isDownloaded = _downloadedEffects.contains(effect);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visual thumbnail card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF1E202B),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00E5FF) : Colors.white10,
                  width: isSelected ? 2.4 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Rich custom thumbnail visual matching CapCut
                  _buildEffectThumbnailArt(effect),

                  // Top-Left download / applied badge (matching CapCut screenshot)
                  if (!isNone)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check
                              : (isDownloaded ? Icons.download_done : Icons.arrow_downward),
                          size: 9.5,
                          color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),

          // Bottom Label
          Text(
            effect.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : const Color(0xFFA0A6B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEffectThumbnailArt(VideoEffectType effect) {
    switch (effect) {
      case VideoEffectType.none:
        return Container(
          color: const Color(0xFF1E202B),
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white60, width: 2.2),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: -0.785, // -45 deg
                  child: Container(width: 26, height: 2.2, color: Colors.white60),
                ),
              ),
            ),
          ),
        );

      case VideoEffectType.explosion:
        // Fiery golden explosion radial burst matching screenshot
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFFEA00),
                Color(0xFFFF6D00),
                Color(0xFFDD2C00),
                Color(0xFF1A0500),
              ],
              stops: [0.0, 0.25, 0.55, 0.8, 1.0],
            ),
          ),
          child: Center(
            child: Icon(Icons.local_fire_department, size: 28, color: Colors.white.withValues(alpha: 0.9)),
          ),
        );

      case VideoEffectType.videoCam:
        // City skyline with camcorder viewfinder brackets and REC dot
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF355C7D), Color(0xFF6C5B7B), Color(0xFFC06C84)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: 8, left: 8, child: _buildMiniBracket(true, true)),
              Positioned(top: 8, right: 8, child: _buildMiniBracket(false, true)),
              Positioned(bottom: 8, left: 8, child: _buildMiniBracket(true, false)),
              Positioned(bottom: 8, right: 8, child: _buildMiniBracket(false, false)),
              const Center(child: Icon(Icons.add, size: 14, color: Colors.white70)),
              Positioned(
                top: 7,
                left: 18,
                child: Row(
                  children: [
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 2),
                    const Text('REC', style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );

      case VideoEffectType.rollingFilm:
        // 35mm film strip with multiple skater frame cells and sprockets
        return Container(
          color: const Color(0xFF1C2A39),
          child: Row(
            children: [
              _buildSprocketMargin(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A6073),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Center(
                          child: Icon(Icons.directions_run, size: 16, color: Colors.white70),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C3E50),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Center(
                          child: Icon(Icons.skateboarding, size: 16, color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSprocketMargin(),
            ],
          ),
        );

      case VideoEffectType.phoneDrift:
        // Rooftop figure with tilted motion drift streaks
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Stack(
            children: [
              Transform.rotate(
                angle: -0.15,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white54, width: 1.2),
                      color: Colors.black26,
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 22, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const Positioned(
                right: 5,
                bottom: 5,
                child: Icon(Icons.speed, size: 13, color: Color(0xFF00E5FF)),
              ),
            ],
          ),
        );

      case VideoEffectType.lightningCloud:
        // Mountain with branching white lightning bolt
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1021), Color(0xFF1B2A47), Color(0xFF2A3A5E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(Icons.bolt, size: 34, color: Colors.white.withValues(alpha: 0.95)),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: _MountainClipper(),
                  child: Container(height: 20, color: const Color(0xFFE0F7FA).withValues(alpha: 0.9)),
                ),
              ),
            ],
          ),
        );

      case VideoEffectType.crossSplit:
        // 4-quadrant cross split screen
        return Container(
          color: const Color(0xFF1A1D24),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Container(color: const Color(0xFF2A5298), child: const Icon(Icons.person, size: 14, color: Colors.white70))),
                        const SizedBox(width: 2),
                        Expanded(child: Container(color: const Color(0xFF1E3C72), child: const Icon(Icons.person, size: 14, color: Colors.white70))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Container(color: const Color(0xFF1E3C72), child: const Icon(Icons.person, size: 14, color: Colors.white70))),
                        const SizedBox(width: 2),
                        Expanded(child: Container(color: const Color(0xFF2A5298), child: const Icon(Icons.person, size: 14, color: Colors.white70))),
                      ],
                    ),
                  ),
                ],
              ),
              Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.8), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case VideoEffectType.superLarge:
        // Dark night with multiple large colorful bokeh blur circles
        return Container(
          color: const Color(0xFF12131A),
          child: Stack(
            children: [
              Positioned(top: 6, left: 8, child: _buildBokehCircle(20, const Color(0xFFFF416C))),
              Positioned(top: 12, right: 10, child: _buildBokehCircle(16, const Color(0xFFFFB199))),
              Positioned(bottom: 8, left: 14, child: _buildBokehCircle(22, const Color(0xFFFF9900))),
              Positioned(bottom: 5, right: 6, child: _buildBokehCircle(24, const Color(0xFFFF3366))),
              Center(child: _buildBokehCircle(14, Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        );

      case VideoEffectType.obliqueBlur:
        // 45-degree diagonal action stripes with chromatic dispersion
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF0844),
                Color(0xFFFFB199),
                Color(0xFF00F2FE),
                Color(0xFF4FACFE),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Transform.rotate(
                  angle: 0.785,
                  child: Container(
                    width: 5,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      boxShadow: [
                        BoxShadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.blur_linear, size: 22, color: Colors.white),
              ),
            ],
          ),
        );

      case VideoEffectType.edgeSilhouette:
        // Portrait silhouette with neon pink and purple glowing edge contour
        return Container(
          color: const Color(0xFF140F2D),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.person,
                  size: 34,
                  color: const Color(0xFFFF007A).withValues(alpha: 0.8),
                ),
              ),
              Center(
                child: Container(
                  width: 40,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00F5D4), width: 1.8),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFF007A).withValues(alpha: 0.6), blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case VideoEffectType.citySunset:
        // Sunset golden hour gradient with radiant sun bloom
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2B1055), Color(0xFF7597DE), Color(0xFFFF8008), Color(0xFFFFC837)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 14,
                right: 12,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFD200).withValues(alpha: 0.9), blurRadius: 14, spreadRadius: 3),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Icon(Icons.location_city, size: 18, color: Colors.black45),
              ),
            ],
          ),
        );

      default:
        // Curated dual-gradient thumbnail card
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [effect.color1, effect.color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(effect.icon, size: 24, color: Colors.white),
          ),
        );
    }
  }

  Widget _buildMiniBracket(bool isLeft, bool isTop) {
    return SizedBox(
      width: 7,
      height: 7,
      child: CustomPaint(
        painter: _ThumbnailBracketPainter(isLeft: isLeft, isTop: isTop),
      ),
    );
  }

  Widget _buildSprocketMargin() {
    return Container(
      width: 6,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (_) => Container(
          width: 3,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(0.8),
          ),
        )),
      ),
    );
  }

  Widget _buildBokehCircle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.65),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.8),
            blurRadius: diameter * 0.4,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTuningView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Effect Parameters & Visual Tuning',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _blur = 0.0;
                    _zoom = 1.0;
                    _fadeInSec = 0.0;
                    _fadeOutSec = 0.0;
                    _brightness = 0.0;
                    _contrast = 1.0;
                    _saturation = 1.0;
                  });
                  _notifyAdvancedChanges();
                },
                child: const Text('Reset All', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Blur Sigma
          ProCutSlider(
            label: 'Gaussian Blur Radius',
            icon: Icons.blur_on,
            value: _blur,
            min: 0.0,
            max: 20.0,
            divisions: 40,
            valueFormatter: (v) => '${v.toStringAsFixed(1)}px',
            onChanged: (v) {
              setState(() => _blur = v);
              _notifyAdvancedChanges();
            },
          ),
          const SizedBox(height: 14),

          // Zoom Scale
          ProCutSlider(
            label: 'Dynamic Zoom Scale',
            icon: Icons.zoom_in,
            value: _zoom,
            min: 1.0,
            max: 3.0,
            divisions: 20,
            valueFormatter: (v) => '${v.toStringAsFixed(2)}x',
            onChanged: (v) {
              setState(() => _zoom = v);
              _notifyAdvancedChanges();
            },
          ),
          const SizedBox(height: 14),

          // Fade In
          ProCutSlider(
            label: 'Fade In Duration',
            icon: Icons.gradient,
            value: _fadeInSec,
            min: 0.0,
            max: 3.0,
            divisions: 30,
            valueFormatter: (v) => '${v.toStringAsFixed(1)}s',
            onChanged: (v) {
              setState(() => _fadeInSec = v);
              _notifyAdvancedChanges();
            },
          ),
          const SizedBox(height: 14),

          // Fade Out
          ProCutSlider(
            label: 'Fade Out Duration',
            icon: Icons.gradient,
            value: _fadeOutSec,
            min: 0.0,
            max: 3.0,
            divisions: 30,
            valueFormatter: (v) => '${v.toStringAsFixed(1)}s',
            onChanged: (v) {
              setState(() => _fadeOutSec = v);
              _notifyAdvancedChanges();
            },
          ),
          const SizedBox(height: 14),

          // Brightness
          ProCutSlider(
            label: 'Luminance Offset',
            icon: Icons.brightness_6,
            value: _brightness,
            min: -0.5,
            max: 0.5,
            divisions: 20,
            valueFormatter: (v) => (v >= 0 ? '+${v.toStringAsFixed(2)}' : v.toStringAsFixed(2)),
            onChanged: (v) {
              setState(() => _brightness = v);
              _notifyAdvancedChanges();
            },
          ),
          const SizedBox(height: 14),

          // Contrast
          ProCutSlider(
            label: 'Contrast Multiplier',
            icon: Icons.contrast,
            value: _contrast,
            min: 0.5,
            max: 2.0,
            divisions: 30,
            valueFormatter: (v) => '${v.toStringAsFixed(2)}x',
            onChanged: (v) {
              setState(() => _contrast = v);
              _notifyAdvancedChanges();
            },
          ),
          const SizedBox(height: 14),

          // Saturation
          ProCutSlider(
            label: 'Chroma Saturation',
            icon: Icons.color_lens,
            value: _saturation,
            min: 0.0,
            max: 2.5,
            divisions: 25,
            valueFormatter: (v) => '${v.toStringAsFixed(2)}x',
            onChanged: (v) {
              setState(() => _saturation = v);
              _notifyAdvancedChanges();
            },
          ),
        ],
      ),
    );
  }
}

class _ThumbnailBracketPainter extends CustomPainter {
  final bool isLeft;
  final bool isTop;
  _ThumbnailBracketPainter({required this.isLeft, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final path = Path();
    final x0 = isLeft ? size.width : 0.0;
    final x1 = isLeft ? 0.0 : size.width;
    final y0 = isTop ? size.height : 0.0;
    final y1 = isTop ? 0.0 : size.height;
    path.moveTo(x0, y1);
    path.lineTo(x1, y1);
    path.lineTo(x1, y0);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MountainClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.25, size.height * 0.35);
    path.lineTo(size.width * 0.5, size.height * 0.65);
    path.lineTo(size.width * 0.75, 0);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
