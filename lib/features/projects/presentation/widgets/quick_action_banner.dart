import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class QuickActionBanner extends StatelessWidget {
  final VoidCallback onNewProject;
  final VoidCallback onNewPhotoProject;
  final VoidCallback onRecordVoiceover;
  final VoidCallback onBrowseTemplates;

  const QuickActionBanner({
    super.key,
    required this.onNewProject,
    required this.onNewPhotoProject,
    required this.onRecordVoiceover,
    required this.onBrowseTemplates,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Large Hero Banner Card (+ New Project)
        InkWell(
          onTap: onNewProject,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 140,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF5B4DFB), Color(0xFF8644FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3B5B4DFB),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Column: + New Project
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 24),
                        const SizedBox(width: 6),
                        Text(
                          'New Project',
                          style: AppTypography.displayMedium.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.blur_on, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Create a new video',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Right Side: Floating Clapperboard Icon Card
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.movie_creation,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 40,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(
                          Icons.auto_awesome,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 2. Three Tools Action Row: Video Edit | Photo Edit | Templates
        Row(
          children: [
            // Video Edit
            Expanded(
              child: _buildToolCard(
                icon: Icons.movie_creation_outlined,
                label: 'Video Edit',
                iconBgColor: const Color(0xFFF0EDFF),
                iconColor: const Color(0xFF5B4DFB),
                onTap: onNewProject,
              ),
            ),
            const SizedBox(width: 12),

            // Photo Edit
            Expanded(
              child: _buildToolCard(
                icon: Icons.photo_library_outlined,
                label: 'Photo Edit',
                iconBgColor: const Color(0xFFE6F9FA),
                iconColor: const Color(0xFF00C2CB),
                onTap: onNewPhotoProject,
              ),
            ),
            const SizedBox(width: 12),

            // Templates
            Expanded(
              child: _buildToolCard(
                icon: Icons.auto_awesome_outlined,
                label: 'Templates',
                iconBgColor: const Color(0xFFFFF8E6),
                iconColor: const Color(0xFFFFB800),
                onTap: onBrowseTemplates,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFECEEF5), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: const Color(0xFF111827),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
