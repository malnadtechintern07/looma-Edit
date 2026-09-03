import 'package:flutter/material.dart';
import '../../../../core/widgets/looma_slider.dart';
import '../../domain/entities/chroma_key_config_entity.dart';

class ChromaKeySheet extends StatefulWidget {
  final ChromaKeyConfigEntity? currentConfig;
  final ValueChanged<ChromaKeyConfigEntity?> onConfigChanged;

  const ChromaKeySheet({
    super.key,
    required this.currentConfig,
    required this.onConfigChanged,
  });

  @override
  State<ChromaKeySheet> createState() => _ChromaKeySheetState();
}

class _ChromaKeySheetState extends State<ChromaKeySheet> {
  late bool _isEnabled;
  late int _keyColorHex;
  late double _intensity;
  late double _shadow;

  final List<Map<String, dynamic>> _presetColors = [
    {'name': 'Green Screen', 'hex': 0xFF00FF00, 'color': Color(0xFF00FF00)},
    {'name': 'Blue Screen', 'hex': 0xFF0000FF, 'color': Color(0xFF0055FF)},
    {'name': 'Magenta', 'hex': 0xFFFF00FF, 'color': Color(0xFFFF00FF)},
    {'name': 'Cyan', 'hex': 0xFF00FFFF, 'color': Color(0xFF00FFFF)},
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.currentConfig ?? const ChromaKeyConfigEntity();
    _isEnabled = c.isEnabled;
    _keyColorHex = c.keyColorHex;
    _intensity = c.intensity;
    _shadow = c.shadow;
  }

  void _notify() {
    if (!_isEnabled) {
      widget.onConfigChanged(null);
    } else {
      widget.onConfigChanged(
        ChromaKeyConfigEntity(
          isEnabled: true,
          keyColorHex: _keyColorHex,
          intensity: _intensity,
          shadow: _shadow,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 28, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF161822),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.colorize, color: Color(0xFF00FF88), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Chroma Key / Green Screen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isEnabled,
                activeTrackColor: const Color(0xFF00FF88),
                activeThumbColor: Colors.white,
                onChanged: (val) {
                  setState(() => _isEnabled = val);
                  _notify();
                },
              ),
            ],
          ),
          const Divider(color: Color(0xFF2E3240), height: 20),

          if (_isEnabled) ...[
            const Text(
              'Select Key Color',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presetColors.map((item) {
                  final isSelected = _keyColorHex == item['hex'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() => _keyColorHex = item['hex'] as int);
                        _notify();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00FF88).withValues(alpha: 0.25) : const Color(0xFF262A38),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00FF88) : const Color(0xFF383D52),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: item['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item['name'] as String,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFFA0A6B8),
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Intensity Slider
            LoomaSlider(
              label: 'Intensity / Sensitivity',
              icon: Icons.tune,
              value: _intensity.clamp(0.1, 1.0),
              min: 0.1,
              max: 1.0,
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (val) {
                setState(() => _intensity = val);
                _notify();
              },
            ),
            const SizedBox(height: 12),

            // Shadow / Edge Smoothness Slider
            LoomaSlider(
              label: 'Shadow & Edge Falloff',
              icon: Icons.opacity,
              value: _shadow.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (val) {
                setState(() => _shadow = val);
                _notify();
              },
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Enable Chroma Key to remove green or blue screen backgrounds.',
                  style: TextStyle(color: Color(0xFFA0A6B8), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
