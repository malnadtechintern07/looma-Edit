import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../projects/domain/entities/project_entity.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../providers/editor_controller.dart';
import '../widgets/canvas_preview.dart';
import '../widgets/chroma_key_sheet.dart';
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

class _EditorScreenBody extends ConsumerStatefulWidget {
  final ProjectEntity project;

  const _EditorScreenBody({required this.project});

  @override
  ConsumerState<_EditorScreenBody> createState() => _EditorScreenBodyState();
}

class _EditorScreenBodyState extends ConsumerState<_EditorScreenBody> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ref.read(editorControllerProvider(widget.project).notifier).saveDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(editorControllerProvider(widget.project));
    final controller = ref.read(editorControllerProvider(widget.project).notifier);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (timelineState.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyS): () {
          controller.splitActiveClip();
        },
        const SingleActivator(LogicalKeyboardKey.delete): () {
          controller.deleteSelected();
        },
        const SingleActivator(LogicalKeyboardKey.backspace): () {
          controller.deleteSelected();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          controller.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          controller.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): () {
          controller.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
          controller.redo();
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          controller.seekTo(timelineState.playheadPositionMs - 33);
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          controller.seekTo(timelineState.playheadPositionMs + 33);
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () {
          controller.seekTo(timelineState.playheadPositionMs - 5000);
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () {
          controller.seekTo(timelineState.playheadPositionMs + 5000);
        },
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          controller.saveDraft();
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
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
                    child: RepaintBoundary(
                      child: CanvasPreview(
                        timelineState: timelineState,
                        controller: controller,
                      ),
                    ),
                  ),

                  if (timelineState.chromaKeyTargetClipId != null) ...[
                    // Dedicated Chroma Key Controls Panel docked at bottom
                    ChromaKeySheet(
                      currentConfig: (timelineState.project.videoClips
                              .where((c) => c.id == timelineState.chromaKeyTargetClipId)
                              .firstOrNull ??
                          timelineState.selectedVideoClip ??
                          timelineState.activeVideoClip)?.chromaKey,
                      isPickingMode: timelineState.isChromaKeyPickingMode,
                      onTogglePickingMode: () {
                        controller.toggleChromaKeyPickingMode();
                      },
                      onConfigChanged: (cfg) {
                        controller.setClipChromaKey(timelineState.chromaKeyTargetClipId!, cfg);
                      },
                      onReset: () {
                        controller.resetChromaKey(timelineState.chromaKeyTargetClipId!);
                      },
                      onClose: () {
                        controller.closeChromaKeyMode();
                      },
                    ),
                  ] else ...[
                    // 3. Multi-Track Timeline Scrubber
                    Expanded(
                      flex: 4,
                      child: RepaintBoundary(
                        child: MultiTrackTimeline(
                          state: timelineState,
                          controller: controller,
                        ),
                      ),
                    ),

                    // 4. Bottom Action Bar Toolbar
                    EditorActionBar(
                      state: timelineState,
                      controller: controller,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
