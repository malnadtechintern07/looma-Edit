import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../domain/entities/project_entity.dart';

class ProjectCard extends StatelessWidget {
  final ProjectEntity project;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final durationStr = TimecodeFormatter.formatHumanDuration(project.calculatedDurationMs);
    final timeAgoStr = _formatTimeAgo(project.updatedAt);
    final firstMedia = project.videoClips.isNotEmpty ? project.videoClips.first.mediaPath : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEEF5), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Thumbnail Box with Play Overlay
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    _getGradientStartColor(project.id),
                    const Color(0xFF5B4DFB),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (firstMedia.isNotEmpty && firstMedia.startsWith('assets/'))
                    Image.asset(firstMedia, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox())
                  else if (firstMedia.isNotEmpty && File(firstMedia).existsSync())
                    Image.file(File(firstMedia), fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),

                  // Dark tint overlay
                  Container(color: Colors.black.withValues(alpha: 0.25)),

                  // Play Icon Overlay
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Middle Column: Title & Metadata (9:16 • 12s • Edited 2m ago)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B4DFB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Draft',
                          style: TextStyle(
                            color: Color(0xFF5B4DFB),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.aspectRatio.label} • $durationStr • Edited $timeAgoStr',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Right Options Menu (Three Dots ⋮)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF9CA3AF)),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFECEEF5)),
              ),
              onSelected: (val) {
                if (val == 'duplicate') onDuplicate();
                if (val == 'export') onExport();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 18, color: Color(0xFF111827)),
                      SizedBox(width: 10),
                      Text('Duplicate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.ios_share, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Export Video'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  Color _getGradientStartColor(String id) {
    final code = id.hashCode.abs() % 4;
    switch (code) {
      case 0:
        return const Color(0xFF1E3A8A);
      case 1:
        return const Color(0xFF00C2CB);
      case 2:
        return const Color(0xFF8644FF);
      default:
        return const Color(0xFFFF3B5C);
    }
  }
}
