import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cloud_sync/presentation/providers/cloud_sync_provider.dart';
import '../../../editor/domain/entities/video_clip_entity.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../../media_picker/presentation/widgets/media_picker_modal.dart';
import '../../domain/entities/aspect_ratio_type.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/sync_status_type.dart';
import '../providers/projects_provider.dart';
import '../widgets/empty_projects_view.dart';
import '../widgets/project_card.dart';

class ProjectsOnlyScreen extends ConsumerStatefulWidget {
  const ProjectsOnlyScreen({super.key});

  @override
  ConsumerState<ProjectsOnlyScreen> createState() => _ProjectsOnlyScreenState();
}

class _ProjectsOnlyScreenState extends ConsumerState<ProjectsOnlyScreen> {
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final DeviceMediaService _mediaService = DeviceMediaService();

  Future<void> _openDirectMediaPicker() async {
    final selectedMedia = await _mediaService.pickVideosFromDevice();

    if (selectedMedia.isNotEmpty && mounted) {
      int offsetMs = 0;
      final List<VideoClipEntity> clips = [];

      for (final m in selectedMedia) {
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

      final projectTitle = selectedMedia.first.name.split('.').first;
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
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xFF0C0D12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => MediaPickerModal(
          title: 'Select Photos & Videos for Project',
          actionLabel: 'Create Project & Open Editor',
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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectsNotifierProvider);
    final allProjects = state.projects;
    final selectedRatio = ref.watch(projectFilterRatioProvider);

    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredProjects = allProjects.where((p) {
      if (selectedRatio != null && p.aspectRatio != selectedRatio) return false;
      if (searchQuery.isNotEmpty && !p.title.toLowerCase().contains(searchQuery)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'My Projects',
              style: AppTypography.titleLarge.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5B4DFB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${filteredProjects.length}',
                style: const TextStyle(
                  color: Color(0xFF5B4DFB),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New Project',
            icon: const Icon(Icons.add_circle, color: Color(0xFF5B4DFB), size: 26),
            onPressed: _openDirectMediaPicker,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Ratio Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFECEEF5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                          decoration: const InputDecoration(
                            hintText: 'Search projects by name...',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: Color(0xFF9CA3AF)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () => setState(() => _searchController.clear()),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Aspect Ratio Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRatioFilterChip(
                        label: 'All Ratios',
                        isSelected: selectedRatio == null,
                        onTap: () => ref.read(projectFilterRatioProvider.notifier).state = null,
                      ),
                      const SizedBox(width: 8),
                      ...AspectRatioType.values.map((ratio) {
                        final isSelected = selectedRatio == ratio;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildRatioFilterChip(
                            label: ratio.label,
                            isSelected: isSelected,
                            onTap: () => ref.read(projectFilterRatioProvider.notifier).state =
                                isSelected ? null : ratio,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Storage & Sync Filter Pills
                Consumer(
                  builder: (context, ref, _) {
                    final syncFilter = ref.watch(projectSyncFilterProvider);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRatioFilterChip(
                            label: 'All Projects',
                            isSelected: syncFilter == null,
                            onTap: () => ref.read(projectSyncFilterProvider.notifier).state = null,
                          ),
                          const SizedBox(width: 8),
                          _buildRatioFilterChip(
                            label: '☁️ Cloud Synced',
                            isSelected: syncFilter == SyncStatusType.synced,
                            onTap: () => ref.read(projectSyncFilterProvider.notifier).state =
                                syncFilter == SyncStatusType.synced ? null : SyncStatusType.synced,
                          ),
                          const SizedBox(width: 8),
                          _buildRatioFilterChip(
                            label: '📱 Device Only',
                            isSelected: syncFilter == SyncStatusType.localOnly,
                            onTap: () => ref.read(projectSyncFilterProvider.notifier).state =
                                syncFilter == SyncStatusType.localOnly ? null : SyncStatusType.localOnly,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 2. Projects List View
          Expanded(
            child: filteredProjects.isEmpty
                ? EmptyProjectsView(onCreateProject: _openDirectMediaPicker)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredProjects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
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
                        onDuplicate: () =>
                            ref.read(projectsNotifierProvider.notifier).duplicateProject(project.id),
                        onDelete: () => _confirmDelete(project),
                        onExport: () => context.push(RoutePaths.exportPath(project.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B4DFB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B4DFB) : const Color(0xFFECEEF5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
