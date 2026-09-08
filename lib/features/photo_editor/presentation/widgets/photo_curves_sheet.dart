import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/photo_frame_entity.dart';
import '../../domain/entities/photo_project_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoCurvesSheet extends StatefulWidget {
  final PhotoProjectEntity project;
  final String? selectedFrameId;
  final PhotoEditorController controller;

  const PhotoCurvesSheet({
    super.key,
    required this.project,
    this.selectedFrameId,
    required this.controller,
  });

  @override
  State<PhotoCurvesSheet> createState() => _PhotoCurvesSheetState();
}

class _PhotoCurvesSheetState extends State<PhotoCurvesSheet> {
  late PhotoFrameEntity? _targetFrame;
  String _selectedChannel = 'RGB';

  static const List<String> _channels = ['RGB', 'Red', 'Green', 'Blue'];

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

  List<double> _getChannelPoints() {
    if (_targetFrame == null) return [0.0, 0.0, 0.0, 0.0, 0.0];
    return _targetFrame!.toneCurves[_selectedChannel] ?? [0.0, 0.0, 0.0, 0.0, 0.0];
  }

  void _updatePoint(int index, double val) {
    if (_targetFrame == null) return;
    final points = List<double>.from(_getChannelPoints());
    points[index] = val;

    final updatedCurves = Map<String, List<double>>.from(_targetFrame!.toneCurves);
    updatedCurves[_selectedChannel] = points;

    setState(() {
      _targetFrame = _targetFrame!.copyWith(toneCurves: updatedCurves);
    });

    widget.controller.updateFrameCurves(
      _targetFrame!.id,
      _selectedChannel,
      blacks: points[0],
      shadows: points[1],
      midtones: points[2],
      highlights: points[3],
      whites: points[4],
    );
  }

  void _resetCurrentCurve() {
    if (_targetFrame == null) return;
    final updatedCurves = Map<String, List<double>>.from(_targetFrame!.toneCurves);
    updatedCurves.remove(_selectedChannel);

    setState(() {
      _targetFrame = _targetFrame!.copyWith(toneCurves: updatedCurves);
    });

    widget.controller.updateFrameCurves(
      _targetFrame!.id,
      _selectedChannel,
      blacks: 0.0,
      shadows: 0.0,
      midtones: 0.0,
      highlights: 0.0,
      whites: 0.0,
      recordHistory: true,
    );
  }

  Color _getChannelColor() {
    switch (_selectedChannel) {
      case 'Red':
        return Colors.redAccent;
      case 'Green':
        return Colors.greenAccent;
      case 'Blue':
        return Colors.lightBlueAccent;
      default:
        return Colors.white;
    }
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
              'Add a photo to adjust Tone Curves',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final points = _getChannelPoints();
    final channelColor = _getChannelColor();

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
                        color: channelColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.show_chart, color: channelColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tone Curves',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetCurrentCurve,
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
            const SizedBox(height: 12),

            // Channel Selector Chips (RGB, Red, Green, Blue)
            Row(
              children: _channels.map((ch) {
                final isSelected = _selectedChannel == ch;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Center(child: Text(ch)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedChannel = ch),
                      selectedColor: isSelected ? AppColors.primary : const Color(0xFF1E212E),
                      backgroundColor: const Color(0xFF1E212E),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Visual Tone Curve Graph
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF181A24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C3042)),
              ),
              child: CustomPaint(
                painter: _ToneCurveGraphPainter(
                  points: points,
                  color: channelColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sliders for Blacks, Shadows, Midtones, Highlights, Whites
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildCurveSlider('Blacks', points[0], (v) => _updatePoint(0, v)),
                    _buildCurveSlider('Shadows', points[1], (v) => _updatePoint(1, v)),
                    _buildCurveSlider('Midtones', points[2], (v) => _updatePoint(2, v)),
                    _buildCurveSlider('Highlights', points[3], (v) => _updatePoint(3, v)),
                    _buildCurveSlider('Whites', points[4], (v) => _updatePoint(4, v)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurveSlider(String title, double val, ValueChanged<double> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E29),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C3042)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: const Color(0xFF2C3042),
                thumbColor: Colors.white,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(
                value: val.clamp(-50.0, 50.0),
                min: -50.0,
                max: 50.0,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${val >= 0 ? '+' : ''}${val.round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneCurveGraphPainter extends CustomPainter {
  final List<double> points; // 5 points: Blacks, Shadows, Midtones, Highlights, Whites
  final Color color;

  _ToneCurveGraphPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;

    // Draw 4x4 Grid
    for (int i = 1; i < 4; i++) {
      final x = size.width * (i / 4.0);
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Diagonal reference line
    final diagPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), diagPaint);

    // Compute 5 coordinate offsets
    final curvePoints = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final x = size.width * (i / 4.0);
      // Normalized default diagonal y: size.height * (1.0 - (i / 4.0))
      final baseNormY = 1.0 - (i / 4.0);
      // point value is in [-50, 50]
      final offsetNorm = points[i] / 100.0;
      final y = (size.height * (baseNormY - offsetNorm)).clamp(0.0, size.height);
      curvePoints.add(Offset(x, y));
    }

    // Draw spline path
    final path = Path()..moveTo(curvePoints[0].dx, curvePoints[0].dy);
    for (int i = 0; i < curvePoints.length - 1; i++) {
      final p0 = curvePoints[i];
      final p1 = curvePoints[i + 1];
      final midX = (p0.dx + p1.dx) / 2.0;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final curvePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, curvePaint);

    // Draw control point circles
    final pointPaint = Paint()..color = Colors.white;
    for (final p in curvePoints) {
      canvas.drawCircle(p, 4.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ToneCurveGraphPainter oldDelegate) => true;
}
