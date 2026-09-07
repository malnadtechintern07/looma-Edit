import 'package:flutter/material.dart';

import '../../../../core/widgets/responsive_tap_button.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Two Prominent Action Cards (Side-by-side from Reference UI)
        Row(
          children: [
            // Left Card: + New video
            Expanded(
              child: ResponsiveTapButton(
                onTap: onNewProject,
                child: Container(
                  height: 124,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'New video',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Right Card: Edit photo
            Expanded(
              child: ResponsiveTapButton(
                onTap: onNewPhotoProject,
                child: Container(
                  height: 124,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Edit photo',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 2. CapCut-Style Quick Tools Grid (3 Columns from Reference UI)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 14,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Row 1: Post template • AutoCut • Retouch
              Row(
                children: [
                  Expanded(
                    child: _buildGridToolItem(
                      icon: Icons.movie_creation_outlined,
                      label: 'Post template',
                      onTap: onBrowseTemplates,
                    ),
                  ),
                  Expanded(
                    child: _buildGridToolItem(
                      icon: Icons.video_library_outlined,
                      label: 'AutoCut',
                      onTap: onNewProject,
                    ),
                  ),
                  Expanded(
                    child: _buildGridToolItem(
                      icon: Icons.face_retouching_natural_outlined,
                      label: 'Retouch',
                      onTap: onNewPhotoProject,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 2: Photo tools • Shoot and record • Auto enhance
              Row(
                children: [
                  Expanded(
                    child: _buildGridToolItem(
                      icon: Icons.photo_filter_outlined,
                      label: 'Photo tools',
                      onTap: onNewPhotoProject,
                    ),
                  ),
                  Expanded(
                    child: _buildGridToolItem(
                      icon: Icons.camera_alt_outlined,
                      label: 'Shoot & record',
                      onTap: onRecordVoiceover,
                    ),
                  ),
                  Expanded(
                    child: _buildGridToolItem(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Auto enhance',
                      onTap: onNewProject,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 3: Auto captions • Remove background • Space
              Row(
                children: [
                  Expanded(
                    child: _buildGridToolItem(
                      icon: Icons.closed_caption_outlined,
                      label: 'Auto captions',
                      onTap: onNewProject,
                    ),
                  ),
                  Expanded(
                    child: _buildGridToolItem(
                      icon: Icons.person_pin_circle_outlined,
                      label: 'Remove bg',
                      onTap: onNewProject,
                    ),
                  ),
                  Expanded(
                    child: _buildGridToolItem(
                      icon: Icons.cloud_outlined,
                      label: 'Cloud Space',
                      onTap: onNewProject,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridToolItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ResponsiveTapButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: const Color(0xFF1E293B)),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
