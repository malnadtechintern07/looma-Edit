import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../projects/domain/entities/project_entity.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../providers/editor_controller.dart';
import '../widgets/canvas_preview.dart';
import '../widgets/editor_action_bar.dart';
import '../widgets/editor_top_bar.dart';
import '../widgets/multi_track_timeline.dart';

class EditorScreen extends ConsumerWidget {
  final String projectId;

  const EditorScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ProjectEntity?>(
      future: ref.read(getProjectByIdUseCaseProvider)(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final project = snapshot.data;
        if (project == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Project Not Found')),
            body: const Center(
              child: Text('This project could not be found or has been deleted.'),
            ),
          );
        }

        return _EditorScreenBody(project: project);
      },
    );
  }
}

class _EditorScreenBody extends ConsumerWidget {
  final ProjectEntity project;

  const _EditorScreenBody({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(editorControllerProvider(project));
    final controller = ref.read(editorControllerProvider(project).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar
            EditorTopBar(
              controller: controller,
              currentRatio: timelineState.project.aspectRatio,
              projectTitle: timelineState.project.title,
              projectId: timelineState.project.id,
            ),

            // 2. Real-Time Canvas Preview Monitor
            Expanded(
              flex: 5,
              child: CanvasPreview(
                timelineState: timelineState,
                controller: controller,
              ),
            ),

            // 3. Multi-Track Timeline Scrubber
            Expanded(
              flex: 4,
              child: MultiTrackTimeline(
                state: timelineState,
                controller: controller,
              ),
            ),

            // 4. Bottom Action Bar Toolbar
            EditorActionBar(
              state: timelineState,
              controller: controller,
            ),
          ],
        ),
      ),
    );
  }
}
