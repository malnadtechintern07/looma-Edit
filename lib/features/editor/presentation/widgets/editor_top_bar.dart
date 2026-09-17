import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../projects/domain/entities/aspect_ratio_type.dart';
import '../providers/editor_controller.dart';

class EditorTopBar extends StatelessWidget {
  final EditorController controller;
  final AspectRatioType currentRatio;
  final String projectTitle;
  final String projectId;

  const EditorTopBar({
    super.key,
    required this.controller,
    required this.currentRatio,
    required this.projectTitle,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Back Button (Auto-Saves Draft)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_ios_new, size: 17),
            tooltip: 'Save Draft & Exit',
            onPressed: () async {
              await controller.saveDraft();
              if (context.mounted) {
                context.pop();
              }
            },
          ),
          const SizedBox(width: 3),

          // Aspect Ratio Switcher Menu
          Flexible(
            child: PopupMenuButton<AspectRatioType>(
            tooltip: 'Change Aspect Ratio',
            initialValue: currentRatio,
            onSelected: controller.updateAspectRatio,
            color: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.surfaceBorder),
            ),
            constraints: const BoxConstraints(maxWidth: 240),
            itemBuilder: (ctx) => AspectRatioType.values.map((ratio) {
              return PopupMenuItem(
                value: ratio,
                child: Row(
                  children: [
                    Icon(
                      ratio == currentRatio ? Icons.check_circle : Icons.crop_portrait,
                      size: 18,
                      color: ratio == currentRatio ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '${ratio.label} (${ratio.description})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.aspect_ratio, size: 13, color: AppColors.primaryLight),
                  const SizedBox(width: 3),
                  Text(currentRatio.label, style: AppTypography.labelLarge.copyWith(fontSize: 10.5)),
                  const Icon(Icons.arrow_drop_down, size: 13, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          ),

          const SizedBox(width: 6),

          // Project Title (Flexible & Ellipsis)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                projectTitle,
                style: AppTypography.titleSmall.copyWith(fontSize: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Save Draft Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.save_outlined,
              size: 19,
              color: AppColors.primary,
            ),
            tooltip: 'Save Draft',
            onPressed: () async {
              await controller.saveDraft();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Draft saved successfully!',
                            style: TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF1F2937),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 4),

          // Export Button CTA (Responsive & Pixel-Perfect)
          InkWell(
            onTap: () => context.push(RoutePaths.exportPath(projectId)),
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.ios_share, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Export',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

