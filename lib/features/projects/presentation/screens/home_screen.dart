import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../asset_store/presentation/screens/template_feed_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cloud_sync/presentation/providers/cloud_sync_provider.dart';
import '../../../editor/domain/entities/video_clip_entity.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../../media_picker/presentation/widgets/media_picker_modal.dart';
import '../../../photo_editor/domain/entities/photo_frame_entity.dart';
import '../../../photo_editor/domain/entities/photo_project_entity.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../domain/entities/aspect_ratio_type.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/sync_status_type.dart';
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
    Future.microtask(() async {
      if (mounted) {
        await ref.read(projectsNotifierProvider.notifier).loadProjects();
        if (ref.read(authNotifierProvider).isAuthenticated) {
          ref.read(syncNotifierProvider.notifier).triggerSync();
        }
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
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.isAuthenticated;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        titleSpacing: 16,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
        ),
        actions: [
          if (!isAuthenticated)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: ElevatedButton.icon(
                key: const Key('home_signin_register_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4DFB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.login, size: 14),
                label: const Text('Sign In / Register', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => context.push(RoutePaths.auth),
              ),
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
              onRefresh: () async {
                await ref.read(projectsNotifierProvider.notifier).loadProjects();
                if (ref.read(authNotifierProvider).isAuthenticated) {
                  await ref.read(syncNotifierProvider.notifier).triggerSync();
                }
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 0. Sign In or Register CTA Banner (Only shown on Home page when NOT signed in)
                    if (!isAuthenticated) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E266D), Color(0xFF1E1B4B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF5B4DFB).withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B4DFB).withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF5B4DFB), Color(0xFF8644FF)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.cloud_sync, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cloud Backup & Sync',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Sign in or register to secure your timeline projects in the cloud.',
                                        style: TextStyle(
                                          color: Color(0xFFC7D2FE),
                                          fontSize: 11.5,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                key: const Key('home_banner_signin_register_btn'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5B4DFB),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                ),
                                icon: const Icon(Icons.login, size: 16),
                                label: const Text(
                                  'Sign In / Register Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () => context.push(RoutePaths.auth),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                        Expanded(
                          child: Text(
                            'Recent Projects',
                            style: AppTypography.titleMedium.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            onRename: () => _showRenameDialog(project),
                            onSync: () => _handleSync(project),
                            onDuplicate: () => ref
                                .read(projectsNotifierProvider.notifier)
                                .duplicateProject(project.id),
                            onDelete: () => _confirmDelete(project),
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

  void _showRenameDialog(ProjectEntity project) {
    final controller = TextEditingController(text: project.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: const InputDecoration(
            labelText: 'Project Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B4DFB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ref.read(projectsNotifierProvider.notifier).renameProject(project.id, newTitle);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project renamed successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleSync(ProjectEntity project) async {
    final isAuthenticated = ref.read(authNotifierProvider).isAuthenticated;
    if (!isAuthenticated) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign In Required', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'To back up and synchronize projects across devices with Looma Cloud, please sign in or create an account.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4DFB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
      if (shouldLogin == true && mounted) {
        context.push(RoutePaths.auth);
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Syncing "${project.title}" to Looma Cloud...')),
    );
    final ok = await ref.read(syncNotifierProvider.notifier).syncSingleProject(project.id);
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('"${project.title}" successfully synced to cloud!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to sync "${project.title}" to cloud.'),
          ),
        );
      }
    }
  }

  void _confirmDelete(ProjectEntity project) {
    final isCloudSynced = project.syncStatus == SyncStatusType.synced ||
        project.syncStatus == SyncStatusType.syncing;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(isCloudSynced ? 'Delete Cloud & Local?' : 'Delete Project?'),
          ],
        ),
        content: Text(
          isCloudSynced
              ? 'Are you sure you want to permanently delete "${project.title}"? This project has a cloud backup. Deleting it will permanently remove both the local copy and the cloud backup.'
              : 'Are you sure you want to permanently delete "${project.title}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (isCloudSynced) {
                await ref.read(syncNotifierProvider.notifier).deleteCloudBackup(project.id);
              }
              await ref.read(projectsNotifierProvider.notifier).deleteProject(project.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${project.title}"')),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
