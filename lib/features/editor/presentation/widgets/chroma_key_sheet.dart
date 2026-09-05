import 'package:flutter/material.dart';
import '../../../../core/widgets/looma_slider.dart';
import '../../domain/entities/chroma_key_config_entity.dart';

class ChromaKeySheet extends StatefulWidget {
  final ChromaKeyConfigEntity? currentConfig;
  final ValueChanged<ChromaKeyConfigEntity?> onConfigChanged;
  final VoidCallback? onReset;
  final VoidCallback? onClose;
  final bool isPickingMode;
  final VoidCallback? onTogglePickingMode;

  const ChromaKeySheet({
    super.key,
    required this.currentConfig,
    required this.onConfigChanged,
    this.onReset,
    this.onClose,
    this.isPickingMode = false,
    this.onTogglePickingMode,
  });

  @override
  State<ChromaKeySheet> createState() => _ChromaKeySheetState();
}

class _ChromaKeySheetState extends State<ChromaKeySheet> {
  late bool _isEnabled;
  late int _keyColorHex;
  late double _intensity;
  late double _edgeSoftness;
  late double _spillSuppression;

  final List<Map<String, dynamic>> _presetColors = [
    {'name': 'Green Screen', 'hex': 0xFF00FF00, 'color': const Color(0xFF00FF00)},
    {'name': 'Blue Screen', 'hex': 0xFF0000FF, 'color': const Color(0xFF0055FF)},
    {'name': 'Magenta', 'hex': 0xFFFF00FF, 'color': const Color(0xFFFF00FF)},
    {'name': 'Cyan', 'hex': 0xFF00FFFF, 'color': const Color(0xFF00FFFF)},
  ];

  @override
  void initState() {
    super.initState();
    _syncWithConfig(widget.currentConfig);
  }

  @override
  void didUpdateWidget(covariant ChromaKeySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentConfig != oldWidget.currentConfig) {
      _syncWithConfig(widget.currentConfig);
    }
  }

  void _syncWithConfig(ChromaKeyConfigEntity? c) {
    final cfg = c ?? const ChromaKeyConfigEntity();
    _isEnabled = cfg.isEnabled;
    _keyColorHex = cfg.keyColorHex;
    _intensity = cfg.intensity;
    _edgeSoftness = cfg.edgeSoftness;
    _spillSuppression = cfg.spillSuppression;
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
          edgeSoftness: _edgeSoftness,
          spillSuppression: _spillSuppression,
        ),
      );
    }
  }

  void _handleReset() {
    setState(() {
      _isEnabled = false;
      _keyColorHex = 0xFF00FF00;
      _intensity = 0.50;
      _edgeSoftness = 0.15;
      _spillSuppression = 0.30;
    });
    if (widget.onReset != null) {
      widget.onReset!();
    } else {
      widget.onConfigChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = Color(_keyColorHex);
    final hexString = '#${_keyColorHex.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 20, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF161822),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Grab Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row: Title, Reset Button, Toggle & Close
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.colorize, color: Color(0xFF00FF88), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chroma Key',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Reset / Remove Button
                IconButton(
                  key: const ValueKey('chroma_reset_btn'),
                  icon: const Icon(Icons.restart_alt, color: Colors.white60, size: 20),
                  tooltip: 'Reset Chroma Key',
                  onPressed: _handleReset,
                ),
                // Enable/Disable Switch
                Switch(
                  key: const ValueKey('chroma_enable_switch'),
                  value: _isEnabled,
                  activeTrackColor: const Color(0xFF00FF88),
                  activeThumbColor: Colors.white,
                  onChanged: (val) {
                    setState(() => _isEnabled = val);
                    _notify();
                  },
                ),
                if (widget.onClose != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    key: const ValueKey('chroma_done_btn'),
                    icon: const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 24),
                    tooltip: 'Done',
                    onPressed: widget.onClose,
                  ),
                ],
              ],
            ),
            const Divider(color: Color(0xFF2E3240), height: 16),

            if (_isEnabled) ...[
              // Color Picker Row: Sampled Color Swatch, Eyedropper & Hex
              Row(
                children: [
                  // Eyedropper / Color Picker Mode Toggle Button
                  InkWell(
                    key: const ValueKey('chroma_eyedropper_btn'),
                    onTap: widget.onTogglePickingMode ?? () {},
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.isPickingMode
                            ? const Color(0xFF00FF88).withValues(alpha: 0.25)
                            : const Color(0xFF262A38),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.isPickingMode ? const Color(0xFF00FF88) : const Color(0xFF383D52),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.colorize,
                            size: 16,
                            color: widget.isPickingMode ? const Color(0xFF00FF88) : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isPickingMode ? 'Picking...' : 'Color Picker',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.isPickingMode ? const Color(0xFF00FF88) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Current Sampled Color Swatch & Hex Display
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hexString,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Color Preset Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _presetColors.map((item) {
                    final isSelected = _keyColorHex == item['hex'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => _keyColorHex = item['hex'] as int);
                          _notify();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00FF88).withValues(alpha: 0.25)
                                : const Color(0xFF262A38),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00FF88) : const Color(0xFF383D52),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
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
              const SizedBox(height: 14),

              // 1. Strength / Tolerance Slider (0-100)
              LoomaSlider(
                key: const ValueKey('chroma_strength_slider'),
                label: 'Strength / Tolerance',
                icon: Icons.tune,
                value: _intensity.clamp(0.01, 1.0),
                min: 0.01,
                max: 1.0,
                valueFormatter: (v) => '${(v * 100).round()}',
                onChanged: (val) {
                  setState(() => _intensity = val);
                  _notify();
                },
              ),
              const SizedBox(height: 10),

              // 2. Edge Softness / Feather Slider (0-100)
              LoomaSlider(
                key: const ValueKey('chroma_feather_slider'),
                label: 'Edge Softness / Feather',
                icon: Icons.blur_on,
                value: _edgeSoftness.clamp(0.01, 1.0),
                min: 0.01,
                max: 1.0,
                valueFormatter: (v) => '${(v * 100).round()}',
                onChanged: (val) {
                  setState(() => _edgeSoftness = val);
                  _notify();
                },
              ),
              const SizedBox(height: 10),

              // 3. Spill Suppression Slider (0-100)
              LoomaSlider(
                key: const ValueKey('chroma_spill_slider'),
                label: 'Spill Suppression',
                icon: Icons.cleaning_services,
                value: _spillSuppression.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                valueFormatter: (v) => '${(v * 100).round()}',
                onChanged: (val) {
                  setState(() => _spillSuppression = val);
                  _notify();
                },
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Enable Chroma Key or tap the preview to remove green or blue screen backgrounds.',
                    style: TextStyle(color: Color(0xFFA0A6B8), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
