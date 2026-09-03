import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/video_clip_entity.dart';

class ClipVolumeSheet extends StatefulWidget {
  final VideoClipEntity clip;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onMuteChanged;
  final VoidCallback onResetVolume;
  final VoidCallback onExtractAudio;

  const ClipVolumeSheet({
    super.key,
    required this.clip,
    required this.onVolumeChanged,
    required this.onMuteChanged,
    required this.onResetVolume,
    required this.onExtractAudio,
  });

  @override
  State<ClipVolumeSheet> createState() => _ClipVolumeSheetState();
}

class _ClipVolumeSheetState extends State<ClipVolumeSheet> {
  late double _volume;
  late bool _isMuted;

  @override
  void initState() {
    super.initState();
    _volume = widget.clip.volume;
    _isMuted = widget.clip.isMuted;
  }

  void _setVolume(double vol) {
    setState(() {
      _volume = vol.clamp(0.0, 2.0);
      if (_volume > 0 && _isMuted) {
        _isMuted = false;
        widget.onMuteChanged(false);
      }
    });
    widget.onVolumeChanged(_volume);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    widget.onMuteChanged(_isMuted);
  }

  void _reset() {
    setState(() {
      _volume = 1.0;
      _isMuted = false;
    });
    widget.onResetVolume();
  }

  IconData _getVolumeIcon() {
    if (_isMuted || _volume == 0) return Icons.volume_off;
    if (_volume < 0.5) return Icons.volume_mute;
    if (_volume <= 1.0) return Icons.volume_down;
    return Icons.volume_up;
  }

  String _getVolumeLabel() {
    if (_isMuted || _volume == 0) return 'Muted (0%)';
    final pct = (_volume * 100).round();
    if (pct == 100) return '100% (Original)';
    if (pct > 100) return '$pct% (Boosted)';
    return '$pct%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF161822),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Title, Reset Button, and Confirm Checkmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getVolumeIcon(),
                        color: _isMuted ? AppColors.error : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clip Volume',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.clip.name,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Reset / Restore Original Button
                    TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.restart_alt, size: 16, color: Colors.white70),
                      label: const Text(
                        'Restore',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Confirm Done Button
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 28),
                      tooltip: 'Confirm',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live Volume Level Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2130),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isMuted
                      ? AppColors.error.withValues(alpha: 0.5)
                      : (_volume > 1.0 ? const Color(0xFF00E5FF).withValues(alpha: 0.4) : Colors.white12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Volume Level',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white70),
                      ),
                      Text(
                        _getVolumeLabel(),
                        style: TextStyle(
                          color: _isMuted
                              ? AppColors.error
                              : (_volume > 1.0 ? const Color(0xFF00E5FF) : Colors.white),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Slider Row
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_mute,
                          color: _isMuted ? AppColors.error : Colors.white70,
                          size: 22,
                        ),
                        onPressed: _toggleMute,
                        tooltip: _isMuted ? 'Unmute' : 'Mute',
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                            activeTrackColor: _isMuted
                                ? AppColors.error
                                : (_volume > 1.0 ? const Color(0xFF00E5FF) : AppColors.primary),
                            inactiveTrackColor: const Color(0xFF2E3245),
                            thumbColor: Colors.white,
                            overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _isMuted ? 0.0 : _volume,
                            min: 0.0,
                            max: 2.0,
                            divisions: 40,
                            onChanged: (val) {
                              _setVolume(val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '200%',
                        style: TextStyle(
                          color: _volume > 1.0 ? const Color(0xFF00E5FF) : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Quick Preset Buttons Row
            Row(
              children: [
                _buildPresetButton(label: 'Mute', value: 0.0, isMuteAction: true),
                const SizedBox(width: 8),
                _buildPresetButton(label: '50%', value: 0.5),
                const SizedBox(width: 8),
                _buildPresetButton(label: '100%', value: 1.0, isDefault: true),
                const SizedBox(width: 8),
                _buildPresetButton(label: '150%', value: 1.5),
                const SizedBox(width: 8),
                _buildPresetButton(label: '200%', value: 2.0),
              ],
            ),
            const SizedBox(height: 18),

            // Extract Audio Card Option
            InkWell(
              onTap: () {
                widget.onExtractAudio();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.audiotrack, color: Color(0xFF00E5FF), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Extracted audio from "${widget.clip.name}" to Audio Track. Original video audio preserved.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF1E2130),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2130),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.call_split, color: Color(0xFF00E5FF), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Extract Audio to Separate Track',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Creates an editable audio clip. Does not mute original clip.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required double value,
    bool isMuteAction = false,
    bool isDefault = false,
  }) {
    final isSelected = isMuteAction
        ? (_isMuted || _volume == 0)
        : (!_isMuted && (_volume - value).abs() < 0.05);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (isMuteAction) {
            _toggleMute();
          } else {
            _setVolume(value);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isMuteAction ? AppColors.error.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.25))
                : const Color(0xFF1E2130),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isMuteAction ? AppColors.error : AppColors.primary)
                  : (isDefault ? Colors.white24 : Colors.transparent),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isMuteAction ? AppColors.error : AppColors.primaryLight)
                    : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected || isDefault ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
