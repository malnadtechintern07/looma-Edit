import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoHslSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final String? selectedFrameId;
  final PhotoEditorController controller;

  const PhotoHslSheet({
    super.key,
    required this.project,
    this.selectedFrameId,
    required this.controller,
  });

  @override
  State<PhotoHslSheet> createState() => _PhotoHslSheetState();
}

class _HslChannel {
  final String name;
  final Color color;
  const _HslChannel(this.name, this.color);
}

class _PhotoHslSheetState extends State<PhotoHslSheet> {
  late PhotoFrameEntity? _targetFrame;
  int _selectedChannelIndex = 0;

  static const List<_HslChannel> _channels = [
    _HslChannel('Red', Color(0xFFFF3B30)),
    _HslChannel('Orange', Color(0xFFFF9500)),
    _HslChannel('Yellow', Color(0xFFFFCC00)),
    _HslChannel('Green', Color(0xFF34C759)),
    _HslChannel('Aqua', Color(0xFF00C2CB)),
    _HslChannel('Blue', Color(0xFF007AFF)),
    _HslChannel('Purple', Color(0xFF5856D6)),
    _HslChannel('Magenta', Color(0xFFAF52DE)),
  ];

  @override
  void initState() {
    super.initState();
    _resolveFrame();
  }

  void _resolveFrame() {
    if (widget.selectedFrameId != null) {
      _targetFrame = widget.project.frames.firstWhere(
        (f) => f.id == widget.selectedFrameId,
        orElse: () => widget.project.frames.isNotEmpty
            ? widget.project.frames.first
            : const PhotoFrameEntity(id: '', imagePath: ''),
      );
    } else {
      _targetFrame = widget.project.frames.isNotEmpty ? widget.project.frames.first : null;
    }
  }

  Map<String, double> _getCurrentChannelValues() {
    if (_targetFrame == null) return {'hue': 0.0, 'sat': 0.0, 'lum': 0.0};
    final channelName = _channels[_selectedChannelIndex].name;
    return _targetFrame!.hslAdjustments[channelName] ?? {'hue': 0.0, 'sat': 0.0, 'lum': 0.0};
  }

  void _updateChannelValue(String key, double val) {
    if (_targetFrame == null) return;
    final channelName = _channels[_selectedChannelIndex].name;
    final current = Map<String, double>.from(_getCurrentChannelValues());
    current[key] = val;

    final updatedMap = Map<String, Map<String, double>>.from(_targetFrame!.hslAdjustments);
    updatedMap[channelName] = current;

    setState(() {
      _targetFrame = _targetFrame!.copyWith(hslAdjustments: updatedMap);
    });
    widget.controller.updateFrameHsl(
      _targetFrame!.id,
      channelName,
      hue: current['hue'],
      sat: current['sat'],
      lum: current['lum'],
    );
  }

  void _resetCurrentChannel() {
    if (_targetFrame == null) return;
    final channelName = _channels[_selectedChannelIndex].name;
    final updatedMap = Map<String, Map<String, double>>.from(_targetFrame!.hslAdjustments);
    updatedMap.remove(channelName);

    setState(() {
      _targetFrame = _targetFrame!.copyWith(hslAdjustments: updatedMap);
    });
    widget.controller.updateFrameHsl(
      _targetFrame!.id,
      channelName,
      hue: 0.0,
      sat: 0.0,
      lum: 0.0,
      recordHistory: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_targetFrame == null || _targetFrame!.id.isEmpty) {
      return SafeArea(
        top: false,
        bottom: true,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Text(
              'Add a photo to adjust HSL color channels',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final activeChannel = _channels[_selectedChannelIndex];
    final values = _getCurrentChannelValues();
    final hue = values['hue'] ?? 0.0;
    final sat = values['sat'] ?? 0.0;
    final lum = values['lum'] ?? 0.0;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: activeChannel.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.colorize, color: activeChannel.color, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HSL Color Channels',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetCurrentChannel,
                      child: const Text('Reset', style: TextStyle(color: AppColors.accentRose, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.success),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Channel Selector Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_channels.length, (idx) {
                final ch = _channels[idx];
                final isSelected = _selectedChannelIndex == idx;
                final hasEdits = _targetFrame!.hslAdjustments.containsKey(ch.name);

                return GestureDetector(
                  onTap: () => setState(() => _selectedChannelIndex = idx),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ch.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: isSelected ? 3.0 : 0.0,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: ch.color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                      if (hasEdits && !isSelected)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${activeChannel.name} Channel',
                style: TextStyle(color: activeChannel.color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // 1. Hue Slider
            _buildHslSlider(
              title: 'HUE',
              val: hue,
              min: -180.0,
              max: 180.0,
              display: '${hue.round()}°',
              onChanged: (v) => _updateChannelValue('hue', v),
            ),

            // 2. Saturation Slider
            _buildHslSlider(
              title: 'SATURATION',
              val: sat,
              min: -100.0,
              max: 100.0,
              display: '${sat.round()}%',
              onChanged: (v) => _updateChannelValue('sat', v),
            ),

            // 3. Luminance Slider
            _buildHslSlider(
              title: 'LUMINANCE',
              val: lum,
              min: -100.0,
              max: 100.0,
              display: '${lum.round()}%',
              onChanged: (v) => _updateChannelValue('lum', v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHslSlider({
    required String title,
    required double val,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    final isModified = val.abs() > 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E29),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isModified ? AppColors.primaryLight : const Color(0xFF2C3042),
          width: isModified ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              Text(display, style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFF2C3042),
              thumbColor: Colors.white,
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: val.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
