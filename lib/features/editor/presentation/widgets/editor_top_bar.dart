import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/looma_button.dart';
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
          // Back Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            tooltip: 'Back to Projects',
            onPressed: () => context.pop(),
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

          // Undo / Redo
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.undo,
              size: 18,
              color: controller.canUndo ? AppColors.textPrimary : AppColors.textDisabled,
            ),
            tooltip: 'Undo',
            onPressed: controller.canUndo ? controller.undo : null,
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.redo,
              size: 18,
              color: controller.canRedo ? AppColors.textPrimary : AppColors.textDisabled,
            ),
            tooltip: 'Redo',
            onPressed: controller.canRedo ? controller.redo : null,
          ),

          const SizedBox(width: 6),

          // Export Button CTA
          LoomaButton(
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
