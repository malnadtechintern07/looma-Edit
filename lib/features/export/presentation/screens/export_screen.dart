import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_actions_service.dart';
import '../../../../core/services/gallery_saver_service.dart';
import '../../../../core/widgets/procut_button.dart';
import '../../../../core/widgets/procut_card.dart';
import '../../../../core/widgets/procut_watermark.dart';
import '../../../../core/widgets/rate_us_dialog.dart';
import '../../../projects/domain/entities/project_entity.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../domain/entities/export_config_entity.dart';
import '../../domain/entities/render_progress_entity.dart';
import '../../../media_picker/domain/entities/media_item_entity.dart';
import '../../../media_picker/domain/services/recent_media_service.dart';
import '../providers/export_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ExportScreen({super.key, required this.projectId});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportResolution _selectedResolution = ExportResolution.res1080p;
  int _selectedFps = 30;
  ExportQuality _selectedQuality = ExportQuality.normal;
  bool _includeWatermark = true;
  String? _autoSavedGalleryPath;
  bool _isAutoSaving = false;
  ProjectEntity? _project;
  bool _isLoadingProject = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final proj = await ref.read(getProjectByIdUseCaseProvider)(widget.projectId);
    if (mounted) {
      setState(() {
        _project = proj;
        _isLoadingProject = false;
      });
    }
  }

  Future<void> _checkAndShowFirstExportRating() async {
    final hasShown = await AppActionsService.hasShownFirstExportRating();
    if (hasShown || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await showRateUsDialog(context, isFirstExport: true);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Riverpod listener must be placed directly at the top of build()
    ref.listen<RenderProgressEntity>(exportControllerProvider, (prev, next) async {
      if (next.status == RenderStatus.completed &&
          _autoSavedGalleryPath == null &&
          !_isAutoSaving &&
          _project != null) {
        setState(() => _isAutoSaving = true);

        // Prioritize actual rendered video outputPath if exists on disk and is a video
        String sourcePath = '';
        if (next.outputPath != null && File(next.outputPath!).existsSync()) {
          sourcePath = next.outputPath!;
        } else {
          // Only allow direct single raw video copy if project has no overlays, photos, text, or watermark
          final isSingleRawVideo = _project!.videoClips.length == 1 &&
              !_project!.videoClips.first.isPhoto &&
              !_project!.videoClips.first.isOverlay &&
              _project!.textOverlays.isEmpty &&
              _project!.stickerOverlays.isEmpty &&
              !_includeWatermark;

          if (isSingleRawVideo && File(_project!.videoClips.first.mediaPath).existsSync()) {
            sourcePath = _project!.videoClips.first.mediaPath;
          } else {
            sourcePath = '';
          }
        }

        if (sourcePath.isNotEmpty && File(sourcePath).existsSync()) {
          final fileName = 'procut_${_project!.title.replaceAll(' ', '_').toLowerCase()}';
          final savedPath = await GallerySaverService.saveVideoToDeviceGallery(
            sourceFilePath: sourcePath,
            fileName: fileName,
          );

          if (mounted) {
            setState(() {
              _autoSavedGalleryPath = savedPath;
              _isAutoSaving = false;
            });
          }

          // Automatically register exported video in recent media catalog
          try {
            final catalogPath = (savedPath != null && savedPath.isNotEmpty && File(savedPath).existsSync())
                ? savedPath
                : sourcePath;
            if (File(catalogPath).existsSync()) {
              RecentMediaService().addRecentMediaSingle(
                MediaItemEntity(
                  path: catalogPath,
                  name: '${_project!.title} (Exported)',
                  type: MediaType.video,
                  durationMs: _project!.calculatedDurationMs,
                  addedAt: DateTime.now(),
                ),
              );
            }
          } catch (_) {}
        } else {
          if (mounted) {
            setState(() {
              _isAutoSaving = false;
            });
          }
        }
      }


      // Prompt Rate Us dialog once after first successful export
      if (next.status == RenderStatus.completed && prev?.status != RenderStatus.completed) {
        _checkAndShowFirstExportRating();
      }
    });

    final renderProgress = ref.watch(exportControllerProvider);
    final isRendering = renderProgress.status == RenderStatus.rendering;
    final isCompleted = renderProgress.status == RenderStatus.completed;

    if (_isLoadingProject || _project == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final project = _project!;
    final config = ExportConfigEntity(
      projectId: project.id,
      resolution: _selectedResolution,
      fps: _selectedFps,
      aspectRatio: project.aspectRatio,
      quality: _selectedQuality,
      includeWatermark: _includeWatermark,
    );

    final estimatedSize = config.getEstimatedSizeMb(project.calculatedDurationMs);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.ios_share, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text('Export Video', style: AppTypography.titleLarge),
          ],
        ),
      ),
      body: isRendering || isCompleted
          ? _buildRenderStatusView(project, renderProgress)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Summary Card
                  ProCutCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.movie, color: AppColors.primaryLight, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(project.title, style: AppTypography.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                '${project.aspectRatio.label} • ${project.videoClips.length} clips • ${(project.calculatedDurationMs / 1000).toStringAsFixed(1)}s',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resolution Selection
                  Text('Resolution', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  Row(
                    children: ExportResolution.values.map((res) {
                      final isSelected = _selectedResolution == res;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InkWell(
                            onTap: () => setState(() => _selectedResolution = res),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryLight : AppColors.surfaceBorder,
                                ),
                              ),
                              child: Text(
                                res.label.split(' ').first,
                                style: AppTypography.labelLarge.copyWith(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Frame Rate
                  Text('Frame Rate (FPS)', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  Row(
                    children: [24, 30, 60].map((fps) {
                      final isSelected = _selectedFps == fps;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () => setState(() => _selectedFps = fps),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.secondary : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.secondaryLight : AppColors.surfaceBorder,
                                ),
                              ),
                              child: Text(
                                '$fps FPS',
                                style: AppTypography.labelLarge.copyWith(
                                  color: isSelected ? Colors.black : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Quality Profile
                  Text('Quality Profile & Bitrate', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  ...ExportQuality.values.map((q) {
                    final isSelected = _selectedQuality == q;
                    return InkWell(
                      onTap: () => setState(() => _selectedQuality = q),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.label, style: AppTypography.titleSmall),
                                  Text('${(q.bitrateKbps / 1000).toInt()} Mbps Bitrate', style: AppTypography.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // ProCut Watermark Toggle
                  ProCutCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const ProCutWatermark(opacity: 0.85, scale: 0.95),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ProCut Watermark', style: AppTypography.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                'Clean watermark in bottom-right corner',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          key: const Key('watermark_toggle'),
                          value: _includeWatermark,
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFCBD5E1),
                          inactiveThumbColor: Colors.white,
                          trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected) ? Colors.transparent : const Color(0xFF94A3B8),
                          ),
                          onChanged: (val) => setState(() => _includeWatermark = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estimated Size Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sd_storage_outlined, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Estimated Size', style: AppTypography.bodyMedium),
                          ],
                        ),
                        Text(
                          '~${estimatedSize.toStringAsFixed(1)} MB',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Render Button CTA
                  ProCutButton(
                    label: 'Render Video Now',
                    icon: Icons.movie_creation,
                    isFullWidth: true,
                    height: 52,
                    onPressed: () {
                      ref.read(exportControllerProvider.notifier).startExport(
                            project: project,
                            config: config,
                          );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRenderStatusView(ProjectEntity project, RenderProgressEntity renderProgress) {
    final isCompleted = renderProgress.status == RenderStatus.completed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Circular Progress or Success Icon
            if (isCompleted)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
                child: const Icon(Icons.check, size: 48, color: Colors.white),
              )
            else
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: renderProgress.progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Text(
                    '${(renderProgress.progress * 100).toInt()}%',
                    style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 28),

            Text(
              isCompleted ? 'Video Exported & Saved!' : 'Exporting Video...',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted
                  ? 'Video was saved directly to your device Gallery / Camera Roll!'
                  : renderProgress.stageDescription,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),

            if (isCompleted && _autoSavedGalleryPath != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.6), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Directly Saved: ${_autoSavedGalleryPath!}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            if (isCompleted) ...[
              ProCutButton(
                label: 'Save Again to Gallery',
                icon: Icons.save_alt,
                isFullWidth: true,
                onPressed: () async {
                  String sourcePath = '';
                  final currentProgress = ref.read(exportControllerProvider);
                  if (currentProgress.outputPath != null && File(currentProgress.outputPath!).existsSync()) {
                    sourcePath = currentProgress.outputPath!;
                  } else {
                    final realClip = _project!.videoClips
                        .where((c) => !c.isPhoto && File(c.mediaPath).existsSync())
                        .firstOrNull;
                    sourcePath = realClip?.mediaPath ?? 'assets/demo/alps_sunrise.mp4';
                  }
                  final fileName = 'procut_${_project!.title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
                  final path = await GallerySaverService.saveVideoToDeviceGallery(
                    sourceFilePath: sourcePath,
                    fileName: fileName,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('Video saved directly to Gallery: ${path ?? _autoSavedGalleryPath ?? "Photos"}'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Return to Editor'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
