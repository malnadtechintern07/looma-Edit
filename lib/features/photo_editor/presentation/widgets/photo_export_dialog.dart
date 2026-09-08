import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_actions_service.dart';
import '../../data/datasources/photo_exporter_service.dart';

class PhotoExportDialog extends StatefulWidget {
  final GlobalKey boundaryKey;
  final String projectTitle;
  final int? targetWidth;
  final int? targetHeight;

  const PhotoExportDialog({
    super.key,
    required this.boundaryKey,
    required this.projectTitle,
    this.targetWidth,
    this.targetHeight,
  });

  @override
  State<PhotoExportDialog> createState() => _PhotoExportDialogState();
}

class _PhotoExportDialogState extends State<PhotoExportDialog> {
  final PhotoExporterService _exporterService = PhotoExporterService();
  bool _isPng = true;
  double _qualityRatio = 3.0; // 3x ultra
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
        targetWidth: widget.targetWidth,
        targetHeight: widget.targetHeight,
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

  Future<void> _shareExportedImage() async {
    if (_exportedPath == null) return;
    await AppActionsService.shareImageFile(_exportedPath!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening share options...')),
      );
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
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.file_download, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Export High-Res Image',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: _exportedPath != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Saved to Device Gallery!',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library, size: 14, color: AppColors.success),
                        SizedBox(width: 6),
                        Text(
                          'Available in Gallery / Photos App',
                          style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: SelectableText(
                      _exportedPath!,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share, size: 16, color: Colors.white),
                    label: const Text('Share Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _shareExportedImage,
                  ),
                ],
              )
            : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FORMAT', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
                          color: _isPng ? Colors.white : AppColors.textPrimary,
                          fontWeight: _isPng ? FontWeight.bold : FontWeight.w500,
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
                          color: !_isPng ? Colors.white : AppColors.textPrimary,
                          fontWeight: !_isPng ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text('RESOLUTION QUALITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('1080p (2x)')),
                        selected: _qualityRatio == 2.0,
                        onSelected: (_) => setState(() => _qualityRatio = 2.0),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: _qualityRatio == 2.0 ? Colors.white : AppColors.textPrimary,
                          fontWeight: _qualityRatio == 2.0 ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('4K (3x Ultra)')),
                        selected: _qualityRatio == 3.0,
                        onSelected: (_) => setState(() => _qualityRatio = 3.0),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: _qualityRatio == 3.0 ? Colors.white : AppColors.textPrimary,
                          fontWeight: _qualityRatio == 3.0 ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      ),
      actions: [
        if (_exportedPath != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            icon: _isExporting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.download, color: Colors.white, size: 16),
            label: Text(
              _isExporting ? 'Exporting...' : 'Export Now',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isExporting ? null : _startExport,
          ),
        ],
      ],
    );
  }
}
