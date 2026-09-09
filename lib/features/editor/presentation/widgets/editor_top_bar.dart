import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/procut_button.dart';
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
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Back Button (Auto-Saves Draft)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            tooltip: 'Save Draft & Exit',
            onPressed: () async {
              await controller.saveDraft();
              if (context.mounted) {
                context.pop();
              }
            },
          ),
          const SizedBox(width: 4),

          // Aspect Ratio Switcher Menu
          PopupMenuButton<AspectRatioType>(
            tooltip: 'Change Aspect Ratio',
            initialValue: currentRatio,
            onSelected: controller.updateAspectRatio,
            color: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.surfaceBorder),
            ),
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
                    Text('${ratio.label} (${ratio.description})'),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.aspect_ratio, size: 14, color: AppColors.primaryLight),
                  const SizedBox(width: 4),
                  Text(currentRatio.label, style: AppTypography.labelLarge.copyWith(fontSize: 11)),
                  const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Project Title (Editable)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                projectTitle,
                style: AppTypography.titleSmall.copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Save Draft Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.save_outlined,
              size: 20,
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
                        Text(
                          'Draft saved successfully!',
                          style: TextStyle(fontWeight: FontWeight.w600),
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

          // Export Button CTA
          ProCutButton(
            label: 'Export',
            icon: Icons.ios_share,
            height: 32,
            onPressed: () => context.push(RoutePaths.exportPath(projectId)),
          ),
        ],
      ),
    );
  }
}
