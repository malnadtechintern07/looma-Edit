import 'package:flutter/material.dart';
import '../../domain/entities/clip_animation_type.dart';

class AnimationPickerSheet extends StatefulWidget {
  final ClipAnimationCombo selectedAnimation;
  final int initialDurationMs;
  final Function(ClipAnimationCombo animation, int durationMs) onAnimationSelected;

  const AnimationPickerSheet({
    super.key,
    this.selectedAnimation = ClipAnimationCombo.pulse,
    this.initialDurationMs = 2000,
    required this.onAnimationSelected,
  });

  @override
  State<AnimationPickerSheet> createState() => _AnimationPickerSheetState();
}

class _AnimationPickerSheetState extends State<AnimationPickerSheet> {
  late ClipAnimationCombo _activeAnimation;
  late int _durationMs;
  final TextEditingController _searchController = TextEditingController();

  final List<ClipAnimationCombo> _allAnimations = [
    ClipAnimationCombo.pulse,
    ClipAnimationCombo.zoomRotate,
    ClipAnimationCombo.shake,
    ClipAnimationCombo.bounce,
    ClipAnimationCombo.floating,
    ClipAnimationCombo.heartbeat,
    ClipAnimationCombo.sway,
    ClipAnimationCombo.pendulum,
    ClipAnimationCombo.wobble,
    ClipAnimationCombo.flashBeat,
    ClipAnimationCombo.spin360,
    ClipAnimationCombo.rubberBand,
    ClipAnimationCombo.jiggle,
  ];

  @override
  void initState() {
    super.initState();
    _activeAnimation = widget.selectedAnimation == ClipAnimationCombo.none
        ? ClipAnimationCombo.pulse
        : widget.selectedAnimation;
    _durationMs = widget.initialDurationMs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _allAnimations.where((a) {
      if (query.isEmpty) return true;
      return a.label.toLowerCase().contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141622),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.animation, color: Color(0xFFFF007A), size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Timeline Animation Clips',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onAnimationSelected(_activeAnimation, _durationMs);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  label: const Text('Add Clip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF007A),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E202B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Color(0xFF8E92A4)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search animations (Pulse, Bounce, Shake...)',
                        hintStyle: TextStyle(color: Color(0xFF8E92A4), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: const Icon(Icons.close, size: 16, color: Colors.white54),
                    ),
                ],
              ),
            ),
          ),

          // Duration slider
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Text(
                  'Duration:',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_durationMs / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(color: Color(0xFFFF007A), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFFF007A),
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _durationMs.toDouble(),
                      min: 500,
                      max: 8000,
                      divisions: 15,
                      onChanged: (v) {
                        setState(() {
                          _durationMs = v.round();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Animations Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final anim = filtered[index];
                final isSelected = _activeAnimation == anim;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeAnimation = anim;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          anim.color1.withValues(alpha: isSelected ? 0.9 : 0.4),
                          anim.color2.withValues(alpha: isSelected ? 0.8 : 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF007A) : Colors.white12,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF007A).withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(anim.icon, color: Colors.white, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          anim.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
