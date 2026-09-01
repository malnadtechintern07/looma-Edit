import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/looma_button.dart';

class EmptyProjectsView extends StatelessWidget {
  final VoidCallback onCreateProject;

  const EmptyProjectsView({super.key, required this.onCreateProject});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.surfaceBorder, width: 2),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 48,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text('No Projects Found', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Start creating your next viral video with trim, transitions, multitrack audio & effects.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 24),
            LoomaButton(
              label: 'Create First Project',
              icon: Icons.add,
              onPressed: onCreateProject,
            ),
          ],
        ),
      ),
    );
  }
}
