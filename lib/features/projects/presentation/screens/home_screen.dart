import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../asset_store/presentation/screens/template_feed_screen.dart';
import '../../../editor/domain/entities/video_clip_entity.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../../media_picker/presentation/widgets/media_picker_modal.dart';
import '../../../photo_editor/domain/entities/photo_frame_entity.dart';
import '../../../photo_editor/domain/entities/photo_project_entity.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../domain/entities/aspect_ratio_type.dart';
import '../providers/projects_provider.dart';
import '../widgets/empty_projects_view.dart';
import '../widgets/project_card.dart';
import '../widgets/quick_action_banner.dart';
import 'projects_only_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  final DeviceMediaService _mediaService = DeviceMediaService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(projectsNotifierProvider.notifier).loadProjects();
      }
    });
  }

  Future<void> _openPhotoEditor() async {
    final photos = await _mediaService.pickPhotosFromDevice();
    if (photos.isNotEmpty && mounted) {
      final newPhotoProject = PhotoProjectEntity(
        id: IdGenerator.generate(),
        title: photos.first.name.split('.').first,
        frames: photos.map((p) => PhotoFrameEntity(
          id: IdGenerator.generate(),
          imagePath: p.path,
        )).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      context.push(RoutePaths.photoEditor, extra: newPhotoProject);
    } else if (mounted) {
      final newPhotoProject = PhotoProjectEntity(
        id: IdGenerator.generate(),
        title: 'Photo Collage ${DateTime.now().millisecond}',
        frames: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      context.push(RoutePaths.photoEditor, extra: newPhotoProject);
    }
  }

  void _openDirectMediaPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => MediaPickerModal(
          title: 'Select Photos & Videos for Project',
          actionLabel: 'Add',
          onMediaSelected: (pickedList) async {
            if (pickedList.isEmpty) return;
            int offsetMs = 0;
            final List<VideoClipEntity> clips = [];

            for (final m in pickedList) {
              final dur = m.durationMs;
              clips.add(
                VideoClipEntity(
                  id: IdGenerator.generate(),
                  mediaPath: m.path,
                  name: m.name,
                  sourceDurationMs: dur,
                  timelineStartMs: offsetMs,
                  timelineEndMs: offsetMs + dur,
                  trimStartMs: 0,
                  trimEndMs: dur,
                ),
              );
              offsetMs += dur;
            }

            final projectTitle = pickedList.first.name.split('.').first;
            final notifier = ref.read(projectsNotifierProvider.notifier);
            final project = await notifier.createProject(
              title: projectTitle,
              aspectRatio: AspectRatioType.ratio9_16,
              fps: 30,
              initialClips: clips,
            );

            if (mounted) {
              await context.push(RoutePaths.editorPath(project.id));
              if (mounted) {
                ref.read(projectsNotifierProvider.notifier).loadProjects();
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_currentNavIndex) {
      case 1:
        currentBody = const ProjectsOnlyScreen();
        break;
      case 2:
        currentBody = const TemplateFeedScreen();
        break;
      case 3:
        currentBody = const ProfileMeScreen();
        break;
      default:
        currentBody = _buildHomeDashboardTab();
    }

    return Scaffold(
      body: currentBody,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeDashboardTab() {
    final state = ref.watch(projectsNotifierProvider);
    final projects = ref.watch(filteredProjectsProvider);
    final selectedRatio = ref.watch(projectFilterRatioProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'LOOMA',
              style: AppTypography.titleLarge.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  color: Color(0xFFFFB800),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Identity',
            icon: const Icon(Icons.person_outline, color: Color(0xFF111827), size: 24),
            onPressed: () => setState(() => _currentNavIndex = 3),
          ),
          IconButton(
            tooltip: 'Cloud Backup',
            icon: const Icon(Icons.cloud_done_outlined, color: Color(0xFF5B4DFB), size: 22),
            onPressed: () => context.push(RoutePaths.cloud),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => ref.read(projectsNotifierProvider.notifier).loadProjects(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Banner Card (+ New Project) & Quick Action Tools Cards
                    QuickActionBanner(
                      onNewProject: _openDirectMediaPicker,
                      onNewPhotoProject: _openPhotoEditor,
                      onRecordVoiceover: _openDirectMediaPicker,
                      onBrowseTemplates: () => setState(() => _currentNavIndex = 2),
                    ),
                    const SizedBox(height: 24),

                    // 2. Recent Projects Section Header & Vertical List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Projects',
                          style: AppTypography.titleMedium.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _currentNavIndex = 1),
                          child: Text(
                            'See All (${projects.length})',
                            style: AppTypography.labelLarge.copyWith(
                              color: const Color(0xFF5B4DFB),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (projects.isEmpty)
                      EmptyProjectsView(onCreateProject: _openDirectMediaPicker)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: projects.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return ProjectCard(
                            project: project,
                            onTap: () async {
                              await context.push(RoutePaths.editorPath(project.id));
                              if (mounted) {
                                ref.read(projectsNotifierProvider.notifier).loadProjects();
                              }
                            },
                            onDuplicate: () => ref
                                .read(projectsNotifierProvider.notifier)
                                .duplicateProject(project.id),
                            onDelete: () => _confirmDelete(project.id, project.title),
                            onExport: () => context.push(RoutePaths.exportPath(project.id)),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // 3. Aspect Ratio Filter Section
                    Text(
                      'Aspect Ratio',
                      style: AppTypography.titleMedium.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRatioPill(
                            icon: Icons.grid_view,
                            label: 'All',
                            isSelected: selectedRatio == null,
                            onTap: () =>
                                ref.read(projectFilterRatioProvider.notifier).state = null,
                          ),
                          const SizedBox(width: 10),
                          ...AspectRatioType.values.map((ratio) {
                            final isSelected = selectedRatio == ratio;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: _buildRatioPill(
                                icon: _getRatioIcon(ratio),
                                label: ratio.label,
                                isSelected: isSelected,
                                onTap: () => ref
                                    .read(projectFilterRatioProvider.notifier)
                                    .state = isSelected ? null : ratio,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            index: 0,
            icon: Icons.home_filled,
            label: 'Home',
            onTap: () => setState(() => _currentNavIndex = 0),
          ),
          _buildBottomNavItem(
            index: 1,
            icon: Icons.folder_open,
            label: 'Projects',
            onTap: () => setState(() => _currentNavIndex = 1),
          ),

          // Center Elevated Floating Action Button (+)
          GestureDetector(
            onTap: _openDirectMediaPicker,
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B4DFB), Color(0xFF8644FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B4DFB).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),

          _buildBottomNavItem(
            index: 2,
            icon: Icons.auto_awesome_outlined,
            label: 'Templates',
            onTap: () => setState(() => _currentNavIndex = 2),
          ),
          _buildBottomNavItem(
            index: 3,
            icon: Icons.person_outline,
            label: 'Me',
            onTap: () => setState(() => _currentNavIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioPill({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B4DFB) : const Color(0xFFECEEF5),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x145B4DFB),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF5B4DFB) : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF5B4DFB) : const Color(0xFF6B7280),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRatioIcon(AspectRatioType ratio) {
    switch (ratio) {
      case AspectRatioType.ratio9_16:
        return Icons.smartphone;
      case AspectRatioType.ratio16_9:
        return Icons.tv;
      case AspectRatioType.ratio1_1:
        return Icons.crop_square;
      case AspectRatioType.ratio4_5:
        return Icons.crop_portrait;
      case AspectRatioType.ratio21_9:
        return Icons.video_label;
    }
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentNavIndex == index;
    final color = isSelected ? const Color(0xFF5B4DFB) : const Color(0xFF9CA3AF);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to permanently delete "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(projectsNotifierProvider.notifier).deleteProject(id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
