import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../core/widgets/looma_button.dart';
import '../../../../core/widgets/looma_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/store_template_entity.dart';

class TemplateCard extends StatelessWidget {
  final StoreTemplateEntity template;
  final VoidCallback onUseTemplate;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final startColorInt = int.tryParse(template.previewGradientStart) ?? 0xFF8B5CF6;
    final endColorInt = int.tryParse(template.previewGradientEnd) ?? 0xFF06B6D4;
    final durationStr = TimecodeFormatter.formatHumanDuration(template.durationMs);

    return LoomaCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Gradient Thumbnail
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              gradient: LinearGradient(
                colors: [Color(startColorInt), Color(endColorInt)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${template.clipsCount} media slots',
                        style: AppTypography.labelSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: StatusBadge(
                    text: durationStr,
                    icon: Icons.timer,
                    color: Colors.black54,
                    textColor: Colors.white,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: StatusBadge(
                    text: template.aspectRatio.label,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Details & Use Action
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        template.title,
                        style: AppTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'by ${template.author}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  template.description,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Audio Track Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note, size: 12, color: AppColors.primaryLight),
                      const SizedBox(width: 4),
                      Text(
                        template.audioTrackTitle,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: template.tags.take(2).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('#$t', style: AppTypography.labelSmall.copyWith(fontSize: 9)),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LoomaButton(
                      label: 'Use Template',
                      icon: Icons.download,
                      height: 34,
                      onPressed: onUseTemplate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
