import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/procut_slider.dart';
import '../../domain/entities/speed_curve_type.dart';

class ClipSpeedSheet extends StatefulWidget {
  final double currentSpeed;
  final SpeedCurveType currentSpeedCurve;
  final bool isReversed;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<SpeedCurveType> onSpeedCurveChanged;
  final VoidCallback onToggleReverse;
  final VoidCallback onFreezeFrame;

  const ClipSpeedSheet({
    super.key,
    required this.currentSpeed,
    this.currentSpeedCurve = SpeedCurveType.none,
    this.isReversed = false,
    required this.onSpeedChanged,
    required this.onSpeedCurveChanged,
    required this.onToggleReverse,
    required this.onFreezeFrame,
  });

  @override
  State<ClipSpeedSheet> createState() => _ClipSpeedSheetState();
}

class _ClipSpeedSheetState extends State<ClipSpeedSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late double _speed;
  late SpeedCurveType _selectedCurve;
  late bool _isReversed;

  final List<double> _presetSpeeds = [0.1, 0.25, 0.5, 1.0, 1.5, 2.0, 4.0, 8.0, 10.0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _speed = widget.currentSpeed;
    _selectedCurve = widget.currentSpeedCurve;
    _isReversed = widget.isReversed;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF161822),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed, color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Speed & Curves',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.secondary,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFA0A6B8),
            tabs: const [
              Tab(text: 'Standard Speed'),
              Tab(text: 'Speed Curves'),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Standard Speed
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProCutSlider(
                      label: 'Playback Speed',
                      icon: Icons.fast_forward,
                      value: _speed.clamp(0.1, 10.0),
                      min: 0.1,
                      max: 10.0,
                      divisions: 99,
                      valueFormatter: (v) => '${v.toStringAsFixed(2)}x',
                      onChanged: (v) {
                        setState(() => _speed = v);
                        widget.onSpeedChanged(v);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Speed Presets',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _presetSpeeds.map((preset) {
                          final isSelected = (_speed - preset).abs() < 0.05;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('${preset}x'),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _speed = preset);
                                widget.onSpeedChanged(preset);
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor: const Color(0xFF262A38),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : const Color(0xFF383D52),
                              ),
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                // Tab 2: Speed Curves
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: SpeedCurveType.values.length,
                  itemBuilder: (context, i) {
                    final curve = SpeedCurveType.values[i];
                    final isSelected = _selectedCurve == curve;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCurve = curve);
                        widget.onSpeedCurveChanged(curve);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.35) : const Color(0xFF262A38),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.secondary : const Color(0xFF383D52),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          curve.label.split(' ')[0],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFA0A6B8),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tools: Reverse & Freeze Frame
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    _isReversed ? Icons.replay : Icons.flip_camera_android,
                    size: 16,
                    color: _isReversed ? AppColors.secondary : Colors.white70,
                  ),
                  label: Text(
                    _isReversed ? 'Reversed (Active)' : 'Reverse Video',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isReversed ? AppColors.secondary : Colors.white,
                      fontWeight: _isReversed ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isReversed ? AppColors.secondary : const Color(0xFF383D52),
                    ),
                    backgroundColor: _isReversed ? AppColors.secondary.withValues(alpha: 0.15) : const Color(0xFF262A38),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() => _isReversed = !_isReversed);
                    widget.onToggleReverse();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.ac_unit, size: 16, color: AppColors.secondary),
                  label: const Text('Freeze Frame', style: TextStyle(fontSize: 11, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF383D52)),
                    backgroundColor: const Color(0xFF262A38),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: widget.onFreezeFrame,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

