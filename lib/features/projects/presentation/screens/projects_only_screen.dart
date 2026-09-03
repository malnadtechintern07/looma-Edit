import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../editor/domain/entities/video_clip_entity.dart';
import '../../../media_picker/domain/services/device_media_service.dart';
import '../../../media_picker/presentation/widgets/media_picker_modal.dart';
import '../../domain/entities/aspect_ratio_type.dart';
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
    Future.microtask(() {
      if (mounted) {
        ref.read(projectsNotifierProvider.notifier).loadProjects();
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
                        label: 'All',
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
                        onDuplicate: () =>
                            ref.read(projectsNotifierProvider.notifier).duplicateProject(project.id),
                        onDelete: () => _confirmDelete(project.id, project.title),
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
