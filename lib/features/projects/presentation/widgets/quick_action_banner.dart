import 'package:flutter/material.dart';
import '../../../../core/services/app_remote_config_service.dart';
import '../../../../core/widgets/responsive_tap_button.dart';

class QuickActionBanner extends StatelessWidget {
  final VoidCallback onNewProject;
  final VoidCallback onNewPhotoProject;
  final VoidCallback onRecordVoiceover;
  final VoidCallback onBrowseTemplates;
  final List<RemoteFeatureModel>? features;

  const QuickActionBanner({
    super.key,
    required this.onNewProject,
    required this.onNewPhotoProject,
    required this.onRecordVoiceover,
    required this.onBrowseTemplates,
    this.features,
  });

  VoidCallback _resolveTap(String featureKey) {
    switch (featureKey) {
      case 'templates':
      case 'post_template':
        return onBrowseTemplates;
      case 'retouch':
      case 'photo_tools':
        return onNewPhotoProject;
      case 'shoot_record':
      case 'voiceover':
        return onRecordVoiceover;
      case 'autocut':
      case 'auto_enhance':
      case 'auto_captions':
      case 'remove_bg':
      case 'cloud_space':
      default:
        return onNewProject;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFeatures = (features ?? [])
        .where((f) => f.isEnabled)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

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

        // 2. CapCut-Style Quick Tools Grid (Dynamically loaded from Admin Panel)
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
          child: activeFeatures.isNotEmpty
              ? _buildDynamicGrid(activeFeatures)
              : _buildDefaultStaticGrid(),
        ),
      ],
    );
  }

  Widget _buildDynamicGrid(List<RemoteFeatureModel> activeFeatures) {
    final List<Widget> gridRows = [];
    for (int i = 0; i < activeFeatures.length; i += 3) {
      final chunk = activeFeatures.sublist(
        i,
        i + 3 > activeFeatures.length ? activeFeatures.length : i + 3,
      );
      gridRows.add(
        Row(
          children: [
            for (final item in chunk)
              Expanded(
                child: _buildDynamicToolItem(
                  feature: item,
                  onTap: _resolveTap(item.featureKey),
                ),
              ),
            for (int filler = 0; filler < (3 - chunk.length); filler++)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
      if (i + 3 < activeFeatures.length) {
        gridRows.add(const SizedBox(height: 16));
      }
    }
    return Column(children: gridRows);
  }

  Widget _buildDynamicToolItem({
    required RemoteFeatureModel feature,
    required VoidCallback onTap,
  }) {
    return ResponsiveTapButton(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                ),
                alignment: Alignment.center,
                child: Icon(feature.iconData, color: const Color(0xFF1E293B), size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                feature.name,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (feature.isPro)
            Positioned(
              top: -2,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultStaticGrid() {
    return Column(
      children: [
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFF1E293B), size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
              fontSize: 12,
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
