import 'package:flutter/material.dart';
import '../../domain/entities/clip_animation_type.dart';
import '../../domain/entities/video_clip_entity.dart';

class ClipAnimationSheet extends StatefulWidget {
  final VideoClipEntity clip;
  final ValueChanged<ClipAnimationIn> onAnimationInChanged;
  final ValueChanged<int> onAnimationInDurationChanged;
  final ValueChanged<ClipAnimationOut> onAnimationOutChanged;
  final ValueChanged<int> onAnimationOutDurationChanged;
  final ValueChanged<ClipAnimationCombo> onAnimationComboChanged;

  const ClipAnimationSheet({
    super.key,
    required this.clip,
    required this.onAnimationInChanged,
    required this.onAnimationInDurationChanged,
    required this.onAnimationOutChanged,
    required this.onAnimationOutDurationChanged,
    required this.onAnimationComboChanged,
  });

  @override
  State<ClipAnimationSheet> createState() => _ClipAnimationSheetState();
}

class _ClipAnimationSheetState extends State<ClipAnimationSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ClipAnimationIn _animIn;
  late int _animInDur;
  late ClipAnimationOut _animOut;
  late int _animOutDur;
  late ClipAnimationCombo _animCombo;
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _downloaded = {'fadeIn', 'slideInLeft', 'zoomIn', 'popIn', 'fadeOut', 'pulse', 'shake'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animIn = widget.clip.animationIn;
    _animInDur = widget.clip.animationInDurationMs;
    _animOut = widget.clip.animationOut;
    _animOutDur = widget.clip.animationOutDurationMs;
    _animCombo = widget.clip.animationCombo;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

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
                              hintText: 'Search animations (zoom, slide, fade)...',
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

          // 2. Category Tabs: IN / OUT / COMBO with Cyan Underline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00E5FF),
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF8E92A4),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13.5),
              tabs: const [
                Tab(text: 'IN'),
                Tab(text: 'OUT'),
                Tab(text: 'COMBO'),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E202B), height: 1),

          // 3. Tab Views: 4-Column Grid with CapCut Cards
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInTab(query),
                _buildOutTab(query),
                _buildComboTab(query),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInTab(String query) {
    final filtered = ClipAnimationIn.values.where((a) {
      if (query.isEmpty) return true;
      return a.label.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        if (_animIn != ClipAnimationIn.none)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF181A24),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF00E5FF)),
                const SizedBox(width: 6),
                const Text(
                  'IN Duration',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                      value: _animInDur.toDouble().clamp(200.0, 3000.0),
                      min: 200.0,
                      max: 3000.0,
                      onChanged: (val) {
                        setState(() => _animInDur = val.toInt());
                        widget.onAnimationInDurationChanged(val.toInt());
                      },
                    ),
                  ),
                ),
                Text(
                  '${(_animInDur / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final a = filtered[i];
              final isNone = a == ClipAnimationIn.none;
              final isSel = _animIn == a;
              final isDownloaded = _downloaded.contains(a.name);

              return _buildAnimationCard(
                label: a.label,
                icon: a.icon,
                color1: a.color1,
                color2: a.color2,
                isNone: isNone,
                isSelected: isSel,
                isDownloaded: isDownloaded,
                onTap: () {
                  setState(() {
                    _animIn = a;
                    _downloaded.add(a.name);
                  });
                  widget.onAnimationInChanged(a);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOutTab(String query) {
    final filtered = ClipAnimationOut.values.where((a) {
      if (query.isEmpty) return true;
      return a.label.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        if (_animOut != ClipAnimationOut.none)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF181A24),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF00E5FF)),
                const SizedBox(width: 6),
                const Text(
                  'OUT Duration',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                      value: _animOutDur.toDouble().clamp(200.0, 3000.0),
                      min: 200.0,
                      max: 3000.0,
                      onChanged: (val) {
                        setState(() => _animOutDur = val.toInt());
                        widget.onAnimationOutDurationChanged(val.toInt());
                      },
                    ),
                  ),
                ),
                Text(
                  '${(_animOutDur / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final a = filtered[i];
              final isNone = a == ClipAnimationOut.none;
              final isSel = _animOut == a;
              final isDownloaded = _downloaded.contains(a.name);

              return _buildAnimationCard(
                label: a.label,
                icon: a.icon,
                color1: a.color1,
                color2: a.color2,
                isNone: isNone,
                isSelected: isSel,
                isDownloaded: isDownloaded,
                onTap: () {
                  setState(() {
                    _animOut = a;
                    _downloaded.add(a.name);
                  });
                  widget.onAnimationOutChanged(a);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComboTab(String query) {
    final filtered = ClipAnimationCombo.values.where((a) {
      if (query.isEmpty) return true;
      return a.label.toLowerCase().contains(query);
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final a = filtered[i];
        final isNone = a == ClipAnimationCombo.none;
        final isSel = _animCombo == a;
        final isDownloaded = _downloaded.contains(a.name);

        return _buildAnimationCard(
          label: a.label,
          icon: a.icon,
          color1: a.color1,
          color2: a.color2,
          isNone: isNone,
          isSelected: isSel,
          isDownloaded: isDownloaded,
          onTap: () {
            setState(() {
              _animCombo = a;
              _downloaded.add(a.name);
            });
            widget.onAnimationComboChanged(a);
          },
        );
      },
    );
  }

  Widget _buildAnimationCard({
    required String label,
    required IconData icon,
    required Color color1,
    required Color color2,
    required bool isNone,
    required bool isSelected,
    required bool isDownloaded,
    required VoidCallback onTap,
  }) {
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
                gradient: isNone
                    ? null
                    : LinearGradient(
                        colors: [color1, color2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isNone ? const Color(0xFF1E202B) : null,
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
                  Center(
                    child: isNone
                        ? const Icon(Icons.block, size: 30, color: Colors.white70)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: 24, color: Colors.white),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  label.split(' ')[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Download / applied corner badge
                  if (!isNone)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check
                              : (isDownloaded ? Icons.download_done : Icons.arrow_downward),
                          size: 9,
                          color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Label
          Text(
            label,
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
}
