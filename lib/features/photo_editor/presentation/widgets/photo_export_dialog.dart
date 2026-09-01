import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/datasources/photo_exporter_service.dart';

class PhotoExportDialog extends StatefulWidget {
  final GlobalKey boundaryKey;
  final String projectTitle;

  const PhotoExportDialog({
    super.key,
    required this.boundaryKey,
    required this.projectTitle,
  });

  @override
  State<PhotoExportDialog> createState() => _PhotoExportDialogState();
}

class _PhotoExportDialogState extends State<PhotoExportDialog> {
  final PhotoExporterService _exporterService = PhotoExporterService();
  bool _isPng = true;
  double _qualityRatio = 3.0; // 3x high-res
  bool _isExporting = false;
  String? _exportedPath;

  Future<void> _startExport() async {
    setState(() => _isExporting = true);
    try {
      final path = await _exporterService.exportCanvasToImage(
        boundaryKey: widget.boundaryKey,
        projectTitle: widget.projectTitle,
        isPng: _isPng,
        pixelRatio: _qualityRatio,
      );
      setState(() {
        _isExporting = false;
        _exportedPath = path;
      });
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.file_download, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 10),
          Text('Export High-Res Image', style: AppTypography.titleMedium),
        ],
      ),
      content: _exportedPath != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.accent, size: 48),
                const SizedBox(height: 12),
                Text('Image Exported Successfully!', style: AppTypography.titleSmall),
                const SizedBox(height: 8),
                Text(
                  _exportedPath!,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FORMAT', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('PNG (Lossless)')),
                        selected: _isPng,
                        onSelected: (_) => setState(() => _isPng = true),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: _isPng ? Colors.white : AppColors.textSecondary,
                          fontWeight: _isPng ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('JPEG (Compact)')),
                        selected: !_isPng,
                        onSelected: (_) => setState(() => _isPng = false),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: !_isPng ? Colors.white : AppColors.textSecondary,
                          fontWeight: !_isPng ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text('RESOLUTION QUALITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('1080p (2x)')),
                        selected: _qualityRatio == 2.0,
                        onSelected: (_) => setState(() => _qualityRatio = 2.0),
                        selectedColor: AppColors.secondary,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: _qualityRatio == 2.0 ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('4K (3x Ultra)')),
                        selected: _qualityRatio == 3.0,
                        onSelected: (_) => setState(() => _qualityRatio = 3.0),
                        selectedColor: AppColors.secondary,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: _qualityRatio == 3.0 ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        if (_exportedPath != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            icon: _isExporting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.download),
            label: Text(_isExporting ? 'Exporting...' : 'Export Now'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: _isExporting ? null : _startExport,
          ),
        ],
      ],
    );
  }
}
